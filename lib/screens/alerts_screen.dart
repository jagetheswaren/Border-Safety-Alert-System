import 'package:flutter/material.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_spacing.dart';
import '../core/theme/bsas_typography.dart';
import '../core/widgets/bsas_card.dart';
import '../core/widgets/bsas_electric_border.dart';
import '../core/widgets/bsas_pill_nav.dart';
import '../core/widgets/bsas_slide_button.dart';
import '../core/widgets/bsas_states.dart';
import '../models/alert_severity.dart';
import '../services/alert_service.dart';
import '../services/local_event_store.dart';
import 'alert_details_screen.dart';
import 'history_screen.dart';

/// Redesigned Alerts Screen with React Bits inspired motion & tactile acknowledge action.
class AlertsScreen extends StatefulWidget {
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
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  int _selectedFilterIndex = 0;
  final Set<String> _acknowledgedAlerts = {};

  final List<String> _filters = const ['ALL', 'CRITICAL', 'WARNING', 'CAUTION'];

  @override
  Widget build(BuildContext context) {
    final allHistory = widget.alertService.history;

    // Apply severity filter
    final filteredHistory = allHistory.where((event) {
      if (_selectedFilterIndex == 0) return true;
      final filter = _filters[_selectedFilterIndex];
      if (filter == 'CRITICAL') {
        return event.message.severity == AlertSeverity.critical;
      }
      if (filter == 'WARNING') {
        return event.message.severity == AlertSeverity.warning;
      }
      if (filter == 'CAUTION') {
        return event.message.severity == AlertSeverity.caution;
      }
      return true;
    }).toList();

    return Scaffold(
      key: const Key('screen-history'), // Preserves test key compatibility
      backgroundColor: BsasColors.darkBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: BsasColors.darkBackground,
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: BsasColors.textLightPrimary),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
            title: Row(
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  color: allHistory.isNotEmpty
                      ? BsasColors.warningOrange
                      : BsasColors.safeGreen,
                  size: 20,
                ),
                const SizedBox(width: BsasSpacing.sm),
                Text(
                  'SAFETY ALERTS',
                  style: BsasTypography.heading.copyWith(
                    color: BsasColors.textLightPrimary,
                    letterSpacing: 1.2,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.receipt_long_outlined,
                  color: BsasColors.primaryBlueLight,
                  size: 22,
                ),
                tooltip: 'SQLite Event Store',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HistoryScreen(eventStore: widget.eventStore),
                    ),
                  );
                },
              ),
              const SizedBox(width: BsasSpacing.xs),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: BSASPillNav(
                  items: _filters,
                  selectedIndex: _selectedFilterIndex,
                  onChanged: (idx) => setState(() => _selectedFilterIndex = idx),
                ),
              ),
            ),
          ),
          if (filteredHistory.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: BSASEmptyState(
                title: 'NO ACTIVE ALERTS',
                description: _selectedFilterIndex == 0
                    ? 'All monitored perimeters report safe civilian transit status.\nReal-time sensors are operational.'
                    : 'No active threats matching ${_filters[_selectedFilterIndex]} severity filter.',
                icon: Icons.verified_user_outlined,
                actionLabel: 'VIEW EVENT LOGS',
                onAction: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HistoryScreen(eventStore: widget.eventStore),
                    ),
                  );
                },
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
                    final event = filteredHistory[idx];
                    final isCritical =
                        event.message.severity == AlertSeverity.critical;
                    final time = event.timestamp ?? DateTime.now();
                    final timeStr =
                        '${time.hour.toString().padLeft(2, "0")}:${time.minute.toString().padLeft(2, "0")}:${time.second.toString().padLeft(2, "0")}';
                    final severityColor = isCritical
                        ? BsasColors.criticalRed
                        : BsasColors.warningOrange;

                    final alertId =
                        '${event.message.title}_${time.millisecondsSinceEpoch}';
                    final isAcknowledged =
                        _acknowledgedAlerts.contains(alertId);

                    return Container(
                      margin: const EdgeInsets.only(bottom: BsasSpacing.md),
                      child: BSASElectricBorder(
                        isActive: isCritical && !isAcknowledged,
                        color: BsasColors.criticalRed,
                        child: BSASCard(
                          backgroundColor: BsasColors.darkSurface,
                          borderColor: severityColor.withValues(alpha: 0.5),
                          padding: EdgeInsets.zero,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AlertDetailsScreen(
                                  event: event,
                                  onViewOnMap: widget.onViewOnMap,
                                  onSafeRoute: widget.onSafeRoute,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Severity ribbon
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: BsasSpacing.md,
                                  vertical: BsasSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: severityColor.withValues(alpha: 0.12),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: severityColor.withValues(alpha: 0.25),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          isCritical
                                              ? Icons.dangerous_outlined
                                              : Icons.warning_amber_rounded,
                                          color: severityColor,
                                          size: 16,
                                        ),
                                        const SizedBox(width: BsasSpacing.xs),
                                        Text(
                                          isCritical
                                              ? 'CRITICAL PERIMETER BREACH'
                                              : 'PROXIMITY WARNING',
                                          style: BsasTypography.monospace.copyWith(
                                            color: severityColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      timeStr,
                                      style: BsasTypography.monospace.copyWith(
                                        color: BsasColors.textLightMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Alert Body
                              Padding(
                                padding: const EdgeInsets.all(BsasSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.message.title,
                                      style: BsasTypography.title.copyWith(
                                        fontSize: 15,
                                        color: BsasColors.textLightPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      event.message.body,
                                      style: BsasTypography.body.copyWith(
                                        fontSize: 13,
                                        color: BsasColors.textLightSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Channels & Acknowledge Action (Section 37)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            _channelBadge('AUDIO'),
                                            const SizedBox(width: 4),
                                            _channelBadge('HAPTIC'),
                                            const SizedBox(width: 4),
                                            _channelBadge('TTS'),
                                          ],
                                        ),
                                        if (isAcknowledged)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF064E3B),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: const Color(0xFF10B981)
                                                    .withValues(alpha: 0.5),
                                              ),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.check_circle_outline,
                                                  size: 13,
                                                  color: Color(0xFF10B981),
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'ACKNOWLEDGED',
                                                  style: TextStyle(
                                                    color: Color(0xFF10B981),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          SizedBox(
                                            height: 32,
                                            child: BSASSlideButton(
                                              label: 'ACKNOWLEDGE',
                                              isFullWidth: false,
                                              height: 32,
                                              primaryColor: severityColor,
                                              onPressed: () {
                                                setState(() {
                                                  _acknowledgedAlerts
                                                      .add(alertId);
                                                });
                                              },
                                            ),
                                          ),
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
                  childCount: filteredHistory.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _channelBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: BsasColors.primaryBlue.withValues(alpha: 0.15),
        border: Border.all(
          color: BsasColors.primaryBlueLight.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: BsasColors.primaryBlueLight,
        ),
      ),
    );
  }
}
