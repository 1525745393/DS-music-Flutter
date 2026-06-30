import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/mini_player/mini_player_bar.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import 'home/home_page.dart';

/// 主框架：底部 4 个 Tab + MiniPlayer
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
      BottomTabItem(icon: CupertinoIcons.house, activeIcon: CupertinoIcons.house_fill, label: t.tabMusic),
      BottomTabItem(icon: CupertinoIcons.search, activeIcon: CupertinoIcons.search, label: t.search),
      BottomTabItem(icon: CupertinoIcons.collections, activeIcon: CupertinoIcons.collections_solid, label: t.tabPlaylists),
      BottomTabItem(icon: CupertinoIcons.gear, activeIcon: CupertinoIcons.gear_solid, label: t.settings),
    ];
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
                child: _pages[_tab],
              ),
            ),
          ),
          const MiniPlayerBar(),
          _bottomBar(tabs),
        ],
      ),
    );
  }

  final List<Widget> _pages = [
    const HomePage(),
    const SizedBox.shrink(), // 占位：搜索由 main_shell 直接跳转
    const HomePage(), // 占位：歌单使用 HomePage 的 tab=4
    const SizedBox.shrink(), // 占位：设置由 main_shell 直接跳转
  ];

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
                if (i == 1) {
                  // 搜索跳到 SearchPage
                  // 实际项目可以更精细，此处简化
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected ? tab.activeIcon : tab.icon,
                    size: 22,
                    color: selected ? AppColors.accent : AppColors.textAssistantDark,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tab.label,
                    style: TextStyle(
                      fontSize: 10,
                      color: selected ? AppColors.accent : AppColors.textAssistantDark,
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
