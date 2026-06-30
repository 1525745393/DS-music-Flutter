package com.dsplayer.music

import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import com.ryanheise.audioservice.AudioServicePlugin

/**
 * 锁屏歌词扩展
 * - 通过 MediaSession 的 customLayout 与 extras 注入 LRC
 * - 通知栏将 lyrics_lrc 作为附加数据由系统锁屏/通知扩展读取
 */
class LockScreenLyricsHelper {

    companion object {
        /**
         * 构造带自定义锁屏视图的 MediaSession
         * 说明：just_audio_background 内部已使用 MediaSession，
         * 此处为示例扩展位置。实际生产可在 just_audio_background 的
         * 自定义 NotificationProvider 中读取 extras.lyrics_lrc。
         */
        fun applyLyricsToMediaItem(
            songId: String,
            title: String,
            artist: String,
            lrc: String
        ): Map<String, Any?> {
            return mapOf(
                "song_id" to songId,
                "title" to title,
                "artist" to artist,
                "lyrics_lrc" to lrc
            )
        }
    }
}
