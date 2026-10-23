import 'package:flutter_test/flutter_test.dart';
import 'package:border_safety_alert/models/location_model.dart';
import 'package:border_safety_alert/services/motion_service.dart';

void main() {
  group('MotionService Tests', () {
    late MotionService service;

    setUp(() {
      service = MotionService();
    });

    test('Initial snapshot has stationary unknown state', () {
      final snapshot = service.snapshot;
      expect(snapshot.activity, UserActivity.unknown);
      expect(snapshot.isStationary, isTrue);
      expect(snapshot.smoothedSpeedMps, 0.0);
    });

    test('Classifies stationary when speed is below threshold', () {
      final now = DateTime.now();
      final loc = LocationModel.validated(
        latitude: 10.7000,
        longitude: 76.9000,
        timestamp: now,
        speed: 0.2, // Below 0.5 m/s
        bearing: 0.0,
      );

      final snapshot = service.processLocation(loc);
      expect(snapshot.activity, UserActivity.stationary);
      expect(snapshot.isStationary, isTrue);
      expect(snapshot.confidence, greaterThanOrEqualTo(0.9));
    });

    test('Classifies walking for human pedestrian speeds', () {
      final now = DateTime.now();
      final loc = LocationModel.validated(
        latitude: 10.7000,
        longitude: 76.9000,
        timestamp: now,
        speed: 1.4, // ~5 km/h walking
        bearing: 45.0,
      );

      final snapshot = service.processLocation(loc);
      expect(snapshot.activity, UserActivity.walking);
      expect(snapshot.isStationary, isFalse);
      expect(snapshot.smoothedSpeedKmh, closeTo(5.04, 0.2));
    });

    test('Classifies running for running pace', () {
      final now = DateTime.now();
      final loc = LocationModel.validated(
        latitude: 10.7000,
        longitude: 76.9000,
        timestamp: now,
        speed: 3.5, // ~12.6 km/h running
        bearing: 90.0,
      );

      final snapshot = service.processLocation(loc);
      expect(snapshot.activity, UserActivity.running);
      expect(snapshot.isStationary, isFalse);
    });

    test('Classifies vehicular for driving speeds', () {
      final now = DateTime.now();
      final loc = LocationModel.validated(
        latitude: 10.7000,
        longitude: 76.9000,
        timestamp: now,
        speed: 15.0, // 54 km/h vehicle
        bearing: 180.0,
      );

      final snapshot = service.processLocation(loc);
      expect(snapshot.activity, UserActivity.vehicular);
      expect(snapshot.isStationary, isFalse);
      expect(snapshot.smoothedSpeedKmh, closeTo(54.0, 1.0));
    });

    test('Detects rapid approach toward restricted boundary', () {
      final t0 = DateTime.now();
      final t1 = t0.add(const Duration(seconds: 2));

      final loc0 = LocationModel.validated(
        latitude: 10.7000,
        longitude: 76.9000,
        timestamp: t0,
        speed: 8.0,
        bearing: 90.0,
      );
      service.processLocation(loc0, distanceToNearestBoundaryMeters: 500.0);

      // 2 seconds later, distance decreased by 20 meters (10 m/s approach velocity)
      final loc1 = LocationModel.validated(
        latitude: 10.7001,
        longitude: 76.9002,
        timestamp: t1,
        speed: 8.0,
        bearing: 90.0,
      );
      final snapshot = service.processLocation(loc1, distanceToNearestBoundaryMeters: 480.0);

      expect(snapshot.isRapidApproach, isTrue);
      expect(snapshot.warning, MotionWarning.rapidApproach);
    });

    test('Applies stationary jitter suppression for micro-displacements', () {
      final t0 = DateTime.now();
      final t1 = t0.add(const Duration(seconds: 1));

      final loc0 = LocationModel.validated(
        latitude: 10.700000,
        longitude: 76.900000,
        timestamp: t0,
        speed: 0.1,
        accuracy: 10.0,
      );
      service.processLocation(loc0);

      // Micro-drift: 0.5 meters while speed is near zero
      final loc1 = LocationModel.validated(
        latitude: 10.700003,
        longitude: 76.900002,
        timestamp: t1,
        speed: 0.1,
        accuracy: 10.0,
      );
      final snapshot = service.processLocation(loc1);

      expect(snapshot.stationaryDriftFiltered, isTrue);
    });

    test('Calculates positive acceleration during speedup', () {
      final t0 = DateTime.now();
      final t1 = t0.add(const Duration(seconds: 2));

      final loc0 = LocationModel.validated(
        latitude: 10.7000,
        longitude: 76.9000,
        timestamp: t0,
        speed: 2.0,
      );
      service.processLocation(loc0);

      final loc1 = LocationModel.validated(
        latitude: 10.7001,
        longitude: 76.9001,
        timestamp: t1,
        speed: 6.0,
      );
      final snapshot = service.processLocation(loc1);

      // dv = 4.0 m/s over 2.0s = 2.0 m/s^2
      expect(snapshot.accelerationMps2, closeTo(2.0, 0.1));
    });

    test('Reset clears all state back to initial', () {
      final loc = LocationModel.validated(
        latitude: 10.7000,
        longitude: 76.9000,
        timestamp: DateTime.now(),
        speed: 10.0,
      );
      service.processLocation(loc);
      service.reset();

      expect(service.snapshot.activity, UserActivity.unknown);
      expect(service.snapshot.smoothedSpeedMps, 0.0);
    });
  });
}
