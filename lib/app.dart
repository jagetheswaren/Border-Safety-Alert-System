import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'models/alert_preferences.dart';
import 'models/alert_severity.dart';
import 'models/geofence_result.dart';
import 'models/geofence_state.dart';
import 'models/gps_snapshot.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/diagnostics_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/route_screen.dart';
import 'screens/safety_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/sos_screen.dart';
import 'services/sos_service.dart';
import 'services/gis_layer_service.dart';
import 'services/ai_orchestrator.dart';
import 'services/alert_preferences_store.dart';
import 'services/alert_service.dart';
import 'services/boundary_summary.dart';
import 'services/chat_memory_service.dart';
import 'services/geofence_service.dart';
import 'services/gps_service.dart';
import 'services/local_chat_service.dart';
import 'services/local_event_store.dart';
import 'services/model_manager.dart';
import 'services/notification_service.dart';
import 'services/offline_map_service.dart';
import 'services/sound_service.dart';
import 'services/sync_service.dart';
import 'services/tracking_service.dart';
import 'services/vibration_alert_service.dart';
import 'services/voice_alert_service.dart';
import 'core/widgets/bsas_bottom_nav.dart';
import 'theme/app_theme.dart';

class BorderSafetyApp extends StatefulWidget {
  const BorderSafetyApp({
    super.key,
    this.gpsService,
    this.boundaryProvider,
    this.geoFenceService,
    this.alertService,
    this.alertPreferencesStore,
    this.showSplash = false,
  });

  final GpsService? gpsService;
  final BoundarySummaryProvider? boundaryProvider;
  final GeoFenceService? geoFenceService;
  final AlertService? alertService;
  final AlertPreferencesStore? alertPreferencesStore;
  final bool showSplash;

  @override
  State<BorderSafetyApp> createState() => _BorderSafetyAppState();
}

class _BorderSafetyAppState extends State<BorderSafetyApp> {
  late bool _displayingSplash;

  @override
  void initState() {
    super.initState();
    _displayingSplash = widget.showSplash;
  }

  @override
  Widget build(BuildContext context) {
    final gps = widget.gpsService ?? GpsService();
    final modelMgr = ModelManager();
    final mapService = OfflineMapService();

    return MaterialApp(
      title: 'Border Safety Alert System',
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: _displayingSplash
          ? SplashScreen(
              gpsService: gps,
              modelManager: modelMgr,
              offlineMapService: mapService,
              onFinished: () {
                if (mounted) setState(() => _displayingSplash = false);
              },
            )
          : AppShell(
              gpsService: widget.gpsService,
              boundaryProvider: widget.boundaryProvider,
              geoFenceService: widget.geoFenceService,
              alertService: widget.alertService,
              alertPreferencesStore: widget.alertPreferencesStore,
              modelManager: modelMgr,
              offlineMapService: mapService,
            ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.gpsService,
    this.boundaryProvider,
    this.geoFenceService,
    this.alertService,
    this.alertPreferencesStore,
    this.modelManager,
    this.offlineMapService,
  });

  final GpsService? gpsService;
  final BoundarySummaryProvider? boundaryProvider;
  final GeoFenceService? geoFenceService;
  final AlertService? alertService;
  final AlertPreferencesStore? alertPreferencesStore;
  final ModelManager? modelManager;
  final OfflineMapService? offlineMapService;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = kIsWeb ? 1 : 0;
  late final GpsService _gps;
  late final bool _ownsService;
  late final Future<BoundarySummary> _boundarySummary;
  late final GeoFenceService _geoFence;
  late final AlertService _alerts;
  late final AlertPreferencesStore _alertPreferencesStore;
  late final SoundService _soundService;
  late final VibrationAlertService _vibrationService;
  late final VoiceAlertService _voiceService;
  late final NotificationService _notificationService;
  late final ModelManager _modelManager;
  late final LocalChatService _chatService;
  late final ChatMemoryService _chatMemory;
  late final TrackingService _trackingService;
  late final OfflineMapService _offlineMapService;
  late final LocalEventStore _eventStore;
  late final SyncService _syncService;
  late final SosService _sosService;
  late final GisLayerService _gisLayerService;
  late final AiOrchestrator _aiOrchestrator;

  AlertPreferences _alertPreferences = const AlertPreferences();
  GeoFenceResult _geoFenceResult = GeoFenceResult.unknown();

  @override
  void initState() {
    super.initState();
    _ownsService = widget.gpsService == null;
    _gps = widget.gpsService ?? GpsService();
    final boundaryProvider =
        widget.boundaryProvider ?? OfflineBoundaryProvider();
    _gisLayerService = GisLayerService();
    _geoFence = widget.geoFenceService ??
        GeoFenceService(
          loadEnabledBoundaries: () async {
            final base = await boundaryProvider.loadEnabledBoundaries();
            if (_gisLayerService.features.isEmpty) {
              await _gisLayerService.initialize();
            }
            final gis = _gisLayerService.getActiveBoundaries();
            return [...base, ...gis];
          },
        );
    _alertPreferencesStore =
        widget.alertPreferencesStore ?? const AlertPreferencesStore();

    _soundService = SoundService();
    _vibrationService = VibrationAlertService();
    _voiceService = VoiceAlertService();
    _notificationService = NotificationService();

    _alerts = widget.alertService ??
        AlertService(
          sound: _soundService,
          voice: _voiceService,
          vibration: _vibrationService,
          notifications: _notificationService,
        );

    _modelManager = widget.modelManager ?? ModelManager();
    _chatService = LocalChatService(modelManager: _modelManager);
    _chatMemory = ChatMemoryService();
    _trackingService = TrackingService();
    _offlineMapService = widget.offlineMapService ?? OfflineMapService();
    _eventStore = LocalEventStore();
    _syncService = SyncService(
      eventStore: _eventStore,
      soundService: _soundService,
      notificationService: _notificationService,
    );
    _sosService = SosService(
      soundService: _soundService,
      vibrationService: _vibrationService,
      voiceService: _voiceService,
    );
    unawaited(_gisLayerService.initialize().then((_) async {
      await _geoFence.refreshBoundaries();
      if (mounted) unawaited(_updateGeoFence());
    }));
    _gisLayerService.addListener(_onGpsChanged);
    _aiOrchestrator = AiOrchestrator(
      chatService: _chatService,
      voiceService: _voiceService,
      gisLayerService: _gisLayerService,
      sosService: _sosService,
      offlineMapService: _offlineMapService,
    );

    _gps.addListener(_onGpsChanged);
    unawaited(_gps.start());
    unawaited(_alerts.start());
    unawaited(_loadAlertPreferences());
    unawaited(_eventStore.initialize());
    unawaited(_offlineMapService.initialize());
    _boundarySummary = boundaryProvider.load();
    unawaited(_updateGeoFence());
  }

  int _evaluationGeneration = 0;

  void _onGpsChanged() => unawaited(_updateGeoFence());

  Future<void> _updateGeoFence() async {
    final generation = ++_evaluationGeneration;
    final location = _gps.snapshot.location;
    if (location == null) {
      if (mounted) setState(() => _geoFenceResult = GeoFenceResult.gpsUnavailable());
      return;
    }

    if (_trackingService.isTracking) {
      _trackingService.addFix(location);
    }

    final result = await _geoFence.evaluate(location);
    if (!mounted) return;
    if (generation != _evaluationGeneration) return;
    setState(() => _geoFenceResult = result);

    // GPS startup and unavailable boundary data must not be mistaken for a
    // safety observation or dispatch an alert.
    if (result.state == GeoFenceState.unknown ||
        result.state == GeoFenceState.gpsUnavailable) {
      return;
    }
    final event = await _alerts.processGeoFenceResult(result);
    if (event != null) {
      unawaited(_eventStore.recordEvent(
        LocalSafetyEvent(
          eventId: 'evt_${DateTime.now().millisecondsSinceEpoch}',
          timestamp: DateTime.now(),
          eventType: event.message.severity.label.toUpperCase(),
          latitude: location.latitude,
          longitude: location.longitude,
          zone: result.nearestBoundary?.name ?? 'Sector',
          riskState: result.state.name.toUpperCase(),
          aiState: 'ADVISORY_ONLY',
          alertState: event.message.title,
          synced: false,
        ),
      ));
    }
  }

  Future<void> _loadAlertPreferences() async {
    final preferences = await _alertPreferencesStore.load();
    if (!mounted) return;
    setState(() => _alertPreferences = preferences);
    _alerts.updatePreferences(preferences);
  }

  String? _monitoringUnavailableReason(GpsSnapshot gps) {
    final location = gps.location;
    if (location == null || gps.stale || location.isStale) {
      return 'Location alerts need a fresh GPS fix. Check location permission and GPS signal.';
    }
    final accuracy = location.accuracy;
    if (accuracy == null || !accuracy.isFinite || accuracy > 200) {
      return 'Location accuracy is too low for reliable alerts. Move to a clearer GPS area and retry.';
    }
    if (_geoFenceResult.state == GeoFenceState.unknown) {
      return 'GPS is active, but alert zones are unavailable because the bundled forest and restricted boundaries are unverified.';
    }
    if (_geoFenceResult.state == GeoFenceState.gpsUnavailable) {
      return 'A fresh, accurate GPS fix is required before location alerts can run.';
    }
    return null;
  }

  void _updateAlertPreferences(AlertPreferences preferences) {
    setState(() => _alertPreferences = preferences);
    _alerts.updatePreferences(preferences);
    unawaited(_alertPreferencesStore.save(preferences));
  }

  LatLng? _targetMapCoordinate;

  void _go(int index, {LatLng? target}) {
    setState(() {
      _index = index;
      if (target != null) {
        _targetMapCoordinate = target;
      }
    });
  }

  void _openDiagnostics() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiagnosticsScreen(
          gps: _gps.snapshot,
          geoFence: _geoFenceResult,
          alertService: _alerts,
          soundService: _soundService,
          vibrationService: _vibrationService,
          voiceService: _voiceService,
          notificationService: _notificationService,
          modelManager: _modelManager,
          offlineMapService: _offlineMapService,
          syncService: _syncService,
          chatService: _chatService,
        ),
      ),
    );
  }

  AiOrchestrator get aiOrchestrator => _aiOrchestrator;

  @override
  void dispose() {
    _gps.removeListener(_onGpsChanged);
    unawaited(_gps.stop());
    unawaited(_alerts.stop());
    _aiOrchestrator.dispose();
    if (_ownsService) _gps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _gps,
      builder: (context, _) {
        final gps = _gps.snapshot;
        final screens = [
          HomeScreen(
            onNavigate: _go,
            gps: gps,
            onGpsRetry: () => unawaited(_gps.start()),
            boundarySummary: _boundarySummary,
            geoFence: _geoFenceResult,
          ),
          MapScreen(
            gps: gps,
            onGpsRetry: () => unawaited(_gps.start()),
            geoFence: _geoFenceResult,
            trackingService: _trackingService,
            offlineMapService: _offlineMapService,
            eventStore: _eventStore,
            loadBoundaries: () async {
              final base = await (widget.boundaryProvider ?? OfflineBoundaryProvider()).loadEnabledBoundaries();
              final gis = _gisLayerService.getActiveBoundaries();
              return [...base, ...gis];
            },
            targetCoordinate: _targetMapCoordinate,
            sosService: _sosService,
            gisLayerService: _gisLayerService,
          ),
          SafetyScreen(gps: gps, geoFence: _geoFenceResult),
          RouteScreen(
            gps: gps,
            loadBoundaries: () async {
              final base = await (widget.boundaryProvider ?? OfflineBoundaryProvider()).loadEnabledBoundaries();
              final gis = _gisLayerService.getActiveBoundaries();
              return [...base, ...gis];
            },
          ),
          AlertsScreen(
            alertService: _alerts,
            eventStore: _eventStore,
            monitoringUnavailableReason: _monitoringUnavailableReason(gps),
            onViewOnMap: () => _go(1),
            onSafeRoute: () => _go(3),
          ),
          AiChatScreen(
            chatService: _chatService,
            memoryService: _chatMemory,
            modelManager: _modelManager,
            gps: gps,
            geoFence: _geoFenceResult,
          ),
          SettingsScreen(
            preferences: _alertPreferences,
            onPreferencesChanged: _updateAlertPreferences,
            modelManager: _modelManager,
            onOpenDiagnostics: _openDiagnostics,
          ),
          SosScreen(
            key: const Key('screen-sos'),
            sosService: _sosService,
            gps: gps,
          ),
        ];

        return Scaffold(
          key: const Key('app-shell'),
          body: IndexedStack(index: _index, children: screens),
          bottomNavigationBar: BSASBottomNav(
            selectedIndex: _index,
            onDestinationSelected: _go,
            destinations: const [
              BSASNavItem(icon: Icons.home_outlined, label: 'Home'),
              BSASNavItem(icon: Icons.map_outlined, label: 'Map'),
              BSASNavItem(icon: Icons.shield_outlined, label: 'Safety'),
              BSASNavItem(icon: Icons.alt_route_rounded, label: 'Route'),
              BSASNavItem(icon: Icons.history_rounded, label: 'History'),
              BSASNavItem(icon: Icons.psychology_outlined, label: 'AI Chat'),
              BSASNavItem(icon: Icons.settings_outlined, label: 'Settings'),
              BSASNavItem(icon: Icons.sos_rounded, label: 'SOS'),
            ],
          ),
        );
      },
    );
  }
}
