import 'package:flutter/material.dart';
import '../theme/bsas_colors.dart';

enum StatusState {
  ready,
  active,
  loading,
  warning,
  critical,
  offline,
  stale,
  error,
  disabled,
  notInstalled,
  idle,
}

Color colorForStatusState(StatusState state) {
  switch (state) {
    case StatusState.ready:
    case StatusState.active:
      return BsasColors.safeGreen;
    case StatusState.loading:
      return BsasColors.primaryBlue;
    case StatusState.warning:
      return BsasColors.warningOrange;
    case StatusState.critical:
    case StatusState.error:
      return BsasColors.criticalRed;
    case StatusState.offline:
    case StatusState.stale:
      return BsasColors.offlineSteel;
    case StatusState.disabled:
    case StatusState.notInstalled:
    case StatusState.idle:
      return BsasColors.textLightMuted;
  }
}

/// Small live status dot with optional subtle pulsing animation.
class StatusDot extends StatelessWidget {
  const StatusDot({
    super.key,
    this.color,
    this.state,
    this.size = 8.0,
    this.pulse = false,
  });

  final Color? color;
  final StatusState? state;
  final double size;
  final bool pulse;

  Color get _resolvedColor {
    if (color != null) return color!;
    if (state != null) return colorForStatusState(state!);
    return BsasColors.safeGreen;
  }

  @override
  Widget build(BuildContext context) {
    final c = _resolvedColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        boxShadow: pulse
            ? [
                BoxShadow(
                  color: c.withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
    );
  }
}
