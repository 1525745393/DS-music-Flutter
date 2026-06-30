import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/song.dart';
import 'core_providers.dart';
import 'auth_provider.dart';

/// 播放模式
enum PlayMode { sequence, singleLoop, shuffle }

class PlayerStateData {
  final List<Song> queue;
  final int currentIndex;
  final Song? current;
  final bool playing;
  final Duration position;
  final Duration buffered;
  final double speed;
  final double volume;
  final PlayMode mode;
  final bool isFullScreen;

  const PlayerStateData({
    this.queue = const [],
    this.currentIndex = -1,
    this.current,
    this.playing = false,
    this.position = Duration.zero,
    this.buffered = Duration.zero,
    this.speed = 1.0,
    this.volume = 1.0,
    this.mode = PlayMode.sequence,
    this.isFullScreen = false,
  });

  /// 别名：与 just_audio 等外部 API 命名习惯保持一致
  bool get isPlaying => playing;

  PlayerStateData copyWith({
    List<Song>? queue,
    int? currentIndex,
    Song? current,
    bool? clearCurrent,
    bool? playing,
    Duration? position,
    Duration? buffered,
    double? speed,
    double? volume,
    PlayMode? mode,
    bool? isFullScreen,
  }) {
    return PlayerStateData(
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      current: (clearCurrent ?? false) ? null : (current ?? this.current),
      playing: playing ?? this.playing,
      position: position ?? this.position,
      buffered: buffered ?? this.buffered,
      speed: speed ?? this.speed,
      volume: volume ?? this.volume,
      mode: mode ?? this.mode,
      isFullScreen: isFullScreen ?? this.isFullScreen,
    );
  }
}

class PlayerStateNotifier extends StateNotifier<PlayerStateData> {
  final Ref _ref;
  PlayerStateNotifier(this._ref) : super(const PlayerStateData());

  void setQueue(List<Song> songs, {int startIndex = 0}) {
    if (songs.isEmpty) return;
    state = state.copyWith(
      queue: List.unmodifiable(songs),
      currentIndex: startIndex.clamp(0, songs.length - 1),
      current: songs[startIndex.clamp(0, songs.length - 1)],
    );
  }

  void addToQueue(Song song) {
    state = state.copyWith(queue: [...state.queue, song]);
  }

  void insertAt(int index, Song song) {
    final list = [...state.queue];
    list.insert(index.clamp(0, list.length), song);
    state = state.copyWith(queue: list);
  }

  void removeAt(int index) {
    if (index < 0 || index >= state.queue.length) return;
    final list = [...state.queue];
    list.removeAt(index);
    int newIdx = state.currentIndex;
    if (index < newIdx) newIdx--;
    if (newIdx < 0) newIdx = 0;
    state = state.copyWith(
      queue: list,
      currentIndex: newIdx,
      current: list.isNotEmpty ? list[newIdx] : null,
      clearCurrent: list.isEmpty,
    );
  }

  void move(int oldIndex, int newIndex) {
    final list = [...state.queue];
    if (oldIndex < 0 || oldIndex >= list.length) return;
    final song = list.removeAt(oldIndex);
    list.insert(newIndex.clamp(0, list.length), song);
    state = state.copyWith(queue: list);
  }

  void setPlaying(bool v) => state = state.copyWith(playing: v);
  void setPosition(Duration v) => state = state.copyWith(position: v);
  void setBuffered(Duration v) => state = state.copyWith(buffered: v);
  void setSpeed(double v) => state = state.copyWith(speed: v);
  void setVolume(double v) => state = state.copyWith(volume: v);
  void setMode(PlayMode m) => state = state.copyWith(mode: m);
  void setFullScreen(bool v) => state = state.copyWith(isFullScreen: v);
  void setCurrentIndex(int idx) {
    if (idx < 0 || idx >= state.queue.length) return;
    state = state.copyWith(currentIndex: idx, current: state.queue[idx]);
  }

  void next() {
    if (state.queue.isEmpty) return;
    int idx;
    if (state.mode == PlayMode.shuffle) {
      idx = (state.queue.length == 1)
          ? 0
          : (state.currentIndex +
                  1 +
                  (DateTime.now().microsecondsSinceEpoch %
                      (state.queue.length - 1))) %
              state.queue.length;
    } else {
      idx = (state.currentIndex + 1) % state.queue.length;
    }
    setCurrentIndex(idx);
  }

  void prev() {
    if (state.queue.isEmpty) return;
    final idx = (state.currentIndex - 1 + state.queue.length) % state.queue.length;
    setCurrentIndex(idx);
  }
}

final playerStateProvider =
    StateNotifierProvider<PlayerStateNotifier, PlayerStateData>(
        (ref) => PlayerStateNotifier(ref));

/// 当前播放歌曲是否已下载到本地
final isCurrentDownloadedProvider = Provider<bool>((ref) {
  final cur = ref.watch(playerStateProvider.select((s) => s.current));
  if (cur == null) return false;
  final repo = ref.read(libraryRepositoryProvider);
  // 这里仅根据模型字段判断，缓存扫描逻辑由 player 内部处理
  return cur.downloaded;
});
