import 'package:border_safety_alert/models/location_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocationModel', () {
    test('accepts a valid fix', () {
      final fix = LocationModel.validated(
        latitude: 10.12345,
        longitude: 78.54321,
        timestamp: DateTime(2026, 9, 10, 12),
        speed: 12.5,
        bearing: 85,
        accuracy: 8,
        altitude: 250,
      );
      expect(fix.latitude, 10.12345);
      expect(fix.speed, 12.5);
      expect(fix.bearing, 85);
      expect(fix.isStaleAt(DateTime(2026, 9, 10, 12, 0, 10)), isFalse);
    });

    test('accepts boundary coordinates +-90 / +-180', () {
      expect(
        () => LocationModel.validated(latitude: -90, longitude: -180),
        returnsNormally,
      );
      expect(
        () => LocationModel.validated(latitude: 90, longitude: 180),
        returnsNormally,
      );
    });

    test('rejects latitude outside [-90, 90]', () {
      expect(
        () => LocationModel.validated(latitude: 90.001, longitude: 0),
        throwsArgumentError,
      );
      expect(
        () => LocationModel.validated(latitude: -91, longitude: 0),
        throwsArgumentError,
      );
    });

    test('rejects longitude outside [-180, 180]', () {
      expect(
        () => LocationModel.validated(latitude: 0, longitude: 180.5),
        throwsArgumentError,
      );
      expect(
        () => LocationModel.validated(latitude: 0, longitude: -200),
        throwsArgumentError,
      );
    });

    test('normalizes negative sensor values to unknown (null)', () {
      final fix = LocationModel.validated(
        latitude: 0,
        longitude: 0,
        speed: -1,
        bearing: -1,
        accuracy: -1,
      );
      expect(fix.speed, isNull);
      expect(fix.bearing, isNull);
      expect(fix.accuracy, isNull);
    });

    test('keeps negative altitude (below sea level is valid)', () {
      final fix = LocationModel.validated(
        latitude: 0,
        longitude: 0,
        altitude: -430,
      );
      expect(fix.altitude, -430);
    });

    test('detects stale readings', () {
      final fix = LocationModel.validated(
        latitude: 0,
        longitude: 0,
        timestamp: DateTime(2026, 9, 10, 12),
      );
      expect(
        fix.isStaleAt(
          DateTime(2026, 9, 10, 12, 1),
          maxAge: const Duration(seconds: 30),
        ),
        isTrue,
      );
      expect(fix.isStaleAt(DateTime(2026, 9, 10, 12, 0, 10)), isFalse);
    });
  });
}
