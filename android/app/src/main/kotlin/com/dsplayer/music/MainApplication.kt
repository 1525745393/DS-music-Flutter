package com.dsplayer.music

import android.app.Application

/// 自定义 Application：Flutter v2 embedding 方式
/// 保留扩展点，后续接入 Bugly / 推送 / 崩溃上报等可在 onCreate 中初始化
class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
    }
}
