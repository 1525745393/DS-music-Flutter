import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/ds_text.dart';
import '../../constants/app_constants.dart';
import '../../player/sleep_timer.dart';
import '../../provider/auth_provider.dart';
import '../../provider/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../cache/cache_manage_page.dart';
import '../dlna/dlna_devices_page.dart';
import '../overlay_lyrics/overlay_lyrics_settings_page.dart';
import '../servers/servers_page.dart';

/// 设置页：iOS 分组列表
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final sleep = ref.watch(sleepTimerProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.darkBg,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: AppColors.darkBg,
        border: Border(),
        middle: DSText('设置'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            _section('外观', [
              _row('跟随系统主题', trailing: CupertinoSwitch(
                value: s.followSystemTheme,
                onChanged: (v) => notifier.setFollowSystemTheme(v),
              )),
              _row('深色模式', trailing: CupertinoSwitch(
                value: s.isDark,
                onChanged: (v) => notifier.setDark(v),
              )),
            ]),
            _section('播放', [
              _row('无缝播放 (gapless)', trailing: CupertinoSwitch(
                value: s.gaplessEnabled,
                onChanged: (v) => notifier.setGapless(v),
              )),
              _row('音量标准化', trailing: CupertinoSwitch(
                value: s.normalizeVolume,
                onChanged: (v) => notifier.setNormalize(v),
              )),
              _row('外网强制无损', trailing: CupertinoSwitch(
                value: s.forceLossless,
                onChanged: (v) => notifier.setForceLossless(v),
              )),
              _row('均衡器', trailing: CupertinoSwitch(
                value: s.equalizerEnabled,
                onChanged: (v) => notifier.setEqEnabled(v),
              )),
              _row('睡眠定时',
                  trailing: DSText.assistant(sleep.inMinutes == 0 ? '关闭' : '${sleep.inMinutes} 分钟'),
                  onTap: () => _showSleepPicker(context, ref)),
            ]),
            _section('转码设置', [
              _row('格式', trailing: DSText.assistant(s.transcodeFormat), onTap: () {}),
              _row('码率', trailing: DSText.assistant('${s.transcodeBitrate ~/ 1000} kbps'), onTap: () {}),
              _row('移动网络强制转码', trailing: CupertinoSwitch(
                value: s.forceTranscodeOnMobile,
                onChanged: (v) => notifier.setForceTranscodeOnMobile(v),
              )),
            ]),
            _section('存储', [
              _row('缓存管理', onTap: () {
                Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const CacheManagePage()));
              }),
              _row('悬浮歌词', onTap: () {
                Navigator.of(context).push(CupertinoPageRoute(
                    builder: (_) => const OverlayLyricsSettingsPage()));
              }),
            ]),
            _section('账号', [
              _row('服务器列表', onTap: () {
                Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const ServersPage()));
              }),
              _row('DLNA 设备', onTap: () {
                Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const DlnaDevicesPage()));
              }),
              _row('退出登录', onTap: () => _confirmLogout(context, ref)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.groupSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: DSText.assistant(title.toUpperCase()),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
            ),
            child: Column(
              children: ListTile.divideTiles(
                context: context,
                tiles: children,
                color: AppColors.darkDivider,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String title, {Widget? trailing, VoidCallback? onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: AppDimens.listItemHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(child: DSText(title)),
            if (trailing != null) trailing,
            if (onTap != null && trailing == null) const Icon(CupertinoIcons.chevron_right,
                color: AppColors.textAssistantDark, size: 16),
          ],
        ),
      ),
    );
  }

  void _showSleepPicker(BuildContext context, WidgetRef ref) {
    int currentIndex = 0;
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 280,
        color: AppColors.darkCard,
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  CupertinoButton(
                    onPressed: () {
                      ref.read(sleepTimerProvider.notifier).cancel();
                      Navigator.pop(context);
                    },
                    child: const DSText('关闭'),
                  ),
                  const Spacer(),
                  CupertinoButton(
                    onPressed: () {
                      ref.read(sleepTimerProvider.notifier)
                          .start(AppConstants.sleepOptions[currentIndex]);
                      Navigator.pop(context);
                    },
                    child: const DSText('确定'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 32,
                onSelectedItemChanged: (i) => currentIndex = i,
                children: [
                  for (final m in AppConstants.sleepOptions) Center(child: DSText('$m 分钟')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const DSText('退出登录'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: DSText('确定退出当前账号？'),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const DSText('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).popUntil((r) => r.isFirst);
              }
            },
            child: const DSText('确定'),
          ),
        ],
      ),
    );
  }
}
