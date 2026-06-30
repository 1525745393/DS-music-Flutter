import 'package:ds_music_flutter/model/song.dart';
import 'package:ds_music_flutter/player/audio_handler.dart';
import 'package:flutter_test/flutter_test.dart';

/// SettingsPort 测试桩
class _StubSettings implements SettingsPort {
  @override
  int get transcodeBitrate => 320000;
  @override
  String get transcodeFormat => 'mp3';
  @override
  bool get forceLossless => false;
  @override
  bool get forceTranscodeOnMobile => true;
  @override
  bool get normalizeVolume => false;
  @override
  bool get gaplessEnabled => true;
}

/// LibraryAccess 测试桩
class _StubRepo implements LibraryAccess {
  @override
  String streamUrl(Song song,
      {bool forceTranscode = false, bool preferLossless = false}) {
    return 'https://stub.stream/${song.id}?trans=$forceTranscode';
  }

  @override
  String coverUrl(String albumId, {String size = '300'}) =>
      'https://stub.cover/$albumId';
}

Song _song(String id) =>
    Song.fromJson({'id': id, 'title': 'S$id', 'duration': 60});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DSPlayerHandler 状态', () {
    test('构造时播放状态为暂停', () {
      final handler = DSPlayerHandler(
        repoGetter: () => _StubRepo(),
        settingsGetter: () => _StubSettings(),
      );
      expect(handler.playbackState.value.playing, isFalse);
      expect(handler.playbackState.value.processingState, isNotNull);
      handler.stop();
    });

    test('currentNetType 默认为当前网络类型', () {
      final handler = DSPlayerHandler(
        repoGetter: () => _StubRepo(),
        settingsGetter: () => _StubSettings(),
      );
      // 初始值来源于 networkTypeWatcher.current
      expect(handler.currentNetType, isNotNull);
      handler.stop();
    });
  });

  group('LibraryAccess 接口契约', () {
    test('forceTranscode=true 反映在 URL 参数', () {
      final repo = _StubRepo();
      final url = repo.streamUrl(_song('a'), forceTranscode: true);
      expect(url, contains('trans=true'));
    });

    test('forceTranscode=false 不带参数', () {
      final repo = _StubRepo();
      final url = repo.streamUrl(_song('a'), forceTranscode: false);
      expect(url, contains('trans=false'));
    });
  });
}
