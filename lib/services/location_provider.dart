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
/// Foreground fixes only: high accuracy with a 5 m distance filter.
/// No background location is requested.
class GeolocatorProvider implements LocationProvider {
  static const _settings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5,
  );

  static const _timeLimit = Duration(seconds: 15);

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
      // No fix within the limit (or disabled service / denied permission):
      // report null instead of hanging startup.
      return await Geolocator.getCurrentPosition(
        locationSettings: _settings,
      ).timeout(_timeLimit);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<Position> positionStream() =>
      Geolocator.getPositionStream(locationSettings: _settings);
}
