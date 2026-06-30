import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/ds_text.dart';
import '../../components/gestures/swipe_to_dismiss.dart';
import '../../model/lyrics.dart';
import '../../model/song.dart';
import '../../constants/app_constants.dart';
import '../../player/playback_service.dart';
import '../../player/overlay_lyrics_controller.dart';
import '../../player/sleep_timer.dart';
import '../../provider/core_providers.dart';
import '../../provider/library_provider.dart';
import '../../provider/lyrics_provider.dart';
import '../../provider/player_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/datetime_utils.dart';
import '../../utils/responsive.dart';
import '../../components/cards/cover_image.dart';
import '../../components/lyrics/lyrics_view.dart';
import '../../components/ds_state_page.dart';
import '../queue/queue_page.dart';

/// 播放详情页：全屏沉浸式
class PlayerPage extends ConsumerStatefulWidget {
  const PlayerPage({super.key});

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  Lyrics _lyrics = const Lyrics();
  bool _showLyrics = false;
  bool _initialized = false;
  bool _overlayOn = false;

  // —— 悬浮歌词：定时把当前位置推送到原生层 ——
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLyricsAndStart());
  }

  Future<void> _loadLyricsAndStart() async {
    if (_initialized) return;
    _initialized = true;
    final song = ref.read(playerStateProvider).current;
    if (song == null) return;

    // 1. 设置播放队列并启动
    final state = ref.read(playerStateProvider);
    final handler = ref.read(audioHandlerProvider);
    if (state.queue.isNotEmpty) {
      await handler.setQueueAndPlay(state.queue, startIndex: state.currentIndex);
    } else {
      await handler.setSingleAndPlay(song);
    }
    ref.read(playerStateProvider.notifier).setPlaying(true);

    // 2. 通过歌词 Provider 拉取（同时驱动锁屏 + 悬浮窗）
    final lyricsNotifier = ref.read(lyricsProvider.notifier);
    await lyricsNotifier.load(song);
    if (mounted) {
      final s = ref.read(lyricsProvider);
      setState(() => _lyrics = s.lyrics);
      // 同步 LRC 给 audio_handler → 锁屏显示
      ref.read(audioHandlerProvider).setLyricsLrc(_serializeLrc(s.lyrics));
    }
  }

  /// 切换悬浮歌词
  Future<void> _toggleOverlayLyrics(Song song) async {
    final s = ref.read(lyricsProvider);
    if (_overlayOn) {
      await OverlayLyricsController.instance.hide();
      setState(() => _overlayOn = false);
    } else {
      final ok = await OverlayLyricsController.instance.show(song, s.lyrics);
      setState(() => _overlayOn = ok);
      if (ok) {
        // 首次开启时推一次位置
        await OverlayLyricsController.instance
            .updatePosition(ref.read(playerStateProvider).position);
      }
    }
  }

  /// LRC 序列化：用于锁屏显示
  String _serializeLrc(Lyrics lyrics) {
    final buf = StringBuffer();
    for (final l in lyrics.lines) {
      final m = l.time.inMinutes.remainder(60).toString().padLeft(2, '0');
      final sec = l.time.inSeconds.remainder(60).toString().padLeft(2, '0');
      final ms = (l.time.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
      buf.writeln('[$m:$sec.$ms]${l.text}');
    }
    return buf.toString();
  }

  @override
  void dispose() {
    if (_overlayOn) {
      OverlayLyricsController.instance.hide();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerStateProvider);
    // 驱动悬浮歌词滚动
    if (_overlayOn) {
      // 使用 microtask 避免在 build 阶段触发外部副作用
      Future.microtask(() {
        OverlayLyricsController.instance.updatePosition(state.position);
      });
    }
    final song = state.current;
    if (song == null) {
      return DSStatePage(type: StateType.empty, message: context.s.empty);
    }
    final repo = ref.read(libraryRepositoryProvider);
    final coverUrl = song.albumId != null ? repo.coverUrl(song.albumId!, size: 'big') : null;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.darkBg,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Stack(
          key: ValueKey(song.id),
          children: [
            // 背景：封面高斯模糊
            _blurBackground(coverUrl),
            Container(color: AppColors.maskDark),
            SwipeToDismiss(
              // 左滑下一首，右滑上一首
              onSwipeLeft: () async {
                ref.read(playerStateProvider.notifier).next();
                await ref.read(audioHandlerProvider).skipToNext();
              },
              onSwipeRight: () async {
                ref.read(playerStateProvider.notifier).prev();
                await ref.read(audioHandlerProvider).skipToPrevious();
              },
              // 下滑超过阈值关闭页面
              onDismiss: (_) => Navigator.of(context).maybePop(),
              child: SafeArea(
                child: Responsive(context).isWideLayout
                    ? _wideLayout(context, state, song, coverUrl)
                    : _portraitLayout(context, state, song, coverUrl),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 竖屏/手机：上下排布（封面 + 信息 + 控制）
  Widget _portraitLayout(BuildContext context, PlayerStateData state, Song song, String? coverUrl) {
    return Column(
      children: [
        _topBar(context),
        const SizedBox(height: 8),
        Expanded(
          child: GestureDetector(
            onVerticalDragEnd: (d) {
              if (d.primaryVelocity != null) {
                if (d.primaryVelocity! < -200) {
                  setState(() => _showLyrics = true);
                } else if (d.primaryVelocity! > 200) {
                  setState(() => _showLyrics = false);
                }
              }
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showLyrics
                  ? LyricsView(
                      key: const ValueKey('lyrics'),
                      lyrics: _lyrics,
                      position: state.position,
                      onSeek: (p) async {
                        final h = ref.read(audioHandlerProvider);
                        await h.seek(p);
                      },
                    )
                  : _albumArt(key: const ValueKey('art'), coverUrl: coverUrl, song: song),
            ),
          ),
        ),
        _info(song),
        const SizedBox(height: 16),
        _progress(state),
        const SizedBox(height: 8),
        _controls(context),
        const SizedBox(height: 12),
        _auxControls(),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 横屏/平板：左右分栏（左侧封面 + 右侧信息/歌词/控制）
  Widget _wideLayout(BuildContext context, PlayerStateData state, Song song, String? coverUrl) {
    return Row(
      children: [
        // 左侧：封面 + 标题
        Expanded(
          flex: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _WideSpacer(),
              _albumArt(key: const ValueKey('art_wide'), coverUrl: coverUrl, song: song),
              const SizedBox(height: 24),
              _info(song),
            ],
          ),
        ),
        // 右侧：进度 + 控制 + 歌词切换
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _topBar(context),
              Expanded(
                child: _showLyrics
                    ? LyricsView(
                        key: const ValueKey('lyrics_wide'),
                        lyrics: _lyrics,
                        position: state.position,
                        onSeek: (p) async {
                          final h = ref.read(audioHandlerProvider);
                          await h.seek(p);
                        },
                      )
                    : const _WideSpacer(),
              ),
              _progress(state),
              const SizedBox(height: 8),
              _controls(context),
              const SizedBox(height: 12),
              _auxControls(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _blurBackground(String? coverUrl) {
    if (coverUrl == null) return const SizedBox.shrink();
    return Positioned.fill(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Image.network(coverUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return SizedBox(
      height: AppDimens.navBarHeight,
      child: Row(
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            onPressed: () => Navigator.of(context).pop(),
            child: const Icon(CupertinoIcons.chevron_down, color: CupertinoColors.white, size: 24),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DSText.assistant(
                    '正在播放',
                    color: AppColors.textAssistantDark,
                  ),
                  const SizedBox(height: 2),
                  DSText(
                    ref.read(playerStateProvider).current?.album ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            onPressed: () {},
            child: const Icon(CupertinoIcons.ellipsis, color: CupertinoColors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _albumArt({required Key key, required String? coverUrl, required Song song}) {
    final r = Responsive(context);
    final size = r.isWideLayout ? r.playerCoverSize : AppDimens.playerCoverSize;
    return Center(
      key: key,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: ValueKey(song.id + '_art'),
          margin: EdgeInsets.only(top: r.isWideLayout ? 0 : AppDimens.playerCoverOffset),
          width: size,
          height: size,
          child: CoverImage(url: coverUrl, size: size, withShadow: true),
        ),
      ),
    );
  }

  Widget _info(Song song) {
    return Column(
      children: [
        DSText.playerSong(song.title),
        const SizedBox(height: 6),
        DSText.playerArtist(
          song.artist ?? '未知艺术家',
          color: AppColors.textAssistantDark,
        ),
      ],
    );
  }

  Widget _progress(PlayerStateData state) {
    final pos = state.position.inMilliseconds.toDouble();
    final dur = (state.current?.duration ?? 1) * 1000.0;
    final value = dur <= 0 ? 0.0 : (pos / dur).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          CupertinoSlider(
            value: value,
            activeColor: AppColors.accent,
            onChanged: (v) async {
              final newPos = Duration(milliseconds: (v * dur).toInt());
              final h = ref.read(audioHandlerProvider);
              await h.seek(newPos);
              ref.read(playerStateProvider.notifier).setPosition(newPos);
            },
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DSText.assistant(DateTimeUtils.formatDuration(state.position)),
              DSText.assistant(DateTimeUtils.formatSeconds(state.current?.duration ?? 0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _controls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(CupertinoIcons.backward_fill, size: AppDimens.controlIconSize, color: CupertinoColors.white),
            onPressed: () async {
              ref.read(playerStateProvider.notifier).prev();
              final h = ref.read(audioHandlerProvider);
              await h.skipToPrevious();
            },
          ),
          _playPauseButton(),
          IconButton(
            icon: const Icon(CupertinoIcons.forward_fill, size: AppDimens.controlIconSize, color: CupertinoColors.white),
            onPressed: () async {
              ref.read(playerStateProvider.notifier).next();
              final h = ref.read(audioHandlerProvider);
              await h.skipToNext();
            },
          ),
        ],
      ),
    );
  }

  Widget _playPauseButton() {
    final playing = ref.watch(playerStateProvider.select((s) => s.playing));
    return GestureDetector(
      onTap: () async {
        final h = ref.read(audioHandlerProvider);
        if (playing) {
          await h.pause();
        } else {
          await h.play();
        }
        ref.read(playerStateProvider.notifier).setPlaying(!playing);
      },
      child: Container(
        width: AppDimens.playButtonSize,
        height: AppDimens.playButtonSize,
        decoration: const BoxDecoration(
          color: CupertinoColors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          playing ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
          size: 30,
          color: CupertinoColors.black,
        ),
      ),
    );
  }

  Widget _auxControls() {
    final mode = ref.watch(playerStateProvider.select((s) => s.mode));
    IconData loopIcon = CupertinoIcons.arrow_2_circlepath;
    if (mode == PlayMode.singleLoop) loopIcon = CupertinoIcons.repeat_1;
    if (mode == PlayMode.sequence) loopIcon = CupertinoIcons.arrow_2_circlepath;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: () {
              ref.read(playerStateProvider.notifier)
                  .setMode(mode == PlayMode.singleLoop ? PlayMode.sequence : PlayMode.singleLoop);
            },
            child: Icon(loopIcon,
                size: AppDimens.smallIconSize,
                color: mode == PlayMode.singleLoop ? AppColors.accent : CupertinoColors.white),
          ),
          GestureDetector(
            onTap: () {
              ref.read(playerStateProvider.notifier)
                  .setMode(mode == PlayMode.shuffle ? PlayMode.sequence : PlayMode.shuffle);
            },
            child: Icon(CupertinoIcons.shuffle,
                size: AppDimens.smallIconSize,
                color: mode == PlayMode.shuffle ? AppColors.accent : CupertinoColors.white),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(CupertinoPageRoute(
                builder: (_) => const QueuePage(),
              ));
            },
            child: const Icon(CupertinoIcons.list_bullet, size: AppDimens.smallIconSize, color: CupertinoColors.white),
          ),
          GestureDetector(
            onTap: () => _toggleOverlayLyrics(song),
            child: Icon(
              _overlayOn ? CupertinoIcons.text_bubble_fill : CupertinoIcons.text_bubble,
              size: AppDimens.smallIconSize,
              color: _overlayOn ? AppColors.accent : CupertinoColors.white,
            ),
          ),
          // A7 修复：第 5 个图标改为"睡眠定时"快捷入口
          // 原 speaker_2_fill 是占位，现在替换为月亮图标，点击弹出时长选择
          GestureDetector(
            onTap: () => _showSleepSheet(context, ref),
            child: Icon(
              CupertinoIcons.moon,
              size: AppDimens.smallIconSize,
              color: ref.watch(sleepTimerProvider).inMinutes > 0
                  ? AppColors.accent
                  : CupertinoColors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 睡眠定时快捷选择 sheet
  void _showSleepSheet(BuildContext context, WidgetRef ref) {
    final t = context.s;
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 280,
        color: AppColors.darkCard,
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  CupertinoButton(
                    onPressed: () {
                      ref.read(sleepTimerProvider.notifier).cancel();
                      Navigator.pop(context);
                    },
                    child: DSText(t.close),
                  ),
                  const Spacer(),
                  CupertinoButton(
                    onPressed: () {
                      // onSelectedItemChanged 已经写入 _selectedMinutes
                      ref.read(sleepTimerProvider.notifier).start(_selectedMinutes);
                      Navigator.pop(context);
                    },
                    child: DSText(t.confirm),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 32,
                scrollController: FixedExtentScrollController(
                  initialItem: AppConstants.sleepOptions.indexOf(_selectedMinutes).clamp(0, AppConstants.sleepOptions.length - 1),
                ),
                onSelectedItemChanged: (i) => _selectedMinutes = AppConstants.sleepOptions[i],
                children: [
                  for (final m in AppConstants.sleepOptions) Center(child: DSText('$m 分钟')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 睡眠定时初始分钟数（Picker 状态）
  int _selectedMinutes = AppConstants.sleepOptions[0];
}

/// 横屏布局中作为左/右侧的占位/对齐辅助
class _WideSpacer extends StatelessWidget {
  const _WideSpacer();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
