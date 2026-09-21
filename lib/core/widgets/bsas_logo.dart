import 'package:flutter/material.dart';
import '../theme/bsas_colors.dart';

typedef BsasLogoWidget = BsasLogo;

/// Original BSAS brand logo rendered via high-performance vector Canvas painter.
class BsasLogo extends StatelessWidget {
  const BsasLogo({
    super.key,
    this.size = 48,
    this.showText = true,
    this.isDark = true,
  });

  final double size;
  final bool showText;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final icon = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BsasLogoPainter(isDark: isDark),
      ),
    );

    if (!showText) return icon;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        icon,
        SizedBox(width: size * 0.25),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BSAS',
              style: TextStyle(
                fontSize: size * 0.46,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                color: isDark ? BsasColors.textLightPrimary : const Color(0xFF0F172A),
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'BORDER SAFETY ALERT',
              style: TextStyle(
                fontSize: size * 0.18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: BsasColors.primaryBlue,
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BsasLogoPainter extends CustomPainter {
  _BsasLogoPainter({required this.isDark});
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Outer Shield
    final shieldPath = Path()
      ..moveTo(w * 0.5, h * 0.08)
      ..lineTo(w * 0.88, h * 0.22)
      ..lineTo(w * 0.88, h * 0.58)
      ..cubicTo(w * 0.88, h * 0.80, w * 0.68, h * 0.94, w * 0.5, h * 0.98)
      ..cubicTo(w * 0.32, h * 0.94, w * 0.12, h * 0.80, w * 0.12, h * 0.58)
      ..lineTo(w * 0.12, h * 0.22)
      ..close();

    final shieldPaint = Paint()
      ..shader = const LinearGradient(
        colors: [BsasColors.primaryBlue, Color(0xFF2563EB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(shieldPath, shieldPaint);

    // Inner Shield cut
    final innerPath = Path()
      ..moveTo(w * 0.5, h * 0.20)
      ..lineTo(w * 0.78, h * 0.30)
      ..lineTo(w * 0.78, h * 0.58)
      ..cubicTo(w * 0.78, h * 0.74, w * 0.64, h * 0.85, w * 0.5, h * 0.89)
      ..cubicTo(w * 0.36, h * 0.85, w * 0.22, h * 0.74, w * 0.22, h * 0.58)
      ..lineTo(w * 0.22, h * 0.30)
      ..close();

    final innerPaint = Paint()
      ..color = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    canvas.drawPath(innerPath, innerPaint);

    // Radar Rings
    final center = Offset(w * 0.5, h * 0.56);
    final radarPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035;

    canvas.drawCircle(center, w * 0.19, radarPaint);

    // Core GPS Node
    final nodePaint = Paint()..color = BsasColors.safeGreen;
    canvas.drawCircle(center, w * 0.08, nodePaint);

    // Crosshair lines
    final crossPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(center.dx, center.dy - w * 0.19), Offset(center.dx, center.dy - w * 0.26), crossPaint);
    canvas.drawLine(Offset(center.dx, center.dy + w * 0.19), Offset(center.dx, center.dy + w * 0.26), crossPaint);
    canvas.drawLine(Offset(center.dx - w * 0.19, center.dy), Offset(center.dx - w * 0.26, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx + w * 0.19, center.dy), Offset(center.dx + w * 0.26, center.dy), crossPaint);
  }

  @override
  bool shouldRepaint(covariant _BsasLogoPainter oldDelegate) => oldDelegate.isDark != isDark;
}
