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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: BsasColors.surface(isDark),
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: BsasColors.text(isDark)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                Icon(Icons.settings_outlined, color: BsasColors.radarCyan, size: 20),
                const SizedBox(width: BsasSpacing.sm),
                Text(
                  'SYSTEM CONFIG',
                  style: BsasTypography.heading.copyWith(
                    color: BsasColors.text(isDark),
                    letterSpacing: 1.2,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(
                color: isDark ? BsasColors.darkBorder : BsasColors.lightBorder,
                height: 1.0,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: BsasSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _sectionHeader('ALERT HARDWARE OUTPUTS', isDark),
                _settingsCard(
                  isDark: isDark,
                  children: [
                    _buildSwitchTile(
                      key: 'setting-sound',
                      title: 'Audio Sound Alerts',
                      subtitle: 'Local acoustic sirens for Warning and Critical events',
                      value: soundAlerts,
                      isDark: isDark,
                      onChanged: (v) => _updatePreferences(widget.preferences.copyWith(soundEnabled: v)),
                    ),
                    _divider(isDark),
                    _buildSwitchTile(
                      key: 'setting-voice',
                      title: 'Voice alerts (TTS)',
                      subtitle: 'Text-to-speech spoken safety instructions in local audio channel',
                      value: voiceAlerts,
                      isDark: isDark,
                      onChanged: (v) => _updatePreferences(widget.preferences.copyWith(voiceEnabled: v)),
                    ),
                    _divider(isDark),
                    _buildSwitchTile(
                      key: 'setting-vibration',
                      title: 'Vibration Haptics',
                      subtitle: 'Physical tactile pulses for boundary escalation',
                      value: vibration,
                      isDark: isDark,
                      onChanged: (v) => _updatePreferences(widget.preferences.copyWith(vibrationEnabled: v)),
                    ),
                    _divider(isDark),
                    _buildSwitchTile(
                      key: 'setting-notifications',
                      title: 'Android Notifications',
                      subtitle: 'Dedicated system channels for high-priority alerts',
                      value: notifications,
                      isDark: isDark,
                      onChanged: (v) => _updatePreferences(widget.preferences.copyWith(notificationsEnabled: v)),
                    ),
                  ],
                ),

                _sectionHeader('REGIONAL PREFERENCES', isDark),
                _settingsCard(
                  isDark: isDark,
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: BsasSpacing.lg, vertical: BsasSpacing.xs),
                      title: Text(
                        'Language',
                        style: BsasTypography.title.copyWith(color: BsasColors.text(isDark), fontSize: 15),
                      ),
                      subtitle: Text(
                        'Interface and voice alert spoken language',
                        style: BsasTypography.caption.copyWith(color: BsasColors.textSec(isDark)),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.sm),
                        decoration: BoxDecoration(
                          color: BsasColors.surface(isDark),
                          borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
                          border: Border.all(color: BsasColors.border(isDark)),
                        ),
                        child: DropdownButton<String>(
                          key: const Key('setting-language'),
                          dropdownColor: BsasColors.surface(isDark),
                          value: language,
                          underline: const SizedBox.shrink(),
                          icon: Icon(Icons.keyboard_arrow_down, color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue),
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: BsasSpacing.lg, vertical: BsasSpacing.xs),
                            leading: Container(
                              padding: const EdgeInsets.all(BsasSpacing.sm),
                              decoration: BoxDecoration(
                                color: (isDark ? BsasColors.primaryBlue : BsasColors.primaryBlueLight).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
                                border: Border.all(color: (isDark ? BsasColors.primaryBlue : BsasColors.primaryBlueLight).withValues(alpha: 0.3)),
                              ),
                              child: Icon(
                                Icons.psychology_outlined,
                                color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
                                size: 24,
                              ),
                            ),
                            title: Text(
                              'Qwen3-0.6B-Q4_0 GGUF',
                              style: BsasTypography.title.copyWith(color: BsasColors.text(isDark), fontSize: 15),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: BsasSpacing.xs),
                              child: Text(
                                'Engine: llama.cpp • Context: 2048\nLicense: Apache-2.0',
                                style: BsasTypography.caption.copyWith(color: BsasColors.textSec(isDark), height: 1.3),
                              ),
                            ),
                            trailing: StatusBadge(
                              label: mm.state.name.toUpperCase(),
                              state: isReady ? StatusState.ready : StatusState.notInstalled,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(BsasSpacing.md),
                            decoration: BoxDecoration(
                              color: isDark ? BsasColors.darkBackground : BsasColors.lightBackground,
                              border: Border(top: BorderSide(color: BsasColors.border(isDark))),
                            ),
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
                                        elevation: 0,
                                      ),
                                      icon: const Icon(Icons.download, size: 18),
                                      label: const Text('Install Model', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                                      onPressed: () => mm.installLocalModel(),
                                    ),
                                  )
                                else ...[
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: BsasColors.border(isDark)),
                                        foregroundColor: BsasColors.text(isDark),
                                        padding: const EdgeInsets.symmetric(vertical: BsasSpacing.md),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
                                        ),
                                      ),
                                      icon: const Icon(Icons.verified_outlined, size: 16),
                                      label: const Text('Verify Hash', style: TextStyle(letterSpacing: 0.5)),
                                      onPressed: () => mm.verifyChecksum(),
                                    ),
                                  ),
                                  const SizedBox(width: BsasSpacing.md),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: BsasColors.criticalRed.withValues(alpha: 0.5)),
                                      foregroundColor: BsasColors.criticalRed,
                                      padding: const EdgeInsets.symmetric(vertical: BsasSpacing.md),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
                                      ),
                                    ),
                                    icon: const Icon(Icons.delete_outline, size: 16),
                                    label: const Text('Purge', style: TextStyle(letterSpacing: 0.5)),
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

                _sectionHeader('SYSTEM & DIAGNOSTICS', isDark),
                _settingsCard(
                  isDark: isDark,
                  children: [
                    _buildNavTile(
                      icon: Icons.security,
                      iconColor: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
                      title: 'System Permissions',
                      subtitle: 'Audit GNSS and notification channels',
                      isDark: isDark,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PermissionSetupScreen())),
                    ),
                    _divider(isDark),
                    _buildNavTile(
                      icon: Icons.monitor_heart_outlined,
                      iconColor: BsasColors.safeGreen,
                      title: 'Hardware Diagnostics',
                      subtitle: 'Live sensor states & latency tests',
                      isDark: isDark,
                      onTap: () => widget.onOpenDiagnostics?.call(),
                    ),
                    _divider(isDark),
                    _buildNavTile(
                      icon: Icons.explore_outlined,
                      iconColor: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
                      title: 'Feature Tour',
                      subtitle: 'Review offline-first protocols',
                      isDark: isDark,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OnboardingScreen())),
                    ),
                  ],
                ),

                _sectionHeader('GOVERNANCE & HELP', isDark),
                _settingsCard(
                  isDark: isDark,
                  children: [
                    _buildNavTile(
                      icon: Icons.help_outline,
                      iconColor: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
                      title: 'Emergency Help',
                      subtitle: 'Severity tiers & routing advice',
                      isDark: isDark,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpScreen())),
                    ),
                    _divider(isDark),
                    _buildNavTile(
                      icon: Icons.privacy_tip_outlined,
                      iconColor: BsasColors.warningOrange,
                      title: 'Privacy & Data',
                      subtitle: 'Zero cloud telemetry policy',
                      isDark: isDark,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyScreen())),
                    ),
                    _divider(isDark),
                    _buildNavTile(
                      icon: Icons.info_outline,
                      iconColor: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
                      title: 'About BSAS',
                      subtitle: 'Version v1.1.0 • Build details',
                      isDark: isDark,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen())),
                    ),
                  ],
                ),
                const SizedBox(height: BsasSpacing.xxxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(
        top: BsasSpacing.xl,
        bottom: BsasSpacing.sm,
        left: BsasSpacing.xl,
        right: BsasSpacing.xl,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 12,
            decoration: BoxDecoration(
              color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: BsasSpacing.sm),
          Text(
            title,
            style: BsasTypography.sectionHeading.copyWith(
              color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
              letterSpacing: 1.5,
              fontSize: 12,
            ),
          ),
        ],
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
        color: BsasColors.card(isDark),
        borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
        border: Border.all(color: BsasColors.border(isDark)),
        boxShadow: isDark
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))]
            : [BoxShadow(color: BsasColors.lightBorder, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: BsasColors.card(isDark),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: BsasColors.border(isDark),
      indent: BsasSpacing.lg,
      endIndent: BsasSpacing.lg,
    );
  }

  Widget _buildSwitchTile({
    required String key,
    required String title,
    required String subtitle,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      key: Key(key),
      contentPadding: const EdgeInsets.symmetric(horizontal: BsasSpacing.lg, vertical: BsasSpacing.xs),
      activeThumbColor: isDark ? BsasColors.darkBackground : BsasColors.lightBackground,
      activeTrackColor: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
      inactiveThumbColor: BsasColors.textMut(isDark),
      inactiveTrackColor: isDark ? BsasColors.darkBackground : BsasColors.lightBorder,
      title: Text(
        title,
        style: BsasTypography.title.copyWith(color: BsasColors.text(isDark), fontSize: 15),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: BsasSpacing.xs),
        child: Text(
          subtitle,
          style: BsasTypography.caption.copyWith(color: BsasColors.textSec(isDark), height: 1.2),
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: BsasSpacing.lg, vertical: BsasSpacing.xs),
      leading: Container(
        padding: const EdgeInsets.all(BsasSpacing.sm),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
          border: Border.all(color: iconColor.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: BsasTypography.title.copyWith(color: BsasColors.text(isDark), fontSize: 15)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: BsasSpacing.xs),
        child: Text(subtitle, style: BsasTypography.caption.copyWith(color: BsasColors.textSec(isDark))),
      ),
      trailing: Icon(Icons.chevron_right, color: BsasColors.textMut(isDark), size: 20),
      onTap: onTap,
    );
  }
}
