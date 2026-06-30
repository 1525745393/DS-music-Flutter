import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import '../model/song.dart';
import '../utils/logger.dart';
import 'audio_station_api.dart';

/// 下载任务：单首歌曲，断点续传（Range），实时进度
class DownloadTask {
  final Song song;
  final String localPath;
  int receivedBytes = 0;
  int totalBytes = 0;
  DownloadStatus status = DownloadStatus.pending;
  String? error;

  DownloadTask({required this.song, required this.localPath});

  double get progress => totalBytes > 0 ? receivedBytes / totalBytes : 0;
}

enum DownloadStatus { pending, downloading, paused, completed, failed }

/// 下载管理器
class DownloadApi {
  final AudioStationApi _api;
  final Map<String, DownloadTask> _tasks = {};
  final _progressController = StreamController<DownloadTask>.broadcast();

  Stream<DownloadTask> get progressStream => _progressController.stream;

  DownloadApi(this._api);

  List<DownloadTask> get tasks => _tasks.values.toList();
  DownloadTask? taskFor(String songId) => _tasks[songId];

  /// 注册任务（不立即下载）
  DownloadTask register(Song song, String localPath) {
    final t = DownloadTask(song: song, localPath: localPath);
    _tasks[song.id] = t;
    return t;
  }

  /// 启动/恢复下载
  Future<void> start(DownloadTask task) async {
    task.status = DownloadStatus.downloading;
    _emit(task);
    final url = _api.buildDownloadUrl(task.song);
    final file = File(task.localPath);
    await file.parent.create(recursive: true);

    int existing = await file.exists() ? await file.length() : 0;
    task.receivedBytes = existing;

    final cancelToken = CancelToken();
    task.song.copyWith; // 占位
    try {
      await Dio().get<ResponseBody>(
        url,
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            if (existing > 0) HttpHeaders.rangeHeader: 'bytes=$existing-',
            '_sid': '',
          },
        ),
      ).then((resp) async {
        task.totalBytes = existing + int.parse(resp.headers.value(HttpHeaders.contentLengthHeader) ?? '0');
        final sink = file.openWrite(mode: existing > 0 ? FileMode.append : FileMode.write);
        await for (final chunk in resp.data!.stream) {
          if (cancelToken.isCancelled) break;
          sink.add(chunk);
          task.receivedBytes += chunk.length;
          _emit(task);
        }
        await sink.flush();
        await sink.close();
        if (!cancelToken.isCancelled) {
          task.status = DownloadStatus.completed;
        }
      });
    } catch (e) {
      AppLogger.e('下载失败', e);
      task.status = DownloadStatus.failed;
      task.error = e.toString();
    } finally {
      _emit(task);
    }
  }

  void _emit(DownloadTask t) {
    if (!_progressController.isClosed) _progressController.add(t);
  }

  void dispose() => _progressController.close();
}
