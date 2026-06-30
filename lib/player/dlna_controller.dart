import 'dart:async';
import '../model/song.dart';
import '../utils/logger.dart';

/// 媒体设备（统一抽象，对外屏蔽不同 upnp 包的 API 差异）
class DlnaDevice {
  final String uuid;
  final String friendlyName;
  final String deviceType; // 'MediaRenderer' | 'MediaServer'
  final String? baseUrl;

  const DlnaDevice({
    required this.uuid,
    required this.friendlyName,
    required this.deviceType,
    this.baseUrl,
  });
}

/// DLNA 媒体项（统一 browse 返回结构）
class DlnaMediaItem {
  final String id;
  final String title;
  final String type; // container / audio / video / image
  final int childrenCount;
  final String? resourceUrl;

  const DlnaMediaItem({
    required this.id,
    required this.title,
    required this.type,
    required this.childrenCount,
    this.resourceUrl,
  });

  bool get isContainer => type == 'container';
}

/// DLNA 投屏控制器（桩实现）
///
/// 设计说明：
/// 1. upnp2 3.0.x 包使用 DeviceDiscoverer + quickDiscoverClients API，
///    与历史代码使用的 UpnpDiscovery.devices() + UpnpDevice 不兼容。
/// 2. 当前 v1.1.0 优先级是发布稳定版，DLNA 功能标记为实验性。
/// 3. 保留所有公开方法（push/pushQueue/pause/resume/stop/seekTo/
///    setVolume/browse/playUrl/dispose/devices/servers/startDiscovery）
///    全部返回 no-op，UI 仍能正常显示设备和操作面板，
///    但实际投屏需等后续接入正确 upnp2 API。
/// 4. 后续 v1.2 将基于 DeviceDiscoverer 重写完整实现。
class DlnaController {
  DlnaDevice? selectedRenderer;
  DlnaDevice? selectedServer;
  final List<DlnaDevice> _devices = [];
  final List<DlnaDevice> _servers = [];

  List<DlnaDevice> get devices => List.unmodifiable(_devices);
  List<DlnaDevice> get servers => List.unmodifiable(_servers);

  Future<void> startDiscovery() async {
    // 桩：未来接入 DeviceDiscoverer.quickDiscoverClients()
    // 暂时填充一个示例设备方便 UI 调试
    if (_devices.isEmpty) {
      _devices.add(const DlnaDevice(
        uuid: 'sample-renderer',
        friendlyName: '客厅 DLNA 音箱（示例）',
        deviceType: 'MediaRenderer',
        baseUrl: 'http://192.168.1.100:49152',
      ));
    }
    AppLogger.i('DLNA 发现：当前为桩实现，1 个示例设备');
  }

  /// 推送单首歌曲
  Future<bool> push(Song song, String streamUrl) async {
    if (selectedRenderer == null) return false;
    AppLogger.i('DLNA push (桩): ${song.title} → ${selectedRenderer!.friendlyName}');
    return true;
  }

  /// 推送整个队列
  Future<bool> pushQueue(List<Song> songs, List<String> streamUrls) async {
    if (selectedRenderer == null) return false;
    if (songs.isEmpty || streamUrls.isEmpty) return false;
    return push(songs.first, streamUrls.first);
  }

  // ============ 远程控制（DMR） ============
  Future<bool> pause() async {
    if (selectedRenderer == null) return false;
    AppLogger.d('DLNA pause (桩)');
    return true;
  }

  Future<bool> resume() async {
    if (selectedRenderer == null) return false;
    AppLogger.d('DLNA resume (桩)');
    return true;
  }

  Future<bool> stop() async {
    if (selectedRenderer == null) return false;
    AppLogger.d('DLNA stop (桩)');
    return true;
  }

  Future<bool> seekTo(int seconds) async {
    if (selectedRenderer == null) return false;
    AppLogger.d('DLNA seek (桩): $seconds');
    return true;
  }

  Future<bool> setVolume(int vol) async {
    if (selectedRenderer == null) return false;
    AppLogger.d('DLNA setVolume (桩): $vol');
    return true;
  }

  // ============ MediaServer 浏览（CDS Browse） ============
  Future<List<DlnaMediaItem>> browse({String objectId = '0'}) async {
    return const [];
  }

  /// 直接投射播放 URL
  Future<bool> playUrl(String url, String title) async {
    if (selectedRenderer == null) return false;
    AppLogger.d('DLNA playUrl (桩): $title');
    return true;
  }

  void dispose() {
    // 桩：无订阅需要取消
  }
}
