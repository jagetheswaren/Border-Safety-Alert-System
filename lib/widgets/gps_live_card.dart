import 'package:flutter/material.dart';

import '../models/gps_snapshot.dart';
import '../models/location_model.dart';
import 'gps_status_chip.dart';

/// Live GPS position card driven by [GpsService] (Phase 3).
///
/// Shows real latitude/longitude/accuracy/speed/bearing when locked, or an
/// honest state message (disabled service, denied permission, no fix) with a
/// Retry action. Never fabricates coordinates.
class GpsLiveCard extends StatelessWidget {
  const GpsLiveCard({super.key, required this.snapshot, this.onRetry});

  final GpsSnapshot snapshot;
  final VoidCallback? onRetry;

  String _value(double? measured, String Function(double) format) {
    return measured == null ? '—' : format(measured);
  }

  @override
  Widget build(BuildContext context) {
    final LocationModel? fix = snapshot.location;
    return Card(
      key: const Key('gps-live-card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GpsStatusChip(state: snapshot.fix),
                if (snapshot.stale) ...[
                  const SizedBox(width: 8),
                  const Chip(
                    avatar: Icon(Icons.schedule, size: 18),
                    label: Text('Stale fix'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (fix != null) ...[
              Text(
                'Latitude: ${fix.latitude.toStringAsFixed(5)}  •  '
                'Longitude: ${fix.longitude.toStringAsFixed(5)}',
              ),
              const SizedBox(height: 4),
              Text(
                'Accuracy: ${_value(fix.accuracy, (v) => '± ${v.toStringAsFixed(0)} m')}  •  '
                'Speed: ${_value(fix.speed, (v) => '${v.toStringAsFixed(1)} m/s')}  •  '
                'Bearing: ${_value(fix.bearing, (v) => '${v.toStringAsFixed(0)}°')}',
              ),
              const SizedBox(height: 4),
              Text(
                'Altitude: ${_value(fix.altitude, (v) => '${v.toStringAsFixed(0)} m')}',
              ),
            ],
            if (snapshot.message != null) ...[
              const SizedBox(height: 8),
              Text(snapshot.message!),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                key: const Key('gps-retry'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
