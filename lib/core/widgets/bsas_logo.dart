import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/bsas_colors.dart';

/// One Original Master BSAS Brand Logo.
///
/// Communicates civilian safety identity:
/// LOCATION (Concentric beacon waves)
/// + SAFETY (Perimeter shield boundary)
/// + GEOFENCE (Precision boundary ring)
/// + ALERT (Calibrated core alert diamond)
///
/// Designed cleanly for both dark & light backgrounds, headers, splash,
/// onboarding, about screens, and app icon assets.
class BsasLogo extends StatefulWidget {
  const BsasLogo({
    super.key,
    this.size = 48.0,
    this.animated = true,
    this.showBadge = false,
    this.isLightSurface = false,
  });

  final double size;
  final bool animated;
  final bool showBadge;
  final bool isLightSurface;

  @override
  State<BsasLogo> createState() => _BsasLogoState();
}

typedef BsasLogoWidget = BsasLogo;

class _BsasLogoState extends State<BsasLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.animated) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(BsasLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animated && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animated && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark && !widget.isLightSurface;

    if (!widget.animated) {
      return CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _BsasLogoPainter(
          animationProgress: 0.0,
          isDark: isDark,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _BsasLogoPainter(
            animationProgress: _controller.value,
            isDark: isDark,
          ),
        );
      },
    );
  }
}

class _BsasLogoPainter extends CustomPainter {
  _BsasLogoPainter({
    required this.animationProgress,
    required this.isDark,
  });

  final double animationProgress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // 1. Safety Shield Perimeter (Civic Safety Boundary)
    final shieldPath = Path();
    shieldPath.moveTo(w * 0.5, h * 0.08);
    shieldPath.quadraticBezierTo(w * 0.86, h * 0.12, w * 0.86, h * 0.44);
    shieldPath.quadraticBezierTo(w * 0.86, h * 0.76, w * 0.5, h * 0.94);
    shieldPath.quadraticBezierTo(w * 0.14, h * 0.76, w * 0.14, h * 0.44);
    shieldPath.quadraticBezierTo(w * 0.14, h * 0.12, w * 0.5, h * 0.08);
    shieldPath.close();

    // Shield background fill
    final shieldPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [
                const Color(0xFF16253B),
                const Color(0xFF0F172A),
              ]
            : [
                const Color(0xFFF0FDF4),
                const Color(0xFFE0F2FE),
              ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(shieldPath, shieldPaint);

    // Shield outline border
    final borderPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
                BsasColors.primaryBlueLight,
                BsasColors.primaryBlue,
                const Color(0xFF0369A1),
              ]
            : [
                BsasColors.primaryBlue,
                const Color(0xFF0369A1),
                const Color(0xFF075985),
              ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.8, w * 0.038)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(shieldPath, borderPaint);

    // 2. Geofence Boundary Ring (Precision circle)
    final geofenceRingPaint = Paint()
      ..color = isDark
          ? const Color(0xFF334A6E)
          : const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, w * 0.018);
    canvas.drawCircle(center, w * 0.25, geofenceRingPaint);

    // 3. Location Radar Pulse (Concentric GNSS wave)
    if (animationProgress > 0) {
      final pulseRadius = (w * 0.16) + (animationProgress * w * 0.22);
      final pulseAlpha = ((1.0 - animationProgress) * 0.45).clamp(0.0, 1.0);
      final pulsePaint = Paint()
        ..color = (isDark ? BsasColors.primaryBlueLight : BsasColors.primaryBlue)
            .withValues(alpha: pulseAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, w * 0.02);
      canvas.drawCircle(center, pulseRadius, pulsePaint);
    }

    // 4. Alert Beacon Diamond (Central Alert Core)
    final diamondPath = Path();
    final dSize = w * 0.13;
    diamondPath.moveTo(center.dx, center.dy - dSize * 1.25);
    diamondPath.lineTo(center.dx + dSize, center.dy);
    diamondPath.lineTo(center.dx, center.dy + dSize * 1.25);
    diamondPath.lineTo(center.dx - dSize, center.dy);
    diamondPath.close();

    final diamondPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          BsasColors.primaryBlueLight,
          BsasColors.primaryBlue,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: dSize))
      ..style = PaintingStyle.fill;
    canvas.drawPath(diamondPath, diamondPaint);

    // 5. White Focal Center Dot (Precision GPS fix point)
    final centerDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, math.max(2.5, w * 0.04), centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant _BsasLogoPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress || oldDelegate.isDark != isDark;
  }
}
