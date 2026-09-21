import 'package:flutter_test/flutter_test.dart';
import 'package:border_safety_alert/models/location_model.dart';
import 'package:border_safety_alert/services/tracking_service.dart';

void main() {
  group('TrackingService', () {
    late TrackingService tracking;

    setUp(() {
      tracking = TrackingService(maxPoints: 5);
    });

    test('initial state is idle and empty', () {
      expect(tracking.isIdle, isTrue);
      expect(tracking.isTracking, isFalse);
      expect(tracking.trail, isEmpty);
      expect(tracking.totalDistanceMeters, 0.0);
    });

    test('start, pause, resume, stop lifecycle', () {
      tracking.startTracking();
      expect(tracking.isTracking, isTrue);
      expect(tracking.status, TrackingStatus.tracking);

      tracking.pauseTracking();
      expect(tracking.isPaused, isTrue);
      expect(tracking.status, TrackingStatus.paused);

      tracking.resumeTracking();
      expect(tracking.isTracking, isTrue);

      tracking.stopTracking();
      expect(tracking.isIdle, isTrue);
    });

    test('adds valid GPS fixes while tracking and respects bounds', () {
      tracking.startTracking();

      final baseTime = DateTime(2026, 9, 20, 10, 0, 0);
      for (int i = 0; i < 7; i++) {
        tracking.addFix(
          LocationModel.validated(
            latitude: 10.7125 + (i * 0.001),
            longitude: 76.9791 + (i * 0.001),
            accuracy: 10.0,
            timestamp: baseTime.add(Duration(seconds: i)),
          ),
        );
      }

      expect(tracking.trail.length, 5); // maxPoints is 5
      expect(tracking.totalDistanceMeters, greaterThan(0.0));

      tracking.clearTrack();
      expect(tracking.trail, isEmpty);
      expect(tracking.totalDistanceMeters, 0.0);
    });

    test('does not record points when idle or paused', () {
      final fix = LocationModel.validated(
        latitude: 10.7125,
        longitude: 76.9791,
      );

      tracking.addFix(fix);
      expect(tracking.trail, isEmpty);

      tracking.startTracking();
      tracking.pauseTracking();
      tracking.addFix(fix);
      expect(tracking.trail, isEmpty);
    });
  });
}
