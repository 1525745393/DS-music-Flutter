import 'package:ds_music_flutter/player/dlna_controller.dart';
import 'package:ds_music_flutter/model/song.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upnp2/upnp2.dart';

/// UpnpCommand 的 candidate 候选策略
/// 关键点：upnp2 1.0.0 的 DMR API 不固定，本测试验证
/// 1. 选中目标为 null 时不调用且不抛
/// 2. 多个候选全部失败时返回 false
class _FakeRenderer extends UpnpDevice {
  _FakeRenderer({this.shouldFail = true}) : super.empty();
  final bool shouldFail;

  @override
  String get uuid => 'fake-uuid';
  @override
  String get deviceType => 'urn:schemas-upnp-org:device:MediaRenderer:1';
  @override
  String? get friendlyName => 'Fake';
  @override
  String? get host => '192.168.1.10';
  @override
  int? get port => 8080;

  @override
  Future<void> setAVTransportURI(String uri, String title) async {
    if (shouldFail) throw StateError('setAVTransportURI failed');
  }

  @override
  Future<void> play() async {
    if (shouldFail) throw StateError('play failed');
  }
}

void main() {
  group('UpnpCommand', () {
    test('target=null 时返回 false 不抛', () async {
      final cmd = UpnpCommand(
        'test',
        target: null,
        candidates: const ['pause'],
      );
      expect(await cmd.invoke(), false);
    });

    test('目标方法不存在时返回 false（NoSuchMethod 兜底）', () async {
      final r = _FakeRenderer(shouldFail: true);
      final cmd = UpnpCommand(
        'pause',
        target: r,
        candidates: const ['nonExistentMethod1', 'nonExistentMethod2'],
      );
      expect(await cmd.invoke(), false);
    });

    test('invokeList null target 返回 null', () async {
      final cmd = UpnpCommand(
        'browse',
        target: null,
        candidates: const ['browse'],
      );
      expect(await cmd.invokeList(), isNull);
    });
  });

  group('DlnaController 设备发现', () {
    test('空 devices 时返回空列表', () {
      final c = DlnaController();
      expect(c.devices, isEmpty);
      expect(c.servers, isEmpty);
      c.dispose();
    });
  });

  group('DlnaMediaItem', () {
    test('isContainer 判定', () {
      final c = const DlnaMediaItem(
          id: '1', title: 'A', type: 'container', childrenCount: 5);
      final a = const DlnaMediaItem(
          id: '2', title: 'B', type: 'audio', childrenCount: 0);
      expect(c.isContainer, true);
      expect(a.isContainer, false);
    });
  });

  group('push/pushQueue', () {
    test('未选设备时 push 返回 false', () async {
      final c = DlnaController();
      final ok = await c.push(
          Song.fromJson({'id': '1', 'title': 'S'}), 'https://stub/1');
      expect(ok, false);
      c.dispose();
    });

    test('pushQueue 空列表返回 false', () async {
      final c = DlnaController();
      expect(await c.pushQueue([], const []), false);
      c.dispose();
    });
  });
}
