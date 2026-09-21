import 'dart:async';

import 'package:border_safety_alert/services/location_provider.dart';
import 'package:geolocator/geolocator.dart';

/// Scriptable [LocationProvider] fake: no platform channels, no real GPS.
///
/// Tests drive it via [addPosition]/[addError] and read [startCalls].
class FakeLocationProvider implements LocationProvider {
  FakeLocationProvider({
    this.serviceEnabled = true,
    this.checkResult = LocationPermission.whileInUse,
    this.requestResult = LocationPermission.whileInUse,
    this.current,
    this.throwOnServiceCheck = false,
    this.throwOnPermissionCheck = false,
  });

  bool serviceEnabled;
  LocationPermission checkResult;
  LocationPermission requestResult;
  Position? current;
  bool throwOnServiceCheck;
  bool throwOnPermissionCheck;

  final StreamController<Position> controller =
      StreamController<Position>.broadcast();
  int startCalls = 0;

  static Position fix({
    required double latitude,
    required double longitude,
    double accuracy = 8,
    double altitude = 100,
    double heading = 90,
    double speed = 5,
    DateTime? timestamp,
  }) {
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp ?? DateTime(2026, 9, 10, 12),
      accuracy: accuracy,
      altitude: altitude,
      altitudeAccuracy: 1,
      heading: heading,
      headingAccuracy: 1,
      speed: speed,
      speedAccuracy: 0.1,
    );
  }

  void addPosition(Position position) => controller.add(position);
  void addError(Object error) => controller.addError(error);

  @override
  Future<bool> isServiceEnabled() async {
    if (throwOnServiceCheck) throw StateError('service check failed');
    return serviceEnabled;
  }

  @override
  Future<LocationPermission> checkPermission() async {
    if (throwOnPermissionCheck) throw StateError('permission check failed');
    return checkResult;
  }

  @override
  Future<LocationPermission> requestPermission() async => requestResult;

  @override
  Future<Position?> currentPosition() async => current;

  @override
  Stream<Position> positionStream() {
    startCalls++;
    return controller.stream;
  }
}
