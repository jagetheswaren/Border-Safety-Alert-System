import 'package:border_safety_alert/models/safety_state.dart';
import 'package:border_safety_alert/services/boundary_import.dart';
import 'package:flutter_test/flutter_test.dart';

const _valid = '''
{"type": "FeatureCollection", "features": [
  {"type": "Feature",
   "properties": {"name": "Demo Restricted Zone A", "type": "restricted",
     "risk_level": "HIGH", "description": "Synthetic demo zone.",
     "source": "SYNTHETIC-DEMO-v0.1", "version": "0.1.0"},
   "geometry": {"type": "Polygon", "coordinates":
     [[[10.1, 78.1], [10.1, 78.2], [10.2, 78.2], [10.1, 78.1]]]}},
  {"type": "Feature",
   "properties": {"name": "Demo Forest B", "type": "forest",
     "risk_level": "MEDIUM", "country": "DemoLand"},
   "geometry": {"type": "Polygon", "coordinates":
     [[[10.5, 78.5], [10.5, 78.6], [10.6, 78.6], [10.5, 78.5]]]}}]}
''';

void main() {
  group('parseBoundariesFromGeoJson', () {
    test('parses the demo FeatureCollection', () {
      final boundaries = parseBoundariesFromGeoJson(_valid);

      expect(boundaries, hasLength(2));
      expect(boundaries.first.name, 'Demo Restricted Zone A');
      expect(boundaries.first.riskLevel, RiskLevel.high);
      expect(boundaries.first.isDemo, isTrue);
    });

    test('preserves geometry in lon/lat order', () {
      final first = parseBoundariesFromGeoJson(_valid).first;
      final ring = first.polygon.single;
      expect(ring.length, 4);
      // GeoJSON position [10.1, 78.1] -> lon 10.1, lat 78.1.
      expect(ring.first.longitude, 10.1);
      expect(ring.first.latitude, 78.1);
    });

    test('preserves metadata and derives stable ids', () {
      final boundaries = parseBoundariesFromGeoJson(_valid);
      final forest = boundaries[1];

      expect(forest.type, 'forest');
      expect(forest.country, 'DemoLand');
      expect(forest.description, isNull);
      expect(forest.id, 'demo-forest-b');
      // Re-parsing yields the same ids, so re-imports upsert.
      expect(
        parseBoundariesFromGeoJson(_valid).map((b) => b.id),
        boundaries.map((b) => b.id),
      );
    });

    test('rejects invalid JSON', () {
      expect(() => parseBoundariesFromGeoJson('nope'), throwsFormatException);
    });

    test('rejects non-FeatureCollection input', () {
      expect(
        () => parseBoundariesFromGeoJson('{"type": "Feature"}'),
        throwsFormatException,
      );
    });

    test('rejects features with missing properties', () {
      const bad = '''
{"type": "FeatureCollection", "features": [
  {"type": "Feature", "properties": {"name": "Nameless"},
   "geometry": {"type": "Polygon", "coordinates":
     [[[0, 0], [0, 1], [1, 1], [0, 0]]]}}]}''';
      expect(() => parseBoundariesFromGeoJson(bad), throwsFormatException);
    });

    test('rejects unknown risk levels', () {
      final bad = _valid.replaceFirst('"HIGH"', '"EXTREME"');
      expect(() => parseBoundariesFromGeoJson(bad), throwsFormatException);
    });

    test('rejects non-polygon and unclosed geometry', () {
      final point = _valid.replaceFirst('"Polygon"', '"Point"');
      expect(() => parseBoundariesFromGeoJson(point), throwsFormatException);

      const open = '''
{"type": "FeatureCollection", "features": [
  {"type": "Feature",
   "properties": {"name": "Open", "type": "custom", "risk_level": "LOW"},
   "geometry": {"type": "Polygon", "coordinates":
     [[[0, 0], [0, 1], [1, 1], [2, 2]]]}}]}''';
      expect(() => parseBoundariesFromGeoJson(open), throwsFormatException);
    });
  });
}
