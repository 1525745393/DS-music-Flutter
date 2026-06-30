import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/ds_state_page.dart';
import '../../components/ds_text.dart';
import '../../components/cards/album_grid_item.dart';
import '../../provider/core_providers.dart';
import '../../provider/library_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../album/album_detail_page.dart';

/// 歌手详情
class ArtistDetailPage extends ConsumerWidget {
  final String artistId;
  final String artistName;
  const ArtistDetailPage({super.key, required this.artistId, required this.artistName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(artistDetailProvider(artistId));
    return CupertinoPageScaffold(
      backgroundColor: AppColors.darkBg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.darkBg.withOpacity(0.85),
        border: const Border(),
        middle: DSText(artistName),
      ),
      child: SafeArea(
        child: async.when(
          loading: () => const DSStatePage(type: StateType.loading),
          error: (e, _) => DSStatePage(type: StateType.error, message: e.toString()),
          data: (data) {
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, AppDimens.miniPlayerHeight + 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.72,
              ),
              itemCount: data.albums.length,
              itemBuilder: (_, i) {
                final a = data.albums[i];
                return AlbumGridItem(
                  album: a,
                  coverUrl: ref.read(libraryRepositoryProvider).coverUrl(a.id),
                  onTap: () => Navigator.of(context).push(CupertinoPageRoute(
                    builder: (_) => AlbumDetailPage(albumId: a.id, albumName: a.name),
                  )),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
