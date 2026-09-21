// lib/services/risk_engine.dart
import '../models/ai_prediction_result.dart';
import '../models/geofence_result.dart';
import '../models/geofence_state.dart';

class RiskEngine {
  /// Fuses deterministic GeoFence results with AI predictions.
  /// The deterministic logic remains the absolute ground truth for current position.
  /// AI acts as a forward-looking upgrade to the risk state.
  static GeoFenceResult fuse(GeoFenceResult deterministic, AiPredictionResult ai) {
    if (!ai.isAvailable) {
      return deterministic; // Fallback to raw deterministic
    }

    // CRUCIAL RULE: Never downgrade an INSIDE or CRITICAL state
    if (deterministic.state == GeoFenceState.insideRestrictedArea ||
        deterministic.state == GeoFenceState.critical ||
        deterministic.state == GeoFenceState.unknown) {
      return deterministic;
    }

    GeoFenceState upgradedState = deterministic.state;

    // Upgrade based on AI classification if the AI predicts a higher risk
    if (ai.riskClass == RiskClass.high) {
      // If AI says HIGH risk, we escalate to CRITICAL unless already inside
      upgradedState = GeoFenceState.critical;
    } else if (ai.riskClass == RiskClass.medium) {
      // If AI says MEDIUM, escalate to WARNING if currently SAFE or CAUTION
      if (deterministic.state == GeoFenceState.safe || deterministic.state == GeoFenceState.caution) {
        upgradedState = GeoFenceState.warning;
      }
    }

    // Return a new GeoFenceResult that carries the upgraded state but keeps all 
    // the deterministic spatial data intact (nearestBoundary, distance, etc).
    return GeoFenceResult(
      state: upgradedState,
      nearestBoundary: deterministic.nearestBoundary,
      distanceToBoundaryMeters: deterministic.distanceToBoundaryMeters,
      insideBoundary: deterministic.insideBoundary,
      directionToBoundaryDegrees: deterministic.directionToBoundaryDegrees,
      bearingDifferenceDegrees: deterministic.bearingDifferenceDegrees,
    );
  }
}
