class AlertPreferences {
  const AlertPreferences({
    this.voiceEnabled = true,
    this.vibrationEnabled = true,
    this.notificationsEnabled = true,
    this.soundEnabled = true,
  });

  final bool voiceEnabled;
  final bool vibrationEnabled;
  final bool notificationsEnabled;
  final bool soundEnabled;

  AlertPreferences copyWith({
    bool? voiceEnabled,
    bool? vibrationEnabled,
    bool? notificationsEnabled,
    bool? soundEnabled,
  }) {
    return AlertPreferences(
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }
}
