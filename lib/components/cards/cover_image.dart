import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import '../../model/song.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../ds_text.dart';

/// 通用封面组件：支持网络 / 占位 / 圆角 / 阴影
class CoverImage extends StatelessWidget {
  final String? url;
  final double size;
  final double radius;
  final bool withShadow;
  final Song? song;

  const CoverImage({
    super.key,
    this.url,
    this.size = AppDimens.albumCardSize,
    this.radius = AppDimens.radiusLarge,
    this.withShadow = true,
    this.song,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: brightness == Brightness.dark
            ? AppColors.darkElevated
            : AppColors.lightElevated,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        CupertinoIcons.music_note,
        size: size * 0.3,
        color: AppColors.textAssistantDark,
      ),
    );
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url == null
          ? placeholder
          : CachedNetworkImage(
              imageUrl: url!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 200),
              placeholder: (_, __) => placeholder,
              errorWidget: (_, __, ___) => placeholder,
            ),
    );
    if (!withShadow) return image;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: AppDimens.shadowBlur,
            offset: const Offset(0, AppDimens.shadowYOffset),
          ),
        ],
      ),
      child: image,
    );
  }
}
