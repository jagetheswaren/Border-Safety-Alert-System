import 'package:flutter/material.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_spacing.dart';
import '../core/theme/bsas_typography.dart';
import '../models/alert_severity.dart';
import '../services/alert_service.dart';

/// Redesigned Alert Details screen providing authoritative telemetry audit,
/// hardware delivery verification, and immediate evacuation guidance.
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final message = event.message;
    final result = event.result;
    final isCritical = message.severity == AlertSeverity.critical;
    final time = event.timestamp ?? DateTime.now();
    final timeStr =
        '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
    final delivery = event.deliveryStatus;
    final severityColor = isCritical ? BsasColors.criticalRed : BsasColors.warningOrange;

    return Scaffold(
      key: const Key('screen-alert-details'),
      appBar: AppBar(
        title: const Text('Incident Report', style: BsasTypography.heading),
      ),
      body: ListView(
        padding: const EdgeInsets.all(BsasSpacing.screenMargin),
        children: [
          // Header Card with Severity Banner
          Container(
            padding: BsasSpacing.cardInsets,
            decoration: BoxDecoration(
              color: isDark ? BsasColors.darkCard : BsasColors.lightCard,
              borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
              border: Border.all(color: severityColor, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: severityColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        message.severity.label.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Text(timeStr, style: BsasTypography.monoDiagnostics.copyWith(fontSize: 11)),
                  ],
                ),
                const SizedBox(height: BsasSpacing.md),
                Text(
                  message.title,
                  style: BsasTypography.title.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: BsasSpacing.xs),
                Text(
                  message.message,
                  style: BsasTypography.body.copyWith(
                    color: isDark ? BsasColors.textLightSecondary : BsasColors.textDarkSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: BsasSpacing.lg),

          // Geospatial Context Section
          Text(
            'GEOSPATIAL INCIDENT TELEMETRY',
            style: BsasTypography.sectionHeading.copyWith(
              color: BsasColors.primaryBlue,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: BsasSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: isDark ? BsasColors.darkCard : BsasColors.lightCard,
              borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
              border: Border.all(color: isDark ? BsasColors.darkBorder : BsasColors.lightBorder),
            ),
            child: Column(
              children: [
                _tile(
                  icon: Icons.shield_outlined,
                  title: 'Geofence Assessment',
                  trailing: result.state.name.toUpperCase(),
                  trailingColor: severityColor,
                ),
                const Divider(height: 1),
                _tile(
                  icon: Icons.near_me_outlined,
                  title: 'Sector / Perimeter',
                  trailing: result.nearestBoundary?.name ?? 'Perimeter Buffer',
                ),
                const Divider(height: 1),
                _tile(
                  icon: Icons.straighten,
                  title: 'Distance to Demarcation',
                  trailing: result.distanceToBoundaryMeters != null
                      ? '${result.distanceToBoundaryMeters!.toStringAsFixed(1)} m'
                      : 'Inside Zone',
                ),
                if (result.directionToBoundaryDegrees != null) ...[
                  const Divider(height: 1),
                  _tile(
                    icon: Icons.navigation_outlined,
                    title: 'Perimeter Bearing',
                    trailing: '${result.directionToBoundaryDegrees!.toStringAsFixed(0)}°',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: BsasSpacing.lg),

          // Hardware Dispatch Audit Section
          Text(
            'HARDWARE DISPATCH VERIFICATION',
            style: BsasTypography.sectionHeading.copyWith(
              color: BsasColors.primaryBlue,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: BsasSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: isDark ? BsasColors.darkCard : BsasColors.lightCard,
              borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
              border: Border.all(color: isDark ? BsasColors.darkBorder : BsasColors.lightBorder),
            ),
            child: Column(
              children: [
                _dispatchTile('Acoustic Siren (Audio)', delivery.soundPlayed),
                const Divider(height: 1),
                _dispatchTile('Text-to-Speech Voice (TTS)', delivery.voiceSpoken),
                const Divider(height: 1),
                _dispatchTile('Haptic Tactile Pulse', delivery.vibrated),
                const Divider(height: 1),
                _dispatchTile('Android System Notification', delivery.notificationPosted),
              ],
            ),
          ),
          const SizedBox(height: BsasSpacing.xl),

          // Emergency Actions
          Row(
            children: [
              if (onViewOnMap != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onViewOnMap!();
                    },
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text('VIEW ON MAP'),
                  ),
                ),
              if (onViewOnMap != null && onSafeRoute != null)
                const SizedBox(width: BsasSpacing.sm),
              if (onSafeRoute != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onSafeRoute!();
                    },
                    icon: const Icon(Icons.alt_route_rounded, size: 18),
                    label: const Text('SAFE ESCAPE ROUTE'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: BsasSpacing.md),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String trailing,
    Color? trailingColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.md, vertical: BsasSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: BsasColors.primaryBlue),
          const SizedBox(width: BsasSpacing.sm),
          Expanded(child: Text(title, style: BsasTypography.bodyMuted)),
          Text(
            trailing,
            style: BsasTypography.monoDiagnostics.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: trailingColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dispatchTile(String channel, bool dispatched) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.md, vertical: BsasSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(channel, style: BsasTypography.body.copyWith(fontSize: 13)),
          Row(
            children: [
              Icon(
                dispatched ? Icons.check_circle_rounded : Icons.cancel_outlined,
                size: 16,
                color: dispatched ? BsasColors.safeGreen : BsasColors.offlineSteel,
              ),
              const SizedBox(width: 4),
              Text(
                dispatched ? 'DISPATCHED' : 'SUPPRESSED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: dispatched ? BsasColors.safeGreen : BsasColors.offlineSteel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
