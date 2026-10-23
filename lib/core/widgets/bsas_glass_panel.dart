import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/bsas_colors.dart';

/// Flutter-native adaptation of the React Bits GlassSurface.
///
/// Provides a frosted, translucent backdrop for floating map controls,
/// search overlays, and tactical HUD elements without obstructing background maps.
class BSASGlassPanel extends StatelessWidget {
  const BSASGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12.0),
    this.margin,
    this.borderRadius = 16.0,
    this.blurSigma = 12.0,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ??
        BsasColors.darkBackground.withValues(alpha: 0.72);
    final effectiveBorder = borderColor ??
        BsasColors.primaryBlueLight.withValues(alpha: 0.22);

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: effectiveBorder, width: borderWidth),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      content = GestureDetector(onTap: onTap, child: content);
    }

    return content;
  }
}
