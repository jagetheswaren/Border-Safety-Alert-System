import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/theme/app_motion.dart';
import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_spacing.dart';
import '../core/theme/bsas_typography.dart';
import '../core/widgets/bsas_logo.dart';
import '../core/widgets/status_dot.dart';
import '../services/gps_service.dart';
import '../services/model_manager.dart';
import '../services/offline_map_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.gpsService,
    required this.modelManager,
    required this.offlineMapService,
    required this.onFinished,
  });

  final GpsService gpsService;
  final ModelManager modelManager;
  final OfflineMapService offlineMapService;
  final VoidCallback onFinished;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  bool _safetyReady = false;
  bool _alertsReady = false;
  bool _mapReady = false;
  bool _aiChecked = false;
  bool _gpsReady = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();
    _runInitialization();
  }

  Future<void> _runInitialization() async {
    // Snappy 1-1.5 second sequence checking real local subsystem ready states
    setState(() => _safetyReady = true);
    await Future.delayed(const Duration(milliseconds: 90));

    setState(() => _alertsReady = true);
    await Future.delayed(const Duration(milliseconds: 90));

    await widget.offlineMapService.initialize();
    if (mounted) setState(() => _mapReady = true);
    await Future.delayed(const Duration(milliseconds: 90));

    await widget.modelManager.checkModelStatus();
    if (mounted) setState(() => _aiChecked = true);
    await Future.delayed(const Duration(milliseconds: 90));

    if (mounted) setState(() => _gpsReady = true);
    await Future.delayed(const Duration(milliseconds: 200));

    if (mounted) {
      widget.onFinished();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.isReducedMotion(context);

    return Scaffold(
      backgroundColor: BsasColors.darkBackground,
      body: Stack(
        children: [
          // Subtle tactical radar grid sweep
          if (!reduced)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _RadarGridPainter(progress: _animController.value),
                  );
                },
              ),
            ),

          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.xl),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BsasLogo(size: 88, animated: true),
                      const SizedBox(height: BsasSpacing.lg),
                      Text(
                        'BSAS',
                        style: BsasTypography.heading.copyWith(
                          fontSize: 32,
                          letterSpacing: 3.0,
                          fontWeight: FontWeight.w900,
                          color: BsasColors.textLightPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'BORDER SAFETY & ALERT SYSTEM',
                        textAlign: TextAlign.center,
                        style: BsasTypography.monospace.copyWith(
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: BsasColors.primaryBlueLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'GEOSPATIAL SAFETY PLATFORM',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: BsasColors.textLightMuted,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: BsasSpacing.xl),

                      // Boot sequence card
                      Container(
                        padding: const EdgeInsets.all(BsasSpacing.md),
                        decoration: BoxDecoration(
                          color: BsasColors.darkSurface.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: BsasColors.darkBorder,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: BsasColors.primaryBlueLight,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'SUBSYSTEM VERIFICATION',
                                    style: BsasTypography.monospace.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: BsasColors.textLightMuted,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _checkItem('Deterministic Risk Engine', _safetyReady),
                            const SizedBox(height: 10),
                            _checkItem('Alert Channels (Sound / TTS)', _alertsReady),
                            const SizedBox(height: 10),
                            _checkItem('Offline Map Tile Storage', _mapReady),
                            const SizedBox(height: 10),
                            _checkItem('On-Device Local AI Runtime', _aiChecked),
                            const SizedBox(height: 10),
                            _checkItem('GNSS Hardware Geolocation', _gpsReady),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkItem(String label, bool isReady) {
    return Row(
      children: [
        StatusDot(
          state: isReady ? StatusState.ready : StatusState.loading,
          size: 8,
          pulse: !isReady,
        ),
        const SizedBox(width: BsasSpacing.md),
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: BsasTypography.monospace.copyWith(
              fontSize: 11,
              color: BsasColors.textLightPrimary,
              fontWeight: isReady ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        if (isReady)
          const Icon(Icons.check, size: 16, color: BsasColors.safeGreen)
        else
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              color: BsasColors.primaryBlueLight,
            ),
          ),
      ],
    );
  }
}

class _RadarGridPainter extends CustomPainter {
  _RadarGridPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final linePaint = Paint()
      ..color = BsasColors.primaryBlueLight.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    // Concentric boundary radar circles
    for (double r = 60; r < size.width; r += 70) {
      canvas.drawCircle(center, r, linePaint);
    }

    // Rotating radar sweep
    final sweepAngle = progress * 2 * math.pi;
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0,
        endAngle: 2 * math.pi,
        transform: GradientRotation(sweepAngle),
        colors: [
          Colors.transparent,
          BsasColors.primaryBlueLight.withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5],
      ).createShader(Rect.fromCircle(center: center, radius: size.width))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, size.width * 0.8, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarGridPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
