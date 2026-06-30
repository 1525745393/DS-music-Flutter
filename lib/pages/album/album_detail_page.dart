import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/ds_state_page.dart';
import '../../components/ds_text.dart';
import '../../components/lists/song_list_tile.dart';
import '../../l10n/app_strings.dart';
import '../../model/song.dart';
import '../../provider/core_providers.dart';
import '../../provider/library_provider.dart';
import '../../provider/player_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../player/player_page.dart';

/// 专辑详情
class AlbumDetailPage extends ConsumerWidget {
  final String albumId;
  final String albumName;
  const AlbumDetailPage(
      {super.key, required this.albumId, required this.albumName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(albumDetailProvider(albumId));
    return CupertinoPageScaffold(
      backgroundColor: AppColors.darkBg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.darkBg.withOpacity(0.85),
        border: const Border(),
        middle: DSText(albumName),
      ),
      child: SafeArea(
        child: async.when(
          loading: () =>
              DSStatePage(type: StateType.loading, message: context.s.loading),
          error: (e, _) => DSStatePage(
              type: StateType.error,
              message: e.toString(),
              onRetry: () => ref.invalidate(albumDetailProvider(albumId))),
          data: (data) {
            final songs = data.songs;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                    child: _header(data.album.coverUrl ?? '', data.album.name,
                        data.album.artist ?? '')),
                SliverList.separated(
                  itemCount: songs.length,
                  separatorBuilder: (_, __) => Container(
                      margin: const EdgeInsets.only(left: 16),
                      height: 0.5,
                      color: AppColors.darkDivider),
                  itemBuilder: (_, i) {
                    final Song s = songs[i];
                    return SongListTile(
                      song: s,
                      coverUrl:
                          ref.read(libraryRepositoryProvider).coverUrl(albumId),
                      onTap: () {
                        ref
                            .read(playerStateProvider.notifier)
                            .setQueue(songs, startIndex: i);
                        Navigator.of(context).push(CupertinoPageRoute(
                          fullscreenDialog: true,
                          builder: (_) => const PlayerPage(),
                        ));
                      },
                    );
                  },
                ),
                const SliverToBoxAdapter(
                    child: SizedBox(height: AppDimens.miniPlayerHeight + 16)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(String cover, String title, String artist) {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.pagePaddingH),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
            child: Image.network(
              cover,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                  width: 120, height: 120, color: AppColors.darkElevated),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                DSText.largeTitle(title),
                const SizedBox(height: 8),
                DSText.assistant(artist),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
