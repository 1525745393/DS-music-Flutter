import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';
import 'core_providers.dart';

class SettingsState {
  final bool followSystemTheme;
  final bool isDark; // 仅在 !followSystem 时有效
  final int playMode; // 0 顺序 1 单曲 2 列表循环
  final int transcodeBitrate; // bps
  final String transcodeFormat; // mp3/aac/...
  final bool forceLossless;
  final bool forceTranscodeOnMobile; // 移动网络强制转码
  final bool gaplessEnabled;
  final bool normalizeVolume;
  final bool equalizerEnabled;
  final int equalizerPreset;
  final double volume;
  final double playSpeed;

  /// 语言：'system' / 'zh' / 'en'
  final String localeCode;

  const SettingsState({
    this.followSystemTheme = true,
    this.isDark = true,
    this.playMode = 0,
    this.transcodeBitrate = 320000,
    this.transcodeFormat = 'mp3',
    this.forceLossless = false,
    this.forceTranscodeOnMobile = true,
    this.gaplessEnabled = true,
    this.normalizeVolume = false,
    this.equalizerEnabled = false,
    this.equalizerPreset = 0,
    this.volume = 1.0,
    this.playSpeed = 1.0,
    this.localeCode = 'system',
  });

  SettingsState copyWith({
    bool? followSystemTheme,
    bool? isDark,
    int? playMode,
    int? transcodeBitrate,
    String? transcodeFormat,
    bool? forceLossless,
    bool? forceTranscodeOnMobile,
    bool? gaplessEnabled,
    bool? normalizeVolume,
    bool? equalizerEnabled,
    int? equalizerPreset,
    double? volume,
    double? playSpeed,
    String? localeCode,
  }) {
    return SettingsState(
      followSystemTheme: followSystemTheme ?? this.followSystemTheme,
      isDark: isDark ?? this.isDark,
      playMode: playMode ?? this.playMode,
      transcodeBitrate: transcodeBitrate ?? this.transcodeBitrate,
      transcodeFormat: transcodeFormat ?? this.transcodeFormat,
      forceLossless: forceLossless ?? this.forceLossless,
      forceTranscodeOnMobile:
          forceTranscodeOnMobile ?? this.forceTranscodeOnMobile,
      gaplessEnabled: gaplessEnabled ?? this.gaplessEnabled,
      normalizeVolume: normalizeVolume ?? this.normalizeVolume,
      equalizerEnabled: equalizerEnabled ?? this.equalizerEnabled,
      equalizerPreset: equalizerPreset ?? this.equalizerPreset,
      volume: volume ?? this.volume,
      playSpeed: playSpeed ?? this.playSpeed,
      localeCode: localeCode ?? this.localeCode,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SharedPreferences _sp;
  SettingsNotifier(this._sp) : super(_load(_sp));

  static SettingsState _load(SharedPreferences sp) {
    return SettingsState(
      followSystemTheme: sp.getBool(StorageKeys.followSystemTheme) ?? true,
      isDark: (sp.getInt(StorageKeys.themeMode) ?? 0) == 0,
      playMode: sp.getInt(StorageKeys.playMode) ?? 0,
      transcodeBitrate: sp.getInt(StorageKeys.transcodeBitrate) ?? 320000,
      transcodeFormat: sp.getString(StorageKeys.transcodeFormat) ?? 'mp3',
      forceLossless: sp.getBool(StorageKeys.forceLossless) ?? false,
      forceTranscodeOnMobile:
          sp.getBool(StorageKeys.forceTranscodeOnMobile) ?? true,
      gaplessEnabled: sp.getBool(StorageKeys.gaplessEnabled) ?? true,
      normalizeVolume: sp.getBool(StorageKeys.normalizeVolume) ?? false,
      equalizerEnabled: sp.getBool(StorageKeys.equalizerEnabled) ?? false,
      equalizerPreset: sp.getInt(StorageKeys.equalizerPreset) ?? 0,
      volume: sp.getDouble(StorageKeys.playVolume) ?? 1.0,
      playSpeed: sp.getDouble(StorageKeys.playSpeed) ?? 1.0,
    );
  }

  Future<void> setFollowSystemTheme(bool v) async {
    state = state.copyWith(followSystemTheme: v);
    await _sp.setBool(StorageKeys.followSystemTheme, v);
  }

  Future<void> setDark(bool v) async {
    state = state.copyWith(isDark: v);
    await _sp.setInt(StorageKeys.themeMode, v ? 0 : 1);
  }

  Future<void> setPlayMode(int v) async {
    state = state.copyWith(playMode: v);
    await _sp.setInt(StorageKeys.playMode, v);
  }

  Future<void> setTranscodeBitrate(int v) async {
    state = state.copyWith(transcodeBitrate: v);
    await _sp.setInt(StorageKeys.transcodeBitrate, v);
  }

  Future<void> setTranscodeFormat(String v) async {
    state = state.copyWith(transcodeFormat: v);
    await _sp.setString(StorageKeys.transcodeFormat, v);
  }

  Future<void> setForceLossless(bool v) async {
    state = state.copyWith(forceLossless: v);
    await _sp.setBool(StorageKeys.forceLossless, v);
  }

  Future<void> setForceTranscodeOnMobile(bool v) async {
    state = state.copyWith(forceTranscodeOnMobile: v);
    await _sp.setBool(StorageKeys.forceTranscodeOnMobile, v);
  }

  Future<void> setGapless(bool v) async {
    state = state.copyWith(gaplessEnabled: v);
    await _sp.setBool(StorageKeys.gaplessEnabled, v);
  }

  Future<void> setNormalize(bool v) async {
    state = state.copyWith(normalizeVolume: v);
    await _sp.setBool(StorageKeys.normalizeVolume, v);
  }

  Future<void> setEqEnabled(bool v) async {
    state = state.copyWith(equalizerEnabled: v);
    await _sp.setBool(StorageKeys.equalizerEnabled, v);
  }

  Future<void> setEqPreset(int v) async {
    state = state.copyWith(equalizerPreset: v);
    await _sp.setInt(StorageKeys.equalizerPreset, v);
  }

  Future<void> setVolume(double v) async {
    state = state.copyWith(volume: v);
    await _sp.setDouble(StorageKeys.playVolume, v);
  }

  Future<void> setPlaySpeed(double v) async {
    state = state.copyWith(playSpeed: v);
    await _sp.setDouble(StorageKeys.playSpeed, v);
  }

  Future<void> setLocaleCode(String code) async {
    state = state.copyWith(localeCode: code);
    await _sp.setString(StorageKeys.localeCode, code);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
    (ref) => SettingsNotifier(ref.watch(sharedPreferencesProvider)));
