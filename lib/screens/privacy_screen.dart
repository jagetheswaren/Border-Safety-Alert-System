import 'package:flutter/material.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_spacing.dart';
import '../core/theme/bsas_typography.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key, this.onClearLocalData});

  final VoidCallback? onClearLocalData;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: const Key('screen-privacy'),
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
                Icon(Icons.shield_outlined, color: BsasColors.radarCyan, size: 20),
                const SizedBox(width: BsasSpacing.sm),
                Text(
                  'PRIVACY & DATA GOVERNANCE',
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
                  // Zero Cloud Telemetry Hero Banner
                  Container(
                    padding: const EdgeInsets.all(BsasSpacing.lg),
                    decoration: BoxDecoration(
                      color: BsasColors.safeGreen.withValues(alpha: isDark ? 0.08 : 0.05),
                      borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
                      border: Border.all(
                        color: BsasColors.safeGreen.withValues(alpha: 0.3),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(BsasSpacing.sm),
                          decoration: BoxDecoration(
                            color: BsasColors.safeGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
                            border: Border.all(color: BsasColors.safeGreen.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            color: BsasColors.safeGreen,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: BsasSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ZERO CLOUD TELEMETRY',
                                style: BsasTypography.heading.copyWith(
                                  color: BsasColors.safeGreen,
                                  fontSize: 13,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: BsasSpacing.xs),
                              Text(
                                'Your location telemetry is computed entirely within device memory. BSAS never transmits your coordinates to third parties or tracking brokers.',
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
                  ),
                  const SizedBox(height: BsasSpacing.xl),

                  _policyCard(
                    isDark: isDark,
                    number: '01',
                    title: 'GPS / GNSS DATA PROCESSING',
                    content:
                        'Precise location (latitude, longitude, speed, bearing) is read directly from your device hardware GNSS receiver. '
                        'It is utilized exclusively for deterministic distance-to-boundary mathematics and on-device LSTM feature extraction. '
                        'Coordinates are never broadcast externally during normal offline operation.',
                  ),
                  const SizedBox(height: BsasSpacing.md),

                  _policyCard(
                    isDark: isDark,
                    number: '02',
                    title: 'ON-DEVICE ML & LOCAL AI PRIVACY',
                    content:
                        'The LSTM trajectory model and Qwen2.5 Generative AI run locally on your phone using TFLite and llama.cpp runtimes. '
                        'Prompts and conversations with the AI Assistant remain strictly on-device and are never uploaded to remote model providers.',
                  ),
                  const SizedBox(height: BsasSpacing.md),

                  _policyCard(
                    isDark: isDark,
                    number: '03',
                    title: 'LOCAL SQLITE RETENTION & SECURITY',
                    content:
                        'Safety alerts and boundary crossing logs are persisted in your device app-private SQLite sandbox. '
                        'No unauthorized third-party application can read these logs without root filesystem privileges.',
                  ),
                  const SizedBox(height: BsasSpacing.md),

                  _policyCard(
                    isDark: isDark,
                    number: '04',
                    title: 'OPTIONAL SERVER SYNCHRONIZATION',
                    content:
                        'If you connect BSAS to a self-hosted FastAPI instance, synchronization only uploads events when authenticated via HMAC/JWT tokens. '
                        'All transmission requires TLS/HTTPS encryption.',
                  ),
                  const SizedBox(height: BsasSpacing.md),

                  _policyCard(
                    isDark: isDark,
                    number: '05',
                    title: 'DATA DELETION & RETENTION RIGHTS',
                    content:
                        'You retain total control over your local data. You can purge all cached map tiles, alert history records, and SQLite logs at any time.',
                  ),
                  const SizedBox(height: BsasSpacing.xxl),

                  // Purge Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: BsasSpacing.md),
                      side: BorderSide(color: BsasColors.criticalRed.withValues(alpha: 0.5)),
                      backgroundColor: BsasColors.criticalRed.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
                      ),
                    ),
                    icon: const Icon(Icons.delete_sweep, color: BsasColors.criticalRed, size: 20),
                    label: Text(
                      'PURGE ALL LOCAL CACHE & HISTORY',
                      style: BsasTypography.monospace.copyWith(
                        color: BsasColors.criticalRed,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        fontSize: 12,
                      ),
                    ),
                    onPressed: () => _confirmPurge(context, isDark),
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

  Widget _policyCard({
    required bool isDark,
    required String number,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(BsasSpacing.lg),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  number,
                  style: BsasTypography.monospace.copyWith(
                    color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: BsasSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: BsasTypography.heading.copyWith(
                    color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: BsasSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(left: 32.0),
            child: Text(
              content,
              style: BsasTypography.body.copyWith(
                color: BsasColors.textSec(isDark),
                height: 1.5,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmPurge(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BsasColors.card(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
          side: BorderSide(color: BsasColors.border(isDark)),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: BsasColors.warningOrange, size: 24),
            const SizedBox(width: BsasSpacing.sm),
            Text(
              'PURGE LOCAL DATA?',
              style: BsasTypography.heading.copyWith(
                color: BsasColors.text(isDark),
                fontSize: 14,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        content: Text(
          'This action permanently deletes all cached offline map tiles and locally stored alert history logs from this device. This action cannot be undone.',
          style: BsasTypography.body.copyWith(
            color: BsasColors.textSec(isDark),
            height: 1.4,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              'CANCEL',
              style: BsasTypography.monospace.copyWith(
                color: BsasColors.textSec(isDark),
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: BsasColors.criticalRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
              ),
            ),
            child: Text(
              'PURGE NOW',
              style: BsasTypography.monospace.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onClearLocalData?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: BsasColors.surface(isDark),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: BsasColors.border(isDark)),
                  ),
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: BsasColors.safeGreen, size: 20),
                      const SizedBox(width: BsasSpacing.sm),
                      Expanded(
                        child: Text(
                          'Local data and caches purged successfully.',
                          style: BsasTypography.body.copyWith(color: BsasColors.text(isDark)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
