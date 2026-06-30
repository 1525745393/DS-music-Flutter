import 'package:flutter_test/flutter_test.dart';
import 'package:ds_music_flutter/model/lyrics.dart';

void main() {
  group('Lyrics', () {
    test('parse 标准 LRC 格式', () {
      const lrc = '''
[ti:Test Title]
[ar:Test Artist]
[al:Test Album]
[00:01.00]第一行歌词
[00:03.50]第二行歌词
[00:06.20]第三行歌词
''';
      final lyrics = Lyrics.parse(lrc);
      expect(lyrics.lines.length, 3);
      expect(lyrics.title, 'Test Title');
      expect(lyrics.artist, 'Test Artist');
      expect(lyrics.album, 'Test Album');
      expect(lyrics.lines[0].text, '第一行歌词');
      expect(lyrics.lines[0].time.inMilliseconds, 1000);
      expect(lyrics.lines[1].time.inMilliseconds, 3500);
    });

    test('parse 空文本返回空', () {
      final lyrics = Lyrics.parse('');
      expect(lyrics.lines, isEmpty);
    });

    test('indexAt 返回正确的当前行', () {
      const lrc = '''
[00:01.00]A
[00:02.00]B
[00:03.00]C
''';
      final lyrics = Lyrics.parse(lrc);
      expect(lyrics.indexAt(const Duration(milliseconds: 500)), -1);
      expect(lyrics.indexAt(const Duration(milliseconds: 1500)), 0);
      expect(lyrics.indexAt(const Duration(milliseconds: 2500)), 1);
      expect(lyrics.indexAt(const Duration(milliseconds: 5000)), 2);
    });
  });
}
