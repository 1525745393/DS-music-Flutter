/// 应用全局常量
class AppConstants {
  AppConstants._();

  static const String appName = 'DS Player';
  static const String appVersion = '1.0.0';

  // —— 播放模式 ——
  static const int loopNone = 0;
  static const int loopOne = 1;
  static const int loopAll = 2;

  // —— 传输质量 ——
  static const int qualityOriginal = 0; // 原始码流
  static const int qualityHigh = 1; // 320k MP3
  static const int qualityMedium = 2; // 192k
  static const int qualityLow = 3; // 128k

  // —— 睡眠定时（分钟） ——
  static const List<int> sleepOptions = [10, 30, 60, 120];

  // —— 播放速度 ——
  static const double minSpeed = 0.5;
  static const double maxSpeed = 2.0;
  static const double defaultSpeed = 1.0;

  // —— 转码 ——
  static const String transcodeMp3 = 'mp3';
  static const int transcodeBitrate = 320000;
  static const int transcodeSampleRate = 44100;

  // —— 预缓冲秒数（外网/弱网提前缓冲下一首的前30秒） ——
  static const int preloadSeconds = 30;
  static const int bufferThresholdSec = 10;

  // —— 歌词显示 ——
  static const int lyricDefaultFontSize = 16;
  static const int lyricLineSpacing = 12;

  // —— UI 动画 ——
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration playerTransition = Duration(milliseconds: 350);
  static const Duration coverFade = Duration(milliseconds: 300);
  static const Duration btnPress = Duration(milliseconds: 100);
}
