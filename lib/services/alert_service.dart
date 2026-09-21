import '../models/alert_message.dart';
import '../models/alert_preferences.dart';
import '../models/alert_severity.dart';
import '../models/geofence_result.dart';
import '../models/geofence_state.dart';
import 'notification_service.dart';
import 'sound_service.dart';
import 'vibration_alert_service.dart';
import 'voice_alert_service.dart';

typedef AlertClock = DateTime Function();

class AlertDeliveryStatus {
  const AlertDeliveryStatus({
    this.soundPlayed = false,
    this.vibrationPlayed = false,
    this.ttsPlayed = false,
    this.notificationPosted = false,
  });

  final bool soundPlayed;
  final bool vibrationPlayed;
  final bool ttsPlayed;
  final bool notificationPosted;
}

class AlertEvent {
  const AlertEvent({
    required this.message,
    required this.result,
    this.timestamp,
    this.deliveryStatus = const AlertDeliveryStatus(),
  });

  final AlertMessage message;
  final GeoFenceResult result;
  final DateTime? timestamp;
  final AlertDeliveryStatus deliveryStatus;
}

class AlertService {
  AlertService({
    this.voice,
    this.vibration,
    this.notifications,
    this.sound,
    this.cooldown = const Duration(seconds: 30),
    AlertClock? now,
    this.preferences = const AlertPreferences(),
  }) : _now = now ?? DateTime.now;

  final VoiceAlertOutput? voice;
  final VibrationAlertOutput? vibration;
  final NotificationAlertOutput? notifications;
  final SoundService? sound;
  final Duration cooldown;
  final AlertClock _now;
  AlertPreferences preferences;
  GeoFenceState? _lastProcessedState;
  AlertSeverity? _lastAlertSeverity;
  GeoFenceState? _lastAlertState;
  DateTime? _lastAlertTimestamp;
  bool _running = false;

  final List<AlertEvent> _history = [];
  List<AlertEvent> get history => List.unmodifiable(_history);

  GeoFenceState? get lastAlertState => _lastAlertState;
  DateTime? get lastAlertTimestamp => _lastAlertTimestamp;
  bool get isRunning => _running;

  Future<void> start() async {
    _running = true;
    try {
      await notifications?.initialize();
      if (voice case final VoiceAlertService voiceService) {
        await voiceService.initialize();
      }
    } catch (_) {}
  }

  Future<void> stop() async {
    _running = false;
    try {
      await voice?.stop();
      await vibration?.stop();
      await notifications?.cancelAlerts();
      await sound?.stop();
    } catch (_) {}
  }

  void reset() {
    _lastProcessedState = null;
    _lastAlertSeverity = null;
    _lastAlertState = null;
    _lastAlertTimestamp = null;
  }

  void updatePreferences(AlertPreferences value) => preferences = value;

  Future<AlertEvent?> processGeoFenceResult(GeoFenceResult result) async {
    final state = result.state;
    final previousState = _lastProcessedState;
    _lastProcessedState = state;
    if (!_running) return null;

    final message = alertMessageForState(state);
    if (message == null) return null;

    final previousSeverity = previousState == null
        ? null
        : severityForGeoFenceState(previousState);
    final escalated =
        previousSeverity == null ||
        message.severity.level > previousSeverity.level ||
        (state == GeoFenceState.insideRestrictedArea && previousState != state);
    final sameSeverity = _lastAlertSeverity == message.severity;
    final withinCooldown =
        _lastAlertTimestamp != null &&
        _now().difference(_lastAlertTimestamp!) < cooldown;
    if (sameSeverity && withinCooldown && !escalated) return null;
    if (!escalated) {
      if (message.severity.level < previousSeverity.level) {
        return null;
      }
    }

    _lastAlertSeverity = message.severity;
    _lastAlertState = state;
    final timestamp = _now();
    _lastAlertTimestamp = timestamp;

    final deliveryStatus = await _dispatch(message, state);
    final event = AlertEvent(
      message: message,
      result: result,
      timestamp: timestamp,
      deliveryStatus: deliveryStatus,
    );

    _history.insert(0, event);
    if (_history.length > 50) {
      _history.removeLast();
    }

    return event;
  }

  Future<AlertDeliveryStatus> _dispatch(
    AlertMessage alertMessage,
    GeoFenceState state,
  ) async {
    final message = alertMessage.message;
    bool soundPlayed = false;
    bool vibrationPlayed = false;
    bool ttsPlayed = false;
    bool notificationPosted = false;

    // 1. Audio sound playback
    if (preferences.soundEnabled && sound != null) {
      try {
        if (alertMessage.severity == AlertSeverity.critical) {
          await sound!.playCritical();
        } else {
          await sound!.playWarning();
        }
        soundPlayed = true;
      } catch (_) {}
    }

    // 2. TTS Voice
    if (preferences.voiceEnabled && voice != null) {
      try {
        await voice!.speak(message);
        ttsPlayed = true;
      } catch (_) {}
    }

    // 3. Vibration
    if (preferences.vibrationEnabled && vibration != null) {
      try {
        await vibration!.vibrate(alertMessage.severity);
        vibrationPlayed = true;
      } catch (_) {}
    }

    // 4. Android Notifications
    if (preferences.notificationsEnabled && notifications != null) {
      try {
        await notifications!.showAlert(alertMessage.severity, message);
        notificationPosted = true;
      } catch (_) {}
    }

    return AlertDeliveryStatus(
      soundPlayed: soundPlayed,
      vibrationPlayed: vibrationPlayed,
      ttsPlayed: ttsPlayed,
      notificationPosted: notificationPosted,
    );
  }
}
