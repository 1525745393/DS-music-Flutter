import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../model/exception.dart';
import '../utils/logger.dart';
import 'dio_client.dart';

/// SYNO.API.Info：动态获取接口路径与版本
/// 设计原因：群晖不同 DSM 版本接口路径会变化，必须先 query 再调用
class ApiInfo {
  final Dio _dio;
  ApiInfo(this._dio);

  Map<String, dynamic> _cache = {};

  /// 查询接口信息（带缓存）
  /// [name] 接口名，例如 SYNO.API.Auth
  /// 返回 {path, maxVersion, minVersion, ...}
  /// 注意：SYNO.API.Info 本身也走 entry.cgi 入口
  Future<Map<String, dynamic>> query(String name) async {
    if (_cache.containsKey(name)) return _cache[name]!;
    try {
      final resp = await _dio.get(ApiConstants.entryPath, queryParameters: {
        'api': 'SYNO.API.Info',
        'version': 1,
        'method': 'query',
        'query': name,
      });
      final data = resp.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw AppException('查询接口失败: $name');
      }
      _cache[name] = Map<String, dynamic>.from(data['data'] ?? {});
      return _cache[name]!;
    } on DioException catch (e) {
      AppLogger.e('API Info 失败: $name', e);
      throw DioClient.mapError(e);
    }
  }

  /// 获取接口路径（拼接完整的相对路径）
  Future<String> getPath(String name) async {
    final info = await query(name);
    return info['path'] as String? ?? '';
  }

  /// 兼容不同 DSM 版本：尝试以 maxVersion 起步，失败则降级
  Future<int> getMaxVersion(String name) async {
    final info = await query(name);
    return info['maxVersion'] as int? ?? 1;
  }

  void clearCache() => _cache.clear();
}
