/// 歌手
class Artist {
  final String id;
  final String name;
  final String? avatarUrl;
  final int albumCount;
  final int songCount;

  const Artist({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.albumCount = 0,
    this.songCount = 0,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: (json['id'] ?? json['artist_id'] ?? '').toString(),
      name: (json['name'] ?? json['artist'] ?? '未知歌手').toString(),
      avatarUrl: json['avatar']?.toString(),
      albumCount: _asInt(json['album_count']) ?? 0,
      songCount: _asInt(json['song_count']) ?? 0,
    );
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
