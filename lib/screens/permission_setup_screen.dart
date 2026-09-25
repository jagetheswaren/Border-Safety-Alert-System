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
        
    final allGranted = hasLoc && _locationServiceEnabled && _notificationsGranted;

    return Scaffold(
      key: const Key('screen-permissions'),
      backgroundColor: BsasColors.background(isDark),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue))
          : CustomScrollView(
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
                      Icon(Icons.shield_outlined, color: BsasColors.radarCyan, size: 20),
                      const SizedBox(width: BsasSpacing.sm),
                      Text(
                        'SYSTEM PERMISSIONS',
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
                      color: BsasColors.border(isDark),
                      height: 1.0,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.lg, vertical: BsasSpacing.xl),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        _sectionHeader('MANDATORY HARDWARE ACCESS', isDark),
                        Container(
                          padding: const EdgeInsets.all(BsasSpacing.lg),
                          decoration: BoxDecoration(
                            color: BsasColors.primaryBlue.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
                            border: Border.all(color: BsasColors.primaryBlue.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            'BSAS operates offline and relies directly on local Android hardware sensors. Granted permissions never communicate telemetry externally.',
                            style: BsasTypography.body.copyWith(
                              fontSize: 13,
                              color: BsasColors.textSec(isDark),
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: BsasSpacing.xl),

                        // 1. Precise GNSS Location Permission
                        _permissionCard(
                          isDark: isDark,
                          title: 'PRECISE GNSS GEOLOCATION',
                          subtitle: 'Required for real-time distance calculations and boundary geofencing.',
                          icon: Icons.location_on_outlined,
                          isGranted: hasLoc,
                          onRequest: _requestLocation,
                          statusText: hasLoc ? 'GRANTED' : 'REQUIRED',
                        ),
                        const SizedBox(height: BsasSpacing.md),

                        // 2. Android Location Services Hardware Switch
                        _permissionCard(
                          isDark: isDark,
                          title: 'DEVICE LOCATION SERVICES',
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
                          isDark: isDark,
                          title: 'EMERGENCY NOTIFICATIONS',
                          subtitle: 'Dispatches boundary warnings and acoustic escalation notices.',
                          icon: Icons.notifications_active_outlined,
                          isGranted: _notificationsGranted,
                          onRequest: _requestNotifications,
                          statusText: _notificationsGranted ? 'ACTIVE' : 'OPTIONAL',
                        ),
                        const SizedBox(height: BsasSpacing.xxl),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: BsasSpacing.lg),
                              backgroundColor: allGranted 
                                ? (isDark ? BsasColors.radarCyan : BsasColors.primaryBlue)
                                : BsasColors.card(isDark),
                              foregroundColor: allGranted
                                ? Colors.black
                                : BsasColors.textSec(isDark),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
                                side: BorderSide(
                                  color: allGranted ? Colors.transparent : BsasColors.border(isDark),
                                ),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              'CONFIRM CONFIGURATION',
                              style: BsasTypography.monospace.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: allGranted 
                                  ? (isDark ? Colors.black : Colors.white)
                                  : BsasColors.textSec(isDark),
                              ),
                            ),
                          ),
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

  Widget _permissionCard({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onRequest,
    required String statusText,
  }) {
    return Container(
      padding: const EdgeInsets.all(BsasSpacing.lg),
      decoration: BoxDecoration(
        color: BsasColors.card(isDark),
        borderRadius: BorderRadius.circular(BsasSpacing.cardRadius),
        border: Border.all(
          color: isGranted ? BsasColors.safeGreen : BsasColors.border(isDark),
          width: isGranted ? 1.5 : 1.0,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : [
                BoxShadow(
                  color: BsasColors.lightBorder,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(BsasSpacing.sm),
                decoration: BoxDecoration(
                  color: (isGranted ? BsasColors.safeGreen : (isDark ? BsasColors.radarCyan : BsasColors.primaryBlue)).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon, 
                  size: 20, 
                  color: isGranted ? BsasColors.safeGreen : (isDark ? BsasColors.radarCyan : BsasColors.primaryBlue)
                ),
              ),
              const SizedBox(width: BsasSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: BsasTypography.monospace.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: BsasColors.text(isDark),
                  ),
                ),
              ),
              StatusBadge(
                label: statusText,
                state: isGranted ? StatusState.ready : StatusState.warning,
              ),
            ],
          ),
          const SizedBox(height: BsasSpacing.md),
          Text(
            subtitle,
            style: BsasTypography.body.copyWith(
              fontSize: 13,
              color: BsasColors.textSec(isDark),
              height: 1.4,
            ),
          ),
          if (!isGranted) ...[
            const SizedBox(height: BsasSpacing.lg),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(BsasSpacing.buttonRadius),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: BsasSpacing.xl, vertical: BsasSpacing.md),
                ),
                onPressed: onRequest,
                child: Text(
                  'GRANT ACCESS',
                  style: BsasTypography.monospace.copyWith(
                    color: isDark ? BsasColors.radarCyan : BsasColors.primaryBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
