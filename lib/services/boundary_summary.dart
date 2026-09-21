import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/boundary_model.dart';
import 'boundary_repository.dart';
import 'boundary_seed.dart';

/// Minimal read model for the Phase 4 UI proof (count + provenance only).
/// No geometry, no safety math — that belongs to Phase 5.
class BoundarySummary {
  const BoundarySummary({
    required this.count,
    required this.allDemo,
    this.error,
  });

  final int count;
  final bool allDemo;
  final String? error;
}

/// Load seam so widget tests can inject fakes instead of opening SQLite.
abstract class BoundarySummaryProvider {
  Future<BoundarySummary> load();

  /// Optional geometry loader for the Phase 5 engine. Test providers may
  /// leave this empty when a geo-fence result is not under test.
  Future<List<BoundaryModel>> loadEnabledBoundaries() async => const [];
}

/// Production provider: opens the on-device database, seeds bundled demo
/// boundaries once, and reports what is stored. Failures become
/// [BoundarySummary.error]; nothing is fabricated.
class OfflineBoundaryProvider implements BoundarySummaryProvider {
  static const assetPath = 'assets/boundaries/demo_boundaries.geojson';
  static const dbFileName = 'border_safety.db';

  /// Loads enabled boundaries through [BoundaryRepository]. The database is
  /// closed after the read; callers should cache the returned list.
  @override
  Future<List<BoundaryModel>> loadEnabledBoundaries() async {
    final path = p.join(await getDatabasesPath(), dbFileName);
    final appDb = await AppDatabase.open(factory: databaseFactory, path: path);
    try {
      final repository = BoundaryRepository(appDb.db);
      final raw = await rootBundle.loadString(assetPath);
      await ensureDemoBoundariesSeeded(repository, raw);
      return repository.getEnabledBoundaries();
    } finally {
      await appDb.close();
    }
  }

  @override
  Future<BoundarySummary> load() async {
    try {
      final stored = await _loadAllBoundaries();
      return BoundarySummary(
        count: stored.length,
        allDemo: stored.every((b) => b.isDemo),
      );
    } catch (e) {
      return BoundarySummary(count: 0, allDemo: true, error: '$e');
    }
  }

  Future<List<BoundaryModel>> _loadAllBoundaries() async {
    final path = p.join(await getDatabasesPath(), dbFileName);
    final appDb = await AppDatabase.open(factory: databaseFactory, path: path);
    try {
      final repository = BoundaryRepository(appDb.db);
      final raw = await rootBundle.loadString(assetPath);
      await ensureDemoBoundariesSeeded(repository, raw);
      return repository.getAllBoundaries();
    } finally {
      await appDb.close();
    }
  }
}
