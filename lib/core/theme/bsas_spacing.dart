import 'package:flutter/material.dart';

/// Centralized layout and spacing tokens for BSAS.
///
/// Follows the strict human-designed grid:
/// 4, 8, 12, 16, 20, 24, 32, 40.
class BsasSpacing {
  BsasSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 40.0;

  // Screen Margins & Card Geometry
  static const double screenMargin = 16.0;
  static const double cardPadding = 16.0;
  static const double cardRadius = 12.0;
  static const double pillRadius = 24.0;
  static const double buttonRadius = 8.0;
  static const double iconTouchTarget = 48.0;

  // Edge insets helpers
  static const EdgeInsets pagePadding = EdgeInsets.all(screenMargin);
  static const EdgeInsets cardInsets = EdgeInsets.all(cardPadding);
  static const EdgeInsets horizontalScreen = EdgeInsets.symmetric(horizontal: screenMargin);
  static const EdgeInsets verticalScreen = EdgeInsets.symmetric(vertical: screenMargin);

  // Common SizedBox spacers
  static const SizedBox gapXs = SizedBox(height: xs, width: xs);
  static const SizedBox gapSm = SizedBox(height: sm, width: sm);
  static const SizedBox gapMd = SizedBox(height: md, width: md);
  static const SizedBox gapLg = SizedBox(height: lg, width: lg);
  static const SizedBox gapXl = SizedBox(height: xl, width: xl);
  static const SizedBox gapXxl = SizedBox(height: xxl, width: xxl);
  static const SizedBox gapXxxl = SizedBox(height: xxxl, width: xxxl);
  static const SizedBox gapHuge = SizedBox(height: huge, width: huge);
}
