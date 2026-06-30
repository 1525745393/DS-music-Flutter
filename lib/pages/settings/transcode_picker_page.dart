import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/ds_text.dart';
import '../../provider/settings_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';

/// 转码选择页：可被复用于"格式"与"码率"两个入口
/// 设计：单一 [TranscodePickerPage] + [type] 参数，避免重复页面
class TranscodePickerPage extends ConsumerWidget {
  /// 区分两种选择类型
  final TranscodePickerType type;
  const TranscodePickerPage({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    // 选项表：label + value
    final List<TranscodeOption> options = switch (type) {
      TranscodePickerType.format => const [
          TranscodeOption('mp3', 'MP3（兼容最好）'),
          TranscodeOption('aac', 'AAC（iOS 原生）'),
          TranscodeOption('flac', 'FLAC（无损，体积大）'),
          TranscodeOption('original', '原始码流（不转码）'),
        ],
      TranscodePickerType.bitrate => const [
          TranscodeOption('128000', '128 kbps（低码率，省流量）'),
          TranscodeOption('192000', '192 kbps（标准）'),
          TranscodeOption('256000', '256 kbps（高质量）'),
          TranscodeOption('320000', '320 kbps（接近无损）'),
          TranscodeOption('0', '原始码率（不转码）'),
        ],
    };

    final currentValue = type == TranscodePickerType.format
        ? s.transcodeFormat
        : s.transcodeBitrate.toString();

    return CupertinoPageScaffold(
      backgroundColor: AppColors.darkBg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.darkBg.withOpacity(0.85),
        border: const Border(),
        middle: DSText(type == TranscodePickerType.format ? '转码格式' : '转码码率'),
      ),
      child: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: options.length,
          separatorBuilder: (_, __) => Container(
            margin: const EdgeInsets.only(left: 56),
            height: 0.5,
            color: AppColors.darkDivider,
          ),
          itemBuilder: (_, i) {
            final opt = options[i];
            final selected = opt.value == currentValue;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (type == TranscodePickerType.format) {
                  notifier.setTranscodeFormat(opt.value);
                } else {
                  notifier.setTranscodeBitrate(int.tryParse(opt.value) ?? 0);
                }
                Navigator.of(context).pop();
              },
              child: Container(
                height: AppDimens.listItemHeight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          DSText(opt.label),
                        ],
                      ),
                    ),
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

enum TranscodePickerType { format, bitrate }

class TranscodeOption {
  final String value;
  final String label;
  const TranscodeOption(this.value, this.label);
}
