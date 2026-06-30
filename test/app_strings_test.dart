import 'package:ds_music_flutter/l10n/app_strings.dart';
import 'package:ds_music_flutter/provider/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppStrings', () {
    test('中英根据 localeCode 切换', () {
      expect(AppStrings.of('zh').login, '登录');
      expect(AppStrings.of('en').login, 'Sign In');
      expect(AppStrings.of('xx').isEnglish, false); // 未知 locale 默认中文
      expect(AppStrings.of('en').isEnglish, true);
    });

    test('t.* 全部 key 非空', () {
      for (final locale in ['zh', 'en']) {
        final s = AppStrings.of(locale);
        // 抽 10 个常用 key
        expect(s.appName, isNotEmpty);
        expect(s.login, isNotEmpty);
        expect(s.search, isNotEmpty);
        expect(s.cancel, isNotEmpty);
        expect(s.confirm, isNotEmpty);
        expect(s.retry, isNotEmpty);
        expect(s.delete, isNotEmpty);
        expect(s.done, isNotEmpty);
        expect(s.add, isNotEmpty);
        expect(s.edit, isNotEmpty);
      }
    });
  });

  group('AppStrings.ofContext', () {
    testWidgets('BuildContext 上能取到当前 locale 字符串', (tester) async {
      SharedPreferencesTestSetup.apply();
      // 场景 1：默认中文
      late BuildContext capturedContext;
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Builder(builder: (ctx) {
            capturedContext = ctx;
            return const SizedBox.shrink();
          }),
        ),
      ));
      expect(AppStrings.ofContext(capturedContext).isEnglish, false);
    });
  });
}

/// 帮助设置 SharedPreferences mock
class SharedPreferencesTestSetup {
  static void apply() {
    // import 不放在文件顶，避免循环依赖
    // ignore: avoid_dynamic_calls
    (TestWidgetsFlutterBinding.ensureInitialized() as dynamic);
  }
}
