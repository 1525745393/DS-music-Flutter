package com.dsplayer.music

import io.flutter.app.FlutterApplication
import io.flutter.embedding.engine.plugins.GeneratedPluginRegistrant

/// 自定义 Application：保留扩展点
/// FlutterApplication 已包含默认插件注册逻辑，
/// 后续接入 Bugly / 推送 / 崩溃上报等可在 onCreate 中初始化
class MainApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
    }
}
