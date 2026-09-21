import 'package:flutter/material.dart';
import '../theme/bsas_colors.dart';

/// Global animations and micro-interaction timing tokens for BSAS.
class BsasAnimations {
  BsasAnimations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);

  /// Returns true if reduced motion is requested by accessibility settings.
  static bool prefersReducedMotion(BuildContext context) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }
}

/// Concentric pulsing radar rings for GNSS satellite acquisition.
class GpsRadarAnimation extends StatefulWidget {
  const GpsRadarAnimation({super.key, this.color = BsasColors.primaryBlue, this.size = 36});

  final Color color;
  final double size;

  @override
  State<GpsRadarAnimation> createState() => _GpsRadarAnimationState();
}

class _GpsRadarAnimationState extends State<GpsRadarAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (BsasAnimations.prefersReducedMotion(context)) {
      return Icon(Icons.gps_fixed, color: widget.color, size: widget.size * 0.6);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _RadarPainter(progress: progress, color: widget.color),
        );
      },
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Outer expanding ring
    final paintRing = Paint()
      ..color = color.withValues(alpha: (1.0 - progress).clamp(0.0, 1.0) * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, maxRadius * progress, paintRing);

    // Inner core
    final paintCore = Paint()..color = color;
    canvas.drawCircle(center, 4.0, paintCore);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => oldDelegate.progress != progress;
}

/// Alert pulse animation for Warning and Critical safety state cards.
class AlertPulseAnimation extends StatefulWidget {
  const AlertPulseAnimation({
    super.key,
    required this.child,
    required this.color,
    this.isActive = true,
  });

  final Widget child;
  final Color color;
  final bool isActive;

  @override
  State<AlertPulseAnimation> createState() => _AlertPulseAnimationState();
}

class _AlertPulseAnimationState extends State<AlertPulseAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isActive) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant AlertPulseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
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
    if (!widget.isActive || BsasAnimations.prefersReducedMotion(context)) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.15 + (_controller.value * 0.25)),
                blurRadius: 10 + (_controller.value * 8),
                spreadRadius: 1 + (_controller.value * 2),
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// 4-stage sequential progress dot animation for Local AI and System startup.
class AiLoadingAnimation extends StatefulWidget {
  const AiLoadingAnimation({super.key, this.color = BsasColors.primaryBlue});

  final Color color;

  @override
  State<AiLoadingAnimation> createState() => _AiLoadingAnimationState();
}

class _AiLoadingAnimationState extends State<AiLoadingAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (BsasAnimations.prefersReducedMotion(context)) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(4, (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: CircleAvatar(radius: 3, backgroundColor: widget.color),
        )),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final step = (_controller.value * 4).floor();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (i) {
            final isLit = i <= step;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLit ? widget.color : widget.color.withValues(alpha: 0.2),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
