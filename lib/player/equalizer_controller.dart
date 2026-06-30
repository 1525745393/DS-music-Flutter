import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_equalizer/flutter_equalizer.dart';

/// 10 段均衡器
class EqualizerState {
  final bool enabled;
  final int preset;
  final List<int> bandGains;  // 单位：milliBel（-1500 ~ 1500）
  final List<int> bandFrequencies; // Hz
  final int minGain;
  final int maxGain;

  const EqualizerState({
    this.enabled = false,
    this.preset = 0,
    this.bandGains = const [],
    this.bandFrequencies = const [],
    this.minGain = -1500,
    this.maxGain = 1500,
  });

  EqualizerState copyWith({
    bool? enabled,
    int? preset,
    List<int>? bandGains,
  }) {
    return EqualizerState(
      enabled: enabled ?? this.enabled,
      preset: preset ?? this.preset,
      bandGains: bandGains ?? this.bandGains,
      bandFrequencies: bandFrequencies,
      minGain: minGain,
      maxGain: maxGain,
    );
  }
}

class EqualizerNotifier extends StateNotifier<EqualizerState> {
  EqualizerNotifier() : super(const EqualizerState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      await FlutterEqualizer.init();
      final params = await FlutterEqualizer.getParameters();
      state = state.copyWith(
        bandFrequencies: List<int>.from(params.bandFrequencies ?? []),
      );
      // 默认 0dB
      state = state.copyWith(
        bandGains: List.filled(params.bandFrequencies?.length ?? 0, 0),
      );
    } catch (e) {
      // 设备可能不支持（iOS 暂未实现），安静失败
    }
  }

  Future<void> setEnabled(bool v) async {
    state = state.copyWith(enabled: v);
    try {
      await FlutterEqualizer.setEnabled(v);
    } catch (_) {}
  }

  Future<void> setBandGain(int band, int gain) async {
    final list = [...state.bandGains];
    if (band < 0 || band >= list.length) return;
    list[band] = gain.clamp(state.minGain, state.maxGain);
    state = state.copyWith(bandGains: list);
    try {
      await FlutterEqualizer.setBandGain(band, gain);
    } catch (_) {}
  }

  Future<void> setPreset(int preset) async {
    state = state.copyWith(preset: preset);
    try {
      await FlutterEqualizer.setPreset(preset);
    } catch (_) {}
  }
}

final equalizerProvider =
    StateNotifierProvider<EqualizerNotifier, EqualizerState>(
        (ref) => EqualizerNotifier());
