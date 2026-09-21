import 'package:flutter/material.dart';

import '../models/safety_state.dart';

/// Pill badge rendering a [RiskLevel] with its semantic color.
class RiskBadge extends StatelessWidget {
  const RiskBadge({super.key, required this.risk});

  final RiskLevel risk;

  (Color, IconData) get _style {
    switch (risk) {
      case RiskLevel.low:
        return (Colors.green, Icons.check_circle);
      case RiskLevel.medium:
        return (Colors.amber, Icons.warning_amber);
      case RiskLevel.high:
        return (Colors.red, Icons.dangerous);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _style;
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(
        risk.label,
        style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.bold),
      ),
      side: BorderSide(color: color),
    );
  }
}
