import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_dimens.dart';

/// 统一文本样式
class DSText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextStyleType type;
  final Color? color;
  final int? maxLines;
  final TextAlign? textAlign;
  final TextOverflow? overflow;

  const DSText(
    this.text, {
    super.key,
    this.type = TextStyleType.body,
    this.color,
    this.maxLines,
    this.textAlign,
    this.overflow,
    this.style,
  });

  const DSText.largeTitle(
    this.text, {
    super.key,
    this.color,
    this.maxLines,
    this.textAlign,
    this.overflow,
    this.style,
  }) : type = TextStyleType.largeTitle;

  const DSText.title(
    this.text, {
    super.key,
    this.color,
    this.maxLines,
    this.textAlign,
    this.overflow,
    this.style,
  }) : type = TextStyleType.title;

  const DSText.body(
    this.text, {
    super.key,
    this.color,
    this.maxLines,
    this.textAlign,
    this.overflow,
    this.style,
  }) : type = TextStyleType.body;

  const DSText.assistant(
    this.text, {
    super.key,
    this.color,
    this.maxLines,
    this.textAlign,
    this.overflow,
    this.style,
  }) : type = TextStyleType.assistant;

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final base = _baseStyle(type, brightness);
    return Text(
      text,
      style: (style ?? base).copyWith(color: color ?? base.color),
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: overflow,
    );
  }

  TextStyle _baseStyle(TextStyleType t, Brightness b) {
    final isDark = b == Brightness.dark;
    final primary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final assistant = isDark ? AppColors.textAssistantDark : AppColors.textAssistantLight;
    switch (t) {
      case TextStyleType.largeTitle:
        return AppTextStyles.largeTitle.copyWith(color: primary);
      case TextStyleType.title:
        return AppTextStyles.title.copyWith(color: primary);
      case TextStyleType.midTitle:
        return AppTextStyles.midTitle.copyWith(color: primary);
      case TextStyleType.body:
        return AppTextStyles.body.copyWith(color: secondary);
      case TextStyleType.assistant:
        return AppTextStyles.assistant.copyWith(color: assistant);
      case TextStyleType.caption:
        return AppTextStyles.caption.copyWith(color: assistant);
    }
  }
}

enum TextStyleType { largeTitle, title, midTitle, body, assistant, caption }
