import 'package:flutter/cupertino.dart';

/// iOS 扁平化设计色板
/// 深色为默认主题，浅色对应同步呈现
class AppColors {
  AppColors._();

  // —— 深色主题 ——
  static const Color darkBg = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkElevated = Color(0xFF2A2A2A);
  static const Color darkDivider = Color(0xFF2C2C2C);

  // —— 浅色主题 ——
  static const Color lightBg = Color(0xFFF2F2F7);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightElevated = Color(0xFFFFFFFF);
  static const Color lightDivider = Color(0xFFE5E5EA);

  // —— 强调色（iOS 系统蓝） ——
  static const Color accent = Color(0xFF007AFF);
  static const Color accentLight = Color(0xFF4DA3FF);

  // —— 文字层级 - 深色 ——
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xE0E0E0); // 87%
  static const Color textAssistantDark = Color(0x9E9E9E); // 60%
  static const Color textDisabledDark = Color(0x616161); // 38%

  // —— 文字层级 - 浅色 ——
  static const Color textPrimaryLight = Color(0xFF000000);
  static const Color textSecondaryLight = Color(0x3C3C43);
  static const Color textAssistantLight = Color(0x8E8E93);
  static const Color textDisabledLight = Color(0xC7C7CC);

  // —— 功能色 ——
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color danger = Color(0xFFFF3B30);

  // —— 毛玻璃色 ——
  static Color glassDark = const Color(0xFFFFFFFF).withOpacity(0.10);
  static Color glassLight = const Color(0xFFFFFFFF).withOpacity(0.65);

  // —— 阴影色 ——
  static Color shadowDark = const Color(0xFF000000).withOpacity(0.20);

  // —— 蒙层色 ——
  static Color maskDark = const Color(0xFF000000).withOpacity(0.70);
  static Color maskLight = const Color(0xFF000000).withOpacity(0.35);
}
