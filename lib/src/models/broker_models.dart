enum BrokerStatus { running, stopped, starting, error }

enum BrokerLogDirection { inbound, outbound, system }

enum NetworkMode { offline, wifi, hotspot, cellular, unknown }

extension BrokerStatusLabel on BrokerStatus {
  String get label => switch (this) {
    BrokerStatus.running => 'Running',
    BrokerStatus.stopped => 'Stopped',
    BrokerStatus.starting => 'Starting',
    BrokerStatus.error => 'Error',
  };
}

extension BrokerLogDirectionLabel on BrokerLogDirection {
  String get label => switch (this) {
    BrokerLogDirection.inbound => 'IN',
    BrokerLogDirection.outbound => 'OUT',
    BrokerLogDirection.system => 'SYSTEM',
  };
}

extension NetworkModeLabel on NetworkMode {
  String get label => switch (this) {
    NetworkMode.offline => 'Offline',
    NetworkMode.wifi => 'Wi-Fi',
    NetworkMode.hotspot => 'Hotspot',
    NetworkMode.cellular => 'Cellular',
    NetworkMode.unknown => 'Unknown',
  };
}

class BrokerNetworkSettings {
  const BrokerNetworkSettings({
    required this.port,
    required this.webSocketEnabled,
    required this.externalAccessEnabled,
    required this.localNetworkOnly,
    required this.hotspotModeSupport,
  });

  factory BrokerNetworkSettings.defaults({required int port}) {
    return BrokerNetworkSettings(
      port: port,
      webSocketEnabled: false,
      externalAccessEnabled: false,
      localNetworkOnly: true,
      hotspotModeSupport: true,
    );
  }

  factory BrokerNetworkSettings.fromJson(Map<String, dynamic> json) {
    return BrokerNetworkSettings(
      port: (json['port'] as num?)?.toInt() ?? 1883,
      webSocketEnabled: json['webSocketEnabled'] as bool? ?? false,
      externalAccessEnabled: json['externalAccessEnabled'] as bool? ?? false,
      localNetworkOnly: json['localNetworkOnly'] as bool? ?? true,
      hotspotModeSupport: json['hotspotModeSupport'] as bool? ?? true,
    );
  }

  final int port;
  final bool webSocketEnabled;
  final bool externalAccessEnabled;
  final bool localNetworkOnly;
  final bool hotspotModeSupport;

  BrokerNetworkSettings copyWith({
    int? port,
    bool? webSocketEnabled,
    bool? externalAccessEnabled,
    bool? localNetworkOnly,
    bool? hotspotModeSupport,
  }) {
    return BrokerNetworkSettings(
      port: port ?? this.port,
      webSocketEnabled: webSocketEnabled ?? this.webSocketEnabled,
      externalAccessEnabled:
          externalAccessEnabled ?? this.externalAccessEnabled,
      localNetworkOnly: localNetworkOnly ?? this.localNetworkOnly,
      hotspotModeSupport: hotspotModeSupport ?? this.hotspotModeSupport,
    );
  }

  Map<String, dynamic> toJson() => {
    'port': port,
    'webSocketEnabled': webSocketEnabled,
    'externalAccessEnabled': externalAccessEnabled,
    'localNetworkOnly': localNetworkOnly,
    'hotspotModeSupport': hotspotModeSupport,
  };
}

class BrokerSecuritySettings {
  const BrokerSecuritySettings({
    required this.anonymousMode,
    required this.username,
    required this.password,
    required this.allowedClients,
    required this.deniedClients,
  });

  const BrokerSecuritySettings.defaults()
    : anonymousMode = true,
      username = '',
      password = '',
      allowedClients = const [],
      deniedClients = const [];

  factory BrokerSecuritySettings.fromJson(Map<String, dynamic> json) {
    return BrokerSecuritySettings(
      anonymousMode: json['anonymousMode'] as bool? ?? true,
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      allowedClients:
          (json['allowedClients'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => item.toString())
              .toList(),
      deniedClients:
          (json['deniedClients'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => item.toString())
              .toList(),
    );
  }

  final bool anonymousMode;
  final String username;
  final String password;
  final List<String> allowedClients;
  final List<String> deniedClients;

  BrokerSecuritySettings copyWith({
    bool? anonymousMode,
    String? username,
    String? password,
    List<String>? allowedClients,
    List<String>? deniedClients,
  }) {
    return BrokerSecuritySettings(
      anonymousMode: anonymousMode ?? this.anonymousMode,
      username: username ?? this.username,
      password: password ?? this.password,
      allowedClients: allowedClients ?? this.allowedClients,
      deniedClients: deniedClients ?? this.deniedClients,
    );
  }

  Map<String, dynamic> toJson() => {
    'anonymousMode': anonymousMode,
    'username': username,
    'password': password,
    'allowedClients': allowedClients,
    'deniedClients': deniedClients,
  };
}

class BrokerAutomationSettings {
  const BrokerAutomationSettings({
    required this.autoStart,
    required this.autoStopMinutes,
    required this.scheduledStart,
    required this.scheduledStop,
    required this.autoRestartOnCrash,
  });

  const BrokerAutomationSettings.defaults()
    : autoStart = false,
      autoStopMinutes = 0,
      scheduledStart = '',
      scheduledStop = '',
      autoRestartOnCrash = true;

  factory BrokerAutomationSettings.fromJson(Map<String, dynamic> json) {
    return BrokerAutomationSettings(
      autoStart: json['autoStart'] as bool? ?? false,
      autoStopMinutes: (json['autoStopMinutes'] as num?)?.toInt() ?? 0,
      scheduledStart: json['scheduledStart'] as String? ?? '',
      scheduledStop: json['scheduledStop'] as String? ?? '',
      autoRestartOnCrash: json['autoRestartOnCrash'] as bool? ?? true,
    );
  }

  final bool autoStart;
  final int autoStopMinutes;
  final String scheduledStart;
  final String scheduledStop;
  final bool autoRestartOnCrash;

  BrokerAutomationSettings copyWith({
    bool? autoStart,
    int? autoStopMinutes,
    String? scheduledStart,
    String? scheduledStop,
    bool? autoRestartOnCrash,
  }) {
    return BrokerAutomationSettings(
      autoStart: autoStart ?? this.autoStart,
      autoStopMinutes: autoStopMinutes ?? this.autoStopMinutes,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      scheduledStop: scheduledStop ?? this.scheduledStop,
      autoRestartOnCrash: autoRestartOnCrash ?? this.autoRestartOnCrash,
    );
  }

  Map<String, dynamic> toJson() => {
    'autoStart': autoStart,
    'autoStopMinutes': autoStopMinutes,
    'scheduledStart': scheduledStart,
    'scheduledStop': scheduledStop,
    'autoRestartOnCrash': autoRestartOnCrash,
  };
}

class BrokerLoggingSettings {
  const BrokerLoggingSettings({
    required this.enabled,
    required this.maxEntries,
    required this.savePayloads,
  });

  const BrokerLoggingSettings.defaults()
    : enabled = true,
      maxEntries = 1000,
      savePayloads = true;

  factory BrokerLoggingSettings.fromJson(Map<String, dynamic> json) {
    return BrokerLoggingSettings(
      enabled: json['enabled'] as bool? ?? true,
      maxEntries: (json['maxEntries'] as num?)?.toInt() ?? 1000,
      savePayloads: json['savePayloads'] as bool? ?? true,
    );
  }

  final bool enabled;
  final int maxEntries;
  final bool savePayloads;

  BrokerLoggingSettings copyWith({
    bool? enabled,
    int? maxEntries,
    bool? savePayloads,
  }) {
    return BrokerLoggingSettings(
      enabled: enabled ?? this.enabled,
      maxEntries: maxEntries ?? this.maxEntries,
      savePayloads: savePayloads ?? this.savePayloads,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'maxEntries': maxEntries,
    'savePayloads': savePayloads,
  };
}

class BrokerConfig {
  const BrokerConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.network,
    required this.security,
    required this.automation,
    required this.logging,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BrokerConfig.draft({required String id, required int port}) {
    final now = DateTime.now();
    return BrokerConfig(
      id: id,
      name: 'Broker $port',
      description: 'Isolated MQTT room on port $port',
      network: BrokerNetworkSettings.defaults(port: port),
      security: const BrokerSecuritySettings.defaults(),
      automation: const BrokerAutomationSettings.defaults(),
      logging: const BrokerLoggingSettings.defaults(),
      createdAt: now,
      updatedAt: now,
    );
  }

  factory BrokerConfig.fromJson(Map<String, dynamic> json) {
    return BrokerConfig(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Broker',
      description: json['description'] as String? ?? '',
      network: BrokerNetworkSettings.fromJson(
        json['network'] as Map<String, dynamic>? ?? const {},
      ),
      security: BrokerSecuritySettings.fromJson(
        json['security'] as Map<String, dynamic>? ?? const {},
      ),
      automation: BrokerAutomationSettings.fromJson(
        json['automation'] as Map<String, dynamic>? ?? const {},
      ),
      logging: BrokerLoggingSettings.fromJson(
        json['logging'] as Map<String, dynamic>? ?? const {},
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['updatedAt'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  final String id;
  final String name;
  final String description;
  final BrokerNetworkSettings network;
  final BrokerSecuritySettings security;
  final BrokerAutomationSettings automation;
  final BrokerLoggingSettings logging;
  final DateTime createdAt;
  final DateTime updatedAt;

  BrokerConfig copyWith({
    String? id,
    String? name,
    String? description,
    BrokerNetworkSettings? network,
    BrokerSecuritySettings? security,
    BrokerAutomationSettings? automation,
    BrokerLoggingSettings? logging,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BrokerConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      network: network ?? this.network,
      security: security ?? this.security,
      automation: automation ?? this.automation,
      logging: logging ?? this.logging,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  BrokerConfig duplicate({required String id, required int port}) {
    return copyWith(
      id: id,
      name: '$name Copy',
      network: network.copyWith(port: port),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'network': network.toJson(),
    'security': security.toJson(),
    'automation': automation.toJson(),
    'logging': logging.toJson(),
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };
}

class BrokerLogEntry {
  const BrokerLogEntry({
    required this.id,
    required this.brokerId,
    required this.timestamp,
    required this.direction,
    required this.topic,
    required this.payload,
    required this.clientId,
    required this.message,
  });

  final String id;
  final String brokerId;
  final DateTime timestamp;
  final BrokerLogDirection direction;
  final String topic;
  final String payload;
  final String clientId;
  final String message;

  Map<String, dynamic> toJson() => {
    'id': id,
    'brokerId': brokerId,
    'timestamp': timestamp.toIso8601String(),
    'direction': direction.name,
    'topic': topic,
    'payload': payload,
    'clientId': clientId,
    'message': message,
  };
}

class BrokerClientSnapshot {
  const BrokerClientSnapshot({
    required this.clientId,
    required this.ipAddress,
    required this.connectedAt,
    required this.lastPacketAt,
    required this.subscriptionsCount,
    required this.packetCount,
  });

  final String clientId;
  final String ipAddress;
  final DateTime connectedAt;
  final DateTime lastPacketAt;
  final int subscriptionsCount;
  final int packetCount;
}

class BrokerRuntimeState {
  const BrokerRuntimeState({
    required this.status,
    required this.connectedClients,
    required this.startedAt,
    required this.lastActivityAt,
    required this.clients,
    required this.errorMessage,
  });

  const BrokerRuntimeState.stopped()
    : status = BrokerStatus.stopped,
      connectedClients = 0,
      startedAt = null,
      lastActivityAt = null,
      clients = const [],
      errorMessage = null;

  final BrokerStatus status;
  final int connectedClients;
  final DateTime? startedAt;
  final DateTime? lastActivityAt;
  final List<BrokerClientSnapshot> clients;
  final String? errorMessage;

  Duration get uptime =>
      startedAt == null ? Duration.zero : DateTime.now().difference(startedAt!);

  BrokerRuntimeState copyWith({
    BrokerStatus? status,
    int? connectedClients,
    DateTime? startedAt,
    DateTime? lastActivityAt,
    List<BrokerClientSnapshot>? clients,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BrokerRuntimeState(
      status: status ?? this.status,
      connectedClients: connectedClients ?? this.connectedClients,
      startedAt: startedAt ?? this.startedAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      clients: clients ?? this.clients,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class NetworkSnapshot {
  const NetworkSnapshot({
    required this.mode,
    required this.localAddresses,
    required this.publicAddress,
    required this.wifiName,
    required this.updatedAt,
  });

  const NetworkSnapshot.initial()
    : mode = NetworkMode.unknown,
      localAddresses = const [],
      publicAddress = null,
      wifiName = null,
      updatedAt = null;

  final NetworkMode mode;
  final List<String> localAddresses;
  final String? publicAddress;
  final String? wifiName;
  final DateTime? updatedAt;

  String get primaryLocalAddress =>
      localAddresses.isEmpty ? 'Unavailable' : localAddresses.first;
}
