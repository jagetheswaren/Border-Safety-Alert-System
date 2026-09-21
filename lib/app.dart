import 'dart:async';
import 'package:flutter/material.dart';

import 'models/alert_preferences.dart';
import 'models/alert_severity.dart';
import 'models/geofence_result.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/diagnostics_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/route_screen.dart';
import 'screens/safety_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'services/ai_prediction_service.dart';
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
import 'services/risk_engine.dart';
import 'services/sound_service.dart';
import 'services/sync_service.dart';
import 'services/tracking_service.dart';
import 'services/vibration_alert_service.dart';
import 'services/voice_alert_service.dart';
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
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
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
  int _index = 0;
  late final GpsService _gps;
  late final bool _ownsService;
  late final Future<BoundarySummary> _boundarySummary;
  late final GeoFenceService _geoFence;
  late final AlertService _alerts;
  late final AiPredictionService _aiService;
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

  AlertPreferences _alertPreferences = const AlertPreferences();
  GeoFenceResult _geoFenceResult = GeoFenceResult.unknown();

  @override
  void initState() {
    super.initState();
    _ownsService = widget.gpsService == null;
    _gps = widget.gpsService ?? GpsService();
    final boundaryProvider =
        widget.boundaryProvider ?? OfflineBoundaryProvider();
    _geoFence =
        widget.geoFenceService ??
        GeoFenceService(
          loadEnabledBoundaries: boundaryProvider.loadEnabledBoundaries,
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

    _aiService = AiPredictionService();
    _aiService.initialize();

    _gps.addListener(_onGpsChanged);
    unawaited(_gps.start());
    unawaited(_alerts.start());
    unawaited(_loadAlertPreferences());
    unawaited(_eventStore.initialize());
    unawaited(_offlineMapService.initialize());
    _boundarySummary = boundaryProvider.load();
    unawaited(_updateGeoFence());
  }

  void _onGpsChanged() => unawaited(_updateGeoFence());

  Future<void> _updateGeoFence() async {
    final location = _gps.snapshot.location;
    if (location == null) return;

    if (_trackingService.isTracking) {
      _trackingService.addFix(location);
    }

    final result = await _geoFence.evaluate(location);
    final firstPoint = result.nearestBoundary?.polygon.firstOrNull?.firstOrNull;
    final bLat = firstPoint?.latitude ?? location.latitude;
    final bLon = firstPoint?.longitude ?? location.longitude;

    final aiResult = await _aiService.predict(location, bLat, bLon);
    final fusedResult = RiskEngine.fuse(result, aiResult);

    if (!mounted) return;
    setState(() => _geoFenceResult = fusedResult);

    final event = await _alerts.processGeoFenceResult(fusedResult);
    if (event != null) {
      unawaited(_eventStore.recordEvent(
        LocalSafetyEvent(
          eventId: 'evt_${DateTime.now().millisecondsSinceEpoch}',
          timestamp: DateTime.now(),
          eventType: event.message.severity.label.toUpperCase(),
          latitude: location.latitude,
          longitude: location.longitude,
          zone: fusedResult.nearestBoundary?.name ?? 'Sector',
          riskState: fusedResult.state.name.toUpperCase(),
          aiState: aiResult.riskClass.name.toUpperCase(),
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

  void _updateAlertPreferences(AlertPreferences preferences) {
    setState(() => _alertPreferences = preferences);
    _alerts.updatePreferences(preferences);
    unawaited(_alertPreferencesStore.save(preferences));
  }

  void _go(int index) => setState(() => _index = index);

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
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gps.removeListener(_onGpsChanged);
    unawaited(_gps.stop());
    unawaited(_alerts.stop());
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
            geoFence: _geoFenceResult,
            trackingService: _trackingService,
            offlineMapService: _offlineMapService,
          ),
          SafetyScreen(gps: gps, geoFence: _geoFenceResult),
          RouteScreen(
            gps: gps,
            loadBoundaries: (widget.boundaryProvider ?? OfflineBoundaryProvider())
                .loadEnabledBoundaries,
          ),
          AlertsScreen(alertService: _alerts),
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
        ];

        return Scaffold(
          key: const Key('app-shell'),
          body: IndexedStack(index: _index, children: screens),
          bottomNavigationBar: NavigationBar(
            key: const Key('bottom-nav'),
            selectedIndex: _index,
            onDestinationSelected: _go,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
              NavigationDestination(icon: Icon(Icons.shield), label: 'Safety'),
              NavigationDestination(icon: Icon(Icons.route), label: 'Route'),
              NavigationDestination(icon: Icon(Icons.history), label: 'History'),
              NavigationDestination(icon: Icon(Icons.psychology), label: 'AI Chat'),
              NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
            ],
          ),
        );
      },
    );
  }
}
