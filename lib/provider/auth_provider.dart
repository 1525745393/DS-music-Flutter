import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/server_config.dart';
import '../utils/network_utils.dart';
import 'core_providers.dart';

/// 服务器列表状态
class ServersNotifier extends StateNotifier<List<ServerConfig>> {
  final Ref _ref;
  ServersNotifier(this._ref) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final repo = _ref.read(authRepositoryProvider);
    state = await repo.loadServers();
  }

  Future<void> add(ServerConfig server) async {
    final repo = _ref.read(authRepositoryProvider);
    await repo.addServer(server);
    state = await repo.loadServers();
  }

  Future<void> remove(String id) async {
    final repo = _ref.read(authRepositoryProvider);
    await repo.removeServer(id);
    state = await repo.loadServers();
  }
}

final serversProvider =
    StateNotifierProvider<ServersNotifier, List<ServerConfig>>(
        (ref) => ServersNotifier(ref));

/// 当前登录态：未登录 / 登录中 / 已登录
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  final String message;
  const AuthLoading(this.message);
}

class AuthSuccess extends AuthState {
  final ServerConfig server;
  const AuthSuccess(this.server);
}

class AuthFailed extends AuthState {
  final String message;
  const AuthFailed(this.message);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  AuthNotifier(this._ref) : super(const AuthInitial());

  Future<void> login({
    required ServerConfig server,
    required String account,
    required String passwd,
    String? otpCode,
  }) async {
    state = const AuthLoading('正在连接服务器…');
    try {
      // 1. 切换当前服务器
      _ref.read(currentServerProvider.notifier).state = server;
      // 等一帧让 dioClient 重建
      await Future.delayed(const Duration(milliseconds: 50));

      final repo = _ref.read(libraryRepositoryProvider);
      final sid = await repo.login(
        config: server,
        account: account,
        passwd: passwd,
        otpCode: otpCode,
      );
      // 持久化
      final sp = _ref.read(sharedPreferencesProvider);
      await sp.setString('ds_sid', sid);
      await sp.setString('ds_account', account);
      await _ref.read(authRepositoryProvider).setCurrentServer(server.id);

      state = AuthSuccess(server);
    } catch (e) {
      state = AuthFailed(e.toString());
      // 失败时回滚
      _ref.read(currentServerProvider.notifier).state = null;
    }
  }

  Future<void> logout() async {
    final repo = _ref.read(libraryRepositoryProvider);
    try {
      await repo.logout();
    } catch (_) {}
    final sp = _ref.read(sharedPreferencesProvider);
    await sp.remove('ds_sid');
    _ref.read(currentServerProvider.notifier).state = null;
    state = const AuthInitial();
  }

  /// 静默重登：401 触发
  Future<bool> silentReLogin({
    required String account,
    required String passwd,
  }) async {
    final server = _ref.read(currentServerProvider);
    if (server == null) return false;
    try {
      final repo = _ref.read(libraryRepositoryProvider);
      final sid =
          await repo.login(config: server, account: account, passwd: passwd);
      final sp = _ref.read(sharedPreferencesProvider);
      await sp.setString('ds_sid', sid);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier(ref));

/// 是否已登录（仅作判断）
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider) is AuthSuccess;
});
