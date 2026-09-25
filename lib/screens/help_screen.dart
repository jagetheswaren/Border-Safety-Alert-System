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
                Icon(Icons.help_center_outlined, color: BsasColors.radarCyan, size: 20),
                const SizedBox(width: BsasSpacing.sm),
                Text(
                  'EMERGENCY PROTOCOLS',
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
            padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.lg, vertical: BsasSpacing.xl),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _banner(isDark),
                  const SizedBox(height: BsasSpacing.xxl),

                  _sectionHeader('SEVERITY TIERS & ACTIONS', isDark),
                  _tierCard(
                    isDark: isDark,
                    title: 'SAFE (Level 0)',
                    color: BsasColors.safeGreen,
                    icon: Icons.verified_user_outlined,
                    description: 'Distance to boundary > 1000 meters. Normal civilian transit. Background GNSS monitoring is active.',
                  ),
                  const SizedBox(height: BsasSpacing.md),
                  _tierCard(
                    isDark: isDark,
                    title: 'CAUTION (Level 1)',
                    color: BsasColors.cautionYellow,
                    icon: Icons.info_outline,
                    description: 'Within buffer zone (500m - 1000m). Approaching demarcated boundary. Prepare to adjust route.',
                  ),
                  const SizedBox(height: BsasSpacing.md),
                  _tierCard(
                    isDark: isDark,
                    title: 'WARNING (Level 2)',
                    color: BsasColors.warningOrange,
                    icon: Icons.warning_amber_rounded,
                    description: 'Critical proximity (<500m) or rapid forward movement toward border. Acoustic warning sound & vibration pulse emitted.',
                  ),
                  const SizedBox(height: BsasSpacing.md),
                  _tierCard(
                    isDark: isDark,
                    title: 'CRITICAL (Level 3)',
                    color: BsasColors.criticalRed,
                    icon: Icons.dangerous_outlined,
                    description: 'Inside restricted perimeter or boundary crossing detected. Emergency siren & spoken TTS instruction. Reverse course immediately!',
                  ),
                  const SizedBox(height: BsasSpacing.xxl),

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
                              'If boundary crossing occurs:',
                              style: BsasTypography.heading.copyWith(
                                color: BsasColors.text(isDark),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: BsasSpacing.lg),
                        _stepRow(1, 'Tap "Route" in the bottom navigation bar.', isDark),
                        const SizedBox(height: BsasSpacing.md),
                        _stepRow(2, 'Press "Calculate Safe Route". The A* routing engine computes an obstacle-free exit corridor.', isDark),
                        const SizedBox(height: BsasSpacing.md),
                        _stepRow(3, 'Follow the initial heading bearing on your compass/HUD and move toward civilian territory.', isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: BsasSpacing.xxl),

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
                          'Ensure you are under open sky. Thick canopy or urban canyons can delay initial satellite lock. Check Location Services are High Accuracy.',
                          isDark,
                        ),
                        Divider(height: BsasSpacing.xxl, color: BsasColors.border(isDark)),
                        _troubleItem(
                          'Offline Maps Not Rendering',
                          'Go to Live Map screen. Ensure sector pack is pre-cached. Tap "Prepare Offline Area" while connected to Wi-Fi before entering the field.',
                          isDark,
                        ),
                        Divider(height: BsasSpacing.xxl, color: BsasColors.border(isDark)),
                        _troubleItem(
                          'Spoken Voice (TTS) Silent',
                          'Check Android media volume is unmuted and the Google Speech Engine is installed in your device language settings.',
                          isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: BsasSpacing.xxxl),
                ],
              ),
            ),
          ),
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
                  style: BsasTypography.heading.copyWith(
                    color: BsasColors.criticalRed,
                    fontSize: 13,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: BsasSpacing.xs),
                Text(
                  'BSAS is an assistive advisory instrument. In all situations, observe physical border markers, signboards, and directives from authorized personnel.',
                  style: BsasTypography.body.copyWith(
                    color: BsasColors.text(isDark),
                    height: 1.4,
                    fontSize: 13,
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
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.0),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            : [
                BoxShadow(
                  color: BsasColors.lightBorder,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: BsasSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: BsasTypography.monospace.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: BsasTypography.body.copyWith(
                    color: BsasColors.textSec(isDark),
                    height: 1.4,
                    fontSize: 13,
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
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: (isDark ? BsasColors.radarCyan : BsasColors.primaryBlue).withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: (isDark ? BsasColors.radarCyan : BsasColors.primaryBlue).withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            '$step',
            style: BsasTypography.monospace.copyWith(
              color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: BsasSpacing.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              text,
              style: BsasTypography.body.copyWith(
                color: BsasColors.textSec(isDark),
                fontSize: 13,
                height: 1.4,
              ),
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
        Row(
          children: [
            Icon(Icons.precision_manufacturing_outlined, size: 16, color: BsasColors.textMut(isDark)),
            const SizedBox(width: BsasSpacing.xs),
            Text(
              title.toUpperCase(),
              style: BsasTypography.monospace.copyWith(
                color: BsasColors.text(isDark),
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: BsasSpacing.sm),
        Text(
          solution,
          style: BsasTypography.body.copyWith(
            color: BsasColors.textSec(isDark),
            height: 1.4,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BsasSpacing.md, left: BsasSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
          ),
          const SizedBox(width: BsasSpacing.sm),
          Text(
            title,
            style: BsasTypography.heading.copyWith(
              color: isDark ? BsasColors.text(isDark) : BsasColors.primaryBlue,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
