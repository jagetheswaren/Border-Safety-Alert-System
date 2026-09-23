import 'package:flutter/material.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_spacing.dart';
import '../core/theme/bsas_typography.dart';
import '../core/widgets/status_badge.dart';
import '../models/alert_severity.dart';
import '../services/alert_service.dart';
import '../services/local_event_store.dart';
import 'alert_details_screen.dart';
import 'history_screen.dart';

/// Redesigned Alerts Screen with clean timeline, delivery channel badges, and empty states.
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
      appBar: AppBar(
        title: const Text('Alert Timeline', style: BsasTypography.heading),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined, size: 20),
            tooltip: 'SQLite Event Store',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => HistoryScreen(eventStore: eventStore),
                ),
              );
            },
          ),
          StatusBadge(
            label: '${history.length} RECORDED',
            state: history.isEmpty ? StatusState.ready : StatusState.warning,
          ),
          const SizedBox(width: BsasSpacing.xs),
        ],
      ),
      body: history.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(BsasSpacing.xxxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(BsasSpacing.lg),
                      decoration: BoxDecoration(
                        color: BsasColors.safeGreen.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_outlined, size: 48, color: BsasColors.safeGreen),
                    ),
                    const SizedBox(height: BsasSpacing.lg),
                    Text(
                      'No Active Alerts',
                      style: BsasTypography.title.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: BsasSpacing.xs),
                    Text(
                      'All configured boundary perimeters report safe civilian transit status.',
                      style: BsasTypography.body.copyWith(
                        color: isDark ? BsasColors.textLightSecondary : BsasColors.textDarkSecondary,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: BsasSpacing.screenMargin,
                vertical: BsasSpacing.md,
              ),
              itemCount: history.length,
              itemBuilder: (context, idx) {
                final event = history[idx];
                final isCritical = event.message.severity == AlertSeverity.critical;
                final time = event.timestamp ?? DateTime.now();
                final timeStr =
                    '${time.hour.toString().padLeft(2, "0")}:${time.minute.toString().padLeft(2, "0")}:${time.second.toString().padLeft(2, "0")}';
                final severityColor = isCritical ? BsasColors.criticalRed : BsasColors.warningOrange;

                return Container(
                  margin: const EdgeInsets.only(bottom: BsasSpacing.sm),
                  decoration: BoxDecoration(
                    color: isDark ? BsasColors.darkCard : BsasColors.lightCard,
                    borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
                    border: Border.all(
                      color: severityColor.withValues(alpha: 0.8),
                      width: 1.2,
                    ),
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
                    child: Padding(
                      padding: BsasSpacing.cardInsets,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(BsasSpacing.sm),
                            decoration: BoxDecoration(
                              color: severityColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
                            ),
                            child: Icon(
                              isCritical ? Icons.dangerous_outlined : Icons.warning_amber_rounded,
                              color: severityColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: BsasSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      event.message.title,
                                      style: BsasTypography.title.copyWith(fontSize: 14),
                                    ),
                                    Text(
                                      timeStr,
                                      style: BsasTypography.caption.copyWith(fontSize: 11),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: BsasSpacing.xs),
                                Text(
                                  event.message.body,
                                  style: BsasTypography.body.copyWith(
                                    fontSize: 12,
                                    color: isDark ? BsasColors.textLightSecondary : BsasColors.textDarkSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: BsasSpacing.sm),
                                Row(
                                  children: [
                                    _channelBadge('AUDIO'),
                                    const SizedBox(width: 4),
                                    _channelBadge('HAPTIC'),
                                    const SizedBox(width: 4),
                                    _channelBadge('TTS'),
                                    const Spacer(),
                                    const Icon(Icons.chevron_right, size: 18, color: BsasColors.primaryBlue),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _channelBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: BsasColors.primaryBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: BsasColors.primaryBlue),
      ),
    );
  }
}
