import 'dart:async';
import 'package:flutter/material.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_spacing.dart';
import '../core/theme/bsas_typography.dart';
import '../core/widgets/status_badge.dart';
import '../models/gps_snapshot.dart';
import '../models/boundary_model.dart';
import '../models/routing_result.dart';
import '../services/routing_service.dart';

/// Redesigned Safe Evacuation Corridor Route screen.
///
/// Runs deterministic A* obstacle-avoidance pathfinding around restricted border polygons.
class RouteScreen extends StatefulWidget {
  const RouteScreen({
    super.key,
    required this.gps,
    required this.loadBoundaries,
  });

  final GpsSnapshot gps;
  final Future<List<BoundaryModel>> Function() loadBoundaries;

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final RoutingService _routingService = RoutingService();
  RoutingResult? _result;
  bool _isLoading = false;

  Future<void> _calculateRoute() async {
    final loc = widget.gps.location;
    if (loc == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No GPS location available. Ensure GNSS receiver is active.')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final boundaries = await widget.loadBoundaries();
      final result = await _routingService.calculateSafeRoute(loc, boundaries);
      if (mounted) {
        setState(() => _result = result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error calculating safe corridor: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = widget.gps.location;

    return Scaffold(
      key: const Key('screen-route'),
      appBar: AppBar(
        title: const Text('Safe Escape Route', style: BsasTypography.heading),
      ),
      body: ListView(
        padding: const EdgeInsets.all(BsasSpacing.screenMargin),
        children: [
          // Origin Location Card
          Container(
            padding: BsasSpacing.cardInsets,
            decoration: BoxDecoration(
              color: isDark ? BsasColors.darkCard : BsasColors.lightCard,
              borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
              border: Border.all(color: isDark ? BsasColors.darkBorder : BsasColors.lightBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.my_location, size: 22, color: BsasColors.primaryBlue),
                const SizedBox(width: BsasSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CURRENT ORIGIN GNSS',
                        style: BsasTypography.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        loc != null
                            ? '${loc.latitude.toStringAsFixed(6)}, ${loc.longitude.toStringAsFixed(6)} (±${loc.accuracy?.toStringAsFixed(0) ?? "15"}m)'
                            : 'Waiting for GNSS fix...',
                        style: BsasTypography.monoDiagnostics.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: loc != null ? 'FIX ACTIVE' : 'NO FIX',
                  state: loc != null ? StatusState.ready : StatusState.warning,
                ),
              ],
            ),
          ),
          const SizedBox(height: BsasSpacing.md),

          // Routing Result Status Card
          if (_result != null) ...[
            Container(
              padding: BsasSpacing.cardInsets,
              decoration: BoxDecoration(
                color: _result!.status == RoutingStatus.alreadySafe
                    ? BsasColors.backgroundForState('SAFE', isDark: isDark)
                    : (_result!.status == RoutingStatus.available
                        ? BsasColors.backgroundForState('CAUTION', isDark: isDark)
                        : BsasColors.backgroundForState('CRITICAL', isDark: isDark)),
                borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
                border: Border.all(
                  color: _result!.status == RoutingStatus.alreadySafe
                      ? BsasColors.safeGreen
                      : (_result!.status == RoutingStatus.available
                          ? BsasColors.primaryBlue
                          : BsasColors.criticalRed),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _result!.status == RoutingStatus.alreadySafe
                            ? Icons.check_circle_outline
                            : (_result!.status == RoutingStatus.available
                                ? Icons.alt_route_rounded
                                : Icons.warning_amber_rounded),
                        color: _result!.status == RoutingStatus.alreadySafe
                            ? BsasColors.safeGreen
                            : (_result!.status == RoutingStatus.available
                                ? BsasColors.primaryBlue
                                : BsasColors.criticalRed),
                        size: 24,
                      ),
                      const SizedBox(width: BsasSpacing.sm),
                      Text(
                        _result!.status == RoutingStatus.alreadySafe
                            ? 'You are safe.'
                            : (_result!.status == RoutingStatus.available
                                ? 'Safe Route Found'
                                : 'No Route Available'),
                        style: BsasTypography.heading.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: BsasSpacing.xs),
                  Text(
                    _result!.message,
                    style: BsasTypography.body.copyWith(
                      color: isDark ? BsasColors.textLightSecondary : BsasColors.textDarkSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: BsasSpacing.md),

            // Navigation Metrics if Available
            if (_result!.status == RoutingStatus.available &&
                _result!.totalDistanceMeters != null) ...[
              Container(
                padding: BsasSpacing.cardInsets,
                decoration: BoxDecoration(
                  color: isDark ? BsasColors.darkCard : BsasColors.lightCard,
                  borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
                  border: Border.all(color: isDark ? BsasColors.darkBorder : BsasColors.lightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESCAPE CORRIDOR NAVIGATION',
                      style: BsasTypography.sectionHeading.copyWith(
                        color: BsasColors.primaryBlue,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: BsasSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _navMetric(
                            'CORRIDOR DISTANCE',
                            '${_result!.totalDistanceMeters!.toStringAsFixed(1)} m',
                            Icons.straighten,
                          ),
                        ),
                        Container(width: 1, height: 36, color: isDark ? BsasColors.darkBorder : BsasColors.lightBorder),
                        Expanded(
                          child: _navMetric(
                            'INITIAL BEARING',
                            _result!.initialBearing != null
                                ? '${_result!.initialBearing!.toStringAsFixed(0)}°'
                                : 'N/A',
                            Icons.explore_outlined,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: BsasSpacing.md),
            ],
          ] else ...[
            Container(
              padding: BsasSpacing.cardInsets,
              decoration: BoxDecoration(
                color: isDark ? BsasColors.darkCard : BsasColors.lightCard,
                borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
                border: Border.all(color: isDark ? BsasColors.darkBorder : BsasColors.lightBorder),
              ),
              child: Column(
                children: [
                  const Icon(Icons.route_outlined, size: 40, color: BsasColors.primaryBlue),
                  const SizedBox(height: BsasSpacing.sm),
                  Text('No route calculated', style: BsasTypography.title),
                  const SizedBox(height: BsasSpacing.xs),
                  Text(
                    'Tap the button below to compute an obstacle-free escape route away from restricted border boundaries using deterministic A* pathfinding.',
                    style: BsasTypography.bodyMuted,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: BsasSpacing.md),
          ],

          // Calculate Route Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _calculateRoute,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.navigation_outlined, size: 20),
              label: Text(_isLoading ? 'CALCULATING SAFE CORRIDOR...' : 'CALCULATE SAFE ROUTE'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: BsasColors.primaryBlue),
        const SizedBox(height: 4),
        Text(
          label,
          style: BsasTypography.caption.copyWith(fontSize: 10, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: BsasTypography.monoDiagnostics.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
