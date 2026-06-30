import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:system_overlay_window/system_overlay_window.dart';
import '../model/lyrics.dart';
import '../model/song.dart';
import '../utils/logger.dart';

/// 状态栏悬浮歌词控制器
/// 设计说明：
/// 1. 使用 system_overlay_window 在 Android 系统层绘制浮窗，浮窗可拖动
/// 2. 歌词行由 Kotlin 原生层接收，绘制简单文字+背景
/// 3. 拖动位置/字号调节通过 MethodChannel 与原生通信
class OverlayLyricsController {
  OverlayLyricsController._();
  static final OverlayLyricsController instance = OverlayLyricsController._();

  static const _channel = MethodChannel('dsplayer/overlay_lyrics');
  bool _isShowing = false;
  Song? _currentSong;
  Lyrics? _currentLyrics;
  int _currentLineIndex = -1;
  Timer? _positionTimer;

  /// 当前是否已显示
  bool get isShowing => _isShowing;

  /// 显示悬浮歌词
  Future<bool> show(Song song, Lyrics lyrics) async {
    if (kIsWeb) return false; // Web 不支持
    try {
      final granted = await SystemOverlayWindow.isPermissionGranted();
      if (!granted) {
        final ok = await SystemOverlayWindow.requestPermission();
        if (!ok) {
          AppLogger.w('用户拒绝悬浮窗权限');
          return false;
        }
      }
      _currentSong = song;
      _currentLyrics = lyrics;
      _currentLineIndex = -1;
      await SystemOverlayWindow.showOverlay(
        height: 80,
        width: SystemOverlayWindow.matchParent,
        alignment: OverlayAlignment.bottomCenter,
        visibility: OverlayVisibility.visible,
        flag: OverlayFlag.defaultInt,
        overlayTitle: 'DS Player 悬浮歌词',
        enableDrag: true,
        positionGravity: PositionGravity.auto,
        startPosition: const OverlayPosition(0, 200),
      );
      _isShowing = true;
      return true;
    } catch (e) {
      AppLogger.e('显示悬浮窗失败', e);
      return false;
    }
  }

  /// 关闭悬浮歌词
  Future<void> hide() async {
    if (!_isShowing) return;
    try {
      await SystemOverlayWindow.closeOverlay();
      _isShowing = false;
      _currentSong = null;
      _currentLyrics = null;
      _currentLineIndex = -1;
    } catch (e) {
      AppLogger.e('关闭悬浮窗失败', e);
    }
  }

  /// 更新悬浮窗显示的歌词
  /// [position] 当前播放位置
  Future<void> updatePosition(Duration position) async {
    if (!_isShowing || _currentLyrics == null) return;
    final newIdx = _currentLyrics!.indexAt(position);
    if (newIdx == _currentLineIndex) return;
    _currentLineIndex = newIdx;
    try {
      // 上一句 + 当前 + 下一句
      final lines = _currentLyrics!.lines;
      final prev = newIdx > 0 ? lines[newIdx - 1].text : '';
      final cur = newIdx >= 0 ? lines[newIdx].text : '';
      final next = newIdx < lines.length - 1 ? lines[newIdx + 1].text : '';
      await _channel.invokeMethod('updateLyrics', {
        'title': _currentSong?.title ?? '',
        'artist': _currentSong?.artist ?? '',
        'prev': prev,
        'current': cur,
        'next': next,
      });
    } catch (e) {
      AppLogger.w('更新悬浮歌词失败: $e');
    }
  }

  /// 调节悬浮窗字号
  Future<void> setFontSize(double size) async {
    try {
      await _channel.invokeMethod('setFontSize', {'size': size});
    } catch (_) {}
  }

  /// 重置浮窗位置
  Future<void> resetPosition() async {
    try {
      await _channel.invokeMethod('resetPosition');
    } catch (_) {}
  }
}
