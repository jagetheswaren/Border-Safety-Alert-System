import 'package:flutter/material.dart';

import '../models/alert_message.dart';
import '../models/alert_severity.dart';
import '../models/geofence_result.dart';
import '../models/geofence_state.dart';

class SafetyAlertBanner extends StatelessWidget {
  const SafetyAlertBanner({super.key, required this.result});

  final GeoFenceResult result;

  @override
  Widget build(BuildContext context) {
    final alert = alertMessageForState(result.state);
    if (alert == null) return const SizedBox.shrink();

    final color = switch (result.state) {
      GeoFenceState.caution => Colors.amber.shade800,
      GeoFenceState.warning => Colors.deepOrange,
      GeoFenceState.critical ||
      GeoFenceState.insideRestrictedArea => Colors.red,
      _ => Colors.transparent,
    };
    final boundary = result.nearestBoundary;
    final distance = result.distanceToBoundaryMeters;
    return Card(
      key: const Key('safety-alert-banner'),
      color: color.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.severity.label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(alert.message),
                  if (boundary != null) ...[
                    const SizedBox(height: 6),
                    Text(boundary.name),
                    Text(
                      'Distance: ${distance == null ? 'Unknown' : '${distance.toStringAsFixed(0)} m'}',
                    ),
                  ],
                  if (boundary?.isDemo ?? false)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Demo boundary — synthetic and non-authoritative.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
