import 'package:flutter/cupertino.dart';
import '../../model/album.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_text_styles.dart';
import '../cards/cover_image.dart';

/// 网格项：2列专辑卡
class AlbumGridItem extends StatelessWidget {
  final Album album;
  final String? coverUrl;
  final VoidCallback? onTap;

  const AlbumGridItem({
    super.key,
    required this.album,
    this.coverUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CoverImage(
            url: coverUrl,
            size: AppDimens.albumCardSize,
            withShadow: true,
          ),
          const SizedBox(height: 8),
          Text(
            album.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.midTitle,
          ),
          const SizedBox(height: 2),
          Text(
            album.artist ?? '未知艺术家',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.songArtist,
          ),
        ],
      ),
    );
  }
}
