import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/location_model.dart';

enum UserActivity {
  stationary,
  walking,
  running,
  vehicular,
  unknown,
}

enum MotionWarning {
  none,
  rapidApproach,
  suddenTurn,
  highSpeedInZone,
}

/// Immutable snapshot representing the user's current physical movement dynamics.
@immutable
class MotionSnapshot {
  const MotionSnapshot({
    required this.activity,
    required this.smoothedSpeedMps,
    required this.accelerationMps2,
    required this.isStationary,
    required this.isRapidApproach,
    required this.turnRateDegPerSec,
    required this.stationaryDriftFiltered,
    required this.confidence,
    required this.timestamp,
    this.warning = MotionWarning.none,
  });

  factory MotionSnapshot.initial() => MotionSnapshot(
        activity: UserActivity.unknown,
        smoothedSpeedMps: 0.0,
        accelerationMps2: 0.0,
        isStationary: true,
        isRapidApproach: false,
        turnRateDegPerSec: 0.0,
        stationaryDriftFiltered: false,
        confidence: 0.0,
        timestamp: DateTime.now(),
        warning: MotionWarning.none,
      );

  final UserActivity activity;
  final double smoothedSpeedMps;
  final double accelerationMps2;
  final bool isStationary;
  final bool isRapidApproach;
  final double turnRateDegPerSec;
  final bool stationaryDriftFiltered;
  final double confidence;
  final DateTime timestamp;
  final MotionWarning warning;

  double get smoothedSpeedKmh => smoothedSpeedMps * 3.6;

  String get activityLabel {
    switch (activity) {
      case UserActivity.stationary:
        return 'STATIONARY';
      case UserActivity.walking:
        return 'WALKING';
      case UserActivity.running:
        return 'RUNNING';
      case UserActivity.vehicular:
        return 'IN VEHICLE';
      case UserActivity.unknown:
        return 'CALIBRATING';
    }
  }
}

/// Service that analyzes GPS trajectory stream to detect user motion dynamics,
/// classify physical activity, suppress GPS multipath jitter when stationary,
/// and detect rapid or anomalous approaches toward restricted boundaries.
class MotionService extends ChangeNotifier {
  MotionService({
    this.speedSmoothingAlpha = 0.35,
    this.stationarySpeedThresholdMps = 0.5, // 1.8 km/h
    this.walkingSpeedThresholdMps = 2.5,   // 9.0 km/h
    this.runningSpeedThresholdMps = 5.5,   // 19.8 km/h
    this.rapidApproachThresholdMps = 3.0,  // Fast closure toward restricted line
  });

  final double speedSmoothingAlpha;
  final double stationarySpeedThresholdMps;
  final double walkingSpeedThresholdMps;
  final double runningSpeedThresholdMps;
  final double rapidApproachThresholdMps;

  MotionSnapshot _snapshot = MotionSnapshot.initial();
  LocationModel? _previousLocation;
  double? _previousDistanceToBoundary;
  DateTime? _previousDistanceTimestamp;
  double _filteredSpeed = 0.0;
  final List<double> _recentSpeeds = [];

  MotionSnapshot get snapshot => _snapshot;
  UserActivity get currentActivity => _snapshot.activity;
  bool get isStationary => _snapshot.isStationary;
  bool get isRapidApproach => _snapshot.isRapidApproach;

  /// Processes a new location fix and updates the motion snapshot.
  /// Optionally accepts [distanceToNearestBoundaryMeters] for rapid boundary approach analysis.
  MotionSnapshot processLocation(
    LocationModel location, {
    double? distanceToNearestBoundaryMeters,
  }) {
    final rawSpeed = (location.speed != null && location.speed! >= 0.0)
        ? location.speed!
        : 0.0;

    // 1. Exponential moving average smoothing for velocity
    if (_recentSpeeds.isEmpty) {
      _filteredSpeed = rawSpeed;
    } else {
      _filteredSpeed = (speedSmoothingAlpha * rawSpeed) +
          ((1.0 - speedSmoothingAlpha) * _filteredSpeed);
    }
    _recentSpeeds.add(rawSpeed);
    if (_recentSpeeds.length > 10) _recentSpeeds.removeAt(0);

    // 2. Acceleration calculation (dv / dt)
    double acceleration = 0.0;
    double turnRate = 0.0;
    bool stationaryDriftFiltered = false;

    if (_previousLocation != null) {
      final dt = location.timestamp
              .difference(_previousLocation!.timestamp)
              .inMilliseconds /
          1000.0;

      if (dt > 0.1 && dt < 10.0) {
        final prevSpeed = _previousLocation!.speed ?? 0.0;
        acceleration = (rawSpeed - prevSpeed) / dt;

        // Turn rate calculation
        if (location.bearing != null && _previousLocation!.bearing != null) {
          double deltaBearing =
              (location.bearing! - _previousLocation!.bearing!).abs();
          if (deltaBearing > 180.0) deltaBearing = 360.0 - deltaBearing;
          turnRate = deltaBearing / dt;
        }
      }

      // 3. Stationary jitter suppression: If measured displacement is less than
      // GPS horizontal accuracy and speed is near zero, suppress artificial coordinate drift.
      final displacement = _haversineDistance(
        _previousLocation!.latitude,
        _previousLocation!.longitude,
        location.latitude,
        location.longitude,
      );
      final accuracy = location.accuracy ?? 15.0;
      if (rawSpeed < stationarySpeedThresholdMps && displacement < (accuracy * 0.5)) {
        stationaryDriftFiltered = true;
      }
    }

    // 4. Activity classification
    final isStationary = _filteredSpeed < stationarySpeedThresholdMps;
    UserActivity activity;
    double confidence;

    if (isStationary) {
      activity = UserActivity.stationary;
      confidence = 0.95;
    } else if (_filteredSpeed < walkingSpeedThresholdMps) {
      activity = UserActivity.walking;
      confidence = 0.88;
    } else if (_filteredSpeed < runningSpeedThresholdMps) {
      activity = UserActivity.running;
      confidence = 0.82;
    } else {
      activity = UserActivity.vehicular;
      confidence = 0.92;
    }

    // 5. Rapid boundary approach rate
    bool isRapidApproach = false;
    MotionWarning warning = MotionWarning.none;

    if (distanceToNearestBoundaryMeters != null &&
        _previousDistanceToBoundary != null &&
        _previousDistanceTimestamp != null) {
      final dtDist = location.timestamp
              .difference(_previousDistanceTimestamp!)
              .inMilliseconds /
          1000.0;

      if (dtDist > 0.5 && dtDist < 10.0) {
        final deltaDist =
            _previousDistanceToBoundary! - distanceToNearestBoundaryMeters;
        final closureRate = deltaDist / dtDist; // Positive when closing in

        if (closureRate >= rapidApproachThresholdMps && !isStationary) {
          isRapidApproach = true;
          warning = MotionWarning.rapidApproach;
        }
      }
    }

    if (turnRate > 45.0 && _filteredSpeed > walkingSpeedThresholdMps) {
      warning = MotionWarning.suddenTurn;
    }

    _snapshot = MotionSnapshot(
      activity: activity,
      smoothedSpeedMps: _filteredSpeed,
      accelerationMps2: acceleration,
      isStationary: isStationary,
      isRapidApproach: isRapidApproach,
      turnRateDegPerSec: turnRate,
      stationaryDriftFiltered: stationaryDriftFiltered,
      confidence: confidence,
      timestamp: location.timestamp,
      warning: warning,
    );

    _previousLocation = location;
    if (distanceToNearestBoundaryMeters != null) {
      _previousDistanceToBoundary = distanceToNearestBoundaryMeters;
      _previousDistanceTimestamp = location.timestamp;
    }

    notifyListeners();
    return _snapshot;
  }

  void reset() {
    _snapshot = MotionSnapshot.initial();
    _previousLocation = null;
    _previousDistanceToBoundary = null;
    _previousDistanceTimestamp = null;
    _filteredSpeed = 0.0;
    _recentSpeeds.clear();
    notifyListeners();
  }

  static double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371000.0;
    final phi1 = lat1 * math.pi / 180.0;
    final phi2 = lat2 * math.pi / 180.0;
    final dPhi = (lat2 - lat1) * math.pi / 180.0;
    final dLambda = (lon2 - lon1) * math.pi / 180.0;

    final a = math.sin(dPhi / 2.0) * math.sin(dPhi / 2.0) +
        math.cos(phi1) *
            math.cos(phi2) *
            math.sin(dLambda / 2.0) *
            math.sin(dLambda / 2.0);
    final c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a));
    return r * c;
  }
}
