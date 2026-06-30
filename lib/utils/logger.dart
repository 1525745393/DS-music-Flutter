import 'package:flutter/foundation.dart';

/// 轻量日志器，发布模式自动静默
class AppLogger {
  static const String _tag = 'DSPlayer';

  static void d(Object? msg) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[$_tag][D] $msg');
    }
  }

  static void i(Object? msg) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[$_tag][I] $msg');
    }
  }

  static void w(Object? msg) {
    // ignore: avoid_print
    print('[$_tag][W] $msg');
  }

  static void e(Object? msg, [Object? err, StackTrace? st]) {
    // ignore: avoid_print
    print('[$_tag][E] $msg err=$err');
    if (err != null && kDebugMode) {
      // ignore: avoid_print
      print(err);
      if (st != null) {
        // ignore: avoid_print
        print(st);
      }
    }
  }
}
