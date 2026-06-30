import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_text_styles.dart';

/// iOS 风格 TabBar：选中态底部 2px 强调色下划线
class DSTabBar extends StatelessWidget {
  final List<String> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final double height;

  const DSTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
    this.height = AppDimens.tabBarHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.pagePaddingH),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 24),
        itemBuilder: (_, i) => _TabItem(
          label: tabs[i],
          selected: i == currentIndex,
          onTap: () => onTap(i),
        ),
      ),
    );
  }
}

class _TabItem extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_TabItem> createState() => _TabItemState();
}

class _TabItemState extends State<_TabItem> {
  double _opacity = 1.0;

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.brightnessOf(context);
    final color = widget.selected
        ? AppColors.accent
        : (brightness == Brightness.dark
            ? AppColors.textAssistantDark
            : AppColors.textAssistantLight);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _opacity = 0.7),
      onTapUp: (_) => setState(() => _opacity = 1.0),
      onTapCancel: () => setState(() => _opacity = 1.0),
      onTap: widget.onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _opacity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.label,
              style: AppTextStyles.tabTitle.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: widget.selected ? 20 : 0,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
