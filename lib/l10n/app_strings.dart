/// DS Player 本地化字符串
/// 说明：避免接入 ARB 工具链的复杂度，使用简单类提供中英双语
/// 调用：AppStrings.of(context).login
class AppStrings {
  final String locale;
  AppStrings._(this.locale);

  static AppStrings of(String? locale) {
    if (locale != null && locale.startsWith('en')) return AppStrings._('en');
    return AppStrings._('zh');
  }

  // —— 通用 ——
  String get appName => locale == 'en' ? 'DS Player' : 'DS Player';
  String get cancel => locale == 'en' ? 'Cancel' : '取消';
  String get confirm => locale == 'en' ? 'Confirm' : '确认';
  String get delete => locale == 'en' ? 'Delete' : '删除';
  String get retry => locale == 'en' ? 'Retry' : '重试';
  String get done => locale == 'en' ? 'Done' : '完成';
  String get add => locale == 'en' ? 'Add' : '添加';
  String get edit => locale == 'en' ? 'Edit' : '编辑';
  String get save => locale == 'en' ? 'Save' : '保存';
  String get search => locale == 'en' ? 'Search' : '搜索';
  String get settings => locale == 'en' ? 'Settings' : '设置';
  String get close => locale == 'en' ? 'Close' : '关闭';

  // —— 登录 ——
  String get login => locale == 'en' ? 'Sign In' : '登录';
  String get account => locale == 'en' ? 'Account' : '账号';
  String get password => locale == 'en' ? 'Password' : '密码';
  String get server => locale == 'en' ? 'Server' : '服务器';
  String get port => locale == 'en' ? 'Port' : '端口';
  String get useHttps => locale == 'en' ? 'Use HTTPS (self-signed)' : '使用 HTTPS（自签证书）';
  String get connectToNas => locale == 'en' ? 'Connect to your Synology AudioStation' : '连接你的群晖 AudioStation';
  String get loggingIn => locale == 'en' ? 'Signing in...' : '登录中...';

  // —— 首页 ——
  String get music => locale == 'en' ? 'Music' : '音乐';
  String get albums => locale == 'en' ? 'Albums' : '专辑';
  String get artists => locale == 'en' ? 'Artists' : '艺术家';
  String get songs => locale == 'en' ? 'Songs' : '歌曲';
  String get folders => locale == 'en' ? 'Folders' : '文件夹';
  String get playlists => locale == 'en' ? 'Playlists' : '歌单';

  // —— 播放 ——
  String get nowPlaying => locale == 'en' ? 'Now Playing' : '正在播放';
  String get queue => locale == 'en' ? 'Up Next' : '播放队列';
  String get shuffle => locale == 'en' ? 'Shuffle' : '随机';
  String get repeat => locale == 'en' ? 'Repeat' : '循环';
  String get sleepTimer => locale == 'en' ? 'Sleep Timer' : '睡眠定时';
  String get downloadAll => locale == 'en' ? 'Download All' : '下载全部';

  // —— 设置 ——
  String get appearance => locale == 'en' ? 'Appearance' : '外观';
  String get playback => locale == 'en' ? 'Playback' : '播放';
  String get storage => locale == 'en' ? 'Storage' : '存储';
  String get accountGroup => locale == 'en' ? 'Account' : '账号';
  String get followSystemTheme => locale == 'en' ? 'Follow System Theme' : '跟随系统主题';
  String get darkMode => locale == 'en' ? 'Dark Mode' : '深色模式';
  String get gapless => locale == 'en' ? 'Gapless Playback' : '无缝播放';
  String get volumeNormalize => locale == 'en' ? 'Volume Normalization' : '音量标准化';
  String get equalizer => locale == 'en' ? 'Equalizer' : '均衡器';
  String get cacheManagement => locale == 'en' ? 'Cache Management' : '缓存管理';
  String get servers => locale == 'en' ? 'Servers' : '服务器';
  String get dlnaDevices => locale == 'en' ? 'DLNA Devices' : 'DLNA 设备';
  String get logout => locale == 'en' ? 'Sign Out' : '退出登录';

  // —— 状态 ——
  String get loading => locale == 'en' ? 'Loading...' : '加载中...';
  String get empty => locale == 'en' ? 'No data' : '暂无数据';
  String get networkError => locale == 'en' ? 'Network error' : '网络异常';

  // —— 错误信息 ——
  String get loginFailed => locale == 'en' ? 'Login failed' : '登录失败';
  String get sidExpired => locale == 'en' ? 'Session expired, please sign in again' : '登录已过期，请重新登录';
  String get permissionDenied => locale == 'en' ? 'Permission denied' : '权限不足';
}
