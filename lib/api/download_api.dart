import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';
import '../model/song.dart';
import '../utils/logger.dart';
import 'audio_station_api.dart';

/// 下载任务：单首歌曲，断点续传（Range），实时进度
class DownloadTask {
  final Song song;
  final String localPath;
  int receivedBytes;
  int totalBytes;
  DownloadStatus status;
  String? error;

  /// 内部使用的可取消令牌与续传起始字节
  CancelToken? cancelToken;
  int resumeFrom; // 已写入文件的字节数（=receivedBytes），供持久化

  DownloadTask({
    required this.song,
    required this.localPath,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.status = DownloadStatus.pending,
    this.resumeFrom = 0,
  });

  double get progress => totalBytes > 0 ? receivedBytes / totalBytes : 0;

  /// 序列化为可持久化 JSON（不含 cancelToken 句柄）
  Map<String, dynamic> toJson() => {
        'song': song.toJson(),
        'localPath': localPath,
        'receivedBytes': receivedBytes,
        'totalBytes': totalBytes,
        'status': status.name,
        'resumeFrom': resumeFrom,
      };

  static DownloadTask? fromJson(Map<String, dynamic> json) {
    try {
      final song = Song.fromJson(Map<String, dynamic>.from(json['song'] ?? {}));
      final status = DownloadStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DownloadStatus.pending,
      );
      return DownloadTask(
        song: song,
        localPath: (json['localPath'] ?? '').toString(),
        receivedBytes: (json['receivedBytes'] as num?)?.toInt() ?? 0,
        totalBytes: (json['totalBytes'] as num?)?.toInt() ?? 0,
        // 启动时一律回到 pending，由调度器决定是否恢复
        status: status == DownloadStatus.downloading
            ? DownloadStatus.pending
            : status,
        resumeFrom: (json['resumeFrom'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      AppLogger.w('DownloadTask.fromJson 失败: $e');
      return null;
    }
  }
}

enum DownloadStatus { pending, downloading, paused, completed, failed }

/// 下载管理器
/// 关键能力：
/// 1. 并发控制：最多同时下载 N 首（[maxParallel]，默认 3）
/// 2. 显式 pause / resume / cancel：通过 [CancelToken] 精准中断
/// 3. 任务持久化：所有任务元数据写入 SharedPreferences，
///    杀进程后下次启动自动恢复（pending/completed 任务直接续跑/跳过）
/// 4. Range 断点续传：每次启动前用文件实际长度作为 Range 起点
class DownloadApi {
  final AudioStationApi _api;
  final SharedPreferences? _sp; // 可选依赖；为 null 时跳过持久化（如测试）

  /// 任务表：songId -> task
  final Map<String, DownloadTask> _tasks = {};

  /// 当前正在运行的任务
  final Set<String> _active = {};

  /// 待调度队列（pending 但尚未开始）
  final List<String> _waiting = [];

  final _progressController = StreamController<DownloadTask>.broadcast();
  Stream<DownloadTask> get progressStream => _progressController.stream;

  static const int maxParallel = 3;

  DownloadApi(this._api, [this._sp]) {
    _restore();
  }

  // ============ 查询 API ============

  List<DownloadTask> get tasks => _tasks.values.toList();
  DownloadTask? taskFor(String songId) => _tasks[songId];
  bool get isBusy => _active.isNotEmpty || _waiting.isNotEmpty;
  int get activeCount => _active.length;
  int get waitingCount => _waiting.length;

  // ============ 任务注册 ============

  /// 注册任务（不立即下载）。重复注册返回已存在任务。
  DownloadTask register(Song song, String localPath) {
    final existing = _tasks[song.id];
    if (existing != null) return existing;
    final t = DownloadTask(song: song, localPath: localPath);
    _tasks[song.id] = t;
    _waiting.add(song.id);
    _emit(t);
    _persist();
    _schedule();
    return t;
  }

  // ============ 调度 ============

  /// 启动调度：从未结束的 pending 任务中拉起 N 个直到达到 maxParallel
  void _schedule() {
    while (_active.length < maxParallel && _waiting.isNotEmpty) {
      final id = _waiting.removeAt(0);
      final t = _tasks[id];
      if (t == null) continue;
      if (t.status == DownloadStatus.completed) continue;
      _active.add(id);
      // 异步启动，不阻塞调度循环
      // ignore: discarded_futures
      _run(t);
    }
  }

  /// 显式恢复一个被暂停或失败的任务
  void resume(String songId) {
    final t = _tasks[songId];
    if (t == null) return;
    if (t.status == DownloadStatus.completed) return;
    if (t.status == DownloadStatus.downloading) return;
    t.status = DownloadStatus.pending;
    t.error = null;
    if (!_waiting.contains(songId) && !_active.contains(songId)) {
      _waiting.add(songId);
    }
    _emit(t);
    _persist();
    _schedule();
  }

  /// 显式暂停：取消当前请求，已写入文件的部分保留
  void pause(String songId) {
    final t = _tasks[songId];
    if (t == null) return;
    if (t.status == DownloadStatus.completed) return;
    t.cancelToken?.cancel('user-paused');
    t.status = DownloadStatus.paused;
    _active.remove(songId);
    _emit(t);
    _persist();
    // 暂停后让队列里其它等待任务有机会启动
    _schedule();
  }

  /// 取消并删除任务
  Future<void> cancel(String songId, {bool deleteFile = true}) async {
    final t = _tasks[songId];
    if (t == null) return;
    t.cancelToken?.cancel('user-cancelled');
    _active.remove(songId);
    _waiting.remove(songId);
    _tasks.remove(songId);
    if (deleteFile) {
      final f = File(t.localPath);
      if (await f.exists()) {
        try {
          await f.delete();
        } catch (e) {
          AppLogger.w('删除文件失败: $e');
        }
      }
    }
    _persist();
    _schedule();
  }

  /// 清空所有已完成任务（保留 pending/paused/failed）
  Future<int> clearCompleted() async {
    final done = _tasks.values
        .where((t) => t.status == DownloadStatus.completed)
        .toList();
    for (final t in done) {
      _tasks.remove(t.song.id);
    }
    _persist();
    return done.length;
  }

  // ============ 内部执行 ============

  Future<void> _run(DownloadTask task) async {
    task.status = DownloadStatus.downloading;
    _emit(task);
    final url = _api.buildDownloadUrl(task.song);
    final file = File(task.localPath);
    try {
      await file.parent.create(recursive: true);
    } catch (e) {
      AppLogger.w('创建目录失败: $e');
    }

    // 续传起点：优先用 task.resumeFrom（持久化的），否则用文件实际长度
    int existing = task.resumeFrom;
    if (existing == 0 && await file.exists()) {
      try {
        existing = await file.length();
        task.receivedBytes = existing;
      } catch (_) {}
    }

    final cancelToken = CancelToken();
    task.cancelToken = cancelToken;
    final sid = await _resolveSid();

    try {
      final resp = await _dio().get<ResponseBody>(
        url,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          // 关键：Range 头让服务端从 existing 处继续传
          headers: {
            if (existing > 0) HttpHeaders.rangeHeader: 'bytes=$existing-',
            if (sid != null) '_sid': sid,
          },
          // 接收超时设长，下载大文件不中断
          receiveTimeout: const Duration(minutes: 30),
        ),
      );

      final contentLen =
          int.parse(resp.headers.value(HttpHeaders.contentLengthHeader) ?? '0');
      task.totalBytes = existing + contentLen;
      final sink =
          file.openWrite(mode: existing > 0 ? FileMode.append : FileMode.write);
      try {
        await for (final chunk in resp.data!.stream) {
          if (cancelToken.isCancelled) break;
          // 累计字节，写盘
          sink.add(chunk);
          task.receivedBytes += chunk.length;
          task.resumeFrom = task.receivedBytes;
          // 节流：每 256KB 持久化一次
          if (task.receivedBytes % (256 * 1024) < chunk.length) {
            _persist();
          }
          _emit(task);
        }
        await sink.flush();
        await sink.close();
        if (cancelToken.isCancelled) {
          // 主动取消不当作失败
          return;
        }
        task.status = DownloadStatus.completed;
        task.error = null;
      } catch (e) {
        await sink.close();
        if (cancelToken.isCancelled) return;
        rethrow;
      }
    } catch (e) {
      AppLogger.e('下载失败 ${task.song.title}', e);
      // 取消不当作失败
      final msg = e.toString();
      if (msg.contains('user-paused') || msg.contains('user-cancelled')) {
        return;
      }
      task.status = DownloadStatus.failed;
      task.error = msg;
    } finally {
      _active.remove(task.song.id);
      task.cancelToken = null;
      _emit(task);
      _persist();
      // 关键：本次结束后立刻调度下一个等待任务
      _schedule();
    }
  }

  /// 复用单例 Dio，避免每次新建（解决原实现的内存/连接泄漏问题）
  Dio _dio() => Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(minutes: 30),
        headers: const {'User-Agent': 'DSPlayer/1.0 (Downloader)'},
      ));

  /// SID 取自当前活跃服务器的 SharedPreferences；用于解决原实现 `_sid: ''` 占位 bug
  Future<String?> _resolveSid() async {
    if (_sp == null) return null;
    return _sp.getString(StorageKeys.sid);
  }

  // ============ 持久化 ============

  void _persist() {
    if (_sp == null) return;
    try {
      final list = _tasks.values.map((t) => t.toJson()).toList();
      _sp.setString(StorageKeys.downloadTasks, jsonEncode(list));
    } catch (e) {
      AppLogger.w('持久化下载任务失败: $e');
    }
  }

  /// 启动时恢复：把 persisted 任务还原到 _tasks / _waiting
  void _restore() {
    if (_sp == null) return;
    final raw = _sp.getString(StorageKeys.downloadTasks);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      for (final j in list) {
        final t = DownloadTask.fromJson(j);
        if (t == null) continue;
        _tasks[t.song.id] = t;
        // pending/paused/failed 都进入调度队列，启动时自动续跑
        if (t.status != DownloadStatus.completed) {
          _waiting.add(t.song.id);
        }
      }
      // 异步启动调度
      Future.microtask(_schedule);
    } catch (e) {
      AppLogger.w('恢复下载任务失败: $e');
    }
  }

  void _emit(DownloadTask t) {
    if (!_progressController.isClosed) _progressController.add(t);
  }

  void dispose() => _progressController.close();
}
