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
      appBar: AppBar(
        backgroundColor: BsasColors.surface(isDark),
        title: Text(
          'Privacy & Data Governance',
          style: BsasTypography.heading.copyWith(color: BsasColors.text(isDark)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: BsasSpacing.lg,
          vertical: BsasSpacing.xl,
        ),
        children: [
          // Zero Cloud Telemetry Hero Banner
          Container(
            padding: const EdgeInsets.all(BsasSpacing.lg),
            decoration: BoxDecoration(
              color: BsasColors.safeGreen.withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
              border: Border.all(
                color: BsasColors.safeGreen.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(BsasSpacing.sm),
                  decoration: BoxDecoration(
                    color: BsasColors.safeGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
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
                        'Zero Cloud Telemetry Policy',
                        style: BsasTypography.title.copyWith(
                          color: BsasColors.text(isDark),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: BsasSpacing.xs),
                      Text(
                        'Your location telemetry is computed entirely within device memory. BSAS never transmits your coordinates to third parties or tracking brokers.',
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
          ),
          const SizedBox(height: BsasSpacing.xl),

          _policyCard(
            isDark: isDark,
            number: '1',
            title: 'GPS / GNSS DATA PROCESSING',
            content:
                'Precise location (latitude, longitude, speed, bearing) is read directly from your device hardware GNSS receiver. '
                'It is utilized exclusively for deterministic distance-to-boundary mathematics and on-device LSTM feature extraction. '
                'Coordinates are never broadcast externally during normal offline operation.',
          ),
          const SizedBox(height: BsasSpacing.md),

          _policyCard(
            isDark: isDark,
            number: '2',
            title: 'ON-DEVICE ML & LOCAL AI PRIVACY',
            content:
                'The LSTM trajectory model and Qwen3 Generative AI run locally on your phone using TFLite and llama.cpp runtimes. '
                'Prompts and conversations with the AI Assistant remain strictly on-device and are never uploaded to remote model providers.',
          ),
          const SizedBox(height: BsasSpacing.md),

          _policyCard(
            isDark: isDark,
            number: '3',
            title: 'LOCAL SQLITE RETENTION & SECURITY',
            content:
                'Safety alerts and boundary crossing logs are persisted in your device app-private SQLite sandbox. '
                'No unauthorized third-party application can read these logs without root filesystem privileges.',
          ),
          const SizedBox(height: BsasSpacing.md),

          _policyCard(
            isDark: isDark,
            number: '4',
            title: 'OPTIONAL SERVER SYNCHRONIZATION',
            content:
                'If you connect BSAS to a self-hosted FastAPI instance, synchronization only uploads events when authenticated via HMAC/JWT tokens. '
                'All transmission requires TLS/HTTPS encryption.',
          ),
          const SizedBox(height: BsasSpacing.md),

          _policyCard(
            isDark: isDark,
            number: '5',
            title: 'DATA DELETION & RETENTION RIGHTS',
            content:
                'You retain total control over your local data. You can purge all cached map tiles, alert history records, and SQLite logs at any time.',
          ),
          const SizedBox(height: BsasSpacing.xl),

          // Purge Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: BsasSpacing.md),
              side: const BorderSide(color: BsasColors.criticalRed),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
              ),
            ),
            icon: const Icon(Icons.delete_forever, color: BsasColors.criticalRed, size: 20),
            label: Text(
              'PURGE ALL LOCAL CACHE & HISTORY',
              style: BsasTypography.label.copyWith(
                color: BsasColors.criticalRed,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            onPressed: () => _confirmPurge(context, isDark),
          ),
          const SizedBox(height: BsasSpacing.xxxl),
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
        border: Border.all(color: BsasColors.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (isDark ? BsasColors.primaryBlue : BsasColors.primaryBlueLight).withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  number,
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
                  title,
                  style: BsasTypography.sectionHeading.copyWith(
                    color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: BsasSpacing.sm),
          Text(
            content,
            style: BsasTypography.body.copyWith(
              color: BsasColors.textSec(isDark),
              height: 1.5,
              fontSize: 13,
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
        title: Text(
          'Purge Local Data?',
          style: BsasTypography.title.copyWith(
            color: BsasColors.text(isDark),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This action permanently deletes all cached offline map tiles and locally stored alert history logs from this device.',
          style: BsasTypography.body.copyWith(
            color: BsasColors.textSec(isDark),
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              'Cancel',
              style: TextStyle(color: BsasColors.textSec(isDark)),
            ),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: BsasColors.criticalRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
              ),
            ),
            child: const Text('Purge Now'),
            onPressed: () {
              Navigator.pop(ctx);
              onClearLocalData?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Local data and caches purged successfully.')),
              );
            },
          ),
        ],
      ),
    );
  }
}
