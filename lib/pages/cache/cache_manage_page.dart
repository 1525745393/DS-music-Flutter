import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ListTile;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/ds_state_page.dart';
import '../../components/ds_text.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/file_utils.dart';

/// 缓存管理页
/// - 展示本地缓存大小
/// - 按类型统计（专辑/歌手/单首）
/// - 一键清理
class CacheManagePage extends ConsumerStatefulWidget {
  const CacheManagePage({super.key});

  @override
  ConsumerState<CacheManagePage> createState() => _CacheManagePageState();
}

class _CacheManagePageState extends ConsumerState<CacheManagePage> {
  int _totalBytes = 0;
  int _albumsCount = 0;
  int _songsCount = 0;
  String _path = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    setState(() => _loading = true);
    final root = await FileUtils.getCacheRoot();
    int total = 0;
    int albums = 0;
    int songs = 0;
    if (await root.exists()) {
      await for (final entity in root.list(recursive: true)) {
        if (entity is File) {
          try {
            total += await entity.length();
            songs += 1;
          } catch (_) {}
        } else if (entity is Directory) {
          albums += 1;
        }
      }
    }
    if (mounted) {
      setState(() {
        _totalBytes = total;
        _albumsCount = albums;
        _songsCount = songs;
        _path = root.path;
        _loading = false;
      });
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const DSText('清理缓存'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: DSText('所有已下载的歌曲都将被删除，需要重新下载。确定继续？'),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const DSText('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const DSText('清理'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final root = await FileUtils.getCacheRoot();
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
    await _scan();
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const DSText('已清理'),
          content: const DSText('所有本地缓存已删除'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const DSText('确定'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.darkBg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.darkBg.withOpacity(0.85),
        border: const Border(),
        middle: const DSText('缓存管理'),
      ),
      child: SafeArea(
        child: _loading
            ? const DSStatePage(type: StateType.loading, message: '正在扫描缓存...')
            : ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  _header(),
                  _section('存储详情', [
                    _row('总占用', FileUtils.humanReadableSize(_totalBytes)),
                    _row('已下载歌曲', '$_songsCount 首'),
                    _row('专辑数', '$_albumsCount 个'),
                    _row('存储路径', _path, showArrow: false),
                  ]),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: CupertinoButton(
                        color: AppColors.danger,
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusMedium),
                        onPressed: _totalBytes == 0 ? null : _clearAll,
                        child: DSText(
                          _totalBytes == 0 ? '缓存为空' : '一键清理全部缓存',
                          color: CupertinoColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _header() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
      ),
      child: Column(
        children: [
          const Icon(CupertinoIcons.archivebox_fill,
              size: 48, color: AppColors.accent),
          const SizedBox(height: 12),
          DSText.largeTitle(FileUtils.humanReadableSize(_totalBytes)),
          const SizedBox(height: 4),
          const DSText.assistant('当前缓存占用'),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: DSText.assistant(title.toUpperCase()),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
            ),
            child: Column(
              children: ListTile.divideTiles(
                context: context,
                tiles: children,
                color: AppColors.darkDivider,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String title, String value, {bool showArrow = true}) {
    return Container(
      height: AppDimens.listItemHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: DSText(title)),
          DSText.assistant(value, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (showArrow) ...[
            const SizedBox(width: 4),
            const Icon(CupertinoIcons.chevron_right,
                color: AppColors.textAssistantDark, size: 16),
          ],
        ],
      ),
    );
  }

  Future<String> _storagePath() async {
    final root = await FileUtils.getCacheRoot();
    return root.path;
  }
}
