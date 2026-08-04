import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../services/p2p_sync_service.dart';
import '../data/p2p_pairing_model.dart';

enum SyncStatus { idle, hosting, connecting, syncing, completed, error }

class P2pSyncProvider with ChangeNotifier {
  static const String _storageKey = 'p2p_paired_devices_v1';
  static const String _autoSyncKey = 'p2p_auto_sync_enabled';

  List<PairedDevice> _pairedDevices = [];
  List<PairedDevice> get pairedDevices => List.unmodifiable(_pairedDevices);

  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  bool _isAutoSyncEnabled = true;
  bool get isAutoSyncEnabled => _isAutoSyncEnabled;

  DateTime? _lastSyncedAt;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  String? _lastMessage;
  String? get lastMessage => _lastMessage;

  String _currentPairCode = '';
  String get currentPairCode => _currentPairCode;

  String? _localIpAddress;
  String? get localIpAddress => _localIpAddress;

  SystemDiagnostics? _diagnostics;
  SystemDiagnostics? get diagnostics => _diagnostics;

  final P2pSyncService _service = P2pSyncService.instance;
  StreamSubscription<SyncResult>? _syncResultSubscription;
  StreamSubscription<PairedDevice>? _remotePairSubscription;

  P2pSyncProvider() {
    loadSettings();
  }

  @override
  void dispose() {
    _syncResultSubscription?.cancel();
    _remotePairSubscription?.cancel();
    _service.stopPrimaryHostServer();
    super.dispose();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isAutoSyncEnabled = prefs.getBool(_autoSyncKey) ?? true;

    final rawJson = prefs.getString(_storageKey);
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final List<dynamic> list = json.decode(rawJson);
        final loadedList = list.map((item) => PairedDevice.fromMap(item as Map<String, dynamic>)).toList();
        
        // Strict Deduplication by unique deviceId
        final Map<String, PairedDevice> uniqueMap = {};
        for (final device in loadedList) {
          uniqueMap[device.deviceId] = device;
        }
        _pairedDevices = uniqueMap.values.toList();
      } catch (e) {
        debugPrint('[P2pSyncProvider] Failed to parse paired devices: $e');
        _pairedDevices = [];
      }
    }

    if (_pairedDevices.isNotEmpty) {
      _currentPairCode = _pairedDevices.first.pairCode;
    } else {
      generateNewPairCode();
    }

    // Subscribe to sync results
    _syncResultSubscription = _service.syncEvents.listen((result) {
      if (result.success) {
        _status = SyncStatus.completed;
        _lastSyncedAt = DateTime.now();
        if (result.latencyMs != null) {
          _lastMessage = 'Test Ping Succeeded 🟢 (${result.latencyMs}ms)';
        } else {
          _lastMessage = result.syncedCount > 0 ? 'Master State Synced' : result.transportUsed;
        }
      } else {
        _status = SyncStatus.error;
        _lastMessage = result.errorMessage ?? 'Sync error';
      }
      notifyListeners();
    });

    // Subscribe to remote device auto-pairing events (1-Scan Bidirectional pairing)
    _remotePairSubscription = _service.remoteDevicePaired.listen((incomingDevice) async {
      final index = _pairedDevices.indexWhere((d) => d.deviceId == incomingDevice.deviceId);
      if (index != -1) {
        _pairedDevices[index] = incomingDevice;
      } else {
        _pairedDevices.add(incomingDevice);
      }
      await _saveDevicesToStorage();
      notifyListeners();
    });

    await refreshDiagnostics();
    await startPrimaryHostServer();
    notifyListeners();
  }

  Future<void> refreshDiagnostics() async {
    _diagnostics = await _service.runDiagnostics();
    _localIpAddress = _diagnostics?.localIp;
    notifyListeners();
  }

  /// Starts Primary Host Server on this device.
  Future<void> startPrimaryHostServer() async {
    _status = SyncStatus.hosting;
    notifyListeners();

    await _service.startPrimaryHostServer('Primary Device', _currentPairCode);
  }

  /// Sends a test ping to Primary Device IP with latency measurement
  Future<bool> sendTestPing({String? targetIp}) async {
    final ipToPing = targetIp ?? (_pairedDevices.isNotEmpty ? _pairedDevices.first.ipAddress : null) ?? _localIpAddress;
    if (ipToPing == null || ipToPing.isEmpty) {
      _lastMessage = 'Test Ping Failed: Target IP address unavailable';
      _status = SyncStatus.error;
      notifyListeners();
      return false;
    }

    _lastMessage = 'Pinging $ipToPing...';
    notifyListeners();

    final result = await _service.sendTestPing(ipToPing, _currentPairCode);
    if (!result.success) {
      _lastMessage = result.errorMessage ?? 'Test Ping Failed: $ipToPing unreachable';
      _status = SyncStatus.error;
    }
    notifyListeners();
    return result.success;
  }

  String generateNewPairCode() {
    final rng = Random();
    final code = (100000 + rng.nextInt(900000)).toString();
    _currentPairCode = code;
    notifyListeners();
    return code;
  }

  Future<void> setAutoSyncEnabled(bool enabled) async {
    _isAutoSyncEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSyncKey, enabled);
    notifyListeners();
  }

  /// Pairs device and performs instant 1-scan bidirectional handshake
  Future<PairedDevice> pairNewDevice({
    required String deviceName,
    required String pairCode,
    String? targetIp,
    String role = 'PRIMARY',
  }) async {
    final newDevice = PairedDevice(
      deviceId: const Uuid().v4(),
      deviceName: deviceName.trim().isEmpty ? 'Paired Device' : deviceName.trim(),
      pairCode: pairCode.trim(),
      lastSyncedAt: DateTime.now(),
      transportMode: 'Primary Direct Sync',
      ipAddress: targetIp,
      role: role,
    );

    // Deduplicate by deviceId or pairCode
    _pairedDevices.removeWhere((d) => d.deviceId == newDevice.deviceId || d.pairCode == pairCode.trim());
    _pairedDevices.add(newDevice);

    _currentPairCode = pairCode.trim();
    await _saveDevicesToStorage();

    if (targetIp != null && targetIp.isNotEmpty) {
      await _service.sendPairHandshake(_currentPairCode, deviceName, targetIp);
    }

    notifyListeners();
    return newDevice;
  }

  Future<void> unpairDevice(String deviceId) async {
    _pairedDevices.removeWhere((d) => d.deviceId == deviceId);
    await _saveDevicesToStorage();
    if (_pairedDevices.isEmpty) {
      generateNewPairCode();
    }
    notifyListeners();
  }

  /// Alias for pullFromPrimary for home app bar button compatibility.
  Future<SyncResult> syncNow({Function()? onCompleted}) async {
    return pullFromPrimary(onCompleted: onCompleted);
  }

  /// Secondary pulls master state from Primary Device
  Future<SyncResult> pullFromPrimary({String? targetIp, Function()? onCompleted}) async {
    final ipToSync = targetIp ?? (_pairedDevices.isNotEmpty ? _pairedDevices.first.ipAddress : null);
    if (ipToSync == null || ipToSync.isEmpty) {
      _status = SyncStatus.error;
      _lastMessage = 'Master Sync Failed: Primary Device IP unavailable. Scan QR code to pair.';
      notifyListeners();
      return SyncResult(success: false, errorMessage: _lastMessage);
    }

    _status = SyncStatus.syncing;
    _lastMessage = 'Pulling master state from Primary ($ipToSync)...';
    notifyListeners();

    final result = await _service.pullMasterFromPrimary(ipToSync, _currentPairCode);

    if (result.success) {
      _status = SyncStatus.completed;
      _lastSyncedAt = DateTime.now();
      _lastMessage = 'Synced master snapshot from $ipToSync';

      final updatedIndex = _pairedDevices.indexWhere((d) => d.ipAddress == ipToSync);
      if (updatedIndex != -1) {
        _pairedDevices[updatedIndex] = _pairedDevices[updatedIndex].copyWith(
          lastSyncedAt: _lastSyncedAt,
          transportMode: result.transportUsed,
        );
        await _saveDevicesToStorage();
      }

      if (onCompleted != null) onCompleted();
    } else {
      _status = SyncStatus.error;
      _lastMessage = result.errorMessage ?? 'Master Sync failed';
    }

    notifyListeners();
    return result;
  }

  Future<void> _saveDevicesToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    // Strict deduplication before saving to SharedPreferences
    final Map<String, PairedDevice> uniqueMap = {};
    for (final device in _pairedDevices) {
      uniqueMap[device.deviceId] = device;
    }
    _pairedDevices = uniqueMap.values.toList();

    final jsonString = json.encode(_pairedDevices.map((d) => d.toMap()).toList());
    await prefs.setString(_storageKey, jsonString);
  }
}
