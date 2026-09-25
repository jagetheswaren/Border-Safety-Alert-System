import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:border_safety_alert/database/app_database.dart';
import 'package:border_safety_alert/services/local_event_store.dart';
import 'package:border_safety_alert/services/sync_service.dart';

void main() {
  sqfliteFfiInit();

  group('SyncService & SQLite Reconciliation Verification', () {
    late AppDatabase appDb;
    late LocalEventStore eventStore;
    late SyncService syncService;
    late HttpServer testServer;
    late int serverPort;

    setUp(() async {
      appDb = await AppDatabase.inMemory(databaseFactoryFfi);

      // 1. Start a real local HTTP server to receive sync requests
      testServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      serverPort = testServer.port;

      testServer.listen((HttpRequest request) async {
        if (request.uri.path == '/api/v1/health') {
          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'status': 'ok'}))
            ..close();
        } else if (request.uri.path == '/api/v1/sync/batch') {
          final content = await utf8.decoder.bind(request).join();
          final data = jsonDecode(content) as Map<String, dynamic>;
          final events = data['events'] as List;
          final ackIds = events.map((e) => e['event_id']).toList();

          request.response
            ..statusCode = HttpStatus.ok
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({
              'status': 'SUCCESS',
              'synced_count': events.length,
              'acknowledged_ids': ackIds,
              'receipt_id': 'rcpt-test-123',
              'server_timestamp': DateTime.now().toUtc().toIso8601String(),
            }))
            ..close();
        } else {
          request.response
            ..statusCode = HttpStatus.notFound
            ..close();
        }
      });

      // 2. Initialize event store backed by real SQLite in-memory database
      eventStore = LocalEventStore(db: appDb.db);
      await eventStore.initialize(factory: databaseFactoryFfi);

      // 3. Setup SyncService pointing to test server
      syncService = SyncService(
        eventStore: eventStore,
        baseUrl: 'http://127.0.0.1:$serverPort',
        deviceId: 'unit-test-device',
        authToken: 'isolated-test-token',
      );
    });

    tearDown(() async {
      await testServer.close(force: true);
      await appDb.close();
    });

    test('health check connects to live HTTP server', () async {
      final isOnline = await syncService.checkConnectivity();
      expect(isOnline, isTrue);
    });

    test('syncNow transmits queued events and reconciles local SQLite state', () async {
      final evt1 = LocalSafetyEvent(
        eventId: 'evt_sync_01',
        timestamp: DateTime.now(),
        eventType: 'ZONE_ENTRY',
        latitude: 10.712530,
        longitude: 76.979150,
        zone: 'BUFFER_ZONE',
        riskState: 'CAUTION',
        aiState: 'IDLE',
        alertState: 'CAUTION',
      );
      final evt2 = LocalSafetyEvent(
        eventId: 'evt_sync_02',
        timestamp: DateTime.now(),
        eventType: 'WARNING_TRIGGER',
        latitude: 10.712600,
        longitude: 76.979200,
        zone: 'DEMARCATION_LINE',
        riskState: 'WARNING',
        aiState: 'IDLE',
        alertState: 'WARNING',
      );

      await eventStore.recordEvent(evt1);
      await eventStore.recordEvent(evt2);

      expect(eventStore.pendingCount, 2);
      expect(syncService.status, SyncStatus.idle);

      // Perform sync
      await syncService.syncNow();

      expect(syncService.status, SyncStatus.complete);
      expect(syncService.lastSyncedCount, 2);
      expect(eventStore.pendingCount, 0);
      expect(eventStore.unsyncedEvents, isEmpty);
      expect(eventStore.allEvents.every((e) => e.synced), isTrue);
    });

    test('syncNow handles offline server gracefully without data loss', () async {
      // Point to closed/dead port
      final offlineService = SyncService(
        eventStore: eventStore,
        baseUrl: 'http://127.0.0.1:54321',
        authToken: 'offline-test-token', // needed to pass auth check; server is dead
      );

      final evt = LocalSafetyEvent(
        eventId: 'evt_offline_01',
        timestamp: DateTime.now(),
        eventType: 'ZONE_ENTRY',
        latitude: 10.712530,
        longitude: 76.979150,
        zone: 'BUFFER_ZONE',
        riskState: 'SAFE',
        aiState: 'IDLE',
        alertState: 'SAFE',
      );
      await eventStore.recordEvent(evt);

      await offlineService.syncNow();

      expect(offlineService.status, SyncStatus.offline);
      expect(eventStore.pendingCount, 1);
      expect(eventStore.unsyncedEvents.first.eventId, 'evt_offline_01');
      expect(offlineService.getRetryDelay().inSeconds, greaterThanOrEqualTo(1));
    });
  });
}
