import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_spacing.dart';
import '../core/theme/bsas_typography.dart';
import '../core/widgets/bsas_logo.dart';
import '../core/widgets/status_badge.dart';

import '../models/gps_snapshot.dart';
import '../models/geofence_result.dart';
import '../models/geofence_state.dart';
import '../models/safety_state.dart';
import '../services/boundary_summary.dart';
import '../widgets/boundary_count_card.dart';
import '../widgets/gps_live_card.dart';

/// Redesigned human-crafted Home Screen for BSAS.
///
/// Features a bespoke Sliver-based layout, ditching the generic grids for a
/// flowing, premium, and highly intentional information hierarchy.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.gps,
    this.onGpsRetry,
    this.boundarySummary,
    this.geoFence = const GeoFenceResult(state: GeoFenceState.unknown),
    required this.onNavigate,
  });

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
    final stateIcon = BsasColors.iconForState(stateStr);

    String statusDescription;
    if (isCritical) {
      statusDescription = 'Perimeter breach detected.\nReverse heading immediately.';
    } else if (isWarning) {
      statusDescription = 'Buffer corridor reached.\nMaintain situational awareness.';
    } else if (state == GeoFenceState.safe) {
      statusDescription = 'Within civilian boundaries.\nMonitoring active.';
    } else {
      statusDescription = 'Acquiring satellite fix\nand evaluating local boundary.';
    }

    return Scaffold(
      key: const Key('screen-home'),
      backgroundColor: isDark ? BsasColors.darkBackground : BsasColors.lightBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 280.0,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? BsasColors.darkBackground : BsasColors.primaryBlue,
            systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      stateColor.withValues(alpha: isDark ? 0.4 : 0.8),
                      isDark ? BsasColors.darkBackground : BsasColors.lightBackground,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: BsasSpacing.xl),
                      _buildPulsingShield(stateColor, stateIcon, isDark),
                      const SizedBox(height: BsasSpacing.md),
                      Text(
                        stateStr,
                        key: const Key('safety-state'),
                        style: BsasTypography.display.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color: isDark ? BsasColors.textLightPrimary : BsasColors.textDarkPrimary,
                        ),
                      ),
                      const SizedBox(height: BsasSpacing.xs),
                      Text(
                        statusDescription,
                        textAlign: TextAlign.center,
                        style: BsasTypography.body.copyWith(
                          fontSize: 14,
                          height: 1.4,
                          color: isDark ? BsasColors.textLightSecondary : BsasColors.textDarkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            title: Row(
              children: [
                const BsasLogo(size: 24, animated: false),
                const SizedBox(width: BsasSpacing.sm),
                Text(
                  'BSAS',
                  style: BsasTypography.title.copyWith(
                    color: isDark ? BsasColors.textLightPrimary : BsasColors.textLightPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: BsasSpacing.sm),
                  child: StatusBadge(
                    label: live.fix == GpsFixState.locked ? 'GPS LOCKED' : 'SEARCHING',
                    state: live.fix == GpsFixState.locked ? StatusState.ready : StatusState.warning,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  color: isDark ? BsasColors.textLightPrimary : BsasColors.textLightPrimary,
                ),
                tooltip: 'Settings',
                onPressed: () => onNavigate(6),
              ),
              const SizedBox(width: BsasSpacing.xs),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BsasSpacing.screenMargin,
                vertical: BsasSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LIVE TELEMETRY',
                    style: BsasTypography.sectionHeading.copyWith(
                      color: isDark ? BsasColors.textLightMuted : BsasColors.textDarkMuted,
                    ),
                  ),
                  const SizedBox(height: BsasSpacing.sm),
                  _buildBespokeTelemetryRow(
                    context,
                    leftLabel: 'Distance to Boundary',
                    leftValue: geoFence.distanceToBoundaryMeters != null
                        ? '${(geoFence.distanceToBoundaryMeters! / 1000).toStringAsFixed(1)} km'
                        : '-- km',
                    leftIcon: Icons.straighten_outlined,
                    rightLabel: 'Current Sector',
                    rightValue: geoFence.nearestBoundary?.name ?? 'Unknown',
                    rightIcon: Icons.explore_outlined,
                  ),
                  const SizedBox(height: BsasSpacing.md),
                  _buildLocationCard(context, fix, live.fix),
                  const SizedBox(height: BsasSpacing.xl),
                  
                  Text(
                    'QUICK ACTIONS',
                    style: BsasTypography.sectionHeading.copyWith(
                      color: isDark ? BsasColors.textLightMuted : BsasColors.textDarkMuted,
                    ),
                  ),
                  const SizedBox(height: BsasSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _actionPill(context, 'Map', Icons.map_outlined, () => onNavigate(1)),
                      _actionPill(context, 'Route', Icons.alt_route_rounded, () => onNavigate(3)),
                      _actionPill(context, 'Alerts', Icons.notifications_active_outlined, () => onNavigate(4)),
                      _actionPill(context, 'AI Assist', Icons.smart_toy_outlined, () => onNavigate(5)),
                    ],
                  ),
                  const SizedBox(height: BsasSpacing.xl),
                  
                  GpsLiveCard(snapshot: live, onRetry: onGpsRetry),
                  const SizedBox(height: BsasSpacing.md),
                  BoundaryCountCard(summary: boundarySummary),
                  const SizedBox(height: BsasSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingShield(Color stateColor, IconData icon, bool isDark) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: stateColor.withValues(alpha: 0.15),
        border: Border.all(color: stateColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: stateColor.withValues(alpha: 0.3),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          size: 36,
          color: isDark ? BsasColors.textLightPrimary : BsasColors.textDarkPrimary,
        ),
      ),
    );
  }

  Widget _buildBespokeTelemetryRow(
    BuildContext context, {
    required String leftLabel,
    required String leftValue,
    required IconData leftIcon,
    required String rightLabel,
    required String rightValue,
    required IconData rightIcon,
  }) {
    return Row(
      children: [
        Expanded(child: _telemetryBlock(context, leftLabel, leftValue, leftIcon)),
        const SizedBox(width: BsasSpacing.md),
        Expanded(child: _telemetryBlock(context, rightLabel, rightValue, rightIcon)),
      ],
    );
  }

  Widget _telemetryBlock(BuildContext context, String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(BsasSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? BsasColors.darkSurface : BsasColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? BsasColors.darkBorder : BsasColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: BsasColors.primaryBlue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: BsasTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? BsasColors.textLightMuted : BsasColors.textDarkMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: BsasSpacing.sm),
          Text(
            value,
            style: BsasTypography.title.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? BsasColors.textLightPrimary : BsasColors.textDarkPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, dynamic fix, GpsFixState fixState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasFix = fix != null;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BsasSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? BsasColors.darkSurface : BsasColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? BsasColors.darkBorder : BsasColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (fixState == GpsFixState.locked ? BsasColors.safeGreen : BsasColors.warningOrange)
                  .withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.my_location_rounded,
              color: fixState == GpsFixState.locked ? BsasColors.safeGreen : BsasColors.warningOrange,
            ),
          ),
          const SizedBox(width: BsasSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GNSS Coordinates',
                  style: BsasTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? BsasColors.textLightMuted : BsasColors.textDarkMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasFix
                      ? '${fix.latitude.toStringAsFixed(5)}°, ${fix.longitude.toStringAsFixed(5)}°'
                      : 'Acquiring satellite fix...',
                  style: BsasTypography.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? BsasColors.textLightPrimary : BsasColors.textDarkPrimary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionPill(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? BsasColors.darkCardHover : BsasColors.lightCardHover,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? BsasColors.darkBorderSubtle : BsasColors.lightBorderSubtle,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: BsasColors.primaryBlue, size: 22),
              const SizedBox(height: 8),
              Text(
                label,
                style: BsasTypography.label.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? BsasColors.textLightPrimary : BsasColors.textDarkPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
