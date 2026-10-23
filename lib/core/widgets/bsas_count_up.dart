import 'package:flutter/material.dart';
import '../theme/app_motion.dart';

/// Flutter-native adaptation of the React Bits CountUp animation.
///
/// Smoothly transitions numerical metrics (e.g. distance to boundary,
/// alert counters, ETA in minutes, sync queue size) using a [TweenAnimationBuilder].
class BSASCountUp extends StatelessWidget {
  const BSASCountUp({
    super.key,
    required this.value,
    this.duration = AppMotion.slow,
    this.decimalPlaces = 0,
    this.prefix = '',
    this.suffix = '',
    this.style,
  });

  final double value;
  final Duration duration;
  final int decimalPlaces;
  final String prefix;
  final String suffix;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final isReduced = AppMotion.isReducedMotion(context);

    if (isReduced) {
      final formatted = value.toStringAsFixed(decimalPlaces);
      return Text('$prefix$formatted$suffix', style: style);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value),
      duration: duration,
      curve: AppMotion.easeOut,
      builder: (context, val, child) {
        final formatted = val.toStringAsFixed(decimalPlaces);
        return Text('$prefix$formatted$suffix', style: style);
      },
    );
  }
}
