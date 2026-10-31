import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Platform boundary for location access (Phase 3).
///
/// [GpsService] talks only to this interface, so unit/widget tests can inject
/// fakes without a physical GPS receiver or platform channels.
abstract class LocationProvider {
  Future<bool> isServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<Position?> currentPosition();
  Stream<Position> positionStream();
}

/// Production implementation backed by the geolocator plugin.
///
/// Foreground fixes use navigation accuracy on Android and a short distance
/// filter so the map follows real movement without treating every GPS jitter
/// sample as a meaningful position change.
class GeolocatorProvider implements LocationProvider {
  static LocationSettings get _settings {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 2),
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
    );
  }

  static const _timeLimit = Duration(seconds: 10);

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  @override
  Future<Position?> currentPosition() async {
    try {
      // 1. Try immediate last known position for instant startup lock
      final lastKnown = kIsWeb ? null : await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        // If last known position is reasonable (< 5 minutes old), return it immediately
        final age = DateTime.now().difference(lastKnown.timestamp);
        if (age >= Duration.zero && age <= const Duration(minutes: 5)) {
          return lastKnown;
        }
      }
      // 2. Fetch fresh high-accuracy position
      return await Geolocator.getCurrentPosition(
        locationSettings: _settings,
      ).timeout(_timeLimit);
    } catch (_) {
      // If fresh fix timed out, fall back to last known position if available
      if (kIsWeb) return null;
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Stream<Position> positionStream() =>
      Geolocator.getPositionStream(locationSettings: _settings);
}
