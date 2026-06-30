import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/cards/album_grid_item.dart';
import '../../components/ds_state_page.dart';
import '../../components/ds_tab_bar.dart';
import '../../components/ds_text.dart';
import '../../components/lists/song_list_tile.dart';
import '../../model/album.dart';
import '../../model/artist.dart';
import '../../model/playlist.dart';
import '../../model/song.dart';
import '../../provider/core_providers.dart';
import '../../provider/library_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../album/album_detail_page.dart';
import '../artist/artist_detail_page.dart';
import '../playlist/playlist_detail_page.dart';
import '../search/search_page.dart';
import '../settings/settings_page.dart';
import '../player/player_page.dart';

/// 首页：专辑墙 + Tab 切换
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  static const _tabs = ['专辑', '歌手', '歌曲', '文件夹', '歌单'];

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(libraryTabProvider);
    return CupertinoPageScaffold(
      backgroundColor: AppColors.darkBg,
      child: Column(
        children: [
          _navBar(),
          DSTabBar(
            tabs: _tabs,
            currentIndex: tab.index,
            onTap: (i) =>
                ref.read(libraryTabProvider.notifier).state = LibraryTab.values[i],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _buildContent(tab),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navBar() {
    return SizedBox(
      height: AppDimens.navBarHeight,
      child: Row(
        children: [
          const SizedBox(width: 16),
          const DSText.largeTitle('音乐'),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(CupertinoPageRoute(
                builder: (_) => const SearchPage(),
              ));
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(CupertinoIcons.search, size: 22, color: AppColors.textPrimaryDark),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(CupertinoPageRoute(
                builder: (_) => const SettingsPage(),
              ));
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(CupertinoIcons.settings, size: 22, color: AppColors.textPrimaryDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(LibraryTab tab) {
    switch (tab) {
      case LibraryTab.albums:
        return _albumsView(key: const ValueKey('albums'));
      case LibraryTab.artists:
        return _artistsView(key: const ValueKey('artists'));
      case LibraryTab.songs:
        return _songsView(key: const ValueKey('songs'));
      case LibraryTab.folders:
        return _foldersView(key: const ValueKey('folders'));
      case LibraryTab.playlists:
        return _playlistsView(key: const ValueKey('playlists'));
    }
  }

  Widget _albumsView({required Key key}) {
    final async = ref.watch(albumsProvider);
    return async.when(
      loading: () => const DSStatePage(type: StateType.loading, message: '加载专辑中...'),
      error: (e, _) => DSStatePage(
        type: StateType.error,
        message: e.toString(),
        onRetry: () => ref.invalidate(albumsProvider),
      ),
      data: (albums) {
        if (albums.isEmpty) {
          return const DSStatePage(type: StateType.empty, message: '暂无专辑');
        }
        return GridView.builder(
          key: key,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, AppDimens.miniPlayerHeight + 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.72,
          ),
          itemCount: albums.length,
          itemBuilder: (_, i) {
            final Album a = albums[i];
            final repo = ref.read(libraryRepositoryProvider);
            return AlbumGridItem(
              album: a,
              coverUrl: a.id.isNotEmpty ? repo.coverUrl(a.id) : null,
              onTap: () {
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (_) => AlbumDetailPage(albumId: a.id, albumName: a.name),
                ));
              },
            );
          },
        );
      },
    );
  }

  Widget _artistsView({required Key key}) {
    final async = ref.watch(artistsProvider);
    return async.when(
      loading: () => const DSStatePage(type: StateType.loading, message: '加载歌手中...'),
      error: (e, _) => DSStatePage(
        type: StateType.error,
        message: e.toString(),
        onRetry: () => ref.invalidate(artistsProvider),
      ),
      data: (artists) {
        if (artists.isEmpty) return const DSStatePage(type: StateType.empty, message: '暂无歌手');
        return ListView.separated(
          key: key,
          padding: const EdgeInsets.only(bottom: AppDimens.miniPlayerHeight + 16),
          itemCount: artists.length,
          separatorBuilder: (_, __) => Container(
            margin: const EdgeInsets.only(left: 72),
            height: 0.5,
            color: AppColors.darkDivider,
          ),
          itemBuilder: (_, i) {
            final Artist a = artists[i];
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (_) => ArtistDetailPage(artistId: a.id, artistName: a.name),
                ));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.darkElevated,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(CupertinoIcons.person_fill,
                          color: AppColors.textAssistantDark, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DSText(a.name),
                          const SizedBox(height: 2),
                          DSText.assistant('${a.albumCount} 张专辑 · ${a.songCount} 首歌曲'),
                        ],
                      ),
                    ),
                    const Icon(CupertinoIcons.chevron_right,
                        color: AppColors.textAssistantDark, size: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _songsView({required Key key}) {
    final async = ref.watch(songsProvider);
    return async.when(
      loading: () => const DSStatePage(type: StateType.loading, message: '加载歌曲中...'),
      error: (e, _) => DSStatePage(
        type: StateType.error,
        message: e.toString(),
        onRetry: () => ref.invalidate(songsProvider),
      ),
      data: (songs) {
        if (songs.isEmpty) return const DSStatePage(type: StateType.empty, message: '暂无歌曲');
        return ListView.separated(
          key: key,
          padding: const EdgeInsets.only(bottom: AppDimens.miniPlayerHeight + 16),
          itemCount: songs.length,
          separatorBuilder: (_, __) => Container(
            margin: const EdgeInsets.only(left: 72),
            height: 0.5,
            color: AppColors.darkDivider,
          ),
          itemBuilder: (_, i) {
            final Song s = songs[i];
            return SongListTile(
              song: s,
              coverUrl: s.albumId != null
                  ? ref.read(libraryRepositoryProvider).coverUrl(s.albumId!)
                  : null,
              onTap: () => _playAll(songs, startIndex: i),
            );
          },
        );
      },
    );
  }

  Widget _foldersView({required Key key}) {
    final async = ref.watch(foldersProvider);
    return async.when(
      loading: () => const DSStatePage(type: StateType.loading, message: '加载文件夹中...'),
      error: (e, _) => DSStatePage(
        type: StateType.error,
        message: e.toString(),
        onRetry: () => ref.invalidate(foldersProvider),
      ),
      data: (folders) {
        if (folders.isEmpty) return const DSStatePage(type: StateType.empty, message: '暂无文件夹');
        return ListView.separated(
          key: key,
          padding: const EdgeInsets.only(bottom: AppDimens.miniPlayerHeight + 16),
          itemCount: folders.length,
          separatorBuilder: (_, __) => Container(
            margin: const EdgeInsets.only(left: 72),
            height: 0.5,
            color: AppColors.darkDivider,
          ),
          itemBuilder: (_, i) {
            final f = folders[i];
            return ListTile(
              leading: const Icon(CupertinoIcons.folder,
                  color: AppColors.accent, size: 28),
              title: DSText(f['name']?.toString() ?? '未命名'),
              subtitle: DSText.assistant('${f['items'] ?? 0} 项'),
              trailing: const Icon(CupertinoIcons.chevron_right,
                  color: AppColors.textAssistantDark, size: 16),
              onTap: () {
                // 进入子目录
              },
            );
          },
        );
      },
    );
  }

  Widget _playlistsView({required Key key}) {
    final async = ref.watch(playlistsProvider);
    return async.when(
      loading: () => const DSStatePage(type: StateType.loading, message: '加载歌单中...'),
      error: (e, _) => DSStatePage(
        type: StateType.error,
        message: e.toString(),
        onRetry: () => ref.invalidate(playlistsProvider),
      ),
      data: (playlists) {
        if (playlists.isEmpty) {
          return const DSStatePage(type: StateType.empty, message: '暂无歌单');
        }
        return GridView.builder(
          key: key,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, AppDimens.miniPlayerHeight + 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: playlists.length,
          itemBuilder: (_, i) {
            final Playlist p = playlists[i];
            return AlbumGridItem(
              album: Album(
                id: p.id,
                name: p.name,
                artist: '${p.songCount} 首',
                coverUrl: p.coverUrl,
              ),
              coverUrl: p.coverUrl,
              onTap: () {
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (_) => PlaylistDetailPage(playlistId: p.id, name: p.name),
                ));
              },
            );
          },
        );
      },
    );
  }

  void _playAll(List<Song> songs, {int startIndex = 0}) {
    ref.read(playerStateProvider.notifier).setQueue(songs, startIndex: startIndex);
    Navigator.of(context).push(CupertinoPageRoute(
      fullscreenDialog: true,
      builder: (_) => const PlayerPage(),
    ));
  }
}
