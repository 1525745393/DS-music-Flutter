# Flutter ProGuard 规则
# 保留 Flutter 引擎关键类，避免 release 混淆导致崩溃/黑屏

# ===== Flutter 引擎 =====
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ===== just_audio / just_audio_background =====
-keep class com.ryanheise.** { *; }
-dontwarn com.ryanheise.audioservice.**

# ===== audio_service =====
-keep class com.ryanheise.audioservice.** { *; }
-keep class com.ryanheise.just_audio.** { *; }

# ===== audio_session =====
-keep class com.ryanheise.audio_session.** { *; }

# ===== Android Auto / MediaBrowserService =====
-keep class com.dsplayer.music.** { *; }

# ===== MediaPlayer / ExoPlayer（音频播放底层） =====
-keep class android.media.MediaPlayer { *; }
-keep class android.media.session.** { *; }
-keep class android.support.v4.media.** { *; }
-keep class android.support.v4.app.** { *; }
-keep class androidx.media.** { *; }
-keep class androidx.core.app.** { *; }

# ===== 通用 Android 保留规则 =====
-keepclassmembers class * {
    @androidx.annotation.Keep <methods>;
}
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# 保留原生方法（JNI 调用）
-keepclasseswithmembernames class * {
    native <methods>;
}

# 保留 View 子类（避免 UI 反射失败）
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
    public void set*(...);
}

# 保留 Activity / Service / Receiver
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.app.Activity

# 保留 R 资源（避免资源 ID 被混淆）
-keep class **.R$* { *; }
-keep class **.R { *; }

# 保留 Parcelable
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# 保留 Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# 保留枚举
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
