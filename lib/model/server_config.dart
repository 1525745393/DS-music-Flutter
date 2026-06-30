/// 服务器配置：内网、DDNS、QuickConnect 三种模式
enum ServerMode { lan, ddns, quickConnect }

class ServerConfig {
  final String id;
  final String name;
  final ServerMode mode;
  final String host; // 内网 IP / 域名 / QuickConnect ID
  final int port; // 内网/域名模式下必填
  final bool useHttps; // 启用 HTTPS（自签证书）
  final String? account; // 已保存的账号（可为空）
  final bool isDefault;

  const ServerConfig({
    required this.id,
    required this.name,
    required this.mode,
    required this.host,
    required this.port,
    required this.useHttps,
    this.account,
    this.isDefault = false,
  });

  /// 构造基础 URL：协议://host:port
  String get baseUrl {
    final scheme = useHttps ? 'https' : 'http';
    return '$scheme://$host:$port';
  }

  /// QuickConnect 模式在使用时才解析具体 baseUrl
  bool get needsResolve => mode == ServerMode.quickConnect;

  ServerConfig copyWith({
    String? id,
    String? name,
    ServerMode? mode,
    String? host,
    int? port,
    bool? useHttps,
    String? account,
    bool? isDefault,
  }) {
    return ServerConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      host: host ?? this.host,
      port: port ?? this.port,
      useHttps: useHttps ?? this.useHttps,
      account: account ?? this.account,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mode': mode.index,
        'host': host,
        'port': port,
        'useHttps': useHttps,
        'account': account,
        'isDefault': isDefault,
      };

  factory ServerConfig.fromJson(Map<String, dynamic> json) => ServerConfig(
        id: json['id'] as String,
        name: json['name'] as String,
        mode: ServerMode.values[json['mode'] as int],
        host: json['host'] as String,
        port: json['port'] as int,
        useHttps: json['useHttps'] as bool,
        account: json['account'] as String?,
        isDefault: (json['isDefault'] as bool?) ?? false,
      );
}
