import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'constants/storage_keys.dart';
import 'model/song.dart';
import 'player/android_auto_browse_tree.dart';
import 'player/audio_handler.dart';
import 'player/playback_service.dart';
import 'provider/auth_provider.dart';
import 'provider/core_providers.dart';
import 'provider/settings_provider.dart';
import 'repository/library_repository.dart';
import 'pages/login/login_page.dart';
import 'pages/main_shell.dart';
import 'pages/onboarding/onboarding_page.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'utils/crash_reporter.dart';
import 'utils/logger.dart';
import 'utils/permissions.dart';

/// 应用入口
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 0. 崩溃上报与性能监控
  CrashReporter.instance.init();

  // 沉浸式状态栏：透明 + 暗色文字
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0x00000000),
    statusBarIconBrightness: Brightness.light,
  ));
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // 1. 启动 just_audio_background（锁屏媒体控件 + 通知栏）
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.dsplayer.audio',
    androidNotificationChannelName: 'DS Player 播放',
    androidNotificationOngoing: true,
  );

  // 1.1 配置音频会话：处理来电/导航播报等音频焦点
  // 设计原因：iOS/Android 在来电、CarPlay、导航播报时会中断当前 App 音频，
  // 必须显式配置 AVAudioSession/Android AudioFocus 才能拿到 interruption 事件
  final audioSession = await AudioSession.instance;
  await audioSession.configure(const AudioSessionConfiguration.music());

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
              forceTranscodeOnMobile: s.forceTranscodeOnMobile,
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

  // 5.1 订阅音频焦点事件：来电/导航/CarPlay 触发时自动暂停
  // 设计原因：手机/车机场景下其他 App 抢占音频焦点是常态，
  // 应在硬件层面降级处理而不是依赖 UI 层监听
  audioSession.becomingNoisyEventStream.listen((_) {
    AppLogger.i('音频焦点丢失（耳机拔出 / 其他 App 抢占），自动暂停');
    handler.pause();
  });
  audioSession.interruptionEventStream.listen((event) {
    if (event.begin) {
      AppLogger.i('音频被打断：${event.type}');
      handler.pause();
    } else {
      // 中断结束：iOS/Android 由系统决定是否自动恢复，
      // 出于用户体验考虑不主动 resume，让用户手动点击
      AppLogger.i('音频中断结束');
    }
  });

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
  String streamUrl(Song song,
          {bool forceTranscode = false, bool preferLossless = false}) =>
      '';
}

/// 应用根
class DSPlayerApp extends ConsumerStatefulWidget {
  const DSPlayerApp({super.key});

  @override
  ConsumerState<DSPlayerApp> createState() => _DSPlayerAppState();
}

class _DSPlayerAppState extends ConsumerState<DSPlayerApp> {
  bool _showOnboarding = false;
  bool _onboardingChecked = false;

  @override
  void initState() {
    super.initState();
    PlatformDispatcher.instance.onPlatformBrightnessChanged = () {
      if (mounted) setState(() {});
    };
    _checkFirstLaunch();
  }

  /// 检查是否首次启动：仅一次，读取 SharedPreferences
  Future<void> _checkFirstLaunch() async {
    try {
      final sp = ref.read(sharedPreferencesProvider);
      final launched = sp.getBool(StorageKeys.firstLaunch) ?? true;
      if (mounted) {
        setState(() {
          _showOnboarding = launched;
          _onboardingChecked = true;
        });
      }
    } catch (e) {
      AppLogger.w('检查首启失败: $e');
      if (mounted) {
        setState(() {
          _showOnboarding = false;
          _onboardingChecked = true;
        });
      }
    }
  }

  void _finishOnboarding() {
    setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final localeCode = ref.watch(settingsProvider.select((s) => s.localeCode));
    // 启动检查未完成前先显示空白背景，避免闪现
    if (!_onboardingChecked) {
      return CupertinoApp(
        title: 'DS Player',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const ColoredBox(color: AppColors.darkBg),
      );
    }
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
      // 关键：根据 settings.localeCode 切换；'system' 表示 null 跟随系统
      locale: switch (localeCode) {
        'zh' => const Locale('zh', 'CN'),
        'en' => const Locale('en', 'US'),
        _ => null,
      },
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _showOnboarding
            ? OnboardingPage(
                key: const ValueKey('onboard'),
                onCompleted: _finishOnboarding,
              )
            : isLoggedIn
                ? const MainShell(key: ValueKey('main'))
                : const LoginPage(key: ValueKey('login')),
      ),
    );
  }
}
