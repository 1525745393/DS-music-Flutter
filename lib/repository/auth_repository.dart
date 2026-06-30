import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';
import '../model/exception.dart';
import '../model/server_config.dart';
import '../utils/logger.dart';

/// 鉴权仓库：管理服务器列表、当前选中服务器、登录 SID
class AuthRepository {
  final SharedPreferences _sp;
  AuthRepository(this._sp);

  // —— 服务器列表 ——
  Future<List<ServerConfig>> loadServers() async {
    final raw = _sp.getString(StorageKeys.serverList);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map(ServerConfig.fromJson).toList();
    } catch (e) {
      AppLogger.e('解析服务器列表失败', e);
      return [];
    }
  }

  Future<void> saveServers(List<ServerConfig> servers) async {
    final encoded = jsonEncode(servers.map((e) => e.toJson()).toList());
    await _sp.setString(StorageKeys.serverList, encoded);
  }

  Future<void> addServer(ServerConfig server) async {
    final list = await loadServers();
    // 同一 host+port 视为同一服务器，避免重复
    list.removeWhere((e) => e.host == server.host && e.port == server.port);
    list.add(server);
    await saveServers(list);
  }

  Future<void> removeServer(String id) async {
    final list = await loadServers();
    list.removeWhere((e) => e.id == id);
    await saveServers(list);
  }

  Future<ServerConfig?> getCurrentServer() async {
    final id = _sp.getString(StorageKeys.currentServerId);
    if (id == null) return null;
    final list = await loadServers();
    try {
      return list.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> setCurrentServer(String id) async {
    await _sp.setString(StorageKeys.currentServerId, id);
  }

  // —— SID ——
  Future<String?> getSid() => _sp.getString(StorageKeys.sid);
  Future<void> setSid(String sid, {Duration? ttl}) async {
    await _sp.setString(StorageKeys.sid, sid);
    if (ttl != null) {
      final expireAt = DateTime.now().add(ttl).millisecondsSinceEpoch;
      await _sp.setInt(StorageKeys.sidExpire, expireAt);
    }
  }

  Future<bool> isSidValid() async {
    final sid = await getSid();
    if (sid == null || sid.isEmpty) return false;
    final exp = _sp.getInt(StorageKeys.sidExpire) ?? 0;
    if (exp == 0) return true;
    return DateTime.now().millisecondsSinceEpoch < exp;
  }

  Future<void> clearSid() async {
    await _sp.remove(StorageKeys.sid);
    await _sp.remove(StorageKeys.sidExpire);
  }

  Future<String?> getLastAccount() => _sp.getString(StorageKeys.account);
  Future<void> setLastAccount(String account) =>
      _sp.setString(StorageKeys.account, account);
}
