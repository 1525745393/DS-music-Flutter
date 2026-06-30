/// 统一业务异常
class AppException implements Exception {
  final int? code;
  final String message;
  final String? rawData;

  const AppException(this.message, {this.code, this.rawData});

  @override
  String toString() => 'AppException($code): $message';
}

/// 401 未登录
class UnauthorizedException extends AppException {
  const UnauthorizedException([String? message])
      : super(message ?? '登录已过期，请重新登录', code: 401);
}

/// 403 权限不足
class ForbiddenException extends AppException {
  const ForbiddenException([String? message])
      : super(message ?? '权限不足，请联系管理员', code: 403);
}

/// 网络错误
class NetworkException extends AppException {
  const NetworkException([String? message])
      : super(message ?? '网络异常，请检查网络设置', code: -1);
}

/// QuickConnect 失败
class QuickConnectException extends AppException {
  const QuickConnectException([String? message])
      : super(message ?? 'QuickConnect 解析失败', code: -2);
}
