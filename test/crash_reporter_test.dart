import 'package:flutter_test/flutter_test.dart';
import 'package:ds_music_flutter/utils/crash_reporter.dart';

void main() {
  group('PerfMonitor', () {
    test('start/end 返回耗时', () async {
      final perf = PerfMonitor.instance;
      perf.start('t1');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final ms = perf.end('t1', tag: 'unit');
      expect(ms, isNotNull);
      expect(ms! >= 25, isTrue, reason: '耗时应在 25ms 以上');
    });

    test('track 包装 task', () async {
      final result = await PerfMonitor.instance.track<String>(
        't2',
        () async {
          await Future<void>.delayed(const Duration(milliseconds: 5));
          return 'ok';
        },
        tag: 'unit',
      );
      expect(result, 'ok');
    });

    test('未 start 直接 end 返回 null', () {
      final ms = PerfMonitor.instance.end('never-started');
      expect(ms, isNull);
    });
  });

  group('CrashReporter', () {
    test('init 不重复注册', () {
      CrashReporter.instance.init();
      CrashReporter.instance.init();
      // 仅验证无异常
    });

    test('reportError 不抛异常', () {
      CrashReporter.instance
          .reportError(Exception('test'), StackTrace.current, tag: 'unit');
    });
  });
}
