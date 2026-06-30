import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/ds_text.dart';
import '../../l10n/app_strings.dart';
import '../../player/equalizer_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';

/// 均衡器 UI
/// 关键能力：
/// 1. 总开关
/// 2. 预设下拉（Normal / Classical / Dance / Flat 等）
/// 3. 10 段频段推子（milliBel 单位的双值进度展示）
class EqualizerPage extends ConsumerWidget {
  const EqualizerPage({super.key});

  static const _presets = <_PresetInfo>[
    _PresetInfo(0, 'Normal'),
    _PresetInfo(1, 'Classical'),
    _PresetInfo(2, 'Dance'),
    _PresetInfo(3, 'Flat'),
    _PresetInfo(4, 'Folk'),
    _PresetInfo(5, 'Heavy Metal'),
    _PresetInfo(6, 'Hip Hop'),
    _PresetInfo(7, 'Jazz'),
    _PresetInfo(8, 'Pop'),
    _PresetInfo(9, 'Rock'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eq = ref.watch(equalizerProvider);
    final notifier = ref.read(equalizerProvider.notifier);
    final bands = eq.bandFrequencies;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.darkBg,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: AppColors.darkBg,
        border: Border(),
        middle: DSText('均衡器'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            // 1. 总开关
            _section('开关', [
              _row('启用均衡器', trailing: CupertinoSwitch(
                value: eq.enabled,
                onChanged: (v) => notifier.setEnabled(v),
              )),
            ]),
            // 2. 预设
            _section('预设', [
              _row('当前预设', trailing: DSText.assistant(_presetsName(eq.preset))),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _presets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final p = _presets[i];
                  final selected = eq.preset == p.id;
                  return GestureDetector(
                    onTap: () => notifier.setPreset(p.id),
                    child: Container(
                      width: 80,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.accent.withOpacity(0.18)
                            : AppColors.darkCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? AppColors.accent
                              : AppColors.darkDivider,
                          width: 0.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: DSText(
                        p.name,
                        color: selected
                            ? AppColors.accent
                            : AppColors.textPrimaryDark,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // 3. 频段推子
            if (bands.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: DSText.assistant('当前设备不支持均衡器'),
                ),
              )
            else
              _section('频段', [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (int i = 0; i < bands.length; i++) ...[
                        Expanded(
                          child: _bandSlider(
                            i,
                            bands[i],
                            eq.bandGains.length > i ? eq.bandGains[i] : 0,
                            eq.minGain.toDouble(),
                            eq.maxGain.toDouble(),
                            notifier,
                          ),
                        ),
                        if (i < bands.length - 1) const SizedBox(width: 4),
                      ],
                    ],
                  ),
                ),
                // 重置按钮
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: CupertinoButton(
                    onPressed: () {
                      for (int i = 0; i < bands.length; i++) {
                        notifier.setBandGain(i, 0);
                      }
                    },
                    child: const DSText('重置为 0 dB'),
                  ),
                ),
              ]),
          ],
        ),
      ),
    );
  }

  String _presetsName(int id) {
    if (id < 0 || id >= _presets.length) return 'Normal';
    return _presets[id].name;
  }

  Widget _bandSlider(
    int idx,
    int freqHz,
    int gainMilliBel,
    double minVal,
    double maxVal,
    EqualizerNotifier notifier,
  ) {
    // 频段标签：> 1000 显示 kHz，否则 Hz
    final freqLabel = freqHz >= 1000
        ? '${(freqHz / 1000).toStringAsFixed(freqHz % 1000 == 0 ? 0 : 1)}k'
        : '$freqHz';
    // 增益显示：dB，milliBel / 100
    final gainDb = (gainMilliBel / 100).toStringAsFixed(1);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: CupertinoSlider(
              value: gainMilliBel.toDouble().clamp(minVal, maxVal),
              min: minVal,
              max: maxVal,
              activeColor: AppColors.accent,
              onChanged: (v) => notifier.setBandGain(idx, v.toInt()),
            ),
          ),
        ),
        const SizedBox(height: 4),
        DSText.assistant('$gainDb dB', color: AppColors.textAssistantDark),
        const SizedBox(height: 2),
        DSText.assistant(freqLabel, color: AppColors.accent),
      ],
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
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String title, {Widget? trailing}) {
    return Container(
      height: AppDimens.listItemHeight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: DSText(title)),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}

class _PresetInfo {
  final int id;
  final String name;
  const _PresetInfo(this.id, this.name);
}
