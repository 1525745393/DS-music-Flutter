# Checklist - DS Player 全量需求自查

## NAS 连接与认证

- [x] 三种登录模式：内网直连（IP+端口）、DDNS 域名、QuickConnect 中继
  - **验证结果**：[login_page.dart](file:///workspace/lib/pages/login/login_page.dart) 已实现
- [x] 动态接口发现：SYNO.API.Info 拉取所有接口路径与最大版本
  - **验证结果**：[api_info.dart](file:///workspace/lib/api/api_info.dart) 已实现
- [x] 自签证书兼容：HTTPS NAS 自动信任
  - **验证结果**：[dio_client.dart](file:///workspace/lib/api/dio_client.dart) badCertificateCallback 已实现
- [x] SID 持久化 + 静默重登：过期自动续期
  - **验证结果**：[auth_repository.dart](file:///workspace/lib/repository/auth_repository.dart) 已实现

## 播放核心

- [ ] 无缝 gapless：ConcatenatingAudioSource 拼接
  - **验证结果**：待验证，需检查 [audio_handler.dart](file:///workspace/lib/player/audio_handler.dart)
- [ ] WiFi/蜂窝智能切换：WiFi 原始码流，蜂窝转码 320k MP3
  - **验证结果**：待验证，[network_type_watcher.dart](file:///workspace/lib/player/network_type_watcher.dart) 存在
- [ ] 本地优先播放：已下载歌曲直接播放本地
  - **验证结果**：待验证，需检查 downloadApi 集成
- [x] 后台播放 + 锁屏控件：audio_service + just_audio_background
  - **验证结果**：[main.dart](file:///workspace/lib/main.dart#L47-L57) 已实现
- [x] DSD/FLAC/APE 全格式软解
  - **验证结果**：just_audio 默认软解支持

## UI/主题（iOS 扁平化）

- [x] 严格遵循 iOS 设计语言，禁止 Material Design
  - **验证结果**：[main.dart](file:///workspace/lib/main.dart#L219-L226) 使用 CupertinoApp
- [x] 主背景 #121212
  - **验证结果**：[app_colors.dart](file:///workspace/lib/theme/app_colors.dart#L9) 已定义
- [x] 强调色 #007AFF
  - **验证结果**：[app_colors.dart](file:///workspace/lib/theme/app_colors.dart#L21) 已定义
- [x] 沉浸式状态栏
  - **验证结果**：[main.dart](file:///workspace/lib/main.dart#L36-L40) 透明状态栏
- [x] 毛玻璃 10%
  - **验证结果**：[app_colors.dart](file:///workspace/lib/theme/app_colors.dart#L42) glassDark 已定义
- [x] 圆角 16/10/4
  - **验证结果**：[app_dimens.dart](file:///workspace/lib/theme/app_dimens.dart) 已定义
- [ ] 弹性阻尼滚动
  - **验证结果**：待验证，需检查 BouncingScrollPhysics
- [ ] 点击透明度反馈
  - **验证结果**：待验证，需检查组件点击状态

## 音乐库浏览

- [x] 专辑列表浏览（封面、标题、艺术家）
  - **验证结果**：[album_detail_page.dart](file:///workspace/lib/pages/album/album_detail_page.dart) 已实现
- [x] 艺术家列表浏览
  - **验证结果**：[artist_detail_page.dart](file:///workspace/lib/pages/artist/artist_detail_page.dart) 已实现
- [x] 歌曲列表浏览
  - **验证结果**：[home_page.dart](file:///workspace/lib/pages/home/home_page.dart#L258-L295) songsProvider 已实现
- [x] 播放列表管理（创建、编辑、删除）
  - **验证结果**：[playlist_editor_page.dart](file:///workspace/lib/pages/playlist/playlist_editor_page.dart) 已实现
- [x] 文件夹浏览（按目录结构）
  - **验证结果**：[folder_browse_page.dart](file:///workspace/lib/pages/folder/folder_browse_page.dart) 已实现
- [x] 搜索功能
  - **验证结果**：[search_page.dart](file:///workspace/lib/pages/search/search_page.dart) 已实现

## 播放器页面与歌词

- [x] 全屏播放器页面（封面、进度、控制按钮）
  - **验证结果**：[player_page.dart](file:///workspace/lib/pages/player/player_page.dart) 已实现
- [x] Mini 播放器条（底部固定）
  - **验证结果**：[mini_player_bar.dart](file:///workspace/lib/components/player_bar/mini_player_bar.dart) 已实现
- [x] 歌词显示与同步滚动
  - **验证结果**：[lyrics_view.dart](file:///workspace/lib/components/lyrics/lyrics_view.dart) 已实现
- [x] 播放队列管理
  - **验证结果**：[queue_page.dart](file:///workspace/lib/pages/queue/queue_page.dart) 已实现
- [x] 歌词解析（LRC 格式）
  - **验证结果**：[lyrics.dart](file:///workspace/lib/model/lyrics.dart) 已实现

## 下载与缓存

- [x] 文件下载（歌曲下载到本地）
  - **验证结果**：[download_api.dart](file:///workspace/lib/api/download_api.dart) DownloadTask 已实现
- [x] 下载管理（进度、暂停、取消）
  - **验证结果**：[download_manager_page.dart](file:///workspace/lib/pages/download/download_manager_page.dart) 已实现
- [x] 本地缓存管理（清理、统计）
  - **验证结果**：[cache_manage_page.dart](file:///workspace/lib/pages/cache/cache_manage_page.dart) 已实现
- [ ] 本地优先播放
  - **验证结果**：待验证，需检查播放源选择逻辑

## Android 权限

- [x] INTERNET（API 请求）
- [x] FOREGROUND_SERVICE（后台播放）
- [x] POST_NOTIFICATIONS（锁屏通知，Android 13+）
- [x] READ_MEDIA_AUDIO（读取本地音乐，Android 13+）
- [x] WAKE_LOCK（息屏播放）
- [x] REQUEST_IGNORE_BATTERY_OPTIMIZATIONS（防止系统查杀）
- [x] SYSTEM_ALERT_WINDOW（悬浮歌词）
- [x] CHANGE_WIFI_MULTICAST_STATE（DLNA 发现）

## 特殊功能

- [ ] DLNA 投屏（设备发现、播放控制）
  - **验证结果**：文件存在，功能待验证
- [ ] 悬浮歌词（Android 原生服务）
  - **验证结果**：文件存在，原生服务待验证
- [ ] Android Auto 适配
  - **验证结果**：README 标记为「后续可扩展」
- [x] 睡眠定时器
  - **验证结果**：[sleep_timer.dart](file:///workspace/lib/player/sleep_timer.dart) 已实现
- [x] 均衡器（纯状态维护）
  - **验证结果**：[equalizer_page.dart](file:///workspace/lib/pages/equalizer/equalizer_page.dart) 已实现