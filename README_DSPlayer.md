# DS Player - Synology AudioStation Flutter Client

> 1:1 复刻 iOS 端 DS Player 音乐播放器体验，基于 Synology AudioStation 开放 WebAPI。

## 📦 项目结构

```
lib/
├── api/                # 接口层（Dio 客户端、Auth、AudioStation、QuickConnect、Download）
├── model/              # 实体类（ServerConfig、Album、Artist、Song、Playlist、Lyrics、Exception）
├── repository/         # 数据仓库（Auth、Library）
├── provider/           # Riverpod 状态管理（core、auth、library、player、settings）
├── pages/              # UI 页面（login、home、player、settings、album、artist、playlist、search）
├── player/             # 播放核心（audio_handler、playback_service、sleep_timer、equalizer、dlna）
├── theme/              # 全局主题（colors、text、dimens、theme）
├── components/         # 通用组件（cards、buttons、lists、lyrics、player_bar、ds_text/tab/state）
├── utils/              # 工具类（logger、permissions、network、file、datetime）
├── constants/          # 常量（api、app、storage_keys）
└── main.dart           # 应用入口
```

## 🚀 快速开始

### 1. 环境要求

- Flutter **3.22+** 稳定版
- Dart **3.4+**
- Android **5.0+**（API 21+）/ iOS 12+
- Android Studio / VS Code

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 运行

```bash
# Android 真机/模拟器
flutter run -d android

# iOS
flutter run -d ios
```

### 4. 构建发布

```bash
# Android Release APK
flutter build apk --release

# Android AppBundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 🔑 核心能力

### NAS 连接
- **三种登录模式**：内网直连（IP+端口）、DDNS 域名、QuickConnect 中继
- **动态接口发现**：调用 `SYNO.API.Info` 拉取所有接口路径与最大版本
- **自签证书兼容**：HTTPS NAS 自动信任
- **SID 持久化 + 静默重登**：过期自动续期

### 播放
- **无缝 gapless**：`ConcatenatingAudioSource` 拼接
- **WiFi/蜂窝智能切换**：WiFi 原始码流，蜂窝转码 320k MP3
- **本地优先**：已下载歌曲直接播放本地
- **后台播放 + 锁屏控件**：`audio_service` + `just_audio_background`
- **DSD/FLAC/APE 全格式软解**：`just_audio` 默认软解

### UI（iOS 扁平化）
- 严格遵循 iOS 设计语言，禁止 Material 默认样式
- 主背景 `#121212`，强调色 `#007AFF`
- 沉浸式状态栏、毛玻璃 10%、圆角 16/10/4
- 弹性阻尼滚动、点击透明度反馈

## ⚠️ 常见编译问题排查

| 问题 | 解决方案 |
|------|----------|
| `Target of URI doesn't exist: 'package:just_audio_media_kit/...'` | 确认 pubspec 完整后 `flutter pub get` |
| `audio_service 启动失败` | 检查 AndroidManifest 是否注册 `MediaButtonReceiver` 和 `AudioService` |
| 通知不显示 | Android 13+ 必须请求 `POST_NOTIFICATIONS` 权限 |
| HTTPS 自签失败 | 已通过 `dio/io` 拦截器 `badCertificateCallback` 处理 |
| 悬浮窗歌词不显示 | 需先引导用户授予「显示悬浮窗」权限 |
| 后台被查杀 | 引导用户加入「电池优化白名单」 |
| DSD 无声 | 默认软解，需要设备支持；外接 USB DAC 时可尝试 `just_audio_media_kit` 直通 |
| `MissingPluginException` | 执行 `flutter clean && flutter pub get`，然后重装 |
| Gradle 构建失败 | 检查 `android/build.gradle` 的 `minSdkVersion >= 21` |
| QuickConnect 解析失败 | 检查 NAS QuickConnect 服务是否开启，并允许此设备 |

## 📋 版本号管理

格式：`x.y.z+BUILD_NUMBER`
- `pubspec.yaml` 的 `version` 字段
- 同步修改 `android/app/build.gradle` 的 `versionCode` 与 `versionName`

## 🔒 Android 关键权限

| 权限 | 用途 |
|------|------|
| `INTERNET` | API 请求 |
| `FOREGROUND_SERVICE` | 后台播放 |
| `POST_NOTIFICATIONS` | 锁屏通知（Android 13+） |
| `READ_MEDIA_AUDIO` | 读取本地音乐（Android 13+） |
| `WAKE_LOCK` | 息屏播放 |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | 防止系统查杀 |
| `SYSTEM_ALERT_WINDOW` | 悬浮歌词 |
| `CHANGE_WIFI_MULTICAST_STATE` | DLNA 发现 |

## 🛠️ 后续可扩展

- Android Auto / CarPlay 适配
- 歌词在线补全（公网 API）
- 智能推荐 / 排行榜
- 多用户/多账号切换
- Apple Music / Spotify 第三方登录
