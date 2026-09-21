import '../models/safety_state.dart';

/// DEMO placeholder snapshot for UI development only (Phase 2).
///
/// This is NOT real GPS data and NOT an AI result. Phase 3+ will replace
/// these call sites with live data from GpsService/GeoFenceService/RiskEngine.
/// Every widget rendering this snapshot must show the demo disclaimer.
class DemoSafetySnapshot {
  const DemoSafetySnapshot({
    required this.safetyState,
    required this.risk,
    required this.gps,
    required this.boundaryName,
    required this.distanceMeters,
    this.isPlaceholder = true,
  });

  final SafetyState safetyState;
  final RiskLevel risk;
  final GpsFixState gps;
  final String boundaryName;
  final double distanceMeters;
  final bool isPlaceholder;

  /// Single shared placeholder used across Phase 2 screens.
  static const placeholder = DemoSafetySnapshot(
    safetyState: SafetyState.caution,
    risk: RiskLevel.medium,
    gps: GpsFixState.searching,
    boundaryName: 'Demo Restricted Zone A',
    distanceMeters: 800,
  );
}
