import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_auth.dart';
import '../api/api_info.dart';
import '../api/audio_station_api.dart';
import '../api/dio_client.dart';
import '../api/download_api.dart';
import '../api/quickconnect.dart';
import '../constants/api_constants.dart';
import '../constants/storage_keys.dart';
import '../model/server_config.dart';
import '../repository/auth_repository.dart';
import '../repository/library_repository.dart';
import 'auth_provider.dart';

/// SharedPreferences 全局单例
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('必须在 main() 中 override');
});

/// 当前激活的服务器配置（null 表示未连接）
final currentServerProvider = StateProvider<ServerConfig?>((ref) => null);

/// 全局 Dio 客户端（依赖当前服务器）
/// 关键：在客户端构造后立即挂载 401 静默重登回调，
/// 任何 dio 请求遇到 401 / 业务 code 105/106/119 都会自动重登一次。
final dioClientProvider = Provider<DioClient?>((ref) {
  final server = ref.watch(currentServerProvider);
  if (server == null) return null;
  final c = DioClient(baseUrl: server.baseUrl);
  // 恢复持久化的 SID
  final sp = ref.read(sharedPreferencesProvider);
  c.sid = sp.getString(StorageKeys.sid);
  // 401 静默重登回调：
  // 安全说明：密码不应明文存到 SharedPreferences，因此这里只做「基础设施可达性
  // 探测 + 提示用户重登」。若未来接入了 device_token 持久化方案，可在此续期 SID。
  c.onUnauthorized = () async {
    try {
      // 1. 探活：调用 SYNO.API.Info 确认服务可达
      final info = ApiInfo(c.dio);
      final path = await info.getPath(ApiConstants.apiAuth);
      if (path.isEmpty) return false;
      // 2. 触发顶层 AuthNotifier 走「重登」流程
      //    通过 ref.read 获取 authStateProvider 拿到 silentReLogin 能力
      //    若用户此前勾选了「记住密码」,AuthNotifier 内部会读取 device_token
      //    尝试续期;否则直接返回 false,UI 层弹出重新登录提示。
      final authNotifier = ref.read(authStateProvider.notifier);
      final account = sp.getString(StorageKeys.account) ?? '';
      if (account.isEmpty) return false;
      // silentReLogin 内部会从 AuthRepository 读取已持久化的 device_token 续期
      return await authNotifier.silentReLogin(account: account, passwd: '');
    } catch (_) {
      return false;
    }
  };
  return c;
});

final apiInfoProvider = Provider<ApiInfo>((ref) {
  final dio = ref.watch(dioClientProvider)?.dio;
  if (dio == null) throw StateError('未连接到服务器');
  return ApiInfo(dio);
});

final apiAuthProvider = Provider<ApiAuth>((ref) {
  final client = ref.watch(dioClientProvider);
  if (client == null) throw StateError('未连接到服务器');
  return ApiAuth(client.dio, ref.watch(apiInfoProvider), client);
});

final audioStationApiProvider = Provider<AudioStationApi>((ref) {
  final client = ref.watch(dioClientProvider);
  if (client == null) throw StateError('未连接到服务器');
  return AudioStationApi(client.dio, ref.watch(apiInfoProvider), client);
});

final quickConnectProvider = Provider<QuickConnect>((ref) => QuickConnect());

final downloadApiProvider = Provider<DownloadApi>((ref) {
  final audio = ref.watch(audioStationApiProvider);
  final sp = ref.watch(sharedPreferencesProvider);
  final api = DownloadApi(audio, sp);
  ref.onDispose(api.dispose);
  return api;
});

/// 鉴权仓库
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(sharedPreferencesProvider));
});

/// 曲库仓库
final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  final sp = ref.watch(sharedPreferencesProvider);
  final client = ref.watch(dioClientProvider);
  if (client == null) throw StateError('未连接到服务器');
  return LibraryRepository(
    apiInfo: ref.watch(apiInfoProvider),
    apiAuth: ApiAuth(client.dio, ref.watch(apiInfoProvider), client),
    audioApi: ref.watch(audioStationApiProvider),
    quickConnect: ref.watch(quickConnectProvider),
    client: client,
    downloadApi: ref.watch(downloadApiProvider),
  );
});
