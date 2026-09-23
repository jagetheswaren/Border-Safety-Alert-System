import 'package:flutter/material.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_typography.dart';
import '../models/alert_severity.dart';
import '../services/alert_service.dart';

class AlertDetailsScreen extends StatelessWidget {
  const AlertDetailsScreen({
    super.key,
    required this.event,
    this.onViewOnMap,
    this.onSafeRoute,
  });

  final AlertEvent event;
  final VoidCallback? onViewOnMap;
  final VoidCallback? onSafeRoute;

  @override
  Widget build(BuildContext context) {
    final message = event.message;
    final result = event.result;
    final isCritical = message.severity == AlertSeverity.critical;
    final time = event.timestamp ?? DateTime.now();
    final timeStr =
        '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
    final delivery = event.deliveryStatus;

    return Scaffold(
      key: const Key('screen-alert-details'),
      backgroundColor: BsasColors.darkBackground,
      appBar: AppBar(
        backgroundColor: BsasColors.darkSurface,
        title: const Text('Alert Incident Report', style: BsasTypography.headline),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card with Severity Banner
          Card(
            color: BsasColors.darkSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isCritical ? BsasColors.criticalRed : BsasColors.warningOrange,
                width: 2.0,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isCritical ? BsasColors.criticalRed : BsasColors.warningOrange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          message.severity.label.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(timeStr, style: BsasTypography.monoDiagnostics),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    message.title,
                    style: BsasTypography.headline.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message.message,
                    style: BsasTypography.body.copyWith(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Geospatial Context Section
          _sectionHeader('GEOSPATIAL INCIDENT TELEMETRY'),
          Card(
            color: BsasColors.darkSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: BsasColors.darkBorder),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.shield_outlined, color: BsasColors.radarCyan),
                  title: const Text('Geofence State', style: TextStyle(color: Colors.white)),
                  trailing: Text(
                    result.state.name.toUpperCase(),
                    style: BsasTypography.monoDiagnostics.copyWith(
                      color: isCritical ? BsasColors.criticalRed : BsasColors.warningOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1, color: BsasColors.darkBorder),
                ListTile(
                  leading: const Icon(Icons.near_me_outlined, color: BsasColors.radarCyan),
                  title: const Text('Sector / Nearest Boundary', style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                    result.nearestBoundary?.name ?? 'Perimeter Zone',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                const Divider(height: 1, color: BsasColors.darkBorder),
                ListTile(
                  leading: const Icon(Icons.straighten, color: BsasColors.radarCyan),
                  title: const Text('Distance to Boundary', style: TextStyle(color: Colors.white)),
                  trailing: Text(
                    result.distanceToBoundaryMeters != null
                        ? '${result.distanceToBoundaryMeters!.toStringAsFixed(1)} m'
                        : 'Inside Sector',
                    style: BsasTypography.monoDiagnostics.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Hardware Delivery Audit
          _sectionHeader('PHYSICAL HARDWARE DISPATCH STATUS'),
          Card(
            color: BsasColors.darkSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: BsasColors.darkBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _dispatchRow(
                    icon: Icons.volume_up,
                    label: 'Siren Audio Output',
                    status: delivery.soundPlayed,
                  ),
                  const Divider(height: 1, color: BsasColors.darkBorder),
                  _dispatchRow(
                    icon: Icons.vibration,
                    label: 'Haptic Vibration Engine',
                    status: delivery.vibrationPlayed,
                  ),
                  const Divider(height: 1, color: BsasColors.darkBorder),
                  _dispatchRow(
                    icon: Icons.record_voice_over,
                    label: 'Android Text-to-Speech (TTS)',
                    status: delivery.ttsPlayed,
                  ),
                  const Divider(height: 1, color: BsasColors.darkBorder),
                  _dispatchRow(
                    icon: Icons.notifications_active,
                    label: 'System Notification Posted',
                    status: delivery.notificationPosted,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Immediate Safety Recommendations
          _sectionHeader('IMMEDIATE SAFETY ACTIONS'),
          Card(
            color: BsasColors.darkSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: BsasColors.darkBorder),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCritical ? Icons.emergency : Icons.warning_amber_rounded,
                        color: isCritical ? BsasColors.criticalRed : BsasColors.warningOrange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isCritical ? 'CRITICAL EVACUATION PROTOCOL' : 'CAUTIONARY RETREAT ADVICE',
                        style: BsasTypography.title.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isCritical
                        ? '1. Reverse direction immediately away from the restricted boundary.\n'
                          '2. Do not proceed further into the marked sector.\n'
                          '3. Tap "Calculate Safe Route" below for a designated safe exit corridor.\n'
                          '4. Verify signal availability and keep communication devices ready.'
                        : '1. Reduce forward velocity and monitor safety status closely.\n'
                          '2. You are approaching a demarcated safety zone.\n'
                          '3. Check the Live Map for exact proximity distances.',
                    style: BsasTypography.caption.copyWith(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: BsasColors.radarCyan),
                  ),
                  icon: const Icon(Icons.map, color: BsasColors.radarCyan),
                  label: const Text('View on Map', style: TextStyle(color: BsasColors.radarCyan)),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onViewOnMap?.call();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BsasColors.safeGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.navigation, color: Colors.black),
                  label: const Text('Safe Route', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onSafeRoute?.call();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _dispatchRow({
    required IconData icon,
    required String label,
    required bool status,
  }) {
    return ListTile(
      leading: Icon(icon, color: status ? BsasColors.safeGreen : BsasColors.textMuted, size: 22),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: status ? BsasColors.safeGreen.withValues(alpha: 0.2) : Colors.white10,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: status ? BsasColors.safeGreen : Colors.white24,
            width: 1,
          ),
        ),
        child: Text(
          status ? 'DISPATCHED' : 'SUPPRESSED / MUTED',
          style: TextStyle(
            color: status ? BsasColors.safeGreen : BsasColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
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
