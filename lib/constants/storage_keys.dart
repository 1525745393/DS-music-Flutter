/// SharedPreferences 存储 Key 统一管理
class StorageKeys {
  StorageKeys._();

  // 服务器配置
  static const String serverList = 'ds_server_list';
  static const String currentServerId = 'ds_current_server_id';

  // 登录
  static const String sid = 'ds_sid';
  static const String sidExpire = 'ds_sid_expire';
  static const String account = 'ds_account';
  static const String isHttps = 'ds_is_https';

  // 播放
  static const String playMode = 'ds_play_mode'; // 0/1/2
  static const String playVolume = 'ds_play_volume';
  static const String playSpeed = 'ds_play_speed';
  static const String lastQueue = 'ds_last_queue';
  static const String lastSongId = 'ds_last_song_id';
  static const String lastPositionMs = 'ds_last_position_ms';

  // 设置
  static const String downloadPath = 'ds_download_path';
  static const String transcodeBitrate = 'ds_transcode_bitrate';
  static const String transcodeFormat = 'ds_transcode_format';
  static const String forceLossless = 'ds_force_lossless';
  static const String followSystemTheme = 'ds_follow_system_theme';
  static const String themeMode = 'ds_theme_mode'; // 0 dark / 1 light
  static const String gaplessEnabled = 'ds_gapless_enabled';
  static const String normalizeVolume = 'ds_normalize_volume';

  // 缓存
  static const String cachedSizeBytes = 'ds_cached_size_bytes';

  // 均衡器
  static const String equalizerEnabled = 'ds_eq_enabled';
  static const String equalizerPreset = 'ds_eq_preset';
  static const String equalizerBands = 'ds_eq_bands';

  // 引导
  static const String firstLaunch = 'ds_first_launch';
  static const String permissionGranted = 'ds_permission_granted';
}
