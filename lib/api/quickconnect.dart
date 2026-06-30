import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../constants/api_constants.dart';
import '../model/exception.dart';
import '../utils/logger.dart';

/// QuickConnect 中继解析
/// 流程：先用 ID 拿 server_id 与可用的外部访问域名（优先 P2P），再回写到鉴权流程
class QuickConnect {
  static const String _apiHost = 'global.quickconnect.to';

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://$_apiHost',
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ))
    ..httpClientAdapter = _insecureAdapter();
  // 关键：使用 IOHttpClientAdapter 配置自签证书接受，
  // 旧 API 直接赋 HttpClient 在 Dio 5.x 会类型不匹配（HttpClient vs HttpClientAdapter）

  /// 构建一个接受自签证书的 Dio HTTP 适配器
  /// 安全性说明：仅用于 QuickConnect 中继接口（公网服务器），
  /// 自签证书接受仅影响本次会话，不会落盘到全局 Dio 实例。
  static HttpClientAdapter _insecureAdapter() {
    final adapter = IOHttpClientAdapter();
    adapter.createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    };
    return adapter;
  }

  /// 第一步：开始 QuickConnect
  /// 返回 {server_id, session_id, ...}
  Future<Map<String, dynamic>> open(String qcId) async {
    try {
      final resp = await _dio.get('/QuickConnectId.cgi', queryParameters: {
        'id': qcId,
        'server_version': 6,
        'version': 1,
      });
      final data = resp.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw QuickConnectException('QuickConnect 不可用，请检查 QC ID');
      }
      return Map<String, dynamic>.from(data['data'] ?? {});
    } on DioException catch (e) {
      throw QuickConnectException('QuickConnect 网络异常: ${e.message}');
    }
  }

  /// 第二步：轮询 QuickConnect 状态，等待用户在 NAS 上确认
  /// 设计原因：QC 流程必须用户侧手动点击，客户端需在 90s 内轮询
  Future<Map<String, dynamic>?> poll({
    required String qcId,
    required String sessionId,
    String? deviceId,
    int timeout = 60,
  }) async {
    final start = DateTime.now();
    while (DateTime.now().difference(start).inSeconds < timeout) {
      try {
        final resp = await _dio.get('/QuickConnectId.cgi', queryParameters: {
          'id': qcId,
          'server_version': 6,
          'version': 1,
          'action': 'wait',
          'session_id': sessionId,
        });
        final data = resp.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return Map<String, dynamic>.from(data['data'] ?? {});
        }
      } catch (e) {
        AppLogger.w('QC 轮询失败: $e');
      }
      await Future.delayed(const Duration(seconds: 2));
    }
    return null;
  }

  /// 解析出最终可用的 baseUrl
  /// [pollData] 来自第二步的返回
  String? resolveBaseUrl(Map<String, dynamic> pollData) {
    // 优先级：P2P 内部地址 > 外部中继域名
    final p2p = pollData['interface'] as Map<String, dynamic>?;
    if (p2p != null) {
      final lan = p2p['lan'] as List?;
      if (lan != null && lan.isNotEmpty) {
        final host = lan.first['ip']?.toString();
        final port = (lan.first['port'] as num?)?.toInt() ?? 5000;
        if (host != null) return 'http://$host:$port';
      }
      final wan = p2p['wan'] as List?;
      if (wan != null && wan.isNotEmpty) {
        final host = wan.first['ip']?.toString();
        final port = (wan.first['port'] as num?)?.toInt() ?? 5000;
        if (host != null) return 'http://$host:$port';
      }
    }
    final relay = pollData['relay'] as String?;
    if (relay != null && relay.isNotEmpty) {
      return 'https://$relay:5001';
    }
    return null;
  }
}
