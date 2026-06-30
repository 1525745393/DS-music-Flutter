import 'package:flutter/cupertino.dart';
import '../theme/app_dimens.dart';

/// 断点（对齐 Material 规范）
enum DeviceClass { compact, medium, expanded, large }

class Breakpoints {
  static const double compact = 600;     // 手机竖屏
  static const double medium = 840;      // 平板/折叠屏展开
  static const double expanded = 1200;   // 桌面/大屏平板
}

/// 根据宽度判断设备类型
DeviceClass deviceClassOf(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  if (w < Breakpoints.compact) return DeviceClass.compact;
  if (w < Breakpoints.medium) return DeviceClass.medium;
  if (w < Breakpoints.expanded) return DeviceClass.expanded;
  return DeviceClass.large;
}

/// 响应式工具：返回当前断点下的最佳值
class Responsive {
  final BuildContext context;
  Responsive(this.context);

  DeviceClass get deviceClass => deviceClassOf(context);

  double get width => MediaQuery.of(context).size.width;
  double get height => MediaQuery.of(context).size.height;

  /// 网格列数：手机 2 / 中屏 3 / 平板 4 / 大屏 5-6
  int get albumGridColumns {
    switch (deviceClass) {
      case DeviceClass.compact:
        return 2;
      case DeviceClass.medium:
        return 3;
      case DeviceClass.expanded:
        return 4;
      case DeviceClass.large:
        return 5;
    }
  }

  /// 专辑卡片边长
  double get albumCardSize {
    final cols = albumGridColumns;
    final spacing = AppDimens.itemSpacing * (cols - 1);
    return (width - spacing - AppDimens.pagePaddingH * 2) / cols;
  }

  /// 平板模式：是否使用左右双栏
  bool get isTablet => deviceClass != DeviceClass.compact;

  /// 是否横屏（width > height）
  bool get isLandscape {
    final size = MediaQuery.of(context).size;
    return size.width > size.height;
  }

  /// 横屏 + 平板：使用 split 布局
  bool get isWideLayout => isTablet && isLandscape;

  /// Player 封面尺寸：手机端较大（占满宽度），平板端固定 360
  double get playerCoverSize {
    if (isWideLayout) return 360;
    if (isTablet) return 420;
    return AppDimens.playerCoverSize;
  }

  /// 玩家信息最大宽度（横屏时限制在 480，居中显示）
  double get playerMaxContentWidth {
    if (isWideLayout) return 480;
    return double.infinity;
  }
}
