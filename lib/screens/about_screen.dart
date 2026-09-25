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
                Icon(Icons.info_outline, color: BsasColors.radarCyan, size: 20),
                const SizedBox(width: BsasSpacing.sm),
                Text(
                  'ABOUT BSAS',
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
                  Center(
                    child: Column(
                      children: [
                        const BsasLogo(size: 80, animated: false),
                        const SizedBox(height: BsasSpacing.lg),
                        Text(
                          'BORDER SAFETY ALERT SYSTEM',
                          style: BsasTypography.heading.copyWith(
                            color: BsasColors.text(isDark),
                            fontSize: 15,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: BsasSpacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: BsasSpacing.sm,
                            vertical: BsasSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: BsasColors.safeGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: BsasColors.safeGreen.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'RELEASE v1.1.0 • PRODUCTION BUILD',
                            style: BsasTypography.monospace.copyWith(
                              color: BsasColors.safeGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: BsasSpacing.sm),
                        Text(
                          'Offline-First Civilian Border Safety\n& Perimeter Alert System',
                          style: BsasTypography.body.copyWith(
                            color: BsasColors.textSec(isDark),
                            height: 1.4,
                            fontSize: 13,
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
                        title: 'MOBILE APPLICATION CORE',
                        subtitle: 'Flutter 3.24 / Dart / Android ARM64 native target',
                      ),
                      Divider(height: 1, color: BsasColors.border(isDark)),
                      _tile(
                        isDark: isDark,
                        icon: Icons.memory_outlined,
                        iconColor: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
                        title: 'ON-DEVICE ML ENGINE',
                        subtitle: 'LSTM TFLite (1x5x6) + Random Forest + RobustScaler',
                      ),
                      Divider(height: 1, color: BsasColors.border(isDark)),
                      _tile(
                        isDark: isDark,
                        icon: Icons.psychology_outlined,
                        iconColor: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
                        title: 'LOCAL GENERATIVE AI',
                        subtitle: 'Qwen2.5-0.5B-Q4_0 GGUF (llama.cpp) / Local GPU',
                      ),
                      Divider(height: 1, color: BsasColors.border(isDark)),
                      _tile(
                        isDark: isDark,
                        icon: Icons.map_outlined,
                        iconColor: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
                        title: 'MAPPING SUBSYSTEM',
                        subtitle: 'Offline Raster Storage + MapLibre GL JS engine',
                      ),
                      Divider(height: 1, color: BsasColors.border(isDark)),
                      _tile(
                        isDark: isDark,
                        icon: Icons.storage_outlined,
                        iconColor: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
                        title: 'LOCAL PERSISTENCE',
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
                        title: 'GITHUB REPOSITORY',
                        subtitle: 'jagetheswaren/Border-Safety-Alert-System',
                      ),
                      Divider(height: 1, color: BsasColors.border(isDark)),
                      _tile(
                        isDark: isDark,
                        icon: Icons.balance_outlined,
                        iconColor: BsasColors.safeGreen,
                        title: 'SOFTWARE LICENSING',
                        subtitle: 'MIT License (BSAS Core) • Apache-2.0 (Qwen AI)',
                      ),
                    ],
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

  Widget _card({required bool isDark, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: BsasColors.card(isDark),
        borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
        border: Border.all(color: BsasColors.border(isDark), width: 1.0),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
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
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: BsasSpacing.md, vertical: BsasSpacing.xs),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: iconColor.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: BsasTypography.monospace.copyWith(
            color: BsasColors.text(isDark),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: BsasTypography.body.copyWith(
              color: BsasColors.textSec(isDark),
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}
