import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/song.dart';
import '../../player/network_type_watcher.dart';
import '../../player/playback_service.dart';
import '../../provider/player_provider.dart';
import '../../provider/core_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../cards/cover_image.dart';
import '../cards/glass_container.dart';
import '../ds_text.dart';

/// 全局底部迷你播放栏
/// 固定 56px 高，毛玻璃背景，点击上滑展开播放详情页
class MiniPlayerBar extends ConsumerWidget {
  final VoidCallback? onTap;
  final VoidCallback? onNext;
  final VoidCallback? onPlayPause;

  const MiniPlayerBar({
    super.key,
    this.onTap,
    this.onNext,
    this.onPlayPause,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerStateProvider);
    final song = playerState.current;
    if (song == null) return const SizedBox.shrink();

    final brightness = CupertinoTheme.brightnessOf(context);
    final divider = brightness == Brightness.dark
        ? AppColors.darkDivider
        : AppColors.lightDivider;
    final repo = ref.read(libraryRepositoryProvider);
    final coverUrl = song.albumId != null ? repo.coverUrl(song.albumId!, size: 'small') : null;

    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 0.5, color: divider),
          SizedBox(
            height: AppDimens.miniPlayerHeight,
            child: Row(
              children: [
                const SizedBox(width: 8),
                CoverImage(url: coverUrl, size: AppDimens.miniCoverSize, withShadow: false),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onTap,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DSText(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        DSText.assistant(
                          song.artist ?? '未知艺术家',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                _IconBtn(
                  icon: playerState.playing
                      ? CupertinoIcons.pause_fill
                      : CupertinoIcons.play_fill,
                  onTap: () async {
                    final h = ref.read(audioHandlerProvider);
                    if (playerState.playing) {
                      await h.pause();
                    } else {
                      await h.play();
                    }
                    ref.read(playerStateProvider.notifier).setPlaying(!playerState.playing);
                  },
                ),
                _IconBtn(
                  icon: CupertinoIcons.forward_fill,
                  onTap: () async {
                    ref.read(playerStateProvider.notifier).next();
                    final h = ref.read(audioHandlerProvider);
                    await h.skipToNext();
                  },
                ),
                // 网络类型指示（蜂窝时显示"流量"标签提醒用户）
                const _NetBadge(),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 网络类型小徽章：WiFi 时不显示，蜂窝时显示"流量"提示
class _NetBadge extends StatelessWidget {
  const _NetBadge();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<NetType>(
      stream: networkTypeWatcher.stream,
      initialData: networkTypeWatcher.current,
      builder: (_, snap) {
        final type = snap.data ?? NetType.unknown;
        if (type == NetType.wifi || type == NetType.ethernet || type == NetType.vpn) {
          return const SizedBox.shrink();
        }
        if (type == NetType.none) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(CupertinoIcons.wifi_slash, size: 16, color: AppColors.textAssistantDark),
          );
        }
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: _Chip(text: '流量'),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.18),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DSText.assistant(text, style: const TextStyle(
        color: AppColors.accent,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      )),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 56,
        child: Icon(icon, size: 22, color: AppColors.textPrimaryDark),
      ),
    );
  }
}
