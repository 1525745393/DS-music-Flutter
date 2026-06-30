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
  String get useHttps => isEnglish ? 'Use HTTPS (self-signed)' : '使用 HTTPS（自签证书）';
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
  String get sidExpired => isEnglish
      ? 'Session expired, please sign in again'
      : '登录已过期，请重新登录';
  String get permissionDenied => isEnglish ? 'Permission denied' : '权限不足';
}

/// BuildContext 扩展：让 [context.s.xxx] 语法糖可用
/// 关键变更：A4 修复后所有 widget 可直接 `context.s.login` 访问字符串
extension AppStringsContext on BuildContext {
  AppStrings get s => AppStrings.ofContext(this);
}
