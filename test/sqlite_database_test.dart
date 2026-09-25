import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:border_safety_alert/database/app_database.dart';
import 'package:border_safety_alert/services/local_event_store.dart';

void main() {
  sqfliteFfiInit();

  group('AppDatabase Schema v2 & SQLite Persistence', () {
    late AppDatabase appDb;

    setUp(() async {
      appDb = await AppDatabase.inMemory(databaseFactoryFfi);
    });

    tearDown(() async {
      await appDb.close();
    });

    test('verifies all 8 required production tables exist in SQLite', () async {
      final tables = await appDb.db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );
      final tableNames = tables.map((r) => r['name'] as String).toSet();

      expect(tableNames, contains(AppDatabase.tableBoundaries));
      expect(tableNames, contains(AppDatabase.tableSafetyEvents));
      expect(tableNames, contains(AppDatabase.tableAlerts));
      expect(tableNames, contains(AppDatabase.tableLocationHistory));
      expect(tableNames, contains(AppDatabase.tableOfflineRegions));
      expect(tableNames, contains(AppDatabase.tableSyncQueue));
      expect(tableNames, contains(AppDatabase.tableAppSettings));
      expect(tableNames, contains(AppDatabase.tableAuditDiagnostics));
    });

    test('verifies production indexes exist', () async {
      final indexes = await appDb.db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND name NOT LIKE 'sqlite_%'",
      );
      final indexNames = indexes.map((r) => r['name'] as String).toSet();

      expect(indexNames, contains('idx_safety_events_timestamp'));
      expect(indexNames, contains('idx_safety_events_synced'));
      expect(indexNames, contains('idx_alerts_timestamp'));
      expect(indexNames, contains('idx_location_history_timestamp'));
      expect(indexNames, contains('idx_sync_queue_status'));
      expect(indexNames, contains('idx_audit_timestamp'));
    });

    test('verifies LocalEventStore writes directly to SQLite and sync queue', () async {
      final store = LocalEventStore(db: appDb.db);
      await store.initialize(factory: databaseFactoryFfi);

      final event = LocalSafetyEvent(
        eventId: 'evt_sql_1',
        timestamp: DateTime.utc(2026, 9, 25, 12, 0, 0),
        eventType: 'CRITICAL',
        latitude: 10.15,
        longitude: 78.15,
        zone: 'Sector 7',
        riskState: 'CRITICAL',
        aiState: 'HIGH',
        alertState: 'Boundary Breached',
      );

      await store.recordEvent(event);

      // Verify row in safety_events
      final eventRows = await appDb.db.query(
        AppDatabase.tableSafetyEvents,
        where: 'event_id = ?',
        whereArgs: ['evt_sql_1'],
      );
      expect(eventRows.length, 1);
      expect(eventRows.first['event_type'], 'CRITICAL');
      expect(eventRows.first['synced'], 0);

      // Verify row in sync_queue
      final syncRows = await appDb.db.query(
        AppDatabase.tableSyncQueue,
        where: 'entity_id = ?',
        whereArgs: ['evt_sql_1'],
      );
      expect(syncRows.length, 1);
      expect(syncRows.first['status'], 'PENDING');

      // Mark synced
      await store.markSynced(['evt_sql_1']);
      final updatedSync = await appDb.db.query(
        AppDatabase.tableSyncQueue,
        where: 'entity_id = ?',
        whereArgs: ['evt_sql_1'],
      );
      expect(updatedSync, isEmpty);
      expect((await appDb.db.query(AppDatabase.tableSafetyEvents)).first['synced'], 1);
    });

    test('verifies location breadcrumb recording in SQLite', () async {
      final store = LocalEventStore(db: appDb.db);
      await store.initialize(factory: databaseFactoryFfi);

      await store.recordLocation(
        latitude: 10.7125,
        longitude: 76.9791,
        accuracy: 3.5,
        speed: 12.4,
        bearing: 88.0,
      );

      final rows = await appDb.db.query(AppDatabase.tableLocationHistory);
      expect(rows.length, 1);
      expect(rows.first['latitude'], 10.7125);
      expect(rows.first['accuracy'], 3.5);
    });
  });
}
