/// Structured geo-fence output feeding the UI now and feature extraction later.
library;

import 'boundary_model.dart';
import 'geofence_state.dart';
import 'safety_state.dart';

class GeoFenceResult {
  const GeoFenceResult({
    required this.state,
    this.nearestBoundary,
    this.distanceToBoundaryMeters,
    this.insideBoundary = false,
    this.directionToBoundaryDegrees,
    this.bearingDifferenceDegrees,
  });

  /// Explicit unknown: no usable fix, no usable boundaries, or a calculation
  /// failure. Never fabricate a SAFE state from missing data.
  factory GeoFenceResult.unknown() =>
      const GeoFenceResult(state: GeoFenceState.unknown);

  factory GeoFenceResult.gpsUnavailable() =>
      const GeoFenceResult(state: GeoFenceState.gpsUnavailable);

  final GeoFenceState state;

  /// Closest enabled boundary by edge distance (the containing boundary when
  /// inside). Null when unknown.
  final BoundaryModel? nearestBoundary;

  /// Meters to the nearest boundary edge. 0 when inside. Null when unknown —
  /// never 0 as a failure sentinel.
  final double? distanceToBoundaryMeters;

  final bool insideBoundary;

  /// Bearing from the fix toward the closest boundary point, 0–360
  /// (0 = North, clockwise). Null when inside or unknown.
  final double? directionToBoundaryDegrees;

  /// |user bearing − direction to boundary| normalized to 0–180.
  /// Small ≈ moving toward; large ≈ moving away/across.
  /// Null when the GPS fix has no movement bearing. No ML involved.
  final double? bearingDifferenceDegrees;

  /// True when the user's movement bearing is within the configured approach
  /// angle of the boundary. Null when either bearing is unavailable.
  bool get movingTowardBoundary {
    final difference = bearingDifferenceDegrees;
    return difference != null && difference <= 45.0;
  }

  String? get boundaryType => nearestBoundary?.type;
  RiskLevel? get boundaryRisk => nearestBoundary?.riskLevel;
}
