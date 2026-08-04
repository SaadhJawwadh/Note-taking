import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_taking_app/data/note_model.dart';
import 'package:note_taking_app/features/sync/data/p2p_pairing_model.dart';
import 'package:note_taking_app/services/p2p_sync_service.dart';
import 'package:note_taking_app/services/sync_crypto_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P2P Sync Functionality & Manifest Tests', () {
    final syncService = P2pSyncService.instance;
    final cryptoService = SyncCryptoService.instance;
    const testPairCode = '123456';

    test('device ID is generated as valid UUID', () async {
      final deviceId = await syncService.getDeviceId();
      expect(deviceId, isNotEmpty);
      expect(deviceId.length, greaterThanOrEqualTo(32));
    });

    test('encrypts and decrypts sync handshake payload correctly', () {
      final payload = json.encode({'action': 'ping', 'deviceId': 'dev_01'});
      final encrypted = cryptoService.encryptPayload(payload, testPairCode);
      expect(encrypted, isNotNull);

      final decrypted = cryptoService.decryptPayload(encrypted!, testPairCode);
      expect(decrypted, equals(payload));
    });

    test('manifest structure contains required keys for LWW conflict resolution', () {
      final note = Note(
        id: 'note_001',
        title: 'Test Note',
        content: 'Content payload',
        dateCreated: DateTime.parse('2026-08-04T12:00:00Z'),
        dateModified: DateTime.parse('2026-08-04T12:30:00Z'),
      );

      final noteMap = note.toMap();
      expect(noteMap['id'], equals('note_001'));
      expect(noteMap['title'], equals('Test Note'));
      expect(noteMap['dateModified'], equals('2026-08-04T12:30:00.000Z'));
    });

    test('PairedDevice serialization and copyWith works cleanly with BLE transport', () {
      final device = PairedDevice(
        deviceId: 'dev_abc',
        deviceName: 'Pixel 8',
        pairCode: '654321',
        transportMode: 'BLE Nearby P2P',
        endpointId: 'ep_123',
      );

      final map = device.toMap();
      expect(map['deviceId'], equals('dev_abc'));
      expect(map['deviceName'], equals('Pixel 8'));
      expect(map['pairCode'], equals('654321'));
      expect(map['endpointId'], equals('ep_123'));

      final restored = PairedDevice.fromMap(map);
      expect(restored.deviceId, equals(device.deviceId));
      expect(restored.deviceName, equals(device.deviceName));
      expect(restored.pairCode, equals(device.pairCode));
      expect(restored.endpointId, equals(device.endpointId));

      final updated = restored.copyWith(transportMode: 'Backup File');
      expect(updated.transportMode, equals('Backup File'));
    });
  });
}
