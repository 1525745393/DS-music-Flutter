import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../utils/logger.dart';

/// 网络类型枚举
enum NetType { wifi, mobile, ethernet, vpn, none, unknown }

extension NetTypeX on NetType {
  /// 描述
  String get label {
    switch (this) {
      case NetType.wifi:
        return 'WiFi';
      case NetType.mobile:
        return '蜂窝网络';
      case NetType.ethernet:
        return '有线';
      case NetType.vpn:
        return 'VPN';
      case NetType.none:
        return '无网络';
      case NetType.unknown:
        return '未知';
    }
  }

  /// 是否为高带宽（应使用原始码流）
  bool get isHighBandwidth =>
      this == NetType.wifi || this == NetType.ethernet;
}

/// 网络状态监听器
/// 设计原因：决定播放时是原始码流还是转码
class NetworkTypeWatcher {
  final Connectivity _connectivity = Connectivity();
  final _controller = StreamController<NetType>.broadcast();
  NetType _current = NetType.unknown;

  /// 当前网络类型
  NetType get current => _current;

  /// 状态流（应用启动即可订阅）
  Stream<NetType> get stream => _controller.stream;

  NetworkTypeWatcher() {
    _init();
  }

  Future<void> _init() async {
    try {
      // 首次拉取
      final results = await _connectivity.checkConnectivity();
      _current = _mapResult(results);
      _controller.add(_current);
    } catch (e) {
      AppLogger.w('NetworkTypeWatcher 初始化失败: $e');
    }
    // 监听变化
    _connectivity.onConnectivityChanged.listen((results) {
      final next = _mapResult(results);
      if (next != _current) {
        _current = next;
        AppLogger.i('网络切换为: ${next.label}');
        _controller.add(next);
      }
    });
  }

  NetType _mapResult(List<ConnectivityResult> results) {
    if (results.isEmpty) return NetType.none;
    final primary = results.first;
    switch (primary) {
      case ConnectivityResult.wifi:
        return NetType.wifi;
      case ConnectivityResult.mobile:
        return NetType.mobile;
      case ConnectivityResult.ethernet:
        return NetType.ethernet;
      case ConnectivityResult.vpn:
        return NetType.vpn;
      case ConnectivityResult.none:
        return NetType.none;
      case ConnectivityResult.bluetooth:
      case ConnectivityResult.other:
        return NetType.unknown;
    }
  }

  void dispose() => _controller.close();
}

/// 全局单例
final networkTypeWatcher = NetworkTypeWatcher();

/// 调试模式标志
bool get isDebug => kDebugMode;
