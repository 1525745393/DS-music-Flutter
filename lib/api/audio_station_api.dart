import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../model/album.dart';
import '../model/artist.dart';
import '../model/exception.dart';
import '../model/playlist.dart';
import '../model/song.dart';
import '../utils/logger.dart';
import 'api_info.dart';
import 'dio_client.dart';

/// AudioStation 业务接口全封装
/// 与 DS Player 同源接口：列表/搜索/详情/歌词/封面/外接播放器
class AudioStationApi {
  final Dio _dio;
  final ApiInfo _apiInfo;
  final DioClient _client;

  AudioStationApi(this._dio, this._apiInfo, this._client);

  // ==================== Albums ====================

  /// 拉取专辑列表
  /// [limit] 每页条数（默认 100）
  /// [offset] 偏移
  /// [sortBy] name / added_time / rating ...
  /// [sortDirection] asc / desc
  Future<List<Album>> listAlbums({
    int limit = 100,
    int offset = 0,
    String sortBy = 'name',
    String sortDirection = 'asc',
    String? keyword,
  }) async {
    final data = await _call(ApiConstants.audioStationAlbum, 'list', version: 3, extra: {
      'limit': limit,
      'offset': offset,
      'sort_by': sortBy,
      'sort_direction': sortDirection,
      if (keyword != null && keyword.isNotEmpty) 'filter': keyword,
    });
    final albums = (data['albums'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return albums.map(Album.fromJson).toList();
  }

  /// 专辑详情 + 包含的歌曲
  Future<({Album album, List<Song> songs})> getAlbumDetail(String albumId) async {
    final data = await _call(ApiConstants.audioStationAlbum, 'getinfo', version: 3, extra: {
      'id': albumId,
      'additional': 'song_count,all_songs',
    });
    final album = Album.fromJson(Map<String, dynamic>.from(data['album'] ?? {}));
    final songsList = (data['songs'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return (album: album, songs: songsList.map(Song.fromJson).toList());
  }

  // ==================== Artists ====================

  Future<List<Artist>> listArtists({
    int limit = 100,
    int offset = 0,
    String sortBy = 'name',
    String sortDirection = 'asc',
    String? keyword,
  }) async {
    final data = await _call(ApiConstants.audioStationArtist, 'list', version: 1, extra: {
      'limit': limit,
      'offset': offset,
      if (keyword != null && keyword.isNotEmpty) 'filter': keyword,
    });
    final list = (data['artists'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return list.map(Artist.fromJson).toList();
  }

  Future<({Artist artist, List<Album> albums})> getArtistDetail(String artistId) async {
    final data = await _call(ApiConstants.audioStationArtist, 'getinfo', version: 1, extra: {
      'id': artistId,
      'additional': 'albums',
    });
    final artist = Artist.fromJson(Map<String, dynamic>.from(data['artist'] ?? {}));
    final albums = ((data['albums'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .map(Album.fromJson)
        .toList();
    return (artist: artist, albums: albums);
  }

  // ==================== Songs ====================

  /// 全部单曲分页拉取
  Future<List<Song>> listSongs({
    int limit = 500,
    int offset = 0,
    String sortBy = 'title',
    String sortDirection = 'asc',
    String? keyword,
    String? albumId,
    String? artistId,
  }) async {
    final data = await _call(ApiConstants.audioStationSong, 'list', version: 2, extra: {
      'limit': limit,
      'offset': offset,
      'sort_by': sortBy,
      'sort_direction': sortDirection,
      if (keyword != null && keyword.isNotEmpty) 'filter': keyword,
      if (albumId != null) 'album_id': albumId,
      if (artistId != null) 'artist_id': artistId,
    });
    final list = (data['songs'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return list.map(Song.fromJson).toList();
  }

  // ==================== Folders ====================

  /// 文件夹浏览
  Future<List<Map<String, dynamic>>> listFolders({
    String? parentId,
    int limit = 200,
    int offset = 0,
  }) async {
    final data = await _call(ApiConstants.audioStationFolder, 'list', version: 2, extra: {
      if (parentId != null) 'id': parentId,
      'limit': limit,
      'offset': offset,
    });
    return (data['folders'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  // ==================== Playlists ====================

  Future<List<Playlist>> listPlaylists({int limit = 100, int offset = 0}) async {
    final data = await _call(ApiConstants.audioStationPlaylist, 'list', version: 3, extra: {
      'limit': limit,
      'offset': offset,
    });
    final list = (data['playlists'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return list.map(Playlist.fromJson).toList();
  }

  Future<Playlist> getPlaylistDetail(String playlistId) async {
    final data = await _call(ApiConstants.audioStationPlaylist, 'getinfo', version: 3, extra: {
      'id': playlistId,
      'additional': 'songs',
    });
    return Playlist.fromJson(Map<String, dynamic>.from(data['playlist'] ?? {}));
  }

  Future<Playlist> createPlaylist(String name) async {
    final data = await _call(ApiConstants.audioStationPlaylist, 'create', version: 3, extra: {
      'name': name,
    });
    return Playlist.fromJson(Map<String, dynamic>.from(data['playlist'] ?? {}));
  }

  Future<void> updatePlaylist({
    required String playlistId,
    String? name,
    List<String>? songIdsToAdd,
    List<String>? songIdsToRemove,
  }) async {
    await _call(ApiConstants.audioStationPlaylist, 'update', version: 3, extra: {
      'id': playlistId,
      if (name != null) 'name': name,
      if (songIdsToAdd != null && songIdsToAdd.isNotEmpty)
        'song_id_to_add': songIdsToAdd.join(','),
      if (songIdsToRemove != null && songIdsToRemove.isNotEmpty)
        'song_id_to_remove': songIdsToRemove.join(','),
    });
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _call(ApiConstants.audioStationPlaylist, 'delete', version: 3, extra: {
      'id': playlistId,
    });
  }

  // ==================== Search ====================

  /// 综合搜索：返回 {albums, artists, songs}
  Future<({List<Album> albums, List<Artist> artists, List<Song> songs})> search(
    String keyword, {
    int limit = 50,
  }) async {
    final data = await _call(ApiConstants.audioStationSearch, 'list', version: 3, extra: {
      'filter': keyword,
      'limit': limit,
      'additional': 'song_album, song_artist',
    });
    final albums = ((data['albums'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .map(Album.fromJson)
        .toList();
    final artists = ((data['artists'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .map(Artist.fromJson)
        .toList();
    final songs = ((data['songs'] as List?) ?? [])
        .cast<Map<String, dynamic>>()
        .map(Song.fromJson)
        .toList();
    return (albums: albums, artists: artists, songs: songs);
  }

  // ==================== Rating ====================

  /// 设置歌曲星级
  Future<void> rate(String songId, int rating) async {
    await _call(ApiConstants.audioStationSong, 'rate', version: 2, extra: {
      'id': songId,
      'rating': rating,
    });
  }

  // ==================== Stream URL 构造 ====================

  /// stream.cgi 完整 URL
  /// [song] 目标歌曲
  /// [forceTranscode] 强制转码（用于蜂窝网络）
  /// [bitrate] 转码码率
  /// [format] 转码格式
  /// [preferLossless] 外网+WiFi 时仍保持原始码流
  String buildStreamUrl(
    Song song, {
    bool forceTranscode = false,
    int? bitrate,
    String? format,
    bool preferLossless = false,
  }) {
    final params = <String, dynamic>{
      'api': ApiConstants.audioStationStream,
      'version': 2,
      'method': 'stream',
      'id': song.id,
    };
    if (forceTranscode && !preferLossless) {
      params['format'] = format ?? ApiConstants.transcodeMp3;
      params['bitrate'] = bitrate ?? ApiConstants.transcodeBitrate;
      params['samplerate'] = ApiConstants.transcodeSampleRate;
    }
    final query = _buildQuery(params);
    return '${_client.baseUrl}/${ApiConstants.streamPath}?$query';
  }

  /// 专辑封面 URL（多尺寸：small/mid/big）
  String buildCoverUrl(String albumId, {String size = 'mid'}) {
    final params = {
      'api': ApiConstants.audioStationCover,
      'version': 1,
      'method': 'getcover',
      'id': albumId,
      'size': size,
    };
    return '${_client.baseUrl}/${ApiConstants.coverPath}?${_buildQuery(params)}';
  }

  /// 头像/歌手封面
  String buildThumbUrl(String id) {
    final params = {
      'api': 'SYNO.AudioStation.Thumb',
      'version': 1,
      'method': 'get',
      'id': id,
    };
    return '${_client.baseUrl}/${ApiConstants.thumbPath}?${_buildQuery(params)}';
  }

  /// 歌词 URL（stream 模式返回 lrc 文本）
  String buildLyricsUrl(String songId) {
    final params = {
      'api': ApiConstants.audioStationLyrics,
      'version': 1,
      'method': 'getlyrics',
      'id': songId,
    };
    return '${_client.baseUrl}/${ApiConstants.entryPath}?${_buildQuery(params)}';
  }

  /// 下载 URL（支持 Range 断点续传）
  String buildDownloadUrl(Song song) {
    final params = {
      'api': ApiConstants.audioStationDownload,
      'version': 1,
      'method': 'download',
      'id': song.id,
    };
    return '${_client.baseUrl}/${ApiConstants.downloadPath}?${_buildQuery(params)}';
  }

  /// 外接播放器（DLNA）URL：作为推送目标
  String buildExternalPlayerUrl(Song song) {
    return buildStreamUrl(song);
  }

  // ==================== Internal ====================

  /// 通用调用入口：解析动态路径、版本
  Future<Map<String, dynamic>> _call(
    String api,
    String method, {
    int? version,
    Map<String, dynamic> extra = const {},
  }) async {
    final path = await _apiInfo.getPath(api);
    if (path.isEmpty) throw AppException('未找到接口: $api');
    final v = version ?? await _apiInfo.getMaxVersion(api);
    final query = <String, dynamic>{
      'api': api,
      'version': v,
      'method': method,
      ...extra,
    };
    try {
      final resp = await _dio.get(path, queryParameters: query);
      final data = resp.data as Map<String, dynamic>;
      if (data['success'] != true) {
        final err = data['error'];
        final code = err?['code'];
        if (code == 102 || code == 105) {
          throw UnauthorizedException();
        }
        throw AppException('API 错误: $api.$method code=$code');
      }
      return Map<String, dynamic>.from(data['data'] ?? {});
    } on DioException catch (e) {
      AppLogger.e('API $api.$method 失败', e);
      throw DioClient.mapError(e);
    }
  }

  String _buildQuery(Map<String, dynamic> params) {
    return params.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value.toString())}')
        .join('&');
  }
}
