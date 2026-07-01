import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../constants/api_constants.dart';
import '../model/exception.dart';
import '../utils/logger.dart';

/// 全局 Dio 客户端
/// 关键点：
/// 1. 自签名证书支持（NAS 默认 HTTPS 自签）
/// 2. 统一错误码拦截：401 自动重登 / 403 弹窗 / 网络超时重试
/// 3. SID 自动从回调中注入
class DioClient {
  final String baseUrl;
  final Dio dio;
  String? _sid;
  // 401 触发重登的回调，由 AuthRepository 设置
  Future<bool> Function()? onUnauthorized;
  // 401 时是否已经触发过重登，避免无限递归
  bool _silentRetried = false;

  DioClient({required this.baseUrl})
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: ApiConstants.timeoutSeconds),
          sendTimeout: const Duration(seconds: ApiConstants.timeoutSeconds),
          receiveTimeout: const Duration(seconds: ApiConstants.timeoutSeconds),
          // 群晖 WebAPI 返回 200/101 等，业务错误以 success=false 表达
          validateStatus: (s) => s != null && s < 500,
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'DSPlayer/1.0 (Flutter)',
          },
        )) {
    _initInterceptor();
  }

  String? get sid => _sid;
  set sid(String? value) {
    _sid = value;
    // 换 SID 后允许再次尝试静默重登
    if (value != null) _silentRetried = false;
  }

  void _initInterceptor() {
    // 1. 自签名证书兼容
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient()
        ..badCertificateCallback = (cert, host, port) => true;
      return client;
    };

    // 2. 请求拦截：注入 _sid（带下划线，群晖规范参数名）
    // 登录请求（SYNO.API.Auth method=login）不注入，避免干扰
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_sid != null) {
          final api = options.queryParameters['api']?.toString();
          final method = options.queryParameters['method']?.toString();
          final isLogin = api == 'SYNO.API.Auth' && method == 'login';
          if (!isLogin) {
            options.queryParameters['_sid'] = _sid;
          }
        }
        AppLogger.d('→ ${options.method} ${options.uri}');
        handler.next(options);
      },
      onResponse: (resp, handler) {
        AppLogger.d('← ${resp.statusCode} ${resp.requestOptions.uri}');
        _checkBusinessError(resp.data);
        handler.next(resp);
      },
      onError: (err, handler) async {
        AppLogger.e('× ${err.requestOptions.uri}', err.message, err.stackTrace);
        if (_shouldRetry(err)) {
          try {
            final retry = await dio.fetch(err.requestOptions);
            handler.resolve(retry);
            return;
          } catch (_) {}
        }
        // 401/未授权：触发静默重登
        final code = err.response?.statusCode;
        if ((code == 401 || _isBusinessUnauthorized(err)) &&
            onUnauthorized != null &&
            !_silentRetried) {
          _silentRetried = true;
          try {
            final ok = await onUnauthorized!.call();
            if (ok) {
              // 重登成功后用新 SID 重放一次原请求
              final retry = await dio.fetch(err.requestOptions);
              handler.resolve(retry);
              return;
            }
          } catch (_) {}
        }
        handler.next(err);
      },
    ));
  }

  /// 业务错误识别：群晖接口在 HTTP 200 内通过 success/code 表达错误
  void _checkBusinessError(dynamic data) {
    if (data is! Map) return;
    final success = data['success'];
    if (success == true) return;
    final code = data['error']?['code'];
    switch (code) {
      case 105:
      case 106:
      case 119:
        throw UnauthorizedException(data['error']?['errors']?.toString());
      case 102:
        throw ForbiddenException();
    }
  }

  bool _shouldRetry(DioException err) {
    if (err.requestOptions.extra['retried'] == true) return false;
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      return true;
    }
    return false;
  }

  /// 业务层未授权：群晖 WebAPI 在 HTTP 200 内返回 error.code=105/106/119
  bool _isBusinessUnauthorized(DioException err) {
    final data = err.response?.data;
    if (data is Map) {
      final code = data['error']?['code'];
      return code == 105 || code == 106 || code == 119;
    }
    return false;
  }

  Future<Response<dynamic>> fetchRetry(RequestOptions options) async {
    options.extra['retried'] = true;
    return dio.fetch(options);
  }

  void close({bool force = false}) => dio.close(force: force);

  static AppException mapError(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const NetworkException('网络连接超时，请检查网络');
        case DioExceptionType.connectionError:
          return const NetworkException('无法连接到服务器');
        case DioExceptionType.badResponse:
          return AppException('服务器响应异常 (${e.response?.statusCode})');
        default:
          return AppException(e.message ?? '请求失败');
      }
    }
    if (e is AppException) return e;
    return AppException(e.toString());
  }
}
