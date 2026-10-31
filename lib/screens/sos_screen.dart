import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_typography.dart';
import '../core/widgets/bsas_card.dart';
import '../core/widgets/status_badge.dart';
import '../models/gps_snapshot.dart';
import '../models/safety_state.dart';
import '../models/sos_delivery.dart';
import '../services/sos_service.dart';
import 'emergency_contacts_screen.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({
    super.key,
    required this.sosService,
    required this.gps,
  });

  final SosService sosService;
  final GpsSnapshot gps;

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
      value: 1.0,
    );

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    widget.sosService.addListener(_onSosChanged);
    if (widget.sosService.hasActiveEmergency) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _onSosChanged() {
    if (!mounted) return;
    if (widget.sosService.hasActiveEmergency) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    widget.sosService.removeListener(_onSosChanged);
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerSos() {
    widget.sosService.triggerOneTapSos(gps: widget.gps);
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BsasColors.darkSurface,
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: BsasColors.safeGreen),
            SizedBox(width: 8),
            Text('Cancel Emergency Alert', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Are you safe? Cancelling will notify all emergency contacts that you are out of danger.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Back', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: BsasColors.safeGreen),
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.sosService.cancelSos(reason: 'User safe / false alarm resolved');
            },
            child: const Text('Confirm Safe', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.sosService,
      builder: (context, _) {
        final activeEvent = widget.sosService.activeEvent;
        final isEmergency = widget.sosService.hasActiveEmergency;
        final deliveries = widget.sosService.activeDeliveries;
        final isProcessing = widget.sosService.isProcessing;

        final loc = widget.gps.location;
        final latStr = loc?.latitude.toStringAsFixed(6) ?? 'Detecting...';
        final lonStr = loc?.longitude.toStringAsFixed(6) ?? 'Detecting...';
        final accStr = loc?.accuracy != null ? '±${loc!.accuracy!.round()} m' : 'Uncertain';

        return Scaffold(
          backgroundColor: BsasColors.darkBg,
          appBar: AppBar(
            backgroundColor: BsasColors.darkSurface,
            title: Row(
              children: [
                const Icon(Icons.emergency_share_rounded, color: BsasColors.dangerRed),
                const SizedBox(width: 8),
                Text('ONE-TAP SOS', style: BsasTypography.heading.copyWith(color: Colors.white)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.contacts_rounded, color: BsasColors.radarCyan),
                tooltip: 'Emergency Contacts',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Emergency Status Banner
                if (isEmergency)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: BsasColors.dangerRed.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: BsasColors.dangerRed, width: 2),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warning_amber_rounded, color: BsasColors.dangerRed, size: 28),
                            SizedBox(width: 8),
                            Text(
                              'EMERGENCY SOS ACTIVE',
                              style: TextStyle(
                                color: BsasColors.dangerRed,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Event UUID: ${activeEvent?.eventUuid ?? "N/A"}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'monospace'),
                        ),
                        Text(
                          'Activated at: ${activeEvent != null ? DateFormat("hh:mm:ss a").format(activeEvent.createdAt) : "Just now"}',
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BsasColors.safeGreen,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          icon: const Icon(Icons.check_circle_rounded),
                          label: const Text('CANCEL SOS — I AM SAFE', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: _showCancelDialog,
                        ),
                      ],
                    ),
                  ),

                // Main Circular One-Tap SOS Button
                Center(
                  child: ScaleTransition(
                    scale: isEmergency ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                    child: GestureDetector(
                      onTap: isProcessing ? null : _triggerSos,
                      child: Container(
                        width: 210,
                        height: 210,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: isEmergency
                                ? [const Color(0xFFFF1744), const Color(0xFFD50000), const Color(0xFF880E4F)]
                                : [const Color(0xFFFF5252), const Color(0xFFD32F2F), const Color(0xFF7B1FA2)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isEmergency ? BsasColors.dangerRed : Colors.redAccent).withValues(alpha: 0.55),
                              blurRadius: 32,
                              spreadRadius: isEmergency ? 12 : 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.sos_rounded, size: 76, color: Colors.white),
                              const SizedBox(height: 4),
                              Text(
                                isEmergency ? 'ALERTING' : 'TAP FOR SOS',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isEmergency ? 'Sending coordinates' : 'Immediate SMS & WhatsApp',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Live Location & Signal Telemetry Card
                BsasCard(
                  title: 'EMERGENCY LOCATION & SIGNAL',
                  status: StatusBadge(
                    label: widget.gps.fix == GpsFixState.locked ? 'GPS LOCKED' : 'GPS SEARCHING',
                    color: widget.gps.fix == GpsFixState.locked ? BsasColors.safeGreen : BsasColors.warningYellow,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _telemetryItem('Latitude', latStr),
                          _telemetryItem('Longitude', lonStr),
                        ],
                      ),
                      const Divider(color: Colors.white12, height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _telemetryItem('Accuracy', accStr),
                          _telemetryItem('Signal Status', widget.gps.stale ? 'Weak / Single Tower' : 'Strong Signal'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Deliveries & Emergency Contacts Card
                BsasCard(
                  title: 'RECIPIENTS & DELIVERY STATUS',
                  status: StatusBadge(
                    label: '${deliveries.length} Channels',
                    color: BsasColors.radarCyan,
                  ),
                  child: deliveries.isEmpty
                      ? Column(
                          children: [
                            const Text(
                              'Tap the SOS button above to immediately dispatch emergency SMS and location alerts to all active contacts.',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(foregroundColor: BsasColors.radarCyan),
                              icon: const Icon(Icons.manage_accounts_rounded),
                              label: const Text('Manage Emergency Contacts'),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()),
                                );
                              },
                            ),
                          ],
                        )
                      : Column(
                          children: deliveries.map((d) {
                            final isSms = d.channel == SosDeliveryChannel.sms;
                            final isDelivered = d.status == SosDeliveryStatus.delivered;
                            final isFailed = d.status == SosDeliveryStatus.failed;

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: BsasColors.darkSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDelivered
                                      ? BsasColors.safeGreen.withValues(alpha: 0.4)
                                      : (isFailed ? BsasColors.dangerRed.withValues(alpha: 0.4) : Colors.white10),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSms ? Icons.sms_rounded : Icons.chat_rounded,
                                    color: isSms ? BsasColors.radarCyan : Colors.greenAccent,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          d.contactName,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        Text(
                                          '${d.channel.name.toUpperCase()}: ${d.phoneNumber}',
                                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                                        ),
                                        if (d.errorMessage != null)
                                          Text(
                                            d.errorMessage!,
                                            style: const TextStyle(color: BsasColors.warningYellow, fontSize: 11),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (!isSms && d.channel == SosDeliveryChannel.whatsapp)
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      ),
                                      icon: const Icon(Icons.share, size: 14),
                                      label: const Text('Send WA', style: TextStyle(fontSize: 12)),
                                      onPressed: () => widget.sosService.initiateWhatsAppHandoff(d),
                                    )
                                  else
                                    StatusBadge(
                                      label: d.status.name.toUpperCase(),
                                      color: isDelivered
                                          ? BsasColors.safeGreen
                                          : (isFailed ? BsasColors.dangerRed : BsasColors.warningYellow),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _telemetryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
