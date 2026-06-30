import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/ds_state_page.dart';
import '../../components/ds_text.dart';
import '../../components/lists/song_list_tile.dart';
import '../../model/song.dart';
import '../../provider/core_providers.dart';
import '../../provider/library_provider.dart';
import '../../provider/player_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../player/player_page.dart';

/// 歌单详情
class PlaylistDetailPage extends ConsumerWidget {
  final String playlistId;
  final String name;
  const PlaylistDetailPage({super.key, required this.playlistId, required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(playlistDetailProvider(playlistId));
    return CupertinoPageScaffold(
      backgroundColor: AppColors.darkBg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.darkBg.withOpacity(0.85),
        border: const Border(),
        middle: DSText(name),
      ),
      child: SafeArea(
        child: async.when(
          loading: () => const DSStatePage(type: StateType.loading),
          error: (e, _) => DSStatePage(type: StateType.error, message: e.toString()),
          data: (pl) {
            final songs = pl.songs;
            if (songs.isEmpty) return const DSStatePage(type: StateType.empty, message: '歌单为空');
            return ListView.separated(
              itemCount: songs.length,
              separatorBuilder: (_, __) =>
                  Container(margin: const EdgeInsets.only(left: 16), height: 0.5, color: AppColors.darkDivider),
              itemBuilder: (_, i) {
                final Song s = songs[i];
                return SongListTile(
                  song: s,
                  coverUrl: s.albumId != null ? ref.read(libraryRepositoryProvider).coverUrl(s.albumId!) : null,
                  onTap: () {
                    ref.read(playerStateProvider.notifier).setQueue(songs, startIndex: i);
                    Navigator.of(context).push(CupertinoPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => const PlayerPage(),
                    ));
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
