import 'package:flutter/material.dart';
import '../theme/bsas_colors.dart';
import 'status_dot.dart';

export 'status_dot.dart' show StatusState;

/// Semantic pill badge showing label, status dot, and optional icon.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.color,
    this.state,
    this.icon,
    this.isPulsing = false,
  });

  final String label;
  final Color? color;
  final StatusState? state;
  final IconData? icon;
  final bool isPulsing;

  Color get _resolvedColor {
    if (color != null) return color!;
    if (state != null) return colorForStatusState(state!);
    return BsasColors.safeGreen;
  }

  @override
  Widget build(BuildContext context) {
    final c = _resolvedColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: c),
            const SizedBox(width: 5),
          ] else ...[
            StatusDot(color: c, size: 7, pulse: isPulsing),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: c,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
