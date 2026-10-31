import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../database/app_database.dart';
import '../models/emergency_contact.dart';

class EmergencyContactsRepository {
  EmergencyContactsRepository({DatabaseFactory? factory, AppDatabase? appDatabase})
      : _customFactory = factory,
        _appDb = appDatabase;

  final DatabaseFactory? _customFactory;
  AppDatabase? _appDb;

  DatabaseFactory get _factory {
    if (_customFactory != null) return _customFactory;
    try {
      return databaseFactory;
    } catch (_) {
      return databaseFactoryFfi;
    }
  }

  Future<AppDatabase> _getDb() async {
    if (_appDb != null) {
      await _seedDefaultsIfNeeded(_appDb!);
      return _appDb!;
    }
    final dbPath = await _factory.getDatabasesPath();
    final path = '$dbPath/border_safety.db';
    _appDb = await AppDatabase.open(factory: _factory, path: path);
    await _seedDefaultsIfNeeded(_appDb!);
    return _appDb!;
  }

  Future<void> _seedDefaultsIfNeeded(AppDatabase appDb) async {
    final countRes = await appDb.db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppDatabase.tableEmergencyContacts}',
    );
    final count = Sqflite.firstIntValue(countRes) ?? 0;
    if (count == 0) {
      final now = DateTime.now();
      final defaults = [
        EmergencyContact(
          id: 'contact_112',
          name: 'National Emergency Response (ERSS)',
          phoneNumber: '112',
          relationship: 'Emergency Services',
          whatsappEnabled: false,
          isActive: true,
          createdAt: now,
        ),
        EmergencyContact(
          id: 'contact_forest',
          name: 'State Forest & Wildlife Control Room',
          phoneNumber: '1926',
          relationship: 'Forest Department Helpline',
          whatsappEnabled: false,
          isActive: true,
          createdAt: now,
        ),
        EmergencyContact(
          id: 'contact_family',
          name: 'Primary Family Contact',
          phoneNumber: '+919876543210',
          relationship: 'Family Member',
          whatsappEnabled: true,
          isActive: true,
          createdAt: now,
        ),
      ];

      for (final contact in defaults) {
        await appDb.db.insert(
          AppDatabase.tableEmergencyContacts,
          contact.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  Future<List<EmergencyContact>> loadAllContacts() async {
    final appDb = await _getDb();
    final rows = await appDb.db.query(
      AppDatabase.tableEmergencyContacts,
      orderBy: 'created_at ASC',
    );
    return rows.map(EmergencyContact.fromMap).toList();
  }

  Future<List<EmergencyContact>> loadActiveContacts() async {
    final appDb = await _getDb();
    final rows = await appDb.db.query(
      AppDatabase.tableEmergencyContacts,
      where: 'is_active = 1',
      orderBy: 'created_at ASC',
    );
    return rows.map(EmergencyContact.fromMap).toList();
  }

  Future<void> saveContact(EmergencyContact contact) async {
    final appDb = await _getDb();
    await appDb.db.insert(
      AppDatabase.tableEmergencyContacts,
      contact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteContact(String contactId) async {
    final appDb = await _getDb();
    await appDb.db.delete(
      AppDatabase.tableEmergencyContacts,
      where: 'id = ?',
      whereArgs: [contactId],
    );
  }

  Future<void> toggleActive(String contactId, bool isActive) async {
    final appDb = await _getDb();
    await appDb.db.update(
      AppDatabase.tableEmergencyContacts,
      {'is_active': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [contactId],
    );
  }
}
