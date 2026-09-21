import 'package:border_safety_alert/models/gps_snapshot.dart';
import 'package:border_safety_alert/models/safety_state.dart';
import 'package:border_safety_alert/services/gps_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'helpers/fake_location_provider.dart';

/// Pumps the event queue so broadcast stream events reach the service.
Future<void> _flush() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  group('GpsService', () {
    test('locks with the current fix when granted', () async {
      final provider = FakeLocationProvider(
        current: FakeLocationProvider.fix(latitude: 10.1, longitude: 78.1),
      );
      final service = GpsService(provider: provider);
      addTearDown(service.dispose);

      await service.start();

      expect(service.snapshot.fix, GpsFixState.locked);
      expect(service.snapshot.permission, LocationPermissionState.granted);
      expect(service.snapshot.location?.latitude, 10.1);
      expect(service.snapshot.poorAccuracy, isFalse);
    });

    test('reports disabled location services without crashing', () async {
      final provider = FakeLocationProvider(serviceEnabled: false);
      final service = GpsService(provider: provider);
      addTearDown(service.dispose);

      await service.start();

      expect(service.snapshot.fix, GpsFixState.unavailable);
      expect(service.snapshot.serviceEnabled, isFalse);
      expect(service.snapshot.location, isNull);
      expect(service.snapshot.message, contains('disabled'));
    });

    test('reports denied permission', () async {
      final provider = FakeLocationProvider(
        checkResult: LocationPermission.denied,
        requestResult: LocationPermission.denied,
      );
      final service = GpsService(provider: provider);
      addTearDown(service.dispose);

      await service.start();

      expect(service.snapshot.fix, GpsFixState.unavailable);
      expect(service.snapshot.permission, LocationPermissionState.denied);
      expect(service.snapshot.location, isNull);
    });

    test('reports permanently denied permission', () async {
      final provider = FakeLocationProvider(
        checkResult: LocationPermission.denied,
        requestResult: LocationPermission.deniedForever,
      );
      final service = GpsService(provider: provider);
      addTearDown(service.dispose);

      await service.start();

      expect(
        service.snapshot.permission,
        LocationPermissionState.deniedForever,
      );
      expect(service.snapshot.message, contains('settings'));
    });

    test('survives provider errors without throwing', () async {
      final provider = FakeLocationProvider(throwOnServiceCheck: true);
      final service = GpsService(provider: provider);
      addTearDown(service.dispose);

      await service.start(); // Must not throw.

      expect(service.snapshot.fix, GpsFixState.unavailable);
      expect(service.snapshot.location, isNull);
    });

    test('updates live from the stream and flags poor accuracy', () async {
      final provider = FakeLocationProvider();
      final service = GpsService(provider: provider);
      addTearDown(service.dispose);

      await service.start();
      provider.addPosition(
        FakeLocationProvider.fix(latitude: 11, longitude: 79, accuracy: 120),
      );
      await _flush();

      expect(service.snapshot.fix, GpsFixState.locked);
      expect(service.snapshot.location?.latitude, 11);
      expect(service.snapshot.poorAccuracy, isTrue);
      expect(service.snapshot.message, contains('Poor GPS accuracy'));
    });

    test('drops invalid coordinates and keeps the previous fix', () async {
      final provider = FakeLocationProvider(
        current: FakeLocationProvider.fix(latitude: 10, longitude: 78),
      );
      final service = GpsService(provider: provider);
      addTearDown(service.dispose);

      await service.start();
      provider.addPosition(
        FakeLocationProvider.fix(latitude: 250, longitude: 78),
      );
      await _flush();

      expect(service.snapshot.location?.latitude, 10);
      expect(service.snapshot.fix, GpsFixState.locked);
    });

    test('stream error with no fix becomes unavailable, not a crash', () async {
      final provider = FakeLocationProvider();
      final service = GpsService(provider: provider);
      addTearDown(service.dispose);

      await service.start();
      provider.addError(StateError('stream broke'));
      await _flush();

      expect(service.snapshot.fix, GpsFixState.unavailable);
      expect(service.snapshot.location, isNull);
    });

    test('stream error keeps last fix and marks it stale', () async {
      final provider = FakeLocationProvider(
        current: FakeLocationProvider.fix(latitude: 10, longitude: 78),
      );
      final service = GpsService(provider: provider);
      addTearDown(service.dispose);

      await service.start();
      provider.addError(StateError('stream broke'));
      await _flush();

      expect(service.snapshot.location?.latitude, 10);
      expect(service.snapshot.stale, isTrue);
      expect(service.snapshot.message, contains('last known fix'));
    });

    test(
      'retry re-checks and re-subscribes without duplicating state',
      () async {
        final provider = FakeLocationProvider();
        final service = GpsService(provider: provider);
        addTearDown(service.dispose);

        await service.start();
        await service.start(); // Retry: re-runs checks, replaces subscription.

        provider.addPosition(
          FakeLocationProvider.fix(latitude: 12, longitude: 80),
        );
        await _flush();

        expect(service.snapshot.fix, GpsFixState.locked);
        expect(service.snapshot.location?.latitude, 12);
      },
    );
  });
}
