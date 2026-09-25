import 'package:flutter/material.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_spacing.dart';
import '../core/theme/bsas_typography.dart';
import '../models/alert_severity.dart';
import '../services/alert_service.dart';
import '../services/local_event_store.dart';
import 'alert_details_screen.dart';
import 'history_screen.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({
    super.key,
    required this.alertService,
    this.eventStore,
    this.onViewOnMap,
    this.onSafeRoute,
  });

  final AlertService alertService;
  final LocalEventStore? eventStore;
  final VoidCallback? onViewOnMap;
  final VoidCallback? onSafeRoute;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final history = alertService.history;

    return Scaffold(
      key: const Key('screen-history'), // Preserves test key compatibility
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
                Icon(Icons.warning_amber_rounded, color: history.isNotEmpty ? BsasColors.warningOrange : BsasColors.safeGreen, size: 20),
                const SizedBox(width: BsasSpacing.sm),
                Text(
                  'ACTIVE ALERTS',
                  style: BsasTypography.heading.copyWith(
                    color: BsasColors.text(isDark),
                    letterSpacing: 1.2,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.receipt_long_outlined, color: BsasColors.radarCyan, size: 22),
                tooltip: 'SQLite Event Store',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HistoryScreen(eventStore: eventStore),
                    ),
                  );
                },
              ),
              const SizedBox(width: BsasSpacing.xs),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(
                color: isDark ? BsasColors.darkBorder : BsasColors.lightBorder,
                height: 1.0,
              ),
            ),
          ),
          if (history.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(BsasSpacing.xxxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(BsasSpacing.xxl),
                        decoration: BoxDecoration(
                          color: BsasColors.safeGreen.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: BsasColors.safeGreen.withValues(alpha: 0.3), width: 1.5),
                        ),
                        child: const Icon(Icons.verified_user_outlined, size: 64, color: BsasColors.safeGreen),
                      ),
                      const SizedBox(height: BsasSpacing.xl),
                      Text(
                        '0 ACTIVE THREATS',
                        style: BsasTypography.heading.copyWith(
                          color: BsasColors.safeGreen,
                          letterSpacing: 1.5,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: BsasSpacing.sm),
                      Text(
                        'All configured boundary perimeters report safe civilian transit status.\nSensors online.',
                        style: BsasTypography.body.copyWith(
                          color: isDark ? BsasColors.textLightSecondary : BsasColors.textDarkSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: BsasSpacing.xl),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: isDark ? BsasColors.darkBorder : BsasColors.lightBorder),
                          foregroundColor: BsasColors.text(isDark),
                          padding: const EdgeInsets.symmetric(vertical: BsasSpacing.md, horizontal: BsasSpacing.xl),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
                          ),
                        ),
                        icon: const Icon(Icons.history, size: 18),
                        label: const Text('View Historical Events', style: TextStyle(letterSpacing: 0.5)),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => HistoryScreen(eventStore: eventStore),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: BsasSpacing.screenMargin,
                vertical: BsasSpacing.md,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, idx) {
                    final event = history[idx];
                    final isCritical = event.message.severity == AlertSeverity.critical;
                    final time = event.timestamp ?? DateTime.now();
                    final timeStr =
                        '${time.hour.toString().padLeft(2, "0")}:${time.minute.toString().padLeft(2, "0")}:${time.second.toString().padLeft(2, "0")}';
                    final severityColor = isCritical ? BsasColors.criticalRed : BsasColors.warningOrange;

                    return Container(
                      margin: const EdgeInsets.only(bottom: BsasSpacing.md),
                      decoration: BoxDecoration(
                        color: BsasColors.card(isDark),
                        borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
                        border: Border.all(
                          color: severityColor.withValues(alpha: 0.6),
                          width: 1.2,
                        ),
                        boxShadow: isDark
                            ? [
                                BoxShadow(
                                  color: severityColor.withValues(alpha: 0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [
                                BoxShadow(
                                  color: severityColor.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AlertDetailsScreen(
                                event: event,
                                onViewOnMap: onViewOnMap,
                                onSafeRoute: onSafeRoute,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.md, vertical: BsasSpacing.sm),
                              decoration: BoxDecoration(
                                color: severityColor.withValues(alpha: 0.1),
                                border: Border(bottom: BorderSide(color: severityColor.withValues(alpha: 0.2))),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        isCritical ? Icons.dangerous_outlined : Icons.warning_amber_rounded,
                                        color: severityColor,
                                        size: 16,
                                      ),
                                      const SizedBox(width: BsasSpacing.xs),
                                      Text(
                                        isCritical ? 'CRITICAL BREACH' : 'PROXIMITY WARNING',
                                        style: BsasTypography.monospace.copyWith(
                                          color: severityColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    timeStr,
                                    style: BsasTypography.monospace.copyWith(
                                      color: BsasColors.textSec(isDark),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(BsasSpacing.md),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event.message.title,
                                          style: BsasTypography.title.copyWith(fontSize: 15),
                                        ),
                                        const SizedBox(height: BsasSpacing.xs),
                                        Text(
                                          event.message.body,
                                          style: BsasTypography.body.copyWith(
                                            fontSize: 13,
                                            color: isDark ? BsasColors.textLightSecondary : BsasColors.textDarkSecondary,
                                            height: 1.4,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: BsasSpacing.md),
                                        Row(
                                          children: [
                                            _channelBadge('AUDIO', isDark),
                                            const SizedBox(width: 4),
                                            _channelBadge('HAPTIC', isDark),
                                            const SizedBox(width: 4),
                                            _channelBadge('TTS', isDark),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: BsasSpacing.md),
                                  Container(
                                    padding: const EdgeInsets.all(BsasSpacing.sm),
                                    decoration: BoxDecoration(
                                      color: isDark ? BsasColors.darkBackground : BsasColors.lightBackground,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.chevron_right, size: 20, color: BsasColors.textSec(isDark)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: history.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _channelBadge(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: (isDark ? BsasColors.primaryBlue : BsasColors.primaryBlueLight).withValues(alpha: 0.15),
        border: Border.all(color: (isDark ? BsasColors.primaryBlue : BsasColors.primaryBlueLight).withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
        ),
      ),
    );
  }
}
