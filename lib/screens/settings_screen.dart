import 'package:flutter/material.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_spacing.dart';
import '../core/theme/bsas_typography.dart';
import '../core/widgets/status_badge.dart';
import '../models/alert_preferences.dart';
import '../services/model_manager.dart';
import 'about_screen.dart';
import 'help_screen.dart';
import 'onboarding_screen.dart';
import 'permission_setup_screen.dart';
import 'privacy_screen.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: const Key('screen-settings'),
      backgroundColor: BsasColors.background(isDark),
      appBar: AppBar(
        backgroundColor: BsasColors.surface(isDark),
        title: Text(
          'Settings & Configuration',
          style: BsasTypography.heading.copyWith(color: BsasColors.text(isDark)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: BsasSpacing.lg),
        children: [
          _sectionHeader('ALERT HARDWARE OUTPUTS', isDark),
          _settingsCard(
            isDark: isDark,
            children: [
              SwitchListTile(
                key: const Key('setting-sound'),
                activeTrackColor: BsasColors.primaryBlue,
                activeThumbColor: Colors.white,
                title: Text(
                  'Audio Sound Alerts',
                  style: BsasTypography.title.copyWith(color: BsasColors.text(isDark), fontSize: 15),
                ),
                subtitle: Text(
                  'Local acoustic sirens for Warning and Critical events',
                  style: BsasTypography.caption.copyWith(color: BsasColors.textSec(isDark)),
                ),
                value: soundAlerts,
                onChanged: (v) => _updatePreferences(
                  widget.preferences.copyWith(soundEnabled: v),
                ),
              ),
              Divider(height: 1, color: BsasColors.border(isDark)),
              SwitchListTile(
                key: const Key('setting-voice'),
                activeTrackColor: BsasColors.primaryBlue,
                activeThumbColor: Colors.white,
                title: Text(
                  'Voice alerts (TTS)',
                  style: BsasTypography.title.copyWith(color: BsasColors.text(isDark), fontSize: 15),
                ),
                subtitle: Text(
                  'Text-to-speech spoken safety instructions in local audio channel',
                  style: BsasTypography.caption.copyWith(color: BsasColors.textSec(isDark)),
                ),
                value: voiceAlerts,
                onChanged: (v) => _updatePreferences(
                  widget.preferences.copyWith(voiceEnabled: v),
                ),
              ),
              Divider(height: 1, color: BsasColors.border(isDark)),
              SwitchListTile(
                key: const Key('setting-vibration'),
                activeTrackColor: BsasColors.primaryBlue,
                activeThumbColor: Colors.white,
                title: Text(
                  'Vibration Haptics',
                  style: BsasTypography.title.copyWith(color: BsasColors.text(isDark), fontSize: 15),
                ),
                subtitle: Text(
                  'Physical tactile pulses for boundary escalation',
                  style: BsasTypography.caption.copyWith(color: BsasColors.textSec(isDark)),
                ),
                value: vibration,
                onChanged: (v) => _updatePreferences(
                  widget.preferences.copyWith(vibrationEnabled: v),
                ),
              ),
              Divider(height: 1, color: BsasColors.border(isDark)),
              SwitchListTile(
                key: const Key('setting-notifications'),
                activeTrackColor: BsasColors.primaryBlue,
                activeThumbColor: Colors.white,
                title: Text(
                  'Android Notifications',
                  style: BsasTypography.title.copyWith(color: BsasColors.text(isDark), fontSize: 15),
                ),
                subtitle: Text(
                  'Dedicated system channels for high-priority alerts',
                  style: BsasTypography.caption.copyWith(color: BsasColors.textSec(isDark)),
                ),
                value: notifications,
                onChanged: (v) => _updatePreferences(
                  widget.preferences.copyWith(notificationsEnabled: v),
                ),
              ),
            ],
          ),

          _sectionHeader('REGIONAL PREFERENCES', isDark),
          _settingsCard(
            isDark: isDark,
            children: [
              ListTile(
                title: Text(
                  'Language',
                  style: BsasTypography.title.copyWith(color: BsasColors.text(isDark), fontSize: 15),
                ),
                subtitle: Text(
                  'Interface and voice alert spoken language',
                  style: BsasTypography.caption.copyWith(color: BsasColors.textSec(isDark)),
                ),
                trailing: DropdownButton<String>(
                  key: const Key('setting-language'),
                  dropdownColor: BsasColors.card(isDark),
                  value: language,
                  underline: const SizedBox.shrink(),
                  style: BsasTypography.label.copyWith(
                    color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
                    fontSize: 14,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'English', child: Text('English')),
                    DropdownMenuItem(value: 'Tamil', child: Text('Tamil (தமிழ்)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => language = v);
                  },
                ),
              ),
            ],
          ),

          _sectionHeader('LOCAL OFFLINE AI ASSISTANT', isDark),
          if (mm != null)
            ListenableBuilder(
              listenable: mm,
              builder: (context, _) {
                final isReady = mm.isModelReady;
                return _settingsCard(
                  isDark: isDark,
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(BsasSpacing.sm),
                        decoration: BoxDecoration(
                          color: (isDark ? BsasColors.primaryBlue : BsasColors.primaryBlueLight).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
                        ),
                        child: Icon(
                          Icons.psychology_outlined,
                          color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        'Qwen3-0.6B-Q4_0 GGUF',
                        style: BsasTypography.title.copyWith(color: BsasColors.text(isDark), fontSize: 15),
                      ),
                      subtitle: Text(
                        'Engine: llama.cpp • Context: 2048 tokens\nLicense: Apache-2.0 • Status: ${mm.state.name.toUpperCase()}',
                        style: BsasTypography.caption.copyWith(color: BsasColors.textSec(isDark), height: 1.3),
                      ),
                      trailing: StatusBadge(
                        label: mm.state.name.toUpperCase(),
                        state: isReady ? StatusState.ready : StatusState.notInstalled,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(BsasSpacing.md),
                      child: Row(
                        children: [
                          if (!isReady)
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
                                  foregroundColor: isDark ? Colors.black : Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: BsasSpacing.md),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
                                  ),
                                ),
                                icon: const Icon(Icons.download, size: 18),
                                label: const Text('Install Model File', style: TextStyle(fontWeight: FontWeight.w600)),
                                onPressed: () => mm.installLocalModel(),
                              ),
                            )
                          else ...[
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: BsasColors.border(isDark)),
                                  padding: const EdgeInsets.symmetric(vertical: BsasSpacing.md),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
                                  ),
                                ),
                                icon: const Icon(Icons.verified_outlined, size: 16),
                                label: const Text('Verify SHA-256'),
                                onPressed: () => mm.verifyChecksum(),
                              ),
                            ),
                            const SizedBox(width: BsasSpacing.sm),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: BsasColors.criticalRed),
                                padding: const EdgeInsets.symmetric(vertical: BsasSpacing.md),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
                                ),
                              ),
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

          _sectionHeader('SYSTEM, PERMISSIONS & TOUR', isDark),
          _settingsCard(
            isDark: isDark,
            children: [
              ListTile(
                leading: Icon(Icons.security, color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue, size: 22),
                title: Text('System Permissions', style: BsasTypography.title.copyWith(color: BsasColors.text(isDark), fontSize: 15)),
                subtitle: Text('Audit and configure GNSS location and notification channels', style: BsasTypography.caption.copyWith(color: BsasColors.textSec(isDark))),
                trailing: Icon(Icons.chevron_right, color: BsasColors.textMut(isDark)),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PermissionSetupScreen()),
                  );
                },
              ),
              Divider(height: 1, color: BsasColors.border(isDark)),
              ListTile(
                leading: Icon(Icons.explore_outlined, color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue, size: 22),
                title: Text('Feature Onboarding Tour', style: BsasTypography.title.copyWith(color: BsasColors.text(isDark), fontSize: 15)),
                subtitle: Text('Review offline-first capabilities and civilian protection protocols', style: BsasTypography.caption.copyWith(color: BsasColors.textSec(isDark))),
                trailing: Icon(Icons.chevron_right, color: BsasColors.textMut(isDark)),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  );
                },
              ),
            ],
          ),

          _sectionHeader('DIAGNOSTICS & HARDWARE VERIFICATION', isDark),
          _settingsCard(
            isDark: isDark,
            children: [
              ListTile(
                leading: const Icon(Icons.monitor_heart_outlined, color: BsasColors.safeGreen, size: 22),
                title: Text('System Diagnostics', style: BsasTypography.title.copyWith(color: BsasColors.text(isDark), fontSize: 15)),
                subtitle: Text('View live sensor states, latencies, and run I/O tests', style: BsasTypography.caption.copyWith(color: BsasColors.textSec(isDark))),
                trailing: Icon(Icons.chevron_right, color: BsasColors.textMut(isDark)),
                onTap: widget.onOpenDiagnostics,
              ),
            ],
          ),

          _sectionHeader('HELP & DATA GOVERNANCE', isDark),
          _settingsCard(
            isDark: isDark,
            children: [
              ListTile(
                leading: Icon(Icons.help_outline, color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue, size: 22),
                title: Text('Emergency Help & Protocols', style: BsasTypography.title.copyWith(color: BsasColors.text(isDark), fontSize: 15)),
                subtitle: Text('Severity tiers, escape routing advice, and troubleshooting', style: BsasTypography.caption.copyWith(color: BsasColors.textSec(isDark))),
                trailing: Icon(Icons.chevron_right, color: BsasColors.textMut(isDark)),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HelpScreen()),
                  );
                },
              ),
              Divider(height: 1, color: BsasColors.border(isDark)),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined, color: BsasColors.safeGreen, size: 22),
                title: Text('Privacy & Data Governance', style: BsasTypography.title.copyWith(color: BsasColors.text(isDark), fontSize: 15)),
                subtitle: Text('Zero cloud telemetry policy and local SQLite purge', style: BsasTypography.caption.copyWith(color: BsasColors.textSec(isDark))),
                trailing: Icon(Icons.chevron_right, color: BsasColors.textMut(isDark)),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                  );
                },
              ),
              Divider(height: 1, color: BsasColors.border(isDark)),
              ListTile(
                leading: Icon(Icons.info_outline, color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue, size: 22),
                title: Text('About BSAS', style: BsasTypography.title.copyWith(color: BsasColors.text(isDark), fontSize: 15)),
                subtitle: Text('Version v1.1.0 • Architecture, licenses & build details', style: BsasTypography.caption.copyWith(color: BsasColors.textSec(isDark))),
                trailing: Icon(Icons.chevron_right, color: BsasColors.textMut(isDark)),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: BsasSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(
        top: BsasSpacing.xl,
        bottom: BsasSpacing.xs,
        left: BsasSpacing.lg,
        right: BsasSpacing.lg,
      ),
      child: Text(
        title,
        style: BsasTypography.sectionHeading.copyWith(
          color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
        ),
      ),
    );
  }

  Widget _settingsCard({required bool isDark, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: BsasSpacing.lg,
        vertical: BsasSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
        border: Border.all(color: BsasColors.border(isDark)),
      ),
      child: Material(
        color: BsasColors.card(isDark),
        borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: children,
        ),
      ),
    );
  }
}
