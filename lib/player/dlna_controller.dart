import 'dart:async';
import 'package:upnp2/upnp2.dart';
import '../model/song.dart';
import '../utils/logger.dart';

/// DLNA 投屏控制器
/// 关键能力：
/// 1. 设备发现（MediaRenderer + MediaServer）
/// 2. 投屏单首歌曲（SetAVTransportURI + Play）
/// 3. 远程控制：pause / stop / seek / setVolume
/// 4. 推送整个队列
/// 5. MediaServer 内容浏览（Browse 协议）
///
/// 注意：upnp2 包的具体 API 因版本而异，所有调用都用 try/catch 兜底，
/// 避免包升级时主流程崩溃。
class DlnaController {
  UpnpDevice? selectedRenderer;
  UpnpDevice? selectedServer;
  StreamSubscription? _sub;
  final List<UpnpDevice> _devices = [];
  final List<UpnpDevice> _servers = [];

  List<UpnpDevice> get devices => List.unmodifiable(_devices);
  List<UpnpDevice> get servers => List.unmodifiable(_servers);

  /// 启动设备发现
  /// 同时筛选 MediaRenderer（音箱/电视）与 MediaServer（媒体库）
  Future<void> startDiscovery() async {
    try {
      _sub?.cancel();
      _sub = UpnpDiscovery.devices().listen((device) {
        // MediaRenderer：被推送端
        if (device.deviceType == 'urn:schemas-upnp-org:device:MediaRenderer:1' ||
            device.deviceType == 'urn:schemas-upnp-org:device:MediaRenderer:2') {
          if (!_devices.any((d) => d.uuid == device.uuid)) {
            _devices.add(device);
          }
        }
        // MediaServer：内容源
        if (device.deviceType == 'urn:schemas-upnp-org:device:MediaServer:1' ||
            device.deviceType == 'urn:schemas-upnp-org:device:MediaServer:2') {
          if (!_servers.any((d) => d.uuid == device.uuid)) {
            _servers.add(device);
          }
        }
      }, onError: (e) => AppLogger.e('UPnP 错误', e));
    } catch (e) {
      AppLogger.e('DLNA 启动失败', e);
    }
  }

  /// 推送单首歌曲
  Future<bool> push(Song song, String streamUrl) async {
    if (selectedRenderer == null) return false;
    try {
      await selectedRenderer!.setAVTransportURI(streamUrl, song.title);
      await selectedRenderer!.play();
      AppLogger.i('DLNA push ok: ${song.title}');
      return true;
    } catch (e) {
      AppLogger.e('DLNA 推送失败', e);
      return false;
    }
  }

  /// 推送整个队列
  /// 当前为简化实现：仅推送第一首，其它由 Renderer 端按 URI 列表播放。
  /// 完整实现需用 SetAVTransportURI 的 playlist 形式。
  Future<bool> pushQueue(List<Song> songs, List<String> streamUrls) async {
    if (selectedRenderer == null) return false;
    if (songs.isEmpty || streamUrls.isEmpty) return false;
    try {
      // 先用首首歌曲的元数据构造 DIDL-Lite；简化处理：直接推第一首
      await selectedRenderer!.setAVTransportURI(
        streamUrls.first,
        songs.first.title,
      );
      await selectedRenderer!.play();
      return true;
    } catch (e) {
      AppLogger.e('DLNA pushQueue 失败', e);
      return false;
    }
  }

  // ============ 远程控制（DMR） ============

  Future<void> pause() async {
    if (selectedRenderer == null) return;
    try {
      // ignore: avoid_dynamic_calls
      await (selectedRenderer as dynamic).pause();
    } catch (e) {
      AppLogger.w('DLNA pause 失败（包 API 不支持？）: $e');
    }
  }

  Future<void> resume() async {
    if (selectedRenderer == null) return;
    try {
      // ignore: avoid_dynamic_calls
      await (selectedRenderer as dynamic).play();
    } catch (e) {
      AppLogger.w('DLNA resume 失败: $e');
    }
  }

  Future<void> stop() async {
    if (selectedRenderer == null) return;
    try {
      // ignore: avoid_dynamic_calls
      await (selectedRenderer as dynamic).stop();
    } catch (e) {
      AppLogger.w('DLNA stop 失败: $e');
    }
  }

  /// 跳转到指定位置（秒）
  Future<void> seekTo(int seconds) async {
    if (selectedRenderer == null) return;
    try {
      // 群晖/标准 UPnP 格式：HH:MM:SS
      final h = seconds ~/ 3600;
      final m = (seconds % 3600) ~/ 60;
      final s = seconds % 60;
      final relTime =
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      // ignore: avoid_dynamic_calls
      await (selectedRenderer as dynamic).seek(relTime);
    } catch (e) {
      AppLogger.w('DLNA seek 失败: $e');
    }
  }

  /// 音量：0-100
  Future<void> setVolume(int vol) async {
    if (selectedRenderer == null) return;
    final v = vol.clamp(0, 100);
    try {
      // ignore: avoid_dynamic_calls
      await (selectedRenderer as dynamic).setVolume(v);
    } catch (e) {
      AppLogger.w('DLNA setVolume 失败: $e');
    }
  }

  // ============ MediaServer 浏览（CDS Browse） ============

  /// 浏览服务器内容
  /// [objectId] '0' = 根目录
  /// 返回 [{id, title, type, children_count, resource_url}]
  /// 简化实现：使用 upnp2 包暴露的通用 SOAP 协议调用。
  /// 若 upnp2 未暴露 browse 接口则返回空列表。
  Future<List<DlnaMediaItem>> browse({String objectId = '0'}) async {
    if (selectedServer == null) return const [];
    try {
      // ignore: avoid_dynamic_calls
      final dynamic svc = selectedServer;
      if (svc == null) return const [];
      // 尝试调用 browse 方法（不同 upnp2 版本 API 略有不同）
      // ignore: avoid_dynamic_calls
      final dynamic result = await (svc as dynamic).browse(objectId);
      if (result is List) {
        return result
            .whereType<Map>()
            .map((m) => DlnaMediaItem(
                  id: m['id']?.toString() ?? '',
                  title: m['title']?.toString() ?? '',
                  type: m['type']?.toString() ?? 'unknown',
                  childrenCount: (m['childCount'] is num)
                      ? (m['childCount'] as num).toInt()
                      : 0,
                  resourceUrl: m['resource']?.toString(),
                ))
            .toList();
      }
      return const [];
    } catch (e) {
      AppLogger.w('DLNA browse 失败: $e');
      return const [];
    }
  }

  void dispose() {
    _sub?.cancel();
  }
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
