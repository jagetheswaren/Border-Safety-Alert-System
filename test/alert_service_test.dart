import 'package:border_safety_alert/models/alert_preferences.dart';
import 'package:border_safety_alert/models/alert_severity.dart';
import 'package:border_safety_alert/models/geofence_result.dart';
import 'package:border_safety_alert/models/geofence_state.dart';
import 'package:border_safety_alert/services/alert_service.dart';
import 'package:border_safety_alert/services/notification_service.dart';
import 'package:border_safety_alert/services/vibration_alert_service.dart';
import 'package:border_safety_alert/services/voice_alert_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeVoice implements VoiceAlertOutput {
  final messages = <String>[];
  bool fail = false;

  @override
  Future<void> speak(String message) async {
    if (fail) throw StateError('tts unavailable');
    messages.add(message);
  }

  @override
  Future<void> stop() async {}
}

class FakeVibration implements VibrationAlertOutput {
  final severities = <AlertSeverity>[];
  bool fail = false;

  @override
  Future<void> vibrate(AlertSeverity severity) async {
    if (fail) throw StateError('vibration unavailable');
    severities.add(severity);
  }

  @override
  Future<void> stop() async {}
}

class FakeNotifications implements NotificationAlertOutput {
  final messages = <String>[];
  bool fail = false;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> showAlert(AlertSeverity severity, String message) async {
    if (fail) throw StateError('notifications unavailable');
    messages.add(message);
  }

  @override
  Future<void> cancelAlerts() async {}
}

GeoFenceResult result(GeoFenceState state) => GeoFenceResult(state: state);

void main() {
  late FakeVoice voice;
  late FakeVibration vibration;
  late FakeNotifications notifications;
  late AlertService service;
  var now = DateTime(2026, 1, 1);

  setUp(() {
    voice = FakeVoice();
    vibration = FakeVibration();
    notifications = FakeNotifications();
    service = AlertService(
      voice: voice,
      vibration: vibration,
      notifications: notifications,
      cooldown: const Duration(minutes: 1),
      now: () => now,
    );
  });

  test('unknown and safe do not alert', () async {
    await service.start();
    expect(
      await service.processGeoFenceResult(result(GeoFenceState.unknown)),
      isNull,
    );
    expect(
      await service.processGeoFenceResult(result(GeoFenceState.safe)),
      isNull,
    );
    expect(voice.messages, isEmpty);
  });

  test(
    'maps caution, warning, and restricted area to alert severity',
    () async {
      await service.start();
      final caution = await service.processGeoFenceResult(
        result(GeoFenceState.caution),
      );
      final warning = await service.processGeoFenceResult(
        result(GeoFenceState.warning),
      );
      final restricted = await service.processGeoFenceResult(
        result(GeoFenceState.insideRestrictedArea),
      );
      expect(caution!.message.severity, AlertSeverity.caution);
      expect(warning!.message.severity, AlertSeverity.warning);
      expect(restricted!.message.severity, AlertSeverity.critical);
      expect(voice.messages, hasLength(3));
    },
  );

  test('same severity is cooled down and escalation is immediate', () async {
    await service.start();
    await service.processGeoFenceResult(result(GeoFenceState.caution));
    await service.processGeoFenceResult(result(GeoFenceState.caution));
    final warning = await service.processGeoFenceResult(
      result(GeoFenceState.warning),
    );
    await service.processGeoFenceResult(result(GeoFenceState.warning));
    expect(warning, isNotNull);
    expect(voice.messages, hasLength(2));
  });

  test('de-escalation does not create a new alert', () async {
    await service.start();
    await service.processGeoFenceResult(result(GeoFenceState.critical));
    final warning = await service.processGeoFenceResult(
      result(GeoFenceState.warning),
    );
    expect(warning, isNull);
    expect(voice.messages, hasLength(1));
  });

  test('same state alerts again after cooldown', () async {
    await service.start();
    await service.processGeoFenceResult(result(GeoFenceState.caution));
    now = now.add(const Duration(minutes: 1, seconds: 1));
    final event = await service.processGeoFenceResult(
      result(GeoFenceState.caution),
    );
    expect(event, isNotNull);
    expect(voice.messages, hasLength(2));
  });

  test('disabled channels are not invoked', () async {
    service.updatePreferences(
      const AlertPreferences(
        voiceEnabled: false,
        vibrationEnabled: false,
        notificationsEnabled: false,
      ),
    );
    await service.start();
    await service.processGeoFenceResult(result(GeoFenceState.warning));
    expect(voice.messages, isEmpty);
    expect(vibration.severities, isEmpty);
    expect(notifications.messages, isEmpty);
  });

  test('platform failures do not escape alert processing', () async {
    voice.fail = true;
    vibration.fail = true;
    notifications.fail = true;
    await service.start();
    await expectLater(
      service.processGeoFenceResult(result(GeoFenceState.critical)),
      completes,
    );
  });
}
