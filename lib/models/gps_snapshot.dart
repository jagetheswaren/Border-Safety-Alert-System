/// Immutable GPS state handed from [GpsService] to the UI (Phase 3).
library;

import 'location_model.dart';
import 'safety_state.dart';

/// Permission outcome in app terms (mapped from the platform plugin).
enum LocationPermissionState { granted, denied, deniedForever }

class GpsSnapshot {
  const GpsSnapshot({
    required this.fix,
    required this.permission,
    required this.serviceEnabled,
    this.location,
    this.message,
    this.poorAccuracy = false,
    this.stale = false,
  });

  /// State before the first platform check completes.
  factory GpsSnapshot.initial() => const GpsSnapshot(
    fix: GpsFixState.searching,
    permission: LocationPermissionState.denied,
    serviceEnabled: true,
    message: 'Checking location status…',
  );

  final GpsFixState fix;
  final LocationPermissionState permission;
  final bool serviceEnabled;
  final LocationModel? location;
  final String? message;
  final bool poorAccuracy;
  final bool stale;

  GpsSnapshot copyWith({
    GpsFixState? fix,
    LocationPermissionState? permission,
    bool? serviceEnabled,
    LocationModel? Function()? location,
    String? Function()? message,
    bool? poorAccuracy,
    bool? stale,
  }) {
    return GpsSnapshot(
      fix: fix ?? this.fix,
      permission: permission ?? this.permission,
      serviceEnabled: serviceEnabled ?? this.serviceEnabled,
      location: location == null ? this.location : location(),
      message: message == null ? this.message : message(),
      poorAccuracy: poorAccuracy ?? this.poorAccuracy,
      stale: stale ?? this.stale,
    );
  }
}
