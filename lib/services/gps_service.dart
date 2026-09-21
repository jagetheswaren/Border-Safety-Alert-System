import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/gps_snapshot.dart';
import '../models/location_model.dart';
import '../models/safety_state.dart';
import 'location_provider.dart';

/// Foreground GPS service (Phase 3).
///
/// Flow: permission/service checks → one current fix → continuous stream.
/// Every failure path yields a descriptive [GpsSnapshot] instead of throwing,
/// so the UI can always render an honest state and never fabricates a
/// position. Invalid coordinates are dropped; the previous valid fix is kept.
///
/// Phase 4 will consume [snapshot] for the SQLite/boundary layer.
class GpsService extends ChangeNotifier {
  GpsService({LocationProvider? provider})
    : _provider = provider ?? GeolocatorProvider();

  /// Accuracy radius above which a fix is flagged unreliable.
  static const poorAccuracyThresholdMeters = 50.0;

  final LocationProvider _provider;
  GpsSnapshot _snapshot = GpsSnapshot.initial();
  StreamSubscription<Position>? _subscription;
  bool _starting = false;
  bool _disposed = false;

  GpsSnapshot get snapshot => _snapshot;

  /// Runs the permission/service check sequence and subscribes to updates.
  ///
  /// Safe to call repeatedly (e.g. Retry button): concurrent runs are
  /// ignored and the previous stream is replaced, never duplicated.
  Future<void> start() async {
    if (_starting) return;
    _starting = true;
    try {
      _emit(GpsSnapshot.initial());

      late final bool serviceEnabled;
      try {
        serviceEnabled = await _provider.isServiceEnabled();
      } catch (e) {
        _emit(
          GpsSnapshot(
            fix: GpsFixState.unavailable,
            permission: LocationPermissionState.denied,
            serviceEnabled: true,
            message: 'Cannot access location services ($e).',
          ),
        );
        return;
      }
      if (!serviceEnabled) {
        _emit(
          const GpsSnapshot(
            fix: GpsFixState.unavailable,
            permission: LocationPermissionState.denied,
            serviceEnabled: false,
            message:
                'Location services are disabled. Enable GPS to receive position updates.',
          ),
        );
        return;
      }

      final permission = await _resolvePermission();
      if (permission == null) return; // _resolvePermission already emitted.
      if (permission != LocationPermissionState.granted) return;

      final current = await _provider.currentPosition();
      if (current != null) {
        _applyPosition(current);
      } else {
        _emit(
          _snapshot.copyWith(
            fix: GpsFixState.searching,
            message: () => 'Waiting for GPS fix…',
          ),
        );
      }

      try {
        await _subscription?.cancel();
        _subscription = _provider.positionStream().listen(
          _applyPosition,
          onError: _onStreamError,
        );
      } catch (e) {
        _onStreamError(e);
      }
    } finally {
      _starting = false;
    }
  }

  /// Checks/requests permission, emitting terminal states. Returns null when
  /// a terminal state was emitted and startup must stop.
  Future<LocationPermissionState?> _resolvePermission() async {
    late LocationPermission checked;
    try {
      checked = await _provider.checkPermission();
      if (checked == LocationPermission.denied) {
        checked = await _provider.requestPermission();
      }
    } catch (e) {
      _emit(
        GpsSnapshot(
          fix: GpsFixState.unavailable,
          permission: LocationPermissionState.denied,
          serviceEnabled: true,
          message: 'Cannot check location permission ($e).',
        ),
      );
      return null;
    }

    switch (checked) {
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return LocationPermissionState.granted;
      case LocationPermission.denied:
        _emit(
          const GpsSnapshot(
            fix: GpsFixState.unavailable,
            permission: LocationPermissionState.denied,
            serviceEnabled: true,
            message:
                'Location permission denied. Grant permission to receive position updates.',
          ),
        );
        return LocationPermissionState.denied;
      case LocationPermission.deniedForever:
      case LocationPermission.unableToDetermine:
        _emit(
          const GpsSnapshot(
            fix: GpsFixState.unavailable,
            permission: LocationPermissionState.deniedForever,
            serviceEnabled: true,
            message:
                'Location permission permanently denied. Open app settings to grant permission.',
          ),
        );
        return LocationPermissionState.deniedForever;
    }
  }

  void _applyPosition(Position position) {
    late final LocationModel fix;
    try {
      fix = LocationModel.validated(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: position.timestamp,
        speed: position.speed,
        bearing: position.heading,
        accuracy: position.accuracy,
        altitude: position.altitude,
      );
    } on ArgumentError {
      // Invalid coordinates: drop the reading, keep the previous fix.
      return;
    }
    final poor =
        fix.accuracy == null || fix.accuracy! > poorAccuracyThresholdMeters;
    _emit(
      GpsSnapshot(
        fix: GpsFixState.locked,
        permission: LocationPermissionState.granted,
        serviceEnabled: true,
        location: fix,
        message: poor
            ? 'Poor GPS accuracy — readings may be unreliable.'
            : null,
        poorAccuracy: poor,
        stale: fix.isStale,
      ),
    );
  }

  void _onStreamError(Object error) {
    final previous = _snapshot.location;
    if (previous == null) {
      _emit(
        GpsSnapshot(
          fix: GpsFixState.unavailable,
          permission: _snapshot.permission,
          serviceEnabled: _snapshot.serviceEnabled,
          message: 'Location updates failed ($error).',
        ),
      );
    } else {
      _emit(
        _snapshot.copyWith(
          message: () => 'Location update error — showing last known fix.',
          stale: true,
        ),
      );
    }
  }

  /// Stops updates; the last snapshot is retained for display.
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void _emit(GpsSnapshot snapshot) {
    if (_disposed) return;
    _snapshot = snapshot;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
  }
}
