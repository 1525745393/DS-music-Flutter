import 'dart:async';
import 'package:upnp2/upnp2.dart';
import '../model/song.dart';
import '../utils/logger.dart';

/// DLNA 投屏（Renderer）
class DlnaController {
  UpnpDevice? selectedRenderer;
  StreamSubscription? _sub;
  final List<UpnpDevice> _devices = [];

  List<UpnpDevice> get devices => List.unmodifiable(_devices);

  /// 启动设备发现
  Future<void> startDiscovery() async {
    try {
      _sub?.cancel();
      _sub = UpnpDiscovery.devices().listen((device) {
        if (device.deviceType == 'urn:schemas-upnp-org:device:MediaRenderer:1') {
          if (!_devices.any((d) => d.uuid == device.uuid)) {
            _devices.add(device);
          }
        }
      }, onError: (e) => AppLogger.e('UPnP 错误', e));
    } catch (e) {
      AppLogger.e('DLNA 启动失败', e);
    }
  }

  /// 推送歌曲到指定 Renderer
  Future<void> push(Song song, String streamUrl) async {
    if (selectedRenderer == null) return;
    // 调用 SetAVTransportURI + Play
    // 实现位于 upnp2 内部 API
    try {
      await selectedRenderer!.setAVTransportURI(streamUrl, song.title);
      await selectedRenderer!.play();
    } catch (e) {
      AppLogger.e('DLNA 推送失败', e);
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}
