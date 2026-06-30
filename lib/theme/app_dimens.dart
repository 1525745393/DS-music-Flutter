/// 全局尺寸与圆角规范
class AppDimens {
  AppDimens._();

  // —— 圆角 ——
  static const double radiusLarge = 16;  // 封面、卡片
  static const double radiusMedium = 10; // 按钮、弹窗
  static const double radiusSmall = 4;   // 标签、小元素
  static const double radiusCircle = 999;

  // —— 间距 ——
  static const double pagePaddingH = 16;
  static const double itemSpacing = 12;
  static const double listItemVPadding = 10;
  static const double groupSpacing = 20;

  // —— 通用高度 ——
  static const double formHeight = 48;
  static const double navBarHeight = 44;
  static const double tabBarHeight = 40;
  static const double miniPlayerHeight = 56;
  static const double listItemHeight = 48;
  static const double playButtonSize = 56;
  static const double controlIconSize = 32;
  static const double smallIconSize = 24;

  // —— 阴影 ——
  static const double shadowBlur = 8;
  static const double shadowYOffset = 2;
  static const double shadowOpacity = 0.20;

  // —— 毛玻璃 ——
  static const double glassBlur = 10;
  static const double glassOpacity = 0.10;

  // —— 进度条 ——
  static const double progressBarHeight = 3;
  static const double progressBarThumb = 12;

  // —— 专辑封面 ——
  static const double albumCardSize = 168;
  static const double listCoverSize = 48;
  static const double miniCoverSize = 40;
  static const double playerCoverOffset = 80;
  static const double playerCoverSize = 280;
}
