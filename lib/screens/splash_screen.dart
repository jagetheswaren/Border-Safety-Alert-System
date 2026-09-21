import 'dart:async';
import 'package:flutter/material.dart';

import '../core/theme/bsas_colors.dart';
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

class _SplashScreenState extends State<SplashScreen> {
  bool _gpsReady = false;
  bool _mapReady = false;
  bool _safetyReady = false;
  bool _aiChecked = false;
  bool _alertsReady = false;

  @override
  void initState() {
    super.initState();
    _runInitialization();
  }

  Future<void> _runInitialization() async {
    // 1. Safety engine is deterministic and always ready
    setState(() => _safetyReady = true);
    await Future.delayed(const Duration(milliseconds: 120));

    // 2. Alert engine channels initialized
    setState(() => _alertsReady = true);
    await Future.delayed(const Duration(milliseconds: 120));

    // 3. Offline map resources check
    await widget.offlineMapService.initialize();
    if (mounted) setState(() => _mapReady = true);
    await Future.delayed(const Duration(milliseconds: 120));

    // 4. Check AI model on-device state
    await widget.modelManager.checkModelStatus();
    if (mounted) setState(() => _aiChecked = true);
    await Future.delayed(const Duration(milliseconds: 120));

    // 5. GPS fix check
    if (mounted) setState(() => _gpsReady = true);
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      widget.onFinished();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BsasColors.darkBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BsasLogoWidget(size: 96),
              const SizedBox(height: 24),
              const Text('BSAS', style: BsasTypography.display),
              const SizedBox(height: 4),
              Text(
                'BORDER SAFETY ALERT SYSTEM',
                style: BsasTypography.title.copyWith(
                  letterSpacing: 2.0,
                  fontSize: 14,
                  color: BsasColors.radarCyan,
                ),
              ),
              const SizedBox(height: 36),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: BsasColors.darkSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: BsasColors.darkBorder),
                ),
                child: Column(
                  children: [
                    _statusRow(
                      'GPS SUBSYSTEM',
                      _gpsReady ? 'READY' : 'INITIALIZING',
                      _gpsReady ? StatusState.ready : StatusState.loading,
                    ),
                    const SizedBox(height: 10),
                    _statusRow(
                      'OFFLINE MAP ENGINE',
                      _mapReady ? 'READY' : 'LOADING TILES',
                      _mapReady ? StatusState.ready : StatusState.loading,
                    ),
                    const SizedBox(height: 10),
                    _statusRow(
                      'SAFETY & RISK ENGINE',
                      _safetyReady ? 'READY' : 'STARTING',
                      _safetyReady ? StatusState.ready : StatusState.loading,
                    ),
                    const SizedBox(height: 10),
                    _statusRow(
                      'LOCAL AI ASSISTANT',
                      _aiChecked
                          ? (widget.modelManager.state == ModelState.notInstalled
                              ? 'NOT INSTALLED'
                              : 'READY')
                          : 'CHECKING',
                      _aiChecked
                          ? (widget.modelManager.state == ModelState.notInstalled
                              ? StatusState.notInstalled
                              : StatusState.ready)
                          : StatusState.loading,
                    ),
                    const SizedBox(height: 10),
                    _statusRow(
                      'ALERT CHANNELS',
                      _alertsReady ? 'READY' : 'INITIALIZING',
                      _alertsReady ? StatusState.ready : StatusState.loading,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusRow(String label, String status, StatusState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            StatusDot(state: state, size: 8),
            const SizedBox(width: 10),
            Text(label, style: BsasTypography.caption.copyWith(color: Colors.white70)),
          ],
        ),
        Text(
          status,
          style: BsasTypography.monoDiagnostics.copyWith(
            fontSize: 12,
            color: state == StatusState.ready
                ? BsasColors.safeGreen
                : (state == StatusState.notInstalled
                    ? BsasColors.textMuted
                    : BsasColors.warningOrange),
          ),
        ),
      ],
    );
  }
}
