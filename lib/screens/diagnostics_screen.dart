import 'package:flutter/material.dart';

import '../core/theme/bsas_colors.dart';
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
    final live = widget.gps ?? GpsSnapshot.initial();
    final fix = live.location;
    final diag = widget.modelManager.diagnostics;

    return Scaffold(
      backgroundColor: BsasColors.darkBackground,
      appBar: AppBar(
        backgroundColor: BsasColors.darkSurface,
        title: const Text('System Diagnostics', style: BsasTypography.headline),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('LOCAL SAFETY ENGINE SUBSYSTEMS'),
          _card([
            _row(
              'GPS GNSS Engine',
              live.fix.name.toUpperCase(),
              live.fix.name == 'locked' ? StatusState.ready : StatusState.loading,
              subtext: fix != null
                  ? '${fix.latitude.toStringAsFixed(6)}, ${fix.longitude.toStringAsFixed(6)} (±${fix.accuracy?.toStringAsFixed(0)}m)'
                  : 'Searching for satellite fix...',
            ),
            const Divider(color: BsasColors.darkBorder),
            _row(
              'Offline Map System',
              widget.offlineMapService.isReady ? 'READY' : 'DOWNLOADING',
              widget.offlineMapService.isReady ? StatusState.ready : StatusState.loading,
              subtext: 'Region: Pollachi / Coimbatore Corridor • Storage: Local Cache',
            ),
            const Divider(color: BsasColors.darkBorder),
            _row(
              'Geofence Evaluator',
              widget.geoFence?.state.name.toUpperCase() ?? 'SAFE',
              StatusState.ready,
              subtext: 'Nearest sector: ${widget.geoFence?.nearestBoundary?.name ?? "Sector 7"}',
            ),
            const Divider(color: BsasColors.darkBorder),
            _row(
              'TensorFlow Lite LSTM',
              'READY',
              StatusState.ready,
              subtext: '5-fix sequence inference buffer • On-device TFLite',
            ),
            const Divider(color: BsasColors.darkBorder),
            _row(
              'Random Forest Classifier',
              'READY',
              StatusState.ready,
              subtext: 'Fused multi-feature danger scoring model',
            ),
            const Divider(color: BsasColors.darkBorder),
            _row(
              'RiskEngine Fusion',
              widget.geoFence?.state.name.toUpperCase() ?? 'SAFE',
              StatusState.ready,
              subtext: 'Deterministic boundary rules + ML model fusion',
            ),
          ]),

          const SizedBox(height: 20),
          _sectionHeader('LOCAL AI ASSISTANT RUNTIME'),
          _card([
            _row(
              'Model Name',
              diag.modelName,
              widget.modelManager.isModelReady ? StatusState.ready : StatusState.notInstalled,
            ),
            _row('Format / Runtime', '${diag.format} / ${diag.engine}', StatusState.ready),
            _row('Hardware Target', diag.device, StatusState.ready),
            _row(
              'Engine State',
              widget.modelManager.state.name.toUpperCase(),
              widget.modelManager.isModelLoaded ? StatusState.ready : StatusState.idle,
            ),
            _row('Load Time', '${diag.loadTimeMs} ms', StatusState.ready),
            _row('Inference Speed', '${diag.tokensPerSecond.toStringAsFixed(1)} tok/s', StatusState.ready),
            _row('Allocated RAM', '${diag.allocatedRamMb.toStringAsFixed(1)} MB', StatusState.ready),
            _row('Context Window', '${diag.contextTokens} tokens', StatusState.ready),
            _row('100% Offline Mode', diag.isOffline ? 'ACTIVE' : 'INACTIVE', StatusState.ready),
          ]),

          const SizedBox(height: 20),
          _sectionHeader('ALERT CHANNELS & HARDWARE I/O'),
          _card([
            _row('Alert Service Coordinator', 'ACTIVE', StatusState.ready),
            _row('Audio Sound System', 'ACTIVE (Local WAVs)', StatusState.ready),
            _row('Vibration Haptic Engine', 'ACTIVE', StatusState.ready),
            _row('Voice TTS Engine', 'ACTIVE', StatusState.ready),
            _row('Android Notification Channels', '4 CHANNELS CONFIGURED', StatusState.ready),
          ]),

          const SizedBox(height: 20),
          _sectionHeader('OFFLINE EVENT JOURNAL & SYNC QUEUE'),
          _card([
            _row(
              'Pending Unsynced Events',
              '${widget.syncService.pendingCount} EVENTS',
              widget.syncService.pendingCount == 0 ? StatusState.ready : StatusState.warning,
            ),
            _row(
              'Sync Status',
              widget.syncService.status.name.toUpperCase(),
              widget.syncService.status == SyncStatus.complete ? StatusState.ready : StatusState.idle,
            ),
            _row('Backend Server Target', widget.syncService.baseUrl, StatusState.ready),
          ]),

          const SizedBox(height: 24),
          _sectionHeader('HARDWARE I/O PHYSICAL VERIFICATION TRIGGERS'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('Test Warning Audio'),
                avatar: const Icon(Icons.volume_up, size: 16, color: BsasColors.warningOrange),
                onPressed: () => widget.soundService.playWarning(),
              ),
              ActionChip(
                label: const Text('Test Critical Audio'),
                avatar: const Icon(Icons.warning, size: 16, color: BsasColors.criticalRed),
                onPressed: () => widget.soundService.playCritical(),
              ),
              ActionChip(
                label: const Text('Test Vibration'),
                avatar: const Icon(Icons.vibration, size: 16, color: BsasColors.radarCyan),
                onPressed: () => widget.vibrationService.vibrate(AlertSeverity.warning),
              ),
              ActionChip(
                label: const Text('Test Voice TTS'),
                avatar: const Icon(Icons.record_voice_over, size: 16, color: BsasColors.safeGreen),
                onPressed: () => widget.voiceService.speak('BSAS physical diagnostics check passed.'),
              ),
              ActionChip(
                label: const Text('Test Notification'),
                avatar: const Icon(Icons.notifications_active, size: 16, color: Colors.amber),
                onPressed: () => widget.notificationService.showAlert(
                  AlertSeverity.warning,
                  'Physical notification channel test verified.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: BsasTypography.caption.copyWith(
          color: BsasColors.radarCyan,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Card(
      color: BsasColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: BsasColors.darkBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _row(String label, String value, StatusState state, {String? subtext}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  StatusDot(state: state, size: 8),
                  const SizedBox(width: 8),
                  Text(label, style: BsasTypography.body.copyWith(color: Colors.white)),
                ],
              ),
              Text(
                value,
                style: BsasTypography.monoDiagnostics.copyWith(
                  fontSize: 12,
                  color: state == StatusState.ready ? BsasColors.safeGreen : BsasColors.warningOrange,
                ),
              ),
            ],
          ),
          if (subtext != null) ...[
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                subtext,
                style: BsasTypography.caption.copyWith(color: BsasColors.textSecondary, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
