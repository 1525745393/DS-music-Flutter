import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/song.dart';
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
              ],
            ),
          ),
        ],
      ),
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
