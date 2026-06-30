import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

/// 网络工具：判断 WiFi / 蜂窝 / 无网 / 仅内网
class NetworkUtils {
  NetworkUtils._();

  /// 当前连接类型
  /// 关键：connectivity_plus 5.x 返回单值 ConnectivityResult，
  /// 不再返回 List<ConnectivityResult>
  static Future<ConnectivityResult> current() async {
    try {
      return await Connectivity().checkConnectivity();
    } catch (_) {
      return ConnectivityResult.none;
    }
  }

  static Future<bool> isOnline() async {
    final r = await current();
    return r != ConnectivityResult.none;
  }

  /// WiFi 环境下走原始码流，蜂窝环境走转码
  static Future<bool> isWifi() async {
    final r = await current();
    return r == ConnectivityResult.wifi;
  }

  static Future<bool> isMobile() async {
    final r = await current();
    return r == ConnectivityResult.mobile;
  }

  static Future<bool> isLanReachable(String host, int port,
      {Duration timeout = const Duration(seconds: 3)}) async {
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}
