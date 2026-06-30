/// 专辑
class Album {
  final String id;
  final String name;
  final String? artist;
  final String? coverUrl;
  final int songCount;
  final int duration; // 秒
  final int? year;
  final String? genre;

  const Album({
    required this.id,
    required this.name,
    this.artist,
    this.coverUrl,
    this.songCount = 0,
    this.duration = 0,
    this.year,
    this.genre,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: (json['id'] ?? json['album_id'] ?? '').toString(),
      name: (json['name'] ?? json['album'] ?? '未知专辑').toString(),
      artist: json['artist']?.toString(),
      coverUrl: json['cover']?.toString(),
      songCount: _asInt(json['song_count'] ?? json['items']) ?? 0,
      duration: _asInt(json['duration']) ?? 0,
      year: _asInt(json['year']),
      genre: json['genre']?.toString(),
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
