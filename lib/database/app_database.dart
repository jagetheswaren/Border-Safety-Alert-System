import 'package:sqflite/sqflite.dart';

/// Local SQLite database for Border Safety Alert System (BSAS).
///
/// Owns schema creation, versioning, and migrations for all mobile persistent data:
/// - Boundaries & geofence polygons
/// - Safety events & audit breadcrumbs
/// - Audio/visual alerts history
/// - Location tracking history
/// - Offline map region metadata
/// - Sync queue & offline-first reconciliation
/// - Application settings & preferences
/// - Subsystem diagnostics & audit logs
class AppDatabase {
  AppDatabase._(this.db);

  /// Current schema version.
  static const version = 3;

  // Table names
  static const tableBoundaries = 'boundaries';
  static const tableSafetyEvents = 'safety_events';
  static const tableAlerts = 'alerts';
  static const tableLocationHistory = 'location_history';
  static const tableOfflineRegions = 'offline_map_regions';
  static const tableSyncQueue = 'sync_queue';
  static const tableAppSettings = 'app_settings';
  static const tableAuditDiagnostics = 'audit_diagnostics';

  // DDL definitions
  static const createBoundaries = '''
CREATE TABLE IF NOT EXISTS boundaries (
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

  static const createSafetyEvents = '''
CREATE TABLE IF NOT EXISTS safety_events (
  event_id TEXT PRIMARY KEY,
  timestamp TEXT NOT NULL,
  event_type TEXT NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  zone TEXT NOT NULL,
  risk_state TEXT NOT NULL,
  ai_state TEXT NOT NULL,
  alert_state TEXT NOT NULL,
  synced INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
)''';

  static const createAlerts = '''
CREATE TABLE IF NOT EXISTS alerts (
  id TEXT PRIMARY KEY,
  timestamp TEXT NOT NULL,
  severity TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  zone TEXT,
  latitude REAL,
  longitude REAL,
  acknowledged INTEGER NOT NULL DEFAULT 0,
  synced INTEGER NOT NULL DEFAULT 0
)''';

  static const createLocationHistory = '''
CREATE TABLE IF NOT EXISTS location_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp TEXT NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  accuracy REAL,
  altitude REAL,
  speed REAL,
  bearing REAL,
  is_synced INTEGER NOT NULL DEFAULT 0
)''';

  static const createOfflineRegions = '''
CREATE TABLE IF NOT EXISTS offline_map_regions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  min_zoom INTEGER NOT NULL,
  max_zoom INTEGER NOT NULL,
  bounds_geojson TEXT NOT NULL,
  tile_count INTEGER NOT NULL DEFAULT 0,
  size_bytes INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL,
  downloaded_at TEXT,
  checksum TEXT
)''';

  static const createSyncQueue = '''
CREATE TABLE IF NOT EXISTS sync_queue (
  id TEXT PRIMARY KEY,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  payload_json TEXT NOT NULL,
  retry_count INTEGER NOT NULL DEFAULT 0,
  last_attempt TEXT,
  next_retry_at TEXT,
  status TEXT NOT NULL DEFAULT 'PENDING',
  error_message TEXT
)''';

  static const createAppSettings = '''
CREATE TABLE IF NOT EXISTS app_settings (
  key TEXT PRIMARY KEY,
  value_json TEXT NOT NULL,
  updated_at TEXT NOT NULL
)''';

  static const createAuditDiagnostics = '''
CREATE TABLE IF NOT EXISTS audit_diagnostics (
  id TEXT PRIMARY KEY,
  timestamp TEXT NOT NULL,
  subsystem TEXT NOT NULL,
  event TEXT NOT NULL,
  details TEXT,
  level TEXT NOT NULL DEFAULT 'INFO'
)''';

  static const createIndexes = [
    'CREATE INDEX IF NOT EXISTS idx_safety_events_timestamp ON safety_events(timestamp DESC)',
    'CREATE INDEX IF NOT EXISTS idx_safety_events_synced ON safety_events(synced)',
    'CREATE INDEX IF NOT EXISTS idx_alerts_timestamp ON alerts(timestamp DESC)',
    'CREATE INDEX IF NOT EXISTS idx_location_history_timestamp ON location_history(timestamp DESC)',
    'CREATE INDEX IF NOT EXISTS idx_sync_queue_status ON sync_queue(status)',
    'CREATE INDEX IF NOT EXISTS idx_audit_timestamp ON audit_diagnostics(timestamp DESC)',
  ];

  final Database db;

  static Future<void> _createAllTables(Database db) async {
    await db.execute(createBoundaries);
    await db.execute(createSafetyEvents);
    await db.execute(createAlerts);
    await db.execute(createLocationHistory);
    await db.execute(createOfflineRegions);
    await db.execute(createSyncQueue);
    await db.execute(createAppSettings);
    await db.execute(createAuditDiagnostics);
    for (final sql in createIndexes) {
      await db.execute(sql);
    }
  }

  static Future<AppDatabase> open({
    required DatabaseFactory factory,
    required String path,
  }) async {
    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: version,
        singleInstance: false,
        onCreate: (db, _) => _createAllTables(db),
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await _createAllTables(db);
          }
          if (oldVersion == 2) {
            await db.execute('ALTER TABLE sync_queue ADD COLUMN next_retry_at TEXT');
          }
        },
      ),
    );
    return AppDatabase._(db);
  }

  /// In-memory database for tests. Nothing is persisted to disk.
  static Future<AppDatabase> inMemory(DatabaseFactory factory) {
    return open(factory: factory, path: inMemoryDatabasePath);
  }

  Future<void> close() => db.close();
}
