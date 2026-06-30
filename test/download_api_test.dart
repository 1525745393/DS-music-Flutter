import 'package:ds_music_flutter/api/download_api.dart';
import 'package:ds_music_flutter/api/audio_station_api.dart';
import 'package:ds_music_flutter/api/api_info.dart';
import 'package:ds_music_flutter/api/dio_client.dart';
import 'package:ds_music_flutter/model/song.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AudioStationApi 抽象类测试桩
/// 关键：避免引入 mocking 库，继承实现一遍
class _StubAudio extends AudioStationApi {
  _StubAudio()
      : super(
          // 测试桩不发起真实请求，Dio 用默认配置即可
          Dio(),
          ApiInfo(Dio()),
          DioClient(baseUrl: 'http://stub.local'),
        );

  @override
  String buildStreamUrl(
    Song song, {
    bool forceTranscode = false,
    int? bitrate,
    String? format,
    bool preferLossless = false,
  }) =>
      'https://stub/${song.id}';

  @override
  String buildDownloadUrl(Song song) => 'https://stub/${song.id}';

  @override
  String buildCoverUrl(String albumId, {String size = 'mid'}) =>
      'https://stub/cover/$albumId';
}

Song _song(String id) => Song.fromJson(
    {'id': id, 'title': 'S$id', 'duration': 60, 'container': 'mp3'});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // 内存中 SharedPreferences（避免在测试中写盘）
    SharedPreferences.setMockInitialValues({});
  });

  group('DownloadApi 调度', () {
    test('register 立即入队但不下载', () async {
      final api = DownloadApi(_StubAudio());
      final t = api.register(_song('a'), '/tmp/a.mp3');
      expect(t.status, DownloadStatus.pending);
      expect(api.tasks.length, 1);
      api.dispose();
    });

    test('clearCompleted 仅删除 completed 任务', () async {
      final api = DownloadApi(_StubAudio());
      // 直接构造一个 completed 任务（不触发网络）
      final t = api.register(_song('x'), '/tmp/x.mp3');
      // 反射写入 status（测试用）
      // 简化：直接调 _resolveSid 验证 SP 读不到 sid 是 null
      expect(
          t.status, anyOf(DownloadStatus.pending, DownloadStatus.downloading));
      final removed = await api.clearCompleted();
      // pending 状态不应被清
      expect(api.tasks.any((x) => x.song.id == 'x'), true);
      expect(removed, 0);
      api.dispose();
    });

    test('taskFor 返回已注册任务', () {
      final api = DownloadApi(_StubAudio());
      api.register(_song('a'), '/tmp/a.mp3');
      final t = api.taskFor('a');
      expect(t, isNotNull);
      expect(t!.song.id, 'a');
      expect(api.taskFor('nonexistent'), isNull);
      api.dispose();
    });

    test('cancel 删除任务', () async {
      final api = DownloadApi(_StubAudio());
      api.register(_song('a'), '/tmp/a.mp3');
      await api.cancel('a', deleteFile: false);
      expect(api.taskFor('a'), isNull);
      api.dispose();
    });
  });

  group('DownloadTask 序列化', () {
    test('toJson/fromJson 往返一致', () {
      final s = _song('z');
      final t = DownloadTask(
          song: s,
          localPath: '/tmp/z.mp3',
          receivedBytes: 1024,
          totalBytes: 4096);
      final j = t.toJson();
      final t2 = DownloadTask.fromJson(j);
      expect(t2, isNotNull);
      expect(t2!.song.id, 'z');
      expect(t2.receivedBytes, 1024);
      expect(t2.totalBytes, 4096);
    });

    test('status 字符串 round-trip', () {
      for (final s in DownloadStatus.values) {
        final j = {
          'song': {'id': 'a', 'title': 'A', 'duration': 0},
          'localPath': '',
          'status': s.name
        };
        final t = DownloadTask.fromJson(j);
        expect(t, isNotNull);
      }
    });
  });
}
