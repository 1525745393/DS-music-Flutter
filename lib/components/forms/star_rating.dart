import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';

/// 星级评分输入组件（0-5）
/// 设计原因：原生 CupertinoSlider 不适合选星；点击/拖动均可
class StarRating extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double size;
  final Color color;

  const StarRating({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 18,
    this.color = AppColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final idx = i + 1;
        final filled = idx <= value;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(value == idx ? 0 : idx), // 再点一次取消评分
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              filled ? CupertinoIcons.star_fill : CupertinoIcons.star,
              size: size,
              color: filled ? color : AppColors.textAssistantDark,
            ),
          ),
        );
      }),
    );
  }
}
