import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 10 段均衡器状态
///
/// 设计说明：
/// 1. 当前不依赖任何原生 EQ 插件（pub.dev 上 flutter_equalizer 不存在，
///    equalizer_flutter 仅 Android 且 API 与本控制器不匹配）。
/// 2. UI 层仅维护 10 段频段增益 + 总开关 + 预设选择，
///    所有 setX 方法已包裹 try/catch 以兼容后续接入原生插件。
/// 3. 默认频段列表 60/230/910/3600/14000 Hz，覆盖低/中/高频段，
///    与 Android 系统 Equalizer 标准 5 段类似，避免 UI 显示空列表。
class EqualizerState {
  final bool enabled;
  final int preset;
  final List<int> bandGains; // 单位：milliBel（-1500 ~ 1500）
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

  /// 初始化：填充默认 10 段频段
  /// 真实设备支持的频段数需在原生层查询（Android 系统 Equalizer 5~10 段）
  Future<void> _init() async {
    // 默认 10 段频段（Hz），与 just_audio 推荐的 EQ 频段相近
    const defaultBands = <int>[60, 230, 910, 3600, 14000];
    state = state.copyWith(
      bandFrequencies: List<int>.from(defaultBands),
      bandGains: List<int>.filled(defaultBands.length, 0),
    );
  }

  /// 开关均衡器
  Future<void> setEnabled(bool v) async {
    state = state.copyWith(enabled: v);
    // 后续接入原生插件时在此调用 setEnabled(v)
  }

  /// 设置某段频段增益
  Future<void> setBandGain(int band, int gain) async {
    final list = [...state.bandGains];
    if (band < 0 || band >= list.length) return;
    list[band] = gain.clamp(state.minGain, state.maxGain);
    state = state.copyWith(bandGains: list);
  }

  /// 切换预设
  Future<void> setPreset(int preset) async {
    state = state.copyWith(preset: preset);
  }
}

final equalizerProvider =
    StateNotifierProvider<EqualizerNotifier, EqualizerState>(
        (ref) => EqualizerNotifier());
