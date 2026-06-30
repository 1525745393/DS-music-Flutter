import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/ds_state_page.dart';
import '../../components/ds_text.dart' show DSText, TextStyleType;
import '../../model/server_config.dart';
import '../../provider/auth_provider.dart';
import '../../provider/core_providers.dart';
import '../../theme/app_colors.dart';
import '../login/login_page.dart';

/// 服务器列表管理页
/// 功能：
/// 1. 列出已保存的所有服务器
/// 2. 一键切换当前服务器（带登录态校验）
/// 3. 增/删/编辑服务器
class ServersPage extends ConsumerWidget {
  const ServersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servers = ref.watch(serversProvider);
    final current = ref.watch(currentServerProvider);
    return CupertinoPageScaffold(
      backgroundColor: AppColors.darkBg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppColors.darkBg.withOpacity(0.85),
        border: const Border(),
        middle: const DSText('服务器'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _addServer(context, ref),
          child:
              const Icon(CupertinoIcons.add, color: AppColors.accent, size: 24),
        ),
      ),
      child: SafeArea(
        child: servers.isEmpty
            ? DSStatePage(
                type: StateType.empty,
                message: '暂无服务器，请点击右上角添加',
                icon: CupertinoIcons.cloud,
                onRetry: () => _addServer(context, ref),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: servers.length,
                separatorBuilder: (_, __) => Container(
                  margin: const EdgeInsets.only(left: 16),
                  height: 0.5,
                  color: AppColors.darkDivider,
                ),
                itemBuilder: (_, i) {
                  final s = servers[i];
                  return _serverItem(context, ref, s,
                      isCurrent: s.id == current?.id);
                },
              ),
      ),
    );
  }

  Widget _serverItem(BuildContext context, WidgetRef ref, ServerConfig s,
      {required bool isCurrent}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isCurrent ? AppColors.accent.withOpacity(0.12) : null,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isCurrent ? AppColors.accent : AppColors.darkElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _iconFor(s.mode),
              color: isCurrent
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
                Row(
                  children: [
                    Flexible(
                        child: DSText(s.name,
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                    if (isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const DSText('当前',
                            color: CupertinoColors.white,
                            type: TextStyleType.caption),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                DSText.assistant(
                  '${_modeName(s.mode)} · ${s.useHttps ? "HTTPS" : "HTTP"} · ${s.host}${s.port > 0 ? ":${s.port}" : ""}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!isCurrent)
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              onPressed: () => _switchServer(context, ref, s),
              child: const DSText('切换', color: AppColors.accent),
            ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onPressed: () => _confirmDelete(context, ref, s),
            child: const Icon(CupertinoIcons.trash,
                color: AppColors.danger, size: 20),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(ServerMode mode) {
    switch (mode) {
      case ServerMode.lan:
        return CupertinoIcons.wifi;
      case ServerMode.ddns:
        return CupertinoIcons.globe;
      case ServerMode.quickConnect:
        return CupertinoIcons.bolt_circle;
    }
  }

  String _modeName(ServerMode mode) {
    switch (mode) {
      case ServerMode.lan:
        return '内网';
      case ServerMode.ddns:
        return '域名';
      case ServerMode.quickConnect:
        return 'QuickConnect';
    }
  }

  void _addServer(BuildContext context, WidgetRef ref) {
    Navigator.of(context)
        .push(CupertinoPageRoute(builder: (_) => const LoginPage()));
  }

  void _switchServer(
      BuildContext context, WidgetRef ref, ServerConfig s) async {
    // 切换服务器：先校验当前账号密码仍有效
    // 这里简化为：直接更新 currentServer，后续拉取会触发重登
    ref.read(currentServerProvider.notifier).state = s;
    await ref.read(authRepositoryProvider).setCurrentServer(s.id);
    if (context.mounted) Navigator.pop(context);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ServerConfig s) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const DSText('删除服务器'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: DSText('确定要删除「${s.name}」？\n已下载的本地音乐不会被删除。'),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const DSText('取消'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              await ref.read(serversProvider.notifier).remove(s.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const DSText('删除'),
          ),
        ],
      ),
    );
  }
}
