import 'package:flutter/material.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_spacing.dart';
import '../core/theme/bsas_typography.dart';
import '../core/widgets/status_badge.dart';
import '../data/demo_data.dart';
import '../models/gps_snapshot.dart';
import '../models/geofence_result.dart';
import '../models/geofence_state.dart';
import '../widgets/gps_status_chip.dart';
import 'map_screen.dart';
import 'route_screen.dart';
import '../services/boundary_summary.dart';

/// Redesigned comprehensive Safety Status screen.
///
/// Presents authoritative deterministic & ML fused safety diagnostics,
/// real distance to border demarcations, trajectory vectors, and clear action guidance.
class SafetyScreen extends StatelessWidget {
  const SafetyScreen({
    super.key,
    this.snapshot = DemoSafetySnapshot.placeholder,
    this.gps,
    this.geoFence = const GeoFenceResult(state: GeoFenceState.unknown),
  });

  final DemoSafetySnapshot snapshot;
  final GpsSnapshot? gps;
  final GeoFenceResult geoFence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final live = gps ?? GpsSnapshot.initial();
    final state = geoFence.state;
    final stateStr = state.name.toUpperCase();

    final isCritical = state == GeoFenceState.critical || state == GeoFenceState.insideRestrictedArea;
    final isWarning = state == GeoFenceState.warning || state == GeoFenceState.caution;

    final stateColor = BsasColors.forSafetyState(stateStr);
    final stateBg = BsasColors.backgroundForState(stateStr, isDark: isDark);
    final stateIcon = BsasColors.iconForState(stateStr);
    final boundary = geoFence.nearestBoundary;
    final distance = geoFence.distanceToBoundaryMeters;

    return Scaffold(
      key: const Key('screen-safety'),
      appBar: AppBar(
        title: const Text('Safety Assessment', style: BsasTypography.heading),
        actions: [
          StatusBadge(
            label: stateStr,
            color: stateColor,
          ),
          const SizedBox(width: BsasSpacing.screenMargin),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: BsasSpacing.screenMargin,
          vertical: BsasSpacing.md,
        ),
        children: [
          // 1. Authoritative Status Card
          Container(
            padding: BsasSpacing.cardInsets,
            decoration: BoxDecoration(
              color: stateBg,
              borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
              border: Border.all(color: stateColor, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(stateIcon, color: stateColor, size: 24),
                        const SizedBox(width: BsasSpacing.sm),
                        Text(
                          state.label,
                          style: BsasTypography.display.copyWith(
                            fontSize: 20,
                            color: stateColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    GpsStatusChip(state: live.fix),
                  ],
                ),
                const SizedBox(height: BsasSpacing.sm),
                Text(
                  isCritical
                      ? 'Immediate Action Required: Your position is inside or directly adjacent to a restricted perimeter.'
                      : (isWarning
                          ? 'Elevated Proximity: You have entered the buffer zone. Movement heading is being continuously evaluated.'
                          : 'Normal Status: Safe civilian clearance maintained across all configured sectors.'),
                  style: BsasTypography.body.copyWith(
                    color: isDark ? BsasColors.textLightPrimary : BsasColors.textDarkPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: BsasSpacing.md),

          // 2. Telemetry & Boundary Intelligence
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: BsasSpacing.cardInsets,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PERIMETER & SENSOR TELEMETRY',
                    style: BsasTypography.sectionHeading.copyWith(
                      color: BsasColors.primaryBlue,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: BsasSpacing.md),
                  _telemetryRow('Nearest Sector', boundary?.name ?? 'Sector Buffer Area'),
                  const Divider(height: BsasSpacing.md),
                  _telemetryRow('Perimeter Classification', boundary?.type.toUpperCase() ?? 'PROTECTED'),
                  const Divider(height: BsasSpacing.md),
                  _telemetryRow(
                    'Demarcation Distance',
                    distance != null ? '${distance.toStringAsFixed(1)} meters' : 'Calculating fix...',
                  ),
                  const Divider(height: BsasSpacing.md),
                  _telemetryRow(
                    'Movement Vector',
                    geoFence.movingTowardBoundary
                        ? 'Converging toward perimeter'
                        : (distance != null ? 'Diverging / parallel transit' : 'Stationary'),
                  ),
                  if (geoFence.directionToBoundaryDegrees != null) ...[
                    const Divider(height: BsasSpacing.md),
                    _telemetryRow(
                      'Compass Bearing to Perimeter',
                      '${geoFence.directionToBoundaryDegrees!.toStringAsFixed(0)}°',
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: BsasSpacing.md),

          // 3. Dual-Engine Assessment Rationale
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: BsasSpacing.cardInsets,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.analytics_outlined, size: 20, color: BsasColors.primaryBlue),
                      const SizedBox(width: BsasSpacing.sm),
                      Text(
                        'DUAL ENGINE EVALUATION',
                        style: BsasTypography.sectionHeading.copyWith(
                          color: BsasColors.primaryBlue,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: BsasSpacing.sm),
                  Text(
                    '• Deterministic Engine: Real-time point-in-polygon & haversine closest-point mathematical verification against on-device SQLite boundary vectors.\n'
                    '• Machine Learning Model: On-device LSTM (5-step temporal sequence) fused with Random Forest risk classification via RobustScaler normalization.\n'
                    '• Risk Fusion: The authoritative higher risk state dominates to prevent false negatives.',
                    style: BsasTypography.body.copyWith(
                      fontSize: 13,
                      height: 1.45,
                      color: isDark ? BsasColors.textLightSecondary : BsasColors.textDarkSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: BsasSpacing.md),

          // 4. Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RouteScreen(
                          gps: live,
                          loadBoundaries: OfflineBoundaryProvider().loadEnabledBoundaries,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.alt_route_rounded, size: 18),
                  label: const Text('CALCULATE SAFE ROUTE'),
                ),
              ),
            ],
          ),
          const SizedBox(height: BsasSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MapScreen(
                          gps: live,
                          geoFence: geoFence,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('INSPECT ON LIVE MAP'),
                ),
              ),
            ],
          ),
          const SizedBox(height: BsasSpacing.lg),
        ],
      ),
    );
  }

  Widget _telemetryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: BsasTypography.bodyMuted),
        const SizedBox(width: BsasSpacing.sm),
        Flexible(
          child: Text(
            value,
            style: BsasTypography.title.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
