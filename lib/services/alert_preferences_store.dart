import 'package:shared_preferences/shared_preferences.dart';

import '../models/alert_preferences.dart';

class AlertPreferencesStore {
  const AlertPreferencesStore({this.preferencesProvider = SharedPreferences.getInstance});

  final Future<SharedPreferences> Function() preferencesProvider;

  Future<AlertPreferences> load() async {
    try {
      final preferences = await preferencesProvider();
      // Older builds defaulted vibration on, which could keep the phone
      // vibrating as soon as any sample boundary was loaded. Migrate existing
      // installs once to the new quiet-by-default behavior.
      if (preferences.getBool(_vibrationPreferenceInitializedKey) != true) {
        await preferences.setBool(_vibrationKey, false);
        await preferences.setBool(_vibrationPreferenceInitializedKey, true);
      }
      return AlertPreferences(
        voiceEnabled: preferences.getBool(_voiceKey) ?? true,
        vibrationEnabled: preferences.getBool(_vibrationKey) ?? false,
        notificationsEnabled: preferences.getBool(_notificationsKey) ?? true,
        soundEnabled: preferences.getBool(_soundKey) ?? true,
      );
    } catch (_) {
      return const AlertPreferences();
    }
  }

  Future<void> save(AlertPreferences value) async {
    try {
      final preferences = await preferencesProvider();
      await preferences.setBool(_voiceKey, value.voiceEnabled);
      await preferences.setBool(_vibrationKey, value.vibrationEnabled);
      await preferences.setBool(_notificationsKey, value.notificationsEnabled);
      await preferences.setBool(_soundKey, value.soundEnabled);
    } catch (_) {
      // Preferences are optional; alert processing must continue without them.
    }
  }

  static const _voiceKey = 'alert_voice_enabled';
  static const _vibrationKey = 'alert_vibration_enabled';
  static const _vibrationPreferenceInitializedKey = 'alert_vibration_default_migrated_v1';
  static const _notificationsKey = 'alert_notifications_enabled';
  static const _soundKey = 'alert_sound_enabled';
}
