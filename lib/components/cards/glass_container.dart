import 'dart:ui';
import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';

/// 毛玻璃容器
/// 全局统一使用：白色 10% 透明 + 模糊度 10
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blur;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = AppDimens.glassBlur,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final color = brightness == Brightness.dark
        ? AppColors.glassDark
        : AppColors.glassLight;
    final radius =
        borderRadius ?? BorderRadius.circular(AppDimens.radiusMedium);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          margin: margin,
          decoration: BoxDecoration(
            color: color,
            borderRadius: radius,
            border: Border.all(
              color: brightness == Brightness.dark
                  ? const Color(0xFFFFFFFF).withOpacity(0.06)
                  : const Color(0xFF000000).withOpacity(0.04),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
