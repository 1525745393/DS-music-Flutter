import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/settings_provider.dart';

/// DS Player 本地化字符串
/// 说明：避免接入完整 ARB 工具链，使用简单类提供中英双语。
///
/// 调用方式：
/// 1. BuildContext 扩展（推荐）：`context.s.login`
/// 2. 直接构造：`AppStrings.of('en').login`
/// 3. 旧 API 兼容：`AppStrings.of(context)`，内部从 settingsProvider 读 localeCode
class AppStrings {
  final String locale; // 'zh' | 'en'
  AppStrings._(this.locale);

  bool get isEnglish => locale == 'en';

  /// 旧 API 兼容：根据 Locale 字符串返回实例
  static AppStrings of(String? locale) {
    if (locale != null && locale.startsWith('en')) return AppStrings._('en');
    return AppStrings._('zh');
  }

  /// 新 API：从 BuildContext 解析当前 locale
  /// 优先用 settingsProvider.localeCode（用户手动选择），
  /// 否则回退到 Localizations（系统语言）。
  static AppStrings ofContext(BuildContext context) {
    // 关键：try/catch 包住 ProviderScope 之外调用场景
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final code = container.read(settingsProvider).localeCode;
      if (code == 'zh' || code == 'en') return AppStrings._(code);
    } catch (_) {
      // ProviderScope 未挂载时回退到 Localizations
    }
    try {
      final loc = Localizations.localeOf(context);
      if (loc.languageCode == 'en') return AppStrings._('en');
    } catch (_) {}
    return AppStrings._('zh');
  }

  // —— 通用 ——
  String get appName => 'DS Player';
  String get cancel => isEnglish ? 'Cancel' : '取消';
  String get confirm => isEnglish ? 'Confirm' : '确认';
  String get delete => isEnglish ? 'Delete' : '删除';
  String get retry => isEnglish ? 'Retry' : '重试';
  String get done => isEnglish ? 'Done' : '完成';
  String get add => isEnglish ? 'Add' : '添加';
  String get edit => isEnglish ? 'Edit' : '编辑';
  String get save => isEnglish ? 'Save' : '保存';
  String get search => isEnglish ? 'Search' : '搜索';
  String get settings => isEnglish ? 'Settings' : '设置';
  String get close => isEnglish ? 'Close' : '关闭';

  // —— 登录 ——
  String get login => isEnglish ? 'Sign In' : '登录';
  String get account => isEnglish ? 'Account' : '账号';
  String get password => isEnglish ? 'Password' : '密码';
  String get server => isEnglish ? 'Server' : '服务器';
  String get port => isEnglish ? 'Port' : '端口';
  String get useHttps =>
      isEnglish ? 'Use HTTPS (self-signed)' : '使用 HTTPS（自签证书）';
  String get connectToNas => isEnglish
      ? 'Connect to your Synology AudioStation'
      : '连接你的群晖 AudioStation';
  String get loggingIn => isEnglish ? 'Signing in...' : '登录中...';

  // —— 首页 ——
  String get music => isEnglish ? 'Music' : '音乐';
  String get albums => isEnglish ? 'Albums' : '专辑';
  String get artists => isEnglish ? 'Artists' : '艺术家';
  String get songs => isEnglish ? 'Songs' : '歌曲';
  String get folders => isEnglish ? 'Folders' : '文件夹';
  String get playlists => isEnglish ? 'Playlists' : '歌单';

  // —— 播放 ——
  String get nowPlaying => isEnglish ? 'Now Playing' : '正在播放';
  String get queue => isEnglish ? 'Up Next' : '播放队列';
  String get shuffle => isEnglish ? 'Shuffle' : '随机';
  String get repeat => isEnglish ? 'Repeat' : '循环';
  String get sleepTimer => isEnglish ? 'Sleep Timer' : '睡眠定时';
  String get downloadAll => isEnglish ? 'Download All' : '下载全部';

  // —— 设置 ——
  String get appearance => isEnglish ? 'Appearance' : '外观';
  String get playback => isEnglish ? 'Playback' : '播放';
  String get storage => isEnglish ? 'Storage' : '存储';
  String get accountGroup => isEnglish ? 'Account' : '账号';
  String get followSystemTheme => isEnglish ? 'Follow System Theme' : '跟随系统主题';
  String get darkMode => isEnglish ? 'Dark Mode' : '深色模式';
  String get gapless => isEnglish ? 'Gapless Playback' : '无缝播放';
  String get volumeNormalize => isEnglish ? 'Volume Normalization' : '音量标准化';
  String get equalizer => isEnglish ? 'Equalizer' : '均衡器';
  String get cacheManagement => isEnglish ? 'Cache Management' : '缓存管理';
  String get servers => isEnglish ? 'Servers' : '服务器';
  String get dlnaDevices => isEnglish ? 'DLNA Devices' : 'DLNA 设备';
  String get logout => isEnglish ? 'Sign Out' : '退出登录';

  // —— 状态 ——
  String get loading => isEnglish ? 'Loading...' : '加载中...';
  String get empty => isEnglish ? 'No data' : '暂无数据';
  String get networkError => isEnglish ? 'Network error' : '网络异常';

  // —— 错误信息 ——
  String get loginFailed => isEnglish ? 'Login failed' : '登录失败';
  String get sidExpired =>
      isEnglish ? 'Session expired, please sign in again' : '登录已过期，请重新登录';
  String get permissionDenied => isEnglish ? 'Permission denied' : '权限不足';
  String get tip => isEnglish ? 'Tip' : '提示';
  String get retryLater => isEnglish ? 'Please try again later' : '请稍后重试';

  // —— 登录页 ——
  String get modeLan => isEnglish ? 'LAN' : '内网';
  String get modeDdns => isEnglish ? 'Domain' : '域名';
  String get quickConnect => 'QuickConnect';
  String get hintAccount => isEnglish ? 'Synology account' : '群晖账号';
  String get hintPassword => isEnglish ? 'Enter password' : '请输入密码';
  String get pleaseFillAccount =>
      isEnglish ? 'Please enter account and password' : '请填写账号和密码';
  String get pleaseFillServer =>
      isEnglish ? 'Please enter server address' : '请填写服务器地址';
  String get pleaseFillQcId =>
      isEnglish ? 'Please enter QuickConnect ID' : '请填写 QuickConnect ID';
  String get qcResolveFailed =>
      isEnglish ? 'Failed to resolve QuickConnect' : 'QuickConnect 解析失败';
  String get qcWaitAuthorize =>
      isEnglish ? 'Please approve this device on NAS' : '请在 NAS 后台允许此设备的访问请求';
  String get qcTimeout =>
      isEnglish ? 'QuickConnect authorization timeout' : 'QuickConnect 授权超时';
  String get qcRouteFailed =>
      isEnglish ? 'Cannot resolve available route' : '未能解析出可用线路';
  String get agree => isEnglish
      ? 'By signing in, you agree to the User Agreement and Privacy Policy'
      : '登录即代表同意《用户协议》与《隐私政策》';

  // —— 引导页 ——
  String get onboardSkip => isEnglish ? 'Skip' : '跳过';
  String get onboardNext => isEnglish ? 'Next' : '下一步';
  String get onboardStart => isEnglish ? 'Get Started' : '开始体验';
  String get onboard1Title =>
      isEnglish ? 'Welcome to DS Player' : '欢迎使用 DS Player';
  String get onboard1Subtitle => isEnglish
      ? 'A mobile music client for Synology & Plex'
      : '为 Synology / Plex 打造的移动端音乐客户端';
  String get onboard2Title => isEnglish ? 'Smart Network Switch' : '智能网络切换';
  String get onboard2Subtitle => isEnglish
      ? 'Lossless over WiFi\nAuto-transcode on cellular'
      : 'WiFi 下播放无损音质\n蜂窝下自动转码节省流量';
  String get onboard3Title =>
      isEnglish ? 'Floating Lyrics & Lock Screen' : '悬浮歌词 + 锁屏控制';
  String get onboard3Subtitle => isEnglish
      ? 'Browse and view lyrics while playing in background'
      : '后台播放时仍可浏览与查看歌词';
  String get onboard4Title =>
      isEnglish ? 'Android Auto Support' : '支持 Android Auto';
  String get onboard4Subtitle =>
      isEnglish ? 'Browse your library in the car' : '在车载系统中浏览你的私人曲库';

  // —— 主导航 ——
  String get tabMusic => isEnglish ? 'Music' : '音乐';
  String get tabAlbums => isEnglish ? 'Albums' : '专辑';
  String get tabArtists => isEnglish ? 'Artists' : '艺术家';
  String get tabFolders => isEnglish ? 'Folders' : '文件夹';
  String get tabPlaylists => isEnglish ? 'Playlists' : '歌单';

  // —— 播放相关 ——
  String get newPlaylist => isEnglish ? 'New Playlist' : '新建歌单';
  String get playlistName => isEnglish ? 'Playlist name' : '歌单名称';
  String get addToPlaylist => isEnglish ? 'Add to Playlist' : '添加到歌单';
  String get playAll => isEnglish ? 'Play All' : '播放全部';
  String get shufflePlay => isEnglish ? 'Shuffle Play' : '随机播放';

  // —— 服务器与缓存 ——
  String get addServer => isEnglish ? 'Add Server' : '添加服务器';
  String get editServer => isEnglish ? 'Edit Server' : '编辑服务器';
  String get deleteServer => isEnglish ? 'Delete Server' : '删除服务器';
  String get clearCache => isEnglish ? 'Clear Cache' : '清理缓存';
  String get cacheSize => isEnglish ? 'Cache Size' : '缓存大小';
  String get scanCache => isEnglish ? 'Scan Cache' : '扫描缓存';

  // —— DLNA ——
  String get dlnaCastCurrent => isEnglish ? 'Cast Now Playing' : '投屏当前播放';
  String get dlnaControl => isEnglish ? 'Remote Control' : '远程控制';
  String get dlnaVolume => isEnglish ? 'Volume' : '音量';

  // —— 悬浮歌词 ——
  String get overlayLyrics => isEnglish ? 'Floating Lyrics' : '悬浮歌词';
  String get overlayFontSize => isEnglish ? 'Font Size' : '字号';
  String get overlayPosition => isEnglish ? 'Position' : '位置';
  String get overlayEnabled => isEnglish ? 'Enable' : '启用';

  // —— 通用动作 ——
  String get deleteConfirm => isEnglish ? 'Delete?' : '确认删除？';
  String get logoutConfirm => isEnglish ? 'Sign out?' : '确认退出当前账号？';
  String get yes => isEnglish ? 'Yes' : '是';
  String get no => isEnglish ? 'No' : '否';
}

/// BuildContext 扩展：让 [context.s.xxx] 语法糖可用
/// 关键变更：A4 修复后所有 widget 可直接 `context.s.login` 访问字符串
extension AppStringsContext on BuildContext {
  AppStrings get s => AppStrings.ofContext(this);
}
