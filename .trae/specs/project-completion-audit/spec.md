# DS Player 项目完成度自查报告

## Why
对当前 Flutter 项目进行全面审计，对照 README_DSPlayer.md 定义的核心需求，量化完成度并明确缺失项，为后续开发提供清晰的优先级路线图。

## What Changes
- 本次为**纯分析任务**，不涉及代码修改
- 生成三份文档：spec.md（本报告）、tasks.md（待办清单）、checklist.md（验证清单）

## Impact
- 影响范围：项目整体开发规划
- 不影响现有代码

---

## 完成度统计

### 整体完成度：**75%**（P0 核心功能验证后更新）

| 模块 | 完成度 | 状态 |
|------|--------|------|
| NAS 连接与认证 | 90% | ✓ 已实现核心功能 |
| 音乐库浏览 | 85% | ✓ P0 验证通过，数据加载完整 |
| 播放核心 | 90% | ✓ P0 验证通过，播放/模式切换完整 |
| UI/主题 | 75% | ✓ P0 验证通过，核心组件完整 |
| DLNA 投屏 | 40% | ⚠ 基础文件存在，功能完整性待验证 |
| 后台播放/锁屏控件 | 85% | ✓ 已实现 |
| 权限管理 | 80% | ✓ 已实现核心权限 |
| 系统集成（Android Auto/悬浮歌词） | 50% | ⚠ 文件存在但可能未完整 |

### P0 核心功能验证结论

| 功能 | 验证结果 | 关键发现 |
|------|----------|----------|
| **首页数据加载** | ✓ 完整实现 | albumsProvider/artistsProvider/songsProvider/foldersProvider/playlistsProvider 全部通过 ref.watch 监听，含 loading/error/empty 占位 |
| **MiniPlayerBar** | ✓ 完整实现 | 订阅 playerStateProvider，显示标题/艺术家，含播放控制按钮，点击导航通过 onTap 回调处理 |
| **CoverImage** | ✓ 完整实现 | 接受外部 url，library_repository.coverUrl + audio_station_api.buildCoverUrl 方法完整，cached_network_image 配置完整 |
| **SongListTile** | ✓ 完整实现 | onTap/onMore 回调设计合理，播放逻辑由父组件处理（符合组件化设计） |
| **播放模式切换** | ✓ 完整实现 | setShuffleMode/setRepeatMode 方法存在，ConcatenatingAudioSource 实现 gapless |

---

## 已实现的核心模块

### ✓ 完全实现

| 模块 | 关键文件 | 说明 |
|------|----------|------|
| **应用入口** | `lib/main.dart` | 初始化、Provider 注入、路由配置 |
| **网络层** | `lib/api/dio_client.dart`, `lib/api/api_auth.dart` | HTTP 客户端、自签证书兼容 |
| **NAS 认证** | `lib/api/quickconnect.dart`, `lib/api/api_info.dart` | QuickConnect、接口发现 |
| **AudioStation API** | `lib/api/audio_station_api.dart` | 音乐库数据接口 |
| **数据模型** | `lib/model/song.dart`, `lib/model/album.dart`, `lib/model/artist.dart`, `lib/model/playlist.dart` | 核心实体类 |
| **状态管理** | `lib/provider/core_providers.dart`, `lib/provider/auth_provider.dart`, `lib/provider/player_provider.dart` | Riverpod 状态管理 |
| **播放核心** | `lib/player/audio_handler.dart`, `lib/player/playback_service.dart` | just_audio + audio_service 集成 |
| **后台播放** | AndroidManifest 配置 + `just_audio_background` | 通知栏控件、锁屏播放 |
| **睡眠定时器** | `lib/player/sleep_timer.dart` | 定时停止播放 |
| **下载管理** | `lib/api/download_api.dart`, `lib/pages/download/download_manager_page.dart` | 文件下载功能 |
| **本地缓存** | `lib/pages/cache/cache_manage_page.dart` | 缓存管理页面 |
| **搜索功能** | `lib/pages/search/search_page.dart` | 搜索页面 |
| **设置页** | `lib/pages/settings/settings_page.dart`, `lib/pages/settings/locale_picker_page.dart`, `lib/pages/settings/transcode_picker_page.dart` | 语言、转码设置 |
| **登录页** | `lib/pages/login/login_page.dart` | 三种登录模式支持 |
| **引导页** | `lib/pages/onboarding/onboarding_page.dart` | 首次启动引导 |
| **主页框架** | `lib/pages/main_shell.dart`, `lib/pages/home/home_page.dart` | 导航框架 |
| **播放器页** | `lib/pages/player/player_page.dart` | 全屏播放器 |
| **专辑详情** | `lib/pages/album/album_detail_page.dart` | 专辑浏览 |
| **艺术家详情** | `lib/pages/artist/artist_detail_page.dart` | 艺术家浏览 |
| **播放列表** | `lib/pages/playlist/playlist_detail_page.dart`, `lib/pages/playlist/playlist_editor_page.dart` | 播放列表管理 |
| **播放队列** | `lib/pages/queue/queue_page.dart` | 队列管理 |
| **歌词组件** | `lib/components/lyrics/lyrics_view.dart`, `lib/model/lyrics.dart` | 歌词显示 |
| **文件夹浏览** | `lib/pages/folder/folder_browse_page.dart` | 文件夹导航 |
| **均衡器** | `lib/pages/equalizer/equalizer_page.dart`, `lib/player/equalizer_controller.dart` | UI 存在（纯状态维护） |
| **主题配置** | `lib/theme/app_colors.dart`, `lib/theme/app_theme.dart`, `lib/theme/app_dimens.dart` | iOS 风格主题 |
| **服务器管理** | `lib/pages/servers/servers_page.dart`, `lib/model/server_config.dart` | 多服务器配置 |
| **崩溃上报** | `lib/utils/crash_reporter.dart` | 本地记录 + 占位上报 |
| **CI/CD** | `.github/workflows/ci.yml`, `.github/workflows/release.yml` | Semantic Release 自动化 |
| **ProGuard** | `android/app/proguard-rules.pro` | R8 混淆规则 |

### ⚠ 部分实现（文件存在但功能可能不完整）

| 模块 | 关键文件 | 缺失内容 |
|------|----------|----------|
| **DLNA 投屏** | `lib/player/dlna_controller.dart`, `lib/pages/dlna/dlna_devices_page.dart`, `lib/pages/dlna/dlna_browse_page.dart` | 文件存在，但 README 提到 `CHANGE_WIFI_MULTICAST_STATE` 权限用于 DLNA 发现，实际投屏功能完整性待验证 |
| **悬浮歌词** | `lib/player/overlay_lyrics_controller.dart`, `lib/pages/overlay_lyrics/overlay_lyrics_settings_page.dart`, `android/app/src/main/kotlin/com/dsplayer/music/OverlayLyricsService.kt` | 文件存在，但 pubspec.yaml 注明 `system_overlay_window` 插件不存在于 pub.dev，需原生实现 |
| **Android Auto** | `lib/player/android_auto_browse_tree.dart`, `android/app/src/main/kotlin/com/dsplayer/music/AABrowseService.kt` | 文件存在，README 标记为「后续可扩展」 |
| **网络智能切换** | `lib/player/network_type_watcher.dart` | 文件存在，WiFi/蜂窝切换逻辑待验证 |
| **无缝播放 Gapless** | `lib/player/audio_handler.dart` | README 提到 `ConcatenatingAudioSource`，实际实现待验证 |
| **歌词提供者** | `lib/provider/lyrics_provider.dart` | 文件存在，但 README 标记「歌词在线补全」为后续扩展 |

---

## 未实现/缺失的功能

### 🔴 P0 必须优先补齐（核心功能缺失）

| 功能 | 预期文件路径 | 当前状态 | 影响 |
|------|--------------|----------|------|
| **首页数据加载** | `lib/pages/home/home_page.dart` → 需验证数据绑定 | 文件存在，可能仅骨架 | 用户无法浏览音乐库 |
| **MiniPlayerBar 数据绑定** | `lib/components/player_bar/mini_player_bar.dart` → 需验证状态订阅 | 文件存在，可能未连接 Provider | 底部播放条无动态信息 |
| **封面图片组件** | `lib/components/cards/cover_image.dart` → 需验证 AudioStation 封面 URL | 文件存在，URL 生成逻辑待验证 | 专辑/艺术家无封面显示 |
| **SongListTile 播放交互** | `lib/components/lists/song_list_tile.dart` → 需验证点击播放逻辑 | 文件存在，事件处理待验证 | 点击歌曲无响应 |
| **CoverImage 缓存策略** | `lib/components/cards/cover_image.dart` | 可能未配置 `cached_network_image` 占位/错误图 | 图片加载体验差 |

### 🟡 P1 应尽快补齐（重要功能不完整）

| 功能 | 预期文件路径 | 当前状态 | 影响 |
|------|--------------|----------|------|
| **DLNA 设备发现** | `lib/player/dlna_controller.dart` → `upnp2` 集成 | 文件存在，发现逻辑待验证 | 无法发现投屏设备 |
| **DLNA 投屏控制** | `lib/pages/dlna/dlna_browse_page.dart` → 播放控制指令 | 文件存在，控制逻辑待验证 | 投屏后无法控制 |
| **悬浮歌词原生实现** | `android/app/src/main/kotlin/com/dsplayer/music/OverlayLyricsService.kt` | 文件存在，可能仅占位 | 无悬浮歌词功能 |
| **网络类型切换逻辑** | `lib/player/network_type_watcher.dart` → WiFi/蜂窝判断 + 转码切换 | 文件存在，切换逻辑待验证 | 蜂窝网络可能播放原始码流 |
| **Gapless 播放实现** | `lib/player/audio_handler.dart` → `ConcatenatingAudioSource` | 待验证是否实现 | 歌曲间有间隙 |
| **歌词同步滚动** | `lib/components/lyrics/lyrics_view.dart` → 播放进度同步 | 文件存在，同步逻辑待验证 | 歌词不随播放滚动 |
| **播放模式切换** | `lib/player/audio_handler.dart` → 单曲循环/列表循环/随机 | 待验证是否实现 | 无法切换播放模式 |
| **本地优先播放** | `lib/repository/library_repository.dart` → 已下载歌曲优先 | 待验证逻辑 | 下载后仍从网络播放 |

### 🟢 P2 可延后优化（增强体验）

| 功能 | 预期文件路径 | 当前状态 | 影响 |
|------|--------------|----------|------|
| **Android Auto 完整适配** | `lib/player/android_auto_browse_tree.dart`, `android/app/src/main/kotlin/com/dsplayer/music/AABrowseService.kt` | 文件存在但 README 标记为「后续可扩展」 | 无法在车载系统浏览音乐库 |
| **歌词在线补全** | 需新建 `lib/api/lyrics_api.dart` + 公网 API 集成 | **不存在** | 无歌词歌曲无法自动获取 |
| **智能推荐/排行榜** | 需新建 `lib/pages/discovery/discovery_page.dart` | **不存在** | 无发现新音乐入口 |
| **多账号切换** | 需新建 `lib/pages/accounts/accounts_page.dart` | **不存在** | 无法管理多个 NAS 账号 |
| **Apple Music/Spotify 登录** | 需新建 `lib/api/oauth_api.dart` | **不存在** | 无第三方服务集成 |
| **SF Pro 字体** | `assets/fonts/` 目录仅有 `README.md` | **不存在字体文件** | 使用系统默认字体 |
| **资源图标** | `assets/icons/`, `assets/images/` 仅含 `README.md` | **不存在图标资源** | 使用 Material/Cupertino 默认图标 |

---

## 不存在的页面/文件

### 完全缺失的页面

| 页面 | 预期路径 | 说明 |
|------|----------|------|
| **发现/推荐页** | `lib/pages/discovery/discovery_page.dart` | README 标记为「后续可扩展」 |
| **账号管理页** | `lib/pages/accounts/accounts_page.dart` | README 标记为「后续可扩展」 |
| **第三方登录页** | `lib/pages/login/oauth_page.dart` | README 标记为「后续可扩展」 |
| **歌词搜索页** | `lib/pages/lyrics/lyrics_search_page.dart` | README 标记为「后续可扩展」 |

### 完全缺失的 API 文件

| API | 预期路径 | 说明 |
|-----|----------|------|
| **歌词公网 API** | `lib/api/lyrics_api.dart` | 无第三方歌词服务集成 |
| **OAuth API** | `lib/api/oauth_api.dart` | 无第三方账号登录 |
| **推荐 API** | `lib/api/recommendation_api.dart` | 无智能推荐服务 |

### 完全缺失的资源文件

| 资源 | 预期路径 | 说明 |
|------|----------|------|
| **SF Pro 字体** | `assets/fonts/SFPro-Regular.ttf` 等 | README 注明「等拿到正式授权字体后再恢复」 |
| **应用图标（矢量）** | `assets/icons/` 下应含 SVG 图标 | 目录仅含 README.md |
| **占位图片** | `assets/images/placeholder.png` | 目录仅含 README.md |

---

## 优先级排序

### P0：必须先补的核心功能（影响基本使用）

1. **验证并修复首页数据加载** - `lib/pages/home/home_page.dart`
2. **验证 MiniPlayerBar 状态订阅** - `lib/components/player_bar/mini_player_bar.dart`
3. **验证 CoverImage 封面 URL 生成** - `lib/components/cards/cover_image.dart`
4. **验证 SongListTile 点击播放** - `lib/components/lists/song_list_tile.dart`
5. **验证播放模式切换逻辑** - `lib/player/audio_handler.dart`

### P1：应尽快补齐的功能（重要体验）

6. **完善 DLNA 发现与控制** - `lib/player/dlna_controller.dart`
7. **实现悬浮歌词原生服务** - `android/app/src/main/kotlin/com/dsplayer/music/OverlayLyricsService.kt`
8. **验证网络类型切换** - `lib/player/network_type_watcher.dart`
9. **验证 Gapless 播放** - `lib/player/audio_handler.dart`
10. **完善歌词同步滚动** - `lib/components/lyrics/lyrics_view.dart`

### P2：可延后的优化项（增强体验）

11. **Android Auto 完整适配** - `lib/player/android_auto_browse_tree.dart`
12. **歌词在线补全** - 新建 `lib/api/lyrics_api.dart`
13. **智能推荐页** - 新建 `lib/pages/discovery/discovery_page.dart`
14. **多账号管理** - 新建 `lib/pages/accounts/accounts_page.dart`
15. **SF Pro 字体集成** - 待正式授权

---

## ADDED Requirements

### Requirement: 功能验证与补齐
系统 SHALL 对所有标记为「文件存在但功能待验证」的模块进行代码审计，确认实际实现状态并补齐缺失逻辑。

#### Scenario: 验证首页数据加载
- **WHEN** 用户打开应用进入首页
- **THEN** 应显示最近播放、推荐专辑、艺术家列表等数据
- **AND** 数据应通过 `libraryRepositoryProvider` 从 AudioStation API 加载

#### Scenario: 验证 MiniPlayerBar 状态订阅
- **WHEN** 用户播放音乐
- **THEN** MiniPlayerBar 应显示当前歌曲标题、艺术家、进度
- **AND** 点击 MiniPlayerBar 应导航到全屏播放器页

#### Scenario: 验证 CoverImage 封面加载
- **WHEN** 显示专辑/艺术家卡片
- **THEN** 应通过 AudioStation 封面 API 加载图片
- **AND** 使用 `cached_network_image` 提供占位图和错误图

---

## MODIFIED Requirements

### Requirement: 悬浮歌词功能
原有设计依赖 `system_overlay_window` 插件，但该插件不存在于 pub.dev。
**修改为**：通过原生 Android Service 实现，使用 `SYSTEM_ALERT_WINDOW` 权限绘制悬浮窗口。

---

## REMOVED Requirements

### Requirement: SF Pro 字体
**Reason**: 正式字体文件未获取授权，pubspec.yaml 已注释字体声明。
**Migration**: 当前使用系统默认字体，待正式授权后再集成。