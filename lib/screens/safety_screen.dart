import 'package:flutter/material.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_spacing.dart';
import '../core/theme/bsas_typography.dart';

import '../models/boundary_model.dart';
import '../models/gps_snapshot.dart';
import '../models/geofence_result.dart';
import '../models/geofence_state.dart';
import 'route_screen.dart';
import 'map_screen.dart';
import '../services/boundary_summary.dart';

/// Redesigned comprehensive Safety Status screen.
///
/// Presents authoritative deterministic & ML fused safety diagnostics,
/// real distance to border demarcations, trajectory vectors, and clear action guidance.
class SafetyScreen extends StatelessWidget {
  const SafetyScreen({
    super.key,
    this.gps,
    this.geoFence = const GeoFenceResult(state: GeoFenceState.unknown),
  });

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
    final stateIcon = BsasColors.iconForState(stateStr);
    final boundary = geoFence.nearestBoundary;
    final distance = geoFence.distanceToBoundaryMeters;

    return Scaffold(
      key: const Key('screen-safety'),
      backgroundColor: isDark ? BsasColors.darkBackground : BsasColors.lightBackground,
      appBar: AppBar(
        title: Text('Safety Diagnostics', style: BsasTypography.title.copyWith(fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Safety Info',
            onPressed: () {},
          ),
          const SizedBox(width: BsasSpacing.xs),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: BsasSpacing.screenMargin,
          vertical: BsasSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Signature Hero Status Dial
            _buildStatusDial(stateStr, stateColor, stateIcon, isCritical, isWarning, state, isDark),
            const SizedBox(height: BsasSpacing.xl),

            // 2. Action Guidance Banner
            _buildGuidanceBanner(stateColor, isCritical, isWarning, isDark),
            const SizedBox(height: BsasSpacing.xl),
            
            Text(
              'TELEMETRY READINGS',
              style: BsasTypography.sectionHeading.copyWith(
                color: isDark ? BsasColors.textLightMuted : BsasColors.textDarkMuted,
              ),
            ),
            const SizedBox(height: BsasSpacing.sm),

            // 3. Structured Telemetry Cards
            _buildMetricsGrid(boundary, distance, live, stateColor, isCritical, isWarning, isDark),
            const SizedBox(height: BsasSpacing.xxl),

            // 4. Action Buttons
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: BsasColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: BsasSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
                ),
                elevation: 4,
                shadowColor: BsasColors.primaryBlue.withValues(alpha: 0.5),
              ),
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
              icon: const Icon(Icons.alt_route_rounded, size: 22),
              label: Text('CALCULATE SAFE ROUTE', style: BsasTypography.label),
            ),
            const SizedBox(height: BsasSpacing.md),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: BsasSpacing.md),
                side: BorderSide(color: isDark ? BsasColors.darkBorder : BsasColors.lightBorder, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
                ),
              ),
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
              icon: Icon(Icons.map_outlined, size: 22, color: isDark ? Colors.white : Colors.black),
              label: Text('INSPECT ON LIVE MAP', style: BsasTypography.label.copyWith(
                color: isDark ? Colors.white : Colors.black,
              )),
            ),
            const SizedBox(height: BsasSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDial(
    String stateStr,
    Color stateColor,
    IconData stateIcon,
    bool isCritical,
    bool isWarning,
    GeoFenceState state,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: BsasSpacing.xxl, horizontal: BsasSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? BsasColors.darkSurface : BsasColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: stateColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: stateColor.withValues(alpha: 0.05),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          // Multi-layer glowing ring
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? BsasColors.darkBackground : BsasColors.lightBackground,
              boxShadow: [
                BoxShadow(
                  color: stateColor.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: stateColor.withValues(alpha: 0.1),
                  blurRadius: 60,
                  spreadRadius: 15,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 4,
                    color: stateColor.withValues(alpha: 0.3),
                  ),
                ),
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CircularProgressIndicator(
                    value: 0.75, // Simulate active scan
                    strokeWidth: 2,
                    color: stateColor,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Icon(
                  stateIcon,
                  size: 52,
                  color: stateColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: BsasSpacing.xl),
          Text(
            stateStr,
            style: BsasTypography.display.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
              color: stateColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isCritical
                ? 'Perimeter breach detected'
                : (isWarning
                    ? 'Approaching monitored area'
                    : (state == GeoFenceState.safe
                        ? 'Authorized safe zone'
                        : 'Acquiring satellite fix...')),
            style: BsasTypography.body.copyWith(
              fontSize: 14,
              color: isDark ? BsasColors.textLightSecondary : BsasColors.textDarkSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGuidanceBanner(Color stateColor, bool isCritical, bool isWarning, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(BsasSpacing.md),
      decoration: BoxDecoration(
        color: stateColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: stateColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 24, color: stateColor),
          const SizedBox(width: BsasSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DIRECTIVE',
                  style: BsasTypography.sectionHeading.copyWith(color: stateColor),
                ),
                const SizedBox(height: 4),
                Text(
                  isCritical
                      ? 'Boundary breach detected. Reverse heading immediately along the recommended safe corridor.'
                      : (isWarning
                          ? 'You are approaching a monitored boundary. Stay alert and prepare to alter course if necessary.'
                          : 'No immediate action required. Maintain normal operations.'),
                  style: BsasTypography.body.copyWith(
                    fontSize: 13.5,
                    height: 1.4,
                    color: isDark ? BsasColors.textLightPrimary : BsasColors.textDarkPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(
    BoundaryModel? boundary, 
    double? distance, 
    GpsSnapshot live, 
    Color stateColor, 
    bool isCritical, 
    bool isWarning, 
    bool isDark
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Distance to Boundary',
                distance != null ? '${(distance / 1000).toStringAsFixed(1)} km' : '--',
                Icons.straighten,
                highlightColor: stateColor,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: BsasSpacing.sm),
            Expanded(
              child: _buildMetricCard(
                'Risk Level',
                isCritical ? 'Critical' : (isWarning ? 'Moderate' : 'Low'),
                Icons.warning_amber_rounded,
                highlightColor: stateColor,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: BsasSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Current Sector',
                boundary?.name ?? 'Unknown',
                Icons.explore,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: BsasSpacing.sm),
            Expanded(
              child: _buildMetricCard(
                'GPS Accuracy',
                live.location?.accuracy != null ? '±${live.location!.accuracy!.toStringAsFixed(0)} m' : '--',
                Icons.gps_fixed,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, {Color? highlightColor, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(BsasSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? BsasColors.darkSurface : BsasColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? BsasColors.darkBorder : BsasColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: highlightColor ?? BsasColors.primaryBlue),
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
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: highlightColor ?? (isDark ? BsasColors.textLightPrimary : BsasColors.textDarkPrimary),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

