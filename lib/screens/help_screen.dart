import 'package:flutter/material.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_typography.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('screen-help'),
      backgroundColor: BsasColors.darkBackground,
      appBar: AppBar(
        backgroundColor: BsasColors.darkSurface,
        title: const Text('Emergency Help & Protocols', style: BsasTypography.headline),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _banner(),
          const SizedBox(height: 20),

          _header('SEVERITY TIERS & ACTIONS'),
          _tierCard(
            title: 'SAFE (Level 0)',
            color: BsasColors.safeGreen,
            description: 'Distance to boundary > 1000 meters. Normal civilian transit. Background GNSS monitoring active.',
          ),
          const SizedBox(height: 10),
          _tierCard(
            title: 'CAUTION (Level 1)',
            color: BsasColors.warningOrange,
            description: 'Within buffer zone (500m - 1000m). Approaching demarcated boundary. Prepare to adjust route.',
          ),
          const SizedBox(height: 10),
          _tierCard(
            title: 'WARNING (Level 2)',
            color: BsasColors.warningOrange,
            description: 'Critical proximity (<500m) or rapid forward movement toward border. Acoustic warning sound & vibration pulse emitted.',
          ),
          const SizedBox(height: 10),
          _tierCard(
            title: 'CRITICAL (Level 3)',
            color: BsasColors.criticalRed,
            description: 'Inside restricted perimeter or boundary crossing detected. Emergency siren & spoken TTS instruction. Reverse course immediately!',
          ),
          const SizedBox(height: 20),

          _header('EMERGENCY ESCAPE ROUTING'),
          Card(
            color: BsasColors.darkSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: BsasColors.darkBorder),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'If an accidental boundary crossing occurs:\n'
                '1. Tap the "Route" tab in the bottom navigation bar.\n'
                '2. Press "Calculate Safe Route". The A* routing engine will compute an obstacle-free exit corridor away from all restricted polygons.\n'
                '3. Follow the initial heading bearing indicated on your compass/HUD.',
                style: TextStyle(color: Colors.white70, height: 1.5, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),

          _header('TROUBLESHOOTING & SENSOR ACCURACY'),
          Card(
            color: BsasColors.darkSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: BsasColors.darkBorder),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• No GPS Fix / Searching:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Ensure you are under open sky. Thick canopy or urban canyons can delay initial satellite lock.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  SizedBox(height: 12),
                  Text('• Offline Maps Not Rendering:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Go to the Live Map screen and ensure the sector pack is pre-cached. Tap "Prepare Offline Area" while connected to Wi-Fi before entering the field.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  SizedBox(height: 12),
                  Text('• Spoken Voice (TTS) Silent:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Check that Android media volume is unmuted and the Google Speech Engine is installed in your device language settings.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _banner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BsasColors.criticalRed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BsasColors.criticalRed, width: 1.5),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield, color: BsasColors.criticalRed, size: 36),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CIVILIAN LIFE SAFETY NOTICE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                SizedBox(height: 4),
                Text(
                  'BSAS is an assistive advisory instrument. In all situations, observe physical border markers, government signboards, and directives from authorized personnel.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tierCard({required String title, required Color color, required String description}) {
    return Card(
      color: BsasColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withValues(alpha: 0.7), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _header(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: BsasTypography.caption.copyWith(
          color: BsasColors.radarCyan,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
