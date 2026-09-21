import 'package:flutter/material.dart';

import '../models/safety_state.dart';

/// Colored dot + safety-state label. Color mapping is the single source of
/// truth for safety semantics in the UI.
class StatusIndicator extends StatelessWidget {
  const StatusIndicator({super.key, required this.state, this.size = 12});

  final SafetyState state;
  final double size;

  Color get color {
    switch (state) {
      case SafetyState.safe:
        return Colors.green;
      case SafetyState.caution:
        return Colors.amber;
      case SafetyState.warning:
        return Colors.orange;
      case SafetyState.critical:
      case SafetyState.insideRestrictedArea:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(state.label, style: textStyle),
      ],
    );
  }
}
