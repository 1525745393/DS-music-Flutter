package com.dsplayer.music

import android.content.ContentResolver
import android.net.Uri
import android.os.Bundle
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.MediaMetadataCompat

/**
 * Android Auto 浏览树
 * 说明：
 * - 这是一个轻量级 MediaBrowserService 浏览根配置器。
 * - 完整的浏览树由 audio_service 提供的 MediaBrowserService 实现；
 * - 本类仅作为集中定义浏览节点常量的位置，供未来需要自定义 AA 浏览时引用。
 */
class AndroidAutoBrowseTree {

    companion object {
        // 根节点 ID
        const val ROOT = "__ROOT__"

        // 顶级分类（与 Dart 端 android_auto_browse_tree.dart 一致）
        const val NODE_ALBUMS = "albums"
        const val NODE_ARTISTS = "artists"
        const val NODE_SONGS = "songs"
        const val NODE_PLAYLISTS = "playlists"
        const val NODE_FOLDERS = "folders"

        // 详情节点前缀
        const val PREFIX_ALBUM = "album:"
        const val PREFIX_ARTIST = "artist:"
        const val PREFIX_PLAYLIST = "playlist:"
        const val PREFIX_SONG = "song:"

        // 根下的 5 个目录项
        val ROOT_CHILDREN: List<MediaBrowserCompat.MediaItem> by lazy {
            listOf(
                browsable(NODE_ALBUMS, "专辑"),
                browsable(NODE_ARTISTS, "歌手"),
                browsable(NODE_SONGS, "单曲"),
                browsable(NODE_PLAYLISTS, "歌单"),
                browsable(NODE_FOLDERS, "文件夹"),
            )
        }

        /** 构造可浏览节点（标题 + 子节点） */
        private fun browsable(id: String, title: String): MediaBrowserCompat.MediaItem {
            val desc = MediaDescriptionCompatBuilder(id, title).build()
            return MediaBrowserCompat.MediaItem(desc,
                MediaBrowserCompat.MediaItem.FLAG_BROWSABLE)
        }

        /** 构造可播放节点（单首歌曲） */
        fun playable(id: String, title: String, artist: String?, album: String?,
                     durationMs: Long, artUri: Uri?): MediaBrowserCompat.MediaItem {
            val metadata = MediaMetadataCompat.Builder()
                .putString(MediaMetadataCompat.METADATA_KEY_MEDIA_ID, id)
                .putString(MediaMetadataCompat.METADATA_KEY_TITLE, title)
                .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, artist ?: "未知艺术家")
                .putString(MediaMetadataCompat.METADATA_KEY_ALBUM, album ?: "")
                .putLong(MediaMetadataCompat.METADATA_KEY_DURATION, durationMs)
                .apply { if (artUri != null) putString(MediaMetadataCompat.METADATA_KEY_ART_URI, artUri.toString()) }
                .build()
            val desc = android.support.v4.media.MediaDescriptionCompat.Builder()
                .setMediaId(id)
                .setTitle(title)
                .setSubtitle(artist)
                .setDescription(album)
                .setIconUri(artUri)
                .setExtras(Bundle().apply { putAll(metadata.bundle) })
                .build()
            return MediaBrowserCompat.MediaItem(desc,
                MediaBrowserCompat.MediaItem.FLAG_PLAYABLE)
        }
    }
}

/**
 * 轻量 MediaDescriptionCompat 构造器（仅用于本类，不引入额外依赖）
 */
class MediaDescriptionCompatBuilder(
    private val id: String,
    private val title: String
) {
    private var subtitle: String? = null
    private var description: String? = null
    private var artUri: Uri? = null

    fun setSubtitle(value: String?): MediaDescriptionCompatBuilder {
        subtitle = value
        return this
    }

    fun setDescription(value: String?): MediaDescriptionCompatBuilder {
        description = value
        return this
    }

    fun setArtUri(value: Uri?): MediaDescriptionCompatBuilder {
        artUri = value
        return this
    }

    fun build(): android.support.v4.media.MediaDescriptionCompat {
        return android.support.v4.media.MediaDescriptionCompat.Builder()
            .setMediaId(id)
            .setTitle(title)
            .setSubtitle(subtitle)
            .setDescription(description)
            .setIconUri(artUri)
            .build()
    }
}
