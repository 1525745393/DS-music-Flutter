import 'package:flutter_test/flutter_test.dart';
import 'package:ds_music_flutter/model/server_config.dart';

void main() {
  group('ServerConfig', () {
    test('toJson / fromJson 完整往返', () {
      final s = ServerConfig(
        id: 'abc',
        name: 'Home NAS',
        mode: ServerMode.ddns,
        host: 'nas.example.com',
        port: 5001,
        useHttps: true,
        account: 'admin',
        isDefault: true,
      );
      final json = s.toJson();
      final s2 = ServerConfig.fromJson(json);
      expect(s2.id, 'abc');
      expect(s2.mode, ServerMode.ddns);
      expect(s2.useHttps, true);
      expect(s2.account, 'admin');
      expect(s2.isDefault, true);
    });

    test('baseUrl 拼接正确', () {
      final s = ServerConfig(
        id: '1', name: 'x', mode: ServerMode.lan,
        host: '192.168.1.1', port: 5000, useHttps: false,
      );
      expect(s.baseUrl, 'http://192.168.1.1:5000');
    });

    test('baseUrl HTTPS 拼接', () {
      final s = ServerConfig(
        id: '1', name: 'x', mode: ServerMode.ddns,
        host: 'nas.example.com', port: 5001, useHttps: true,
      );
      expect(s.baseUrl, 'https://nas.example.com:5001');
    });

    test('copyWith 不影响原对象', () {
      final s = ServerConfig(
        id: '1', name: 'x', mode: ServerMode.lan,
        host: '1.1.1.1', port: 5000, useHttps: false,
      );
      final s2 = s.copyWith(port: 5001);
      expect(s.port, 5000);
      expect(s2.port, 5001);
    });
  });
}
