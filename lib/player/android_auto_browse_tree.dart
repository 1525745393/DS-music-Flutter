import 'dart:async';
import '../model/album.dart';
import '../model/artist.dart';
import '../model/playlist.dart';
import '../model/song.dart';
import '../repository/library_repository.dart';
import '../utils/logger.dart';

/// Android Auto 浏览树定义
/// 设计原因：原生 MediaBrowserService 需要 browseTree 来决定展示内容；
/// 这里用纯 Dart 把 AudioStation 资源映射为 AA 的树结构。
///
/// 节点 ID 约定：
/// - "root"               根
/// - "albums"             专辑列表入口
/// - "artists"            歌手列表入口
/// - "songs"              单曲列表入口
/// - "playlists"          歌单列表入口
/// - "folders"            文件夹入口
/// - "album:{id}"         专辑详情（含歌曲）
/// - "artist:{id}"        歌手详情（含专辑）
/// - "playlist:{id}"      歌单详情（含歌曲）
class AndroidAutoBrowseTree {
  final LibraryRepository _repo;
  AndroidAutoBrowseTree(this._repo);

  /// 解析 parentId，返回子节点 MediaItem 列表（用于 Android Auto onLoadChildren）
  Future<List<AutoMediaItem>> getChildren(String parentId) async {
    try {
      if (parentId == 'root') {
        return _rootItems();
      }
      if (parentId == 'albums') {
        final albums = await _repo.albums();
        return albums.map(_albumNode).toList();
      }
      if (parentId == 'artists') {
        final artists = await _repo.artists();
        return artists.map(_artistNode).toList();
      }
      if (parentId == 'songs') {
        final songs = await _repo.songs();
        return songs.map(_songNode).toList();
      }
      if (parentId == 'playlists') {
        final pls = await _repo.playlists();
        return pls.map(_playlistNode).toList();
      }
      if (parentId.startsWith('album:')) {
        final id = parentId.substring('album:'.length);
        final r = await _repo.albumDetail(id);
        return r.songs.map(_songNode).toList();
      }
      if (parentId.startsWith('artist:')) {
        final id = parentId.substring('artist:'.length);
        final r = await _repo.artistDetail(id);
        return r.albums.map(_albumNode).toList();
      }
      if (parentId.startsWith('playlist:')) {
        final id = parentId.substring('playlist:'.length);
        final pl = await _repo.playlistDetail(id);
        return pl.songs.map(_songNode).toList();
      }
      return const [];
    } catch (e) {
      AppLogger.w('BrowseTree.getChildren($parentId) 失败: $e');
      return const [];
    }
  }

  /// 解析 mediaId，返回单个 AutoMediaItem（用于 onLoadItem）
  Future<AutoMediaItem?> getItem(String mediaId) async {
    try {
      if (mediaId.startsWith('song:')) {
        // 实际场景应从缓存或服务端再次拉取；这里为了演示直接返回空，
        // 真正播放时由 queue 决定
        return null;
      }
      if (mediaId.startsWith('album:')) {
        final id = mediaId.substring('album:'.length);
        final r = await _repo.albumDetail(id);
        return _albumNode(r.album);
      }
      if (mediaId.startsWith('playlist:')) {
        final id = mediaId.substring('playlist:'.length);
        final pl = await _repo.playlistDetail(id);
        return _playlistNode(pl);
      }
      return null;
    } catch (e) {
      AppLogger.w('BrowseTree.getItem($mediaId) 失败: $e');
      return null;
    }
  }

  /// 根节点固定 5 个入口
  List<AutoMediaItem> _rootItems() => const [
        AutoMediaItem(
          id: 'albums',
          title: '专辑',
          isBrowsable: true,
        ),
        AutoMediaItem(
          id: 'artists',
          title: '歌手',
          isBrowsable: true,
        ),
        AutoMediaItem(
          id: 'songs',
          title: '单曲',
          isBrowsable: true,
        ),
        AutoMediaItem(
          id: 'playlists',
          title: '歌单',
          isBrowsable: true,
        ),
        AutoMediaItem(
          id: 'folders',
          title: '文件夹',
          isBrowsable: true,
        ),
      ];

  AutoMediaItem _albumNode(Album a) => AutoMediaItem(
        id: 'album:${a.id}',
        title: a.name,
        subtitle: a.artist,
        albumArtUrl: a.coverUrl != null ? _repo.coverUrl(a.id, size: 'big') : null,
        isBrowsable: true,
      );

  AutoMediaItem _artistNode(Artist a) => AutoMediaItem(
        id: 'artist:${a.id}',
        title: a.name,
        subtitle: '歌手',
        albumArtUrl: a.id.isNotEmpty ? _repo.artistThumb(a.id) : null,
        isBrowsable: true,
      );

  AutoMediaItem _songNode(Song s) => AutoMediaItem(
        id: 'song:${s.id}',
        title: s.title,
        subtitle: s.artist ?? '',
        albumArtUrl: s.albumId != null ? _repo.coverUrl(s.albumId!, size: 'small') : null,
        isBrowsable: false,
        durationMs: s.duration * 1000,
      );

  AutoMediaItem _playlistNode(Playlist p) => AutoMediaItem(
        id: 'playlist:${p.id}',
        title: p.name,
        subtitle: '${p.songCount} 首',
        albumArtUrl: p.coverUrl,
        isBrowsable: true,
      );
}

/// 浏览树节点（结构化数据，可由原生 Kotlin 转换为 MediaItem）
class AutoMediaItem {
  final String id;
  final String title;
  final String? subtitle;
  final String? albumArtUrl;
  final bool isBrowsable; // true=目录，false=可播放
  final int? durationMs;

  const AutoMediaItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.albumArtUrl,
    this.isBrowsable = false,
    this.durationMs,
  });
}
