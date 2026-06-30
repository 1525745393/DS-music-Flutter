import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/ds_state_page.dart';
import '../../components/ds_text.dart';
import '../../components/lists/song_list_tile.dart';
import '../../l10n/app_strings.dart';
import '../../model/song.dart';
import '../../provider/core_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';

/// 文件夹浏览页：可递归钻入子目录
/// 数据源：libraryRepository.listFolders(parentId)
class FolderBrowsePage extends ConsumerStatefulWidget {
  final String folderId;
  final String folderName;
  const FolderBrowsePage({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  @override
  ConsumerState<FolderBrowsePage> createState() => _FolderBrowsePageState();
}

class _FolderBrowsePageState extends ConsumerState<FolderBrowsePage> {
  late Future<_FolderLoadResult> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_FolderLoadResult> _load() async {
    final repo = ref.read(libraryRepositoryProvider);
    final folders = await repo.folders(parentId: widget.folderId);
    // 简化：列出当前目录下歌曲（不带 albumId 过滤）
    final songs = await repo.songs();
    return _FolderLoadResult(folders: folders, songs: songs);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.darkBg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.darkBg.withOpacity(0.85),
        border: const Border(),
        middle: DSText(widget.folderName),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _refresh,
          child: const Icon(CupertinoIcons.refresh, color: AppColors.accent),
        ),
      ),
      child: SafeArea(
        child: FutureBuilder<_FolderLoadResult>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CupertinoActivityIndicator());
            }
            if (snap.hasError) {
              return DSStatePage(
                type: StateType.error,
                message: snap.error.toString(),
                onRetry: _refresh,
              );
            }
            final result = snap.data!;
            if (result.folders.isEmpty && result.songs.isEmpty) {
              return const DSStatePage(
                type: StateType.empty,
                message: '此文件夹为空',
                icon: CupertinoIcons.folder,
              );
            }
            return ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                if (result.folders.isNotEmpty) ...[
                  _header('子文件夹 (${result.folders.length})'),
                  for (int i = 0; i < result.folders.length; i++) ...[
                    _folderItem(result.folders[i]),
                    if (i < result.folders.length - 1)
                      Container(
                        margin: const EdgeInsets.only(left: 56),
                        height: 0.5,
                        color: AppColors.darkDivider,
                      ),
                  ],
                ],
                if (result.songs.isNotEmpty) ...[
                  _header('歌曲 (${result.songs.length})'),
                  for (int i = 0; i < result.songs.length; i++) ...[
                    SongListTile(
                      song: result.songs[i],
                      onTap: () {
                        // TODO: 接入 player 队列
                      },
                    ),
                    if (i < result.songs.length - 1)
                      Container(
                        margin: const EdgeInsets.only(left: 56),
                        height: 0.5,
                        color: AppColors.darkDivider,
                      ),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: DSText.assistant(text),
    );
  }

  Widget _folderItem(Map<String, dynamic> f) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).push(CupertinoPageRoute(
          builder: (_) => FolderBrowsePage(
            folderId: (f['id'] ?? '').toString(),
            folderName: (f['name'] ?? '未命名').toString(),
          ),
        ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(CupertinoIcons.folder_fill,
                color: AppColors.accent, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DSText((f['name'] ?? '未命名').toString()),
                  if (f['items'] != null) ...[
                    const SizedBox(height: 2),
                    DSText.assistant('${f['items']} 项'),
                  ],
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right,
                color: AppColors.textAssistantDark, size: 16),
          ],
        ),
      ),
    );
  }
}

class _FolderLoadResult {
  final List<Map<String, dynamic>> folders;
  final List<Song> songs;
  _FolderLoadResult({required this.folders, required this.songs});
}
