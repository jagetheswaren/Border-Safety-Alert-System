import 'package:flutter/material.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_typography.dart';
import '../core/widgets/status_badge.dart';
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
    final history = alertService.history;

    return Scaffold(
      key: const Key('screen-history'), // Preserves test key compatibility
      backgroundColor: BsasColors.darkBackground,
      appBar: AppBar(
        backgroundColor: BsasColors.darkSurface,
        title: const Text('Alert History & Timeline', style: BsasTypography.headline),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long, color: BsasColors.radarCyan),
            tooltip: 'View SQLite Event Logs',
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
        ],
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline, size: 64, color: BsasColors.safeGreen),
                  const SizedBox(height: 16),
                  const Text('No Active Alerts', style: BsasTypography.title),
                  const SizedBox(height: 8),
                  Text(
                    'All boundary sectors report normal safety state.',
                    style: BsasTypography.caption.copyWith(color: BsasColors.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, idx) {
                final event = history[idx];
                final isCritical = event.message.severity == AlertSeverity.critical;
                final time = event.timestamp ?? DateTime.now();
                final timeStr =
                    '${time.hour.toString().padLeft(2, "0")}:${time.minute.toString().padLeft(2, "0")}:${time.second.toString().padLeft(2, "0")}';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: BsasColors.darkSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isCritical ? BsasColors.criticalRed : BsasColors.warningOrange,
                      width: 1.5,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
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
                      padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isCritical ? BsasColors.criticalRed : BsasColors.warningOrange,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                event.message.severity.label.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(timeStr, style: BsasTypography.monoDiagnostics),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(event.message.message, style: BsasTypography.title.copyWith(fontSize: 15)),
                        const SizedBox(height: 6),
                        Text(
                          'Zone: ${event.result.state.name.toUpperCase()} • Nearest: ${event.result.nearestBoundary?.name ?? "Sector Perimeter"}',
                          style: BsasTypography.caption.copyWith(color: BsasColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: BsasColors.darkBorder),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _channelCheck('Sound', event.deliveryStatus.soundPlayed),
                            _channelCheck('Vibration', event.deliveryStatus.vibrationPlayed),
                            _channelCheck('TTS', event.deliveryStatus.ttsPlayed),
                            _channelCheck('Notification', event.deliveryStatus.notificationPosted),
                          ],
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

  Widget _channelCheck(String channel, bool executed) {
    return Row(
      children: [
        Icon(
          executed ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 14,
          color: executed ? BsasColors.safeGreen : BsasColors.textMuted,
        ),
        const SizedBox(width: 4),
        Text(
          channel,
          style: TextStyle(
            fontSize: 11,
            color: executed ? Colors.white : BsasColors.textMuted,
            fontWeight: executed ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
