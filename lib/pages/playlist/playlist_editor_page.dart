import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/cards/song_list_tile.dart';
import '../../components/ds_state_page.dart';
import '../../components/ds_text.dart';
import '../../components/forms/star_rating.dart';
import '../../model/song.dart';
import '../../player/playback_service.dart';
import '../../provider/core_providers.dart';
import '../../provider/library_provider.dart';
import '../../provider/player_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/logger.dart';

/// 歌单编辑器：重命名、添加/删除歌曲、评分、播放全部
class PlaylistEditorPage extends ConsumerStatefulWidget {
  final String playlistId;
  const PlaylistEditorPage({super.key, required this.playlistId});

  @override
  ConsumerState<PlaylistEditorPage> createState() => _PlaylistEditorPageState();
}

class _PlaylistEditorPageState extends ConsumerState<PlaylistEditorPage> {
  late TextEditingController _nameCtrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(playlistDetailProvider(widget.playlistId));
    return CupertinoPageScaffold(
      backgroundColor: AppColors.darkBg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.darkBg,
        border: const Border(),
        middle: DSText(_editing ? '编辑歌单' : '歌单'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => setState(() => _editing = !_editing),
          child: DSText(_editing ? '完成' : '编辑', color: AppColors.accent),
        ),
      ),
      child: SafeArea(
        child: detail.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => DSStatePage(
              type: StateType.error, message: '加载失败: $e', onRetry: () => ref.invalidate(playlistDetailProvider(widget.playlistId))),
          data: (pl) {
            if (_nameCtrl.text.isEmpty) {
              _nameCtrl.text = pl.name;
            }
            final songs = pl.songs;
            return Column(
              children: [
                // 头部：封面 + 名称（编辑模式下可重命名）
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.darkCard,
                          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                        ),
                        child: const Icon(CupertinoIcons.music_note_list, size: 36, color: AppColors.textAssistantDark),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _editing
                            ? CupertinoTextField(
                                controller: _nameCtrl,
                                style: const TextStyle(color: CupertinoColors.white, fontSize: 18, fontWeight: FontWeight.w600),
                                decoration: BoxDecoration(
                                  color: AppColors.darkCard,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  DSText(pl.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  DSText.assistant('${songs.length} 首 · ${_fmtDur(pl.duration)}'),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
                // 工具栏
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          color: AppColors.accent,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          onPressed: songs.isEmpty
                              ? null
                              : () => _playAll(songs),
                          child: DSText('播放全部', color: CupertinoColors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CupertinoButton(
                          color: AppColors.darkCard,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          onPressed: () => _addSongs(pl),
                          child: DSText('添加歌曲', color: AppColors.accent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: songs.isEmpty
                      ? const DSStatePage(type: StateType.empty, message: '歌单为空')
                      : ListView.separated(
                          itemCount: songs.length,
                          separatorBuilder: (_, __) => Container(
                            height: 0.5,
                            margin: const EdgeInsets.only(left: 70),
                            color: AppColors.darkDivider,
                          ),
                          itemBuilder: (_, i) {
                            final s = songs[i];
                            return Dismissible(
                              key: ValueKey(s.id),
                              direction: _editing
                                  ? DismissDirection.endToStart
                                  : DismissDirection.none,
                              background: Container(
                                color: CupertinoColors.systemRed,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(CupertinoIcons.delete, color: CupertinoColors.white),
                              ),
                              onDismissed: (_) => _removeSong(pl, s),
                              child: SongListTile(
                                song: s,
                                showAlbum: true,
                                trailing: _editing
                                    ? null
                                    : StarRating(
                                        value: s.rating,
                                        size: 14,
                                        onChanged: (v) => _rateSong(s, v),
                                      ),
                                onTap: () => _playFrom(songs, i),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ==================== Actions ====================

  String _fmtDur(int seconds) {
    final m = seconds ~/ 60;
    if (m < 60) return '$m 分钟';
    final h = m ~/ 60;
    return '$h 小时 ${m % 60} 分';
  }

  Future<void> _playAll(List<Song> songs) async {
    final h = ref.read(audioHandlerProvider);
    await h.setQueueAndPlay(songs, startIndex: 0);
    ref.read(playerStateProvider.notifier).setQueue(songs, startIndex: 0);
    ref.read(playerStateProvider.notifier).setPlaying(true);
  }

  Future<void> _playFrom(List<Song> songs, int idx) async {
    final h = ref.read(audioHandlerProvider);
    await h.setQueueAndPlay(songs, startIndex: idx);
    ref.read(playerStateProvider.notifier).setQueue(songs, startIndex: idx);
    ref.read(playerStateProvider.notifier).setPlaying(true);
  }

  Future<void> _rateSong(Song s, int rating) async {
    try {
      final repo = ref.read(libraryRepositoryProvider);
      await repo.rate(s, rating);
      // 通过重新拉详情刷新 UI
      ref.invalidate(playlistDetailProvider(widget.playlistId));
    } catch (e) {
      AppLogger.e('评分失败: $e');
    }
  }

  Future<void> _removeSong(pl, Song s) async {
    try {
      final repo = ref.read(libraryRepositoryProvider);
      await repo.updatePlaylist(id: pl.id, removeSongIds: [s.id]);
      ref.invalidate(playlistDetailProvider(widget.playlistId));
      ref.invalidate(playlistsProvider);
    } catch (e) {
      AppLogger.e('删除歌曲失败: $e');
    }
  }

  Future<void> _addSongs(pl) async {
    // 简化实现：弹一个底部 sheet 让用户选择要添加的歌曲 id
    final songs = await ref.read(libraryRepositoryProvider).songs();
    if (!mounted) return;
    final selected = <String>{};
    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 360,
        color: AppColors.darkBg,
        child: StatefulBuilder(
          builder: (ctx, setS) => Column(
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const DSText('取消'),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      onPressed: () async {
                        try {
                          if (selected.isEmpty) return;
                          await ref.read(libraryRepositoryProvider).updatePlaylist(
                                id: pl.id,
                                addSongIds: selected.toList(),
                              );
                          ref.invalidate(playlistDetailProvider(widget.playlistId));
                          ref.invalidate(playlistsProvider);
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          AppLogger.e('添加失败: $e');
                        }
                      },
                      child: const DSText('确定', color: AppColors.accent),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 36,
                  onSelectedItemChanged: (_) {},
                  children: [
                    for (final s in songs)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setS(() {
                          if (selected.contains(s.id)) {
                            selected.remove(s.id);
                          } else {
                            selected.add(s.id);
                          }
                        }),
                        child: Row(
                          children: [
                            Icon(
                              selected.contains(s.id)
                                  ? CupertinoIcons.checkmark_circle_fill
                                  : CupertinoIcons.circle,
                              color: selected.contains(s.id)
                                  ? AppColors.accent
                                  : AppColors.textAssistantDark,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DSText(
                                '${s.title}  -  ${s.artist ?? ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
