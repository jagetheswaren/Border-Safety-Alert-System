/// Safety domain enums shared by UI and (later) services.
///
/// Phase 2: UI shell only. The authoritative values will be produced by
/// GeoFenceService/RiskEngine in later phases; screens currently render
/// clearly-marked demo snapshots (see lib/data/demo_data.dart).
library;

/// Classification produced by the risk engine (deterministic baseline first,
/// Random Forest from Phase 11).
enum RiskLevel { low, medium, high }

extension RiskLevelLabel on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.low:
        return 'LOW';
      case RiskLevel.medium:
        return 'MEDIUM';
      case RiskLevel.high:
        return 'HIGH';
    }
  }
}

/// Live safety situation derived from geo-fence + risk engine.
enum SafetyState { safe, caution, warning, critical, insideRestrictedArea }

extension SafetyStateLabel on SafetyState {
  String get label {
    switch (this) {
      case SafetyState.safe:
        return 'SAFE';
      case SafetyState.caution:
        return 'CAUTION';
      case SafetyState.warning:
        return 'WARNING';
      case SafetyState.critical:
        return 'CRITICAL';
      case SafetyState.insideRestrictedArea:
        return 'INSIDE RESTRICTED AREA';
    }
  }
}

/// GPS receiver condition. Real values arrive with GpsService (Phase 3).
enum GpsFixState { unavailable, searching, locked }

extension GpsFixStateLabel on GpsFixState {
  String get label {
    switch (this) {
      case GpsFixState.unavailable:
        return 'GPS unavailable';
      case GpsFixState.searching:
        return 'Searching for GPS…';
      case GpsFixState.locked:
        return 'GPS locked';
    }
  }
}
