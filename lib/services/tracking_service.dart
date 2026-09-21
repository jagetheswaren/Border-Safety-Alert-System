import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/location_model.dart';

enum TrackingStatus { idle, tracking, paused }

class TrackingService extends ChangeNotifier {
  TrackingService({this.maxPoints = 1000});

  final int maxPoints;
  final List<LocationModel> _trail = [];
  TrackingStatus _status = TrackingStatus.idle;
  DateTime? _startTime;
  Duration _accumulatedTime = Duration.zero;

  List<LocationModel> get trail => List.unmodifiable(_trail);
  TrackingStatus get status => _status;
  bool get isTracking => _status == TrackingStatus.tracking;
  bool get isPaused => _status == TrackingStatus.paused;
  bool get isIdle => _status == TrackingStatus.idle;

  Duration get elapsedTime {
    if (_startTime == null) return _accumulatedTime;
    if (_status == TrackingStatus.tracking) {
      return _accumulatedTime + DateTime.now().difference(_startTime!);
    }
    return _accumulatedTime;
  }

  double get totalDistanceMeters {
    if (_trail.length < 2) return 0.0;
    double total = 0.0;
    for (int i = 0; i < _trail.length - 1; i++) {
      total += _haversineMeters(_trail[i], _trail[i + 1]);
    }
    return total;
  }

  void startTracking() {
    if (_status == TrackingStatus.tracking) return;
    _status = TrackingStatus.tracking;
    _startTime = DateTime.now();
    notifyListeners();
  }

  void pauseTracking() {
    if (_status != TrackingStatus.tracking) return;
    _status = TrackingStatus.paused;
    if (_startTime != null) {
      _accumulatedTime += DateTime.now().difference(_startTime!);
      _startTime = null;
    }
    notifyListeners();
  }

  void resumeTracking() {
    if (_status != TrackingStatus.paused) return;
    _status = TrackingStatus.tracking;
    _startTime = DateTime.now();
    notifyListeners();
  }

  void stopTracking() {
    if (_status == TrackingStatus.idle) return;
    _status = TrackingStatus.idle;
    if (_startTime != null) {
      _accumulatedTime += DateTime.now().difference(_startTime!);
      _startTime = null;
    }
    notifyListeners();
  }

  void clearTrack() {
    _trail.clear();
    _startTime = null;
    _accumulatedTime = Duration.zero;
    _status = TrackingStatus.idle;
    notifyListeners();
  }

  void addFix(LocationModel fix) {
    if (_status != TrackingStatus.tracking) return;

    // Filter out redundant points if closer than 1 meter to avoid jitter
    if (_trail.isNotEmpty) {
      final last = _trail.last;
      if (_haversineMeters(last, fix) < 0.5) return;
    }

    _trail.add(fix);
    if (_trail.length > maxPoints) {
      _trail.removeAt(0);
    }
    notifyListeners();
  }

  static double _haversineMeters(LocationModel p1, LocationModel p2) {
    const r = 6371000.0;
    final lat1 = p1.latitude * pi / 180.0;
    final lat2 = p2.latitude * pi / 180.0;
    final dLat = (p2.latitude - p1.latitude) * pi / 180.0;
    final dLon = (p2.longitude - p1.longitude) * pi / 180.0;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }
}
