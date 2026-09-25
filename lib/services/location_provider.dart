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
/// Foreground fixes: best accuracy with continuous real-time streaming (0m filter).
class GeolocatorProvider implements LocationProvider {
  static LocationSettings get _settings {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 1),
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
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        // If last known position is fresh (< 2 minutes old), return it immediately
        final age = DateTime.now().difference(lastKnown.timestamp);
        if (age.inMinutes < 2) {
          return lastKnown;
        }
      }
      // 2. Fetch fresh high-accuracy position
      return await Geolocator.getCurrentPosition(
        locationSettings: _settings,
      ).timeout(_timeLimit);
    } catch (_) {
      // If fresh fix timed out, fall back to last known position if available
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
