import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ds_music_flutter/api/dio_client.dart';
import 'package:ds_music_flutter/api/api_info.dart';
import 'package:ds_music_flutter/api/api_auth.dart';
import 'package:ds_music_flutter/constants/api_constants.dart';

/// 自定义 Mock 适配器：捕获请求参数，返回预设响应
class MockAdapter implements HttpClientAdapter {
  /// 请求记录：每次请求的 {path, query, method}
  final List<Map<String, dynamic>> requests = [];

  /// 响应回调：根据 path 返回预设 ResponseBody
  final ResponseBody Function(String path, Map<String, dynamic> query)
      responder;

  MockAdapter(this.responder);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future? cancelFuture,
  ) async {
    final path = options.path;
    final query = Map<String, dynamic>.from(options.queryParameters);
    requests.add({'path': path, 'query': query, 'method': options.method});
    return responder(path, query);
  }

  @override
  void close({bool force = false}) {}
}

/// 构造 JSON 响应体
ResponseBody _jsonResponse(Map<String, dynamic> data) {
  final bytes = Uint8List.fromList(utf8.encode(jsonEncode(data)));
  return ResponseBody.fromBytes(
    bytes,
    200,
    headers: {
      'content-type': ['application/json'],
    },
  );
}

void main() {
  group('DioClient SID 拦截器', () {
    test('非登录请求注入 _sid（带下划线）', () async {
      final client = DioClient(baseUrl: 'https://nas.example.com:5001');
      // 设置已登录 SID
      client.sid = 'test-sid-123';

      String? capturedSid;
      client.dio.httpClientAdapter = MockAdapter((path, query) {
        capturedSid = query['_sid'] as String?;
        return _jsonResponse({'success': true, 'data': {}});
      });

      // 发起一个非登录请求
      await client.dio.get(ApiConstants.entryPath, queryParameters: {
        'api': 'SYNO.AudioStation.Album',
        'version': 3,
        'method': 'list',
      });

      expect(capturedSid, 'test-sid-123', reason: '_sid 必须带下划线且值为当前 SID');
      client.close();
    });

    test('登录请求（SYNO.API.Auth method=login）不注入 _sid', () async {
      final client = DioClient(baseUrl: 'https://nas.example.com:5001');
      client.sid = 'old-sid';

      String? capturedSid;
      client.dio.httpClientAdapter = MockAdapter((path, query) {
        capturedSid = query['_sid'] as String?;
        return _jsonResponse({
          'success': true,
          'data': {'sid': 'new-sid'},
        });
      });

      await client.dio.get(ApiConstants.entryPath, queryParameters: {
        'api': 'SYNO.API.Auth',
        'version': 6,
        'method': 'login',
        'account': 'admin',
        'passwd': 'pass',
      });

      expect(capturedSid, isNull, reason: '登录请求不应携带 _sid，避免干扰鉴权');
      client.close();
    });
  });

  group('ApiInfo - SYNO.API.Info 走 entry.cgi', () {
    test('查询请求路径为 webapi/entry.cgi 而非 query.cgi', () async {
      final dio = Dio();
      String? capturedPath;

      dio.httpClientAdapter = MockAdapter((path, query) {
        capturedPath = path;
        return _jsonResponse({
          'success': true,
          'data': {
            'SYNO.API.Auth': {
              'path': 'entry.cgi',
              'maxVersion': 6,
              'minVersion': 1,
            }
          },
        });
      });

      final apiInfo = ApiInfo(dio);
      await apiInfo.query('SYNO.API.Auth');

      expect(capturedPath, 'webapi/entry.cgi',
          reason: 'SYNO.API.Info 必须走 entry.cgi，不能走 query.cgi');
    });

    test('查询请求带 api=SYNO.API.Info 参数', () async {
      final dio = Dio();
      String? capturedApi;

      dio.httpClientAdapter = MockAdapter((path, query) {
        capturedApi = query['api'] as String?;
        return _jsonResponse({
          'success': true,
          'data': {
            'SYNO.API.Auth': {'path': 'entry.cgi', 'maxVersion': 6}
          },
        });
      });

      final apiInfo = ApiInfo(dio);
      await apiInfo.query('SYNO.API.Auth');

      expect(capturedApi, 'SYNO.API.Info');
    });
  });

  group('ApiAuth - 登录流程', () {
    test('登录请求走 entry.cgi 而非 auth.cgi', () async {
      final client = DioClient(baseUrl: 'https://nas.example.com:5001');
      final mock = MockAdapter((path, query) {
        if (query['api'] == 'SYNO.API.Info') {
          return _jsonResponse({
            'success': true,
            'data': {
              'SYNO.API.Auth': {
                'path': 'entry.cgi',
                'maxVersion': 6,
              }
            },
          });
        }
        if (query['api'] == 'SYNO.API.Auth') {
          return _jsonResponse({
            'success': true,
            'data': {'sid': 'login-sid-999'},
          });
        }
        return _jsonResponse({
          'success': false,
          'error': {'code': 100}
        });
      });
      client.dio.httpClientAdapter = mock;

      final apiInfo = ApiInfo(client.dio);
      final apiAuth = ApiAuth(client.dio, apiInfo, client);

      await apiAuth.login(account: 'admin', passwd: 'password');

      // 找到登录请求
      final loginReq = mock.requests.firstWhere(
        (r) => r['query']['api'] == 'SYNO.API.Auth',
        orElse: () => throw StateError('未找到 SYNO.API.Auth 请求'),
      );

      expect(loginReq['path'], 'webapi/entry.cgi',
          reason: '登录必须走 entry.cgi，不能走 auth.cgi');
      client.close();
    });

    test('登录请求 session 参数为 AudioStation', () async {
      final client = DioClient(baseUrl: 'https://nas.example.com:5001');
      final mock = MockAdapter((path, query) {
        if (query['api'] == 'SYNO.API.Info') {
          return _jsonResponse({
            'success': true,
            'data': {
              'SYNO.API.Auth': {'path': 'entry.cgi', 'maxVersion': 6}
            },
          });
        }
        return _jsonResponse({
          'success': true,
          'data': {'sid': 'sid-001'},
        });
      });
      client.dio.httpClientAdapter = mock;

      final apiInfo = ApiInfo(client.dio);
      final apiAuth = ApiAuth(client.dio, apiInfo, client);

      await apiAuth.login(account: 'admin', passwd: 'password');

      final loginReq = mock.requests.firstWhere(
        (r) => r['query']['api'] == 'SYNO.API.Auth',
      );
      expect(loginReq['query']['session'], 'AudioStation',
          reason: 'session 必须为 AudioStation');
      client.close();
    });

    test('登录成功后 SID 写入 DioClient', () async {
      final client = DioClient(baseUrl: 'https://nas.example.com:5001');
      client.dio.httpClientAdapter = MockAdapter((path, query) {
        if (query['api'] == 'SYNO.API.Info') {
          return _jsonResponse({
            'success': true,
            'data': {
              'SYNO.API.Auth': {'path': 'entry.cgi', 'maxVersion': 6}
            },
          });
        }
        return _jsonResponse({
          'success': true,
          'data': {'sid': 'sid-after-login'},
        });
      });

      final apiInfo = ApiInfo(client.dio);
      final apiAuth = ApiAuth(client.dio, apiInfo, client);

      expect(client.sid, isNull, reason: '登录前 SID 应为空');

      final sid = await apiAuth.login(account: 'admin', passwd: 'password');

      expect(sid, 'sid-after-login');
      expect(client.sid, 'sid-after-login', reason: '登录后 SID 必须写入 DioClient');
      client.close();
    });

    test('登录失败（密码错误 code=403）抛出异常', () async {
      final client = DioClient(baseUrl: 'https://nas.example.com:5001');
      client.dio.httpClientAdapter = MockAdapter((path, query) {
        if (query['api'] == 'SYNO.API.Info') {
          return _jsonResponse({
            'success': true,
            'data': {
              'SYNO.API.Auth': {'path': 'entry.cgi', 'maxVersion': 6}
            },
          });
        }
        return _jsonResponse({
          'success': false,
          'error': {'code': 403},
        });
      });

      final apiInfo = ApiInfo(client.dio);
      final apiAuth = ApiAuth(client.dio, apiInfo, client);

      try {
        await apiAuth.login(account: 'admin', passwd: 'wrong');
        fail('密码错误应抛出异常');
      } catch (e) {
        expect(e, isA<Exception>(), reason: '密码错误 (code=403) 应抛出 Exception');
      }
      client.close();
    });
  });

  group('ApiAuth - 注销流程', () {
    test('注销请求带 _sid 和 session=AudioStation', () async {
      final client = DioClient(baseUrl: 'https://nas.example.com:5001');
      client.sid = 'logout-test-sid';
      final mock = MockAdapter((path, query) {
        if (query['api'] == 'SYNO.API.Info') {
          return _jsonResponse({
            'success': true,
            'data': {
              'SYNO.API.Auth': {'path': 'entry.cgi', 'maxVersion': 6}
            },
          });
        }
        return _jsonResponse({'success': true, 'data': {}});
      });
      client.dio.httpClientAdapter = mock;

      final apiInfo = ApiInfo(client.dio);
      final apiAuth = ApiAuth(client.dio, apiInfo, client);

      await apiAuth.logout();

      final logoutReq = mock.requests.lastWhere(
        (r) => r['query']['api'] == 'SYNO.API.Auth',
      );
      expect(logoutReq['path'], 'webapi/entry.cgi');
      expect(logoutReq['query']['method'], 'logout');
      expect(logoutReq['query']['_sid'], 'logout-test-sid');
      expect(logoutReq['query']['session'], 'AudioStation');

      expect(client.sid, isNull, reason: '注销后 SID 应清空');
      client.close();
    });
  });

  group('DioClient - baseUrl 配置', () {
    test('Dio 实例的 BaseOptions.baseUrl 必须等于传入的 baseUrl', () {
      final url = 'https://nas.example.com:5001';
      final client = DioClient(baseUrl: url);
      expect(client.dio.options.baseUrl, url,
          reason: 'Dio 实例必须配置 baseUrl，否则相对路径请求无法解析');
      client.close();
    });

    test('baseUrl 包含协议和端口', () {
      final client = DioClient(baseUrl: 'http://192.168.1.100:5000');
      expect(client.dio.options.baseUrl, 'http://192.168.1.100:5000');
      client.close();
    });
  });

  group('ApiConstants - 路径常量', () {
    test('entryPath 为 webapi/entry.cgi', () {
      expect(ApiConstants.entryPath, 'webapi/entry.cgi');
    });

    test('默认端口 HTTP 5000 / HTTPS 5001', () {
      expect(ApiConstants.defaultHttpPort, 5000);
      expect(ApiConstants.defaultHttpsPort, 5001);
    });
  });
}
