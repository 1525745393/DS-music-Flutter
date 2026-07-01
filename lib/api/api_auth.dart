import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../model/exception.dart';
import '../utils/logger.dart';
import 'api_info.dart';
import 'dio_client.dart';

/// SYNO.API.Auth 登录封装
class ApiAuth {
  final Dio _dio;
  final ApiInfo _apiInfo;
  final DioClient _client;

  ApiAuth(this._dio, this._apiInfo, this._client);

  /// 登录获取 SID
  /// 完整流程：先通过 SYNO.API.Info 获取接口版本，再调用 SYNO.API.Auth 执行登录
  /// 所有 SYNO. 接口统一走 entry.cgi 入口
  Future<String> login({
    required String account,
    required String passwd,
    String? otpCode,
    String? deviceId,
  }) async {
    final version = await _apiInfo.getMaxVersion(ApiConstants.apiAuth);

    try {
      final resp = await _dio.get(ApiConstants.entryPath, queryParameters: {
        'api': ApiConstants.apiAuth,
        'version': version,
        'method': 'login',
        'account': account,
        'passwd': passwd,
        if (otpCode != null) 'otp_code': otpCode,
        'device_id':
            deviceId ?? _client.dio.options.headers['Device-Id'] ?? 'ds-player',
        'format': 'sid',
        'session': 'AudioStation',
        'enable_device_token': 'yes',
      });
      final data = resp.data as Map<String, dynamic>;
      if (data['success'] != true) {
        final code = data['error']?['code'];
        if (code == 403) throw AppException('账号或密码错误');
        if (code == 404) throw AppException('账号不存在');
        if (code == 406) throw AppException('需要双重认证码');
        if (code == 407) throw AppException('设备未授权，请在群晖后台允许此设备');
        throw AppException('登录失败 (code=$code)');
      }
      final sid = data['data']?['sid'] as String?;
      if (sid == null || sid.isEmpty) throw AppException('未获取到 SID');
      _client.sid = sid;
      return sid;
    } on DioException catch (e) {
      AppLogger.e('Auth 失败', e);
      throw DioClient.mapError(e);
    }
  }

  /// 注销 SID
  Future<void> logout() async {
    final sid = _client.sid;
    if (sid == null) return;
    try {
      final version = await _apiInfo.getMaxVersion(ApiConstants.apiAuth);
      await _dio.get(ApiConstants.entryPath, queryParameters: {
        'api': ApiConstants.apiAuth,
        'version': version,
        'method': 'logout',
        '_sid': sid,
        'session': 'AudioStation',
      });
    } catch (e) {
      AppLogger.w('logout 失败（已忽略）: $e');
    } finally {
      _client.sid = null;
    }
  }
}
