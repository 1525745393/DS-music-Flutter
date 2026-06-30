import 'package:flutter/cupertino.dart';
import 'package:flutter/physics.dart';

/// 通用滑动反馈包装：
/// - [onSwipeLeft] / [onSwipeRight]：水平滑动触发切歌
/// - [onDismiss]  下滑超过阈值后触发关闭；用 [DismissController] 暴露程序化关闭
///
/// 设计原因：原生 Dismissible 只能 dismiss 后销毁，无法精细控制阈值与回落动画；
/// 这里手写一个带弹性回弹的 SwipeToDismiss。
class SwipeToDismiss extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final DismissDirectionCallback? onDismiss;
  final DismissController? controller;

  /// 触发水平切歌的滑动距离（逻辑像素，默认 80）
  final double swipeThreshold;

  /// 触发关闭的下滑距离阈值
  final double dismissThreshold;

  const SwipeToDismiss({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onDismiss,
    this.controller,
    this.swipeThreshold = 80,
    this.dismissThreshold = 140,
  });

  @override
  State<SwipeToDismiss> createState() => _SwipeToDismissState();
}

typedef DismissDirectionCallback = void Function(DismissDirection dir);

enum DismissDirection { up, down }

class DismissController {
  _SwipeToDismissState? _state;
  void _attach(_SwipeToDismissState s) => _state = s;
  void _detach(_SwipeToDismissState s) {
    if (identical(_state, s)) _state = null;
  }

  /// 程序化触发下滑关闭动画
  void dismiss([DismissDirection dir = DismissDirection.down]) {
    _state?._programmaticDismiss(dir);
  }
}

class _SwipeToDismissState extends State<SwipeToDismiss>
    with TickerProviderStateMixin {
  late AnimationController _hCtrl; // 水平回弹
  late AnimationController _vCtrl; // 垂直回弹 / 关闭
  Offset _offset = Offset.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _hCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        setState(() {
          _offset = Offset(_hCtrl.value, _offset.dy);
        });
      });
    _vCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addListener(() {
        setState(() {
          _offset = Offset(_offset.dx, _vCtrl.value);
        });
      });
    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(covariant SwipeToDismiss old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?._detach(this);
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _hCtrl.dispose();
    _vCtrl.dispose();
    super.dispose();
  }

  void _programmaticDismiss(DismissDirection dir) {
    _vCtrl.stop();
    _vCtrl.value = 0;
    _animateDismiss(dir, from: 0);
  }

  void _onPanStart(DragStartDetails d) {
    _isDragging = true;
    _hCtrl.stop();
    _vCtrl.stop();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() {
      // 水平：左右不限；垂直：仅允许下滑
      _offset = Offset(
        _offset.dx + d.delta.dx,
        (_offset.dy + d.delta.dy).clamp(0.0, double.infinity),
      );
    });
  }

  void _onPanEnd(DragEndDetails d) {
    _isDragging = false;
    final vx = d.velocity.pixelsPerSecond.dx;
    final vy = d.velocity.pixelsPerSecond.dy;
    final dx = _offset.dx;
    final dy = _offset.dy;
    // 1) 关闭判定：下滑距离或速度超过阈值
    if (dy > widget.dismissThreshold || vy > 800) {
      _animateDismiss(DismissDirection.down);
      return;
    }
    // 2) 水平切歌
    if (dx > widget.swipeThreshold || vx > 600) {
      _animateHorizontal(true);
      widget.onSwipeRight?.call();
      return;
    }
    if (dx < -widget.swipeThreshold || vx < -600) {
      _animateHorizontal(false);
      widget.onSwipeLeft?.call();
      return;
    }
    // 3) 回弹
    _hCtrl.stop();
    _vCtrl.stop();
    _hCtrl.value = _offset.dx;
    _vCtrl.value = _offset.dy;
    _hCtrl.animateTo(0, curve: Curves.easeOutCubic);
    _vCtrl.animateTo(0, curve: Curves.easeOutCubic);
  }

  void _animateHorizontal(bool toRight) {
    _hCtrl.stop();
    final target = toRight ? 1.0 : -1.0;
    _hCtrl.value = _offset.dx;
    _hCtrl.animateWith(SpringSimulation(
      const SpringDescription(mass: 1, stiffness: 220, damping: 18),
      _offset.dx,
      target,
      0,
    ));
    // 切歌动画完成后回到 0
    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      _hCtrl.animateTo(0, duration: const Duration(milliseconds: 80));
    });
  }

  void _animateDismiss(DismissDirection dir, {double? from}) {
    _vCtrl.stop();
    _vCtrl.value = from ?? _offset.dy;
    final size = MediaQuery.of(context).size.height;
    _vCtrl
        .animateTo(
      size,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeIn,
    )
        .then((_) {
      if (!mounted) return;
      widget.onDismiss?.call(dir);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: Listenable.merge([_hCtrl, _vCtrl]),
        builder: (_, child) {
          // 关闭进行中：透明度随 y 衰减
          final opacity = (1.0 - (_offset.dy.abs() / 600.0)).clamp(0.0, 1.0);
          return Transform.translate(
            offset: _offset,
            child: Opacity(opacity: opacity, child: child),
          );
        },
        child: widget.child,
      ),
    );
  }
}
