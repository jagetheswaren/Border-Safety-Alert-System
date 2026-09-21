import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../models/gps_snapshot.dart';
import '../models/geofence_result.dart';
import '../models/geofence_state.dart';
import '../widgets/gps_status_chip.dart';
import '../widgets/geofence_status_card.dart';
import '../widgets/info_card.dart';
import '../widgets/risk_badge.dart';
import '../widgets/status_indicator.dart';
import '../widgets/safety_alert_banner.dart';

/// Safety detail view. The deterministic risk engine (later phase) and the
/// ML pipeline (LSTM + Random Forest) will feed this screen; risk content
/// remains demo data with a disclaimer, while [gps] shows the live GPS
/// status from [GpsService].
class SafetyScreen extends StatelessWidget {
  const SafetyScreen({
    super.key,
    this.snapshot = DemoSafetySnapshot.placeholder,
    this.gps,
    this.geoFence = const GeoFenceResult(state: GeoFenceState.unknown),
  });

  final DemoSafetySnapshot snapshot;
  final GpsSnapshot? gps;
  final GeoFenceResult geoFence;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('screen-safety'),
      appBar: AppBar(title: const Text('Safety')),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusIndicator(state: snapshot.safetyState),
                  const SizedBox(height: 12),
                  RiskBadge(risk: snapshot.risk),
                  const SizedBox(height: 12),
                  GpsStatusChip(state: (gps ?? GpsSnapshot.initial()).fix),
                  const Text(
                    'Live GPS status — risk level above is demo data.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 12),
                  Text('Nearest area: ${snapshot.boundaryName}'),
                  Text(
                    'Distance: ${snapshot.distanceMeters.toStringAsFixed(0)} m',
                  ),
                  if (snapshot.isPlaceholder)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Demo data — geo-fence and risk engine arrive in later phases.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ),
            ),
          ),
          GeoFenceStatusCard(result: geoFence),
          SafetyAlertBanner(result: geoFence),
          const InfoCard(
            title: 'Why this warning?',
            subtitle: 'Explanation panel connects to the risk engine later',
            leading: Icon(Icons.info_outline),
          ),
          const InfoCard(
            title: 'Recommended action',
            subtitle: 'Safe-route guidance arrives with A* routing',
            leading: Icon(Icons.directions),
          ),
        ],
      ),
    );
  }
}
