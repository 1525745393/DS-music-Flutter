import 'package:flutter/cupertino.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// 全局主题：浅色 + 深色，严格对齐 iOS 扁平化设计
class AppTheme {
  AppTheme._();

  static const String fontFamily = AppTextStyles.fontFamily;

  static CupertinoThemeData get dark {
    return const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.accent,
      scaffoldBackgroundColor: AppColors.darkBg,
      barBackgroundColor: AppColors.darkBg,
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.accent,
        textStyle: TextStyle(
          fontFamily: fontFamily,
          color: AppColors.textPrimaryDark,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.2,
        ),
        navTitleTextStyle: AppTextStyles.navTitle,
        navLargeTitleTextStyle: AppTextStyles.largeTitle,
        tabLabelTextStyle: AppTextStyles.tabTitle,
        actionTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: AppColors.accent,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static CupertinoThemeData get light {
    return const CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.accent,
      scaffoldBackgroundColor: AppColors.lightBg,
      barBackgroundColor: AppColors.lightBg,
      textTheme: CupertinoTextThemeData(
        primaryColor: AppColors.accent,
        textStyle: TextStyle(
          fontFamily: fontFamily,
          color: AppColors.textPrimaryLight,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        navTitleTextStyle: AppTextStyles.navTitle,
        navLargeTitleTextStyle: AppTextStyles.largeTitle,
        tabLabelTextStyle: AppTextStyles.tabTitle,
        actionTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: AppColors.accent,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 根据主题模式获取对应 ThemeData
  static CupertinoThemeData of(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }
}
