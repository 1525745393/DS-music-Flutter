import 'package:permission_handler/permission_handler.dart';

/// 安卓权限工具：分级引导开启关键后台能力
class AppPermissions {
  AppPermissions._();

  /// 首次启动请求：通知 + 存储 + 忽略电池优化
  static Future<bool> requestStartupPermissions() async {
    final statuses = await Future.wait([
      Permission.notification.request(),
      Permission.storage.request(),
      Permission.ignoreBatteryOptimizations.request(),
    ]);
    return statuses.every((s) => s.isGranted || s.isLimited);
  }

  /// 请求悬浮窗权限（Android 13+ 行为变更）
  /// 当前未接入原生浮窗插件，返回 false 以触发 graceful degradation
  /// 后续接入 flutter_floatwing 时改为真实实现
  static Future<bool> requestOverlay() async {
    return false;
  }

  /// 外部存储媒体（Android 13+）
  static Future<bool> requestMediaAudio() async {
    final status = await Permission.audio.request();
    return status.isGranted || status.isLimited;
  }

  /// 申请所有必要权限（一次性引导）
  static Future<Map<String, bool>> requestAll() async {
    return {
      'notification':
          await Permission.notification.request().then((s) => s.isGranted),
      'storage': await Permission.storage.request().then((s) => s.isGranted),
      'battery': await Permission.ignoreBatteryOptimizations
          .request()
          .then((s) => s.isGranted),
      'overlay': await requestOverlay(),
      'mediaAudio': await requestMediaAudio(),
    };
  }
}
