import 'package:flutter/cupertino.dart';
import 'app_colors.dart';

/// 全局字号与字重，iOS 标准 SF Pro 体系
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'SF Pro';

  static const TextStyle largeTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
  );
  static const TextStyle title = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
  );
  static const TextStyle midTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle assistant = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle navTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle tabTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle songTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle songArtist = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle playerSong = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle playerArtist = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle lyricsActive = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryDark,
  );
  static const TextStyle lyricsInactive = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textAssistantDark,
  );
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
}
