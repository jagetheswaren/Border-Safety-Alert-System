import 'local_chat_service.dart';

class SafetyContextBuilder {
  static const String baseSystemInstruction = '''
You are the BSAS Local Safety Assistant. You are an offline conversational assistant running locally on-device.
Your responsibilities:
- Explain BSAS official status
- Explain GPS status and coordinates
- Explain geofence boundary conditions
- Summarize alerts and system diagnostics
- Answer general field-safety questions
Important rules:
- You are not the safety decision engine.
- Never override BSAS's official risk or geofence state.
- Never invent GPS coordinates.
- Never invent alerts or incidents.
- Never claim emergency services were contacted unless confirmed.
- When data is unavailable, clearly state it is unavailable.
- Work completely offline without cloud dependencies.
You are advisory only; authoritative safety state comes from BSAS RiskEngine and GeofenceService.
''';

  static String buildSystemPrompt(SafetyContextSnapshot? snapshot) {
    if (snapshot == null) {
      return baseSystemInstruction;
    }

    final buffer = StringBuffer(baseSystemInstruction);
    buffer.writeln('\n--- READ-ONLY AUTHORITATIVE TELEMETRY SNAPSHOT ---');
    buffer.writeln('GPS AVAILABLE: ${snapshot.gpsAvailable}');
    if (snapshot.gpsAvailable && snapshot.latitude != null && snapshot.longitude != null) {
      buffer.writeln('CURRENT COORDINATES: ${snapshot.latitude!.toStringAsFixed(6)}°, ${snapshot.longitude!.toStringAsFixed(6)}°');
      if (snapshot.accuracyM != null) {
        buffer.writeln('GNSS ACCURACY: ±${snapshot.accuracyM!.toStringAsFixed(1)} meters');
      }
      if (snapshot.speedMps != null) {
        buffer.writeln('SPEED: ${(snapshot.speedMps! * 3.6).toStringAsFixed(1)} km/h');
      }
      if (snapshot.bearingDeg != null) {
        buffer.writeln('BEARING: ${snapshot.bearingDeg!.toStringAsFixed(0)}°');
      }
    } else {
      buffer.writeln('GNSS FIX: Not acquired / Constellation searching');
    }

    buffer.writeln('OFFICIAL RISK ENGINE STATE: ${snapshot.riskState.toUpperCase()}');
    buffer.writeln('GEOFENCE PERIMETER STATE: ${snapshot.zoneState.toUpperCase()}');
    buffer.writeln('ACTIVE INCIDENT ALERTS: ${snapshot.activeAlertCount}');
    buffer.writeln('OFFLINE OPERATIONAL MODE: ${snapshot.isOffline}');
    buffer.writeln('--------------------------------------------------');

    return buffer.toString();
  }
}
