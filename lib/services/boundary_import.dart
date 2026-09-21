import 'dart:convert';

import '../models/boundary_model.dart';
import '../models/safety_state.dart';

/// GeoJSON → [BoundaryModel] importer (Phase 4).
///
/// Expected input: a `FeatureCollection` of `Feature` objects with `Polygon`
/// geometry (RFC 7946 `[lon, lat]` position order) and properties
/// `name`, `type`, `risk_level` (LOW|MEDIUM|HIGH) plus optional `country`,
/// `description`, `source`, `version`, `updated_at`. Features may carry an
/// explicit string `id`; otherwise a stable slug of the name is used so
/// re-imports upsert instead of duplicating.
///
/// Anything else raises [FormatException] with the feature index — malformed
/// input never produces fabricated boundaries.
List<BoundaryModel> parseBoundariesFromGeoJson(String raw) {
  late final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException catch (e) {
    throw FormatException('Boundary data is not valid JSON: $e');
  }
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('Boundary data must be a JSON object.');
  }
  if (decoded['type'] != 'FeatureCollection') {
    throw FormatException(
      'Boundary data must be a FeatureCollection, got "${decoded['type']}".',
    );
  }
  final features = decoded['features'];
  if (features is! List) {
    throw const FormatException('FeatureCollection is missing "features".');
  }
  return [
    for (var i = 0; i < features.length; i++) _parseFeature(features[i], i),
  ];
}

BoundaryModel _parseFeature(Object? feature, int index) {
  String error(String detail) => 'Feature #$index: $detail.';
  if (feature is! Map<String, Object?> || feature['type'] != 'Feature') {
    throw FormatException(error('expected a Feature object'));
  }
  final properties = feature['properties'];
  if (properties is! Map<String, Object?>) {
    throw FormatException(error('missing "properties"'));
  }

  String requiredText(String key) {
    final value = properties[key];
    if (value is! String || value.isEmpty) {
      throw FormatException(error('missing required property "$key"'));
    }
    return value;
  }

  final name = requiredText('name');
  final type = requiredText('type');
  final riskRaw = requiredText('risk_level').toLowerCase();
  late final RiskLevel risk;
  try {
    risk = RiskLevel.values.byName(riskRaw);
  } on ArgumentError {
    throw FormatException(error('unknown risk_level "$riskRaw"'));
  }

  final geometry = feature['geometry'];
  if (geometry is! Map<String, Object?> || geometry['type'] != 'Polygon') {
    throw FormatException(error('geometry must be a Polygon'));
  }
  final coordinates = geometry['coordinates'];
  if (coordinates is! List || coordinates.isEmpty) {
    throw FormatException(error('Polygon has no rings'));
  }
  final rings = <List<BoundaryPosition>>[];
  for (final ring in coordinates) {
    if (ring is! List || ring.length < 4) {
      throw FormatException(error('linear ring needs at least 4 positions'));
    }
    final positions = [
      for (final pair in ring) BoundaryPosition.fromPair(pair),
    ];
    if (positions.first.longitude != positions.last.longitude ||
        positions.first.latitude != positions.last.latitude) {
      throw FormatException(error('linear ring is not closed'));
    }
    rings.add(positions);
  }

  final rawId = properties['id'];
  final id = rawId is String && rawId.isNotEmpty ? rawId : _slug(name);
  if (id.isEmpty) {
    throw FormatException(error('cannot derive a stable id from "$name"'));
  }

  String? optionalText(String key) {
    final value = properties[key];
    if (value == null) return null;
    if (value is! String) {
      throw FormatException(error('property "$key" must be a string'));
    }
    return value.isEmpty ? null : value;
  }

  DateTime? updatedAt;
  final rawUpdated = optionalText('updated_at');
  if (rawUpdated != null) {
    updatedAt = DateTime.tryParse(rawUpdated);
    if (updatedAt == null) {
      throw FormatException(error('updated_at is not ISO-8601'));
    }
  }

  return BoundaryModel(
    id: id,
    name: name,
    type: type,
    riskLevel: risk,
    country: optionalText('country'),
    description: optionalText('description'),
    polygon: rings,
    source: optionalText('source'),
    version: optionalText('version'),
    updatedAt: updatedAt,
  );
}

/// Lowercase slug used as a stable fallback id (e.g. "Demo Forest B" →
/// "demo-forest-b"). Deterministic, so re-imports upsert the same row.
String _slug(String name) {
  return name
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp('^-+|-+\$'), '');
}
