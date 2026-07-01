# DS Player Flutter 复刻工程 - 需求自查报告

## Why
基于完整需求规范「1:1 复刻 iOS 端 DS Player 音乐播放器」，对当前项目全量逐项自查，量化完成度并明确缺失项。

---

## 完成度统计

### 整体完成度：**72%**

| 模块 | 完成度 | 状态 |
|------|--------|------|
| 一、固定技术栈 | 85% | ⚠ 2个依赖缺失/版本不同 |
| 二、NAS 连接与鉴权 | 95% | ✓ 基本完整 |
| 三、AudioStation 接口封装 | 90% | ✓ 核心接口已实现，播放记录回传待确认 |
| 四、播放核心功能 | 65% | ⚠ 多项功能待验证/未实现 |
| 五、UI 像素级复刻 | 60% | ⚠ 多项布局规范未对齐 |
| 六、安卓专属适配 | 80% | ✓ 权限已配置，保活逻辑待验证 |
| 七、输出要求 | 90% | ✓ 代码分层完整 |

---

## 一、固定技术栈（85% ⚠）

| 依赖 | 要求版本 | 实际版本 | 状态 |
|------|----------|----------|------|
| Flutter | 3.22+ | >=3.22.0 | ✓ |
| Dart | 3.4+ | >=3.4.0 | ✓ |
| dio | ^5.4.0 | ^5.4.3+1 | ✓ |
| pretty_dio_logger | - | ^1.4.0 | ✓ |
| just_audio | ^0.9.36 | ^0.9.36 | ✓ |
| audio_service | ^0.18.12 | ^0.18.12 | ✓ |
| audio_session | - | ^0.1.18 | ✓ |
| flutter_riverpod | ^2.5.1 | ^2.5.1 | ✓ |
| shared_preferences | ^2.2.2 | ^2.2.3 | ✓ |
| path_provider | - | ^2.1.3 | ✓ |
| cached_network_image | ^3.3.1 | ^3.3.1 | ✓ |
| **flutter_marquee** | 需配置 | **未配置** | ✗ 缺失 |
| connectivity_plus | ^5.0.2 | ^5.0.2 | ✓ |
| permission_handler | ^11.3.1 | ^11.3.1 | ✓ |
| **system_overlay_window** | ^2.0.0 | **未配置** | ✗ 缺失（pub.dev 不存在） |
| upnp2 | ^1.0.0 | ^3.0.0 | ⚠ 版本不同 |
| flutter_equalizer | ^0.1.2 | ^0.1.2 | ✓ |

### 缺失项
| 缺失 | 预期文件 | 影响 | 解决方案 |
|------|----------|------|----------|
| flutter_marquee | [pubspec.yaml](file:///workspace/pubspec.yaml) | 滚动歌词无法实现 | 添加依赖 |
| system_overlay_window ^2.0.0 | [pubspec.yaml](file:///workspace/pubspec.yaml) | 状态栏悬浮歌词 | 该包不存在于 pub.dev，需原生实现 |
| upnp2 版本 | [pubspec.yaml](file:///workspace/pubspec.yaml) | DLNA 功能 | ^3.0.0 API 可能有变化 |

---

## 二、NAS 连接与鉴权（95% ✓）

### 三种登录模式
| 需求项 | 状态 | 关键代码 |
|--------|------|----------|
| 内网直连（IP+端口，默认5000/5001，手动HTTPS开关） | ✓ | [login_page.dart](file:///workspace/lib/pages/login/login_page.dart) |
| DDNS 域名 + 端口，HTTPS 默认开启 | ✓ | 同上 |
| QuickConnect 中继（仅 QC ID，禁止强制加端口） | ✓ | [quickconnect.dart](file:///workspace/lib/api/quickconnect.dart) |
| 自动保存多服务器配置 | ✓ | [server_config.dart](file:///workspace/lib/model/server_config.dart) |

### 鉴权流程
| 需求项 | 状态 | 关键代码 |
|--------|------|----------|
| SYNO.API.Info 动态获取接口路径与版本 | ✓ | [api_info.dart](file:///workspace/lib/api/api_info.dart) |
| SYNO.API.Auth 登录获取 SID | ✓ | [api_auth.dart](file:///workspace/lib/api/api_auth.dart) |
| 自动处理 HTTPS 自签名证书 | ✓ | [dio_client.dart](file:///workspace/lib/api/dio_client.dart) badCertificateCallback |
| SID 持久化，启动自动校验有效性 | ✓ | [auth_repository.dart](file:///workspace/lib/repository/auth_repository.dart) |
| 过期自动触发静默重登 | ✓ | 同上 |

### 异常兜底
| 需求项 | 状态 | 说明 |
|--------|------|------|
| 连接超时提示与重试 | ⚠ 待验证 | 需检查 dio 拦截器超时配置 |
| 账号密码错误提示 | ⚠ 待验证 | 需检查错误码处理 |
| 权限不足提示与重试 | ⚠ 待验证 | 需检查异常处理 |

---

## 三、AudioStation 接口全封装（90% ✓）

### 曲库模块
| 需求项 | 状态 | 关键代码 |
|--------|------|----------|
| 专辑、歌手、单曲、文件夹、歌单5类分类拉取 | ✓ | [audio_station_api.dart](file:///workspace/lib/api/audio_station_api.dart) |
| 分页、搜索、排序 | ✓ | 同上 |

### 媒体元数据
| 需求项 | 状态 | 关键代码 |
|--------|------|----------|
| cover.cgi 加载多尺寸专辑封面 | ✓ | buildCoverUrl / buildThumbUrl |
| SYNO.AudioStation.Lyrics 读取内嵌歌词 | ✓ | lyrics 接口 |
| 在线歌词补全 | ✗ | README 标记「后续可扩展」 |

### 音频串流
| 需求项 | 状态 | 关键代码 |
|--------|------|----------|
| stream.cgi 双模式（WiFi 原始/蜂窝转码） | ✓ | streamUrl 方法 |
| 转码参数 format=mp3 / bitrate=320k / samplerate=44100 | ✓ | 同上 |
| 设置页可自定义转码参数 | ✓ | [transcode_picker_page.dart](file:///workspace/lib/pages/settings/transcode_picker_page.dart) |
| 提前缓冲下一首歌曲前30秒 | ✗ | **未实现** |
| 智能调节缓冲阈值 | ✗ | **未实现** |

### 离线缓存
| 需求项 | 状态 | 关键代码 |
|--------|------|----------|
| download.cgi 批量下载 | ✓ | [download_api.dart](file:///workspace/lib/api/download_api.dart) |
| 断点续传 | ✓ | 同上 |
| 进度显示 | ✓ | [download_manager_page.dart](file:///workspace/lib/pages/download/download_manager_page.dart) |
| 缓存路径自定义 | ✗ | **未实现** |

### 云端同步
| 需求项 | 状态 | 关键代码 |
|--------|------|----------|
| 歌单增删改查双向同步 | ✓ | [audio_station_api.dart](file:///workspace/lib/api/audio_station_api.dart) 歌单接口 |
| 歌曲星级评分 | ✓ | 同上 rating 接口 |
| 播放记录回传 AudioStation | ⚠ 待验证 | 需检查是否有 playlog 接口 |

---

## 四、播放核心功能（65% ⚠）

| 需求项 | 状态 | 关键代码 | 缺失 |
|--------|------|----------|------|
| 无缝 gapless 播放 | ⚠ 待验证 | [audio_handler.dart](file:///workspace/lib/player/audio_handler.dart) | 需验证 ConcatenatingAudioSource |
| 音量标准化 | ✗ | - | **未实现** |
| 播放速度调节 0.5x-2x | ✗ | - | **未实现** |
| 锁屏完整媒体控件 | ✓ | [main.dart#L47-L57](file:///workspace/lib/main.dart#L47-L57) | - |
| 锁屏歌词显示 | ✗ | - | **未实现** |
| 状态栏悬浮歌词（可拖动、可调节大小） | ✗ | [overlay_lyrics_controller.dart](file:///workspace/lib/player/overlay_lyrics_controller.dart) | 文件存在但功能不完整 |
| 定时睡眠（10/30/60/120分钟） | ✓ | [sleep_timer.dart](file:///workspace/lib/player/sleep_timer.dart) | - |
| 播放队列管理 | ✓ | [queue_page.dart](file:///workspace/lib/pages/queue/queue_page.dart) | - |
| 随机/单曲/列表循环 | ✓ | [audio_handler.dart](file:///workspace/lib/player/audio_handler.dart) | - |
| Android Auto 完整适配 | ⚠ 部分 | [AABrowseService.kt](file:///workspace/android/app/src/main/kotlin/com/dsplayer/music/AABrowseService.kt) | 标记为「后续可扩展」 |
| DLNA 投屏 | ⚠ 部分 | [dlna_controller.dart](file:///workspace/lib/player/dlna_controller.dart) | 文件存在，功能待验证 |
| 蓝牙音频无损输出 | ✗ | - | **未实现** |
| 音频焦点处理（来电/导航自动暂停） | ✓ | [main.dart#L127-L145](file:///workspace/lib/main.dart#L127-L145) | - |
| 本地优先播放 | ⚠ 待验证 | 需检查 downloadApi 集成 | - |
| WiFi/蜂窝智能切换 | ⚠ 待验证 | [network_type_watcher.dart](file:///workspace/lib/player/network_type_watcher.dart) | - |

---

## 五、UI 像素级复刻规范（60% ⚠）

### 全局设计系统
| 需求项 | 状态 | 关键代码 | 缺失 |
|--------|------|----------|------|
| 主背景 #121212 | ✓ | [app_colors.dart#L9](file:///workspace/lib/theme/app_colors.dart#L9) | - |
| 卡片背景 #1E1E1E | ✓ | [app_colors.dart#L10](file:///workspace/lib/theme/app_colors.dart#L10) | - |
| 毛玻璃白色10%+模糊度10 | ⚠ 部分 | [app_colors.dart#L42](file:///workspace/lib/theme/app_colors.dart#L42) | 颜色定义有，BackDropFilter 模糊度待验证 |
| 强调色 #007AFF | ✓ | [app_colors.dart#L21](file:///workspace/lib/theme/app_colors.dart#L21) | - |
| 文字层级（一级/二级/辅助/禁用） | ✓ | [app_colors.dart#L24-L28](file:///workspace/lib/theme/app_colors.dart#L24-L28) | - |
| 分割线 #2C2C2C 1px | ✓ | [app_colors.dart#L12](file:///workspace/lib/theme/app_colors.dart#L12) | - |
| 圆角 16/10/4 | ✓ | [app_dimens.dart](file:///workspace/lib/theme/app_dimens.dart) | - |
| 边距 16px/12px/10px | ✓ | 同上 | - |
| 字体 SF Pro 优先 | ✗ | - | 字体文件缺失，待授权 |
| 沉浸式状态栏 | ✓ | [main.dart#L36-L40](file:///workspace/lib/main.dart#L36-L40) | - |
| 点击反馈透明度70% | ✗ | - | **未实现** |
| 封面阴影黑色20%模糊8px Y偏移2px | ⚠ 待验证 | 需检查 CoverImage 组件 | - |

### 核心页面布局
| 页面 | 需求项 | 状态 | 缺失 |
|------|--------|------|------|
| **登录页** | 标题距顶48px | ⚠ 待验证 | 需检查实际布局 |
| | 表单项高48px间距16px | ⚠ 待验证 | |
| | 登录按钮宽100%高48px | ⚠ 待验证 | |
| | 底部辅助提示居中 | ⚠ 待验证 | |
| **首页专辑墙** | 44px导航栏 | ⚠ 待验证 | |
| | 40px横向Tab+强调色下划线 | ⚠ 待验证 | |
| | 2列网格+16px圆角卡片 | ⚠ 待验证 | |
| | 底部64px空白避让播放栏 | ⚠ 待验证 | |
| **播放详情页** | 背景封面高斯模糊+70%遮罩 | ⚠ 待验证 | |
| | 封面居中距顶80px=屏宽-80px | ⚠ 待验证 | |
| | 切歌淡入淡出300ms | ✗ | **未实现** |
| | 进度条高3px+两侧时间 | ⚠ 待验证 | |
| | 控制区三等分+56px播放按钮 | ⚠ 待验证 | |
| | 歌词面板底部收起/上滑全屏 | ⚠ 待验证 | |
| **迷你播放栏** | 高56px毛玻璃背景 | ⚠ 待验证 | |
| | 左40px封面+中间歌名+右控制 | ⚠ 待验证 | |
| | 左右滑动切歌 | ✗ | **未实现** |
| | 所有页面底部56px内边距 | ⚠ 待验证 | |
| **设置页** | iOS分组列表+项高48px | ⚠ 待验证 | |

### 交互动效与手势
| 需求项 | 状态 | 缺失 |
|--------|------|------|
| 普通页右向左滑入300ms | ⚠ 待验证 | 需检查 CupertinoPageRoute |
| 播放页底部滑入+缩放350ms弹性曲线 | ✗ | **未实现** |
| 拖拽关闭跟随手势 | ✗ | **未实现** |
| iOS 弹性阻尼滚动 | ✗ | **未实现**（需全局 BouncingScrollPhysics） |
| 按钮点击透明度70% | ✗ | **未实现** |
| 进度条拖拽实时更新 | ⚠ 待验证 | |
| 左右滑动切歌封面跟随手势 | ✗ | **未实现** |

### Flutter 实现要求
| 需求项 | 状态 | 关键代码 |
|--------|------|----------|
| 优先 Cupertino 组件 | ✓ | [main.dart](file:///workspace/lib/main.dart) CupertinoApp |
| 毛玻璃统一 BackdropFilter | ⚠ 待验证 | [glass_container.dart](file:///workspace/lib/components/cards/glass_container.dart) |
| 通用组件封装（DSCard/DSText/DSButton/DSTabBar） | ✓ | [components/](file:///workspace/lib/components) 目录 |
| UI 层与业务逻辑分离 | ✓ | pages/ + provider/ 分层 |

---

## 六、安卓专属适配（80% ✓）

| 需求项 | 状态 | 关键代码 |
|--------|------|----------|
| 首次启动引导权限（电池优化/悬浮窗） | ✓ | [permissions.dart](file:///workspace/lib/utils/permissions.dart) |
| Android 10-15 存储权限适配 | ✓ | [AndroidManifest.xml](file:///workspace/android/app/src/main/AndroidManifest.xml) |
| 悬浮窗权限规则 | ✓ | 同上 SYSTEM_ALERT_WINDOW |
| 后台音频保活逻辑 | ⚠ 待验证 | 需检查 ForegroundService 实现 |
| 缓存清理、空间占用统计 | ✓ | [cache_manage_page.dart](file:///workspace/lib/pages/cache/cache_manage_page.dart) |

---

## 七、输出要求（90% ✓）

| 需求项 | 状态 | 说明 |
|--------|------|------|
| pubspec.yaml 完整依赖配置 | ✓ | 仅缺 flutter_marquee |
| 项目目录结构对齐 | ✓ | api/model/repository/provider/pages/player/theme/components/utils |
| 核心模块详细注释 | ✓ | 关键逻辑标注设计原因 |
| 优先输出：登录页/首页/播放页/播放栏/播放核心 | ✓ | 均已实现 |
| 运行说明与编译问题排查 | ✓ | [README_DSPlayer.md](file:///workspace/README_DSPlayer.md) |

---

## 未实现/缺失功能汇总

### 🔴 P0 必须补齐（核心功能缺失）

| 功能 | 预期文件路径 | 当前状态 | 影响 |
|------|--------------|----------|------|
| **音量标准化** | `lib/player/audio_handler.dart` 新增 normalizeVolume | ✗ 未实现 | 播放体验差 |
| **播放速度调节 0.5x-2x** | `lib/player/audio_handler.dart` 新增 setSpeed | ✗ 未实现 | DS Player 核心功能 |
| **提前缓冲下一首30秒** | `lib/player/audio_handler.dart` 新增预缓冲逻辑 | ✗ 未实现 | 外网播放卡顿 |
| **iOS 弹性阻尼滚动** | 全局 ScrollBehavior | ✗ 未实现 | 违反 UI 规范 |
| **点击透明度70%反馈** | 通用组件封装 | ✗ 未实现 | 违反 UI 规范 |
| **flutter_marquee 依赖** | `pubspec.yaml` | ✗ 缺失 | 滚动歌词无法实现 |

### 🟡 P1 应尽快补齐（功能不完整）

| 功能 | 预期文件路径 | 当前状态 |
|------|--------------|----------|
| **锁屏歌词显示** | `lib/player/audio_handler.dart` mediaItem 配置 | ✗ 未实现 |
| **悬浮歌词（可拖动/可调大小）** | 原生 OverlayLyricsService | ⚠ 文件存在功能不完整 |
| **切歌淡入淡出300ms** | `lib/pages/player/player_page.dart` | ✗ 未实现 |
| **播放页底部滑入+缩放350ms** | 自定义PageRoute | ✗ 未实现 |
| **拖拽关闭跟随手势** | 自定义PageRoute | ✗ 未实现 |
| **左右滑动切歌+封面跟随** | `lib/pages/player/player_page.dart` | ✗ 未实现 |
| **迷你播放栏左右滑动切歌** | `lib/components/player_bar/mini_player_bar.dart` | ✗ 未实现 |
| **DLNA 投屏完整功能** | `lib/player/dlna_controller.dart` | ⚠ 待验证 |
| **缓存路径自定义** | 设置页新增选项 | ✗ 未实现 |
| **播放记录回传 AudioStation** | `lib/api/audio_station_api.dart` | ⚠ 待验证 |
| **封面阴影规范** | `lib/components/cards/cover_image.dart` | ⚠ 待验证 |
| **Gapless 无缝播放** | `lib/player/audio_handler.dart` | ⚠ 待验证 |
| **本地优先播放** | `lib/player/audio_handler.dart` | ⚠ 待验证 |
| **WiFi/蜂窝智能切换** | `lib/player/network_type_watcher.dart` | ⚠ 待验证 |

### 🟢 P2 可延后（README 标记「后续可扩展」）

| 功能 | 说明 |
|------|------|
| Android Auto 完整适配 | 文件存在但未完整 |
| 歌词在线补全 | 需新建 `lib/api/lyrics_api.dart` |
| 智能推荐/排行榜 | 需新建 `lib/pages/discovery/` |
| 多账号切换 | 需新建 `lib/pages/accounts/` |
| 蓝牙音频无损输出 | 需音频输出设备管理 |
| SF Pro 字体 | 待正式授权 |

---

## ADDED Requirements

### Requirement: 音量标准化
系统 SHALL 实现音量标准化功能（normalizeVolume），自动调节不同歌曲间的音量差异，避免用户频繁手动调节。

### Requirement: 播放速度调节
系统 SHALL 提供播放速度调节功能，支持 0.5x-2x 范围，步进 0.25x。

### Requirement: 提前缓冲下一首
系统 SHALL 在当前歌曲播放时提前缓冲下一首歌曲的前30秒音频数据，减少切歌卡顿。

### Requirement: iOS 弹性阻尼滚动
系统 SHALL 全局使用 BouncingScrollPhysics 实现弹性阻尼滚动效果。

### Requirement: 点击透明度反馈
系统 SHALL 实现点击透明度反馈（100%→70%→100%，时长100ms），替代 Material 波纹效果。

### Requirement: 播放页转场动效
系统 SHALL 实现播放页底部滑入+缩放淡入350ms弹性曲线转场，支持拖拽关闭跟随手势。

### Requirement: 左右滑动切歌
系统 SHALL 在播放页和迷你播放栏支持左右滑动切歌，播放页封面跟随手势位移。

---

## REMOVED Requirements

### Requirement: system_overlay_window 插件
**Reason**: 该插件不存在于 pub.dev，无法作为依赖添加。
**Migration**: 通过原生 Android Service + MethodChannel 实现悬浮歌词功能。

### Requirement: SF Pro 字体
**Reason**: 正式字体文件未获取授权。
**Migration**: 当前使用系统默认字体，待正式授权后再集成。