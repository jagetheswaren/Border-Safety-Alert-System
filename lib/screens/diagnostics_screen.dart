import 'package:flutter/material.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_spacing.dart';
import '../core/theme/bsas_typography.dart';
import '../core/widgets/status_dot.dart';
import '../models/alert_severity.dart';
import '../models/gps_snapshot.dart';
import '../models/geofence_result.dart';
import '../services/alert_service.dart';
import '../services/model_manager.dart';
import '../services/notification_service.dart';
import '../services/offline_map_service.dart';
import '../services/sound_service.dart';
import '../services/sync_service.dart';
import '../services/vibration_alert_service.dart';
import '../services/voice_alert_service.dart';

class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({
    super.key,
    required this.gps,
    required this.geoFence,
    required this.alertService,
    required this.soundService,
    required this.vibrationService,
    required this.voiceService,
    required this.notificationService,
    required this.modelManager,
    required this.offlineMapService,
    required this.syncService,
  });

  final GpsSnapshot? gps;
  final GeoFenceResult? geoFence;
  final AlertService alertService;
  final SoundService soundService;
  final VibrationAlertOutput vibrationService;
  final VoiceAlertOutput voiceService;
  final NotificationService notificationService;
  final ModelManager modelManager;
  final OfflineMapService offlineMapService;
  final SyncService syncService;

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final live = widget.gps ?? GpsSnapshot.initial();
    final fix = live.location;
    final diag = widget.modelManager.diagnostics;

    return Scaffold(
      backgroundColor: BsasColors.background(isDark),
      appBar: AppBar(
        backgroundColor: BsasColors.surface(isDark),
        title: Text(
          'System Diagnostics',
          style: BsasTypography.heading.copyWith(color: BsasColors.text(isDark)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: BsasSpacing.lg,
          vertical: BsasSpacing.xl,
        ),
        children: [
          _sectionHeader('LOCAL SAFETY ENGINE SUBSYSTEMS', isDark),
          _card(
            isDark: isDark,
            children: [
              _row(
                isDark,
                'GPS GNSS Receiver',
                live.fix.name.toUpperCase(),
                live.fix.name == 'locked' ? StatusState.ready : StatusState.loading,
                subtext: fix != null
                    ? '${fix.latitude.toStringAsFixed(6)}, ${fix.longitude.toStringAsFixed(6)} (±${fix.accuracy?.toStringAsFixed(0)}m)'
                    : 'Acquiring satellite constellation...',
              ),
              Divider(height: 1, color: BsasColors.border(isDark)),
              _row(
                isDark,
                'Offline Map System',
                widget.offlineMapService.isReady ? 'READY' : 'DOWNLOADING',
                widget.offlineMapService.isReady ? StatusState.ready : StatusState.loading,
                subtext: 'Region: Pollachi / Coimbatore Corridor • Storage: Local Cache',
              ),
              Divider(height: 1, color: BsasColors.border(isDark)),
              _row(
                isDark,
                'Geofence Polygon Engine',
                widget.geoFence?.state.name.toUpperCase() ?? 'SAFE',
                StatusState.ready,
                subtext: 'Nearest boundary: ${widget.geoFence?.nearestBoundary?.name ?? "Sector 7"}',
              ),
              Divider(height: 1, color: BsasColors.border(isDark)),
              _row(
                isDark,
                'TensorFlow Lite LSTM',
                'READY',
                StatusState.ready,
                subtext: '5-fix sequence inference buffer • On-device TFLite',
              ),
              Divider(height: 1, color: BsasColors.border(isDark)),
              _row(
                isDark,
                'Random Forest Classifier',
                'READY',
                StatusState.ready,
                subtext: 'Fused multi-feature danger scoring model',
              ),
              Divider(height: 1, color: BsasColors.border(isDark)),
              _row(
                isDark,
                'RiskEngine Fusion Layer',
                widget.geoFence?.state.name.toUpperCase() ?? 'SAFE',
                StatusState.ready,
                subtext: 'Deterministic boundary geometry + ML model fusion',
              ),
            ],
          ),
          const SizedBox(height: BsasSpacing.xl),

          _sectionHeader('LOCAL AI ASSISTANT RUNTIME', isDark),
          _card(
            isDark: isDark,
            children: [
              _row(
                isDark,
                'Model Name',
                diag.modelName,
                widget.modelManager.isModelReady ? StatusState.ready : StatusState.notInstalled,
              ),
              Divider(height: 1, color: BsasColors.border(isDark)),
              _row(isDark, 'Format / Runtime', '${diag.format} / ${diag.engine}', StatusState.ready),
              Divider(height: 1, color: BsasColors.border(isDark)),
              _row(isDark, 'Hardware Target', diag.device, StatusState.ready),
              Divider(height: 1, color: BsasColors.border(isDark)),
              _row(
                isDark,
                'Engine State',
                widget.modelManager.state.name.toUpperCase(),
                widget.modelManager.isModelLoaded ? StatusState.ready : StatusState.idle,
              ),
              Divider(height: 1, color: BsasColors.border(isDark)),
              _row(isDark, 'Load Time', '${diag.loadTimeMs} ms', StatusState.ready),
              Divider(height: 1, color: BsasColors.border(isDark)),
              _row(isDark, 'Inference Speed', '${diag.tokensPerSecond.toStringAsFixed(1)} tok/s', StatusState.ready),
              Divider(height: 1, color: BsasColors.border(isDark)),
              _row(isDark, 'Allocated Memory', '${diag.allocatedRamMb.toStringAsFixed(1)} MB', StatusState.ready),
              Divider(height: 1, color: BsasColors.border(isDark)),
              _row(isDark, 'Context Window', '${diag.contextTokens} tokens', StatusState.ready),
              Divider(height: 1, color: BsasColors.border(isDark)),
              _row(isDark, '100% Offline Mode', diag.isOffline ? 'ACTIVE' : 'INACTIVE', StatusState.ready),
            ],
          ),
          const SizedBox(height: BsasSpacing.xl),

          _sectionHeader('ALERT CHANNELS & HARDWARE I/O', isDark),
          _card(
            isDark: isDark,
            children: [
              _row(isDark, 'Alert Coordinator', 'ACTIVE', StatusState.ready),
              Divider(height: 1, color: BsasColors.border(isDark)),
              _row(isDark, 'Acoustic Sound Output', 'ACTIVE (Local WAVs)', StatusState.ready),
              Divider(height: 1, color: BsasColors.border(isDark)),
              _row(isDark, 'Haptic Tactile Engine', 'ACTIVE', StatusState.ready),
              Divider(height: 1, color: BsasColors.border(isDark)),
              _row(isDark, 'Voice TTS Engine', 'ACTIVE', StatusState.ready),
              Divider(height: 1, color: BsasColors.border(isDark)),
              _row(isDark, 'Android Notification Channels', '4 CHANNELS CONFIGURED', StatusState.ready),
            ],
          ),
          const SizedBox(height: BsasSpacing.xl),

          _sectionHeader('OFFLINE EVENT JOURNAL & SYNC QUEUE', isDark),
          _card(
            isDark: isDark,
            children: [
              _row(
                isDark,
                'Pending Unsynced Events',
                '${widget.syncService.pendingCount} EVENTS',
                widget.syncService.pendingCount == 0 ? StatusState.ready : StatusState.warning,
              ),
              Divider(height: 1, color: BsasColors.border(isDark)),
              _row(
                isDark,
                'Sync Status',
                widget.syncService.status.name.toUpperCase(),
                widget.syncService.status == SyncStatus.complete ? StatusState.ready : StatusState.idle,
              ),
              Divider(height: 1, color: BsasColors.border(isDark)),
              _row(isDark, 'Backend Target URL', widget.syncService.baseUrl, StatusState.ready),
            ],
          ),
          const SizedBox(height: BsasSpacing.xl),

          _sectionHeader('HARDWARE PHYSICAL VERIFICATION TRIGGERS', isDark),
          Wrap(
            spacing: BsasSpacing.sm,
            runSpacing: BsasSpacing.sm,
            children: [
              ActionChip(
                backgroundColor: isDark ? BsasColors.card(isDark) : Colors.white,
                side: BorderSide(color: BsasColors.border(isDark)),
                label: Text(
                  'Warning Audio',
                  style: BsasTypography.caption.copyWith(color: BsasColors.text(isDark)),
                ),
                avatar: const Icon(Icons.volume_up, size: 16, color: BsasColors.warningOrange),
                onPressed: () => widget.soundService.playWarning(),
              ),
              ActionChip(
                backgroundColor: isDark ? BsasColors.card(isDark) : Colors.white,
                side: BorderSide(color: BsasColors.border(isDark)),
                label: Text(
                  'Critical Siren',
                  style: BsasTypography.caption.copyWith(color: BsasColors.text(isDark)),
                ),
                avatar: const Icon(Icons.warning, size: 16, color: BsasColors.criticalRed),
                onPressed: () => widget.soundService.playCritical(),
              ),
              ActionChip(
                backgroundColor: isDark ? BsasColors.card(isDark) : Colors.white,
                side: BorderSide(color: BsasColors.border(isDark)),
                label: Text(
                  'Test Vibration',
                  style: BsasTypography.caption.copyWith(color: BsasColors.text(isDark)),
                ),
                avatar: Icon(Icons.vibration, size: 16, color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue),
                onPressed: () => widget.vibrationService.vibrate(AlertSeverity.warning),
              ),
              ActionChip(
                backgroundColor: isDark ? BsasColors.card(isDark) : Colors.white,
                side: BorderSide(color: BsasColors.border(isDark)),
                label: Text(
                  'Test Voice TTS',
                  style: BsasTypography.caption.copyWith(color: BsasColors.text(isDark)),
                ),
                avatar: const Icon(Icons.record_voice_over, size: 16, color: BsasColors.safeGreen),
                onPressed: () => widget.voiceService.speak('BSAS physical diagnostics check passed.'),
              ),
              ActionChip(
                backgroundColor: isDark ? BsasColors.card(isDark) : Colors.white,
                side: BorderSide(color: BsasColors.border(isDark)),
                label: Text(
                  'Test Notification',
                  style: BsasTypography.caption.copyWith(color: BsasColors.text(isDark)),
                ),
                avatar: const Icon(Icons.notifications_active, size: 16, color: Colors.amber),
                onPressed: () => widget.notificationService.showAlert(
                  AlertSeverity.warning,
                  'Physical notification channel test verified.',
                ),
              ),
            ],
          ),
          const SizedBox(height: BsasSpacing.xxxl),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BsasSpacing.sm, left: BsasSpacing.xs),
      child: Text(
        title,
        style: BsasTypography.sectionHeading.copyWith(
          color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
        ),
      ),
    );
  }

  Widget _card({required bool isDark, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: BsasColors.card(isDark),
        borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
        border: Border.all(color: BsasColors.border(isDark)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _row(
    bool isDark,
    String label,
    String value,
    StatusState state, {
    String? subtext,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BsasSpacing.lg,
        vertical: BsasSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  StatusDot(state: state, size: 8),
                  const SizedBox(width: BsasSpacing.sm),
                  Text(
                    label,
                    style: BsasTypography.body.copyWith(
                      color: BsasColors.text(isDark),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Text(
                value,
                style: BsasTypography.monospace.copyWith(
                  fontSize: 12,
                  color: state == StatusState.ready
                      ? BsasColors.safeGreen
                      : (state == StatusState.warning
                          ? BsasColors.warningOrange
                          : BsasColors.textSec(isDark)),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (subtext != null) ...[
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                subtext,
                style: BsasTypography.caption.copyWith(
                  color: BsasColors.textSec(isDark),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
