import 'package:flutter/material.dart';

import '../core/animations/bsas_animations.dart';
import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_typography.dart';
import '../core/widgets/status_badge.dart';
import '../core/widgets/status_dot.dart';
import '../data/demo_data.dart';
import '../models/gps_snapshot.dart';
import '../models/geofence_result.dart';
import '../models/geofence_state.dart';
import '../services/boundary_summary.dart';
import '../widgets/boundary_count_card.dart';
import '../widgets/geofence_status_card.dart';
import '../widgets/gps_live_card.dart';
import '../widgets/safety_alert_banner.dart';

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
    final live = gps ?? GpsSnapshot.initial();
    final fix = live.location;
    final state = geoFence.state;
    final stateStr = state.name.toUpperCase();

    final isCritical = state == GeoFenceState.critical || state == GeoFenceState.insideRestrictedArea;
    final isWarning = state == GeoFenceState.warning || state == GeoFenceState.caution;

    Color stateColor = BsasColors.safeGreen;
    if (isCritical) {
      stateColor = BsasColors.criticalRed;
    } else if (isWarning) {
      stateColor = BsasColors.warningOrange;
    }

    return Scaffold(
      key: const Key('screen-home'),
      backgroundColor: BsasColors.darkBackground,
      appBar: AppBar(
        backgroundColor: BsasColors.darkSurface,
        title: Row(
          children: [
            const StatusDot(state: StatusState.ready, size: 8),
            const SizedBox(width: 8),
            Text('BSAS FIELD SAFETY', style: BsasTypography.headline.copyWith(letterSpacing: 1.2)),
          ],
        ),
        actions: const [
          StatusBadge(label: 'GPS ACTIVE', state: StatusState.ready),
          SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          GpsLiveCard(
            snapshot: live,
            onRetry: onGpsRetry,
          ),
          const SizedBox(height: 6),
          BoundaryCountCard(summary: boundarySummary),
          const SizedBox(height: 6),
          GeoFenceStatusCard(result: geoFence),
          const SizedBox(height: 6),
          SafetyAlertBanner(result: geoFence),
          const SizedBox(height: 12),

          // Operational Safety Command Card
          Card(
            color: BsasColors.darkSurface,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: stateColor, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CURRENT SAFETY STATE',
                        style: BsasTypography.caption.copyWith(letterSpacing: 1.2),
                      ),
                      StatusBadge(
                        label: isCritical ? 'CRITICAL ALERT' : (isWarning ? 'PROXIMITY WARNING' : 'NOMINAL'),
                        state: isCritical ? StatusState.critical : (isWarning ? StatusState.warning : StatusState.ready),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AlertPulseAnimation(
                    isActive: isCritical || isWarning,
                    color: stateColor,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      decoration: BoxDecoration(
                        color: stateColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: stateColor),
                      ),
                      child: Text(
                        stateStr,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: stateColor,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _hudItem('GPS', live.fix.name.toUpperCase()),
                      _hudItem('ACCURACY', fix?.accuracy != null ? '±${fix!.accuracy!.toStringAsFixed(0)}m' : '±15m'),
                      _hudItem('ZONE', geoFence.nearestBoundary?.name ?? 'SECTOR 7'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BsasColors.radarCyan,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('OPEN MAP', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () => onNavigate(1), // Jump to Map
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: BsasColors.darkBorder),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.psychology_outlined, color: BsasColors.radarCyan),
                          label: const Text('AI ASSISTANT'),
                          onPressed: () => onNavigate(5), // Jump to AI Chat
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hudItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: BsasTypography.caption.copyWith(color: BsasColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: BsasTypography.monoDiagnostics.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
