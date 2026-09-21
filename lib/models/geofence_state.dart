/// Deterministic geo-fence states (Phase 5).
///
/// Produced purely from GPS geometry + stored boundaries. This is NOT an AI
/// prediction; the ML risk pipeline arrives in later phases.
library;

enum GeoFenceState {
  unknown,
  gpsUnavailable,
  safe,
  caution,
  warning,
  critical,
  insideRestrictedArea,
}

extension GeoFenceStateLabel on GeoFenceState {
  String get label {
    switch (this) {
      case GeoFenceState.unknown:
        return 'UNKNOWN';
      case GeoFenceState.gpsUnavailable:
        return 'GPS_UNAVAILABLE';
      case GeoFenceState.safe:
        return 'SAFE';
      case GeoFenceState.caution:
        return 'CAUTION';
      case GeoFenceState.warning:
        return 'WARNING';
      case GeoFenceState.critical:
        return 'CRITICAL';
      case GeoFenceState.insideRestrictedArea:
        return 'INSIDE RESTRICTED AREA';
    }
  }
}
