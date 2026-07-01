# Tasks - DS Player 全量需求自查

---

## P0：必须补齐（核心功能缺失，违反需求规范）

- [ ] Task 1: 添加 flutter_marquee 依赖
  - [ ] SubTask 1.1: 在 `pubspec.yaml` 添加 `flutter_marquee: ^0.2.2`
  - [ ] SubTask 1.2: 运行 `flutter pub get` 验证

- [ ] Task 2: 实现音量标准化
  - [ ] SubTask 2.1: 在 `lib/player/audio_handler.dart` 新增 `normalizeVolume` 逻辑
  - [ ] SubTask 2.2: 在设置页添加音量标准化开关
  - [ ] SubTask 2.3: 与 `settingsProvider.normalizeVolume` 配置联动

- [ ] Task 3: 实现播放速度调节 0.5x-2x
  - [ ] SubTask 3.1: 在 `lib/player/audio_handler.dart` 新增 `setSpeed(double rate)` 方法
  - [ ] SubTask 3.2: 在播放页添加速度选择 UI（0.5x/0.75x/1.0x/1.25x/1.5x/2.0x）
  - [ ] SubTask 3.3: 速度状态持久化到 settingsProvider

- [ ] Task 4: 实现提前缓冲下一首歌曲
  - [ ] SubTask 4.1: 在 `lib/player/audio_handler.dart` 新增预缓冲逻辑
  - [ ] SubTask 4.2: 当前歌曲播放到70%时开始缓冲下一首前30秒
  - [ ] SubTask 4.3: 智能调节缓冲阈值（根据网络状态）

- [ ] Task 5: 实现全局 iOS 弹性阻尼滚动
  - [ ] SubTask 5.1: 创建 `lib/theme/app_scroll_behavior.dart` 使用 `BouncingScrollPhysics`
  - [ ] SubTask 5.2: 在 `CupertinoApp` 的 `scrollBehavior` 中注入
  - [ ] SubTask 5.3: 验证所有列表页面的滚动效果

- [ ] Task 6: 实现点击透明度70%反馈
  - [ ] SubTask 6.1: 创建通用 `DSInkWell` 组件，支持透明度变化 100%→70%→100%（100ms）
  - [ ] SubTask 6.2: 替换所有交互组件的 GestureDetector 为 DSInkWell
  - [ ] SubTask 6.3: 验证按钮、列表项、卡片的点击效果

---

## P1：应尽快补齐（功能不完整，影响体验对齐）

- [ ] Task 7: 验证并完善 Gapless 无缝播放
  - [ ] SubTask 7.1: 验证 `audio_handler.dart` 中 ConcatenatingAudioSource 使用
  - [ ] SubTask 7.2: 如未实现，新增 gapless 播放逻辑
  - [ ] SubTask 7.3: 验证 `gaplessEnabled` 设置项是否生效

- [ ] Task 8: 验证并完善本地优先播放
  - [ ] SubTask 8.1: 验证 `audio_handler.dart` 是否集成 downloadApi
  - [ ] SubTask 8.2: 如未实现，新增播放源选择逻辑（本地文件存在时优先）
  - [ ] SubTask 8.3: 验证本地文件路径获取方式

- [ ] Task 9: 验证并完善 WiFi/蜂窝智能切换
  - [ ] SubTask 9.1: 验证 `network_type_watcher.dart` WiFi/蜂窝判断
  - [ ] SubTask 9.2: 验证转码策略触发（WiFi 原始码流，蜂窝转码 320k MP3）
  - [ ] SubTask 9.3: 验证 `forceTranscodeOnMobile` 设置项是否生效

- [ ] Task 10: 实现播放页转场动效
  - [ ] SubTask 10.1: 创建自定义 `DSPlayerPageRoute`：底部滑入+缩放淡入350ms弹性曲线
  - [ ] SubTask 10.2: 实现拖拽关闭跟随手势
  - [ ] SubTask 10.3: 应用到迷你播放栏→播放页的导航

- [ ] Task 11: 实现左右滑动切歌
  - [ ] SubTask 11.1: 播放页 GestureDetector 水平滑动检测
  - [ ] SubTask 11.2: 封面跟随手势水平位移，松手切歌
  - [ ] SubTask 11.3: 迷你播放栏左右滑动切歌

- [ ] Task 12: 实现切歌淡入淡出 300ms
  - [ ] SubTask 12.1: 播放页封面切换时 AnimatedSwitcher 淡入淡出
  - [ ] SubTask 12.2: 歌曲信息同步更新

- [ ] Task 13: 完善悬浮歌词
  - [ ] SubTask 13.1: 验证 `OverlayLyricsService.kt` 原生服务实现
  - [ ] SubTask 13.2: 实现可拖动位置、可调节大小
  - [ ] SubTask 13.3: Flutter 侧 MethodChannel 通信

- [ ] Task 14: 实现锁屏歌词显示
  - [ ] SubTask 14.1: 配置 mediaItem 的 lyrics 字段
  - [ ] SubTask 14.2: Android 通知栏歌词显示

- [ ] Task 15: 验证 DLNA 投屏功能
  - [ ] SubTask 15.1: 验证 `dlna_controller.dart` 设备发现逻辑
  - [ ] SubTask 15.2: 验证投屏控制指令（播放/暂停/音量）
  - [ ] SubTask 15.3: 验证 `upnp2 ^3.0.0` API 兼容性

- [ ] Task 16: 验证 UI 布局像素级规范
  - [ ] SubTask 16.1: 登录页布局（标题距顶48px/表单48px高/按钮100%宽48px高）
  - [ ] SubTask 16.2: 首页专辑墙（44px导航栏/40pxTab/2列网格/64px底部空白）
  - [ ] SubTask 16.3: 播放详情页（封面居中距顶80px/进度条3px/控制区三等分）
  - [ ] SubTask 16.4: 迷你播放栏（56px高/毛玻璃/左封面中歌名右控制）
  - [ ] SubTask 16.5: 设置页（iOS分组列表/项高48px）

- [ ] Task 17: 添加缓存路径自定义
  - [ ] SubTask 17.1: 设置页新增缓存路径选项
  - [ ] SubTask 17.2: download_api 读取自定义路径
  - [ ] SubTask 17.3: 路径变更时迁移已有缓存

- [ ] Task 18: 验证播放记录回传
  - [ ] SubTask 18.1: 检查 `audio_station_api.dart` 是否有 playlog 接口
  - [ ] SubTask 18.2: 如缺失，新增播放记录回传逻辑

---

## P2：可延后（README 标记「后续可扩展」）

- [ ] Task 19: 完善 Android Auto 适配
- [ ] Task 20: 歌词在线补全（需新建 `lib/api/lyrics_api.dart`）
- [ ] Task 21: 智能推荐页（需新建 `lib/pages/discovery/`）
- [ ] Task 22: 多账号管理（需新建 `lib/pages/accounts/`）
- [ ] Task 23: 蓝牙音频无损输出
- [ ] Task 24: SF Pro 字体集成（待授权）

---

# Task Dependencies

- Task 1（flutter_marquee）为 Task 13（悬浮歌词）的前置
- Task 5（弹性滚动）和 Task 6（点击反馈）独立，可并行
- Task 7-9 为验证任务，可并行
- Task 10-12 为播放页动效，建议顺序执行
- Task 16（UI 布局验证）可与其他任务并行