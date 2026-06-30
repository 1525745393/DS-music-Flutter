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
/// 兼容策略：upnp2 1.0.0 的 Renderer API 不直接暴露 pause/seek/setVolume/browse，
/// 所有非明确 API 都通过 [UpnpCommand] shim 调用，
/// 传入一组候选方法名自动匹配，避免主流程崩溃。
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
        if (device.deviceType ==
                'urn:schemas-upnp-org:device:MediaRenderer:1' ||
            device.deviceType ==
                'urn:schemas-upnp-org:device:MediaRenderer:2') {
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

  /// 推送整个队列（当前简化：仅推送首首）
  Future<bool> pushQueue(List<Song> songs, List<String> streamUrls) async {
    if (selectedRenderer == null) return false;
    if (songs.isEmpty || streamUrls.isEmpty) return false;
    try {
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

  /// 暂停：尝试 pause / PauseTransport / doPause
  Future<bool> pause() async => UpnpCommand(
        'pause',
        target: selectedRenderer,
        candidates: const [
          'pause',
          'PauseTransport',
          'doPause',
          'pausePlayback'
        ],
      ).invoke();

  /// 恢复播放
  Future<bool> resume() async => UpnpCommand(
        'play',
        target: selectedRenderer,
        candidates: const [
          'play',
          'PlayTransport',
          'doPlay',
          'resume',
          'resumePlayback'
        ],
      ).invoke();

  /// 停止
  Future<bool> stop() async => UpnpCommand(
        'stop',
        target: selectedRenderer,
        candidates: const ['stop', 'StopTransport', 'doStop'],
      ).invoke();

  /// 跳转到指定位置（秒）
  /// UPnP 标准格式：HH:MM:SS
  Future<bool> seekTo(int seconds) async {
    if (selectedRenderer == null) return false;
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final relTime =
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return UpnpCommand(
      'seek',
      target: selectedRenderer,
      candidates: const ['seek', 'SeekTransport', 'doSeek'],
      positionalArgs: [relTime],
    ).invoke();
  }

  /// 音量：0-100
  /// 不同 Renderer 的 setVolume 签名不同：有接受 (int) 的，也有接受 (0..1) 的
  Future<bool> setVolume(int vol) async {
    if (selectedRenderer == null) return false;
    final v = vol.clamp(0, 100);
    // 优先尝试 0-100 整数（DLNA 标准）
    if (await UpnpCommand(
      'setVolume',
      target: selectedRenderer,
      candidates: const ['setVolume', 'SetVolume'],
      positionalArgs: [v],
    ).invoke()) {
      return true;
    }
    // 降级：尝试 0..1 浮点
    try {
      return await UpnpCommand(
        'setVolume',
        target: selectedRenderer,
        candidates: const ['setVolume', 'SetVolume'],
        positionalArgs: [v / 100.0],
      ).invoke();
    } catch (_) {
      return false;
    }
  }

  // ============ MediaServer 浏览（CDS Browse） ============

  /// 浏览服务器内容
  /// [objectId] '0' = 根目录
  /// 关键：upnp2 没有标准 browse API，通过 shim 尝试多个候选方法
  /// 若 upnp2 包未实现 browse，将返回空列表（UI 提示"不支持"）
  Future<List<DlnaMediaItem>> browse({String objectId = '0'}) async {
    if (selectedServer == null) return const [];
    // 尝试位置参数
    return UpnpCommand(
          'browse',
          target: selectedServer,
          candidates: const [
            'browse',
            'Browse',
            'browseServer',
            'listChildren'
          ],
          positionalArgs: [objectId],
        ).invokeList() ??
        const [];
  }

  /// 直接从已选 Renderer 投射播放 URL（dlna_browse_page 内部用）
  Future<bool> playUrl(String url, String title) async {
    if (selectedRenderer == null) return false;
    try {
      await selectedRenderer!.setAVTransportURI(url, title);
      await selectedRenderer!.play();
      return true;
    } catch (e) {
      AppLogger.w('DLNA playUrl 失败: $e');
      return false;
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}

/// UPnP 命令 shim
/// 关键作用：upnp2 不同版本的 API 签名不一致（pause vs PauseTransport vs doPause），
/// 此 shim 自动尝试多个候选方法名，找到第一个成功调用的。
///
/// 实现说明：
/// - 不使用 dart:mirrors（release/AOT 不支持）
/// - 改用 try/catch NoSuchMethodError + 重新 dynamic 调用
/// - 失败时返回 null/false 不抛异常，调用方按降级路径处理
class UpnpCommand {
  final String opName; // 用于日志
  final Object? target;
  final List<String> candidates;
  final List<dynamic> positionalArgs;

  UpnpCommand(
    this.opName, {
    required this.target,
    required this.candidates,
    this.positionalArgs = const [],
  });

  /// 通用调用：返回 true 表示成功
  /// 设计：明确调用每个候选方法，捕获 NoSuchMethodError
  /// 关键：upnp2 1.0.0 不会直接动态 dispatch，必须硬编码调用
  Future<bool> invoke() async {
    if (target == null) return false;
    final t = target!;
    for (final name in candidates) {
      try {
        // 关键：用 dynamic + named-arg 转发，捕获 NoSuchMethodError
        // ignore: avoid_dynamic_calls
        final dynamic result = await Function.apply(
          _resolveMethod(t, name),
          [t, ...positionalArgs],
        );
        AppLogger.d('UPnP $opName → $name() 成功');
        // 任何非 false/null 的返回值都视为成功
        return result != false && result != null;
      } on NoSuchMethodError {
        // 该方法不存在，尝试下一个
        continue;
      } catch (e) {
        // 业务错误（如网络），重试下一个候选
        AppLogger.w('UPnP $opName 尝试 $name 失败: $e');
      }
    }
    AppLogger.w('UPnP $opName 全部候选方法都失败 (${candidates.length} 个)');
    return false;
  }

  /// 列表型调用：返回 List<dynamic> 或 null
  Future<List<dynamic>?> invokeList() async {
    if (target == null) return null;
    final t = target!;
    for (final name in candidates) {
      try {
        // ignore: avoid_dynamic_calls
        final dynamic result = await Function.apply(
          _resolveMethod(t, name),
          [t, ...positionalArgs],
        );
        if (result is List) return result;
      } on NoSuchMethodError {
        continue;
      } catch (e) {
        AppLogger.w('UPnP $opName 列表调用 $name 失败: $e');
      }
    }
    return null;
  }

  /// 反射获取实例方法
  /// 关键：在 AOT 模式下 dart:mirrors 不可用，因此采用 try/catch 探测
  Function _resolveMethod(Object instance, String name) {
    // ignore: avoid_dynamic_calls
    return (instance as dynamic)[name] as Function;
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
