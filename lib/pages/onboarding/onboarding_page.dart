import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../components/buttons/ds_button.dart';
import '../../components/ds_text.dart';
import '../../constants/storage_keys.dart';
import '../../provider/core_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';

/// 首次启动引导页：4 屏横滑 + 底部指示器
class OnboardingPage extends ConsumerStatefulWidget {
  final VoidCallback onCompleted;
  const OnboardingPage({super.key, required this.onCompleted});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    _OnboardSlide(
      icon: CupertinoIcons.music_note_2,
      title: '欢迎使用 DS Player',
      subtitle: '为 Synology / Plex 打造的移动端音乐客户端',
    ),
    _OnboardSlide(
      icon: CupertinoIcons.wifi,
      title: '智能网络切换',
      subtitle: 'WiFi 下播放无损音质\n蜂窝下自动转码节省流量',
    ),
    _OnboardSlide(
      icon: CupertinoIcons.text_quote,
      title: '悬浮歌词 + 锁屏控制',
      subtitle: '后台播放时仍可浏览与查看歌词',
    ),
    _OnboardSlide(
      icon: CupertinoIcons.car_detailed,
      title: '支持 Android Auto',
      subtitle: '在车载系统中浏览你的私人曲库',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final sp = await ref.read(sharedPreferencesProvider.future);
    await sp.setBool(StorageKeys.firstLaunch, false);
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.darkBg,
      child: SafeArea(
        child: Column(
          children: [
            // 顶部：跳过按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const Spacer(),
                  CupertinoButton(
                    onPressed: _complete,
                    child: DSText.assistant('跳过', color: AppColors.textAssistantDark),
                  ),
                ],
              ),
            ),
            // 中间：4 屏
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _pages[i],
              ),
            ),
            // 底部：指示器 + 按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                children: [
                  // 指示器
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: active ? 24 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: active ? AppColors.accent : AppColors.darkDivider,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  DSButton(
                    text: _index == _pages.length - 1 ? '开始体验' : '下一步',
                    onPressed: () {
                      if (_index == _pages.length - 1) {
                        _complete();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
                    fullWidth: true,
                    height: 52,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardSlide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _OnboardSlide({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 56, color: AppColors.accent),
          ),
          const SizedBox(height: 32),
          DSText.largeTitle(title, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          DSText.assistant(subtitle, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
