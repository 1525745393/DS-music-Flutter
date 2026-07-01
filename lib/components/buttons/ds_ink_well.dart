import 'package:flutter/cupertino.dart';

/// iOS 风格点击反馈组件
/// 设计原因：需求规范要求「点击反馈为透明度70%，无波纹」，
/// 替代 Material InkWell 的水波纹效果，实现 iOS 扁平化的透明度变化
class DSInkWell extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;
  final bool enabled;

  const DSInkWell({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.enabled = true,
  });

  @override
  State<DSInkWell> createState() => _DSInkWellState();
}

class _DSInkWellState extends State<DSInkWell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  // 透明度动画：100% → 70% → 100%，时长100ms
  static const double _pressedOpacity = 0.70;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 1.0,
      upperBound: _pressedOpacity,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.enabled) _controller.reverse();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.forward();
  }

  void _onTapCancel() {
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: FadeTransition(
        opacity: _controller,
        child: widget.child,
      ),
    );
  }
}
