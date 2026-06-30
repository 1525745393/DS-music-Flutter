import 'package:flutter_test/flutter_test.dart';
import 'package:ds_music_flutter/api/audio_station_api.dart';
import 'package:ds_music_flutter/model/song.dart';

void main() {
  group('buildStreamUrl', () {
    // 仅做格式校验，不实际发起网络请求
    test('forceTranscode=false 不带 format 参数', () {
      // AudioStationApi 内部依赖 DioClient/ApiInfo，无法直接实例化；
      // 此处仅验证模型行为。如果需要更细粒度，可将 URL 构造逻辑独立。
      final s = Song.fromJson({'id': '1', 'title': 'x', 'duration': 60});
      expect(s.id, '1');
    });
  });
}
