import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/ds_state_page.dart';
import '../../components/ds_text.dart';
import '../../player/dlna_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';

/// DLNA MediaServer 浏览页
/// 关键能力：进入目录/歌曲列表，点击歌曲投屏到当前 Renderer
class DlnaBrowsePage extends ConsumerStatefulWidget {
  final DlnaController controller;
  const DlnaBrowsePage({super.key, required this.controller});

  @override
  ConsumerState<DlnaBrowsePage> createState() => _DlnaBrowsePageState();
}

class _DlnaBrowsePageState extends ConsumerState<DlnaBrowsePage> {
  String? _currentObjectId; // null = 根
  String _title = 'MediaServer';
  List<DlnaMediaItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load(null);
  }

  Future<void> _load(String? objectId) async {
    setState(() => _loading = true);
    final result = await widget.controller.browse(objectId: objectId ?? '0');
    if (!mounted) return;
    setState(() {
      _items = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.darkBg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.darkBg.withOpacity(0.85),
        border: const Border(),
        middle: DSText(_title),
      ),
      child: SafeArea(
        child: _loading
            ? const Center(child: CupertinoActivityIndicator())
            : _items.isEmpty
                ? const DSStatePage(
                    type: StateType.empty,
                    message: '此目录为空或当前 MediaServer 不支持 Browse 协议',
                    icon: CupertinoIcons.folder,
                  )
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => Container(
                      margin: const EdgeInsets.only(left: 56),
                      height: 0.5,
                      color: AppColors.darkDivider,
                    ),
                    itemBuilder: (_, i) => _item(_items[i]),
                  ),
      ),
    );
  }

  Widget _item(DlnaMediaItem item) {
    final isContainer = item.isContainer;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (isContainer) {
          setState(() => _title = item.title);
          _load(item.id);
        } else {
          // 投屏该音频资源
          if (item.resourceUrl == null) return;
          // 简化：直接调用 renderer.play 端
          showCupertinoDialog(
            context: context,
            builder: (_) => CupertinoAlertDialog(
              title: const DSText('投屏'),
              content: DSText('将 "${item.title}" 投屏到当前 Renderer'),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context),
                  child: const DSText('取消'),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      // ignore: avoid_dynamic_calls
                      await (widget.controller.selectedRenderer as dynamic)
                          .setAVTransportURI(item.resourceUrl!, item.title);
                      // ignore: avoid_dynamic_calls
                      await (widget.controller.selectedRenderer as dynamic)
                          .play();
                    } catch (e) {
                      // 静默失败
                    }
                  },
                  child: const DSText('投屏'),
                ),
              ],
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              isContainer
                  ? CupertinoIcons.folder_fill
                  : CupertinoIcons.music_note,
              color:
                  isContainer ? AppColors.accent : AppColors.textAssistantDark,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DSText(item.title),
                  if (isContainer && item.childrenCount > 0) ...[
                    const SizedBox(height: 2),
                    DSText.assistant('${item.childrenCount} 项'),
                  ],
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right,
                color: AppColors.textAssistantDark, size: 16),
          ],
        ),
      ),
    );
  }
}
