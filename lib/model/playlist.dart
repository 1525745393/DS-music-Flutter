import 'song.dart';

/// 歌单/播放列表
class Playlist {
  final String id;
  final String name;
  final String? coverUrl;
  final int songCount;
  final int duration;          // 总时长
  final String? owner;
  final bool isShared;
  final bool isOwn;            // 是否本账号创建
  final List<Song> songs;

  const Playlist({
    required this.id,
    required this.name,
    this.coverUrl,
    this.songCount = 0,
    this.duration = 0,
    this.owner,
    this.isShared = false,
    this.isOwn = false,
    this.songs = const [],
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final songs = (json['songs'] as List?)
            ?.cast<Map<String, dynamic>>()
            .map(Song.fromJson)
            .toList() ??
        const <Song>[];
    return Playlist(
      id: (json['id'] ?? json['playlist_id'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? '未命名歌单').toString(),
      coverUrl: json['cover']?.toString(),
      songCount: _asInt(json['song_count'] ?? json['items']) ?? songs.length,
      duration: _asInt(json['duration']) ?? 0,
      owner: json['owner']?.toString(),
      isShared: json['shared'] == true,
      isOwn: json['own'] == true,
      songs: songs,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'cover': coverUrl,
    'song_count': songCount,
    'duration': duration,
    'owner': owner,
    'shared': isShared,
    'own': isOwn,
  };

  Playlist copyWith({List<Song>? songs}) => Playlist(
    id: id,
    name: name,
    coverUrl: coverUrl,
    songCount: songs?.length ?? songCount,
    duration: duration,
    owner: owner,
    isShared: isShared,
    isOwn: isOwn,
    songs: songs ?? this.songs,
  );

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
