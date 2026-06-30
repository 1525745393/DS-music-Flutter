import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'playback_service.dart';

/// 睡眠定时
class SleepTimer {
  final int minutes;
  final void Function() onTimeout;
  Timer? _timer;
  final _remainingProvider = StateProvider<Duration>((ref) => Duration.zero);

  SleepTimer({required this.minutes, required this.onTimeout});

  void start(StateNotifierProviderRef<SleepTimerNotifier, Duration> ref) {
    _timer?.cancel();
    _remaining = Duration(minutes: minutes);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _remaining -= const Duration(seconds: 1);
      if (_remaining <= Duration.zero) {
        t.cancel();
        onTimeout();
      }
    });
  }

  Duration _remaining = Duration.zero;
  Duration get remaining => _remaining;

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _remaining = Duration.zero;
  }
}

class SleepTimerNotifier extends StateNotifier<Duration> {
  final Ref ref;
  SleepTimer? _timer;

  SleepTimerNotifier(this.ref) : super(Duration.zero);

  /// 启动定时（minutes 分钟后停止播放）
  void start(int minutes) {
    cancel();
    _timer = SleepTimer(
      minutes: minutes,
      onTimeout: () async {
        final handler = ref.read(audioHandlerProvider);
        await handler.pause();
        state = Duration.zero;
      },
    );
    _timer!.start(ref);
    state = Duration(minutes: minutes);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    state = Duration.zero;
  }
}

final sleepTimerProvider =
    StateNotifierProvider<SleepTimerNotifier, Duration>(
        (ref) => SleepTimerNotifier(ref));
