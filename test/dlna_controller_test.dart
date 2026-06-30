import 'package:ds_music_flutter/player/dlna_controller.dart';
import 'package:ds_music_flutter/model/song.dart';
import 'package:flutter_test/flutter_test.dart';

/// DlnaController 桩实现行为测试
/// 关键点：v1.1.0 DLNA 改为桩实现，仅验证：
/// 1. 设备列表初始为空
/// 2. 未选设备时 push/pushQueue 返回 false
/// 3. DlnaMediaItem 字段与判定正确
void main() {
  group('DlnaController 设备管理', () {
    test('初始 devices/servers 为空', () {
      final c = DlnaController();
      expect(c.devices, isEmpty);
      expect(c.servers, isEmpty);
      c.dispose();
    });

    test('startDiscovery 后填充示例设备', () async {
      final c = DlnaController();
      await c.startDiscovery();
      expect(c.devices, isNotEmpty);
      c.dispose();
    });
  });

  group('DlnaMediaItem', () {
    test('isContainer 判定', () {
      const c = DlnaMediaItem(
        id: '1',
        title: 'A',
        type: 'container',
        childrenCount: 5,
      );
      const a = DlnaMediaItem(
        id: '2',
        title: 'B',
        type: 'audio',
        childrenCount: 0,
      );
      expect(c.isContainer, true);
      expect(a.isContainer, false);
    });
  });

  group('push/pushQueue', () {
    test('未选设备时 push 返回 false', () async {
      final c = DlnaController();
      final ok = await c.push(
        Song.fromJson({'id': '1', 'title': 'S'}),
        'https://stub/1',
      );
      expect(ok, false);
      c.dispose();
    });

    test('pushQueue 空列表返回 false', () async {
      final c = DlnaController();
      expect(await c.pushQueue(const [], const []), false);
      c.dispose();
    });
  });

  group('远程控制 (DMR)', () {
    test('未选设备时 pause/resume/stop/seekTo/setVolume 返回 false', () async {
      final c = DlnaController();
      expect(await c.pause(), false);
      expect(await c.resume(), false);
      expect(await c.stop(), false);
      expect(await c.seekTo(30), false);
      expect(await c.setVolume(50), false);
      c.dispose();
    });
  });

  group('Browse', () {
    test('browse 未选设备返回空列表', () async {
      final c = DlnaController();
      final items = await c.browse();
      expect(items, isEmpty);
      c.dispose();
    });
  });
}
