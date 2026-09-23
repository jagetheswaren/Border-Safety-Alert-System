import 'package:flutter/material.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_spacing.dart';
import '../core/theme/bsas_typography.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: const Key('screen-help'),
      backgroundColor: BsasColors.background(isDark),
      appBar: AppBar(
        backgroundColor: BsasColors.surface(isDark),
        title: Text(
          'Emergency Help & Protocols',
          style: BsasTypography.heading.copyWith(color: BsasColors.text(isDark)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: BsasSpacing.lg,
          vertical: BsasSpacing.xl,
        ),
        children: [
          _banner(isDark),
          const SizedBox(height: BsasSpacing.xl),

          _sectionHeader('SEVERITY TIERS & ACTIONS', isDark),
          _tierCard(
            isDark: isDark,
            title: 'SAFE (Level 0)',
            color: BsasColors.safeGreen,
            icon: Icons.verified_user_outlined,
            description: 'Distance to boundary > 1000 meters. Normal civilian transit. Background GNSS monitoring is active.',
          ),
          const SizedBox(height: BsasSpacing.sm),
          _tierCard(
            isDark: isDark,
            title: 'CAUTION (Level 1)',
            color: BsasColors.cautionYellow,
            icon: Icons.info_outline,
            description: 'Within buffer zone (500m - 1000m). Approaching demarcated boundary. Prepare to adjust route.',
          ),
          const SizedBox(height: BsasSpacing.sm),
          _tierCard(
            isDark: isDark,
            title: 'WARNING (Level 2)',
            color: BsasColors.warningOrange,
            icon: Icons.warning_amber_rounded,
            description: 'Critical proximity (<500m) or rapid forward movement toward border. Acoustic warning sound & vibration pulse emitted.',
          ),
          const SizedBox(height: BsasSpacing.sm),
          _tierCard(
            isDark: isDark,
            title: 'CRITICAL (Level 3)',
            color: BsasColors.criticalRed,
            icon: Icons.dangerous_outlined,
            description: 'Inside restricted perimeter or boundary crossing detected. Emergency siren & spoken TTS instruction. Reverse course immediately!',
          ),
          const SizedBox(height: BsasSpacing.xl),

          _sectionHeader('EMERGENCY ESCAPE ROUTING', isDark),
          Container(
            padding: const EdgeInsets.all(BsasSpacing.lg),
            decoration: BoxDecoration(
              color: BsasColors.card(isDark),
              borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
              border: Border.all(color: BsasColors.border(isDark)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.alt_route, color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue, size: 20),
                    const SizedBox(width: BsasSpacing.sm),
                    Text(
                      'If an accidental boundary crossing occurs:',
                      style: BsasTypography.title.copyWith(
                        color: BsasColors.text(isDark),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BsasSpacing.md),
                _stepRow(1, 'Tap the "Route" tab in the bottom navigation bar.', isDark),
                const SizedBox(height: BsasSpacing.sm),
                _stepRow(2, 'Press "Calculate Safe Route". The A* routing engine computes an obstacle-free exit corridor away from all restricted polygons.', isDark),
                const SizedBox(height: BsasSpacing.sm),
                _stepRow(3, 'Follow the initial heading bearing indicated on your compass/HUD and move directly toward safe civilian territory.', isDark),
              ],
            ),
          ),
          const SizedBox(height: BsasSpacing.xl),

          _sectionHeader('TROUBLESHOOTING & SENSOR ACCURACY', isDark),
          Container(
            padding: const EdgeInsets.all(BsasSpacing.lg),
            decoration: BoxDecoration(
              color: BsasColors.card(isDark),
              borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
              border: Border.all(color: BsasColors.border(isDark)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _troubleItem(
                  'No GPS Fix / Searching',
                  'Ensure you are under open sky. Thick canopy or urban canyons can delay initial satellite lock. Check that Location Services are set to High Accuracy.',
                  isDark,
                ),
                Divider(height: BsasSpacing.xl, color: BsasColors.border(isDark)),
                _troubleItem(
                  'Offline Maps Not Rendering',
                  'Go to the Live Map screen and ensure the sector pack is pre-cached. Tap "Prepare Offline Area" while connected to Wi-Fi before entering the field.',
                  isDark,
                ),
                Divider(height: BsasSpacing.xl, color: BsasColors.border(isDark)),
                _troubleItem(
                  'Spoken Voice (TTS) Silent',
                  'Check that Android media volume is unmuted and the Google Speech Engine is installed in your device language settings.',
                  isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: BsasSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _banner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(BsasSpacing.lg),
      decoration: BoxDecoration(
        color: BsasColors.criticalRed.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
        border: Border.all(color: BsasColors.criticalRed.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(BsasSpacing.sm),
            decoration: BoxDecoration(
              color: BsasColors.criticalRed.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
            ),
            child: const Icon(Icons.shield, color: BsasColors.criticalRed, size: 24),
          ),
          const SizedBox(width: BsasSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CIVILIAN LIFE SAFETY NOTICE',
                  style: BsasTypography.sectionHeading.copyWith(
                    color: BsasColors.criticalRed,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: BsasSpacing.xs),
                Text(
                  'BSAS is an assistive advisory instrument. In all situations, observe physical border markers, signboards, and directives from authorized personnel.',
                  style: BsasTypography.caption.copyWith(
                    color: BsasColors.textSec(isDark),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierCard({
    required bool isDark,
    required String title,
    required Color color,
    required IconData icon,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(BsasSpacing.md),
      decoration: BoxDecoration(
        color: BsasColors.card(isDark),
        borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(BsasSpacing.xs),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: BsasSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: BsasTypography.title.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: BsasTypography.caption.copyWith(
                    color: BsasColors.textSec(isDark),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepRow(int step, String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: (isDark ? BsasColors.primaryBlue : BsasColors.primaryBlueLight).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$step',
            style: BsasTypography.label.copyWith(
              color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: BsasSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: BsasTypography.body.copyWith(
              color: BsasColors.textSec(isDark),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _troubleItem(String title, String solution, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: BsasTypography.title.copyWith(
            color: BsasColors.text(isDark),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: BsasSpacing.xs),
        Text(
          solution,
          style: BsasTypography.caption.copyWith(
            color: BsasColors.textSec(isDark),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BsasSpacing.sm, left: BsasSpacing.xs),
      child: Text(
        title,
        style: BsasTypography.sectionHeading.copyWith(
          color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
        ),
      ),
    );
  }
}
