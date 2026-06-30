import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/buttons/ds_button.dart';
import '../../components/ds_text.dart';
import '../../l10n/app_strings.dart';
import '../../player/overlay_lyrics_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';

/// 悬浮歌词设置：字号 + 位置预设
class OverlayLyricsSettingsPage extends ConsumerStatefulWidget {
  const OverlayLyricsSettingsPage({super.key});

  @override
  ConsumerState<OverlayLyricsSettingsPage> createState() =>
      _OverlayLyricsSettingsPageState();
}

enum OverlayGravity { top, middle, bottom }

extension _GravityX on OverlayGravity {
  String get label {
    switch (this) {
      case OverlayGravity.top:
        return '顶部';
      case OverlayGravity.middle:
        return '居中';
      case OverlayGravity.bottom:
        return '底部';
    }
  }
}

class _OverlayLyricsSettingsPageState
    extends ConsumerState<OverlayLyricsSettingsPage> {
  double _fontSize = 18;
  OverlayGravity _gravity = OverlayGravity.bottom;
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _enabled = OverlayLyricsController.instance.isShowing;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.darkBg,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: AppColors.darkBg,
        border: Border(),
        middle: DSText('悬浮歌词'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            _section('开关', [
              _row('启用悬浮歌词',
                  trailing: CupertinoSwitch(
                    value: _enabled,
                    onChanged: (v) async {
                      setState(() => _enabled = v);
                      if (v) {
                        // 提示用户先开启系统层叠权限
                        await OverlayLyricsController.instance.resetPosition();
                      }
                    },
                  )),
            ]),
            _section('字号 (${_fontSize.toStringAsFixed(0)})', [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: CupertinoSlider(
                  min: 12,
                  max: 36,
                  value: _fontSize,
                  onChanged: (v) => setState(() => _fontSize = v),
                  onChangeEnd: (v) =>
                      OverlayLyricsController.instance.setFontSize(v),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DSText.assistant('12'),
                    DSText.assistant('当前：${_fontSize.toStringAsFixed(0)}'),
                    DSText.assistant('36'),
                  ],
                ),
              ),
            ]),
            _section('位置', [
              for (final g in OverlayGravity.values)
                _row(g.label,
                    trailing: _gravity == g
                        ? const Icon(CupertinoIcons.checkmark,
                            color: AppColors.accent)
                        : null, onTap: () {
                  setState(() => _gravity = g);
                  // 通过 resetPosition 让原生层重新落位
                  OverlayLyricsController.instance.resetPosition();
                }),
            ]),
            _section('操作', [
              _row('重置为默认位置', onTap: () {
                OverlayLyricsController.instance.resetPosition();
                setState(() => _gravity = OverlayGravity.bottom);
              }),
            ]),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DSText.assistant(
                '提示：开启悬浮歌词后，可在系统层叠权限中允许 DS Player 显示在其他应用上方。',
                color: AppColors.textAssistantDark,
              ),
            ),
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
              children: _buildWithDividers(children),
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
            if (onTap != null && trailing == null)
              const Icon(CupertinoIcons.chevron_right,
                  color: AppColors.textAssistantDark, size: 16),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWithDividers(List<Widget> children) {
    if (children.isEmpty) return children;
    final result = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(Container(
          margin: const EdgeInsets.only(left: 16),
          height: 0.5,
          color: AppColors.darkDivider,
        ));
      }
    }
    return result;
  }
}
