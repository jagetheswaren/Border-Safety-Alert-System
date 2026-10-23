import 'package:flutter/material.dart';

/// Centralized motion design system for BSAS Mobile.
///
/// Mirrors the React Bits motion specifications adapted natively for Flutter:
/// - Fast: 140ms (micro-interactions, button presses, tab clicks)
/// - Normal: 260ms (card reveals, bottom sheet snaps, dialogs)
/// - Slow: 450ms (large transitions, radar pulses)
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 140);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 450);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve spring = Curves.elasticOut;

  /// Checks if reduced motion is requested by system accessibility settings.
  static bool isReducedMotion(BuildContext context) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }
}
