/// Offline boundary model (Phase 4).
///
/// Persistence-agnostic: [toMap]/[fromMap] use plain maps whose keys match the
/// SQLite `boundaries` table (see lib/database/app_database.dart), but the
/// model itself imports nothing from sqflite.
///
/// Polygon serialization: `polygon_data` is a JSON string of GeoJSON-style
/// coordinate rings: `[[[lon, lat], ...], ...]` (outer ring first, then
/// holes). Doubles round-trip through JSON without precision loss.
library;

import 'dart:convert';

import 'safety_state.dart';

/// Single GeoJSON position: [longitude, latitude] order per RFC 7946.
class BoundaryPosition {
  const BoundaryPosition({required this.longitude, required this.latitude});

  final double longitude;
  final double latitude;

  List<double> toPair() => [longitude, latitude];

  static BoundaryPosition fromPair(Object? pair) {
    if (pair is! List || pair.length < 2) {
      throw FormatException('Invalid position (expected [lon, lat]): $pair');
    }
    final lon = pair[0];
    final lat = pair[1];
    if (lon is! num || lat is! num) {
      throw FormatException('Non-numeric position: $pair');
    }
    return BoundaryPosition(
      longitude: lon.toDouble(),
      latitude: lat.toDouble(),
    );
  }
}

class BoundaryModel {
  const BoundaryModel({
    required this.id,
    required this.name,
    this.type = 'custom',
    required this.riskLevel,
    this.country,
    this.description,
    this.polygon = const [],
    this.source,
    this.version,
    this.updatedAt,
    this.enabled = true,
  });

  // Column names shared with the SQLite layer (single source of truth).
  static const fieldId = 'id';
  static const fieldName = 'name';
  static const fieldType = 'type';
  static const fieldRiskLevel = 'risk_level';
  static const fieldCountry = 'country';
  static const fieldDescription = 'description';
  static const fieldPolygonData = 'polygon_data';
  static const fieldSource = 'source';
  static const fieldVersion = 'version';
  static const fieldUpdatedAt = 'updated_at';
  static const fieldEnabled = 'enabled';

  final String id;
  final String name;

  /// Open set: international_border | forest | wildlife | military | mining |
  /// disaster | coastal | restricted | custom (see docs/boundary_database.md).
  final String type;
  final RiskLevel riskLevel;
  final String? country;
  final String? description;

  /// Polygon rings: outer ring first, then holes. Empty = point metadata only.
  final List<List<BoundaryPosition>> polygon;
  final String? source;
  final String? version;
  final DateTime? updatedAt;
  final bool enabled;

  /// True when the source identifies synthetic demo data (never authoritative).
  ///
  /// Matches `SYNTHETIC` anywhere, or `DEMO` as a standalone token, so real
  /// sources that merely contain those letters (e.g. "DemoLand survey")
  /// are not mislabeled.
  bool get isDemo {
    final marker = (source ?? '').toUpperCase();
    if (marker.contains('SYNTHETIC')) return true;
    return RegExp('(^|[^A-Z])DEMO([^A-Z]|\$)').hasMatch(marker);
  }

  Map<String, Object?> toMap() {
    return {
      fieldId: id,
      fieldName: name,
      fieldType: type,
      fieldRiskLevel: riskLevel.name.toUpperCase(),
      fieldCountry: country,
      fieldDescription: description,
      fieldPolygonData: jsonEncode([
        for (final ring in polygon) [for (final point in ring) point.toPair()],
      ]),
      fieldSource: source,
      fieldVersion: version,
      fieldUpdatedAt: updatedAt?.toIso8601String(),
      fieldEnabled: enabled ? 1 : 0,
    };
  }

  factory BoundaryModel.fromMap(Map<String, Object?> map) {
    Object? requiredField(String key) {
      final value = map[key];
      if (value == null ||
          (value is String && value.isEmpty && key != fieldPolygonData)) {
        throw FormatException('Boundary is missing required field "$key".');
      }
      return value;
    }

    final rawRisk = requiredField(fieldRiskLevel).toString().toLowerCase();
    late final RiskLevel risk;
    try {
      risk = RiskLevel.values.byName(rawRisk);
    } on ArgumentError {
      throw FormatException('Unknown risk_level "$rawRisk".');
    }

    final rawPolygon = map[fieldPolygonData];
    if (rawPolygon is! String) {
      throw FormatException('Boundary polygon_data must be a JSON string.');
    }
    late final Object? decoded;
    try {
      decoded = jsonDecode(rawPolygon);
    } on FormatException catch (e) {
      throw FormatException('Boundary polygon_data is not valid JSON: $e');
    }
    if (decoded is! List) {
      throw FormatException('Boundary polygon_data must be a list of rings.');
    }
    final rings = <List<BoundaryPosition>>[];
    for (final ring in decoded) {
      if (ring is! List) {
        throw FormatException('Boundary polygon ring must be a list: $ring');
      }
      rings.add([for (final pair in ring) BoundaryPosition.fromPair(pair)]);
    }

    final rawEnabled = map[fieldEnabled];
    final enabled = switch (rawEnabled) {
      null => true,
      int() => rawEnabled != 0,
      bool() => rawEnabled,
      _ => throw FormatException(
        'Boundary enabled must be 0/1, got $rawEnabled.',
      ),
    };

    DateTime? updatedAt;
    final rawUpdated = map[fieldUpdatedAt];
    if (rawUpdated is String && rawUpdated.isNotEmpty) {
      updatedAt = DateTime.tryParse(rawUpdated);
      if (updatedAt == null) {
        throw FormatException(
          'Boundary updated_at is not ISO-8601: $rawUpdated.',
        );
      }
    }

    return BoundaryModel(
      id: requiredField(fieldId).toString(),
      name: requiredField(fieldName).toString(),
      type: (map[fieldType] ?? 'custom').toString(),
      riskLevel: risk,
      country: map[fieldCountry]?.toString(),
      description: map[fieldDescription]?.toString(),
      polygon: rings,
      source: map[fieldSource]?.toString(),
      version: map[fieldVersion]?.toString(),
      updatedAt: updatedAt,
      enabled: enabled,
    );
  }
}
