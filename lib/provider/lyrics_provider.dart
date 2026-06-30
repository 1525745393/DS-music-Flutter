import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/lyrics.dart';
import '../model/song.dart';
import '../repository/library_repository.dart';
import 'core_providers.dart';

/// 全局歌词状态：缓存当前歌曲的解析结果
class LyricsState {
  final Song? song;
  final Lyrics lyrics;
  final Duration position;
  final int currentLineIndex;
  final bool loading;

  const LyricsState({
    this.song,
    this.lyrics = const Lyrics(),
    this.position = Duration.zero,
    this.currentLineIndex = -1,
    this.loading = false,
  });

  LyricsState copyWith({
    Song? song,
    Lyrics? lyrics,
    Duration? position,
    int? currentLineIndex,
    bool? loading,
  }) {
    return LyricsState(
      song: song ?? this.song,
      lyrics: lyrics ?? this.lyrics,
      position: position ?? this.position,
      currentLineIndex: currentLineIndex ?? this.currentLineIndex,
      loading: loading ?? this.loading,
    );
  }
}

class LyricsNotifier extends StateNotifier<LyricsState> {
  final Ref _ref;
  LyricsNotifier(this._ref) : super(const LyricsState());

  /// 加载指定歌曲的歌词
  Future<void> load(Song song) async {
    if (state.song?.id == song.id && state.lyrics.lines.isNotEmpty) {
      return; // 已加载
    }
    state = state.copyWith(song: song, loading: true, currentLineIndex: -1);
    try {
      final repo = _ref.read(libraryRepositoryProvider);
      final lyrics = await repo.lyricsOf(song);
      state = state.copyWith(lyrics: lyrics, loading: false);
    } catch (_) {
      state = state.copyWith(loading: false);
    }
  }

  /// 更新当前播放位置（用于滚动定位）
  void updatePosition(Duration position) {
    if (state.lyrics.lines.isEmpty) return;
    final idx = state.lyrics.indexAt(position);
    if (idx != state.currentLineIndex) {
      state = state.copyWith(position: position, currentLineIndex: idx);
    } else {
      state = state.copyWith(position: position);
    }
  }

  void clear() {
    state = const LyricsState();
  }
}

final lyricsProvider =
    StateNotifierProvider<LyricsNotifier, LyricsState>((ref) => LyricsNotifier(ref));
