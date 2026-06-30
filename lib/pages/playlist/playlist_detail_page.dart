import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/ds_state_page.dart';
import '../../components/ds_text.dart';
import '../../components/forms/star_rating.dart';
import '../../components/lists/song_list_tile.dart';
import '../../l10n/app_strings.dart';
import '../../model/song.dart';
import '../../player/playback_service.dart';
import '../../provider/core_providers.dart';
import '../../provider/library_provider.dart';
import '../../provider/player_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../utils/logger.dart';
import '../player/player_page.dart';
import 'playlist_editor_page.dart';

/// 歌单详情
class PlaylistDetailPage extends ConsumerWidget {
  final String playlistId;
  final String name;
  const PlaylistDetailPage({super.key, required this.playlistId, required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.s;
    final async = ref.watch(playlistDetailProvider(playlistId));
    return CupertinoPageScaffold(
      backgroundColor: AppColors.darkBg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.darkBg.withOpacity(0.85),
        border: const Border(),
        middle: DSText(name),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            Navigator.of(context).push(CupertinoPageRoute(
              builder: (_) => PlaylistEditorPage(playlistId: playlistId),
            ));
          },
          child: DSText(t.edit, color: AppColors.accent),
        ),
      ),
      child: SafeArea(
        child: async.when(
          loading: () => const DSStatePage(type: StateType.loading),
          error: (e, _) => DSStatePage(type: StateType.error, message: e.toString()),
          data: (pl) {
            final songs = pl.songs;
            if (songs.isEmpty) return DSStatePage(type: StateType.empty, message: t.empty);
            return ListView.separated(
              itemCount: songs.length,
              separatorBuilder: (_, __) => Container(
                  margin: const EdgeInsets.only(left: 16), height: 0.5, color: AppColors.darkDivider),
              itemBuilder: (_, i) {
                final Song s = songs[i];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPress: () => _showRatingSheet(context, ref, s),
                  child: SongListTile(
                    song: s,
                    coverUrl: s.albumId != null
                        ? ref.read(libraryRepositoryProvider).coverUrl(s.albumId!)
                        : null,
                    trailing: s.rating > 0
                        ? StarRating(value: s.rating, size: 12, onChanged: (_) {})
                        : null,
                    onTap: () async {
                      final h = ref.read(audioHandlerProvider);
                      await h.setQueueAndPlay(songs, startIndex: i);
                      ref.read(playerStateProvider.notifier)
                          .setQueue(songs, startIndex: i);
                      ref.read(playerStateProvider.notifier).setPlaying(true);
                      if (context.mounted) {
                        Navigator.of(context).push(CupertinoPageRoute(
                          fullscreenDialog: true,
                          builder: (_) => const PlayerPage(),
                        ));
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// 弹出评分底部弹窗
  void _showRatingSheet(BuildContext context, WidgetRef ref, Song s) {
    int current = s.rating;
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        return Container(
          height: 220,
          color: AppColors.darkCard,
          child: StatefulBuilder(
            builder: (ctx, setS) => Column(
              children: [
                SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      CupertinoButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: DSText(t.cancel),
                      ),
                      const Spacer(),
                      CupertinoButton(
                        onPressed: () async {
                          try {
                            await ref.read(libraryRepositoryProvider).rate(s, current);
                            ref.invalidate(playlistDetailProvider(playlistId));
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (e) {
                            AppLogger.e('评分失败: $e');
                          }
                        },
                        child: const DSText('确定', color: AppColors.accent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const DSText('为这首歌评分'),
                const SizedBox(height: 12),
                StarRating(
                  value: current,
                  size: 32,
                  onChanged: (v) => setS(() => current = v),
                ),
                const SizedBox(height: 12),
                DSText.assistant(
                  current == 0 ? '未评分' : '$current / 5',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
