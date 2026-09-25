import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_spacing.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final message = event.message;
    final result = event.result;
    final isCritical = message.severity == AlertSeverity.critical;
    final time = event.timestamp ?? DateTime.now();
    final timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(time);
    final delivery = event.deliveryStatus;
    final severityColor = isCritical ? BsasColors.criticalRed : BsasColors.warningOrange;

    return Scaffold(
      key: const Key('screen-alert-details'),
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
                Icon(
                  isCritical ? Icons.warning_amber_rounded : Icons.info_outline,
                  color: severityColor,
                  size: 20,
                ),
                const SizedBox(width: BsasSpacing.sm),
                Text(
                  'INCIDENT REPORT',
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
                  // Header Card with Severity Banner
                  Container(
                    padding: const EdgeInsets.all(BsasSpacing.lg),
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: isDark ? 0.08 : 0.05),
                      borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
                      border: Border.all(
                        color: severityColor.withValues(alpha: 0.3),
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.sm, vertical: 4),
                              decoration: BoxDecoration(
                                color: severityColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: severityColor.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                message.severity.label.toUpperCase(),
                                style: BsasTypography.monospace.copyWith(
                                  color: severityColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Text(
                              timeStr,
                              style: BsasTypography.monospace.copyWith(
                                fontSize: 11,
                                color: BsasColors.textSec(isDark),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: BsasSpacing.md),
                        Text(
                          message.title,
                          style: BsasTypography.heading.copyWith(
                            fontSize: 16,
                            color: BsasColors.text(isDark),
                          ),
                        ),
                        const SizedBox(height: BsasSpacing.sm),
                        Text(
                          message.message,
                          style: BsasTypography.body.copyWith(
                            color: BsasColors.text(isDark),
                            height: 1.45,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: BsasSpacing.xl),

                  // Geospatial Context Section
                  _sectionHeader('GEOSPATIAL INCIDENT TELEMETRY', isDark),
                  _card(
                    isDark: isDark,
                    children: [
                      _tile(
                        isDark: isDark,
                        icon: Icons.shield_outlined,
                        title: 'GEOFENCE ASSESSMENT',
                        trailing: result.state.name.toUpperCase(),
                        trailingColor: severityColor,
                      ),
                      Divider(height: 1, color: BsasColors.border(isDark)),
                      _tile(
                        isDark: isDark,
                        icon: Icons.near_me_outlined,
                        title: 'SECTOR / PERIMETER',
                        trailing: result.nearestBoundary?.name ?? 'PERIMETER BUFFER',
                      ),
                      Divider(height: 1, color: BsasColors.border(isDark)),
                      _tile(
                        isDark: isDark,
                        icon: Icons.straighten,
                        title: 'DISTANCE TO DEMARCATION',
                        trailing: result.distanceToBoundaryMeters != null
                            ? '${result.distanceToBoundaryMeters!.toStringAsFixed(1)} M'
                            : 'INSIDE ZONE',
                      ),
                      if (result.directionToBoundaryDegrees != null) ...[
                        Divider(height: 1, color: BsasColors.border(isDark)),
                        _tile(
                          isDark: isDark,
                          icon: Icons.navigation_outlined,
                          title: 'PERIMETER BEARING',
                          trailing: '${result.directionToBoundaryDegrees!.toStringAsFixed(0)}°',
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: BsasSpacing.xl),

                  // Hardware Dispatch Audit Section
                  _sectionHeader('HARDWARE DISPATCH VERIFICATION', isDark),
                  _card(
                    isDark: isDark,
                    children: [
                      _dispatchTile(
                        isDark: isDark,
                        channel: 'ACOUSTIC SIREN (AUDIO)',
                        dispatched: delivery.soundPlayed,
                      ),
                      Divider(height: 1, color: BsasColors.border(isDark)),
                      _dispatchTile(
                        isDark: isDark,
                        channel: 'TEXT-TO-SPEECH VOICE (TTS)',
                        dispatched: delivery.voiceSpoken,
                      ),
                      Divider(height: 1, color: BsasColors.border(isDark)),
                      _dispatchTile(
                        isDark: isDark,
                        channel: 'HAPTIC TACTILE PULSE',
                        dispatched: delivery.vibrated,
                      ),
                      Divider(height: 1, color: BsasColors.border(isDark)),
                      _dispatchTile(
                        isDark: isDark,
                        channel: 'ANDROID SYSTEM NOTIFICATION',
                        dispatched: delivery.notificationPosted,
                      ),
                    ],
                  ),
                  const SizedBox(height: BsasSpacing.xxl),

                  // Emergency Actions
                  Row(
                    children: [
                      if (onViewOnMap != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: BsasSpacing.md),
                              side: BorderSide(color: BsasColors.radarCyan.withValues(alpha: 0.5)),
                              backgroundColor: BsasColors.radarCyan.withValues(alpha: 0.05),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              onViewOnMap!();
                            },
                            icon: const Icon(Icons.map_outlined, color: BsasColors.radarCyan, size: 20),
                            label: Text(
                              'VIEW ON MAP',
                              style: BsasTypography.monospace.copyWith(
                                color: BsasColors.radarCyan,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      if (onViewOnMap != null && onSafeRoute != null)
                        const SizedBox(width: BsasSpacing.md),
                      if (onSafeRoute != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: BsasSpacing.md),
                              backgroundColor: isCritical ? BsasColors.criticalRed : BsasColors.warningOrange,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              onSafeRoute!();
                            },
                            icon: const Icon(Icons.alt_route_rounded, size: 20),
                            label: Text(
                              'SAFE ESCAPE ROUTE',
                              style: BsasTypography.monospace.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: BsasSpacing.xl),
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

  Widget _card({required bool isDark, required List<Widget> children}) {
    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _tile({
    required bool isDark,
    required IconData icon,
    required String title,
    required String trailing,
    Color? trailingColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.md, vertical: BsasSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue),
          const SizedBox(width: BsasSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: BsasTypography.monospace.copyWith(
                color: BsasColors.textSec(isDark),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            trailing,
            style: BsasTypography.monospace.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: trailingColor ?? BsasColors.text(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dispatchTile({
    required bool isDark,
    required String channel,
    required bool dispatched,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.md, vertical: BsasSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            channel,
            style: BsasTypography.monospace.copyWith(
              color: BsasColors.text(isDark),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Row(
            children: [
              Icon(
                dispatched ? Icons.check_circle_rounded : Icons.cancel_outlined,
                size: 16,
                color: dispatched ? BsasColors.safeGreen : BsasColors.offlineSteel,
              ),
              const SizedBox(width: 6),
              Text(
                dispatched ? 'DISPATCHED' : 'SUPPRESSED',
                style: BsasTypography.monospace.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
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
