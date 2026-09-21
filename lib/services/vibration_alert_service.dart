import 'package:vibration/vibration.dart';

import '../models/alert_severity.dart';

abstract interface class VibrationAlertOutput {
  Future<void> vibrate(AlertSeverity severity);
  Future<void> stop();
}

class VibrationAlertService implements VibrationAlertOutput {
  @override
  Future<void> vibrate(AlertSeverity severity) async {
    try {
      if (!await Vibration.hasVibrator()) return;
      switch (severity) {
        case AlertSeverity.caution:
          await Vibration.vibrate(duration: 180);
        case AlertSeverity.warning:
          await Vibration.vibrate(pattern: [0, 180, 120, 280]);
        case AlertSeverity.critical:
          await Vibration.vibrate(pattern: [0, 220, 100, 220, 100, 420]);
      }
    } catch (_) {}
  }

  Future<void> vibrateSystem() async {
    try {
      if (!await Vibration.hasVibrator()) return;
      await Vibration.vibrate(pattern: [0, 80, 60, 80]);
    } catch (_) {}
  }

  @override
  Future<void> stop() async {
    try {
      await Vibration.cancel();
    } catch (_) {}
  }
}
