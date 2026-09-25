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

          return CustomScrollView(
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
                    Icon(Icons.history, color: BsasColors.radarCyan, size: 20),
                    const SizedBox(width: BsasSpacing.sm),
                    Text(
                      'AUDIT LOG',
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
                    icon: const Icon(Icons.delete_outline, color: BsasColors.criticalRed, size: 22),
                    tooltip: 'Clear Event History',
                    onPressed: () => _confirmClear(context, isDark),
                  ),
                  const SizedBox(width: BsasSpacing.xs),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        color: isDark ? BsasColors.darkBorder : BsasColors.lightBorder,
                        height: 1.0,
                      ),
                      Container(
                        height: 59.0,
                        color: BsasColors.background(isDark),
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.lg, vertical: BsasSpacing.md),
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
                    ],
                  ),
                ),
              ),
              if (events.isEmpty)
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
                          const SizedBox(height: BsasSpacing.xl),
                          Text(
                            'NO LOGS FOUND',
                            style: BsasTypography.heading.copyWith(
                              color: BsasColors.textSec(isDark),
                              letterSpacing: 1.5,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: BsasSpacing.sm),
                          Text(
                            'Boundary crossings, proximity alerts, and geofence evaluations will automatically be logged and persisted in your local SQLite store.',
                            style: BsasTypography.body.copyWith(
                              color: BsasColors.textMut(isDark),
                              height: 1.5,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.lg, vertical: BsasSpacing.md),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, idx) {
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

                        return Container(
                          margin: const EdgeInsets.only(bottom: BsasSpacing.md),
                          decoration: BoxDecoration(
                            color: BsasColors.card(isDark),
                            borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.5),
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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.md, vertical: BsasSpacing.sm),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  border: Border(bottom: BorderSide(color: statusColor.withValues(alpha: 0.2))),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: statusColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: BsasSpacing.sm),
                                        Text(
                                          event.eventType.toUpperCase(),
                                          style: BsasTypography.monospace.copyWith(
                                            color: statusColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
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
                              ),
                              Padding(
                                padding: const EdgeInsets.all(BsasSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.alertState.isNotEmpty ? event.alertState : 'Geofence State Change',
                                      style: BsasTypography.title.copyWith(
                                        color: BsasColors.text(isDark),
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: BsasSpacing.xs),
                                    Text(
                                      'Zone: ${event.zone}',
                                      style: BsasTypography.monospace.copyWith(
                                        color: BsasColors.textSec(isDark),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Loc : ${event.latitude.toStringAsFixed(5)}, ${event.longitude.toStringAsFixed(5)}',
                                      style: BsasTypography.monospace.copyWith(
                                        color: BsasColors.textSec(isDark),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: BsasSpacing.md),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            'RISK: ${event.riskState}',
                                            style: BsasTypography.monospace.copyWith(
                                              color: statusColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
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
                                              event.synced ? 'SYNCED' : 'LOCAL',
                                              style: BsasTypography.monospace.copyWith(
                                                fontSize: 10,
                                                color: event.synced ? BsasColors.safeGreen : BsasColors.textMut(isDark),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      childCount: events.length,
                    ),
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
          horizontal: BsasSpacing.lg,
          vertical: BsasSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? BsasColors.primaryBlue.withValues(alpha: 0.25) : BsasColors.primaryBlue)
              : BsasColors.card(isDark),
          borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
          border: Border.all(
            color: isSelected
                ? (isDark ? BsasColors.radarCyan : BsasColors.primaryBlue)
                : BsasColors.border(isDark),
          ),
        ),
        child: Center(
          child: Text(
            label.toUpperCase(),
            style: BsasTypography.monospace.copyWith(
              color: isSelected
                  ? (isDark ? BsasColors.radarCyan : Colors.white)
                  : BsasColors.textSec(isDark),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
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
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: BsasColors.criticalRed),
            const SizedBox(width: BsasSpacing.sm),
            Text(
              'PURGE LOGS?',
              style: BsasTypography.heading.copyWith(
                color: BsasColors.criticalRed,
                letterSpacing: 1.0,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          'This permanently removes all local incident and boundary crossing audit logs from your on-device SQLite database. This action cannot be undone.',
          style: BsasTypography.body.copyWith(
            color: BsasColors.textSec(isDark),
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: BsasSpacing.lg, vertical: BsasSpacing.md),
        actions: [
          TextButton(
            child: Text(
              'CANCEL',
              style: BsasTypography.label.copyWith(color: BsasColors.textSec(isDark)),
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
              elevation: 0,
            ),
            child: Text('PURGE DATABASE', style: BsasTypography.label.copyWith(letterSpacing: 0.5)),
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
