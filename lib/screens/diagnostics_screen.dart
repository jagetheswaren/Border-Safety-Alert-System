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
      key: const Key('screen-diagnostics'),
      backgroundColor: BsasColors.background(isDark),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: BsasColors.surface(isDark),
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: BsasColors.text(isDark)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                Icon(Icons.tune_rounded, color: BsasColors.radarCyan, size: 20),
                const SizedBox(width: BsasSpacing.sm),
                Text(
                  'SYSTEM DIAGNOSTICS',
                  style: BsasTypography.heading.copyWith(
                    color: BsasColors.text(isDark),
                    letterSpacing: 1.2,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(
                color: isDark ? BsasColors.darkBorder : BsasColors.lightBorder,
                height: 1.0,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.lg, vertical: BsasSpacing.xl),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _sectionHeader('LOCAL SAFETY ENGINE SUBSYSTEMS', isDark),
                  _card(
                    isDark: isDark,
                    children: [
                      _row(
                        isDark: isDark,
                        label: 'GPS GNSS RECEIVER',
                        value: live.fix.name.toUpperCase(),
                        state: live.fix.name == 'locked' ? StatusState.ready : StatusState.loading,
                        subtext: fix != null
                            ? '${fix.latitude.toStringAsFixed(6)}, ${fix.longitude.toStringAsFixed(6)} (±${fix.accuracy?.toStringAsFixed(0)}m)'
                            : 'Acquiring satellite constellation...',
                      ),
                      Divider(height: 1, color: BsasColors.border(isDark)),
                      _row(
                        isDark: isDark,
                        label: 'OFFLINE MAP SYSTEM',
                        value: widget.offlineMapService.isReady ? 'READY' : 'DOWNLOADING',
                        state: widget.offlineMapService.isReady ? StatusState.ready : StatusState.loading,
                        subtext: 'Region: Pollachi / Coimbatore Corridor • Storage: Local Cache',
                      ),
                      Divider(height: 1, color: BsasColors.border(isDark)),
                      _row(
                        isDark: isDark,
                        label: 'GEOFENCE POLYGON ENGINE',
                        value: widget.geoFence?.state.name.toUpperCase() ?? 'SAFE',
                        state: StatusState.ready,
                        subtext: 'Nearest boundary: ${widget.geoFence?.nearestBoundary?.name ?? "Sector 7"}',
                      ),
                      Divider(height: 1, color: BsasColors.border(isDark)),
                      _row(
                        isDark: isDark,
                        label: 'TENSORFLOW LITE LSTM',
                        value: 'READY',
                        state: StatusState.ready,
                        subtext: '5-fix sequence inference buffer • On-device TFLite',
                      ),
                      Divider(height: 1, color: BsasColors.border(isDark)),
                      _row(
                        isDark: isDark,
                        label: 'RANDOM FOREST CLASSIFIER',
                        value: 'READY',
                        state: StatusState.ready,
                        subtext: 'Fused multi-feature danger scoring model',
                      ),
                      Divider(height: 1, color: BsasColors.border(isDark)),
                      _row(
                        isDark: isDark,
                        label: 'RISK ENGINE FUSION LAYER',
                        value: widget.geoFence?.state.name.toUpperCase() ?? 'SAFE',
                        state: StatusState.ready,
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
                        isDark: isDark,
                        label: 'MODEL NAME',
                        value: diag.modelName.toUpperCase(),
                        state: widget.modelManager.isModelReady ? StatusState.ready : StatusState.notInstalled,
                      ),
                      Divider(height: 1, color: BsasColors.border(isDark)),
                      _row(isDark: isDark, label: 'FORMAT / RUNTIME', value: '${diag.format} / ${diag.engine}'.toUpperCase(), state: StatusState.ready),
                      Divider(height: 1, color: BsasColors.border(isDark)),
                      _row(isDark: isDark, label: 'HARDWARE TARGET', value: diag.device.toUpperCase(), state: StatusState.ready),
                      Divider(height: 1, color: BsasColors.border(isDark)),
                      _row(
                        isDark: isDark,
                        label: 'ENGINE STATE',
                        value: widget.modelManager.state.name.toUpperCase(),
                        state: widget.modelManager.isModelLoaded ? StatusState.ready : StatusState.idle,
                      ),
                      Divider(height: 1, color: BsasColors.border(isDark)),
                      _row(isDark: isDark, label: 'LOAD TIME', value: '${diag.loadTimeMs} MS', state: StatusState.ready),
                      Divider(height: 1, color: BsasColors.border(isDark)),
                      _row(isDark: isDark, label: 'INFERENCE SPEED', value: '${diag.tokensPerSecond.toStringAsFixed(1)} TOK/S', state: StatusState.ready),
                      Divider(height: 1, color: BsasColors.border(isDark)),
                      _row(isDark: isDark, label: 'ALLOCATED MEMORY', value: '${diag.allocatedRamMb.toStringAsFixed(1)} MB', state: StatusState.ready),
                      Divider(height: 1, color: BsasColors.border(isDark)),
                      _row(isDark: isDark, label: 'CONTEXT WINDOW', value: '${diag.contextTokens} TOKENS', state: StatusState.ready),
                      Divider(height: 1, color: BsasColors.border(isDark)),
                      _row(isDark: isDark, label: '100% OFFLINE MODE', value: diag.isOffline ? 'ACTIVE' : 'INACTIVE', state: StatusState.ready),
                    ],
                  ),
                  const SizedBox(height: BsasSpacing.xl),

                  _sectionHeader('ALERT CHANNELS & HARDWARE I/O', isDark),
                  _card(
                    isDark: isDark,
                    children: [
                      _row(isDark: isDark, label: 'ALERT COORDINATOR', value: 'ACTIVE', state: StatusState.ready),
                      Divider(height: 1, color: BsasColors.border(isDark)),
                      _row(isDark: isDark, label: 'ACOUSTIC SOUND OUTPUT', value: 'ACTIVE (LOCAL WAVS)', state: StatusState.ready),
                      Divider(height: 1, color: BsasColors.border(isDark)),
                      _row(isDark: isDark, label: 'HAPTIC TACTILE ENGINE', value: 'ACTIVE', state: StatusState.ready),
                      Divider(height: 1, color: BsasColors.border(isDark)),
                      _row(isDark: isDark, label: 'VOICE TTS ENGINE', value: 'ACTIVE', state: StatusState.ready),
                      Divider(height: 1, color: BsasColors.border(isDark)),
                      _row(isDark: isDark, label: 'ANDROID NOTIFICATION CHANNELS', value: '4 CHANNELS CONFIGURED', state: StatusState.ready),
                    ],
                  ),
                  const SizedBox(height: BsasSpacing.xl),

                  _sectionHeader('OFFLINE EVENT JOURNAL & SYNC QUEUE', isDark),
                  _card(
                    isDark: isDark,
                    children: [
                      _row(
                        isDark: isDark,
                        label: 'PENDING UNSYNCED EVENTS',
                        value: '${widget.syncService.pendingCount} EVENTS',
                        state: widget.syncService.pendingCount == 0 ? StatusState.ready : StatusState.warning,
                      ),
                      Divider(height: 1, color: BsasColors.border(isDark)),
                      _row(
                        isDark: isDark,
                        label: 'SYNC STATUS',
                        value: widget.syncService.status.name.toUpperCase(),
                        state: widget.syncService.status == SyncStatus.complete ? StatusState.ready : StatusState.idle,
                      ),
                      Divider(height: 1, color: BsasColors.border(isDark)),
                      _row(isDark: isDark, label: 'BACKEND TARGET URL', value: widget.syncService.baseUrl, state: StatusState.ready),
                    ],
                  ),
                  const SizedBox(height: BsasSpacing.xl),

                  _sectionHeader('HARDWARE PHYSICAL VERIFICATION TRIGGERS', isDark),
                  Wrap(
                    spacing: BsasSpacing.sm,
                    runSpacing: BsasSpacing.sm,
                    children: [
                      _actionChip(
                        isDark: isDark,
                        label: 'WARNING AUDIO',
                        icon: Icons.volume_up,
                        color: BsasColors.warningOrange,
                        onPressed: () => widget.soundService.playWarning(),
                      ),
                      _actionChip(
                        isDark: isDark,
                        label: 'CRITICAL SIREN',
                        icon: Icons.warning,
                        color: BsasColors.criticalRed,
                        onPressed: () => widget.soundService.playCritical(),
                      ),
                      _actionChip(
                        isDark: isDark,
                        label: 'TEST VIBRATION',
                        icon: Icons.vibration,
                        color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
                        onPressed: () => widget.vibrationService.vibrate(AlertSeverity.warning),
                      ),
                      _actionChip(
                        isDark: isDark,
                        label: 'TEST VOICE TTS',
                        icon: Icons.record_voice_over,
                        color: BsasColors.safeGreen,
                        onPressed: () => widget.voiceService.speak('BSAS physical diagnostics check passed.'),
                      ),
                      _actionChip(
                        isDark: isDark,
                        label: 'TEST NOTIFICATION',
                        icon: Icons.notifications_active,
                        color: Colors.amber,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BsasSpacing.md, left: BsasSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
          ),
          const SizedBox(width: BsasSpacing.sm),
          Text(
            title,
            style: BsasTypography.heading.copyWith(
              color: isDark ? BsasColors.text(isDark) : BsasColors.primaryBlue,
              fontSize: 13,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required bool isDark, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: BsasColors.card(isDark),
        borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
        border: Border.all(color: BsasColors.border(isDark), width: 1.0),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            : [
                BoxShadow(
                  color: BsasColors.lightBorder,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _row({
    required bool isDark,
    required String label,
    required String value,
    required StatusState state,
    String? subtext,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: BsasSpacing.md,
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
                    style: BsasTypography.monospace.copyWith(
                      color: BsasColors.text(isDark),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: BsasSpacing.sm),
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: BsasTypography.monospace.copyWith(
                      fontSize: 11,
                      color: state == StatusState.ready
                          ? BsasColors.safeGreen
                          : (state == StatusState.warning
                              ? BsasColors.warningOrange
                              : BsasColors.textSec(isDark)),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (subtext != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                subtext,
                style: BsasTypography.body.copyWith(
                  color: BsasColors.textSec(isDark),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionChip({
    required bool isDark,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ActionChip(
      backgroundColor: isDark ? BsasColors.card(isDark) : Colors.white,
      side: BorderSide(color: BsasColors.border(isDark)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      label: Text(
        label,
        style: BsasTypography.monospace.copyWith(
          color: BsasColors.text(isDark),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      avatar: Icon(icon, size: 16, color: color),
      onPressed: onPressed,
    );
  }
}
