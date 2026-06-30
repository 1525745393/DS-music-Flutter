import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'model/song.dart';
import 'player/audio_handler.dart';
import 'player/playback_service.dart';
import 'provider/auth_provider.dart';
import 'provider/core_providers.dart';
import 'provider/settings_provider.dart';
import 'pages/login/login_page.dart';
import 'pages/main_shell.dart';
import 'theme/app_theme.dart';
import 'utils/logger.dart';
import 'utils/permissions.dart';

/// 应用入口
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 沉浸式状态栏：透明 + 暗色文字
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0x00000000),
    statusBarIconBrightness: Brightness.light,
  ));
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // 1. 启动 just_audio_background（锁屏媒体控件 + 通知栏）
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.dsplayer.audio',
    androidNotificationChannelName: 'DS Player 播放',
    androidNotificationOngoing: true,
  );

  // 2. 加载持久化
  final sp = await SharedPreferences.getInstance();

  // 3. 构造根 ProviderContainer
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
  );

  // 4. 启动后台播放服务
  // 设计原因：handler 仅在调用 setQueueAndPlay 时才真正访问 repo
  // 因此允许在 ProviderContainer 还未注入 LibraryRepository 时创建
  final handler = await AudioService.init<DSPlayerHandler>(
    builder: () {
      return DSPlayerHandler(
        repoGetter: () {
          try {
            return container.read(libraryRepositoryProvider) as dynamic;
          } catch (_) {
            return _NullAccess();
          }
        },
        settingsGetter: () {
          try {
            final s = container.read(settingsProvider);
            return SettingsPort(
              forceLossless: s.forceLossless,
              normalizeVolume: s.normalizeVolume,
              gaplessEnabled: s.gaplessEnabled,
            );
          } catch (_) {
            return const SettingsPort();
          }
        },
      );
    },
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.dsplayer.audio',
      androidNotificationChannelName: 'DS Player 播放',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  // 5. 首次启动请求关键权限
  try {
    await AppPermissions.requestStartupPermissions();
  } catch (e) {
    AppLogger.w('权限请求失败：$e');
  }

  runApp(ProviderScope(
    parent: container,
    overrides: [audioHandlerProvider.overrideWithValue(handler)],
    child: const DSPlayerApp(),
  ));
}

/// 未登录时的占位访问对象：避免在登录前 handler 误用
class _NullAccess implements LibraryAccess {
  @override
  String coverUrl(String albumId, {String size = 'mid'}) => '';
  @override
  String streamUrl(Song song, {bool forceTranscode = false, bool preferLossless = false}) => '';
}

/// 应用根
class DSPlayerApp extends ConsumerStatefulWidget {
  const DSPlayerApp({super.key});

  @override
  ConsumerState<DSPlayerApp> createState() => _DSPlayerAppState();
}

class _DSPlayerAppState extends ConsumerState<DSPlayerApp> {
  @override
  void initState() {
    super.initState();
    PlatformDispatcher.instance.onPlatformBrightnessChanged = () {
      if (mounted) setState(() {});
    };
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    return CupertinoApp(
      title: 'DS Player',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('zh', 'CN'),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: isLoggedIn
            ? const MainShell(key: ValueKey('main'))
            : const LoginPage(key: ValueKey('login')),
      ),
    );
  }
}
