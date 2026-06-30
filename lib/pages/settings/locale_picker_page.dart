import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/ds_text.dart';
import '../../provider/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';

/// 语言切换页
/// 支持：跟随系统 / 简体中文 / English
/// 切换后立即生效（设置中监听 localeCode 即可）
class LocalePickerPage extends ConsumerWidget {
  const LocalePickerPage({super.key});

  static const _options = <_LocaleOption>[
    _LocaleOption('system', '跟随系统', null),
    _LocaleOption('zh', '简体中文', 'zh_CN'),
    _LocaleOption('en', 'English', 'en_US'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(settingsProvider).localeCode;
    final notifier = ref.read(settingsProvider.notifier);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.darkBg,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: AppColors.darkBg,
        border: Border(),
        middle: DSText('语言'),
      ),
      child: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: _options.length,
          separatorBuilder: (_, __) => Container(
            margin: const EdgeInsets.only(left: 56),
            height: 0.5,
            color: AppColors.darkDivider,
          ),
          itemBuilder: (_, i) {
            final opt = _options[i];
            final selected = opt.code == current;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                notifier.setLocaleCode(opt.code);
                Navigator.of(context).pop();
              },
              child: Container(
                height: AppDimens.listItemHeight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: DSText(opt.label)),
                    if (selected)
                      const Icon(CupertinoIcons.check_mark,
                          color: AppColors.accent, size: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LocaleOption {
  final String code; // 持久化 key
  final String label; // UI 显示
  final String? bcp47; // 真实 locale tag，给后续 flutter_localizations 用
  const _LocaleOption(this.code, this.label, this.bcp47);
}
