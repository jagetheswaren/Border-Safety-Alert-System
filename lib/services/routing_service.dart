import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/boundary_model.dart';
import '../models/location_model.dart';
import '../models/routing_result.dart';
import 'geo_math.dart';

class _RoutingRequest {
  final double startLat;
  final double startLon;
  final List<BoundaryModel> boundaries;

  _RoutingRequest(this.startLat, this.startLon, this.boundaries);
}

class GridNode {
  final int x;
  final int y;
  final double lat;
  final double lon;

  double g = double.infinity;
  double f = double.infinity;
  GridNode? parent;

  GridNode(this.x, this.y, this.lat, this.lon);

  @override
  bool operator ==(Object other) =>
      other is GridNode && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

class _MinHeap {
  final List<GridNode> _data = [];

  bool get isEmpty => _data.isEmpty;

  void add(GridNode node) {
    _data.add(node);
    _up(_data.length - 1);
  }

  GridNode removeFirst() {
    if (_data.isEmpty) throw StateError('Empty');
    final root = _data.first;
    final last = _data.removeLast();
    if (_data.isNotEmpty) {
      _data[0] = last;
      _down(0);
    }
    return root;
  }

  void _up(int i) {
    while (i > 0) {
      final p = (i - 1) >> 1;
      if (_data[i].f >= _data[p].f) break;
      final temp = _data[i];
      _data[i] = _data[p];
      _data[p] = temp;
      i = p;
    }
  }

  void _down(int i) {
    final len = _data.length;
    while (true) {
      final left = (i << 1) + 1;
      final right = left + 1;
      int smallest = i;
      if (left < len && _data[left].f < _data[smallest].f) smallest = left;
      if (right < len && _data[right].f < _data[smallest].f) smallest = right;
      if (smallest == i) break;
      final temp = _data[i];
      _data[i] = _data[smallest];
      _data[smallest] = temp;
      i = smallest;
    }
  }
}

class RoutingService {
  static const double gridCellSizeMeters = 50.0;
  static const int maxSearchNodes = 2000;
  static const double safetyClearanceMeters = 50.0;
  static const double maxRaycastRadiusMeters = 3000.0;

  /// Calculate a safe route asynchronously on an isolate.
  Future<RoutingResult> calculateSafeRoute(
    LocationModel currentLocation,
    List<BoundaryModel> boundaries,
  ) async {
    if (boundaries.isEmpty) {
      return RoutingResult.alreadySafe(message: 'No boundaries available.');
    }
    final req = _RoutingRequest(
      currentLocation.latitude,
      currentLocation.longitude,
      boundaries,
    );
    return await compute(_runAStar, req);
  }

  static bool _isSafe(double lat, double lon, List<BoundaryModel> boundaries) {
    for (final b in boundaries) {
      if (isPointInPolygon(
          latitude: lat, longitude: lon, polygon: b.polygon)) {
        return false;
      }
      final closest = closestPointOnPolygon(
          latitude: lat, longitude: lon, polygon: b.polygon);
      if (closest != null && closest.distanceMeters < safetyClearanceMeters) {
        return false;
      }
    }
    return true;
  }

  static GridNode? _findGoal(double startLat, double startLon,
      double latDelta, double lonDelta, List<BoundaryModel> boundaries) {
    double bestDist = double.infinity;
    GridNode? bestGoal;

    // Raycast in 16 directions to find the nearest valid safe point
    for (int deg = 0; deg < 360; deg += 22) {
      for (double dist = gridCellSizeMeters;
          dist <= maxRaycastRadiusMeters;
          dist += gridCellSizeMeters) {
        
        double rad = deg * math.pi / 180.0;
        double testLat = startLat + (dist * math.cos(rad) / 111320.0);
        double testLon = startLon + (dist * math.sin(rad) / (111320.0 * math.cos(startLat * math.pi / 180.0)));

        if (_isSafe(testLat, testLon, boundaries)) {
          double hDist = haversineMeters(startLat, startLon, testLat, testLon);
          if (hDist < bestDist) {
            bestDist = hDist;
            // Snap to grid
            int y = ((testLat - startLat) / latDelta).round();
            int x = ((testLon - startLon) / lonDelta).round();
            bestGoal = GridNode(x, y, startLat + y * latDelta, startLon + x * lonDelta);
          }
          break; // move to next ray
        }
      }
    }
    return bestGoal;
  }

  static RoutingResult _runAStar(_RoutingRequest req) {
    final startLat = req.startLat;
    final startLon = req.startLon;
    final boundaries = req.boundaries;

    if (_isSafe(startLat, startLon, boundaries)) {
      return RoutingResult.alreadySafe(message: 'Already in a safe area.');
    }

    // Determine which boundaries we are currently violating
    final Set<BoundaryModel> violatedAtStart = {};
    for (final b in boundaries) {
      if (!_isSafe(startLat, startLon, [b])) {
        violatedAtStart.add(b);
      }
    }

    final double latDelta = gridCellSizeMeters / 111320.0;
    final double lonDelta =
        gridCellSizeMeters / (111320.0 * math.cos(startLat * math.pi / 180.0));

    final goalNode = _findGoal(startLat, startLon, latDelta, lonDelta, boundaries);
    if (goalNode == null) {
      return RoutingResult.unavailable(message: 'No safe destination found within range.');
    }

    final openSet = _MinHeap();
    final Map<int, GridNode> allNodes = {};

    GridNode startNode = GridNode(0, 0, startLat, startLon);
    startNode.g = 0;
    startNode.f = haversineMeters(startLat, startLon, goalNode.lat, goalNode.lon);
    openSet.add(startNode);
    allNodes[startNode.hashCode] = startNode;

    int expandedNodes = 0;
    GridNode? reachedGoal;

    while (!openSet.isEmpty) {
      final current = openSet.removeFirst();
      expandedNodes++;

      if (expandedNodes > maxSearchNodes) {
        return RoutingResult.unavailable(
            message: 'Search limit exceeded ($maxSearchNodes nodes). Route too complex.');
      }

      if (current.x == goalNode.x && current.y == goalNode.y) {
        reachedGoal = current;
        break;
      }

      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          if (dx == 0 && dy == 0) continue;

          int nx = current.x + dx;
          int ny = current.y + dy;
          double nLat = startLat + ny * latDelta;
          double nLon = startLon + nx * lonDelta;

          GridNode neighbor = GridNode(nx, ny, nLat, nLon);
          if (!allNodes.containsKey(neighbor.hashCode)) {
             // Obstacle check: we can traverse violated boundaries, but not new ones
             bool canTraverse = true;
             for (final b in boundaries) {
               if (!violatedAtStart.contains(b)) {
                 if (!_isSafe(nLat, nLon, [b])) {
                   canTraverse = false;
                   break;
                 }
               }
             }

             if (!canTraverse) {
                allNodes[neighbor.hashCode] = neighbor; // Store but do not add
                continue;
             }
             allNodes[neighbor.hashCode] = neighbor;
          } else {
             neighbor = allNodes[neighbor.hashCode]!;
             if (neighbor.g == double.infinity && neighbor != startNode) {
                // Was previously blocked
                continue;
             }
          }

          double baseCost = haversineMeters(current.lat, current.lon, neighbor.lat, neighbor.lon);
          
          // Add a penalty if still inside the violated boundaries to encourage leaving them directly
          double penalty = 1.0;
          for (final b in violatedAtStart) {
            if (!_isSafe(neighbor.lat, neighbor.lon, [b])) {
               penalty += 2.0;
               break;
            }
          }
          
          double tentativeG = current.g + (baseCost * penalty);

          if (tentativeG < neighbor.g) {
            neighbor.parent = current;
            neighbor.g = tentativeG;
            neighbor.f = tentativeG + haversineMeters(neighbor.lat, neighbor.lon, goalNode.lat, goalNode.lon);
            openSet.add(neighbor);
          }
        }
      }
    }

    if (reachedGoal == null) {
      return RoutingResult.unavailable(message: 'No safe route could be found.');
    }

    // Reconstruct path
    List<LocationModel> path = [];
    GridNode? curr = reachedGoal;
    double totalDistance = 0;
    
    while (curr != null) {
      path.add(LocationModel.validated(
          latitude: curr.lat,
          longitude: curr.lon,
          timestamp: DateTime.now()));
      if (curr.parent != null) {
        totalDistance += haversineMeters(curr.lat, curr.lon, curr.parent!.lat, curr.parent!.lon);
      }
      curr = curr.parent;
    }
    path = path.reversed.toList();

    double bearing = 0.0;
    if (path.length > 1) {
      bearing = bearingDegrees(path[0].latitude, path[0].longitude, path[1].latitude, path[1].longitude);
    }

    return RoutingResult(
      status: RoutingStatus.available,
      routePoints: path,
      totalDistanceMeters: totalDistance,
      initialBearing: bearing,
      destination: path.last,
      message: 'Safe route calculated successfully.',
    );
  }
}
