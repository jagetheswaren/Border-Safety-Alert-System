/// Validated single GPS fix (Phase 3).
///
/// Coordinates outside their legal ranges are rejected at construction so an
/// invalid reading can never be presented as the current location. Sensor
/// values reported as negative (the platform convention for "unknown"
/// speed/heading/accuracy) are normalized to null.
library;

class LocationModel {
  const LocationModel({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speed,
    this.bearing,
    this.accuracy,
    this.altitude,
  });

  /// Validates and normalizes raw platform values.
  ///
  /// Throws [ArgumentError] for latitude outside [-90, 90] or longitude
  /// outside [-180, 180].
  factory LocationModel.validated({
    required double latitude,
    required double longitude,
    DateTime? timestamp,
    double? speed,
    double? bearing,
    double? accuracy,
    double? altitude,
  }) {
    if (!isValidLatitude(latitude)) {
      throw ArgumentError.value(latitude, 'latitude', 'Must be in [-90, 90]');
    }
    if (!isValidLongitude(longitude)) {
      throw ArgumentError.value(
        longitude,
        'longitude',
        'Must be in [-180, 180]',
      );
    }
    return LocationModel(
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp ?? DateTime.now(),
      // Negative sensor values mean "unknown" on the platform side.
      speed: speed == null || speed < 0 ? null : speed,
      bearing: bearing == null || bearing < 0 ? null : bearing,
      accuracy: accuracy == null || accuracy < 0 ? null : accuracy,
      // Altitude can legitimately be negative (below sea level).
      altitude: altitude,
    );
  }

  static bool isValidLatitude(double value) =>
      value.isFinite && value >= -90 && value <= 90;
  static bool isValidLongitude(double value) =>
      value.isFinite && value >= -180 && value <= 180;

  /// Latitude in degrees, guaranteed in [-90, 90].
  final double latitude;

  /// Longitude in degrees, guaranteed in [-180, 180].
  final double longitude;

  /// Speed in m/s, or null when unknown.
  final double? speed;

  /// Bearing in degrees (0-360), or null when unknown.
  final double? bearing;

  /// Horizontal accuracy radius in meters, or null when unknown.
  final double? accuracy;

  /// Altitude in meters (may be negative), or null when unknown.
  final double? altitude;

  final DateTime timestamp;

  bool isStaleAt(
    DateTime now, {
    Duration maxAge = const Duration(seconds: 30),
  }) {
    return now.difference(timestamp) > maxAge;
  }

  bool get isStale => isStaleAt(DateTime.now());
}
