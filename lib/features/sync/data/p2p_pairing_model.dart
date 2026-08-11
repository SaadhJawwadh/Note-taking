class DeviceEndpoint {
  final String ipAddress;
  final int port;
  final String? networkLabel;
  final DateTime? lastSeenAt;
  final DateTime? lastSyncedAt;

  const DeviceEndpoint({
    required this.ipAddress,
    this.port = 8765,
    this.networkLabel,
    this.lastSeenAt,
    this.lastSyncedAt,
  });

  Map<String, dynamic> toMap() => {
        'ipAddress': ipAddress,
        'port': port,
        'networkLabel': networkLabel,
        'lastSeenAt': lastSeenAt?.toIso8601String(),
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      };

  factory DeviceEndpoint.fromMap(Map<String, dynamic> map) => DeviceEndpoint(
        ipAddress: map['ipAddress']?.toString() ?? '',
        port: map['port'] is int ? map['port'] as int : int.tryParse('${map['port']}') ?? 8765,
        networkLabel: map['networkLabel']?.toString(),
        lastSeenAt: map['lastSeenAt'] == null ? null : DateTime.tryParse('${map['lastSeenAt']}'),
        lastSyncedAt: map['lastSyncedAt'] == null ? null : DateTime.tryParse('${map['lastSyncedAt']}'),
      );

  DeviceEndpoint copyWith({
    String? networkLabel,
    DateTime? lastSeenAt,
    DateTime? lastSyncedAt,
  }) =>
      DeviceEndpoint(
        ipAddress: ipAddress,
        port: port,
        networkLabel: networkLabel ?? this.networkLabel,
        lastSeenAt: lastSeenAt ?? this.lastSeenAt,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      );
}

class PairedDevice {
  final String deviceId;
  final String deviceName;
  final String pairCode;
  final DateTime? lastSyncedAt;
  final String transportMode;
  final bool isPaired;
  final String role; // PRIMARY | SECONDARY
  final String? endpointId;
  final List<DeviceEndpoint> endpoints;
  final bool isNameCustom;

  PairedDevice({
    required this.deviceId,
    required this.deviceName,
    required this.pairCode,
    this.lastSyncedAt,
    this.transportMode = 'Primary Direct Sync',
    this.isPaired = true,
    String? ipAddress,
    this.role = 'PRIMARY',
    this.endpointId,
    List<DeviceEndpoint>? endpoints,
    this.isNameCustom = false,
  }) : endpoints = List.unmodifiable(_migrateEndpoint(ipAddress, endpointId, endpoints));

  static List<DeviceEndpoint> _migrateEndpoint(
    String? ipAddress,
    String? endpointId,
    List<DeviceEndpoint>? endpoints,
  ) {
    final allEndpoints = [...?endpoints];
    final legacyIp = ipAddress ?? endpointId;
    if (legacyIp != null && legacyIp.isNotEmpty && !allEndpoints.any((endpoint) => endpoint.ipAddress == legacyIp)) {
      allEndpoints.add(DeviceEndpoint(ipAddress: legacyIp));
    }
    return allEndpoints.where((endpoint) => endpoint.ipAddress.isNotEmpty).toList();
  }

  /// The most recently discovered endpoint, retained for legacy call sites.
  String? get ipAddress => endpoints.isEmpty ? null : endpoints.last.ipAddress;

  DeviceEndpoint? get preferredEndpoint {
    if (endpoints.isEmpty) return null;
    final sorted = [...endpoints]
      ..sort((a, b) => (b.lastSyncedAt ?? b.lastSeenAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.lastSyncedAt ?? a.lastSeenAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
    return sorted.first;
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'pairCode': pairCode,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'transportMode': transportMode,
      'isPaired': isPaired ? 1 : 0,
      'ipAddress': ipAddress,
      'role': role,
      'endpointId': endpointId ?? ipAddress,
      'endpoints': endpoints.map((endpoint) => endpoint.toMap()).toList(),
      'isNameCustom': isNameCustom,
    };
  }

  factory PairedDevice.fromMap(Map<String, dynamic> map) {
    final rawEndpoints = map['endpoints'];
    final endpoints = rawEndpoints is List
        ? rawEndpoints
            .whereType<Map>()
            .map((endpoint) => DeviceEndpoint.fromMap(Map<String, dynamic>.from(endpoint)))
            .toList()
        : <DeviceEndpoint>[];
    return PairedDevice(
      deviceId: map['deviceId'] as String? ?? 'dev_${map['pairCode'] ?? '01'}',
      deviceName: map['deviceName'] as String? ?? 'Paired Device',
      pairCode: map['pairCode'] as String? ?? '',
      lastSyncedAt: map['lastSyncedAt'] != null
          ? DateTime.tryParse(map['lastSyncedAt'].toString())
          : null,
      transportMode: map['transportMode'] as String? ?? 'Primary Direct Sync',
      isPaired: map['isPaired'] == 1 || map['isPaired'] == true,
      ipAddress: map['ipAddress'] as String? ?? map['endpointId'] as String?,
      role: map['role'] as String? ?? 'PRIMARY',
      endpointId: map['endpointId'] as String? ?? map['ipAddress'] as String?,
      endpoints: endpoints,
      isNameCustom: map['isNameCustom'] == 1 || map['isNameCustom'] == true,
    );
  }

  PairedDevice copyWith({
    String? deviceName,
    String? pairCode,
    DateTime? lastSyncedAt,
    String? transportMode,
    bool? isPaired,
    String? ipAddress,
    String? role,
    String? endpointId,
    List<DeviceEndpoint>? endpoints,
    bool? isNameCustom,
  }) {
    return PairedDevice(
      deviceId: deviceId,
      deviceName: deviceName ?? this.deviceName,
      pairCode: pairCode ?? this.pairCode,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      transportMode: transportMode ?? this.transportMode,
      isPaired: isPaired ?? this.isPaired,
      ipAddress: ipAddress ?? this.ipAddress,
      role: role ?? this.role,
      endpointId: endpointId ?? this.endpointId,
      endpoints: endpoints ?? this.endpoints,
      isNameCustom: isNameCustom ?? this.isNameCustom,
    );
  }

  PairedDevice withEndpoint(DeviceEndpoint endpoint) {
    final updatedEndpoints = endpoints.where((item) => item.ipAddress != endpoint.ipAddress || item.port != endpoint.port).toList()
      ..add(endpoint);
    return copyWith(endpoints: updatedEndpoints);
  }
}
