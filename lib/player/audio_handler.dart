import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../model/song.dart';
import '../utils/logger.dart';

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
  }

  AudioPlayer get player => _player;

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
  Future<void> setQueueAndPlay(List<Song> songs, {int startIndex = 0}) async {
    if (songs.isEmpty) return;
    _currentQueue
      ..clear()
      ..addAll(songs);
    final sources = <AudioSource>[];
    for (var i = 0; i < songs.length; i++) {
      sources.add(_buildAudioSource(songs[i]));
    }
    _queueSource = ConcatenatingAudioSource(
      useLazyPreparation: true,
      shuffleOrder: DefaultShuffleOrder(),
      children: sources,
    );
    await _player.setAudioSource(
      _queueSource!,
      initialIndex: startIndex,
      preload: true,
    );
    await _player.play();
  }

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
    // WiFi/蜂窝智能选择
    final isWifi = true; // 实际可在 setQueueAndPlay 前预判
    final settings = _settingsGetter();
    final url = _repoGetter().streamUrl(
      song,
      forceTranscode: !isWifi,
      preferLossless: settings.forceLossless,
    );
    return AudioSource.uri(
      Uri.parse(url),
      tag: _mediaItem(song),
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
    );
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
  const SettingsPort({
    this.forceLossless = false,
    this.normalizeVolume = false,
    this.gaplessEnabled = true,
  });
}
