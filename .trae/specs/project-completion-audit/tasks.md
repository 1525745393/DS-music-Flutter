# Tasks - DS Player 全量需求自查

本次为纯分析任务，不涉及代码实现。以下为后续待验证/补齐的工作项清单。

---

## P0：必须验证/补齐（核心功能待确认）

- [ ] Task 1: 验证 Gapless 无缝播放实现
  - [ ] SubTask 1.1: 审计 `lib/player/audio_handler.dart`，确认是否使用 `ConcatenatingAudioSource`
  - [ ] SubTask 1.2: 确认歌曲切换是否无缝（无间隙）
  - [ ] SubTask 1.3: 确认 `gaplessEnabled` 设置项是否生效

- [ ] Task 2: 验证本地优先播放逻辑
  - [ ] SubTask 2.1: 审计 `lib/player/audio_handler.dart`，确认是否集成 `downloadApi`
  - [ ] SubTask 2.2: 确认播放源选择逻辑（本地文件存在时优先使用本地）
  - [ ] SubTask 2.3: 确认本地文件路径获取方式

- [ ] Task 3: 验证 WiFi/蜂窝智能切换
  - [ ] SubTask 3.1: 审计 `lib/player/network_type_watcher.dart`，确认 WiFi/蜂窝判断
  - [ ] SubTask 3.2: 确认转码策略触发（WiFi 原始码流，蜂窝转码 320k MP3）
  - [ ] SubTask 3.3: 确认 `forceTranscodeOnMobile` 设置项是否生效

- [ ] Task 4: 添加弹性阻尼滚动
  - [ ] SubTask 4.1: 创建全局 `ScrollBehavior` 使用 `BouncingScrollPhysics`
  - [ ] SubTask 4.2: 应用到所有 `ListView`/`GridView`/`CustomScrollView`
  - [ ] SubTask 4.3: 验证 iOS 风格滚动效果

---

## P1：应尽快补齐（功能不完整）

- [ ] Task 5: 验证 DLNA 设备发现与控制
  - [ ] SubTask 5.1: 审计 `lib/player/dlna_controller.dart`，确认 `upnp2` 设备发现逻辑
  - [ ] SubTask 5.2: 确认 `DlnaDevicesPage` 是否展示发现结果
  - [ ] SubTask 5.3: 确认投屏控制指令（播放/暂停/音量）是否实现

- [ ] Task 6: 验证悬浮歌词原生实现
  - [ ] SubTask 6.1: 审计 `android/app/src/main/kotlin/.../OverlayLyricsService.kt`
  - [ ] SubTask 6.2: 确认是否使用 `WindowManager` 绘制悬浮窗口
  - [ ] SubTask 6.3: 确认与 Flutter 侧的通信通道（MethodChannel）

- [ ] Task 7: 添加点击透明度反馈
  - [ ] SubTask 7.1: 创建通用 `GestureDetector` 包装组件，支持点击透明度变化
  - [ ] SubTask 7.2: 应用到所有交互组件（按钮、列表项、卡片）
  - [ ] SubTask 7.3: 验证 iOS 风格点击反馈效果

---

## P2：可延后优化（README 标记为「后续可扩展」）

- [ ] Task 8: 完善 Android Auto 适配
  - [ ] SubTask 8.1: 验证 `AABrowseService.kt` 媒体浏览树实现
  - [ ] SubTask 8.2: 验证 `android_auto_browse_tree.dart` 与 Flutter 侧数据同步

- [ ] Task 9: 歌词在线补全功能
  - [ ] SubTask 9.1: 新建 `lib/api/lyrics_api.dart`（公网歌词 API 集成）
  - [ ] SubTask 9.2: 在播放器页添加「搜索歌词」入口

- [ ] Task 10: 智能推荐页
  - [ ] SubTask 10.1: 新建 `lib/pages/discovery/discovery_page.dart`

- [ ] Task 11: 多账号管理
  - [ ] SubTask 11.1: 新建 `lib/pages/accounts/accounts_page.dart`

- [ ] Task 12: SF Pro 字体集成
  - [ ] SubTask 12.1: 获取正式字体授权后，添加字体文件到 `assets/fonts/`
  - [ ] SubTask 12.2: 恢复 `pubspec.yaml` 字体声明

---

# Task Dependencies

- Task 1-4 可并行执行（各模块独立）
- Task 5-7 可并行执行（各模块独立）
- Task 8-12 无依赖，可延后处理