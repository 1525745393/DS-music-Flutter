package com.dsplayer.music

import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.IBinder
import android.util.TypedValue
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import io.flutter.plugin.common.MethodChannel

/**
 * 系统悬浮窗歌词
 * - 由 Flutter 端 system_overlay_window 创建后，本服务接管绘制
 * - 提供 updateLyrics / setFontSize / resetPosition 三个 MethodChannel 调用
 */
class OverlayLyricsService : Service() {

    companion object {
        private const val CHANNEL = "dsplayer/overlay_lyrics"
        var currentTitle = ""
        var currentArtist = ""
        var prevText = ""
        var currentText = ""
        var nextText = ""
        var fontSizeSp = 14f
        var rootView: View? = null
        var windowManager: WindowManager? = null
        var layoutParams: WindowManager.LayoutParams? = null
        private var titleView: TextView? = null
        private var prevView: TextView? = null
        private var currentView: TextView? = null
        private var nextView: TextView? = null
        private var initialX = 0
        private var initialY = 0
        private var initialTouchX = 0f
        private var initialTouchY = 0f

        @JvmStatic
        fun updateAll(ctx: Context) {
            titleView?.text = if (currentArtist.isNotEmpty()) "$currentTitle · $currentArtist" else currentTitle
            prevView?.text = prevText
            prevView?.alpha = 0.5f
            currentView?.text = currentText
            currentView?.alpha = 1.0f
            currentView?.setTextColor(Color.WHITE)
            prevView?.setTextColor(Color.argb(180, 220, 220, 220))
            nextView?.text = nextText
            nextView?.alpha = 0.5f
            nextView?.setTextColor(Color.argb(180, 220, 220, 220))
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        rootView?.let { runCatching { windowManager?.removeView(it) } }
        rootView = null
    }
}
