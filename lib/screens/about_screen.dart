import 'package:flutter/material.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_spacing.dart';
import '../core/theme/bsas_typography.dart';
import '../core/widgets/bsas_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: const Key('screen-about'),
      backgroundColor: BsasColors.background(isDark),
      appBar: AppBar(
        backgroundColor: BsasColors.surface(isDark),
        title: Text(
          'About BSAS',
          style: BsasTypography.heading.copyWith(color: BsasColors.text(isDark)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: BsasSpacing.lg,
          vertical: BsasSpacing.xl,
        ),
        children: [
          Center(
            child: Column(
              children: [
                const BsasLogo(size: 80, animated: false),
                const SizedBox(height: BsasSpacing.lg),
                Text(
                  'BORDER SAFETY ALERT SYSTEM',
                  style: BsasTypography.sectionHeading.copyWith(
                    color: BsasColors.text(isDark),
                    fontSize: 15,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: BsasSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: BsasSpacing.sm,
                    vertical: BsasSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: BsasColors.safeGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: BsasColors.safeGreen.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'RELEASE v1.1.0 • PRODUCTION BUILD',
                    style: BsasTypography.monospace.copyWith(
                      color: BsasColors.safeGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: BsasSpacing.sm),
                Text(
                  'Offline-First Civilian Border Safety & Perimeter Alert System',
                  style: BsasTypography.caption.copyWith(
                    color: BsasColors.textSec(isDark),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: BsasSpacing.xxl),

          _sectionHeader('SYSTEM ARCHITECTURE', isDark),
          _card(
            isDark: isDark,
            children: [
              _tile(
                isDark: isDark,
                icon: Icons.phone_android_outlined,
                iconColor: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
                title: 'Mobile Application Core',
                subtitle: 'Flutter 3.12 / Dart / Android ARM64 native target',
              ),
              Divider(height: 1, color: BsasColors.border(isDark)),
              _tile(
                isDark: isDark,
                icon: Icons.memory_outlined,
                iconColor: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
                title: 'On-Device ML Engine',
                subtitle: 'LSTM TFLite (1x5x6) + Random Forest + RobustScaler',
              ),
              Divider(height: 1, color: BsasColors.border(isDark)),
              _tile(
                isDark: isDark,
                icon: Icons.psychology_outlined,
                iconColor: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
                title: 'Local Generative AI',
                subtitle: 'Qwen3-0.6B-Q4_0 GGUF (llama.cpp) / Ollama GPU Bridge',
              ),
              Divider(height: 1, color: BsasColors.border(isDark)),
              _tile(
                isDark: isDark,
                icon: Icons.map_outlined,
                iconColor: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
                title: 'Mapping Subsystem',
                subtitle: 'Offline Raster Storage + Esri World Imagery Satellite',
              ),
              Divider(height: 1, color: BsasColors.border(isDark)),
              _tile(
                isDark: isDark,
                icon: Icons.storage_outlined,
                iconColor: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
                title: 'Local Persistence',
                subtitle: 'SQLite native database + encrypted JSON fallback',
              ),
            ],
          ),
          const SizedBox(height: BsasSpacing.xl),

          _sectionHeader('PROJECT & REPOSITORY', isDark),
          _card(
            isDark: isDark,
            children: [
              _tile(
                isDark: isDark,
                icon: Icons.code,
                iconColor: BsasColors.safeGreen,
                title: 'GitHub Repository',
                subtitle: 'jagetheswaren/Border-Safety-Alert-System',
              ),
              Divider(height: 1, color: BsasColors.border(isDark)),
              _tile(
                isDark: isDark,
                icon: Icons.balance_outlined,
                iconColor: BsasColors.safeGreen,
                title: 'Software Licensing',
                subtitle: 'MIT License (BSAS Core) • Apache-2.0 (Qwen AI)',
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
      padding: const EdgeInsets.only(bottom: BsasSpacing.sm, left: BsasSpacing.xs),
      child: Text(
        title,
        style: BsasTypography.sectionHeading.copyWith(
          color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
        ),
      ),
    );
  }

  Widget _card({required bool isDark, required List<Widget> children}) {
    return Container(
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

  Widget _tile({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(BsasSpacing.sm),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: BsasTypography.title.copyWith(
          color: BsasColors.text(isDark),
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: BsasTypography.caption.copyWith(
          color: BsasColors.textSec(isDark),
        ),
      ),
    );
  }
}
