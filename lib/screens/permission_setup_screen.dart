import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_spacing.dart';
import '../core/theme/bsas_typography.dart';
import '../core/widgets/status_badge.dart';

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
      final notifPerm = await fln
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          true;

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
      final androidImpl =
          fln.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidImpl?.requestNotificationsPermission() ?? false;
      if (mounted) {
        setState(() => _notificationsGranted = granted);
      }
      await _checkPermissions();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hasLoc = _locationPermission == LocationPermission.always ||
        _locationPermission == LocationPermission.whileInUse;

    return Scaffold(
      key: const Key('screen-permissions'),
      appBar: AppBar(
        title: const Text('System Permissions', style: BsasTypography.heading),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: BsasColors.primaryBlue))
          : ListView(
              padding: const EdgeInsets.all(BsasSpacing.screenMargin),
              children: [
                Text(
                  'MANDATORY HARDWARE ACCESS',
                  style: BsasTypography.sectionHeading.copyWith(
                    color: BsasColors.primaryBlue,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: BsasSpacing.sm),
                Text(
                  'BSAS operates offline and relies directly on local Android hardware sensors. Granted permissions never communicate telemetry externally.',
                  style: BsasTypography.body.copyWith(
                    fontSize: 13,
                    color: isDark ? BsasColors.textLightSecondary : BsasColors.textDarkSecondary,
                  ),
                ),
                const SizedBox(height: BsasSpacing.lg),

                // 1. Precise GNSS Location Permission
                _permissionCard(
                  context,
                  title: 'Precise GNSS Geolocation',
                  subtitle: 'Required for real-time distance calculations and boundary geofencing.',
                  icon: Icons.location_on_outlined,
                  isGranted: hasLoc,
                  onRequest: _requestLocation,
                  statusText: hasLoc ? 'GRANTED' : 'REQUIRED',
                ),
                const SizedBox(height: BsasSpacing.md),

                // 2. Android Location Services Hardware Switch
                _permissionCard(
                  context,
                  title: 'Device Location Services',
                  subtitle: 'Physical GPS satellite receiver must be enabled in device settings.',
                  icon: Icons.gps_fixed,
                  isGranted: _locationServiceEnabled,
                  onRequest: () async {
                    await Geolocator.openLocationSettings();
                    await _checkPermissions();
                  },
                  statusText: _locationServiceEnabled ? 'ACTIVE' : 'DISABLED',
                ),
                const SizedBox(height: BsasSpacing.md),

                // 3. High-Priority System Notifications
                _permissionCard(
                  context,
                  title: 'Emergency Notifications',
                  subtitle: 'Dispatches boundary warnings and acoustic escalation notices.',
                  icon: Icons.notifications_active_outlined,
                  isGranted: _notificationsGranted,
                  onRequest: _requestNotifications,
                  statusText: _notificationsGranted ? 'ACTIVE' : 'OPTIONAL',
                ),
                const SizedBox(height: BsasSpacing.xxl),

                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CONFIRM CONFIGURATION'),
                ),
              ],
            ),
    );
  }

  Widget _permissionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onRequest,
    required String statusText,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: BsasSpacing.cardInsets,
      decoration: BoxDecoration(
        color: isDark ? BsasColors.darkCard : BsasColors.lightCard,
        borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
        border: Border.all(
          color: isGranted ? BsasColors.safeGreen : (isDark ? BsasColors.darkBorder : BsasColors.lightBorder),
          width: isGranted ? 1.2 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: isGranted ? BsasColors.safeGreen : BsasColors.primaryBlue),
              const SizedBox(width: BsasSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: BsasTypography.title.copyWith(fontSize: 14),
                ),
              ),
              StatusBadge(
                label: statusText,
                color: isGranted ? BsasColors.safeGreen : BsasColors.warningOrange,
              ),
            ],
          ),
          const SizedBox(height: BsasSpacing.xs),
          Text(
            subtitle,
            style: BsasTypography.body.copyWith(
              fontSize: 12,
              color: isDark ? BsasColors.textLightSecondary : BsasColors.textDarkSecondary,
            ),
          ),
          if (!isGranted) ...[
            const SizedBox(height: BsasSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: onRequest,
                child: const Text('GRANT ACCESS'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
