import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_typography.dart';

class PermissionSetupScreen extends StatefulWidget {
  const PermissionSetupScreen({super.key});

  @override
  State<PermissionSetupScreen> createState() => _PermissionSetupScreenState();
}

class _PermissionSetupScreenState extends State<PermissionSetupScreen> {
  LocationPermission _locationPermission = LocationPermission.denied;
  bool _locationServiceEnabled = false;
  bool _notificationsGranted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);
    try {
      final locEnabled = await Geolocator.isLocationServiceEnabled();
      final locPerm = await Geolocator.checkPermission();
      
      final fln = FlutterLocalNotificationsPlugin();
      final notifPerm = await fln.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled() ?? true;

      if (mounted) {
        setState(() {
          _locationServiceEnabled = locEnabled;
          _locationPermission = locPerm;
          _notificationsGranted = notifPerm;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _requestLocation() async {
    try {
      final perm = await Geolocator.requestPermission();
      if (mounted) {
        setState(() => _locationPermission = perm);
      }
      await _checkPermissions();
    } catch (_) {}
  }

  Future<void> _requestNotifications() async {
    try {
      final fln = FlutterLocalNotificationsPlugin();
      final androidImpl = fln.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidImpl?.requestNotificationsPermission() ?? false;
      if (mounted) {
        setState(() => _notificationsGranted = granted);
      }
      await _checkPermissions();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final hasLoc = _locationPermission == LocationPermission.always ||
        _locationPermission == LocationPermission.whileInUse;

    return Scaffold(
      key: const Key('screen-permissions'),
      backgroundColor: BsasColors.darkBackground,
      appBar: AppBar(
        backgroundColor: BsasColors.darkSurface,
        title: const Text('System Permissions', style: BsasTypography.headline),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: BsasColors.radarCyan))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 8),
                Text(
                  'MANDATORY HARDWARE ACCESS',
                  style: BsasTypography.caption.copyWith(
                    color: BsasColors.radarCyan,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'BSAS operates offline and strictly processes all geospatial telemetry on your local device. '
                  'The following permissions are required for life-safety alerting.',
                  style: BsasTypography.body.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 20),

                // 1. Precise GNSS Location Card
                Card(
                  color: BsasColors.darkSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: hasLoc ? BsasColors.safeGreen : BsasColors.warningOrange,
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.gps_fixed, color: hasLoc ? BsasColors.safeGreen : BsasColors.warningOrange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Precise GPS / GNSS Location',
                                style: BsasTypography.title.copyWith(fontSize: 16),
                              ),
                            ),
                            _badge(
                              hasLoc ? 'GRANTED' : (_locationPermission == LocationPermission.deniedForever ? 'DENIED' : 'REQUIRED'),
                              hasLoc,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Required for continuous point-in-polygon border distance calculation and deterministic geofence evaluation.',
                          style: BsasTypography.caption.copyWith(color: Colors.white70),
                        ),
                        if (!_locationServiceEnabled) ...[
                          const SizedBox(height: 8),
                          const Text(
                            '⚠️ Hardware Location Services (GPS) are currently DISABLED on this device.',
                            style: TextStyle(color: BsasColors.criticalRed, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (!hasLoc)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: BsasColors.radarCyan),
                                onPressed: _requestLocation,
                                child: const Text('GRANT ACCESS', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () => Geolocator.openLocationSettings(),
                              child: const Text('DEVICE GPS SETTINGS', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Android System Notifications Card
                Card(
                  color: BsasColors.darkSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _notificationsGranted ? BsasColors.safeGreen : BsasColors.warningOrange,
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.notifications_active,
                              color: _notificationsGranted ? BsasColors.safeGreen : BsasColors.warningOrange,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Android Notification Channel',
                                style: BsasTypography.title.copyWith(fontSize: 16),
                              ),
                            ),
                            _badge(
                              _notificationsGranted ? 'ACTIVE' : 'MUTED',
                              _notificationsGranted,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Dispatches high-importance notifications with custom alert sounds and vibration patterns during boundary escalation.',
                          style: BsasTypography.caption.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        if (!_notificationsGranted)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: BsasColors.radarCyan),
                            onPressed: _requestNotifications,
                            child: const Text('ENABLE NOTIFICATIONS', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // System Settings Link
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: BsasColors.darkBorder),
                  ),
                  icon: const Icon(Icons.settings, color: BsasColors.radarCyan),
                  label: const Text('OPEN ANDROID APP SETTINGS', style: TextStyle(color: Colors.white)),
                  onPressed: () => Geolocator.openAppSettings(),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.refresh, color: BsasColors.radarCyan, size: 18),
                    label: const Text('Re-check Status', style: TextStyle(color: BsasColors.radarCyan)),
                    onPressed: _checkPermissions,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _badge(String label, bool ok) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ok ? BsasColors.safeGreen.withValues(alpha: 0.2) : BsasColors.warningOrange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: ok ? BsasColors.safeGreen : BsasColors.warningOrange,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: ok ? BsasColors.safeGreen : BsasColors.warningOrange,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
