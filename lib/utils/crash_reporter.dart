import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'logger.dart';

/// 崩溃上报与性能监控
/// 设计原因：
/// - 真实项目中对接 Sentry/Firebase Crashlytics/Bugly
/// - 此处先做轻量本地记录 + 异步上报占位
class CrashReporter {
  CrashReporter._();
  static final CrashReporter instance = CrashReporter._();

  bool _initialized = false;
  final List<_PendingCrash> _queue = [];
  void Function(Map<String, dynamic> report)? _uploader;

  /// 初始化：捕获 Flutter / Platform 异常与未处理的异步错误
  void init({void Function(Map<String, dynamic> report)? uploader}) {
    if (_initialized) return;
    _initialized = true;
    _uploader = uploader;

    // Flutter 框架错误
    FlutterError.onError = (FlutterErrorDetails details) {
      _report(
        type: 'flutter',
        message: details.exceptionAsString(),
        stack: details.stack,
        library: details.library ?? '',
        context: details.context?.toString() ?? '',
      );
      // 同时打到控制台
      FlutterError.presentError(details);
    };

    // 未捕获的异步错误
    PlatformDispatcher.instance.onError = (error, stack) {
      _report(type: 'async', message: error.toString(), stack: stack);
      return true;
    };

    AppLogger.i('CrashReporter 已初始化');
  }

  /// 手动上报业务错误
  void reportError(Object error, StackTrace? stack, {String? tag}) {
    _report(type: 'manual', message: '$tag: $error', stack: stack);
  }

  void _report({
    required String type,
    required String message,
    StackTrace? stack,
    String library = '',
    String context = '',
  }) {
    final report = {
      'type': type,
      'message': message,
      'library': library,
      'context': context,
      'stack': stack?.toString() ?? '',
      'ts': DateTime.now().toIso8601String(),
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
    };
    if (kDebugMode) {
      AppLogger.e('崩溃上报[$type]', message, stack);
    }
    if (_uploader == null) {
      _queue.add(_PendingCrash(report, DateTime.now()));
    } else {
      try {
        _uploader!(report);
      } catch (e) {
        _queue.add(_PendingCrash(report, DateTime.now()));
      }
    }
  }

  /// 读取当前未上报队列（调试用）
  List<_PendingCrash> pending() => List.unmodifiable(_queue);

  /// 标记所有项已上报
  void clearPending() => _queue.clear();
}

class _PendingCrash {
  final Map<String, dynamic> report;
  final DateTime ts;
  _PendingCrash(this.report, this.ts);
}

/// 性能监控：简单打点（FP/FCP/页面停留时长）
class PerfMonitor {
  PerfMonitor._();
  static final PerfMonitor instance = PerfMonitor._();

  final Map<String, DateTime> _markers = {};

  /// 标记起点
  void start(String key) => _markers[key] = DateTime.now();

  /// 标记终点并打点（毫秒）
  int? end(String key, {String? tag}) {
    final start = _markers.remove(key);
    if (start == null) return null;
    final ms = DateTime.now().difference(start).inMilliseconds;
    if (kDebugMode) {
      AppLogger.i('Perf[$tag ?? key] ${ms}ms');
    }
    return ms;
  }

  /// 包装一个 Future 自动打点耗时
  Future<T> track<T>(String key, Future<T> Function() task, {String? tag}) async {
    start(key);
    try {
      return await task();
    } finally {
      end(key, tag: tag);
    }
  }
}
