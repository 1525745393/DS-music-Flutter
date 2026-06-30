import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_auth.dart';
import '../api/api_info.dart';
import '../api/audio_station_api.dart';
import '../api/dio_client.dart';
import '../api/download_api.dart';
import '../api/quickconnect.dart';
import '../model/server_config.dart';
import '../repository/auth_repository.dart';
import '../repository/library_repository.dart';

/// SharedPreferences 全局单例
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('必须在 main() 中 override');
});

/// 当前激活的服务器配置（null 表示未连接）
final currentServerProvider = StateProvider<ServerConfig?>((ref) => null);

/// 全局 Dio 客户端（依赖当前服务器）
final dioClientProvider = Provider<DioClient?>((ref) {
  final server = ref.watch(currentServerProvider);
  if (server == null) return null;
  final c = DioClient(baseUrl: server.baseUrl);
  // 恢复持久化的 SID
  final sp = ref.read(sharedPreferencesProvider);
  c.sid = sp.getString('ds_sid');
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
  final api = DownloadApi(audio);
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
