/// Synology AudioStation 全部接口名常量定义
/// 之所以抽离：避免接口路径在多个文件中硬编码，便于维护与版本升级
class ApiConstants {
  ApiConstants._();

  // —— 基础鉴权与元信息 ——
  static const String apiInfo = 'SYNO.API.Info';
  static const String apiAuth = 'SYNO.API.Auth';

  // —— AudioStation 业务接口 ——
  static const String audioStationInfo = 'SYNO.AudioStation.Info';
  static const String audioStationArtist = 'SYNO.AudioStation.Artist';
  static const String audioStationAlbum = 'SYNO.AudioStation.Album';
  static const String audioStationSong = 'SYNO.AudioStation.Song';
  static const String audioStationFolder = 'SYNO.AudioStation.Folder';
  static const String audioStationPlaylist = 'SYNO.AudioStation.Playlist';
  static const String audioStationStream = 'SYNO.AudioStation.Stream';
  static const String audioStationLyrics = 'SYNO.AudioStation.Lyrics';
  static const String audioStationDownload = 'SYNO.AudioStation.Download';
  static const String audioStationCover = 'SYNO.AudioStation.Cover';
  static const String audioStationSearch = 'SYNO.AudioStation.Search';
  static const String audioStationRating = 'SYNO.AudioStation.Rating';
  static const String audioStationExternalPlayer =
      'SYNO.AudioStation.ExternalPlayer';

  // —— QuickConnect ——
  static const String quickConnectId = 'SYNO.QuickConnect.ID';
  static const String quickConnectAuth = 'SYNO.QuickConnect.Auth';

  // —— WebAPI 公开路径 ——
  static const String infoPath = 'webapi/query.cgi';
  static const String authPath = 'webapi/auth.cgi';
  static const String entryPath = 'webapi/entry.cgi';
  static const String streamPath = 'webapi/AudioStation/stream.cgi';
  static const String coverPath = 'webapi/AudioStation/cover.cgi';
  static const String lyricsPath = 'webapi/AudioStation/lyrics.cgi';
  static const String downloadPath = 'webapi/AudioStation/download.cgi';
  static const String thumbPath = 'webapi/AudioStation/thumb.cgi';

  // —— 默认端口 ——
  static const int defaultHttpPort = 5000;
  static const int defaultHttpsPort = 5001;
  static const int timeoutSeconds = 15;
  static const int retryCount = 2;

  // —— 默认转码参数（蜂窝网络下使用）——
  static const String transcodeMp3 = 'mp3';
  static const int transcodeBitrate = 128000; // 128kbps
  static const int transcodeSampleRate = 44100; // 44.1kHz
}
