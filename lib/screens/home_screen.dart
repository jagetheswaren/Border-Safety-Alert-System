import 'package:flutter/material.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_spacing.dart';
import '../core/theme/bsas_typography.dart';
import '../core/widgets/bsas_logo.dart';
import '../core/widgets/status_badge.dart';
import '../data/demo_data.dart';
import '../models/gps_snapshot.dart';
import '../models/geofence_result.dart';
import '../models/geofence_state.dart';
import '../models/safety_state.dart';
import '../services/boundary_summary.dart';
import '../widgets/boundary_count_card.dart';
import '../widgets/gps_live_card.dart';

/// Redesigned human-crafted Home Screen for BSAS.
///
/// Immediately answers: "Am I safe right now?"
/// Follows strict spacing grid, clear typography hierarchy, and calm civilian aesthetics.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.snapshot = DemoSafetySnapshot.placeholder,
    this.gps,
    this.onGpsRetry,
    this.boundarySummary,
    this.geoFence = const GeoFenceResult(state: GeoFenceState.unknown),
    required this.onNavigate,
  });

  final DemoSafetySnapshot snapshot;
  final GpsSnapshot? gps;
  final VoidCallback? onGpsRetry;
  final Future<BoundarySummary>? boundarySummary;
  final void Function(int index) onNavigate;
  final GeoFenceResult geoFence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final live = gps ?? GpsSnapshot.initial();
    final fix = live.location;
    final state = geoFence.state;
    final stateStr = state.name.toUpperCase();

    final isCritical = state == GeoFenceState.critical || state == GeoFenceState.insideRestrictedArea;
    final isWarning = state == GeoFenceState.warning || state == GeoFenceState.caution;

    final stateColor = BsasColors.forSafetyState(stateStr);
    final stateBg = BsasColors.backgroundForState(stateStr, isDark: isDark);
    final stateIcon = BsasColors.iconForState(stateStr);

    String statusDescription;
    if (isCritical) {
      statusDescription = 'Perimeter breach detected. Reverse heading immediately and follow safe route.';
    } else if (isWarning) {
      statusDescription = 'Buffer corridor reached. Demarcated perimeter nearby. Maintain situational awareness.';
    } else if (state == GeoFenceState.safe) {
      statusDescription = 'You are within authorized civilian boundaries. Real-time GNSS monitoring is active.';
    } else {
      statusDescription = 'Acquiring satellite fix and evaluating local boundary status.';
    }

    return Scaffold(
      key: const Key('screen-home'),
      appBar: AppBar(
        title: Row(
          children: [
            const BsasLogo(size: 24, animated: false),
            const SizedBox(width: BsasSpacing.sm),
            Text(
              'BSAS CIVILIAN SAFETY',
              style: BsasTypography.sectionHeading.copyWith(
                color: isDark ? BsasColors.textLightPrimary : BsasColors.textDarkPrimary,
                fontSize: 13,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        actions: [
          StatusBadge(
            label: live.fix == GpsFixState.locked ? 'GPS LOCKED' : 'SEARCHING',
            state: live.fix == GpsFixState.locked ? StatusState.ready : StatusState.warning,
          ),
          const SizedBox(width: BsasSpacing.sm),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: BsasSpacing.screenMargin,
          vertical: BsasSpacing.sm,
        ),
        children: [
          // 1. Primary "Am I Safe Right Now?" Hero Banner (Compact & Dominant)
          Container(
            key: const Key('safety-status-card'),
            padding: const EdgeInsets.all(BsasSpacing.md),
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
                        Icon(stateIcon, color: stateColor, size: 22),
                        const SizedBox(width: BsasSpacing.sm),
                        Text(
                          stateStr,
                          style: BsasTypography.heading.copyWith(
                            color: stateColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    StatusBadge(
                      label: isCritical ? 'CRITICAL' : (isWarning ? 'PROXIMITY' : 'NORMAL'),
                      color: stateColor,
                    ),
                  ],
                ),
                const SizedBox(height: BsasSpacing.xs),
                Text(
                  statusDescription,
                  style: BsasTypography.body.copyWith(
                    fontSize: 13,
                    color: isDark ? BsasColors.textLightPrimary : BsasColors.textDarkPrimary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: BsasSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _metricCell(
                        context,
                        label: 'NEAREST SECTOR',
                        value: geoFence.nearestBoundary?.name ?? 'Sector Buffer',
                      ),
                    ),
                    Container(width: 1, height: 28, color: isDark ? BsasColors.darkBorder : BsasColors.lightBorder),
                    Expanded(
                      child: _metricCell(
                        context,
                        label: 'DISTANCE',
                        value: geoFence.distanceToBoundaryMeters != null
                            ? '${geoFence.distanceToBoundaryMeters!.toStringAsFixed(0)} m'
                            : 'Evaluating',
                      ),
                    ),
                    Container(width: 1, height: 28, color: isDark ? BsasColors.darkBorder : BsasColors.lightBorder),
                    Expanded(
                      child: _metricCell(
                        context,
                        label: 'ACCURACY',
                        value: fix?.accuracy != null ? '±${fix!.accuracy!.toStringAsFixed(0)}m' : '±15m',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: BsasSpacing.xs),

          // 2. Live Hardware GNSS Coordinates Card (Preserves test keys & live telemetry)
          GpsLiveCard(
            snapshot: live,
            onRetry: onGpsRetry,
          ),
          const SizedBox(height: BsasSpacing.xs),

          // 3. Offline Boundary Datasets (Preserves boundary summary & test keys)
          BoundaryCountCard(summary: boundarySummary),
          const SizedBox(height: BsasSpacing.sm),

          // 4. Quick Response Action Toolbar
          Row(
            children: [
              Expanded(
                child: _quickActionButton(
                  context,
                  icon: Icons.map_outlined,
                  label: 'Live Map',
                  onTap: () => onNavigate(1), // Map tab
                ),
              ),
              const SizedBox(width: BsasSpacing.sm),
              Expanded(
                child: _quickActionButton(
                  context,
                  icon: Icons.alt_route_rounded,
                  label: 'Safe Route',
                  onTap: () => onNavigate(3), // Route tab
                ),
              ),
              const SizedBox(width: BsasSpacing.sm),
              Expanded(
                child: _quickActionButton(
                  context,
                  icon: Icons.shield_outlined,
                  label: 'Safety Audit',
                  onTap: () => onNavigate(2), // Safety tab
                ),
              ),
            ],
          ),
          const SizedBox(height: BsasSpacing.sm),

          // 5. Demo or Field Environment Disclaimer
          if (snapshot.isPlaceholder)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.xs),
              child: Text(
                'Demo data — live GPS and risk engine arrive in later phases.',
                style: BsasTypography.caption.copyWith(
                  fontStyle: FontStyle.italic,
                  color: isDark ? BsasColors.textLightMuted : BsasColors.textDarkMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _metricCell(BuildContext context, {required String label, required String value}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: BsasTypography.caption.copyWith(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: isDark ? BsasColors.textLightMuted : BsasColors.textDarkMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: BsasTypography.title.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? BsasColors.textLightPrimary : BsasColors.textDarkPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: BsasSpacing.sm),
        decoration: BoxDecoration(
          color: isDark ? BsasColors.darkCard : BsasColors.lightCard,
          borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
          border: Border.all(
            color: isDark ? BsasColors.darkBorder : BsasColors.lightBorder,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: BsasColors.primaryBlue),
            const SizedBox(height: BsasSpacing.xs),
            Text(
              label,
              style: BsasTypography.label.copyWith(
                fontSize: 11,
                color: isDark ? BsasColors.textLightPrimary : BsasColors.textDarkPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
