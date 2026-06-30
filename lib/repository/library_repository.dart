import '../api/audio_station_api.dart';
import '../api/quickconnect.dart';
import '../api/api_auth.dart';
import '../api/api_info.dart';
import '../api/dio_client.dart';
import '../api/download_api.dart';
import '../model/album.dart';
import '../model/artist.dart';
import '../model/exception.dart';
import '../model/lyrics.dart';
import '../model/playlist.dart';
import '../model/server_config.dart';
import '../model/song.dart';
import '../player/audio_handler.dart';
import '../utils/logger.dart';

/// 曲库仓库：聚合所有 AudioStation 业务方法，向上对 Riverpod 暴露
class LibraryRepository implements LibraryAccess {
  final ApiInfo _apiInfo;
  final ApiAuth _apiAuth;
  final AudioStationApi _audioApi;
  final QuickConnect _qc;
  final DioClient _client;
  final DownloadApi _downloadApi;

  LibraryRepository({
    required ApiInfo apiInfo,
    required ApiAuth apiAuth,
    required AudioStationApi audioApi,
    required QuickConnect quickConnect,
    required DioClient client,
    required DownloadApi downloadApi,
  })  : _apiInfo = apiInfo,
        _apiAuth = apiAuth,
        _audioApi = audioApi,
        _qc = quickConnect,
        _client = client,
        _downloadApi = downloadApi;

  QuickConnect get quickConnect => _qc;
  DownloadApi get downloadApi => _downloadApi;
  DioClient get client => _client;

  // —— 鉴权 ——
  Future<String> login({
    required ServerConfig config,
    required String account,
    required String passwd,
    String? otpCode,
  }) async {
    _client.sid = null;
    return _apiAuth.login(account: account, passwd: passwd, otpCode: otpCode);
  }

  Future<void> logout() => _apiAuth.logout();

  // —— Albums / Artists / Songs / Folders / Playlists ——
  Future<List<Album>> albums({String? keyword, int offset = 0}) =>
      _audioApi.listAlbums(keyword: keyword, offset: offset);

  Future<({Album album, List<Song> songs})> albumDetail(String id) =>
      _audioApi.getAlbumDetail(id);

  Future<List<Artist>> artists({String? keyword}) =>
      _audioApi.listArtists(keyword: keyword);

  Future<({Artist artist, List<Album> albums})> artistDetail(String id) =>
      _audioApi.getArtistDetail(id);

  Future<List<Song>> songs(
          {String? keyword, String? albumId, String? artistId}) =>
      _audioApi.listSongs(
          keyword: keyword, albumId: albumId, artistId: artistId);

  Future<List<Map<String, dynamic>>> folders({String? parentId}) =>
      _audioApi.listFolders(parentId: parentId);

  Future<List<Playlist>> playlists() => _audioApi.listPlaylists();
  Future<Playlist> playlistDetail(String id) => _audioApi.getPlaylistDetail(id);
  Future<Playlist> createPlaylist(String name) =>
      _audioApi.createPlaylist(name);
  Future<void> deletePlaylist(String id) => _audioApi.deletePlaylist(id);
  Future<void> updatePlaylist({
    required String id,
    String? name,
    List<String>? addSongIds,
    List<String>? removeSongIds,
  }) =>
      _audioApi.updatePlaylist(
        playlistId: id,
        name: name,
        songIdsToAdd: addSongIds,
        songIdsToRemove: removeSongIds,
      );

  // —— Search ——
  Future<({List<Album> albums, List<Artist> artists, List<Song> songs})> search(
          String keyword) =>
      _audioApi.search(keyword);

  // —— 歌词 ——
  /// 优先读接口返回的内嵌歌词；解析失败时返回空（UI 显示「暂无歌词」）
  Future<Lyrics> lyricsOf(Song song) async {
    try {
      final url = _audioApi.buildLyricsUrl(song.id);
      final resp = await _client.dio.get(url);
      final data = resp.data;
      if (data is String && data.trim().startsWith('[')) {
        return Lyrics.parse(data);
      }
      if (data is Map && data['data']?['lyrics'] is String) {
        return Lyrics.parse(data['data']['lyrics'] as String);
      }
      return const Lyrics();
    } catch (e) {
      AppLogger.w('读取歌词失败: $e');
      return const Lyrics();
    }
  }

  // —— 评分 / 收藏 ——
  Future<void> rate(Song song, int rating) => _audioApi.rate(song.id, rating);

  // —— 流媒体 / 封面 URL ——
  @override
  String streamUrl(Song song,
      {bool forceTranscode = false, bool preferLossless = false}) {
    return _audioApi.buildStreamUrl(
      song,
      forceTranscode: forceTranscode,
      preferLossless: preferLossless,
    );
  }

  @override
  String coverUrl(String albumId, {String size = 'mid'}) =>
      _audioApi.buildCoverUrl(albumId, size: size);

  String artistThumb(String id) => _audioApi.buildThumbUrl(id);
}
