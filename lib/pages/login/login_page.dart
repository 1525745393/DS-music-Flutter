import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/quickconnect.dart';
import '../../constants/api_constants.dart';
import '../../l10n/app_strings.dart';
import '../../model/server_config.dart';
import '../../provider/auth_provider.dart';
import '../../provider/core_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/logger.dart';
import '../../components/buttons/ds_button.dart';
import '../../components/ds_text.dart';

/// 登录连接页
/// 支持三种模式：内网直连 / DDNS 域名 / QuickConnect
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  ServerMode _mode = ServerMode.lan;
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '5000');
  final _accountCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _useHttps = false;
  bool _useQuickConnect = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _accountCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    final t = context.s;
    final account = _accountCtrl.text.trim();
    final passwd = _passwordCtrl.text;
    if (account.isEmpty || passwd.isEmpty) {
      _showAlert(t.pleaseFillAccount);
      return;
    }
    ServerConfig config;
    try {
      config = _buildConfig();
    } catch (e) {
      _showAlert(e.toString());
      return;
    }

    // QuickConnect 模式：先解析
    if (_mode == ServerMode.quickConnect) {
      try {
        final qc = ref.read(quickConnectProvider);
        final open = await qc.open(config.host);
        final sessionId = open['session_id'] as String? ?? '';
        if (sessionId.isEmpty) {
          _showAlert(t.qcResolveFailed);
          return;
        }
        _showAlert(t.qcWaitAuthorize, title: t.tip);
        final poll = await qc.poll(
          qcId: config.host,
          sessionId: sessionId,
        );
        if (poll == null) {
          _showAlert(t.qcTimeout);
          return;
        }
        final baseUrl = qc.resolveBaseUrl(poll);
        if (baseUrl == null) {
          _showAlert(t.qcRouteFailed);
          return;
        }
        // 覆写为解析出的 host/port
        final uri = Uri.parse(baseUrl);
        config = config.copyWith(
          host: uri.host,
          port: uri.port,
          useHttps: uri.scheme == 'https',
        );
      } catch (e) {
        _showAlert(e.toString());
        return;
      }
    }

    // 保存服务器
    final serversNotifier = ref.read(serversProvider.notifier);
    await serversNotifier.add(config);

    // 登录
    await ref.read(authStateProvider.notifier).login(
          server: config,
          account: account,
          passwd: passwd,
        );

    if (!mounted) return;
    final state = ref.read(authStateProvider);
    if (state is AuthFailed) {
      _showAlert(state.message);
    }
  }

  ServerConfig _buildConfig() {
    final t = context.s;
    final host = _hostCtrl.text.trim();
    if (host.isEmpty) {
      throw _mode == ServerMode.quickConnect
          ? t.pleaseFillQcId
          : t.pleaseFillServer;
    }
    final port = int.tryParse(_portCtrl.text.trim()) ??
        (_useHttps
            ? ApiConstants.defaultHttpsPort
            : ApiConstants.defaultHttpPort);
    return ServerConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: host,
      mode: _mode,
      host: host,
      port: _mode == ServerMode.quickConnect ? 0 : port,
      useHttps: _mode == ServerMode.ddns ? true : _useHttps,
    );
  }

  void _showAlert(String message, {String? title}) {
    final t = context.s;
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: DSText(title ?? t.tip),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: DSText(message),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: DSText(t.confirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.s;
    final state = ref.watch(authStateProvider);
    final loading = state is AuthLoading;
    return CupertinoPageScaffold(
      backgroundColor: AppColors.darkBg,
      child: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: AppDimens.pagePaddingH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Center(
                child: Text(t.appName,
                    style: AppTextStyles.largeTitle.copyWith(
                      color: AppColors.textPrimaryDark,
                      fontSize: 28,
                    )),
              ),
              const SizedBox(height: 8),
              Center(
                child: DSText.assistant(t.connectToNas),
              ),
              const SizedBox(height: 32),
              _modeSelector(),
              const SizedBox(height: 24),
              if (_mode != ServerMode.quickConnect) _hostField(),
              if (_mode != ServerMode.quickConnect) const SizedBox(height: 16),
              if (_mode != ServerMode.quickConnect) _portField(),
              if (_mode != ServerMode.quickConnect) const SizedBox(height: 12),
              if (_mode == ServerMode.lan) _httpsToggle(),
              if (_mode == ServerMode.quickConnect) _qcField(),
              const SizedBox(height: 24),
              _accountField(),
              const SizedBox(height: 16),
              _passwordField(),
              const SizedBox(height: 40),
              DSButton(
                text: loading ? t.loggingIn : t.login,
                fullWidth: true,
                loading: loading,
                onPressed: loading ? null : _doLogin,
              ),
              const SizedBox(height: 24),
              if (state is AuthLoading)
                Center(
                  child: DSText.assistant(state.message),
                ),
              const SizedBox(height: 16),
              Center(
                child: DSText.assistant(
                  t.agree,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeSelector() {
    final t = context.s;
    Widget chip(String text, ServerMode mode) {
      final selected = _mode == mode;
      return GestureDetector(
        onTap: () => setState(() => _mode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : AppColors.darkElevated,
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          ),
          child: DSText(
            text,
            color:
                selected ? CupertinoColors.white : AppColors.textSecondaryDark,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        chip(t.modeLan, ServerMode.lan),
        chip(t.modeDdns, ServerMode.ddns),
        chip(t.quickConnect, ServerMode.quickConnect),
      ],
    );
  }

  Widget _hostField() {
    final t = context.s;
    return _input(
      label: t.server,
      controller: _hostCtrl,
      hint: _mode == ServerMode.lan ? '192.168.1.100' : 'nas.example.com',
      keyboardType: TextInputType.url,
    );
  }

  Widget _qcField() {
    final t = context.s;
    return _input(
      label: t.quickConnect,
      controller: _hostCtrl,
      hint: 'ABCDEFG',
    );
  }

  Widget _portField() {
    final t = context.s;
    return _input(
      label: t.port,
      controller: _portCtrl,
      hint: '5000',
      keyboardType: TextInputType.number,
    );
  }

  Widget _accountField() {
    final t = context.s;
    return _input(
      label: t.account,
      controller: _accountCtrl,
      hint: t.hintAccount,
      keyboardType: TextInputType.text,
    );
  }

  Widget _passwordField() {
    final t = context.s;
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        _input(
          label: t.password,
          controller: _passwordCtrl,
          hint: t.hintPassword,
          obscure: _obscurePassword,
        ),
        CupertinoButton(
          padding: const EdgeInsets.only(right: 12),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          child: Icon(
            _obscurePassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
            color: AppColors.textAssistantDark,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _httpsToggle() {
    final t = context.s;
    return Row(
      children: [
        Expanded(child: DSText(t.useHttps)),
        CupertinoSwitch(
          value: _useHttps,
          onChanged: (v) {
            setState(() {
              _useHttps = v;
              _portCtrl.text = v
                  ? ApiConstants.defaultHttpsPort.toString()
                  : ApiConstants.defaultHttpPort.toString();
            });
          },
        ),
      ],
    );
  }

  Widget _input({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DSText.assistant(label),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: controller,
          placeholder: hint,
          obscureText: obscure,
          keyboardType: keyboardType,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          style: const TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 15,
          ),
          decoration: BoxDecoration(
            color: AppColors.darkElevated,
            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
          ),
        ),
      ],
    );
  }
}
