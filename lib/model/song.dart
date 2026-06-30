import 'album.dart';

/// 单曲
class Song {
  final String id;
  final String title;
  final String? artist;
  final String? artistId;
  final String? album;
  final String? albumId;
  final String? coverUrl;
  final int duration;          // 秒
  final int? track;
  final int? year;
  final String? genre;
  final int? bitrate;
  final int? sampleRate;
  final String? container;     // flac / dsd / mp3 ...
  final int size;              // 字节
  final String? path;          // NAS 上的相对路径
  final bool favorite;
  final int rating;            // 0-5
  final bool downloaded;       // 是否已下载到本地
  final String? localPath;     // 本地缓存路径

  const Song({
    required this.id,
    required this.title,
    this.artist,
    this.artistId,
    this.album,
    this.albumId,
    this.coverUrl,
    required this.duration,
    this.track,
    this.year,
    this.genre,
    this.bitrate,
    this.sampleRate,
    this.container,
    this.size = 0,
    this.path,
    this.favorite = false,
    this.rating = 0,
    this.downloaded = false,
    this.localPath,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: (json['id'] ?? json['song_id'] ?? '').toString(),
      title: (json['title'] ?? '未知歌曲').toString(),
      artist: json['artist']?.toString(),
      artistId: json['artist_id']?.toString(),
      album: json['album']?.toString(),
      albumId: json['album_id']?.toString(),
      coverUrl: json['cover']?.toString(),
      duration: _asInt(json['duration']) ?? 0,
      track: _asInt(json['track']),
      year: _asInt(json['year']),
      genre: json['genre']?.toString(),
      bitrate: _asInt(json['bitrate']),
      sampleRate: _asInt(json['samplerate']) ?? _asInt(json['sample_rate']),
      container: json['container']?.toString() ?? json['type']?.toString(),
      size: _asInt(json['size']) ?? 0,
      path: json['path']?.toString(),
      favorite: (json['favorite'] == true || json['favourite'] == true),
      rating: _asInt(json['rating']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'artist_id': artistId,
    'album': album,
    'album_id': albumId,
    'cover': coverUrl,
    'duration': duration,
    'track': track,
    'year': year,
    'genre': genre,
    'bitrate': bitrate,
    'samplerate': sampleRate,
    'container': container,
    'size': size,
    'path': path,
    'favorite': favorite,
    'rating': rating,
  };

  /// 格式化时长为 mm:ss
  String get durationText {
    final m = duration ~/ 60;
    final s = duration % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Song copyWith({
    bool? downloaded,
    String? localPath,
    bool? favorite,
    int? rating,
  }) {
    return Song(
      id: id,
      title: title,
      artist: artist,
      artistId: artistId,
      album: album,
      albumId: albumId,
      coverUrl: coverUrl,
      duration: duration,
      track: track,
      year: year,
      genre: genre,
      bitrate: bitrate,
      sampleRate: sampleRate,
      container: container,
      size: size,
      path: path,
      favorite: favorite ?? this.favorite,
      rating: rating ?? this.rating,
      downloaded: downloaded ?? this.downloaded,
      localPath: localPath ?? this.localPath,
    );
  }

  /// 从本地缓存中恢复下载状态
  static Song markDownloaded(Song s, String localPath) =>
      s.copyWith(downloaded: true, localPath: localPath);

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
