import 'package:border_safety_alert/database/app_database.dart';
import 'package:border_safety_alert/services/boundary_repository.dart';
import 'package:border_safety_alert/services/boundary_seed.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _seed = '''
{"type": "FeatureCollection", "features": [
  {"type": "Feature",
   "properties": {"name": "Seed Zone", "type": "restricted",
     "risk_level": "HIGH", "source": "SYNTHETIC-DEMO-v0.1"},
   "geometry": {"type": "Polygon", "coordinates":
     [[[10.1, 78.1], [10.1, 78.2], [10.2, 78.2], [10.1, 78.1]]]}}]}
''';

void main() {
  sqfliteFfiInit();

  group('ensureDemoBoundariesSeeded', () {
    test('seeds once and never duplicates', () async {
      final appDb = await AppDatabase.inMemory(databaseFactoryFfi);
      final repo = BoundaryRepository(appDb.db);
      addTearDown(appDb.close);

      expect(await ensureDemoBoundariesSeeded(repo, _seed), 1);
      expect(await repo.countBoundaries(), 1);
      expect(await ensureDemoBoundariesSeeded(repo, _seed), 0);
      expect(await repo.countBoundaries(), 1);
    });

    test('skips seeding when boundaries already exist', () async {
      final appDb = await AppDatabase.inMemory(databaseFactoryFfi);
      final repo = BoundaryRepository(appDb.db);
      addTearDown(appDb.close);

      await ensureDemoBoundariesSeeded(repo, _seed);
      expect(
        await ensureDemoBoundariesSeeded(
          repo,
          '{"type":"FeatureCollection","features":[]}',
        ),
        0,
      );
    });

    test('refuses to seed an empty dataset silently', () async {
      final appDb = await AppDatabase.inMemory(databaseFactoryFfi);
      final repo = BoundaryRepository(appDb.db);
      addTearDown(appDb.close);

      expect(
        () => ensureDemoBoundariesSeeded(
          repo,
          '{"type":"FeatureCollection","features":[]}',
        ),
        throwsA(isA<BoundaryException>()),
      );
      expect(await repo.countBoundaries(), 0);
    });
  });
}
