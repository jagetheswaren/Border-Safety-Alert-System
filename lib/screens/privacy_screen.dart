import 'package:flutter/material.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_typography.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key, this.onClearLocalData});

  final VoidCallback? onClearLocalData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('screen-privacy'),
      backgroundColor: BsasColors.darkBackground,
      appBar: AppBar(
        backgroundColor: BsasColors.darkSurface,
        title: const Text('Privacy & Data Governance', style: BsasTypography.headline),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: BsasColors.darkSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: BsasColors.safeGreen, width: 1.5),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, color: BsasColors.safeGreen, size: 36),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Zero Cloud Telemetry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 4),
                        Text(
                          'Your location telemetry is computed entirely within your device memory. BSAS never sells or transmits tracking data to ad brokers.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          _section(
            title: '1. GPS / GNSS DATA PROCESSING',
            content:
                'Precise location (latitude, longitude, speed, bearing) is read directly from your device hardware GNSS receiver. '
                'It is utilized exclusively for deterministic distance-to-boundary mathematics and on-device LSTM feature extraction. '
                'Coordinates are never broadcast externally during normal offline operation.',
          ),
          const SizedBox(height: 16),

          _section(
            title: '2. ON-DEVICE ML & LOCAL AI PRIVACY',
            content:
                'The LSTM trajectory model and Qwen3 Generative AI run locally on your phone using TFLite and llama.cpp runtimes. '
                'Prompts and conversations with the AI Assistant remain strictly on-device and are never uploaded to remote model providers.',
          ),
          const SizedBox(height: 16),

          _section(
            title: '3. LOCAL SQLITE RETENTION & SECURITY',
            content:
                'Safety alerts and boundary crossing logs are persisted in your device app-private SQLite sandbox. '
                'No unauthorized third-party application can read these logs without root filesystem privileges.',
          ),
          const SizedBox(height: 16),

          _section(
            title: '4. OPTIONAL SERVER SYNCHRONIZATION',
            content:
                'If you connect BSAS to a self-hosted FastAPI instance, synchronization only uploads events when authenticated via HMAC/JWT tokens. '
                'All transmission requires TLS/HTTPS encryption.',
          ),
          const SizedBox(height: 24),

          _section(
            title: '5. DATA DELETION & RETENTION RIGHTS',
            content:
                'You retain total control over your local data. You can purge all cached map tiles, alert history records, and SQLite logs at any time.',
          ),
          const SizedBox(height: 16),

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: BsasColors.criticalRed),
            ),
            icon: const Icon(Icons.delete_forever, color: BsasColors.criticalRed),
            label: const Text('PURGE ALL LOCAL CACHE & HISTORY', style: TextStyle(color: BsasColors.criticalRed, fontWeight: FontWeight.bold)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: BsasColors.darkSurface,
                  title: const Text('Purge Local Data?', style: TextStyle(color: Colors.white)),
                  content: const Text(
                    'This action permanently deletes all cached offline map tiles and locally stored alert history logs from this device.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: BsasColors.criticalRed),
                      child: const Text('Purge Now', style: TextStyle(color: Colors.white)),
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
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _section({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: BsasTypography.caption.copyWith(
            color: BsasColors.radarCyan,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: BsasTypography.body.copyWith(
            color: Colors.white70,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
