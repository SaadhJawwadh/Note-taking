class PairedDevice {
  final String deviceId;
  final String deviceName;
  final String pairCode;
  final DateTime? lastSyncedAt;
  final String transportMode;
  final bool isPaired;
  final String? ipAddress;
  final String role; // PRIMARY | SECONDARY
  final String? endpointId;

  PairedDevice({
    required this.deviceId,
    required this.deviceName,
    required this.pairCode,
    this.lastSyncedAt,
    this.transportMode = 'Primary Direct Sync',
    this.isPaired = true,
    this.ipAddress,
    this.role = 'PRIMARY',
    this.endpointId,
  });

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
    };
  }

  factory PairedDevice.fromMap(Map<String, dynamic> map) {
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
    );
  }
}
