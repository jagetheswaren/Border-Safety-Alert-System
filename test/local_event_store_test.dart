import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:border_safety_alert/database/app_database.dart';
import 'package:border_safety_alert/services/local_event_store.dart';

void main() {
  group('LocalEventStore', () {
    late LocalEventStore store;

    late AppDatabase database;
    setUp(() async {
      sqfliteFfiInit();
      database = await AppDatabase.inMemory(databaseFactoryFfi);
      store = LocalEventStore(db: database.db);
      await store.initialize();
    });
    tearDown(() async { store.dispose(); await database.close(); });

    test('initial state has zero pending events', () {
      expect(store.pendingCount, 0);
      expect(store.allEvents, isEmpty);
      expect(store.unsyncedEvents, isEmpty);
    });

    test('records events and tracks unsynced queue', () async {
      final evt = LocalSafetyEvent(
        eventId: 'evt_1',
        timestamp: DateTime.now(),
        eventType: 'WARNING',
        latitude: 10.7125,
        longitude: 76.9791,
        zone: 'Sector 7',
        riskState: 'WARNING',
        aiState: 'HIGH',
        alertState: 'Approaching border',
      );

      await store.recordEvent(evt);
      expect(store.pendingCount, 1);
      expect(store.unsyncedEvents.first.eventId, 'evt_1');

      await store.markSynced(['evt_1']);
      expect(store.pendingCount, 0);
      expect(store.unsyncedEvents, isEmpty);
      expect(store.allEvents.first.synced, isTrue);

      await store.clearEvents();
      expect(store.allEvents, isEmpty);
    });
  });
}
