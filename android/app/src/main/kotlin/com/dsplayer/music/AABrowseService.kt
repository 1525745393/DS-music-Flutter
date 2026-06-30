package com.dsplayer.music

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.session.MediaSessionCompat
import androidx.core.app.NotificationCompat
import androidx.media.MediaBrowserServiceCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * Android Auto MediaBrowserService 桥接
 *
 * 设计要点：
 * 1. 必须 startForeground()，否则 Android 8+ 会在数秒后杀掉服务
 * 2. onLoadChildren(parentId, result) 通过 MethodChannel 调用
 *    Dart 侧 [AndroidAutoBrowseTree.getChildren]，将浏览树节点返回给 AA
 * 3. 兼容 just_audio_background 的 'com.dsplayer.audio' 通道，
 *    让媒体通知与播放进度合并显示
 *
 * 替代：原 com.ryanheise.audioservice.AudioService 的
 * android.media.browse.MediaBrowserService 实现，
 * 提供真实媒体库浏览能力（通过 MethodChannel 回查 Dart 侧）
 */
class AABrowseService : MediaBrowserServiceCompat() {

    companion object {
        const val CHANNEL = "com.dsplayer.music/auto_browse"
        const val NOTIFICATION_CHANNEL_ID = "com.dsplayer.audio"
        const val NOTIFICATION_ID = 1001
    }

    private var mediaSession: MediaSessionCompat? = null
    private var methodChannel: MethodChannel? = null
    private var engine: FlutterEngine? = null

    override fun onCreate() {
        super.onCreate()

        // 1. 媒体会话：AA / 系统媒体控件依赖
        mediaSession = MediaSessionCompat(this, "DSPlayerAASession").apply {
            isActive = true
        }
        sessionToken = mediaSession?.sessionToken ?: return

        // 2. 启动前台服务 + 通知（Android 8+ 必做）
        startForegroundCompat()

        // 3. 启动 Flutter 引擎（用于 MethodChannel 调用）
        try {
            val eng = FlutterEngine(this)
            eng.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            )
            methodChannel = MethodChannel(eng.dartExecutor.binaryMessenger, CHANNEL)
            engine = eng
        } catch (e: Throwable) {
            // 引擎启动失败仍保持服务存活
            methodChannel = null
        }
    }

    override fun onDestroy() {
        mediaSession?.release()
        engine?.destroy()
        // 退出前台
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        super.onDestroy()
    }

    /**
     * 启动前台通知
     * 关键：必须 startForeground，否则 Android 8+ 会在 Service.onStartCommand
     *      之后数秒抛出 ANR 并杀掉服务。
     * 兼容性：通道 ID 与 just_audio_background 一致（"com.dsplayer.audio"），
     *      让两条通知合并显示，避免通知栏双条。
     */
    private fun startForegroundCompat() {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "DS Player 播放",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "锁屏与系统媒体控件"
                setShowBadge(false)
            }
            nm.createNotificationChannel(channel)
        }

        val notification: Notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("DS Player")
            .setContentText("正在准备 Android Auto 浏览…")
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_TRANSPORT)
            .build()

        // API 26+ 必须用 startForegroundService(intent) 启动
        // 但 MediaBrowserService 启动方式略不同：直接 startForeground
        startForeground(NOTIFICATION_ID, notification)
    }

    /**
     * 系统/AA 询问根节点可浏览列表
     */
    override fun onGetRoot(
        clientPackageName: String,
        clientUid: Int,
        rootHints: Bundle?
    ): BrowserRoot? {
        val isAA = clientPackageName == "com.google.android.projection.gearhead" ||
                   clientPackageName == "com.google.android.googlequicksearchbox" ||
                   clientPackageName == packageName
        return if (isAA) {
            BrowserRoot(AndroidAutoBrowseTree.ROOT, null)
        } else {
            // 拒绝非授权客户端，避免被同设备其他 app 探测
            BrowserRoot("__DENIED__", null)
        }
    }

    /**
     * 加载子节点
     * 通过 MethodChannel 调 Dart：[AndroidAutoBrowseTree.getChildren]
     * 失败/未启动：返回 5 个固定分类（专辑/歌手/单曲/歌单/文件夹）
     */
    override fun onLoadChildren(
        parentId: String,
        result: Result<MutableList<MediaBrowserCompat.MediaItem>>
    ) {
        result.detach()

        val ch = methodChannel
        if (ch == null) {
            result.sendResult(AndroidAutoBrowseTree.ROOT_CHILDREN.toMutableList())
            return
        }

        ch.invokeMethod(
            "getChildren",
            mapOf("parentId" to parentId),
            object : MethodChannel.Result {
                override fun success(result2: Any?) {
                    val items = parseItems(result2)
                    result.sendResult(items.toMutableList())
                }
                override fun error(code: String, msg: String?, details: Any?) {
                    result.sendResult(AndroidAutoBrowseTree.ROOT_CHILDREN.toMutableList())
                }
                override fun notImplemented() {
                    result.sendResult(AndroidAutoBrowseTree.ROOT_CHILDREN.toMutableList())
                }
            }
        )
    }

    override fun onLoadItem(itemId: String, result: Result<MediaBrowserCompat.MediaItem>) {
        result.detach()
        val ch = methodChannel ?: run {
            result.sendResult(null)
            return
        }
        ch.invokeMethod(
            "getItem",
            mapOf("mediaId" to itemId),
            object : MethodChannel.Result {
                override fun success(raw: Any?) {
                    result.sendResult(parseItems(listOf(raw)).firstOrNull())
                }
                override fun error(code: String, msg: String?, details: Any?) {
                    result.sendResult(null)
                }
                override fun notImplemented() {
                    result.sendResult(null)
                }
            }
        )
    }

    /**
     * 解析 Dart 返回的 List<Map> 为 MediaItem 列表
     */
    private fun parseItems(raw: Any?): List<MediaBrowserCompat.MediaItem> {
        if (raw !is List<*>) return emptyList()
        return raw.mapNotNull { item ->
            try {
                val m = item as? Map<*, *> ?: return@mapNotNull null
                val id = m["id"]?.toString() ?: return@mapNotNull null
                val title = m["title"]?.toString() ?: ""
                val browsable = (m["browsable"] as? Boolean) ?: false
                if (browsable) {
                    val desc = android.support.v4.media.MediaDescriptionCompat.Builder()
                        .setMediaId(id)
                        .setTitle(title)
                        .build()
                    MediaBrowserCompat.MediaItem(desc, MediaBrowserCompat.MediaItem.FLAG_BROWSABLE)
                } else {
                    val artist = m["artist"]?.toString()
                    val album = m["album"]?.toString()
                    val durationMs = (m["durationMs"] as? Number)?.toLong() ?: 0L
                    val artUri = m["artUri"]?.toString()?.let { android.net.Uri.parse(it) }
                    AndroidAutoBrowseTree.playable(id, title, artist, album, durationMs, artUri)
                }
            } catch (e: Throwable) {
                null
            }
        }
    }
}
