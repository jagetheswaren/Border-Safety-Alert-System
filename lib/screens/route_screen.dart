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
          SnackBar(
            backgroundColor: BsasColors.surface(Theme.of(context).brightness == Brightness.dark),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: BsasColors.border(Theme.of(context).brightness == Brightness.dark)),
            ),
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: BsasColors.warningOrange, size: 20),
                const SizedBox(width: BsasSpacing.sm),
                Expanded(
                  child: Text(
                    'No GPS location available. Ensure GNSS receiver is active.',
                    style: BsasTypography.body.copyWith(color: BsasColors.text(Theme.of(context).brightness == Brightness.dark)),
                  ),
                ),
              ],
            ),
          ),
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
          SnackBar(
            backgroundColor: BsasColors.surface(Theme.of(context).brightness == Brightness.dark),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: BsasColors.border(Theme.of(context).brightness == Brightness.dark)),
            ),
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: BsasColors.criticalRed, size: 20),
                const SizedBox(width: BsasSpacing.sm),
                Expanded(
                  child: Text(
                    'Error calculating safe corridor: $e',
                    style: BsasTypography.body.copyWith(color: BsasColors.text(Theme.of(context).brightness == Brightness.dark)),
                  ),
                ),
              ],
            ),
          ),
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
      backgroundColor: BsasColors.background(isDark),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: BsasColors.surface(isDark),
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: BsasColors.text(isDark)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                Icon(Icons.alt_route_rounded, color: BsasColors.radarCyan, size: 20),
                const SizedBox(width: BsasSpacing.sm),
                Text(
                  'SAFE ESCAPE ROUTE',
                  style: BsasTypography.heading.copyWith(
                    color: BsasColors.text(isDark),
                    letterSpacing: 1.2,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(
                color: isDark ? BsasColors.darkBorder : BsasColors.lightBorder,
                height: 1.0,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.lg, vertical: BsasSpacing.xl),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  // Origin Location Card
                  _sectionHeader('CURRENT ORIGIN GNSS', isDark),
                  Container(
                    padding: const EdgeInsets.all(BsasSpacing.lg),
                    decoration: BoxDecoration(
                      color: BsasColors.card(isDark),
                      borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
                      border: Border.all(color: BsasColors.border(isDark), width: 1.0),
                      boxShadow: isDark
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [
                              BoxShadow(
                                color: BsasColors.lightBorder,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(BsasSpacing.sm),
                          decoration: BoxDecoration(
                            color: BsasColors.primaryBlue.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: BsasColors.primaryBlue.withValues(alpha: 0.3)),
                          ),
                          child: Icon(Icons.my_location, size: 20, color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue),
                        ),
                        const SizedBox(width: BsasSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc != null
                                    ? '${loc.latitude.toStringAsFixed(6)}, ${loc.longitude.toStringAsFixed(6)}'
                                    : 'Waiting for GNSS fix...',
                                style: BsasTypography.monospace.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: BsasColors.text(isDark),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (loc != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Accuracy: ±${loc.accuracy?.toStringAsFixed(0) ?? "15"}m',
                                  style: BsasTypography.monospace.copyWith(
                                    fontSize: 11,
                                    color: BsasColors.textSec(isDark),
                                  ),
                                ),
                              ]
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
                  const SizedBox(height: BsasSpacing.xxl),

                  // Routing Result Status Card
                  if (_result != null) ...[
                    _sectionHeader('ROUTING RESULT', isDark),
                    Container(
                      padding: const EdgeInsets.all(BsasSpacing.lg),
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
                                  ? BsasColors.warningOrange
                                  : BsasColors.criticalRed),
                          width: 1.0,
                        ),
                        boxShadow: isDark
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [
                                BoxShadow(
                                  color: BsasColors.lightBorder,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(BsasSpacing.sm),
                                decoration: BoxDecoration(
                                  color: _result!.status == RoutingStatus.alreadySafe
                                      ? BsasColors.safeGreen.withValues(alpha: 0.15)
                                      : (_result!.status == RoutingStatus.available
                                          ? BsasColors.warningOrange.withValues(alpha: 0.15)
                                          : BsasColors.criticalRed.withValues(alpha: 0.15)),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _result!.status == RoutingStatus.alreadySafe
                                      ? Icons.check_circle_outline
                                      : (_result!.status == RoutingStatus.available
                                          ? Icons.alt_route_rounded
                                          : Icons.warning_amber_rounded),
                                  color: _result!.status == RoutingStatus.alreadySafe
                                      ? BsasColors.safeGreen
                                      : (_result!.status == RoutingStatus.available
                                          ? BsasColors.warningOrange
                                          : BsasColors.criticalRed),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: BsasSpacing.md),
                              Expanded(
                                child: Text(
                                  _result!.status == RoutingStatus.alreadySafe
                                      ? 'YOU ARE SAFE'
                                      : (_result!.status == RoutingStatus.available
                                          ? 'SAFE ROUTE FOUND'
                                          : 'NO ROUTE AVAILABLE'),
                                  style: BsasTypography.heading.copyWith(
                                    fontSize: 16,
                                    letterSpacing: 1.2,
                                    color: BsasColors.text(isDark),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: BsasSpacing.md),
                          Padding(
                            padding: const EdgeInsets.only(left: 44.0),
                            child: Text(
                              _result!.message,
                              style: BsasTypography.body.copyWith(
                                color: BsasColors.textSec(isDark),
                                height: 1.4,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: BsasSpacing.xl),

                    // Navigation Metrics if Available
                    if (_result!.status == RoutingStatus.available &&
                        _result!.totalDistanceMeters != null) ...[
                      _sectionHeader('ESCAPE CORRIDOR NAVIGATION', isDark),
                      Container(
                        padding: const EdgeInsets.all(BsasSpacing.lg),
                        decoration: BoxDecoration(
                          color: BsasColors.card(isDark),
                          borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
                          border: Border.all(color: BsasColors.border(isDark), width: 1.0),
                          boxShadow: isDark
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : [
                                  BoxShadow(
                                    color: BsasColors.lightBorder,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _navMetric(
                                isDark: isDark,
                                label: 'CORRIDOR DISTANCE',
                                value: '${_result!.totalDistanceMeters!.toStringAsFixed(1)} m',
                                icon: Icons.straighten,
                              ),
                            ),
                            Container(width: 1, height: 48, color: BsasColors.border(isDark)),
                            Expanded(
                              child: _navMetric(
                                isDark: isDark,
                                label: 'INITIAL BEARING',
                                value: _result!.initialBearing != null
                                    ? '${_result!.initialBearing!.toStringAsFixed(0)}°'
                                    : 'N/A',
                                icon: Icons.explore_outlined,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: BsasSpacing.xl),
                    ],
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(BsasSpacing.xl),
                      decoration: BoxDecoration(
                        color: BsasColors.card(isDark),
                        borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
                        border: Border.all(color: BsasColors.border(isDark), width: 1.0),
                        boxShadow: isDark
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [
                                BoxShadow(
                                  color: BsasColors.lightBorder,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(BsasSpacing.lg),
                            decoration: BoxDecoration(
                              color: (isDark ? BsasColors.radarCyan : BsasColors.primaryBlue).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.route_outlined, size: 48, color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue),
                          ),
                          const SizedBox(height: BsasSpacing.lg),
                          Text(
                            'NO ROUTE CALCULATED',
                            style: BsasTypography.heading.copyWith(
                              color: BsasColors.text(isDark),
                              fontSize: 15,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: BsasSpacing.md),
                          Text(
                            'Tap the button below to compute an obstacle-free escape route away from restricted border boundaries using deterministic A* pathfinding.',
                            style: BsasTypography.body.copyWith(
                              color: BsasColors.textSec(isDark),
                              height: 1.4,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: BsasSpacing.xl),
                  ],

                  // Calculate Route Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: BsasSpacing.lg),
                        backgroundColor: BsasColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
                        ),
                      ),
                      onPressed: _isLoading ? null : _calculateRoute,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.navigation_outlined, size: 20),
                      label: Text(
                        _isLoading ? 'CALCULATING SAFE CORRIDOR...' : 'CALCULATE SAFE ROUTE',
                        style: BsasTypography.monospace.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: BsasSpacing.xxxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BsasSpacing.md, left: BsasSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
          ),
          const SizedBox(width: BsasSpacing.sm),
          Text(
            title,
            style: BsasTypography.heading.copyWith(
              color: isDark ? BsasColors.text(isDark) : BsasColors.primaryBlue,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navMetric({
    required bool isDark,
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue),
        const SizedBox(height: BsasSpacing.sm),
        Text(
          label,
          style: BsasTypography.monospace.copyWith(
            color: BsasColors.textSec(isDark),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: BsasSpacing.xs),
        Text(
          value,
          style: BsasTypography.monospace.copyWith(
            color: BsasColors.text(isDark),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
