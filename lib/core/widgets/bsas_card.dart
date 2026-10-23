import 'package:flutter/material.dart';
import '../theme/app_motion.dart';
import '../theme/bsas_colors.dart';

/// Flutter-native adaptation of the React Bits SpotlightCard & BSASCard.
///
/// Provides:
/// - Dark tactical elevated surface
/// - Subtle touch-press micro-compression (~0.985x)
/// - Touch-reactive radial illumination near the finger contact point
class BSASCard extends StatefulWidget {
  const BSASCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = EdgeInsets.zero,
    this.borderColor,
    this.backgroundColor,
    this.borderRadius = 16.0,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? borderColor;
  final Color? backgroundColor;
  final double borderRadius;

  @override
  State<BSASCard> createState() => _BSASCardState();
}

class _BSASCardState extends State<BSASCard> {
  bool _isPressed = false;
  Offset _touchPosition = Offset.zero;
  bool _hasTouch = false;

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.isReducedMotion(context);
    final scale = (_isPressed && widget.onTap != null && !reduced) ? 0.985 : 1.0;

    return Padding(
      padding: widget.margin,
      child: AnimatedScale(
        scale: scale,
        duration: AppMotion.fast,
        curve: AppMotion.easeOut,
        child: GestureDetector(
          onTapDown: widget.onTap != null
              ? (details) {
                  setState(() {
                    _isPressed = true;
                    _touchPosition = details.localPosition;
                    _hasTouch = true;
                  });
                }
              : null,
          onTapUp: widget.onTap != null
              ? (_) {
                  setState(() {
                    _isPressed = false;
                    _hasTouch = false;
                  });
                  widget.onTap?.call();
                }
              : null,
          onTapCancel: widget.onTap != null
              ? () {
                  setState(() {
                    _isPressed = false;
                    _hasTouch = false;
                  });
                }
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: widget.backgroundColor ?? BsasColors.darkSurface,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: widget.borderColor ?? BsasColors.darkBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: Stack(
                children: [
                  // Subtle touch-following spotlight radial gradient (when pressed)
                  if (_hasTouch && !reduced)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _SpotlightPainter(
                          position: _touchPosition,
                          color: BsasColors.primaryBlueLight.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                  Padding(
                    padding: widget.padding,
                    child: widget.child,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({required this.position, required this.color});

  final Offset position;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (position.dx / size.width) * 2 - 1,
          (position.dy / size.height) * 2 - 1,
        ),
        radius: 0.8,
        colors: [color, Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.position != position || oldDelegate.color != color;
}
