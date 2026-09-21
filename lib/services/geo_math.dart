/// Pure geographic math for the deterministic geo-fence engine (Phase 5).
///
/// Conventions (see docs/geofencing.md):
/// - Model coordinates are decimal degrees: `BoundaryPosition(longitude,
///   latitude)` matching GeoJSON RFC 7946 `[lon, lat]` order. Callers must
///   not transpose them.
/// - Bearings are degrees clockwise from North: 0 = N, 90 = E, 180 = S,
///   270 = W.
/// - Distances use the haversine formula on a spherical Earth
///   (R = 6,371,000 m). Point-to-segment projection uses a local
///   equirectangular approximation, accurate for the meter-to-kilometer
///   scales of this prototype; documented limitation for very large areas.
/// - Every function is total: invalid input yields `false`/`null`, never a
///   throw and never a fabricated 0 m.
library;

import 'dart:math' as math;

import '../models/boundary_model.dart';

const double earthRadiusMeters = 6371000.0;

/// Edge tolerance in degrees (~1 mm). Points within this of an edge count
/// as on the edge (inside).
const double _edgeEpsilonDegrees = 1e-8;

double _radians(double degrees) => degrees * math.pi / 180.0;
double _degrees(double radians) => radians * 180.0 / math.pi;

/// Ray-casting point-in-ring test in the lon/lat plane.
///
/// Points on an edge or vertex count as inside. Rings with fewer than 3
/// finite positions, and non-finite queries, return false.
bool isPointInRing({
  required double latitude,
  required double longitude,
  required List<BoundaryPosition> ring,
}) {
  if (!latitude.isFinite || !longitude.isFinite) return false;
  if (ring.any((p) => !p.latitude.isFinite || !p.longitude.isFinite)) {
    return false;
  }
  final pts = [...ring];
  if (pts.length < 3) return false;

  for (var i = 0; i < pts.length; i++) {
    if (_onSegment(
      latitude: latitude,
      longitude: longitude,
      a: pts[i],
      b: pts[(i + 1) % pts.length],
    )) {
      return true;
    }
  }

  var inside = false;
  for (var i = 0, j = pts.length - 1; i < pts.length; j = i++) {
    final xi = pts[i].longitude;
    final yi = pts[i].latitude;
    final xj = pts[j].longitude;
    final yj = pts[j].latitude;
    if ((yi > latitude) != (yj > latitude)) {
      final xIntersect = (xj - xi) * (latitude - yi) / (yj - yi) + xi;
      if (longitude < xIntersect) inside = !inside;
    }
  }
  return inside;
}

/// Polygon test with holes: inside the outer ring and not inside any hole.
/// An empty polygon (or empty outer ring) is outside, never inside.
bool isPointInPolygon({
  required double latitude,
  required double longitude,
  required List<List<BoundaryPosition>> polygon,
}) {
  if (polygon.isEmpty) return false;
  if (!isPointInRing(
    latitude: latitude,
    longitude: longitude,
    ring: polygon.first,
  )) {
    return false;
  }
  for (var k = 1; k < polygon.length; k++) {
    if (isPointInRing(
      latitude: latitude,
      longitude: longitude,
      ring: polygon[k],
    )) {
      return false;
    }
  }
  return true;
}

bool _onSegment({
  required double latitude,
  required double longitude,
  required BoundaryPosition a,
  required BoundaryPosition b,
}) {
  final dx = b.longitude - a.longitude;
  final dy = b.latitude - a.latitude;
  final lenSq = dx * dx + dy * dy;
  if (lenSq == 0) {
    // Degenerate edge: only matches the shared vertex itself.
    return (longitude - a.longitude).abs() <= _edgeEpsilonDegrees &&
        (latitude - a.latitude).abs() <= _edgeEpsilonDegrees;
  }
  final cross = (longitude - a.longitude) * dy - (latitude - a.latitude) * dx;
  if ((cross * cross) / lenSq > _edgeEpsilonDegrees * _edgeEpsilonDegrees) {
    return false;
  }
  final dot = (longitude - a.longitude) * dx + (latitude - a.latitude) * dy;
  return dot >= -_edgeEpsilonDegrees && dot <= lenSq + _edgeEpsilonDegrees;
}

/// Great-circle distance in meters (haversine, spherical Earth).
double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
  final dLat = _radians(lat2 - lat1);
  final dLon = _radians(lon2 - lon1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_radians(lat1)) *
          math.cos(_radians(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return 2 * earthRadiusMeters * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
}

/// Closest boundary point with its haversine distance in meters.
class ClosestPoint {
  const ClosestPoint({
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
  });

  final double latitude;
  final double longitude;
  final double distanceMeters;
}

/// Closest point on any polygon edge (outer ring or holes).
///
/// Returns null when there is no usable segment — including empty polygons —
/// so callers can represent failure explicitly instead of 0 m.
ClosestPoint? closestPointOnPolygon({
  required double latitude,
  required double longitude,
  required List<List<BoundaryPosition>> polygon,
}) {
  if (!latitude.isFinite || !longitude.isFinite) return null;
  if (polygon.any(
    (ring) =>
        ring.length < 2 ||
        ring.any((p) => !p.latitude.isFinite || !p.longitude.isFinite),
  )) {
    return null;
  }
  ClosestPoint? best;
  for (final ring in polygon) {
    final pts = [...ring];
    if (pts.length < 2) continue;
    // Consecutive edges, plus the closing edge when the ring is not closed.
    final edges = pts.length - 1;
    for (var i = 0; i < edges; i++) {
      final candidate = _closestOnSegment(
        latitude: latitude,
        longitude: longitude,
        a: pts[i],
        b: pts[i + 1],
      );
      if (best == null || candidate.distanceMeters < best.distanceMeters) {
        best = candidate;
      }
    }
    final first = pts.first;
    final last = pts.last;
    if (first.latitude != last.latitude || first.longitude != last.longitude) {
      final candidate = _closestOnSegment(
        latitude: latitude,
        longitude: longitude,
        a: last,
        b: first,
      );
      if (best == null || candidate.distanceMeters < best.distanceMeters) {
        best = candidate;
      }
    }
  }
  return best;
}

ClosestPoint _closestOnSegment({
  required double latitude,
  required double longitude,
  required BoundaryPosition a,
  required BoundaryPosition b,
}) {
  // Local equirectangular projection around the query latitude.
  final kx = math.cos(_radians(latitude));
  final ax = (a.longitude - longitude) * kx;
  final ay = a.latitude - latitude;
  final bx = (b.longitude - longitude) * kx;
  final by = b.latitude - latitude;
  final dx = bx - ax;
  final dy = by - ay;
  final lenSq = dx * dx + dy * dy;
  double t = lenSq == 0 ? 0 : -(ax * dx + ay * dy) / lenSq;
  t = t.clamp(0.0, 1.0);
  final cx = ax + t * dx;
  final cy = ay + t * dy;
  final closestLon = longitude + cx / kx;
  final closestLat = latitude + cy;
  return ClosestPoint(
    latitude: closestLat,
    longitude: closestLon,
    distanceMeters: haversineMeters(
      latitude,
      longitude,
      closestLat,
      closestLon,
    ),
  );
}

/// Initial bearing from (lat1, lon1) to (lat2, lon2), normalized to [0, 360).
double bearingDegrees(double lat1, double lon1, double lat2, double lon2) {
  final dLon = _radians(lon2 - lon1);
  final y = math.sin(dLon) * math.cos(_radians(lat2));
  final x =
      math.cos(_radians(lat1)) * math.sin(_radians(lat2)) -
      math.sin(_radians(lat1)) * math.cos(_radians(lat2)) * math.cos(dLon);
  return (_degrees(math.atan2(y, x)) + 360.0) % 360.0;
}

/// Absolute angular difference normalized to [0, 180].
double bearingDifferenceDegrees(double a, double b) {
  var diff = (a - b).abs() % 360.0;
  if (diff > 180.0) diff = 360.0 - diff;
  return diff;
}
