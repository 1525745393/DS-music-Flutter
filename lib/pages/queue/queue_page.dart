import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/ds_state_page.dart';
import '../../components/ds_text.dart';
import '../../components/lists/song_list_tile.dart';
import '../../l10n/app_strings.dart';
import '../../model/song.dart';
import '../../player/playback_service.dart';
import '../../provider/core_providers.dart';
import '../../provider/player_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_text_styles.dart';

/// 播放队列管理页
/// i18n：所有硬编码中文已切换为 context.s.xxx
class QueuePage extends ConsumerStatefulWidget {
  const QueuePage({super.key});

  @override
  ConsumerState<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends ConsumerState<QueuePage> {
  bool _editing = false;
  final Set<int> _selectedIndexes = {};

  @override
  Widget build(BuildContext context) {
    final t = context.s;
    final state = ref.watch(playerStateProvider);
    final queue = state.queue;
    final currentIndex = state.currentIndex;
    final totalDuration = queue.fold<int>(0, (s, e) => s + e.duration);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.darkBg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.darkBg.withOpacity(0.85),
        border: const Border(),
        middle: DSText('${t.queue} (${queue.length})'),
        trailing: _editing
            ? _editingTrailing(queue, t)
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => setState(() {
                  _editing = true;
                  _selectedIndexes.clear();
                }),
                child: DSText(t.edit, color: AppColors.accent),
              ),
      ),
      child: SafeArea(
        child: queue.isEmpty
            ? DSStatePage(type: StateType.empty, message: '${t.queue} ${t.empty}')
            : Column(
                children: [
                  _summary(state.current, totalDuration),
                  if (_editing) _batchBar(),
                  Expanded(
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.only(bottom: AppDimens.miniPlayerHeight + 16),
                      proxyDecorator: (child, index, animation) {
                        return Material(
                          color: AppColors.darkBg,
                          child: child,
                        );
                      },
                      buildDefaultDragHandles: !_editing,
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) newIndex -= 1;
                        ref.read(playerStateProvider.notifier).move(oldIndex, newIndex);
                      },
                      itemCount: queue.length,
                      itemBuilder: (_, i) {
                        final Song s = queue[i];
                        final isCurrent = i == currentIndex;
                        return _queueItem(
                          key: ValueKey('q_$i'),
                          index: i,
                          song: s,
                          isCurrent: isCurrent,
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _editingTrailing(List<Song> queue, AppStrings t) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_selectedIndexes.isNotEmpty)
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onPressed: () {
              final sorted = _selectedIndexes.toList()..sort((a, b) => b.compareTo(a));
              for (final i in sorted) {
                ref.read(playerStateProvider.notifier).removeAt(i);
              }
              _selectedIndexes.clear();
              setState(() {});
            },
            child: DSText('${t.delete}(${_selectedIndexes.length})',
                color: AppColors.danger),
          ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => setState(() {
            _editing = false;
            _selectedIndexes.clear();
          }),
          child: DSText(t.done, color: AppColors.accent),
        ),
      ],
    );
  }

  Widget _summary(Song? current, int totalSeconds) {
    if (current == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.darkDivider, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(CupertinoIcons.music_note_2, color: CupertinoColors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                DSText(current.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                DSText.assistant('共 ${ref.read(playerStateProvider).queue.length} 首 · 总时长 ${_formatTotal(totalSeconds)}'),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              ref.read(playerStateProvider.notifier).setQueue([]);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(CupertinoIcons.trash, color: AppColors.danger, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _batchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.darkElevated,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() {
              if (_selectedIndexes.length == ref.read(playerStateProvider).queue.length) {
                _selectedIndexes.clear();
              } else {
                _selectedIndexes.clear();
                for (var i = 0; i < ref.read(playerStateProvider).queue.length; i++) {
                  _selectedIndexes.add(i);
                }
              }
            }),
            child: Row(
              children: [
                Icon(
                  _selectedIndexes.length == ref.read(playerStateProvider).queue.length
                      ? CupertinoIcons.checkmark_square_fill
                      : CupertinoIcons.square,
                  color: AppColors.accent,
                  size: 18,
                ),
                const SizedBox(width: 6),
                DSText(context.s.isEnglish ? 'Select All' : '全选'),
              ],
            ),
          ),
          const Spacer(),
          DSText.assistant(context.s.isEnglish
              ? 'Selected ${_selectedIndexes.length}'
              : '已选 ${_selectedIndexes.length} 项'),
        ],
      ),
    );
  }

  Widget _queueItem({
    required Key key,
    required int index,
    required Song song,
    required bool isCurrent,
  }) {
    final repo = ref.read(libraryRepositoryProvider);
    final coverUrl = song.albumId != null ? repo.coverUrl(song.albumId!, size: 'small') : null;

    Widget content = Container(
      color: isCurrent ? AppColors.accent.withOpacity(0.12) : null,
      child: Row(
        children: [
          if (_editing)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 4),
              child: GestureDetector(
                onTap: () => setState(() {
                  if (_selectedIndexes.contains(index)) {
                    _selectedIndexes.remove(index);
                  } else {
                    _selectedIndexes.add(index);
                  }
                }),
                child: Icon(
                  _selectedIndexes.contains(index)
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.circle,
                  color: _selectedIndexes.contains(index) ? AppColors.accent : AppColors.textAssistantDark,
                  size: 22,
                ),
              ),
            )
          else
            SizedBox(
              width: 40,
              child: isCurrent
                  ? const Icon(CupertinoIcons.speaker_2_fill, color: AppColors.accent, size: 18)
                  : Center(child: DSText('${index + 1}', color: AppColors.textAssistantDark)),
            ),
          Expanded(
            child: SongListTile(
              song: song,
              coverUrl: coverUrl,
              showCover: true,
              onTap: _editing
                  ? null
                  : () async {
                      ref.read(playerStateProvider.notifier).setCurrentIndex(index);
                      final h = ref.read(audioHandlerProvider);
                      await h.skipToQueueItem(index);
                    },
            ),
          ),
        ],
      ),
    );

    if (_editing) {
      return Container(
        key: key,
        child: Dismissible(
          key: ValueKey('dismiss_$index'),
          direction: DismissDirection.endToStart,
          background: Container(
            color: AppColors.danger,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: const Icon(CupertinoIcons.trash, color: CupertinoColors.white),
          ),
          onDismissed: (_) {
            ref.read(playerStateProvider.notifier).removeAt(index);
          },
          child: content,
        ),
      );
    }

    return content;
  }

  String _formatTotal(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '$h 小时 $m 分';
    return '$m 分';
  }
}
