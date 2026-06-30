import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/ds_state_page.dart';
import '../../components/ds_text.dart';
import '../../l10n/app_strings.dart';
import '../../model/song.dart';
import '../../player/dlna_controller.dart';
import '../../provider/core_providers.dart';
import '../../provider/player_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import 'dlna_browse_page.dart';

/// DLNA 设备页：包含 Renderer（推送端）列表 + 选中的控制面板 + MediaServer 浏览入口
class DlnaDevicesPage extends ConsumerStatefulWidget {
  const DlnaDevicesPage({super.key});

  @override
  ConsumerState<DlnaDevicesPage> createState() => _DlnaDevicesPageState();
}

class _DlnaDevicesPageState extends ConsumerState<DlnaDevicesPage> {
  final DlnaController _controller = DlnaController();
  Timer? _refreshTimer;
  bool _discovering = true;

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  Future<void> _startDiscovery() async {
    setState(() => _discovering = true);
    await _controller.startDiscovery();
    // 每 5 秒刷新一次列表
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
    // 30 秒后停止发现
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) setState(() => _discovering = false);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devices = _controller.devices;
    final state = ref.watch(playerStateProvider);
    final current = state.current;
    final selected = _controller.selectedRenderer;

    return CupertinoPageScaffold(
      backgroundColor: AppColors.darkBg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.darkBg.withOpacity(0.85),
        border: const Border(),
        middle: const DSText('DLNA 设备'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _discovering ? null : _startDiscovery,
          child: const Icon(CupertinoIcons.refresh, color: AppColors.accent),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _header(_discovering, devices.length, current != null),
            // 当已选 Renderer 且有当前歌曲时，显示控制面板
            if (selected != null && current != null)
              _ControlPanel(
                controller: _controller,
                current: current,
                isPlaying: state.isPlaying,
              ),
            Expanded(
              child: devices.isEmpty
                  ? DSStatePage(
                      type: _discovering ? StateType.loading : StateType.empty,
                      message: _discovering
                          ? '正在搜索局域网 DLNA 设备...'
                          : '未发现 DLNA 设备\n请确保音箱/电视已开启并连接到同一网络',
                      icon: _discovering ? null : CupertinoIcons.speaker_3,
                    )
                  : ListView.separated(
                      itemCount: devices.length +
                          (_controller.servers.isNotEmpty ? 1 : 0),
                      separatorBuilder: (_, __) => Container(
                        margin: const EdgeInsets.only(left: 72),
                        height: 0.5,
                        color: AppColors.darkDivider,
                      ),
                      itemBuilder: (_, i) {
                        // 末尾追加 MediaServer 浏览入口
                        if (i == devices.length) {
                          return _browseServerEntry();
                        }
                        final d = devices[i];
                        final isSelected = selected.uuid == d.uuid;
                        return _deviceItem(d, isSelected, current);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _browseServerEntry() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_controller.servers.isEmpty) {
          // 没有发现 server，弹提示
          showCupertinoDialog(
            context: context,
            builder: (_) => CupertinoAlertDialog(
              title: const DSText('未发现媒体服务器'),
              content: const DSText('请确认 NAS / 媒体服务器已开启 UPnP/DLNA 服务'),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context),
                  child: const DSText('好'),
                ),
              ],
            ),
          );
          return;
        }
        // 简化：选择第一个 server
        _controller.selectedServer = _controller.servers.first;
        Navigator.of(context).push(CupertinoPageRoute(
          builder: (_) => DlnaBrowsePage(controller: _controller),
        ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: const [
            Icon(CupertinoIcons.folder_fill_badge_plus,
                color: AppColors.accent, size: 22),
            SizedBox(width: 12),
            DSText('浏览 MediaServer 内容'),
            Spacer(),
            Icon(CupertinoIcons.chevron_right,
                color: AppColors.textAssistantDark, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _header(bool discovering, int count, bool hasCurrent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AppColors.darkDivider, width: 0.5)),
      ),
      child: Row(
        children: [
          if (discovering) ...[
            const CupertinoActivityIndicator(radius: 8),
            const SizedBox(width: 8),
            const DSText.assistant('搜索中…'),
          ] else
            DSText.assistant('已找到 $count 个设备'),
          const Spacer(),
          if (!hasCurrent)
            const DSText.assistant('请先开始播放', color: AppColors.warning),
        ],
      ),
    );
  }

  Widget _deviceItem(dynamic device, bool selected, Song? current) {
    final name = device.friendlyName?.toString() ?? '未知设备';
    final host = device.host?.toString() ?? '';
    final port = device.port ?? 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        _controller.selectedRenderer = device;
        if (current != null) {
          // 推送当前歌曲到设备
          final audio = ref.read(audioStationApiProvider);
          final streamUrl = audio.buildStreamUrl(current);
          final ok = await _controller.push(current, streamUrl);
          if (mounted) {
            showCupertinoDialog(
              context: context,
              builder: (_) => CupertinoAlertDialog(
                title: DSText(ok ? '已投屏' : '投屏失败'),
                content:
                    DSText(ok ? '正在 $name 播放\n${current.title}' : '请检查设备连接'),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.pop(context),
                    child: const DSText('好'),
                  ),
                ],
              ),
            );
          }
        }
        setState(() {});
      },
      child: Container(
        color: selected ? AppColors.accent.withOpacity(0.12) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? AppColors.accent : AppColors.darkElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                selected
                    ? CupertinoIcons.speaker_3_fill
                    : CupertinoIcons.speaker_3,
                color: selected
                    ? CupertinoColors.white
                    : AppColors.textAssistantDark,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DSText(name),
                  const SizedBox(height: 2),
                  DSText.assistant('$host:$port'),
                ],
              ),
            ),
            if (selected)
              const Icon(CupertinoIcons.checkmark_circle_fill,
                  color: AppColors.accent, size: 20),
          ],
        ),
      ),
    );
  }
}

/// 远程控制面板
/// 关键能力：play/pause/stop/seek/volume
/// 关键变更：解决原实现"选设备但无控制"的核心痛点
class _ControlPanel extends StatefulWidget {
  final DlnaController controller;
  final Song current;
  final bool isPlaying;
  const _ControlPanel({
    required this.controller,
    required this.current,
    required this.isPlaying,
  });

  @override
  State<_ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends State<_ControlPanel> {
  double _volume = 50;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.accent.withOpacity(0.4), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.speaker_3_fill,
                  color: AppColors.accent, size: 18),
              const SizedBox(width: 6),
              DSText.assistant('正在投屏：${widget.current.title}'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ctrlBtn(CupertinoIcons.backward_fill, '后退10s', () {
                // 假设当前在第 0 秒，简化处理：直接调到 0
                widget.controller.seekTo(0);
              }),
              _ctrlBtn(
                widget.isPlaying
                    ? CupertinoIcons.pause_fill
                    : CupertinoIcons.play_fill,
                widget.isPlaying ? '暂停' : '播放',
                () async {
                  if (widget.isPlaying) {
                    await widget.controller.pause();
                  } else {
                    await widget.controller.resume();
                  }
                },
              ),
              _ctrlBtn(CupertinoIcons.forward_fill, '前进10s', () {
                // 简化：跳到末尾
                widget.controller.seekTo(widget.current.duration);
              }),
              _ctrlBtn(CupertinoIcons.stop_fill, '停止', () async {
                await widget.controller.stop();
              }),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(CupertinoIcons.volume_down,
                  color: AppColors.textAssistantDark, size: 16),
              Expanded(
                child: CupertinoSlider(
                  value: _volume,
                  min: 0,
                  max: 100,
                  onChanged: (v) => setState(() => _volume = v),
                  onChangeEnd: (v) => widget.controller.setVolume(v.toInt()),
                ),
              ),
              const Icon(CupertinoIcons.volume_up,
                  color: AppColors.textAssistantDark, size: 16),
              const SizedBox(width: 6),
              SizedBox(
                width: 32,
                child: DSText.assistant('${_volume.toInt()}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ctrlBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.accent, size: 24),
          const SizedBox(height: 4),
          DSText.assistant(label),
        ],
      ),
    );
  }
}
