import 'dart:convert';

import 'package:border_safety_alert/models/boundary_model.dart';
import 'package:border_safety_alert/models/safety_state.dart';
import 'package:flutter_test/flutter_test.dart';

BoundaryModel _zone({
  String id = 'demo-zone',
  RiskLevel risk = RiskLevel.high,
  bool enabled = true,
}) {
  return BoundaryModel(
    id: id,
    name: 'Demo Zone',
    type: 'restricted',
    riskLevel: risk,
    country: 'DemoLand',
    description: 'Synthetic demo polygon.',
    polygon: [
      [
        const BoundaryPosition(longitude: 10.1, latitude: 78.1),
        const BoundaryPosition(longitude: 10.1, latitude: 78.2),
        const BoundaryPosition(longitude: 10.2, latitude: 78.2),
        const BoundaryPosition(longitude: 10.1, latitude: 78.1),
      ],
    ],
    source: 'SYNTHETIC-DEMO-v0.1',
    version: '0.1.0',
    updatedAt: DateTime.utc(2026, 9, 10, 12),
    enabled: enabled,
  );
}

void main() {
  group('BoundaryModel', () {
    test('toMap/fromMap round-trip preserves every field', () {
      final restored = BoundaryModel.fromMap(_zone().toMap());

      expect(restored.id, 'demo-zone');
      expect(restored.name, 'Demo Zone');
      expect(restored.type, 'restricted');
      expect(restored.riskLevel, RiskLevel.high);
      expect(restored.country, 'DemoLand');
      expect(restored.description, 'Synthetic demo polygon.');
      expect(restored.polygon.length, 1);
      expect(restored.polygon.first.length, 4);
      expect(restored.source, 'SYNTHETIC-DEMO-v0.1');
      expect(restored.version, '0.1.0');
      expect(restored.updatedAt, DateTime.utc(2026, 9, 10, 12));
      expect(restored.enabled, isTrue);
    });

    test('polygon precision survives JSON serialization', () {
      const lon = 78.12345678901234;
      const lat = 10.98765432109876;
      final model = BoundaryModel(
        id: 'precise',
        name: 'Precise',
        riskLevel: RiskLevel.low,
        polygon: [
          [BoundaryPosition(longitude: lon, latitude: lat)],
        ],
      );
      final restored = BoundaryModel.fromMap(model.toMap());
      expect(restored.polygon.first.first.longitude, lon);
      expect(restored.polygon.first.first.latitude, lat);
    });

    test('nullable fields round-trip as null', () {
      const model = BoundaryModel(
        id: 'bare',
        name: 'Bare',
        riskLevel: RiskLevel.medium,
      );
      final restored = BoundaryModel.fromMap(model.toMap());
      expect(restored.country, isNull);
      expect(restored.description, isNull);
      expect(restored.polygon, isEmpty);
      expect(restored.source, isNull);
      expect(restored.version, isNull);
      expect(restored.updatedAt, isNull);
      expect(restored.enabled, isTrue);
    });

    test('enabled converts to 0 and back', () {
      final restored = BoundaryModel.fromMap(_zone(enabled: false).toMap());
      expect(restored.enabled, isFalse);
      expect(_zone(enabled: false).toMap()['enabled'], 0);
    });

    test('accepts all risk levels in either case', () {
      for (final entry in {
        'LOW': RiskLevel.low,
        'medium': RiskLevel.medium,
        'High': RiskLevel.high,
      }.entries) {
        final restored = BoundaryModel.fromMap({
          ..._zone().toMap(),
          'risk_level': entry.key,
        });
        expect(restored.riskLevel, entry.value);
      }
    });

    test('rejects unknown risk level', () {
      expect(
        () => BoundaryModel.fromMap({
          ..._zone().toMap(),
          'risk_level': 'EXTREME',
        }),
        throwsFormatException,
      );
    });

    test('rejects missing required fields', () {
      final map = _zone().toMap()..remove('name');
      expect(() => BoundaryModel.fromMap(map), throwsFormatException);
    });

    test('rejects malformed polygon JSON', () {
      expect(
        () =>
            BoundaryModel.fromMap({..._zone().toMap(), 'polygon_data': 'nope'}),
        throwsFormatException,
      );
      expect(
        () => BoundaryModel.fromMap({
          ..._zone().toMap(),
          'polygon_data': jsonEncode({'a': 1}),
        }),
        throwsFormatException,
      );
    });

    test('isDemo flags synthetic sources only', () {
      expect(_zone().isDemo, isTrue);
      const real = BoundaryModel(
        id: 'x',
        name: 'X',
        riskLevel: RiskLevel.low,
        source: 'Survey of DemoLand 2026',
      );
      expect(real.isDemo, isFalse);
      const none = BoundaryModel(id: 'y', name: 'Y', riskLevel: RiskLevel.low);
      expect(none.isDemo, isFalse);
    });
  });
}
