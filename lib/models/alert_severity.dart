import 'geofence_state.dart';

enum AlertSeverity { caution, warning, critical }

extension AlertSeverityDetails on AlertSeverity {
  String get label {
    switch (this) {
      case AlertSeverity.caution:
        return 'CAUTION';
      case AlertSeverity.warning:
        return 'WARNING';
      case AlertSeverity.critical:
        return 'CRITICAL';
    }
  }

  int get level {
    switch (this) {
      case AlertSeverity.caution:
        return 1;
      case AlertSeverity.warning:
        return 2;
      case AlertSeverity.critical:
        return 3;
    }
  }
}

AlertSeverity? severityForGeoFenceState(GeoFenceState state) {
  switch (state) {
    case GeoFenceState.caution:
      return AlertSeverity.caution;
    case GeoFenceState.warning:
      return AlertSeverity.warning;
    case GeoFenceState.critical:
    case GeoFenceState.insideRestrictedArea:
      return AlertSeverity.critical;
    case GeoFenceState.unknown:
    case GeoFenceState.gpsUnavailable:
    case GeoFenceState.safe:
      return null;
  }
}
