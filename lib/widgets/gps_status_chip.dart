import 'package:flutter/material.dart';

import '../models/safety_state.dart';

/// Chip showing the GPS receiver condition.
///
/// Driven live by [GpsService] since Phase 3; demo screens may still pass a
/// placeholder state, which must be labeled as demo by the parent widget.
class GpsStatusChip extends StatelessWidget {
  const GpsStatusChip({super.key, required this.state});

  final GpsFixState state;

  IconData get _icon {
    switch (state) {
      case GpsFixState.unavailable:
        return Icons.location_off;
      case GpsFixState.searching:
        return Icons.location_searching;
      case GpsFixState.locked:
        return Icons.my_location;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      key: const Key('gps-status-chip'),
      avatar: Icon(_icon, size: 18),
      label: Text(state.label),
    );
  }
}
