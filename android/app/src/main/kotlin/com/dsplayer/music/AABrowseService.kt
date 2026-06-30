package com.dsplayer.music

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.session.MediaSessionCompat
import androidx.media.MediaBrowserServiceCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterMain

/**
 * Android Auto MediaBrowserService 桥接
 *
 * 设计要点：
 * 1. 系统要求在 onCreate() 时创建一个 MediaSessionCompat；
 *    Android Auto 与系统媒体控件都依赖此 session。
 * 2. onLoadChildren(parentId, result) 通过 MethodChannel 调用
 *    Dart 侧 [AndroidAutoBrowseTree.getChildren]，将 Dart 端构建的
 *    浏览树节点返回给 AA / 系统媒体浏览器。
 * 3. 当 Flutter 引擎尚未启动时（例如冷启动 AA 连接），返回 ROOT
 *    节点的 5 个分类占位，避免 AA 报"无内容"。
 *
 * 注册方式：在 AndroidManifest.xml 中将
 *     com.ryanheise.audioservice.AudioService
 * 替换为：
 *     com.dsplayer.music.AABrowseService
 * 注意：替换后 just_audio_background 的前台通知需另行处理，
 *      当前实现仅保证 AA 浏览能力。
 */
class AABrowseService : MediaBrowserServiceCompat() {

    companion object {
        const val CHANNEL = "com.dsplayer.music/auto_browse"
    }

    private var mediaSession: MediaSessionCompat? = null
    private var methodChannel: MethodChannel? = null

    override fun onCreate() {
        super.onCreate()

        // 1. 媒体会话
        mediaSession = MediaSessionCompat(this, "DSPlayerAASession").apply {
            isActive = true
        }
        sessionToken = mediaSession?.sessionToken ?: return

        // 2. 启动 Flutter 引擎（用于调用 Dart 侧浏览树）
        try {
            FlutterMain.startInitialization(this)
            val engine = FlutterEngine(this)
            engine.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            )
            methodChannel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            engineLifecycle = engine
        } catch (e: Throwable) {
            // 引擎启动失败时仍保持服务存活，返回空根节点即可
            methodChannel = null
        }
    }

    private var engineLifecycle: FlutterEngine? = null

    override fun onDestroy() {
        mediaSession?.release()
        engineLifecycle?.destroy()
        super.onDestroy()
    }

    /**
     * 系统/AA 询问根节点可浏览列表
     * 永远返回 ROOT 节点 ID "__ROOT__"，对应 Dart 端 ROOT
     */
    override fun onGetRoot(
        clientPackageName: String,
        clientUid: Int,
        rootHints: Bundle?
    ): BrowserRoot? {
        // 仅允许 Android Auto / 系统媒体浏览器连接
        val isAA = clientPackageName == "com.google.android.projection.gearhead" ||
                   clientPackageName == "com.google.android.googlequicksearchbox" ||
                   clientPackageName == packageName
        return if (isAA) {
            BrowserRoot(AndroidAutoBrowseTree.ROOT, null)
        } else {
            // 拒绝其它客户端连接
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
            // 引擎未就绪，返回根节点静态结构
            result.sendResult(AndroidAutoBrowseTree.ROOT_CHILDREN.toMutableList())
            return
        }

        // 异步调 Dart 端获取真实浏览树
        // 关键：invokeMethod 是异步的，需用 callback 形式
        ch.invokeMethod(
            "getChildren",
            mapOf("parentId" to parentId),
            object : MethodChannel.Result {
                override fun success(result2: Any?) {
                    val items = parseItems(result2)
                    result.sendResult(items.toMutableList())
                }

                override fun error(code: String, msg: String?, details: Any?) {
                    // 失败时回退到根节点静态结构
                    result.sendResult(AndroidAutoBrowseTree.ROOT_CHILDREN.toMutableList())
                }

                override fun notImplemented() {
                    result.sendResult(AndroidAutoBrowseTree.ROOT_CHILDREN.toMutableList())
                }
            }
        )
    }

    /**
     * 解析 Dart 侧返回的 List<Map> 为 MediaItem 列表
     * Dart 端约定的 Map 结构：
     *   { id: String, title: String, browsable: Bool, artist?: String, album?: String, durationMs?: Long, artUri?: String }
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
                    AndroidAutoBrowseTree.run {
                        // 构造可浏览节点
                        val desc = android.support.v4.media.MediaDescriptionCompat.Builder()
                            .setMediaId(id)
                            .setTitle(title)
                            .build()
                        MediaBrowserCompat.MediaItem(desc, MediaBrowserCompat.MediaItem.FLAG_BROWSABLE)
                    }
                } else {
                    // 可播放节点
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
}
