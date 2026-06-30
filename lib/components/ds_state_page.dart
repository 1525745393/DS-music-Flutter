import 'package:flutter/cupertino.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import 'buttons/ds_button.dart';
import 'ds_text.dart';

/// 统一状态页：加载 / 空数据 / 错误
class DSStatePage extends StatelessWidget {
  final StateType type;
  final String? message;
  final VoidCallback? onRetry;
  final IconData? icon;

  const DSStatePage({
    super.key,
    required this.type,
    this.message,
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (type == StateType.loading)
              const CupertinoActivityIndicator(radius: 16)
            else if (type == StateType.empty || type == StateType.error)
              Icon(
                icon ?? _defaultIcon(),
                size: 64,
                color: AppColors.textAssistantDark,
              ),
            if (message != null) ...[
              const SizedBox(height: AppDimens.itemSpacing),
              DSText(
                message!,
                textAlign: TextAlign.center,
                color: AppColors.textAssistantDark,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppDimens.groupSpacing),
              DSButton(text: '重试', onPressed: onRetry),
            ],
          ],
        ),
      ),
    );
  }

  IconData _defaultIcon() {
    switch (type) {
      case StateType.empty:
        return CupertinoIcons.music_note_list;
      case StateType.error:
        return CupertinoIcons.exclamationmark_triangle;
      case StateType.loading:
        return CupertinoIcons.hourglass;
    }
  }
}

enum StateType { loading, empty, error }
