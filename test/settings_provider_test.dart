import 'package:flutter_test/flutter_test.dart';
import 'package:ds_music_flutter/provider/settings_provider.dart';

void main() {
  group('SettingsState', () {
    test('默认值正确', () {
      const s = SettingsState();
      expect(s.followSystemTheme, isTrue);
      expect(s.isDark, isTrue);
      expect(s.playMode, 0);
      expect(s.transcodeBitrate, 320000);
      expect(s.transcodeFormat, 'mp3');
      expect(s.forceLossless, isFalse);
      expect(s.forceTranscodeOnMobile, isTrue);
      expect(s.gaplessEnabled, isTrue);
      expect(s.normalizeVolume, isFalse);
    });

    test('copyWith 正确合并', () {
      const s = SettingsState();
      final s2 = s.copyWith(
        forceLossless: true,
        transcodeBitrate: 192000,
        forceTranscodeOnMobile: false,
      );
      expect(s2.forceLossless, isTrue);
      expect(s2.transcodeBitrate, 192000);
      expect(s2.forceTranscodeOnMobile, isFalse);
      expect(s2.gaplessEnabled, isTrue); // 保留旧值
    });
  });
}
