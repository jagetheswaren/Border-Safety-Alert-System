import 'package:flutter/material.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_spacing.dart';
import '../core/theme/bsas_typography.dart';
import '../services/local_event_store.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, this.eventStore});

  final LocalEventStore? eventStore;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final LocalEventStore _store;
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _store = widget.eventStore ?? LocalEventStore();
    _store.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: const Key('screen-history'),
      backgroundColor: BsasColors.background(isDark),
      appBar: AppBar(
        backgroundColor: BsasColors.surface(isDark),
        title: Text(
          'Event History & Audit Log',
          style: BsasTypography.heading.copyWith(color: BsasColors.text(isDark)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: BsasColors.criticalRed),
            tooltip: 'Clear Event History',
            onPressed: () => _confirmClear(context, isDark),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final all = _store.allEvents;
          final events = all.where((e) {
            if (_selectedFilter == 'CRITICAL') {
              return e.riskState.toUpperCase().contains('CRITICAL') ||
                  e.eventType.toUpperCase().contains('CRITICAL');
            }
            if (_selectedFilter == 'WARNING') {
              return e.riskState.toUpperCase().contains('WARN') ||
                  e.eventType.toUpperCase().contains('WARN');
            }
            if (_selectedFilter == 'UNSYNCED') {
              return !e.synced;
            }
            return true;
          }).toList();

          return Column(
            children: [
              // Filter Chips Bar
              Container(
                color: BsasColors.surface(isDark),
                padding: const EdgeInsets.symmetric(
                  horizontal: BsasSpacing.lg,
                  vertical: BsasSpacing.md,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('ALL', 'All (${all.length})', isDark),
                      const SizedBox(width: BsasSpacing.sm),
                      _filterChip('CRITICAL', 'Critical', isDark),
                      const SizedBox(width: BsasSpacing.sm),
                      _filterChip('WARNING', 'Warning', isDark),
                      const SizedBox(width: BsasSpacing.sm),
                      _filterChip('UNSYNCED', 'Unsynced (${_store.pendingCount})', isDark),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: BsasColors.border(isDark)),

              // Event List or Empty State
              Expanded(
                child: events.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(BsasSpacing.xxxl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(BsasSpacing.xl),
                                decoration: BoxDecoration(
                                  color: isDark ? BsasColors.darkCard : BsasColors.lightSurface,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: BsasColors.border(isDark)),
                                ),
                                child: Icon(
                                  Icons.history_toggle_off,
                                  size: 48,
                                  color: BsasColors.textMut(isDark),
                                ),
                              ),
                              const SizedBox(height: BsasSpacing.lg),
                              Text(
                                'No Safety Events Logged',
                                style: BsasTypography.title.copyWith(
                                  color: BsasColors.text(isDark),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: BsasSpacing.sm),
                              Text(
                                'Boundary crossings, proximity alerts, and geofence evaluations will automatically be logged and persisted in your local SQLite store.',
                                style: BsasTypography.caption.copyWith(
                                  color: BsasColors.textSec(isDark),
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(BsasSpacing.lg),
                        itemCount: events.length,
                        itemBuilder: (context, idx) {
                          final event = events[idx];
                          final isCritical = event.riskState.toUpperCase().contains('CRITICAL') ||
                              event.eventType.toUpperCase().contains('CRITICAL');
                          final isWarning = event.riskState.toUpperCase().contains('WARN') ||
                              event.eventType.toUpperCase().contains('WARN');
                          final statusColor = isCritical
                              ? BsasColors.criticalRed
                              : (isWarning ? BsasColors.warningOrange : BsasColors.safeGreen);

                          final time = event.timestamp;
                          final timeStr =
                              '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
                              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';

                          return Card(
                            margin: const EdgeInsets.only(bottom: BsasSpacing.md),
                            color: BsasColors.card(isDark),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
                              side: BorderSide(
                                color: isCritical
                                    ? BsasColors.criticalRed.withValues(alpha: 0.6)
                                    : BsasColors.border(isDark),
                                width: isCritical ? 1.5 : 1.0,
                              ),
                            ),
                            elevation: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(BsasSpacing.lg),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: BsasSpacing.sm,
                                          vertical: BsasSpacing.xs,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                                        ),
                                        child: Text(
                                          event.eventType.toUpperCase(),
                                          style: BsasTypography.label.copyWith(
                                            color: statusColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        timeStr,
                                        style: BsasTypography.monospace.copyWith(
                                          color: BsasColors.textSec(isDark),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: BsasSpacing.sm),
                                  Text(
                                    event.alertState.isNotEmpty ? event.alertState : 'Geofence State Change',
                                    style: BsasTypography.title.copyWith(
                                      color: BsasColors.text(isDark),
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: BsasSpacing.xs),
                                  Text(
                                    'Zone: ${event.zone} • Lat/Lon: ${event.latitude.toStringAsFixed(5)}, ${event.longitude.toStringAsFixed(5)}',
                                    style: BsasTypography.caption.copyWith(
                                      color: BsasColors.textSec(isDark),
                                    ),
                                  ),
                                  const SizedBox(height: BsasSpacing.md),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: statusColor,
                                            ),
                                          ),
                                          const SizedBox(width: BsasSpacing.xs),
                                          Text(
                                            'Risk State: ${event.riskState}',
                                            style: BsasTypography.monospace.copyWith(
                                              color: statusColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            event.synced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                                            size: 14,
                                            color: event.synced ? BsasColors.safeGreen : BsasColors.textMut(isDark),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            event.synced ? 'SYNCED' : 'LOCAL ONLY',
                                            style: BsasTypography.caption.copyWith(
                                              fontSize: 10,
                                              color: event.synced ? BsasColors.safeGreen : BsasColors.textMut(isDark),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterChip(String filterId, String label, bool isDark) {
    final isSelected = _selectedFilter == filterId;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filterId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: BsasSpacing.md,
          vertical: BsasSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? BsasColors.primaryBlue.withValues(alpha: 0.25) : BsasColors.primaryBlue)
              : (isDark ? BsasColors.darkCard : BsasColors.lightBackground),
          borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
          border: Border.all(
            color: isSelected
                ? (isDark ? BsasColors.radarCyan : BsasColors.primaryBlue)
                : BsasColors.border(isDark),
          ),
        ),
        child: Text(
          label,
          style: BsasTypography.caption.copyWith(
            color: isSelected
                ? (isDark ? BsasColors.radarCyan : Colors.white)
                : BsasColors.textSec(isDark),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BsasColors.card(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
          side: BorderSide(color: BsasColors.border(isDark)),
        ),
        title: Text(
          'Clear All Event Logs?',
          style: BsasTypography.title.copyWith(
            color: BsasColors.text(isDark),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This permanently removes all local incident and boundary crossing audit logs from your on-device SQLite database.',
          style: BsasTypography.body.copyWith(
            color: BsasColors.textSec(isDark),
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              'Cancel',
              style: TextStyle(color: BsasColors.textSec(isDark)),
            ),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: BsasColors.criticalRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
              ),
            ),
            child: const Text('Clear'),
            onPressed: () {
              Navigator.pop(ctx);
              _store.clearEvents();
            },
          ),
        ],
      ),
    );
  }
}
