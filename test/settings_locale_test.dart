import 'package:ds_music_flutter/provider/settings_provider.dart';
import 'package:ds_music_flutter/constants/storage_keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsNotifier', () {
    late ProviderContainer container;
    late SharedPreferences sp;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      sp = await SharedPreferences.getInstance();
      container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
      ]);
    });
    tearDown(() => container.dispose());

    test('默认值', () {
      final s = container.read(settingsProvider);
      expect(s.followSystemTheme, true);
      expect(s.isDark, true);
      expect(s.playMode, 0);
      expect(s.transcodeBitrate, 320000);
      expect(s.transcodeFormat, 'mp3');
      expect(s.forceLossless, false);
      expect(s.gaplessEnabled, true);
      expect(s.equalizerEnabled, false);
      expect(s.localeCode, 'system');
    });

    test('setLocaleCode 持久化 + 通知', () async {
      final notifier = container.read(settingsProvider.notifier);
      await notifier.setLocaleCode('en');
      final s = container.read(settingsProvider);
      expect(s.localeCode, 'en');
      // 验证持久化
      expect(sp.getString(StorageKeys.localeCode), 'en');
    });

    test('setVolume clamp 到 [0,1]', () async {
      final notifier = container.read(settingsProvider.notifier);
      await notifier.setVolume(0.5);
      expect(container.read(settingsProvider).volume, 0.5);
    });

    test('setTranscodeFormat', () async {
      final notifier = container.read(settingsProvider.notifier);
      await notifier.setTranscodeFormat('flac');
      expect(container.read(settingsProvider).transcodeFormat, 'flac');
    });

    test('setTranscodeBitrate', () async {
      final notifier = container.read(settingsProvider.notifier);
      await notifier.setTranscodeBitrate(128000);
      expect(container.read(settingsProvider).transcodeBitrate, 128000);
    });

    test('setEqEnabled', () async {
      final notifier = container.read(settingsProvider.notifier);
      await notifier.setEqEnabled(true);
      expect(container.read(settingsProvider).equalizerEnabled, true);
    });

    test('setPlayMode', () async {
      final notifier = container.read(settingsProvider.notifier);
      await notifier.setPlayMode(2);
      expect(container.read(settingsProvider).playMode, 2);
    });
  });
}
