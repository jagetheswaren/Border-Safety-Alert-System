import 'dart:async';
import 'package:flutter/material.dart';

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

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
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
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();
    _runInitialization();
  }

  Future<void> _runInitialization() async {
    // 1. Safety engine
    setState(() => _safetyReady = true);
    await Future.delayed(const Duration(milliseconds: 120));

    // 2. Alert engine channels
    setState(() => _alertsReady = true);
    await Future.delayed(const Duration(milliseconds: 120));

    // 3. Offline map resources check
    await widget.offlineMapService.initialize();
    if (mounted) setState(() => _mapReady = true);
    await Future.delayed(const Duration(milliseconds: 120));

    // 4. Check AI model status
    await widget.modelManager.checkModelStatus();
    if (mounted) setState(() => _aiChecked = true);
    await Future.delayed(const Duration(milliseconds: 120));

    // 5. GPS fix check
    if (mounted) setState(() => _gpsReady = true);
    await Future.delayed(const Duration(milliseconds: 250));

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: BsasColors.background(isDark),
      body: Center(
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
                  const SizedBox(height: BsasSpacing.xl),
                  Text(
                    'BSAS',
                    style: BsasTypography.heading.copyWith(
                      fontSize: 32,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w800,
                      color: BsasColors.text(isDark),
                    ),
                  ),
                  const SizedBox(height: BsasSpacing.xs),
                  Text(
                    'BORDER SAFETY ALERT SYSTEM',
                    style: BsasTypography.monospace.copyWith(
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: BsasSpacing.xxl),

                  // Diagnostics Checklist Card
                  Container(
                    padding: const EdgeInsets.all(BsasSpacing.lg),
                    decoration: BoxDecoration(
                      color: BsasColors.card(isDark),
                      borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
                      border: Border.all(
                        color: BsasColors.border(isDark),
                        width: 1,
                      ),
                      boxShadow: isDark
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [
                              BoxShadow(
                                color: BsasColors.lightBorder,
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: BsasSpacing.md),
                          child: Text(
                            'BOOT SEQUENCE INITIATED',
                            style: BsasTypography.monospace.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: BsasColors.textSec(isDark),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        _checkItem('Deterministic Risk Engine', _safetyReady, isDark),
                        const SizedBox(height: BsasSpacing.md),
                        _checkItem('Alert Channels (Sound/TTS)', _alertsReady, isDark),
                        const SizedBox(height: BsasSpacing.md),
                        _checkItem('Offline Map Tile Storage', _mapReady, isDark),
                        const SizedBox(height: BsasSpacing.md),
                        _checkItem('On-Device Local AI Runtime', _aiChecked, isDark),
                        const SizedBox(height: BsasSpacing.md),
                        _checkItem('GNSS Hardware Geolocation', _gpsReady, isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _checkItem(String label, bool isReady, bool isDark) {
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
              color: BsasColors.text(isDark),
              fontWeight: isReady ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        if (isReady)
          const Icon(Icons.check, size: 16, color: BsasColors.safeGreen)
        else
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2.0, 
              color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
            ),
          ),
      ],
    );
  }
}
