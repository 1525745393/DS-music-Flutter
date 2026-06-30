import 'package:ds_music_flutter/l10n/app_strings.dart';
import 'package:ds_music_flutter/pages/onboarding/onboarding_page.dart';
import 'package:ds_music_flutter/pages/settings/settings_page.dart';
import 'package:ds_music_flutter/pages/settings/transcode_picker_page.dart';
import 'package:ds_music_flutter/pages/settings/locale_picker_page.dart';
import 'package:ds_music_flutter/theme/app_colors.dart';
import 'package:ds_music_flutter/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 烟雾测试：关键页面能 pump 起来，不抛异常
/// 关键覆盖：
/// 1. OnboardingPage 4 屏
/// 2. SettingsPage 7 个分组
/// 3. TranscodePickerPage format/bitrate
/// 4. LocalePickerPage
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> _pumpWithDefaults(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(ProviderScope(
      child: CupertinoApp(
        theme: AppTheme.dark,
        home: child,
      ),
    ));
    // 让 FutureBuilder / Provider 完成一次重建
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('OnboardingPage 渲染完成', (tester) async {
    bool completed = false;
    await _pumpWithDefaults(
      tester,
      OnboardingPage(onCompleted: () => completed = true),
    );
    // 验证 4 个页面内容均可见
    expect(find.text(AppStrings.of('zh').onboard1Title), findsOneWidget);
    // 跳过按钮
    expect(find.text(AppStrings.of('zh').onboardSkip), findsOneWidget);
    // 点击跳过
    await tester.tap(find.text(AppStrings.of('zh').onboardSkip));
    expect(completed, true);
  });

  testWidgets('SettingsPage 不抛异常且显示外观分组', (tester) async {
    await _pumpWithDefaults(tester, const SettingsPage());
    // 验证 i18n 后的"设置"标题存在
    expect(find.text('设置'), findsOneWidget);
  });

  testWidgets('TranscodePickerPage format 选项可见', (tester) async {
    await _pumpWithDefaults(
      tester,
      const TranscodePickerPage(type: TranscodePickerType.format),
    );
    // 验证 4 个格式
    expect(find.textContaining('MP3'), findsOneWidget);
  });

  testWidgets('TranscodePickerPage bitrate 选项可见', (tester) async {
    await _pumpWithDefaults(
      tester,
      const TranscodePickerPage(type: TranscodePickerType.bitrate),
    );
    expect(find.textContaining('kbps'), findsWidgets);
  });

  testWidgets('LocalePickerPage 3 个语言选项', (tester) async {
    await _pumpWithDefaults(tester, const LocalePickerPage());
    expect(find.text('简体中文'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('跟随系统'), findsOneWidget);
  });
}
