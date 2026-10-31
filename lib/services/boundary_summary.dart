import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/boundary_model.dart';
import 'boundary_repository.dart';
import 'boundary_import.dart';

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

/// Loads the five official local village polygons for map context. Village
/// administration geometry is not a hazard perimeter and never drives alerts.
class OfflineBoundaryProvider implements BoundarySummaryProvider {
  static const assetPath = String.fromEnvironment('BSAS_BOUNDARY_ASSET', defaultValue: 'assets/boundaries/soi_pollachi_villages.geojson');
  static const dbFileName = 'border_safety.db';

  /// Loads enabled boundaries through [BoundaryRepository]. The database is
  /// closed after the read; callers should cache the returned list.
  @override
  Future<List<BoundaryModel>> loadEnabledBoundaries() async {
    if (kIsWeb) {
      final raw = await rootBundle.loadString(assetPath);
      return parseBoundariesFromGeoJson(raw).where((b) => b.enabled).toList();
    }
    final path = p.join(await getDatabasesPath(), dbFileName);
    final appDb = await AppDatabase.open(factory: databaseFactory, path: path);
    try {
      final repository = BoundaryRepository(appDb.db);
      final raw = await rootBundle.loadString(assetPath);
      final bundled = parseBoundariesFromGeoJson(raw).where((b) => b.enabled).toList();
      if (bundled.isNotEmpty) {
        await repository.insertBoundaries(bundled);
        return bundled;
      }
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
        allDemo: stored.every((boundary) => boundary.isDemo),
      );
    } catch (e) {
      return BoundarySummary(count: 0, allDemo: true, error: '$e');
    }
  }

  Future<List<BoundaryModel>> _loadAllBoundaries() async {
    if (kIsWeb) {
      final raw = await rootBundle.loadString(assetPath);
      return parseBoundariesFromGeoJson(raw).where((b) => b.enabled).toList();
    }
    final path = p.join(await getDatabasesPath(), dbFileName);
    final appDb = await AppDatabase.open(factory: databaseFactory, path: path);
    try {
      final repository = BoundaryRepository(appDb.db);
      final raw = await rootBundle.loadString(assetPath);
      final bundled = parseBoundariesFromGeoJson(raw).where((b) => b.enabled).toList();
      if (bundled.isNotEmpty) {
        await repository.insertBoundaries(bundled);
        return bundled;
      }
      return repository.getAllBoundaries();
    } finally {
      await appDb.close();
    }
  }
}
