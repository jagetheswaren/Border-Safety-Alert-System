import 'package:flutter/material.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_typography.dart';
import '../core/widgets/status_badge.dart';
import '../models/alert_preferences.dart';
import '../services/model_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.preferences = const AlertPreferences(),
    this.onPreferencesChanged,
    this.modelManager,
    this.onOpenDiagnostics,
  });

  final AlertPreferences preferences;
  final ValueChanged<AlertPreferences>? onPreferencesChanged;
  final ModelManager? modelManager;
  final VoidCallback? onOpenDiagnostics;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool voiceAlerts;
  late bool vibration;
  late bool notifications;
  late bool soundAlerts;
  String language = 'English';

  @override
  void initState() {
    super.initState();
    _applyPreferences(widget.preferences);
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preferences != widget.preferences) {
      _applyPreferences(widget.preferences);
    }
  }

  void _applyPreferences(AlertPreferences preferences) {
    voiceAlerts = preferences.voiceEnabled;
    vibration = preferences.vibrationEnabled;
    notifications = preferences.notificationsEnabled;
    soundAlerts = preferences.soundEnabled;
  }

  void _updatePreferences(AlertPreferences preferences) {
    setState(() => _applyPreferences(preferences));
    widget.onPreferencesChanged?.call(preferences);
  }

  @override
  Widget build(BuildContext context) {
    final mm = widget.modelManager;

    return Scaffold(
      key: const Key('screen-settings'),
      backgroundColor: BsasColors.darkBackground,
      appBar: AppBar(
        backgroundColor: BsasColors.darkSurface,
        title: const Text('Settings & Configuration', style: BsasTypography.headline),
      ),
      body: ListView(
        children: [
          _header('ALERT HARDWARE OUTPUTS'),
          SwitchListTile(
            key: const Key('setting-sound'),
            title: const Text('Audio Sound Alerts', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Local acoustic sirens for Warning and Critical events'),
            value: soundAlerts,
            onChanged: (v) => _updatePreferences(
              widget.preferences.copyWith(soundEnabled: v),
            ),
          ),
          SwitchListTile(
            key: const Key('setting-voice'),
            title: const Text('Voice alerts (TTS)', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Text-to-speech spoken safety warnings'),
            value: voiceAlerts,
            onChanged: (v) => _updatePreferences(
              widget.preferences.copyWith(voiceEnabled: v),
            ),
          ),
          SwitchListTile(
            key: const Key('setting-vibration'),
            title: const Text('Vibration Haptics', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Physical tactile pulses for boundary escalation'),
            value: vibration,
            onChanged: (v) => _updatePreferences(
              widget.preferences.copyWith(vibrationEnabled: v),
            ),
          ),
          SwitchListTile(
            key: const Key('setting-notifications'),
            title: const Text('Android Notifications', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Dedicated system channels for high-priority alerts'),
            value: notifications,
            onChanged: (v) => _updatePreferences(
              widget.preferences.copyWith(notificationsEnabled: v),
            ),
          ),

          _header('REGIONAL PREFERENCES'),
          ListTile(
            title: const Text('Language', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Interface and voice alert translation'),
            trailing: DropdownButton<String>(
              key: const Key('setting-language'),
              dropdownColor: BsasColors.darkSurface,
              value: language,
              style: const TextStyle(color: Colors.white),
              items: const [
                DropdownMenuItem(value: 'English', child: Text('English')),
                DropdownMenuItem(value: 'Tamil', child: Text('Tamil')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => language = v);
              },
            ),
          ),

          _header('LOCAL OFFLINE AI ASSISTANT'),
          if (mm != null)
            ListenableBuilder(
              listenable: mm,
              builder: (context, _) {
                final isReady = mm.isModelReady;
                return Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.psychology, color: BsasColors.radarCyan),
                      title: const Text('Qwen3-0.6B-Q4_0 GGUF', style: TextStyle(color: Colors.white)),
                      subtitle: Text(
                        'Engine: llama.cpp • Status: ${mm.state.name.toUpperCase()}\n'
                        'Context: 2048 tokens • License: Apache-2.0',
                      ),
                      trailing: StatusBadge(
                        label: mm.state.name.toUpperCase(),
                        state: isReady ? StatusState.ready : StatusState.notInstalled,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          if (!isReady)
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: BsasColors.radarCyan),
                                icon: const Icon(Icons.download, color: Colors.black),
                                label: const Text('Install Model', style: TextStyle(color: Colors.black)),
                                onPressed: () => mm.installLocalModel(),
                              ),
                            )
                          else ...[
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.verified, size: 16),
                                label: const Text('Verify SHA-256'),
                                onPressed: () => mm.verifyChecksum(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.delete_outline, size: 16, color: BsasColors.criticalRed),
                              label: const Text('Delete', style: TextStyle(color: BsasColors.criticalRed)),
                              onPressed: () => mm.deleteModel(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

          _header('DIAGNOSTICS & SYSTEM STATUS'),
          ListTile(
            leading: const Icon(Icons.monitor_heart_outlined, color: BsasColors.safeGreen),
            title: const Text('System Diagnostics', style: TextStyle(color: Colors.white)),
            subtitle: const Text('View live sensor states, latencies, and run I/O tests'),
            trailing: const Icon(Icons.chevron_right, color: BsasColors.textMuted),
            onTap: widget.onOpenDiagnostics,
          ),

          _header('ABOUT & LICENSING'),
          const ListTile(
            leading: Icon(Icons.verified_user_outlined, color: BsasColors.safeGreen),
            title: Text('BSAS v2.4 Production Build', style: TextStyle(color: Colors.white)),
            subtitle: Text('Border Safety & Alert System • Offline-First Civilian Safety'),
          ),
          const ListTile(
            leading: Icon(Icons.copyright_outlined),
            title: Text('Open Source Licenses', style: TextStyle(color: Colors.white)),
            subtitle: Text('Qwen3 (Apache-2.0) • llama.cpp (MIT) • Flutter Map (BSD)'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _header(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8, left: 16, right: 16),
      child: Text(
        title,
        style: BsasTypography.caption.copyWith(
          color: BsasColors.radarCyan,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
