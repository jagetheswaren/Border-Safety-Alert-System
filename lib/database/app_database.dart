import 'package:sqflite/sqflite.dart';

/// Local SQLite database (Phase 4).
///
/// Owns schema creation and versioning only. All queries live in
/// [BoundaryRepository]; the UI never touches this class directly.
/// Accepts an injectable [DatabaseFactory] so host-side tests can use an
/// in-memory database with no device.
class AppDatabase {
  AppDatabase._(this.db);

  /// Current schema version. Bump + add onUpgrade when the schema changes.
  static const version = 1;

  static const tableBoundaries = 'boundaries';

  static const createBoundaries = '''
CREATE TABLE boundaries (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  risk_level TEXT NOT NULL,
  country TEXT,
  description TEXT,
  polygon_data TEXT NOT NULL,
  source TEXT,
  version TEXT,
  updated_at TEXT,
  enabled INTEGER NOT NULL DEFAULT 1
)''';

  final Database db;

  static Future<AppDatabase> open({
    required DatabaseFactory factory,
    required String path,
  }) async {
    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: version,
        onCreate: (db, _) => db.execute(createBoundaries),
      ),
    );
    return AppDatabase._(db);
  }

  /// In-memory database for tests. Nothing is persisted.
  static Future<AppDatabase> inMemory(DatabaseFactory factory) {
    return open(factory: factory, path: inMemoryDatabasePath);
  }

  Future<void> close() => db.close();
}
