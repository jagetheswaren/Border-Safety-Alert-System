import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_motion.dart';
import '../theme/bsas_colors.dart';

/// Flutter-native adaptation of the React Bits ElectricBorder.
///
/// Wraps a child widget in an animated, glowing gradient perimeter border.
/// Used selectively for Critical alerts, restricted perimeter breaches, and
/// primary emergency callouts without continuous full-screen flashing.
class BSASElectricBorder extends StatefulWidget {
  const BSASElectricBorder({
    super.key,
    required this.child,
    this.color = BsasColors.criticalRed,
    this.glowColor = const Color(0xFFFF5252),
    this.borderWidth = 2.0,
    this.borderRadius = 16.0,
    this.isActive = true,
  });

  final Widget child;
  final Color color;
  final Color glowColor;
  final double borderWidth;
  final double borderRadius;
  final bool isActive;

  @override
  State<BSASElectricBorder> createState() => _BSASElectricBorderState();
}

class _BSASElectricBorderState extends State<BSASElectricBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant BSASElectricBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return widget.child;
    }

    final isReduced = AppMotion.isReducedMotion(context);

    if (isReduced) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: widget.color, width: widget.borderWidth),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.3),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ElectricBorderPainter(
            progress: _controller.value,
            color: widget.color,
            glowColor: widget.glowColor,
            borderWidth: widget.borderWidth,
            borderRadius: widget.borderRadius,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _ElectricBorderPainter extends CustomPainter {
  _ElectricBorderPainter({
    required this.progress,
    required this.color,
    required this.glowColor,
    required this.borderWidth,
    required this.borderRadius,
  });

  final double progress;
  final Color color;
  final Color glowColor;
  final double borderWidth;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Gradient sweep rotating around the card perimeter
    final angle = progress * 2 * math.pi;
    final sweepGradient = SweepGradient(
      center: Alignment.center,
      startAngle: 0,
      endAngle: 2 * math.pi,
      transform: GradientRotation(angle),
      colors: [
        color.withValues(alpha: 0.1),
        glowColor,
        color,
        color.withValues(alpha: 0.1),
      ],
      stops: const [0.0, 0.45, 0.55, 1.0],
    );

    // Glowing border stroke
    final glowPaint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth + 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final borderPaint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRRect(rrect, glowPaint);
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _ElectricBorderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.glowColor != glowColor;
  }
}
