import 'alert_severity.dart';
import 'geofence_state.dart';

class AlertMessage {
  const AlertMessage({
    required this.severity,
    required this.title,
    required this.message,
  });

  final AlertSeverity severity;
  final String title;
  final String message;
}

AlertMessage? alertMessageForState(GeoFenceState state) {
  switch (state) {
    case GeoFenceState.caution:
      return const AlertMessage(
        severity: AlertSeverity.caution,
        title: 'Caution',
        message: 'Caution. You are approaching a restricted area.',
      );
    case GeoFenceState.warning:
      return const AlertMessage(
        severity: AlertSeverity.warning,
        title: 'Warning',
        message: 'Warning. You are close to a restricted area.',
      );
    case GeoFenceState.critical:
      return const AlertMessage(
        severity: AlertSeverity.critical,
        title: 'Critical warning',
        message: 'Critical warning. You are very close to a restricted area.',
      );
    case GeoFenceState.insideRestrictedArea:
      return const AlertMessage(
        severity: AlertSeverity.critical,
        title: 'Critical warning',
        message: 'Critical warning. You are inside a restricted area.',
      );
    case GeoFenceState.unknown:
    case GeoFenceState.gpsUnavailable:
    case GeoFenceState.safe:
      return null;
  }
}
