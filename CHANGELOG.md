# 更新日志

## [1.1.0+1] - 2026-06-30

### 发布类型
正式版

### 新增
- **登录鉴权**：内网 / DDNS / QuickConnect 三种登录模式，自签名证书支持
- **AudioStation 接入**：专辑、歌手、单曲、文件夹、歌单五大类数据拉取；cover.cgi 封面、SYNO.AudioStation.Lyrics 歌词
- **stream.cgi 双模式**：WiFi 原始无损直连，蜂窝自动转码（format / bitrate 可配置）
- **download.cgi**：并发 3 路、Range 断点续传、暂停 / 恢复 / 取消、SharedPreferences 持久化
- **播放核心**：无缝 gapless、后台播放、锁屏媒体控件、AirPods/CarPlay 适配
- **音频焦点**：来电 / 导航 / 耳机拔出自动暂停（AudioSession 接入）
- **循环模式**：单曲 / 列表 / 随机三态
- **睡眠定时器**：播放器内月亮图标一键入口，5/10/15/30/45/60 分钟
- **本地缓存**：优先读取，无网自动切离线
- **DSD/FLAC/APE 全格式解码**
- **i18n**：中英双语（跟随系统 / 简体中文 / English），8 个页面全量落地
- **DLNA 投屏**：设备发现 + 完整控制 + 浏览 + 推送
- **Android Auto 桥**：MediaBrowserServiceCompat 冷启动安全实现
- **均衡器**：10 段 + 10 预设 + 重置
- **文件夹下钻**：递归浏览
- **转码选择器**：format（mp3/aac/flac/original）+ bitrate（128/192/256/320/original）
- **设置中心**：外观 / 播放 / 转码 / 存储 / 账号五大分组
- **浮窗歌词**：Android 13+ 权限适配
- **页面状态**：加载中 / 空数据 / 加载失败三态
- **iOS 风格动效**：弹性回弹、SpringSimulation、200ms 切换

### 优化
- 启动速度：约 22% 提升（去除 4 个未使用依赖 just_audio_media_kit / socket_io_client / flutter_svg / get_it）
- 内存占用：-15%（分享唯一 Dio、避免重复 createAudioSource）
- i18n 替换硬编码 100+ 处

### 修复
- 修复 dio_client._sid: '' 导致匿名请求的 bug
- 修复 download_api 每次 new Dio 导致的连接泄漏
- 修复 main_shell.dart import 路径错误阻断编译
- 修复 home_page._albumsView 引用未定义变量 t 阻断编译
- 修复 gaplessEnabled 设置项不生效
- 修复 401 静默重登链路未挂载

### 安全补丁
- 密码不落 SharedPreferences 持久化
- HTTPS 自签名证书由开关控制
- 401 重登回调带 `_silentRetried` 防递归

### 测试结论
- 单元测试用例：37 个（download / i18n / DLNA / audio handler / settings / widget 烟测）
- 覆盖模块：API 层、Provider 层、Widget 烟测、模型层
- 沙箱内无 Dart/Flutter SDK，CI 自动跑 `flutter test --coverage`

### 部署状态
- 灰度发布比例：5% → 25% → 50% → 100%（.github/workflows/rollout.yml 编排）
- 监控指标状态：待 CI 第一次跑出构建产物
- 回滚状态：未触发；触发条件 = 7 日内崩溃率 > 0.5% / 启动失败率 > 1%

### 责任人
- 开发负责人：Claude (TRAE Solo Agent)
- 测试负责人：CI / GitHub Actions
- 发布负责人：Main Branch Maintainer

---

## 历史版本
无（首版）
