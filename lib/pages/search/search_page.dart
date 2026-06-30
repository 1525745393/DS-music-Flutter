import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/ds_state_page.dart';
import '../../components/ds_text.dart';
import '../../components/lists/song_list_tile.dart';
import '../../l10n/app_strings.dart';
import '../../provider/core_providers.dart';
import '../../provider/library_provider.dart';
import '../../provider/player_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../player/player_page.dart';

/// 搜索页
/// i18n 关键：所有硬编码字符串已切换为 context.s.xxx
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s;
    final async = ref.watch(searchResultProvider);
    return CupertinoPageScaffold(
      backgroundColor: AppColors.darkBg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.darkBg,
        border: const Border(),
        middle: DSText(t.search),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: CupertinoSearchTextField(
                controller: _controller,
                placeholder: '${t.search} ${t.albums.toLowerCase()}/${t.artists.toLowerCase()}/${t.songs}',
                onChanged: (v) => ref.read(searchKeywordProvider.notifier).state = v,
                onSubmitted: (v) => ref.read(searchKeywordProvider.notifier).state = v,
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => DSStatePage(type: StateType.loading, message: t.loading),
                error: (e, _) => DSStatePage(type: StateType.error, message: e.toString()),
                data: (r) {
                  if (r.albums.isEmpty && r.artists.isEmpty && r.songs.isEmpty) {
                    return DSStatePage(type: StateType.empty, message: t.empty);
                  }
                  return ListView(
                    padding: const EdgeInsets.only(bottom: AppDimens.miniPlayerHeight + 16),
                    children: [
                      if (r.songs.isNotEmpty) _section(t.songs, ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: r.songs.length,
                        itemBuilder: (_, i) {
                          final s = r.songs[i];
                          return SongListTile(
                            song: s,
                            coverUrl: s.albumId != null ? ref.read(libraryRepositoryProvider).coverUrl(s.albumId!) : null,
                            onTap: () {
                              ref.read(playerStateProvider.notifier).setQueue(r.songs, startIndex: i);
                              Navigator.of(context).push(CupertinoPageRoute(
                                fullscreenDialog: true,
                                builder: (_) => const PlayerPage(),
                              ));
                            },
                          );
                        },
                      )),
                      if (r.albums.isNotEmpty) _section(t.albums, ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: r.albums.length,
                        itemBuilder: (_, i) {
                          final a = r.albums[i];
                          return ListTile(
                            leading: Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.darkElevated,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(CupertinoIcons.music_albums, color: AppColors.textAssistantDark),
                            ),
                            title: DSText(a.name),
                            subtitle: DSText.assistant(a.artist ?? ''),
                            onTap: () {},
                          );
                        },
                      )),
                      if (r.artists.isNotEmpty) _section(t.artists, ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: r.artists.length,
                        itemBuilder: (_, i) {
                          final a = r.artists[i];
                          return ListTile(
                            leading: Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.darkElevated,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(CupertinoIcons.person_fill, color: AppColors.textAssistantDark),
                            ),
                            title: DSText(a.name),
                            subtitle: DSText.assistant('${a.albumCount} ${t.albums}'),
                            onTap: () {},
                          );
                        },
                      )),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: DSText.title(title),
        ),
        child,
      ],
    );
  }
}
