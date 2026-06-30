import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/download_api.dart';
import '../../components/ds_state_page.dart';
import '../../components/ds_text.dart';
import '../../l10n/app_strings.dart';
import '../../model/song.dart';
import '../../provider/core_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/file_utils.dart';

/// 批量下载页
/// - 展示专辑/歌单内的全部歌曲
/// - 支持多选 / 全选 / 单曲/批量下载
/// - 实时进度显示、暂停/恢复
class DownloadManagerPage extends ConsumerStatefulWidget {
  final String title;
  final List<Song> songs;
  const DownloadManagerPage({super.key, required this.title, required this.songs});

  @override
  ConsumerState<DownloadManagerPage> createState() => _DownloadManagerPageState();
}

class _DownloadManagerPageState extends ConsumerState<DownloadManagerPage> {
  final Set<String> _selected = {};
  StreamSubscription? _progressSub;
  // 进度表：songId -> {received, total, status}
  final Map<String, _DownloadProgress> _progress = {};

  @override
  void initState() {
    super.initState();
    final api = ref.read(downloadApiProvider);
    _progressSub = api.progressStream.listen((task) {
      if (!mounted) return;
      setState(() {
        _progress[task.song.id] = _DownloadProgress(
          received: task.receivedBytes,
          total: task.totalBytes,
          status: task.status,
        );
      });
    });
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.darkBg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.darkBg.withOpacity(0.85),
        border: const Border(),
        middle: DSText(widget.title),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _selected.isEmpty ? null : _downloadSelected,
          child: DSText('下载(${_selected.length})', color: _selected.isEmpty ? AppColors.textAssistantDark : AppColors.accent),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: ListView.separated(
                itemCount: widget.songs.length,
                separatorBuilder: (_, __) => Container(
                  margin: const EdgeInsets.only(left: 64),
                  height: 0.5,
                  color: AppColors.darkDivider,
                ),
                itemBuilder: (_, i) {
                  final s = widget.songs[i];
                  final p = _progress[s.id];
                  return _songItem(s, p);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.darkElevated,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                if (_selected.length == widget.songs.length) {
                  _selected.clear();
                } else {
                  _selected.clear();
                  _selected.addAll(widget.songs.map((e) => e.id));
                }
              });
            },
            child: Row(
              children: [
                Icon(
                  _selected.length == widget.songs.length
                      ? CupertinoIcons.checkmark_square_fill
                      : CupertinoIcons.square,
                  color: AppColors.accent,
                  size: 18,
                ),
                const SizedBox(width: 6),
                const DSText('全选'),
              ],
            ),
          ),
          const Spacer(),
          DSText.assistant('已选 ${_selected.length} / ${widget.songs.length}'),
        ],
      ),
    );
  }

  Widget _songItem(Song s, _DownloadProgress? p) {
    final api = ref.read(downloadApiProvider);
    final selected = _selected.contains(s.id);
    final completed = p?.status == DownloadStatus.completed;
    final downloading = p?.status == DownloadStatus.downloading;
    final progress = p?.progress ?? 0.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() {
        if (selected) {
          _selected.remove(s.id);
        } else {
          _selected.add(s.id);
        }
      }),
      child: Container(
        color: selected ? AppColors.accent.withOpacity(0.10) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              selected
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              color: selected ? AppColors.accent : AppColors.textAssistantDark,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DSText(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      DSText.assistant(s.artist ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(width: 8),
                      DSText.assistant('${FileUtils.humanReadableSize(s.size)}'),
                    ],
                  ),
                  if (downloading || completed) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.darkDivider,
                        color: completed ? AppColors.success : AppColors.accent,
                        minHeight: 3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        DSText.assistant(completed ? '已完成' : '${(progress * 100).toStringAsFixed(0)}%'),
                        const Spacer(),
                        if (p != null)
                          DSText.assistant(
                            '${FileUtils.humanReadableSize(p.received)} / ${p.total > 0 ? FileUtils.humanReadableSize(p.total) : "?"}',
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (completed)
              const Icon(CupertinoIcons.checkmark_alt_circle_fill, color: AppColors.success, size: 20)
            else if (downloading)
              GestureDetector(
                onTap: () => api.pause(s.id),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(CupertinoIcons.pause_circle_fill, color: AppColors.accent, size: 22),
                ),
              )
            else if (p?.status == DownloadStatus.paused || p?.status == DownloadStatus.failed)
              GestureDetector(
                onTap: () => api.resume(s.id),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(CupertinoIcons.play_circle_fill, color: AppColors.accent, size: 22),
                ),
              )
            else
              GestureDetector(
                onTap: () => _downloadOne(s),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(CupertinoIcons.arrow_down_circle, color: AppColors.accent, size: 22),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 注册下载任务，由 DownloadApi 内部调度器决定何时启动
  /// 关键变更：原实现串行 await start(task)，新实现只 register，
  /// 由 maxParallel=3 的调度器自动并行执行。
  Future<void> _downloadOne(Song s) async {
    final api = ref.read(downloadApiProvider);
    final ext = s.container ?? 'mp3';
    final file = await FileUtils.songFile(
      album: s.album ?? 'unknown',
      title: s.title,
      ext: ext,
    );
    api.register(s, file.path);
  }

  Future<void> _downloadSelected() async {
    // 并发由 DownloadApi 内部 maxParallel 限制，UI 层只需批量注册
    for (final s in widget.songs.where((s) => _selected.contains(s.id))) {
      await _downloadOne(s);
    }
  }
}

/// 自定义 LinearProgressIndicator：避免对 material.dart 全量依赖
class LinearProgressIndicator extends StatelessWidget {
  final double value;
  final Color backgroundColor;
  final Color color;
  final double minHeight;
  const LinearProgressIndicator({
    super.key,
    required this.value,
    required this.backgroundColor,
    required this.color,
    this.minHeight = 4,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: minHeight,
      child: Stack(
        children: [
          Container(color: backgroundColor),
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(color: color),
          ),
        ],
      ),
    );
  }
}

class _DownloadProgress {
  final int received;
  final int total;
  final DownloadStatus status;
  const _DownloadProgress({required this.received, required this.total, required this.status});
  double get progress => total > 0 ? received / total : 0;
}
