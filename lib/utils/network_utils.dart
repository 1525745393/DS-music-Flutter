import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

/// 网络工具：判断 WiFi / 蜂窝 / 无网 / 仅内网
class NetworkUtils {
  NetworkUtils._();

  /// 当前连接类型列表
  static Future<List<ConnectivityResult>> current() async {
    try {
      final r = await Connectivity().checkConnectivity();
      return List<ConnectivityResult>.from(r);
    } catch (_) {
      return [ConnectivityResult.none];
    }
  }

  static Future<bool> isOnline() async {
    final r = await current();
    return r.any((e) => e != ConnectivityResult.none);
  }

  /// WiFi 环境下走原始码流，蜂窝环境走转码
  static Future<bool> isWifi() async {
    final r = await current();
    return r.contains(ConnectivityResult.wifi);
  }

  static Future<bool> isMobile() async {
    final r = await current();
    return r.contains(ConnectivityResult.mobile);
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
