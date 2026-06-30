import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/album.dart';
import '../model/artist.dart';
import '../model/playlist.dart';
import '../model/song.dart';
import 'core_providers.dart';
import 'auth_provider.dart';

/// 曲库 Tab 索引
enum LibraryTab { albums, artists, songs, folders, playlists }

final libraryTabProvider =
    StateProvider<LibraryTab>((ref) => LibraryTab.albums);

/// 专辑列表
final albumsProvider = FutureProvider.autoDispose<List<Album>>((ref) async {
  ref.watch(authStateProvider); // 依赖登录态
  final repo = ref.watch(libraryRepositoryProvider);
  return repo.albums();
});

/// 歌手列表
final artistsProvider = FutureProvider.autoDispose<List<Artist>>((ref) async {
  ref.watch(authStateProvider);
  final repo = ref.watch(libraryRepositoryProvider);
  return repo.artists();
});

/// 歌曲列表
final songsProvider = FutureProvider.autoDispose<List<Song>>((ref) async {
  ref.watch(authStateProvider);
  final repo = ref.watch(libraryRepositoryProvider);
  return repo.songs();
});

/// 文件夹
final foldersProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authStateProvider);
  final repo = ref.watch(libraryRepositoryProvider);
  return repo.folders();
});

/// 歌单
final playlistsProvider =
    FutureProvider.autoDispose<List<Playlist>>((ref) async {
  ref.watch(authStateProvider);
  final repo = ref.watch(libraryRepositoryProvider);
  return repo.playlists();
});

/// 专辑详情（含曲目）
final albumDetailProvider = FutureProvider.autoDispose
    .family<({Album album, List<Song> songs}), String>((ref, albumId) async {
  final repo = ref.watch(libraryRepositoryProvider);
  return repo.albumDetail(albumId);
});

/// 歌手详情
final artistDetailProvider = FutureProvider.autoDispose
    .family<({Artist artist, List<Album> albums}), String>(
        (ref, artistId) async {
  final repo = ref.watch(libraryRepositoryProvider);
  return repo.artistDetail(artistId);
});

/// 歌单详情
final playlistDetailProvider = FutureProvider.autoDispose
    .family<Playlist, String>((ref, playlistId) async {
  final repo = ref.watch(libraryRepositoryProvider);
  return repo.playlistDetail(playlistId);
});

/// 搜索关键字 + 结果
final searchKeywordProvider = StateProvider<String>((ref) => '');

class SearchResult {
  final List<Album> albums;
  final List<Artist> artists;
  final List<Song> songs;
  final bool isLoading;

  const SearchResult({
    this.albums = const [],
    this.artists = const [],
    this.songs = const [],
    this.isLoading = false,
  });
}

final searchResultProvider =
    FutureProvider.autoDispose<SearchResult>((ref) async {
  final keyword = ref.watch(searchKeywordProvider);
  if (keyword.trim().isEmpty) {
    return const SearchResult();
  }
  final repo = ref.watch(libraryRepositoryProvider);
  final r = await repo.search(keyword);
  return SearchResult(albums: r.albums, artists: r.artists, songs: r.songs);
});
