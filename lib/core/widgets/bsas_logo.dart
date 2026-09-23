import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/bsas_colors.dart';

/// Professional vector-rendered BSAS Brand Logo
/// Communicates: Geospatial awareness, Border perimeter defense, and Alert readiness.
class BsasLogo extends StatefulWidget {
  const BsasLogo({
    super.key,
    this.size = 64.0,
    this.animated = true,
    this.showBadge = false,
  });

  final double size;
  final bool animated;
  final bool showBadge;

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
      duration: const Duration(seconds: 3),
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _BsasLogoPainter(
            animationProgress: widget.animated ? _controller.value : 0.0,
          ),
        );
      },
    );
  }
}

class _BsasLogoPainter extends CustomPainter {
  _BsasLogoPainter({required this.animationProgress});

  final double animationProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // 1. Outer Safety Shield Boundary
    final shieldPath = Path();
    shieldPath.moveTo(w * 0.5, h * 0.06);
    shieldPath.quadraticBezierTo(w * 0.88, h * 0.12, w * 0.88, h * 0.45);
    shieldPath.quadraticBezierTo(w * 0.88, h * 0.78, w * 0.5, h * 0.96);
    shieldPath.quadraticBezierTo(w * 0.12, h * 0.78, w * 0.12, h * 0.45);
    shieldPath.quadraticBezierTo(w * 0.12, h * 0.12, w * 0.5, h * 0.06);
    shieldPath.close();

    // Shield Background with Radial Gradient
    final shieldPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.2),
        radius: 0.9,
        colors: [
          BsasColors.darkSurface,
          const Color(0xFF0F172A),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(shieldPath, shieldPaint);

    // Shield Outer Border
    final borderPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          BsasColors.radarCyan,
          Color(0xFF0284C7),
          Color(0xFF1E3A8A),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.8, w * 0.035)
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(shieldPath, borderPaint);

    // 2. Animated Concentric Radar Waves
    if (animationProgress > 0) {
      final pulseRadius1 = (w * 0.18) + (animationProgress * w * 0.22);
      final pulseAlpha1 = ((1.0 - animationProgress) * 0.4).clamp(0.0, 1.0);
      final pulsePaint1 = Paint()
        ..color = BsasColors.radarCyan.withValues(alpha: pulseAlpha1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      canvas.drawCircle(center, pulseRadius1, pulsePaint1);

      final secondProgress = (animationProgress + 0.5) % 1.0;
      final pulseRadius2 = (w * 0.18) + (secondProgress * w * 0.22);
      final pulseAlpha2 = ((1.0 - secondProgress) * 0.3).clamp(0.0, 1.0);
      final pulsePaint2 = Paint()
        ..color = BsasColors.radarCyan.withValues(alpha: pulseAlpha2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(center, pulseRadius2, pulsePaint2);
    }

    // 3. Static Precision Radar Ring
    final ringPaint = Paint()
      ..color = BsasColors.darkBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, w * 0.24, ringPaint);

    // 4. Central Diamond Beacon & Safety Star
    final diamondPath = Path();
    final dSize = w * 0.14;
    diamondPath.moveTo(center.dx, center.dy - dSize * 1.3);
    diamondPath.lineTo(center.dx + dSize, center.dy);
    diamondPath.lineTo(center.dx, center.dy + dSize * 1.3);
    diamondPath.lineTo(center.dx - dSize, center.dy);
    diamondPath.close();

    final diamondFill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF38BDF8), // Sky bright
          Color(0xFF0284C7), // Blue
        ],
      ).createShader(Rect.fromCircle(center: center, radius: dSize))
      ..style = PaintingStyle.fill;
    canvas.drawPath(diamondPath, diamondFill);

    // Central Alert Core Pulse
    final corePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, w * 0.045, corePaint);
  }

  @override
  bool shouldRepaint(covariant _BsasLogoPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress;
  }
}
