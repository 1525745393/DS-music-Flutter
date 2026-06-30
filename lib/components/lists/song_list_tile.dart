import 'package:flutter/cupertino.dart';
import '../../model/song.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_text_styles.dart';
import '../cards/cover_image.dart';
import '../ds_text.dart';

/// 歌曲列表项：行高 48px，包含歌名、艺术家、时长
/// 可选参数：
/// - [trailing] 自定义右侧尾随区域（覆盖默认时长 + 更多按钮），常用于评分星星
/// - [showAlbum] 是否在副标题中展示专辑名（与艺术家并用 `·` 分隔）
class SongListTile extends StatelessWidget {
  final Song song;
  final String? coverUrl;
  final VoidCallback? onTap;
  final VoidCallback? onMore;
  final bool highlighted;
  final bool showCover;
  final bool showAlbum;
  final Widget? trailing;

  const SongListTile({
    super.key,
    required this.song,
    this.coverUrl,
    this.onTap,
    this.onMore,
    this.highlighted = false,
    this.showCover = true,
    this.showAlbum = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.pagePaddingH,
          vertical: AppDimens.listItemVPadding,
        ),
        child: Row(
          children: [
            if (showCover) ...[
              CoverImage(
                  url: coverUrl,
                  size: AppDimens.listCoverSize,
                  withShadow: false),
              const SizedBox(width: AppDimens.itemSpacing),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.songTitle.copyWith(
                      color: highlighted ? AppColors.accent : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [song.artist, if (showAlbum) song.album]
                        .whereType<String>()
                        .join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.songArtist,
                  ),
                ],
              ),
            ),
            // 右侧：自定义 trailing 优先；否则默认显示时长 + 更多按钮
            if (trailing != null)
              trailing!
            else ...[
              const SizedBox(width: 8),
              Text(song.durationText, style: AppTextStyles.songArtist),
              if (onMore != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onMore,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(CupertinoIcons.ellipsis,
                        size: 18, color: AppColors.textAssistantDark),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
