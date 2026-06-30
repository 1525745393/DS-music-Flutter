import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/player_bar/mini_player_bar.dart';
import '../../provider/auth_provider.dart';
import '../../provider/player_provider.dart';
import '../home/home_page.dart';
import '../player/player_page.dart';

/// 主壳：底部固定迷你播放栏
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          const Positioned.fill(child: HomePage()),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Consumer(
                builder: (_, ref, __) {
                  final cur = ref.watch(playerStateProvider.select((s) => s.current));
                  if (cur == null) return const SizedBox.shrink();
                  return MiniPlayerBar(
                    onTap: () {
                      Navigator.of(context).push(CupertinoPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => const PlayerPage(),
                      ));
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
