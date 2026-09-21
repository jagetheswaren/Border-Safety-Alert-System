import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/alert_severity.dart';

abstract interface class NotificationAlertOutput {
  Future<void> initialize();
  Future<void> showAlert(AlertSeverity severity, String message);
  Future<void> cancelAlerts();
}

class NotificationService implements NotificationAlertOutput {
  NotificationService({FlutterLocalNotificationsPlugin? notifications})
    : _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _notifications;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  static const String channelCritical = 'bsas_critical_alerts';
  static const String channelWarning = 'bsas_warning_alerts';
  static const String channelSystem = 'bsas_system_notifications';
  static const String channelAi = 'bsas_ai_notifications';

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      const settings = AndroidInitializationSettings('@mipmap/ic_launcher');
      final initialized = await _notifications.initialize(
        const InitializationSettings(android: settings),
      );
      _initialized = initialized ?? false;
      if (_initialized) {
        final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

        if (androidPlugin != null) {
          // Channel 1: Critical Alerts
          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              channelCritical,
              'BSAS Critical Alerts',
              description: 'Urgent restricted area entries and critical threats',
              importance: Importance.max,
              enableVibration: true,
              playSound: true,
            ),
          );

          // Channel 2: Warning Alerts
          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              channelWarning,
              'BSAS Warning Alerts',
              description: 'Proximity warnings and high-risk boundary alerts',
              importance: Importance.high,
              enableVibration: true,
              playSound: true,
            ),
          );

          // Channel 3: System Notifications
          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              channelSystem,
              'BSAS System Notifications',
              description: 'GPS locks, sync events, and background status',
              importance: Importance.defaultImportance,
              enableVibration: false,
              playSound: false,
            ),
          );

          // Channel 4: AI Notifications
          await androidPlugin.createNotificationChannel(
            const AndroidNotificationChannel(
              channelAi,
              'BSAS AI Notifications',
              description: 'Offline AI assistant generation and status updates',
              importance: Importance.low,
              enableVibration: false,
              playSound: false,
            ),
          );
        }
      }
    } catch (_) {
      _initialized = false;
    }
  }

  @override
  Future<void> showAlert(AlertSeverity severity, String message) async {
    if (!_initialized) await initialize();
    if (!_initialized) return;

    final isCritical = severity == AlertSeverity.critical;
    final channelId = isCritical ? channelCritical : channelWarning;
    final channelName = isCritical ? 'BSAS Critical Alerts' : 'BSAS Warning Alerts';
    final importance = isCritical ? Importance.max : Importance.high;
    final priority = isCritical ? Priority.max : Priority.high;
    final id = isCritical ? 100 : 101;

    try {
      await _notifications.show(
        id,
        'BSAS ${severity.label.toUpperCase()} ALERT',
        message,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: isCritical
                ? 'Urgent restricted area entries and critical threats'
                : 'Proximity warnings and high-risk boundary alerts',
            importance: importance,
            priority: priority,
            category: isCritical
                ? AndroidNotificationCategory.alarm
                : AndroidNotificationCategory.reminder,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> showSystemNotification(String title, String message) async {
    if (!_initialized) await initialize();
    if (!_initialized) return;

    try {
      await _notifications.show(
        200,
        title,
        message,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelSystem,
            'BSAS System Notifications',
            channelDescription: 'GPS locks, sync events, and background status',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            category: AndroidNotificationCategory.status,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> showAiNotification(String title, String message) async {
    if (!_initialized) await initialize();
    if (!_initialized) return;

    try {
      await _notifications.show(
        300,
        title,
        message,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelAi,
            'BSAS AI Notifications',
            channelDescription: 'Offline AI assistant generation and status updates',
            importance: Importance.low,
            priority: Priority.low,
            category: AndroidNotificationCategory.recommendation,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    } catch (_) {}
  }

  @override
  Future<void> cancelAlerts() async {
    try {
      await _notifications.cancel(100);
      await _notifications.cancel(101);
    } catch (_) {}
  }
}
