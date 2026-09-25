import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';

/// A typed, immutable model representing an authoritative safety event.
class LocalSafetyEvent {
  const LocalSafetyEvent({
    required this.eventId,
    required this.timestamp,
    required this.eventType,
    required this.latitude,
    required this.longitude,
    required this.zone,
    required this.riskState,
    required this.aiState,
    required this.alertState,
    this.synced = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? timestamp;

  final String eventId;
  final DateTime timestamp;
  final String eventType;
  final double latitude;
  final double longitude;
  final String zone;
  final String riskState;
  final String aiState;
  final String alertState;
  final bool synced;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'event_id': eventId,
        'timestamp': timestamp.toIso8601String(),
        'event_type': eventType,
        'latitude': latitude,
        'longitude': longitude,
        'zone': zone,
        'risk_state': riskState,
        'ai_state': aiState,
        'alert_state': alertState,
        'synced': synced ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory LocalSafetyEvent.fromMap(Map<String, dynamic> map) => LocalSafetyEvent(
        eventId: map['event_id'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
        eventType: map['event_type'] as String,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        zone: map['zone'] as String,
        riskState: map['risk_state'] as String,
        aiState: map['ai_state'] as String,
        alertState: map['alert_state'] as String,
        synced: (map['synced'] as int) == 1,
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'] as String)
            : DateTime.parse(map['timestamp'] as String),
      );

  LocalSafetyEvent copyWith({bool? synced}) => LocalSafetyEvent(
        eventId: eventId,
        timestamp: timestamp,
        eventType: eventType,
        latitude: latitude,
        longitude: longitude,
        zone: zone,
        riskState: riskState,
        aiState: aiState,
        alertState: alertState,
        synced: synced ?? this.synced,
        createdAt: createdAt,
      );
}

/// Events and their durable upload queue share a single SQLite transaction.
class LocalEventStore extends ChangeNotifier {
  LocalEventStore({Database? db}) : _db = db, _ownsDatabase = db == null;
  static const dbFileName = 'border_safety.db';
  static const maxRetentionCount = 500;
  Database? _db;
  final bool _ownsDatabase;
  Future<void>? _opening;
  bool _initialized = false;
  bool _disposed = false;
  String? _lastError;
  final List<LocalSafetyEvent> _events = [];

  bool get isInitialized => _initialized && (_db?.isOpen ?? false);
  String? get lastError => _lastError;
  List<LocalSafetyEvent> get allEvents => List.unmodifiable(_events);
  List<LocalSafetyEvent> get unsyncedEvents => List.unmodifiable(_events.where((e) => !e.synced));
  int get pendingCount => _events.where((e) => !e.synced).length;
  void _changed() { if (!_disposed) notifyListeners(); }

  Future<void> initialize({DatabaseFactory? factory}) async {
    if (isInitialized) return;
    if (_opening != null) return _opening;
    _opening = _open(factory);
    await _opening;
    _opening = null;
  }

  Future<void> _open(DatabaseFactory? factory) async {
    try {
      if (_db == null || !_db!.isOpen) {
        final selected = factory ?? databaseFactory;
        final path = p.join(await selected.getDatabasesPath(), dbFileName);
        _db = (await AppDatabase.open(factory: selected, path: path)).db;
      }
      // Repair queues for older event rows without fabricating server acknowledgements.
      await _db!.execute("INSERT OR IGNORE INTO sync_queue(id,entity_type,entity_id,payload_json,status) SELECT 'sq_' || event_id,'SAFETY_EVENT',event_id,'{}','PENDING' FROM safety_events WHERE synced=0");
      _initialized = true;
      _lastError = null;
      await _reload();
    } catch (error) {
      _initialized = false;
      _lastError = 'SQLite unavailable: $error';
    }
    _changed();
  }

  Future<Database> _database() async {
    await initialize();
    if (!isInitialized) throw StateError(_lastError ?? 'SQLite unavailable');
    return _db!;
  }

  Future<void> _reload() async {
    final rows = await _db!.rawQuery('SELECT * FROM safety_events WHERE synced=0 OR event_id IN (SELECT event_id FROM safety_events ORDER BY timestamp DESC LIMIT $maxRetentionCount) ORDER BY timestamp DESC');
    _events..clear()..addAll(rows.map(LocalSafetyEvent.fromMap));
    _changed();
  }

  Future<void> recordEvent(LocalSafetyEvent event) async {
    try {
      final db = await _database();
      await db.transaction((txn) async {
        final existing = await txn.query('safety_events', where: 'event_id=?', whereArgs: [event.eventId]);
        if (existing.isNotEmpty) return;
        await txn.insert('safety_events', event.toMap());
        if (!event.synced) {
          await txn.insert('sync_queue', {'id':'sq_${event.eventId}', 'entity_type':'SAFETY_EVENT',
            'entity_id':event.eventId, 'payload_json':jsonEncode(event.toMap()), 'status':'PENDING'});
        }
        await txn.rawDelete('DELETE FROM safety_events WHERE synced=1 AND event_id NOT IN (SELECT event_id FROM safety_events ORDER BY timestamp DESC LIMIT $maxRetentionCount)');
      });
      _lastError = null;
      await _reload();
    } catch (error) {
      _lastError = 'Event was not saved: $error';
      _changed();
      rethrow;
    }
  }

  Future<List<LocalSafetyEvent>> pendingBatch({int limit = 100, bool force = false}) async {
    final db = await _database();
    final rows = await db.rawQuery('SELECT e.* FROM safety_events e JOIN sync_queue q ON q.entity_id=e.event_id WHERE e.synced=0 AND q.entity_type=\'SAFETY_EVENT\' AND (?=1 OR q.next_retry_at IS NULL OR q.next_retry_at<=?) ORDER BY e.timestamp LIMIT ?',
      [force ? 1 : 0, DateTime.now().toUtc().toIso8601String(), limit]);
    return rows.map(LocalSafetyEvent.fromMap).toList();
  }

  Future<void> recordFailure(List<String> ids, String error, Duration delay) async {
    final db = await _database();
    final now = DateTime.now().toUtc();
    await db.transaction((txn) async {
      for (final id in ids) {
        await txn.rawUpdate('UPDATE sync_queue SET retry_count=retry_count+1,last_attempt=?,next_retry_at=?,status=\'PENDING\',error_message=? WHERE entity_id=?',
          [now.toIso8601String(), now.add(delay).toIso8601String(), error, id]);
      }
    });
    _changed();
  }

  Future<void> markSynced(List<String> eventIds) async {
    final db = await _database();
    await db.transaction((txn) async {
      for (final id in eventIds) {
        await txn.update('safety_events', {'synced':1}, where:'event_id=?', whereArgs:[id]);
        await txn.delete('sync_queue', where:'entity_id=? AND entity_type=?', whereArgs:[id,'SAFETY_EVENT']);
      }
    });
    _lastError = null;
    await _reload();
  }

  Future<void> recordLocation({required double latitude, required double longitude, double? accuracy,
    double? altitude, double? speed, double? bearing}) async {
    final db = await _database();
    await db.insert('location_history', {'timestamp':DateTime.now().toUtc().toIso8601String(),
      'latitude':latitude,'longitude':longitude,'accuracy':accuracy,'altitude':altitude,'speed':speed,'bearing':bearing});
    await db.rawDelete('DELETE FROM location_history WHERE id NOT IN (SELECT id FROM location_history ORDER BY id DESC LIMIT 1000)');
  }

  Future<void> clearEvents() async {
    final db = await _database();
    await db.transaction((txn) async {
      await txn.delete('sync_queue');
      await txn.delete('safety_events');
      await txn.delete('alerts');
      await txn.delete('location_history');
    });
    await _reload();
  }

  @override
  void dispose() {
    _disposed = true;
    if (_ownsDatabase && _db != null) unawaited(_db!.close());
    super.dispose();
  }
}
