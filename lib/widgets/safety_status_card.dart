import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import 'gps_status_chip.dart';
import 'risk_badge.dart';
import 'status_indicator.dart';

/// Composite safety summary card: state, risk, nearest boundary, GPS.
///
/// Renders a [DemoSafetySnapshot] in Phase 2 with an explicit demo disclaimer.
/// Later phases pass live engine output through this same widget.
class SafetyStatusCard extends StatelessWidget {
  const SafetyStatusCard({super.key, required this.snapshot});

  final DemoSafetySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('safety-status-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusIndicator(state: snapshot.safetyState),
            const SizedBox(height: 12),
            Row(
              children: [
                RiskBadge(risk: snapshot.risk),
                const SizedBox(width: 8),
                GpsStatusChip(state: snapshot.gps),
              ],
            ),
            const SizedBox(height: 12),
            Text('Nearest area: ${snapshot.boundaryName}'),
            Text('Distance: ${snapshot.distanceMeters.toStringAsFixed(0)} m'),
            if (snapshot.isPlaceholder)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Demo data — live GPS and risk engine arrive in later phases.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
