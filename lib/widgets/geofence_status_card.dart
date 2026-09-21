import 'package:flutter/material.dart';

import '../models/geofence_result.dart';
import '../models/geofence_state.dart';
import '../models/safety_state.dart';

class GeoFenceStatusCard extends StatelessWidget {
  const GeoFenceStatusCard({super.key, required this.result});

  final GeoFenceResult result;

  @override
  Widget build(BuildContext context) {
    final boundary = result.nearestBoundary;
    final distance = result.distanceToBoundaryMeters;
    return Card(
      key: const Key('safety-status-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GeoFence State',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              result.state.label,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text('Nearest boundary: ${boundary?.name ?? 'Unknown'}'),
            Text(
              'Distance: ${distance == null ? 'Unknown' : '${distance.toStringAsFixed(0)} m'}',
            ),
            if (boundary != null) ...[
              Text('Type: ${boundary.type}'),
              Text('Boundary risk: ${boundary.riskLevel.label}'),
            ],
            if (result.directionToBoundaryDegrees != null)
              Text(
                'Direction: ${result.directionToBoundaryDegrees!.toStringAsFixed(0)}°',
              ),
            if (result.bearingDifferenceDegrees != null)
              Text(
                result.movingTowardBoundary
                    ? 'Movement: toward boundary'
                    : 'Movement: away/across boundary',
              ),
            if (boundary?.isDemo ?? false)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Demo boundary — synthetic and non-authoritative.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
