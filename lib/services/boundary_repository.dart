import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/boundary_model.dart';

/// Typed database failure. The original error is preserved in [cause] and
/// never swallowed: callers (and Phase 5) can distinguish storage failures
/// from empty results.
class BoundaryException implements Exception {
  BoundaryException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'BoundaryException: $message${cause == null ? '' : ' (caused by $cause)'}';
}

/// CRUD over the `boundaries` table (Phase 4).
///
/// Inserts use upsert semantics (replace on duplicate id) so re-seeding is
/// safe. Reads return an empty list — never null — when nothing matches.
class BoundaryRepository {
  BoundaryRepository(this._db);

  final Database _db;

  Future<void> insertBoundary(BoundaryModel boundary) {
    return _guard(
      () => _db.insert(
        AppDatabase.tableBoundaries,
        boundary.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      ),
      'insert boundary "${boundary.id}"',
    );
  }

  Future<void> insertBoundaries(List<BoundaryModel> boundaries) {
    return _guard(() async {
      final batch = _db.batch();
      for (final boundary in boundaries) {
        batch.insert(
          AppDatabase.tableBoundaries,
          boundary.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    }, 'bulk insert ${boundaries.length} boundaries');
  }

  Future<BoundaryModel?> getBoundaryById(String id) {
    return _guard(() async {
      final rows = await _db.query(
        AppDatabase.tableBoundaries,
        where: '${BoundaryModel.fieldId} = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return BoundaryModel.fromMap(rows.first);
    }, 'load boundary "$id"');
  }

  Future<List<BoundaryModel>> getAllBoundaries() {
    return _guard(() async {
      final rows = await _db.query(
        AppDatabase.tableBoundaries,
        orderBy: BoundaryModel.fieldName,
      );
      return [for (final row in rows) BoundaryModel.fromMap(row)];
    }, 'load all boundaries');
  }

  Future<List<BoundaryModel>> getEnabledBoundaries() {
    return _guard(() async {
      final rows = await _db.query(
        AppDatabase.tableBoundaries,
        where: '${BoundaryModel.fieldEnabled} = ?',
        whereArgs: [1],
        orderBy: BoundaryModel.fieldName,
      );
      return [for (final row in rows) BoundaryModel.fromMap(row)];
    }, 'load enabled boundaries');
  }

  Future<List<BoundaryModel>> getBoundariesByType(String type) {
    return _guard(() async {
      final rows = await _db.query(
        AppDatabase.tableBoundaries,
        where: '${BoundaryModel.fieldType} = ?',
        whereArgs: [type],
        orderBy: BoundaryModel.fieldName,
      );
      return [for (final row in rows) BoundaryModel.fromMap(row)];
    }, 'load boundaries of type "$type"');
  }

  /// Returns the number of rows updated (0 when the id does not exist).
  Future<int> updateBoundary(BoundaryModel boundary) {
    return _guard(
      () => _db.update(
        AppDatabase.tableBoundaries,
        boundary.toMap(),
        where: '${BoundaryModel.fieldId} = ?',
        whereArgs: [boundary.id],
      ),
      'update boundary "${boundary.id}"',
    );
  }

  /// Returns the number of rows deleted (0 when the id does not exist).
  Future<int> deleteBoundary(String id) {
    return _guard(
      () => _db.delete(
        AppDatabase.tableBoundaries,
        where: '${BoundaryModel.fieldId} = ?',
        whereArgs: [id],
      ),
      'delete boundary "$id"',
    );
  }

  /// Returns the number of rows removed.
  Future<int> clearBoundaries() {
    return _guard(
      () => _db.delete(AppDatabase.tableBoundaries),
      'clear boundaries',
    );
  }

  Future<int> countBoundaries({bool enabledOnly = false}) {
    return _guard(() async {
      final rows = await _db.rawQuery(
        'SELECT COUNT(*) AS n FROM ${AppDatabase.tableBoundaries}'
        '${enabledOnly ? ' WHERE ${BoundaryModel.fieldEnabled} = 1' : ''}',
      );
      return Sqflite.firstIntValue(rows) ?? 0;
    }, 'count boundaries');
  }

  Future<T> _guard<T>(Future<T> Function() operation, String what) async {
    try {
      return await operation();
    } on BoundaryException {
      rethrow;
    } catch (e) {
      throw BoundaryException('Failed to $what.', e);
    }
  }
}
