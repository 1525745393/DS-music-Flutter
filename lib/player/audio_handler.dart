import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../model/song.dart';
import '../utils/logger.dart';
import 'network_type_watcher.dart';

/// 库数据获取的抽象接口
/// 设计原因：让 DSPlayerHandler 不直接依赖 ProviderContainer，
/// 便于 main 阶段在 ProviderContainer 还未就绪时构造 handler
abstract class LibraryAccess {
  String streamUrl(Song song, {bool forceTranscode, bool preferLossless});
  String coverUrl(String albumId, {String size});
}

/// DSPlayerHandler：通过回调访问库
class DSPlayerHandler extends BaseAudioHandler with SeekHandler {
  final LibraryAccess Function() _repoGetter;
  final SettingsPort Function() _settingsGetter;

  final AudioPlayer _player = AudioPlayer();
  final List<Song> _currentQueue = [];
  ConcatenatingAudioSource? _queueSource;

  DSPlayerHandler({
    required LibraryAccess Function() repoGetter,
    required SettingsPort Function() settingsGetter,
  })  : _repoGetter = repoGetter,
        _settingsGetter = settingsGetter {
    _init();
    _watchNetwork();
  }

  AudioPlayer get player => _player;

  // 当前网络类型（WiFi/有线 → 原始码流；蜂窝/未知 → 转码）
  NetType _currentNetType = networkTypeWatcher.current;
  NetType get currentNetType => _currentNetType;

  /// 订阅网络变化：在蜂窝/未知/无网络下应使用转码流
  /// 设计原因：用户进入 WiFi 区域时希望立即切换回原始码流；
  /// 离开 WiFi 时降到转码以节省流量。
  /// 当前限制：仅记录策略变化；实时重建队列在用户主动设置开关或
  /// 切歌时才会生效，避免在播放途中频繁切换源造成卡顿。
  void _watchNetwork() {
    networkTypeWatcher.stream.listen((type) {
      if (type == _currentNetType) return;
      _currentNetType = type;
      AppLogger.i('音频码流策略: ${type.label} → ${type.isHighBandwidth ? "原始" : "转码"}');
    });
  }

  Future<void> _init() async {
    _player.playbackEventStream.listen(_broadcastState, onError: (Object e, StackTrace st) {
      AppLogger.e('Player 错误', e, st);
    });
    _player.positionStream.listen((p) =>
        playbackState.add(playbackState.value.copyWith(updatePosition: p)));
    _player.bufferedPositionStream.listen((b) =>
        playbackState.add(playbackState.value.copyWith(bufferedPosition: b)));
    _player.speedStream.listen((s) =>
        playbackState.add(playbackState.value.copyWith(speed: s)));
    _player.durationStream.listen((d) => _updateMediaItem(d));

    try {
      await _player.setSkipSilenceEnabled(_settingsGetter().normalizeVolume);
    } catch (_) {}
  }

  /// 播放指定队列
  /// [resumePosition] 从指定位置恢复（用于网络切换重建队列）
  /// [autoPlay] 是否在加载完成后自动播放
  Future<void> setQueueAndPlay(
    List<Song> songs, {
    int startIndex = 0,
    Duration resumePosition = Duration.zero,
    bool autoPlay = true,
  }) async {
    if (songs.isEmpty) return;
    _currentQueue
      ..clear()
      ..addAll(songs);
    final sources = <AudioSource>[];
    for (var i = 0; i < songs.length; i++) {
      sources.add(_buildAudioSource(songs[i]));
    }
    // 应用「无缝播放」开关：
    //   - 开：ConcatenatingAudioSource 内部连续预加载下一首，真正 0 gap 切换
    //   - 关：插入 100ms SilenceIntercom 作为「喘息」，降低 CPU/带宽但有体感停顿
    final settings = _settingsGetter();
    if (settings.gaplessEnabled) {
      _queueSource = ConcatenatingAudioSource(
        useLazyPreparation: true,
        shuffleOrder: DefaultShuffleOrder(),
        children: sources,
      );
    } else {
      _queueSource = ConcatenatingAudioSource(
        useLazyPreparation: false,
        shuffleOrder: DefaultShuffleOrder(),
        // 非无缝模式：在每首之间插入短暂静音以减轻后端压力
        children: _withBreaks(sources),
      );
    }
    await _player.setAudioSource(
      _queueSource!,
      initialIndex: startIndex,
      preload: true,
    );
    if (resumePosition > Duration.zero) {
      await _player.seek(resumePosition);
    }
    if (autoPlay) {
      await _player.play();
    }
  }

  /// 在每两首歌之间插入 100ms 静音片段
  /// 设计原因：关闭 gapless 时仍希望队列结构稳定，但给系统留出缓冲/调度窗口
  List<AudioSource> _withBreaks(List<AudioSource> sources) {
    if (sources.length <= 1) return sources;
    final out = <AudioSource>[];
    for (var i = 0; i < sources.length; i++) {
      out.add(sources[i]);
      if (i < sources.length - 1) {
        out.add(AudioSource.uri(
          Uri.dataFromBytes(_silentWavBytes),
          tag: MediaItem(id: '__gap_$i', title: '', album: ''),
        ));
      }
    }
    return out;
  }

  /// 100ms 静音的 WAV（44 字节头 + ~4410 字节静音样本），
  /// 用 Uri.dataFromBytes 内嵌避免再起一次网络请求
  static final List<int> _silentWavBytes = _buildSilentWav();

  static List<int> _buildSilentWav() {
    const sampleRate = 44100;
    const samples = 4410; // 100ms
    const dataSize = samples * 2; // 16-bit mono
    final bytes = <int>[];
    // RIFF header
    bytes.addAll('RIFF'.codeUnits);
    bytes.addAll(_u32(36 + dataSize));
    bytes.addAll('WAVE'.codeUnits);
    // fmt chunk
    bytes.addAll('fmt '.codeUnits);
    bytes.addAll(_u32(16));      // chunk size
    bytes.addAll(_u16(1));       // PCM
    bytes.addAll(_u16(1));       // mono
    bytes.addAll(_u32(sampleRate));
    bytes.addAll(_u32(sampleRate * 2));
    bytes.addAll(_u16(2));       // block align
    bytes.addAll(_u16(16));      // bits per sample
    // data chunk
    bytes.addAll('data'.codeUnits);
    bytes.addAll(_u32(dataSize));
    // 静音样本（0）
    for (var i = 0; i < dataSize; i++) {
      bytes.add(0);
    }
    return bytes;
  }

  static List<int> _u16(int v) =>
      [(v & 0xFF), ((v >> 8) & 0xFF)];

  static List<int> _u32(int v) => [
        (v & 0xFF),
        ((v >> 8) & 0xFF),
        ((v >> 16) & 0xFF),
        ((v >> 24) & 0xFF),
      ];

  Future<void> setSingleAndPlay(Song song) async {
    _currentQueue
      ..clear()
      ..add(song);
    final source = _buildAudioSource(song);
    await _player.setAudioSource(source, preload: true);
    await _player.play();
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> skipToNext() => _player.seekToNext();
  Future<void> skipToPrevious() => _player.seekToPrevious();
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await _player.setShuffleModeEnabled(shuffleMode != AudioServiceShuffleMode.none);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    LoopMode mode;
    switch (repeatMode) {
      case AudioServiceRepeatMode.one:
        mode = LoopMode.one;
        break;
      case AudioServiceRepeatMode.group:
      case AudioServiceRepeatMode.all:
        mode = LoopMode.all;
        break;
      case AudioServiceRepeatMode.none:
        mode = LoopMode.off;
        break;
    }
    await _player.setLoopMode(mode);
  }

  // ==================== Internal ====================

  AudioSource _buildAudioSource(Song song) {
    // 本地缓存命中
    if (song.downloaded && song.localPath != null) {
      return AudioSource.uri(
        Uri.file(song.localPath!),
        tag: _mediaItem(song),
      );
    }
    // WiFi/有线 → 原始码流（无损）；蜂窝/未知/无网络 → 转码
    final settings = _settingsGetter();
    final forceTranscode = !_currentNetType.isHighBandwidth || settings.forceTranscodeOnMobile;
    final url = _repoGetter().streamUrl(
      song,
      forceTranscode: forceTranscode,
      preferLossless: settings.forceLossless,
    );
    return AudioSource.uri(
      Uri.parse(url),
      tag: _mediaItem(song),
    );
  }

  /// 网络切换后重建队列。
  /// 设计原因：原队列的 URL 已经在 setAudioSource 时锁定，单纯订阅变化无济于事；
  /// 需重建 ConcatenatingAudioSource 并从当前位置恢复。
  Future<void> _rebuildForNetwork() async {
    if (_currentQueue.isEmpty) return;
    final idx = _player.currentIndex ?? 0;
    final pos = _player.position;
    final wasPlaying = _player.playing;
    AppLogger.i('网络变化：重建队列以切换码流策略');
    await setQueueAndPlay(
      List<Song>.from(_currentQueue),
      startIndex: idx,
      resumePosition: pos,
      autoPlay: wasPlaying,
    );
  }

  MediaItem _mediaItem(Song song) {
    String? artUri;
    if (song.albumId != null && song.albumId!.isNotEmpty) {
      artUri = _repoGetter().coverUrl(song.albumId!, size: 'big');
    }
    return MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist ?? '未知艺术家',
      album: song.album ?? '未知专辑',
      duration: Duration(seconds: song.duration),
      artUri: artUri != null ? Uri.parse(artUri) : null,
      // 锁屏歌词：通过 extras 传递 LRC 文本，原生通知/锁屏扩展可读取
      extras: {
        'song_id': song.id,
        'album_id': song.albumId ?? '',
        'lyrics_lrc': _cachedLyricsLrc,
      },
    );
  }

  // 缓存当前队列的 LRC（由 UI 侧注入）
  String _cachedLyricsLrc = '';
  void setLyricsLrc(String lrc) {
    _cachedLyricsLrc = lrc;
  }

  void _updateMediaItem(Duration? d) {
    final item = _player.audioSource?.sequenceState?.currentSource?.tag as MediaItem?;
    if (item == null) return;
    mediaItem.add(item);
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: _toProcessingState(event.processingState),
      playing: playing,
      updatePosition: event.position,
      bufferedPosition: event.bufferedPosition,
      speed: event.speed,
      queueIndex: event.currentIndex,
    ));
  }

  AudioProcessingState _toProcessingState(ProcessingState s) {
    switch (s) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  Future<void> dispose() async => _player.dispose();
}

/// 设置项只读快照（handler 只需要读，避免直接依赖 StateNotifier）
class SettingsPort {
  final bool forceLossless;
  final bool normalizeVolume;
  final bool gaplessEnabled;
  /// 强制在移动网络下转码（与"高带宽判断"独立；用于用户手动覆盖）
  final bool forceTranscodeOnMobile;
  const SettingsPort({
    this.forceLossless = false,
    this.normalizeVolume = false,
    this.gaplessEnabled = true,
    this.forceTranscodeOnMobile = true,
  });
}
