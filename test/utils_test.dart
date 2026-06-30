import 'package:flutter_test/flutter_test.dart';
import 'package:ds_music_flutter/utils/datetime_utils.dart';
import 'package:ds_music_flutter/utils/file_utils.dart';

void main() {
  group('DateTimeUtils', () {
    test('formatDuration hh:mm:ss', () {
      expect(
          DateTimeUtils.formatDuration(
              const Duration(hours: 1, minutes: 23, seconds: 45)),
          '1:23:45');
    });

    test('formatDuration mm:ss', () {
      expect(
          DateTimeUtils.formatDuration(const Duration(minutes: 3, seconds: 5)),
          '03:05');
    });

    test('formatSeconds', () {
      expect(DateTimeUtils.formatSeconds(125), '02:05');
    });
  });

  group('FileUtils', () {
    test('humanReadableSize', () {
      expect(FileUtils.humanReadableSize(512), '512 B');
      expect(FileUtils.humanReadableSize(1024), '1.00 KB');
      expect(FileUtils.humanReadableSize(1024 * 1024), '1.00 MB');
      expect(FileUtils.humanReadableSize(1024 * 1024 * 1024), '1.00 GB');
    });
  });
}
