import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../ds_text.dart';

/// iOS 风格按钮：透明度反馈，无波纹
class DSButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool primary;
  final bool fullWidth;
  final double height;
  final double radius;
  final IconData? leadingIcon;
  final bool loading;

  const DSButton({
    super.key,
    required this.text,
    this.onPressed,
    this.primary = true,
    this.fullWidth = false,
    this.height = AppDimens.formHeight,
    this.radius = AppDimens.radiusMedium,
    this.leadingIcon,
    this.loading = false,
  });

  @override
  State<DSButton> createState() => _DSButtonState();
}

class _DSButtonState extends State<DSButton> {
  double _opacity = 1.0;

  void _down(_) => setState(() => _opacity = 0.7);
  void _up(_) => setState(() => _opacity = 1.0);
  void _cancel() => setState(() => _opacity = 1.0);

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final disabled = widget.onPressed == null || widget.loading;
    final bg = widget.primary
        ? AppColors.accent
        : (brightness == Brightness.dark
            ? AppColors.darkElevated
            : AppColors.lightElevated);
    final fg = widget.primary
        ? CupertinoColors.white
        : (brightness == Brightness.dark
            ? AppColors.textPrimaryDark
            : AppColors.textPrimaryLight);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 100),
      opacity: _opacity,
      child: GestureDetector(
        onTapDown: disabled ? null : _down,
        onTapUp: disabled ? null : _up,
        onTapCancel: _cancel,
        onTap: disabled ? null : widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: widget.fullWidth ? double.infinity : null,
          height: widget.height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
          child: widget.loading
              ? CupertinoActivityIndicator(color: fg)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.leadingIcon != null) ...[
                      Icon(widget.leadingIcon, color: fg, size: 18),
                      const SizedBox(width: 6),
                    ],
                    DSText(
                      widget.text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.white,
                      ).copyWith(color: fg),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
