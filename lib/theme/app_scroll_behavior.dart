import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

/// 全局滚动行为：iOS 弹性阻尼滚动
/// 设计原因：需求规范要求「iOS弹性阻尼，无安卓边缘波纹」，
/// 通过自定义 ScrollBehavior 全局替换 Android 默认的 ClampingScrollPhysics
class AppScrollBehavior extends ScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // 全局使用 iOS 弹性滚动
    return const BouncingScrollPhysics(parent: RangeMaintainingScrollPhysics());
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };
}
