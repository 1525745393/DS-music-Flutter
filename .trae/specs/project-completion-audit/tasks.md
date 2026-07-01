# Tasks - DS Player 项目完成度自查

本次为纯分析任务，不涉及代码实现。以下为后续待验证/补齐的工作项清单。

---

## P0：必须优先补齐（影响基本使用）

- [x] Task 1: 验证首页数据加载逻辑
  - [x] SubTask 1.1: 审计 `lib/pages/home/home_page.dart`，确认是否从 `libraryRepositoryProvider` 加载数据
  - [x] SubTask 1.2: 确认数据是否绑定到 UI 组件（专辑列表、艺术家列表、最近播放）
  - [x] SubTask 1.3: 如缺失，补齐数据加载与绑定逻辑
  - **结论：已完整实现**。使用 albumsProvider/artistsProvider/songsProvider/foldersProvider/playlistsProvider，通过 ref.watch 监听，包含 loading/error/empty 占位状态。

- [x] Task 2: 验证 MiniPlayerBar 状态订阅
  - [x] SubTask 2.1: 审计 `lib/components/player_bar/mini_player_bar.dart`，确认是否订阅 `playerProvider`
  - [x] SubTask 2.2: 确认歌曲标题、艺术家、进度条是否动态更新
  - [x] SubTask 2.3: 确认点击事件是否导航到 `PlayerPage`
  - **结论：已完整实现**。订阅 playerStateProvider，显示标题/艺术家，包含播放/暂停/下一首按钮，点击歌曲信息区域触发 onTap 回调（由父组件处理导航）。

- [x] Task 3: 验证 CoverImage 封面 URL 生成
  - [x] SubTask 3.1: 审计 `lib/components/cards/cover_image.dart`，确认封面 URL 生成逻辑
  - [x] SubTask 3.2: 确认是否使用 AudioStation 封面 API（`/webapi/entry.cgi?api=SYNO.AudioStation.Cover`）
  - [x] SubTask 3.3: 确认 `cached_network_image` 占位图、错误图配置
  - **结论：已完整实现**。CoverImage 接受外部 url 参数，library_repository.dart 有 coverUrl 方法，audio_station_api.dart 有 buildCoverUrl/buildThumbUrl 方法，配置了 placeholder/errorWidget。

- [x] Task 4: 验证 SongListTile 点击播放
  - [x] SubTask 4.1: 审计 `lib/components/lists/song_list_tile.dart`，确认点击事件处理
  - [x] SubTask 4.2: 确认是否调用 `audioHandler.setQueueAndPlay()` 或类似播放方法
  - [x] SubTask 4.3: 确认播放队列更新逻辑
  - **结论：已实现**。组件有 onTap/onMore 回调参数，显示标题/艺术家/专辑/封面。播放逻辑由父组件通过 onTap 回调处理（组件本身不调用 audioHandler，这是合理的设计）。

- [x] Task 5: 验证播放模式切换
  - [x] SubTask 5.1: 审计 `lib/player/audio_handler.dart`，确认循环/随机模式实现
  - [x] SubTask 5.2: 确认 UI 控件（循环按钮）是否连接播放模式状态
  - [x] SubTask 5.3: 确认 `setLoopMode()` / `setShuffleMode()` 方法存在
  - **结论：已完整实现**。audio_handler.dart 有 setShuffleMode/setRepeatMode 方法，使用 ConcatenatingAudioSource 实现 gapless 播放，播放队列管理逻辑完整，状态通过 playerStateProvider 暴露。

---

## P1：应尽快补齐（重要体验）

- [ ] Task 6: 验证 DLNA 设备发现与控制
  - [ ] SubTask 6.1: 审计 `lib/player/dlna_controller.dart`，确认 `upnp2` 设备发现逻辑
  - [ ] SubTask 6.2: 确认 `DlnaDevicesPage` 是否展示发现结果
  - [ ] SubTask 6.3: 确认投屏控制指令（播放/暂停/音量）是否实现

- [ ] Task 7: 验证悬浮歌词原生实现
  - [ ] SubTask 7.1: 审计 `android/app/src/main/kotlin/com/dsplayer/music/OverlayLyricsService.kt`
  - [ ] SubTask 7.2: 确认是否使用 `WindowManager` 绘制悬浮窗口
  - [ ] SubTask 7.3: 确认与 Flutter 侧的通信通道（MethodChannel）

- [ ] Task 8: 验证网络类型切换逻辑
  - [ ] SubTask 8.1: 审计 `lib/player/network_type_watcher.dart`，确认 WiFi/蜂窝判断
  - [ ] SubTask 8.2: 确认是否触发转码切换（WiFi 原始码流，蜂窝转码）
  - [ ] SubTask 8.3: 确认 `connectivity_plus` 集成

- [ ] Task 9: 验证 Gapless 播放实现
  - [ ] SubTask 9.1: 审计 `lib/player/audio_handler.dart`，确认 `ConcatenatingAudioSource` 使用
  - [ ] SubTask 9.2: 确认歌曲切换是否无缝

- [ ] Task 10: 验证歌词同步滚动
  - [ ] SubTask 10.1: 审计 `lib/components/lyrics/lyrics_view.dart`，确认播放进度监听
  - [ ] SubTask 10.2: 确认歌词行是否随播放位置滚动高亮

---

## P2：可延后优化（增强体验）

- [ ] Task 11: 完善 Android Auto 适配
  - [ ] SubTask 11.1: 验证 `AABrowseService.kt` 媒体浏览树实现
  - [ ] SubTask 11.2: 验证 `android_auto_browse_tree.dart` 与 Flutter 侧数据同步

- [ ] Task 12: 歌词在线补全功能
  - [ ] SubTask 12.1: 新建 `lib/api/lyrics_api.dart`（公网歌词 API 集成）
  - [ ] SubTask 12.2: 在播放器页添加「搜索歌词」入口

- [ ] Task 13: 智能推荐页
  - [ ] SubTask 13.1: 新建 `lib/pages/discovery/discovery_page.dart`

- [ ] Task 14: 多账号管理
  - [ ] SubTask 14.1: 新建 `lib/pages/accounts/accounts_page.dart`

- [ ] Task 15: SF Pro 字体集成
  - [ ] SubTask 15.1: 获取正式字体授权后，添加字体文件到 `assets/fonts/`
  - [ ] SubTask 15.2: 恢复 `pubspec.yaml` 字体声明

---

# Task Dependencies

- Task 2 依赖 Task 1（首页数据加载验证）
- Task 4 依赖 Task 3（封面 URL 生成验证）
- Task 6-10 可并行执行（各模块独立）
- Task 11-15 无依赖，可延后处理