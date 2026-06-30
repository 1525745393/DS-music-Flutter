import 'package:flutter_test/flutter_test.dart';
import 'package:ds_music_flutter/model/song.dart';
import 'package:ds_music_flutter/model/album.dart';
import 'package:ds_music_flutter/model/artist.dart';
import 'package:ds_music_flutter/model/playlist.dart';

void main() {
  group('Song', () {
    test('fromJson 完整字段', () {
      final json = {
        'id': '123',
        'title': 'Test Song',
        'artist': 'Test Artist',
        'artist_id': 'a1',
        'album': 'Test Album',
        'album_id': 'b1',
        'cover': 'http://example.com/cover.jpg',
        'duration': 180,
        'track': 5,
        'year': 2024,
        'genre': 'Pop',
        'bitrate': 320000,
        'samplerate': 44100,
        'container': 'flac',
        'size': 12345678,
        'path': '/music/test.flac',
        'rating': 5,
      };
      final song = Song.fromJson(json);
      expect(song.id, '123');
      expect(song.title, 'Test Song');
      expect(song.artist, 'Test Artist');
      expect(song.duration, 180);
      expect(song.durationText, '03:00');
      expect(song.container, 'flac');
      expect(song.rating, 5);
    });

    test('fromJson 最小字段', () {
      final song = Song.fromJson({'id': '1', 'title': 'x', 'duration': 60});
      expect(song.id, '1');
      expect(song.artist, isNull);
      expect(song.durationText, '01:00');
    });

    test('copyWith 正确合并', () {
      final s = Song.fromJson({'id': '1', 'title': 'x', 'duration': 60});
      final s2 = s.copyWith(downloaded: true, localPath: '/tmp/x.mp3');
      expect(s2.downloaded, true);
      expect(s2.localPath, '/tmp/x.mp3');
      expect(s2.id, '1');
    });
  });

  group('Album', () {
    test('fromJson 解析', () {
      final a = Album.fromJson({
        'id': 'a1',
        'name': 'Album Name',
        'artist': 'Artist',
        'song_count': 12,
        'duration': 3600,
      });
      expect(a.id, 'a1');
      expect(a.songCount, 12);
      expect(a.duration, 3600);
    });
  });

  group('Artist', () {
    test('fromJson 解析', () {
      final a = Artist.fromJson({
        'id': 'ar1',
        'name': 'Artist Name',
        'album_count': 5,
        'song_count': 60,
      });
      expect(a.albumCount, 5);
      expect(a.songCount, 60);
    });
  });

  group('Playlist', () {
    test('fromJson 解析含歌曲', () {
      final p = Playlist.fromJson({
        'id': 'p1',
        'name': 'Playlist',
        'songs': [
          {'id': 's1', 'title': 'Song 1', 'duration': 100},
        ],
      });
      expect(p.id, 'p1');
      expect(p.songs.length, 1);
      expect(p.songs[0].title, 'Song 1');
    });
  });
}
