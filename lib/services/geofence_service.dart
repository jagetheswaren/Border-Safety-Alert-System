import '../models/boundary_model.dart';
import '../models/geofence_result.dart';
import '../models/geofence_state.dart';
import '../models/location_model.dart';
import 'boundary_repository.dart';
import 'geo_math.dart';

/// Configurable prototype thresholds for deterministic geo-fencing.
class GeoFenceConfig {
  const GeoFenceConfig({
    this.cautionRadiusMeters = 1000,
    this.warningRadiusMeters = 300,
    this.criticalRadiusMeters = 100,
  }) : assert(cautionRadiusMeters >= warningRadiusMeters),
       assert(warningRadiusMeters >= criticalRadiusMeters),
       assert(criticalRadiusMeters >= 0);

  final double cautionRadiusMeters;
  final double warningRadiusMeters;
  final double criticalRadiusMeters;
}

/// Deterministic GPS + SQLite boundary engine. It performs no AI prediction.
class GeoFenceService {
  GeoFenceService({
    BoundaryRepository? repository,
    Future<List<BoundaryModel>> Function()? loadEnabledBoundaries,
    this.config = const GeoFenceConfig(),
  }) : assert(
         repository != null || loadEnabledBoundaries != null,
         'A repository or boundary loader is required.',
       ),
       _loadEnabledBoundaries =
           loadEnabledBoundaries ?? repository!.getEnabledBoundaries;

  final Future<List<BoundaryModel>> Function() _loadEnabledBoundaries;
  final GeoFenceConfig config;
  List<BoundaryModel>? _cachedBoundaries;

  Future<void> refreshBoundaries() async {
    _cachedBoundaries = await _loadEnabledBoundaries();
  }

  Future<GeoFenceResult> evaluate(LocationModel? location) async {
    if (location == null ||
        !location.latitude.isFinite ||
        !location.longitude.isFinite || location.isStale || (location.accuracy ?? double.infinity) > 50) {
      return GeoFenceResult.gpsUnavailable();
    }
    try {
      _cachedBoundaries ??= await _loadEnabledBoundaries();
    } catch (_) {
      return GeoFenceResult.unknown();
    }
    final candidates = [
      for (final boundary in _cachedBoundaries!)
        if (boundary.enabled && _hasUsablePolygon(boundary.polygon)) boundary,
    ];
    if (candidates.isEmpty) return GeoFenceResult.unknown();

    BoundaryModel? nearest;
    ClosestPoint? closest;
    var inside = false;
    for (final boundary in candidates) {
      final isInside = isPointInPolygon(
        latitude: location.latitude,
        longitude: location.longitude,
        polygon: boundary.polygon,
      );
      final point = closestPointOnPolygon(
        latitude: location.latitude,
        longitude: location.longitude,
        polygon: boundary.polygon,
      );
      if (point == null) continue;
      if (nearest == null ||
          (isInside && !inside) ||
          (isInside == inside &&
              point.distanceMeters < closest!.distanceMeters)) {
        nearest = boundary;
        closest = point;
        inside = isInside;
      }
    }
    if (nearest == null || closest == null) return GeoFenceResult.unknown();

    final distance = inside ? 0.0 : closest.distanceMeters;
    final direction = inside
        ? null
        : bearingDegrees(
            location.latitude,
            location.longitude,
            closest.latitude,
            closest.longitude,
          );
    final movementDifference = direction == null || location.bearing == null
        ? null
        : bearingDifferenceDegrees(location.bearing!, direction);
    return GeoFenceResult(
      state: inside ? GeoFenceState.insideRestrictedArea : _stateFor(distance),
      nearestBoundary: nearest,
      distanceToBoundaryMeters: distance,
      insideBoundary: inside,
      directionToBoundaryDegrees: direction,
      bearingDifferenceDegrees: movementDifference,
    );
  }

  GeoFenceState _stateFor(double distance) {
    if (distance <= config.criticalRadiusMeters) return GeoFenceState.critical;
    if (distance <= config.warningRadiusMeters) return GeoFenceState.warning;
    if (distance <= config.cautionRadiusMeters) return GeoFenceState.caution;
    return GeoFenceState.safe;
  }

  bool _hasUsablePolygon(List<List<BoundaryPosition>> polygon) {
    if (polygon.isEmpty || polygon.first.length < 3) return false;
    return polygon.every(
      (ring) =>
          ring.length >= 3 &&
          ring.every(
            (point) => point.latitude.isFinite && point.longitude.isFinite,
          ),
    );
  }
}
