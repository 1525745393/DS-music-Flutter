import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/player_bar/mini_player_bar.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import 'home/home_page.dart';
import 'search/search_page.dart';
import 'settings/settings_page.dart';
import '../provider/library_provider.dart';

/// 主框架：底部 4 个 Tab + MiniPlayer
/// Tab 含义：
///   0 = 音乐（HomePage）
///   1 = 搜索（SearchPage）
///   2 = 歌单（HomePage 切到 playlists Tab）
///   3 = 设置（SettingsPage）
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _tab = 0;

  /// i18n 后的 Tab 标题
  /// 关键：从 context.s 动态构造而非 static const
  List<BottomTabItem> _buildTabs(BuildContext context) {
    final t = context.s;
    return [
      BottomTabItem(
          icon: CupertinoIcons.house,
          activeIcon: CupertinoIcons.house_fill,
          label: t.tabMusic),
      BottomTabItem(
          icon: CupertinoIcons.search,
          activeIcon: CupertinoIcons.search,
          label: t.search),
      BottomTabItem(
          icon: CupertinoIcons.collections,
          activeIcon: CupertinoIcons.collections_solid,
          label: t.tabPlaylists),
      BottomTabItem(
          icon: CupertinoIcons.gear,
          activeIcon: CupertinoIcons.gear_solid,
          label: t.settings),
    ];
  }

  /// 根据当前 tab 渲染对应页面。
  /// 关键：歌单 tab 复用 HomePage 但把内部 tab 切到 playlists，避免重复路由栈。
  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const HomePage(key: ValueKey('home_music'));
      case 1:
        return const SearchPage();
      case 2:
        // 切到 HomePage 的 playlists Tab
        return HomePage(
          key: const ValueKey('home_playlists'),
          initialTab: LibraryTab.playlists,
        );
      case 3:
        return const SettingsPage();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _buildTabs(context);
    return CupertinoPageScaffold(
      backgroundColor: AppColors.darkBg,
      child: Column(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(
                key: ValueKey('tab-$_tab'),
                child: _buildPage(_tab),
              ),
            ),
          ),
          const MiniPlayerBar(),
          _bottomBar(tabs),
        ],
      ),
    );
  }

  Widget _bottomBar(List<BottomTabItem> tabs) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: AppColors.darkElevated,
        border: Border(
          top: BorderSide(color: AppColors.darkDivider, width: 0.5),
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final tab = tabs[i];
          final selected = i == _tab;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() => _tab = i);
                // 切到歌单 tab 时同步通知 HomePage 内部 libraryTabProvider
                if (i == 2) {
                  ref.read(libraryTabProvider.notifier).state =
                      LibraryTab.playlists;
                } else if (i == 0) {
                  ref.read(libraryTabProvider.notifier).state =
                      LibraryTab.albums;
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected ? tab.activeIcon : tab.icon,
                    size: 22,
                    color: selected
                        ? AppColors.accent
                        : AppColors.textAssistantDark,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tab.label,
                    style: TextStyle(
                      fontSize: 10,
                      color: selected
                          ? AppColors.accent
                          : AppColors.textAssistantDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class BottomTabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const BottomTabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
