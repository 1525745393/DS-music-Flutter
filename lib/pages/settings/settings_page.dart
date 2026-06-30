import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/ds_text.dart';
import '../../constants/app_constants.dart';
import '../../l10n/app_strings.dart';
import '../../player/sleep_timer.dart';
import '../../provider/auth_provider.dart';
import '../../provider/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../cache/cache_manage_page.dart';
import '../dlna/dlna_devices_page.dart';
import '../equalizer/equalizer_page.dart';
import '../overlay_lyrics/overlay_lyrics_settings_page.dart';
import '../servers/servers_page.dart';
import 'transcode_picker_page.dart';
import 'locale_picker_page.dart';

/// 设置页：iOS 分组列表
/// 关键变更（A4）：所有硬编码中文字符串已切换为 [context.s.xxx]，
/// 切换语言后立即生效。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final sleep = ref.watch(sleepTimerProvider);
    final t = context.s; // 本地字符串

    return CupertinoPageScaffold(
      backgroundColor: AppColors.darkBg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.darkBg,
        border: const Border(),
        middle: DSText(t.settings),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            _section(context, t.appearance, [
              _row(context, t.followSystemTheme, trailing: CupertinoSwitch(
                value: s.followSystemTheme,
                onChanged: (v) => notifier.setFollowSystemTheme(v),
              )),
              _row(context, t.darkMode, trailing: CupertinoSwitch(
                value: s.isDark,
                onChanged: (v) => notifier.setDark(v),
              )),
              _row(context, '语言', trailing: DSText.assistant(_localeLabel(context, s.localeCode)), onTap: () {
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (_) => const LocalePickerPage(),
                ));
              }),
            ]),
            _section(context, t.playback, [
              _row(context, t.gapless, trailing: CupertinoSwitch(
                value: s.gaplessEnabled,
                onChanged: (v) => notifier.setGapless(v),
              )),
              _row(context, t.volumeNormalize, trailing: CupertinoSwitch(
                value: s.normalizeVolume,
                onChanged: (v) => notifier.setNormalize(v),
              )),
              _row(context, '外网强制无损', trailing: CupertinoSwitch(
                value: s.forceLossless,
                onChanged: (v) => notifier.setForceLossless(v),
              )),
              _row(context, t.equalizer, trailing: CupertinoSwitch(
                value: s.equalizerEnabled,
                onChanged: (v) => notifier.setEqEnabled(v),
              )),
              _row(context, '均衡器调节', trailing: const Icon(CupertinoIcons.chevron_right,
                  color: AppColors.textAssistantDark, size: 16), onTap: () {
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (_) => const EqualizerPage(),
                ));
              }),
              _row(context, t.sleepTimer,
                  trailing: DSText.assistant(sleep.inMinutes == 0
                      ? t.close : '${sleep.inMinutes} 分钟'),
                  onTap: () => _showSleepPicker(context, ref)),
            ]),
            _section(context, '转码设置', [
              _row(context, '格式', trailing: DSText.assistant(s.transcodeFormat), onTap: () {
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (_) => const TranscodePickerPage(type: TranscodePickerType.format),
                ));
              }),
              _row(context, '码率', trailing: DSText.assistant('${s.transcodeBitrate ~/ 1000} kbps'), onTap: () {
                Navigator.of(context).push(CupertinoPageRoute(
                  builder: (_) => const TranscodePickerPage(type: TranscodePickerType.bitrate),
                ));
              }),
              _row(context, '移动网络强制转码', trailing: CupertinoSwitch(
                value: s.forceTranscodeOnMobile,
                onChanged: (v) => notifier.setForceTranscodeOnMobile(v),
              )),
            ]),
            _section(context, t.storage, [
              _row(context, t.cacheManagement, onTap: () {
                Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const CacheManagePage()));
              }),
              _row(context, '悬浮歌词', onTap: () {
                Navigator.of(context).push(CupertinoPageRoute(
                    builder: (_) => const OverlayLyricsSettingsPage()));
              }),
            ]),
            _section(context, t.accountGroup, [
              _row(context, t.servers, onTap: () {
                Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const ServersPage()));
              }),
              _row(context, t.dlnaDevices, onTap: () {
                Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const DlnaDevicesPage()));
              }),
              _row(context, t.logout, onTap: () => _confirmLogout(context, ref)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
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

  Widget _row(BuildContext context, String title, {Widget? trailing, VoidCallback? onTap}) {
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

  String _localeLabel(BuildContext context, String code) {
    final t = context.s;
    switch (code) {
      case 'zh': return '简体中文';
      case 'en': return 'English';
      default: return t.followSystemTheme; // 复用 "跟随系统" 含义相近
    }
  }

  void _showSleepPicker(BuildContext context, WidgetRef ref) {
    int currentIndex = 0;
    final t = context.s;
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
                    child: DSText(t.close),
                  ),
                  const Spacer(),
                  CupertinoButton(
                    onPressed: () {
                      ref.read(sleepTimerProvider.notifier)
                          .start(AppConstants.sleepOptions[currentIndex]);
                      Navigator.pop(context);
                    },
                    child: DSText(t.confirm),
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
    final t = context.s;
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: DSText(t.logout),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: DSText('确定退出当前账号？'),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: DSText(t.cancel),
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
            child: DSText(t.confirm),
          ),
        ],
      ),
    );
  }
}
