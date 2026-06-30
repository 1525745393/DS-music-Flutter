import 'package:flutter/foundation.dart';
import '../model/lyrics.dart';
import '../model/song.dart';

/// 状态栏悬浮歌词控制器（桩实现）
///
/// 设计说明：
/// 1. 原计划使用 system_overlay_window 在 Android 系统层绘制浮窗，
///    但该包在 pub.dev 上不存在。
/// 2. 后续可接 flutter_floatwing 或自研 Kotlin 浮窗 Service
///    完整还原"桌面歌词"功能。
/// 3. 当前所有方法为 no-op，UI 层调用不会崩溃，状态统一为"未显示"。
class OverlayLyricsController {
  OverlayLyricsController._();
  static final OverlayLyricsController instance = OverlayLyricsController._();

  bool _isShowing = false;

  /// 当前是否已显示
  bool get isShowing => _isShowing;

  /// 显示悬浮歌词
  /// 当前为桩实现，永久返回 false（功能未启用）
  Future<bool> show(Song song, Lyrics lyrics) async {
    if (kIsWeb) return false; // Web 不支持
    return false;
  }

  /// 关闭悬浮歌词
  Future<void> hide() async {
    _isShowing = false;
  }

  /// 更新悬浮窗显示的歌词
  /// [position] 当前播放位置
  /// 当前为桩实现，直接返回
  Future<void> updatePosition(Duration position) async {
    // no-op
  }

  /// 调节悬浮窗字号
  Future<void> setFontSize(double size) async {
    // no-op
  }

  /// 重置浮窗位置
  Future<void> resetPosition() async {
    // no-op
  }
}
