import 'package:border_safety_alert/database/app_database.dart';
import 'package:border_safety_alert/models/boundary_model.dart';
import 'package:border_safety_alert/models/safety_state.dart';
import 'package:border_safety_alert/services/boundary_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

BoundaryModel _zone(
  String id, {
  String type = 'restricted',
  bool enabled = true,
}) {
  return BoundaryModel(
    id: id,
    name: 'Zone $id',
    type: type,
    riskLevel: RiskLevel.high,
    polygon: [
      [
        const BoundaryPosition(longitude: 10.1, latitude: 78.1),
        const BoundaryPosition(longitude: 10.1, latitude: 78.2),
        const BoundaryPosition(longitude: 10.2, latitude: 78.2),
        const BoundaryPosition(longitude: 10.1, latitude: 78.1),
      ],
    ],
    source: 'SYNTHETIC-DEMO-v0.1',
    enabled: enabled,
  );
}

void main() {
  sqfliteFfiInit();

  late AppDatabase appDb;
  late BoundaryRepository repo;

  setUp(() async {
    appDb = await AppDatabase.inMemory(databaseFactoryFfi);
    repo = BoundaryRepository(appDb.db);
  });

  tearDown(() async => appDb.close());

  group('AppDatabase', () {
    test('creates the boundaries table on open', () async {
      final tables = await appDb.db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'boundaries'",
      );
      expect(tables, hasLength(1));
    });
  });

  group('BoundaryRepository', () {
    test('insert and get by id round-trips geometry', () async {
      await repo.insertBoundary(_zone('a'));
      final loaded = await repo.getBoundaryById('a');

      expect(loaded, isNotNull);
      expect(loaded!.name, 'Zone a');
      expect(loaded.polygon.first.length, 4);
      expect(loaded.polygon.first.first.longitude, 10.1);
      expect(loaded.isDemo, isTrue);
    });

    test('get by id returns null when missing', () async {
      expect(await repo.getBoundaryById('nope'), isNull);
    });

    test('bulk insert then get all', () async {
      await repo.insertBoundaries([_zone('a'), _zone('b'), _zone('c')]);
      final all = await repo.getAllBoundaries();
      expect(all.map((b) => b.id), containsAll(['a', 'b', 'c']));
    });

    test('re-inserting an id upserts instead of duplicating', () async {
      await repo.insertBoundary(_zone('a'));
      await repo.insertBoundary(_zone('a'));
      expect(await repo.countBoundaries(), 1);
    });

    test('update changes the row and reports the count', () async {
      await repo.insertBoundary(_zone('a'));
      final updated = await repo.updateBoundary(_zone('a', type: 'forest'));
      expect(updated, 1);
      expect((await repo.getBoundaryById('a'))!.type, 'forest');
      expect(await repo.updateBoundary(_zone('ghost')), 0);
    });

    test('delete removes the row and reports the count', () async {
      await repo.insertBoundary(_zone('a'));
      expect(await repo.deleteBoundary('a'), 1);
      expect(await repo.getBoundaryById('a'), isNull);
      expect(await repo.deleteBoundary('a'), 0);
    });

    test('clear removes everything', () async {
      await repo.insertBoundaries([_zone('a'), _zone('b')]);
      expect(await repo.clearBoundaries(), 2);
      expect(await repo.countBoundaries(), 0);
    });

    test('enabled filtering', () async {
      await repo.insertBoundaries([_zone('on'), _zone('off', enabled: false)]);
      expect(await repo.countBoundaries(), 2);
      expect(await repo.countBoundaries(enabledOnly: true), 1);
      final enabled = await repo.getEnabledBoundaries();
      expect(enabled.map((b) => b.id), ['on']);
    });

    test('type filtering', () async {
      await repo.insertBoundaries([
        _zone('r', type: 'restricted'),
        _zone('f', type: 'forest'),
      ]);
      final forests = await repo.getBoundariesByType('forest');
      expect(forests.map((b) => b.id), ['f']);
      expect(await repo.getBoundariesByType('unknown'), isEmpty);
    });

    test(
      'database failure surfaces as BoundaryException, not silence',
      () async {
        await appDb.close();
        expect(() => repo.countBoundaries(), throwsA(isA<BoundaryException>()));
        expect(
          () => repo.getAllBoundaries(),
          throwsA(isA<BoundaryException>()),
        );
      },
    );
  });
}
