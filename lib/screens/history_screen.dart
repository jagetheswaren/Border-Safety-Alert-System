import 'package:flutter/material.dart';

import '../core/theme/bsas_colors.dart';
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
    return Scaffold(
      key: const Key('screen-history'),
      backgroundColor: BsasColors.darkBackground,
      appBar: AppBar(
        backgroundColor: BsasColors.darkSurface,
        title: const Text('Event History & Audit Log', style: BsasTypography.headline),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: BsasColors.criticalRed),
            tooltip: 'Clear Event History',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: BsasColors.darkSurface,
                  title: const Text('Clear All Event Logs?', style: TextStyle(color: Colors.white)),
                  content: const Text(
                    'This permanently removes all local incident and boundary crossing audit logs.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: BsasColors.criticalRed),
                      child: const Text('Clear', style: TextStyle(color: Colors.white)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _store.clearEvents();
                      },
                    ),
                  ],
                ),
              );
            },
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
              // Filter Chips
              Container(
                color: BsasColors.darkSurface,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    _filterChip('ALL', 'All (${all.length})'),
                    const SizedBox(width: 8),
                    _filterChip('CRITICAL', 'Critical'),
                    const SizedBox(width: 8),
                    _filterChip('WARNING', 'Warning'),
                    const SizedBox(width: 8),
                    _filterChip('UNSYNCED', 'Unsynced (${_store.pendingCount})'),
                  ],
                ),
              ),

              // Event List or Empty State
              Expanded(
                child: events.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.history_toggle_off, size: 64, color: BsasColors.textMuted),
                              const SizedBox(height: 16),
                              const Text('No Safety Events Logged', style: BsasTypography.title),
                              const SizedBox(height: 8),
                              Text(
                                'Boundary crossings, cautionary proximity warnings, and geofence evaluations will automatically be logged and persisted here in SQLite.',
                                style: BsasTypography.caption.copyWith(color: BsasColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: events.length,
                        itemBuilder: (context, idx) {
                          final event = events[idx];
                          final isCritical = event.riskState.toUpperCase().contains('CRITICAL') ||
                              event.eventType.toUpperCase().contains('CRITICAL');
                          final time = event.timestamp;
                          final timeStr =
                              '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
                              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: BsasColors.darkSurface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isCritical ? BsasColors.criticalRed : BsasColors.darkBorder,
                                width: isCritical ? 1.5 : 1.0,
                              ),
                            ),
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
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          event.eventType.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      Text(timeStr, style: BsasTypography.monoDiagnostics.copyWith(fontSize: 11)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    event.alertState.isNotEmpty ? event.alertState : 'Geofence State Change',
                                    style: BsasTypography.title.copyWith(fontSize: 15),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Zone: ${event.zone} • Lat/Lon: ${event.latitude.toStringAsFixed(5)}, ${event.longitude.toStringAsFixed(5)}',
                                    style: BsasTypography.caption.copyWith(color: BsasColors.textSecondary),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Risk State: ${event.riskState}',
                                        style: BsasTypography.monoDiagnostics.copyWith(
                                          color: isCritical ? BsasColors.criticalRed : BsasColors.radarCyan,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(
                                            event.synced ? Icons.cloud_done : Icons.cloud_off,
                                            size: 14,
                                            color: event.synced ? BsasColors.safeGreen : BsasColors.textMuted,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            event.synced ? 'SYNCED' : 'LOCAL ONLY',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: event.synced ? BsasColors.safeGreen : BsasColors.textMuted,
                                              fontWeight: FontWeight.bold,
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

  Widget _filterChip(String filterId, String label) {
    final isSelected = _selectedFilter == filterId;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filterId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? BsasColors.radarCyan : Colors.white10,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
