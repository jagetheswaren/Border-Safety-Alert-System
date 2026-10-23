import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme/bsas_colors.dart';
import '../core/theme/bsas_typography.dart';
import '../core/widgets/status_badge.dart';
import '../core/widgets/status_dot.dart';
import '../models/boundary_model.dart';
import '../models/geofence_result.dart';
import '../models/geofence_state.dart';
import '../models/gps_snapshot.dart';
import '../models/location_model.dart';
import '../models/routing_result.dart';
import '../models/safety_state.dart';
import '../services/boundary_summary.dart';
import '../services/connectivity_service.dart';
import '../services/local_event_store.dart';
import '../services/offline_map_service.dart';
import '../services/offline_tile_provider.dart';
import '../services/routing_service.dart';
import '../services/tracking_service.dart';
import '../widgets/geofence_status_card.dart';
import '../widgets/gps_status_chip.dart';

enum MapLayerType {
  hybrid,
  standard,
  satellite,
  offline,
}

enum MapNavigationMode {
  follow,
  free,
}

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    this.gps,
    this.geoFence = const GeoFenceResult(state: GeoFenceState.unknown),
    this.trackingService,
    this.offlineMapService,
    this.eventStore,
    this.loadBoundaries,
    this.targetCoordinate,
    this.initialFollowUser = true,
  });

  final GpsSnapshot? gps;
  final GeoFenceResult geoFence;
  final TrackingService? trackingService;
  final OfflineMapService? offlineMapService;
  final LocalEventStore? eventStore;
  final Future<List<BoundaryModel>> Function()? loadBoundaries;
  final LatLng? targetCoordinate;
  final bool initialFollowUser;

  static const defaultBaseCoordinate = LatLng(10.712530, 76.979150);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  late final MapController _mapController;
  late final TrackingService _tracking;
  late final OfflineMapService _offlineMap;
  late final DraggableScrollableController _sheetController;
  final ConnectivityService _connectivity = ConnectivityService();
  final RoutingService _routingService = RoutingService();

  MapNavigationMode _navMode = MapNavigationMode.follow;
  MapLayerType _currentLayer = MapLayerType.hybrid;
  bool _showSafetyZones = true;
  bool _showTrail = true;
  bool _showAccuracyRing = true;
  bool _showAlertMarkers = true;
  bool _isOnline = true;
  Timer? _connectivityTimer;

  List<BoundaryModel> _boundaries = [];
  bool _loadingBoundaries = false;

  RoutingResult? _safeRoute;
  bool _isCalculatingRoute = false;
  String? _routingStatusText;

  double _currentRotation = 0.0;
  bool _hasInitialCentered = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _sheetController = DraggableScrollableController();
    _tracking = widget.trackingService ?? TrackingService();
    _offlineMap = widget.offlineMapService ?? OfflineMapService();
    _navMode = widget.initialFollowUser ? MapNavigationMode.follow : MapNavigationMode.free;

    _initSubsystems();
  }

  Future<void> _initSubsystems() async {
    await _offlineMap.initialize();
    await _loadBoundaryDataset();
    await _checkConnectivity();
    _connectivityTimer = Timer.periodic(const Duration(seconds: 15), (_) => _checkConnectivity());

    if (widget.targetCoordinate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(widget.targetCoordinate!, 15.0);
        setState(() => _navMode = MapNavigationMode.free);
      });
    }
  }

  Future<void> _checkConnectivity() async {
    final online = await _connectivity.isOnline();
    if (mounted && online != _isOnline) {
      setState(() => _isOnline = online);
    }
  }

  Future<void> _loadBoundaryDataset() async {
    if (_loadingBoundaries) return;
    _loadingBoundaries = true;
    try {
      final loader = widget.loadBoundaries ?? OfflineBoundaryProvider().loadEnabledBoundaries;
      final loaded = await loader();
      if (mounted) {
        setState(() {
          _boundaries = loaded;
          _loadingBoundaries = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingBoundaries = false);
    }
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldLoc = oldWidget.gps?.location;
    final newLoc = widget.gps?.location;

    // Follow mode camera repositioning on real GPS fix
    if (newLoc != null && _navMode == MapNavigationMode.follow) {
      final pos = LatLng(newLoc.latitude, newLoc.longitude);
      if (!_hasInitialCentered) {
        _hasInitialCentered = true;
        _mapController.move(pos, 15.5);
      } else if (oldLoc == null ||
          oldLoc.latitude != newLoc.latitude ||
          oldLoc.longitude != newLoc.longitude) {
        _mapController.move(pos, _mapController.camera.zoom);
      }
    }

    // Record trail
    if (newLoc != null && _tracking.isTracking) {
      _tracking.addFix(newLoc);
    }
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    _sheetController.dispose();
    super.dispose();
  }

  LatLng? get _realUserLocation {
    final loc = widget.gps?.location;
    if (loc != null && loc.latitude.isFinite && loc.longitude.isFinite) {
      return LatLng(loc.latitude, loc.longitude);
    }
    return null;
  }

  LatLng get _cameraAnchorPosition {
    if (_realUserLocation != null) return _realUserLocation!;
    if (widget.targetCoordinate != null) return widget.targetCoordinate!;
    return MapScreen.defaultBaseCoordinate;
  }

  void _recenter() {
    final userPos = _realUserLocation;
    if (userPos != null) {
      _mapController.move(userPos, 15.5);
      setState(() => _navMode = MapNavigationMode.follow);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: BsasColors.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: BsasColors.darkBorder),
          ),
          content: Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: BsasColors.radarCyan),
              ),
              const SizedBox(width: 12),
              Text(
                'Acquiring GNSS constellation fix...',
                style: BsasTypography.caption.copyWith(color: Colors.white),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _resetNorth() {
    _mapController.rotate(0.0);
    setState(() => _currentRotation = 0.0);
  }

  Future<void> _calculateSafeEscapeRoute() async {
    final loc = widget.gps?.location;
    if (loc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot calculate route: GPS location not acquired.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isCalculatingRoute = true;
      _routingStatusText = 'Calculating safe escape corridor...';
    });

    try {
      final boundaries = _boundaries.isNotEmpty
          ? _boundaries
          : (await (widget.loadBoundaries ?? OfflineBoundaryProvider().loadEnabledBoundaries)());
      final result = await _routingService.calculateSafeRoute(loc, boundaries);
      if (mounted) {
        setState(() {
          _safeRoute = result;
          _isCalculatingRoute = false;
          _routingStatusText = result.message;
        });

        if (result.status == RoutingStatus.available && (result.routePoints?.isNotEmpty ?? false)) {
          final first = result.routePoints!.first;
          _mapController.move(LatLng(first.latitude, first.longitude), 15.0);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCalculatingRoute = false;
          _routingStatusText = 'Routing error: $e';
        });
      }
    }
  }

  void _clearRoute() {
    setState(() {
      _safeRoute = null;
      _routingStatusText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final live = widget.gps ?? GpsSnapshot.initial();
    final fix = live.location;
    final userPos = _realUserLocation;
    final geoFence = widget.geoFence;
    final isGpsLocked = live.fix == GpsFixState.locked && fix != null;
    final accuracy = fix?.accuracy ?? 15.0;

    return Scaffold(
      key: const Key('screen-map'),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ==========================================
          // 1. Interactive FlutterMap Engine
          // ==========================================
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _cameraAnchorPosition,
              initialZoom: userPos != null ? 15.0 : 13.0,
              maxZoom: 18.0,
              minZoom: 6.0,
              initialRotation: 0.0,
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture && _navMode == MapNavigationMode.follow) {
                  setState(() => _navMode = MapNavigationMode.free);
                }
                if (camera.rotation != _currentRotation) {
                  setState(() => _currentRotation = camera.rotation);
                }
              },
            ),
            children: [
              // Tile Layer based on selected MapLayerType
              if (_currentLayer == MapLayerType.hybrid) ...[
                TileLayer(
                  key: const ValueKey('tile-hybrid-base'),
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.bordersafety.border_safety_alert',
                  maxZoom: 18.0,
                ),
                TileLayer(
                  key: const ValueKey('tile-hybrid-overlay'),
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.bordersafety.border_safety_alert',
                  maxZoom: 18.0,
                ),
              ] else if (_currentLayer == MapLayerType.satellite)
                TileLayer(
                  key: const ValueKey('tile-satellite'),
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.bordersafety.border_safety_alert',
                  maxZoom: 18.0,
                )
              else if (_currentLayer == MapLayerType.offline)
                TileLayer(
                  key: const ValueKey('tile-offline'),
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.bordersafety.border_safety_alert',
                  tileProvider: OfflineTileProvider(
                    mapService: _offlineMap,
                    allowNetworkFallback: false,
                  ),
                )
              else
                TileLayer(
                  key: const ValueKey('tile-standard'),
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.bordersafety.border_safety_alert',
                  tileProvider: OfflineTileProvider(
                    mapService: _offlineMap,
                    allowNetworkFallback: _isOnline,
                  ),
                ),

              // Real Safety Boundaries (Polygons) from Repository
              if (_showSafetyZones && _boundaries.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    for (final boundary in _boundaries)
                      for (final ring in boundary.polygon)
                        if (ring.length >= 3)
                          Polygon(
                            points: ring.map((p) => LatLng(p.latitude, p.longitude)).toList(),
                            color: _colorForRisk(boundary.riskLevel).withValues(alpha: 0.18),
                            borderColor: _colorForRisk(boundary.riskLevel),
                            borderStrokeWidth: 2.2,
                          ),
                  ],
                ),

              // Active Nearest Boundary Polygon Highlight
              if (_showSafetyZones &&
                  geoFence.nearestBoundary != null &&
                  geoFence.nearestBoundary!.polygon.isNotEmpty)
                PolygonLayer(
                  polygons: geoFence.nearestBoundary!.polygon.map((ring) {
                    return Polygon(
                      points: ring.map((p) => LatLng(p.latitude, p.longitude)).toList(),
                      color: _colorForGeoState(geoFence.state).withValues(alpha: 0.25),
                      borderColor: _colorForGeoState(geoFence.state),
                      borderStrokeWidth: 3.0,
                    );
                  }).toList(),
                ),

              // Safe Escape Corridor Polyline
              if (_safeRoute != null && (_safeRoute!.routePoints?.isNotEmpty ?? false))
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _safeRoute!.routePoints!
                          .map((p) => LatLng(p.latitude, p.longitude))
                          .toList(),
                      strokeWidth: 5.0,
                      color: BsasColors.safeGreen,
                    ),
                  ],
                ),

              // Movement Breadcrumb Trail Layer
              if (_showTrail)
                ListenableBuilder(
                  listenable: _tracking,
                  builder: (context, _) {
                    final points = _tracking.trail
                        .map((p) => LatLng(p.latitude, p.longitude))
                        .toList();
                    if (points.length < 2) return const SizedBox.shrink();
                    return PolylineLayer(
                      polylines: [
                        Polyline(
                          points: points,
                          strokeWidth: 3.5,
                          color: BsasColors.radarCyan,
                        ),
                      ],
                    );
                  },
                ),

              // Real GPS Accuracy Ring (Only rendered when real fix exists)
              if (_showAccuracyRing && userPos != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: userPos,
                      radius: accuracy.clamp(5.0, 1000.0),
                      useRadiusInMeter: true,
                      color: BsasColors.radarCyan.withValues(alpha: 0.12),
                      borderColor: BsasColors.radarCyan.withValues(alpha: 0.55),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),

              // Stored Alert / Safety Event Markers
              if (_showAlertMarkers && widget.eventStore != null)
                ListenableBuilder(
                  listenable: widget.eventStore!,
                  builder: (context, _) {
                    final validEvents = widget.eventStore!.allEvents
                        .where((e) => e.latitude != 0.0 && e.longitude != 0.0 && e.latitude.isFinite && e.longitude.isFinite)
                        .toList();

                    return MarkerLayer(
                      markers: [
                        for (final evt in validEvents)
                          Marker(
                            point: LatLng(evt.latitude, evt.longitude),
                            width: 36,
                            height: 36,
                            child: GestureDetector(
                              onTap: () => _showAlertDetailsSheet(evt),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: evt.eventType == 'CRITICAL'
                                      ? BsasColors.criticalRed
                                      : BsasColors.warningOrange,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.0),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black45,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),

              // Escape Corridor Destination Exit Pin
              if (_safeRoute != null && _safeRoute!.destination != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_safeRoute!.destination!.latitude, _safeRoute!.destination!.longitude),
                      width: 36,
                      height: 36,
                      child: Container(
                        decoration: BoxDecoration(
                          color: BsasColors.safeGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.0),
                          boxShadow: const [
                            BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        child: const Icon(Icons.check, color: Colors.black, size: 20),
                      ),
                    ),
                  ],
                ),

              // Real User Location Marker (Strictly real GNSS fix)
              if (userPos != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: userPos,
                      width: 48,
                      height: 48,
                      child: _buildUserPuck(fix),
                    ),
                  ],
                ),
            ],
          ),

          // Hidden compatibility key for tests
          const Positioned(
            bottom: -100,
            child: SizedBox(key: Key('map-placeholder')),
          ),

          // ==========================================
          // 2. TOP FLOATING COMPACT HUD
          // ==========================================
          Positioned(
            top: MediaQuery.paddingOf(context).top + 10,
            left: 14,
            right: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Floating Safety Pill + GPS Sub-pill
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Floating Safety Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: BsasColors.darkSurface.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _colorForGeoState(geoFence.state).withValues(alpha: 0.7),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StatusDot(state: _statusStateForGeo(geoFence.state)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _labelForGeoState(geoFence.state),
                                style: BsasTypography.monospace.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Secondary Pill: GPS State + Offline Badge
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            key: const Key('map-gps-line'),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: BsasColors.darkSurface.withValues(alpha: 0.90),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: BsasColors.darkBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GpsStatusChip(state: live.fix),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    isGpsLocked
                                        ? 'GPS LOCKED (±${accuracy.toStringAsFixed(0)}m)'
                                        : (live.message ?? 'Acquiring GPS...'),
                                    style: BsasTypography.monoDiagnostics.copyWith(
                                      fontSize: 10,
                                      color: isGpsLocked ? Colors.white70 : BsasColors.warningOrange,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!_isOnline || _currentLayer == MapLayerType.offline)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: BsasColors.radarCyan.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: BsasColors.radarCyan.withValues(alpha: 0.5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.offline_pin, size: 12, color: BsasColors.radarCyan),
                                  const SizedBox(width: 4),
                                  Text(
                                    'OFFLINE MAP',
                                    style: BsasTypography.monoDiagnostics.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: BsasColors.radarCyan,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Right: Compact Compass Button
                Container(
                  decoration: BoxDecoration(
                    color: BsasColors.darkSurface.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                    border: Border.all(color: BsasColors.darkBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Transform.rotate(
                      angle: -_currentRotation * (math.pi / 180.0),
                      child: const Icon(Icons.explore_outlined, color: BsasColors.radarCyan, size: 22),
                    ),
                    tooltip: 'Reset North',
                    onPressed: _resetNorth,
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // 3. RIGHT FLOATING NAVIGATION CONTROLS
          // ==========================================
          Positioned(
            top: MediaQuery.paddingOf(context).top + 90,
            right: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Zoom Control Capsule
                Container(
                  decoration: BoxDecoration(
                    color: BsasColors.darkSurface.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: BsasColors.darkBorder),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white, size: 20),
                        tooltip: 'Zoom In',
                        onPressed: () {
                          final nextZoom = (_mapController.camera.zoom + 1.0).clamp(6.0, 18.0);
                          _mapController.move(_mapController.camera.center, nextZoom);
                        },
                      ),
                      Container(width: 28, height: 1, color: BsasColors.darkBorder),
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.white, size: 20),
                        tooltip: 'Zoom Out',
                        onPressed: () {
                          final nextZoom = (_mapController.camera.zoom - 1.0).clamp(6.0, 18.0);
                          _mapController.move(_mapController.camera.center, nextZoom);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Map Layers Selector Button
                _circularActionBtn(
                  icon: Icons.layers_rounded,
                  color: Colors.white,
                  tooltip: 'Map Layers',
                  onTap: _showLayerSheet,
                ),
                const SizedBox(height: 10),

                // Safe Escape Corridor Button
                _circularActionBtn(
                  icon: Icons.alt_route_rounded,
                  color: _safeRoute != null ? BsasColors.safeGreen : Colors.white70,
                  tooltip: 'Escape Route',
                  onTap: _safeRoute != null ? _clearRoute : _calculateSafeEscapeRoute,
                ),
                const SizedBox(height: 10),

                // Follow Location Toggle
                _circularActionBtn(
                  icon: _navMode == MapNavigationMode.follow
                      ? Icons.navigation_rounded
                      : Icons.near_me_outlined,
                  color: _navMode == MapNavigationMode.follow ? BsasColors.radarCyan : Colors.white60,
                  tooltip: _navMode == MapNavigationMode.follow ? 'Follow Mode: ON' : 'Free Mode: ON',
                  onTap: () {
                    setState(() {
                      if (_navMode == MapNavigationMode.follow) {
                        _navMode = MapNavigationMode.free;
                      } else {
                        _navMode = MapNavigationMode.follow;
                        _recenter();
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),

                // Recenter Button
                FloatingActionButton.small(
                  heroTag: 'btn-recenter',
                  key: const Key('btn-recenter'),
                  backgroundColor: _navMode == MapNavigationMode.follow
                      ? BsasColors.safeGreen
                      : BsasColors.darkSurface,
                  foregroundColor: _navMode == MapNavigationMode.follow ? Colors.black : Colors.white,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: _navMode == MapNavigationMode.follow ? Colors.transparent : BsasColors.darkBorder,
                    ),
                  ),
                  onPressed: _recenter,
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),

          // ==========================================
          // 4. DRAGGABLE / COLLAPSIBLE BOTTOM SHEET
          // ==========================================
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.15,
            minChildSize: 0.13,
            maxChildSize: 0.58,
            snap: true,
            snapSizes: const [0.15, 0.58],
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: BsasColors.darkSurface.withValues(alpha: 0.96),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: const Border(
                    top: BorderSide(color: BsasColors.darkBorder, width: 1.2),
                    left: BorderSide(color: BsasColors.darkBorder, width: 0.8),
                    right: BorderSide(color: BsasColors.darkBorder, width: 0.8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  children: [
                    // Drag Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // --- COLLAPSED SUMMARY ROW ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  StatusDot(state: _statusStateForGeo(geoFence.state)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      geoFence.nearestBoundary?.name ?? 'Perimeter Monitor Active',
                                      style: BsasTypography.heading.copyWith(
                                        fontSize: 14,
                                        color: Colors.white,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDistance(geoFence.distanceToBoundaryMeters),
                                style: BsasTypography.caption.copyWith(
                                  color: _colorForGeoState(geoFence.state),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: BsasColors.darkBorder),
                          ),
                          child: Text(
                            '±${accuracy.toStringAsFixed(0)}m ACC',
                            style: BsasTypography.monoDiagnostics.copyWith(
                              fontSize: 11,
                              color: isGpsLocked ? BsasColors.safeGreen : BsasColors.warningOrange,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: BsasColors.darkBorder, height: 1),
                    const SizedBox(height: 16),

                    // --- EXPANDED TELEMETRY GRID ---
                    Text(
                      'TELEMETRY & SENSOR SUITE',
                      style: BsasTypography.caption.copyWith(
                        color: BsasColors.radarCyan,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Coordinates & Speed Grid
                    Container(
                      key: const Key('map-gps-line'),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: BsasColors.darkBorder),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _telemetryCell(
                                  label: 'LATITUDE',
                                  value: fix != null ? '${fix.latitude.toStringAsFixed(6)}°' : '--',
                                ),
                              ),
                              Expanded(
                                child: _telemetryCell(
                                  label: 'LONGITUDE',
                                  value: fix != null ? '${fix.longitude.toStringAsFixed(6)}°' : '--',
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white10, height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _telemetryCell(
                                  label: 'SPEED',
                                  value: fix?.speed != null
                                      ? '${(fix!.speed! * 3.6).toStringAsFixed(1)} km/h'
                                      : '0.0 km/h',
                                ),
                              ),
                              Expanded(
                                child: _telemetryCell(
                                  label: 'HEADING',
                                  value: fix?.bearing != null
                                      ? '${fix!.bearing!.toStringAsFixed(0)}°'
                                      : 'N/A',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Boundary & Geofence Details
                    GeoFenceStatusCard(result: widget.geoFence),

                    const SizedBox(height: 14),

                    // Action Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: BsasColors.radarCyan),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: _isCalculatingRoute
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: BsasColors.radarCyan),
                                  )
                                : Icon(
                                    _safeRoute != null ? Icons.close : Icons.alt_route_rounded,
                                    color: BsasColors.radarCyan,
                                    size: 18,
                                  ),
                            label: Text(
                              _isCalculatingRoute
                                  ? 'CALCULATING...'
                                  : (_safeRoute != null ? 'CLEAR CORRIDOR' : 'SAFE CORRIDOR'),
                              style: const TextStyle(color: BsasColors.radarCyan, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            onPressed: _isCalculatingRoute
                                ? null
                                : (_safeRoute != null ? _clearRoute : _calculateSafeEscapeRoute),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BsasColors.darkSurface,
                              side: const BorderSide(color: BsasColors.darkBorder),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.download_for_offline, color: Colors.white, size: 18),
                            label: const Text(
                              'OFFLINE MAPS',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            onPressed: _showPrepareOfflineDialog,
                          ),
                        ),
                      ],
                    ),
                    if (_routingStatusText != null) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          _routingStatusText!,
                          style: BsasTypography.caption.copyWith(color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HELPER WIDGETS & SHEETS
  // ==========================================

  Widget _buildUserPuck(LocationModel? fix) {
    final bearing = fix?.bearing;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer pulsing wave
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: BsasColors.radarCyan.withValues(alpha: 0.22),
          ),
        ),
        // Direction pointer arrow if bearing is active
        if (bearing != null && (fix?.speed ?? 0) > 0.4)
          Transform.rotate(
            angle: bearing * (math.pi / 180.0),
            child: const Icon(Icons.navigation, color: BsasColors.radarCyan, size: 36),
          )
        else
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BsasColors.radarCyan,
              border: Border.all(color: Colors.white, width: 3.0),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _circularActionBtn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: BsasColors.darkSurface.withValues(alpha: 0.94),
        shape: BoxShape.circle,
        border: Border.all(color: BsasColors.darkBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }

  Widget _telemetryCell({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: BsasTypography.caption.copyWith(color: BsasColors.textSecondary, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: BsasTypography.monoDiagnostics.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  void _showAlertDetailsSheet(LocalSafetyEvent event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BsasColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isCrit = event.eventType == 'CRITICAL';
        final color = isCrit ? BsasColors.criticalRed : BsasColors.warningOrange;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(isCrit ? Icons.dangerous_rounded : Icons.warning_amber_rounded, color: color, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        event.alertState.isNotEmpty ? event.alertState : 'SAFETY EVENT ALERT',
                        style: BsasTypography.heading.copyWith(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    StatusBadge(
                      label: event.eventType,
                      state: isCrit ? StatusState.critical : StatusState.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: BsasColors.darkBorder),
                const SizedBox(height: 8),
                _detailRow('Zone / Sector', event.zone),
                _detailRow('Timestamp', event.timestamp.toLocal().toString().split('.').first),
                _detailRow('Latitude', '${event.latitude.toStringAsFixed(6)}°'),
                _detailRow('Longitude', '${event.longitude.toStringAsFixed(6)}°'),
                _detailRow('Risk Engine State', event.riskState),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: BsasColors.radarCyan),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('DISMISS', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
          Text(value, style: BsasTypography.monoDiagnostics.copyWith(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  void _showLayerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: BsasColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'MAP LAYERS & SENSOR CHANNELS',
                        style: BsasTypography.caption.copyWith(
                          color: BsasColors.radarCyan,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _layerOptionTile(
                      title: 'Hybrid (Satellite + Roads & Places)',
                      subtitle: 'Optical photography with roads, town & village names • Default\nSource: Esri, Maxar, Earthstar Geographics',
                      isSelected: _currentLayer == MapLayerType.hybrid,
                      onTap: () {
                        setState(() => _currentLayer = MapLayerType.hybrid);
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: 6),
                    _layerOptionTile(
                      title: 'Standard (ArcGIS World Street)',
                      subtitle: 'Vector-derived cartographic street tiles with local disk cache\nSource: Esri, HERE, Garmin, USGS',
                      isSelected: _currentLayer == MapLayerType.standard,
                      onTap: () {
                        setState(() => _currentLayer = MapLayerType.standard);
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: 6),
                    _layerOptionTile(
                      title: 'Satellite (Esri World Imagery)',
                      subtitle: 'High-res optical photography • Online only\nSource: Esri, Maxar, Earthstar Geographics',
                      isSelected: _currentLayer == MapLayerType.satellite,
                      onTap: () {
                        setState(() => _currentLayer = MapLayerType.satellite);
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: 6),
                    _layerOptionTile(
                      title: 'Offline Sector (0 Data / Local Cache)',
                      subtitle: 'Strict local cache: ${_offlineMap.tileCount} tiles (${_offlineMap.storageMb.toStringAsFixed(1)} MB)',
                      isSelected: _currentLayer == MapLayerType.offline,
                      onTap: () {
                        setState(() => _currentLayer = MapLayerType.offline);
                        setSheetState(() {});
                      },
                    ),
                    const Divider(color: BsasColors.darkBorder, height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'OVERLAYS',
                        style: BsasTypography.caption.copyWith(
                          color: BsasColors.radarCyan,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Restricted Zones & Geofence Polygons', style: TextStyle(color: Colors.white, fontSize: 13)),
                      value: _showSafetyZones,
                      activeThumbColor: BsasColors.radarCyan,
                      onChanged: (v) {
                        setState(() => _showSafetyZones = v);
                        setSheetState(() {});
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Movement Breadcrumb Trail', style: TextStyle(color: Colors.white, fontSize: 13)),
                      value: _showTrail,
                      activeThumbColor: BsasColors.radarCyan,
                      onChanged: (v) {
                        setState(() => _showTrail = v);
                        setSheetState(() {});
                      },
                    ),
                    SwitchListTile(
                      title: const Text('GPS Accuracy Radius Ring', style: TextStyle(color: Colors.white, fontSize: 13)),
                      value: _showAccuracyRing,
                      activeThumbColor: BsasColors.radarCyan,
                      onChanged: (v) {
                        setState(() => _showAccuracyRing = v);
                        setSheetState(() {});
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Alert Incident Markers', style: TextStyle(color: Colors.white, fontSize: 13)),
                      value: _showAlertMarkers,
                      activeThumbColor: BsasColors.radarCyan,
                      onChanged: (v) {
                        setState(() => _showAlertMarkers = v);
                        setSheetState(() {});
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPrepareOfflineDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: BsasColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            final regions = _offlineMap.getAvailableRegions();
            return FutureBuilder<List<OfflineRegionRecord>>(
              future: _offlineMap.getStoredRegions(),
              builder: (context, snapshot) {
                final records = snapshot.data ?? [];
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'OFFLINE MAP REGIONS (SQLite)',
                              style: BsasTypography.caption.copyWith(
                                color: BsasColors.radarCyan,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white70),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        for (final reg in regions) ...[
                          _regionCard(reg, records, setDlgState),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _regionCard(
    OfflineRegion region,
    List<OfflineRegionRecord> records,
    StateSetter setDlgState,
  ) {
    final record = records.firstWhere(
      (r) => r.id == region.id,
      orElse: () => OfflineRegionRecord(
        id: region.id,
        name: region.name,
        minZoom: region.minZoom,
        maxZoom: region.maxZoom,
        boundsGeoJson: region.toBoundsGeoJson(),
        tileCount: 0,
        sizeBytes: 0,
        status: 'AVAILABLE',
      ),
    );

    final isDownloading = _offlineMap.status == OfflineMapStatus.downloading;
    final isReady = record.status == 'READY' || (region.id == OfflineMapService.defaultRegion.id && _offlineMap.isReady);
    final count = record.tileCount > 0 ? record.tileCount : _offlineMap.tileCount;
    final sizeMb = record.sizeBytes > 0 ? record.sizeMb : _offlineMap.storageMb;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isReady ? BsasColors.safeGreen.withValues(alpha: 0.5) : BsasColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  region.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              StatusBadge(
                label: isDownloading ? 'DOWNLOADING' : (isReady ? 'READY' : 'AVAILABLE'),
                state: isDownloading ? StatusState.loading : (isReady ? StatusState.ready : StatusState.idle),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(region.description, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            'Zoom: ${region.minZoom}–${region.maxZoom}  •  ${count > 0 ? "$count tiles (${sizeMb.toStringAsFixed(1)} MB)" : "Estimated 142 tiles (~2.5 MB)"}',
            style: BsasTypography.monoDiagnostics.copyWith(fontSize: 11, color: BsasColors.radarCyan),
          ),
          if (isDownloading) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: _offlineMap.downloadProgress,
              color: BsasColors.radarCyan,
              backgroundColor: Colors.white10,
            ),
            const SizedBox(height: 4),
            Text(
              'Progress: ${(_offlineMap.downloadProgress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isReady && count > 0)
                TextButton(
                  child: const Text('Delete Cache', style: TextStyle(color: BsasColors.criticalRed, fontSize: 12)),
                  onPressed: () async {
                    await _offlineMap.deleteRegion(region.id);
                    setDlgState(() {});
                  },
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isReady ? BsasColors.radarCyan : BsasColors.safeGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: isDownloading
                    ? null
                    : () async {
                        await _offlineMap.downloadRegion(region.id);
                        setDlgState(() {});
                      },
                child: Text(
                  isReady ? 'Re-Download' : 'Prepare & Download',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _layerOptionTile({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? BsasColors.radarCyan.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? BsasColors.radarCyan : BsasColors.darkBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              color: isSelected ? BsasColors.radarCyan : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double? meters) {
    if (meters == null) return 'Perimeter: Calculating...';
    if (meters <= 0) return 'BREACH: INSIDE RESTRICTED SECTOR';
    if (meters < 1000) return 'Nearest Perimeter: ${meters.toStringAsFixed(0)} m';
    return 'Nearest Perimeter: ${(meters / 1000.0).toStringAsFixed(2)} km';
  }

  Color _colorForGeoState(GeoFenceState state) {
    switch (state) {
      case GeoFenceState.insideRestrictedArea:
      case GeoFenceState.critical:
        return BsasColors.criticalRed;
      case GeoFenceState.warning:
        return BsasColors.warningOrange;
      case GeoFenceState.caution:
        return const Color(0xFFF59E0B);
      case GeoFenceState.safe:
        return BsasColors.safeGreen;
      case GeoFenceState.gpsUnavailable:
      case GeoFenceState.unknown:
        return BsasColors.radarCyan;
    }
  }

  StatusState _statusStateForGeo(GeoFenceState state) {
    switch (state) {
      case GeoFenceState.insideRestrictedArea:
      case GeoFenceState.critical:
        return StatusState.critical;
      case GeoFenceState.warning:
        return StatusState.warning;
      case GeoFenceState.caution:
        return StatusState.warning;
      case GeoFenceState.safe:
        return StatusState.ready;
      case GeoFenceState.gpsUnavailable:
      case GeoFenceState.unknown:
        return StatusState.idle;
    }
  }

  String _labelForGeoState(GeoFenceState state) {
    switch (state) {
      case GeoFenceState.insideRestrictedArea:
        return 'INSIDE RESTRICTED ZONE';
      case GeoFenceState.critical:
        return 'CRITICAL PROXIMITY';
      case GeoFenceState.warning:
        return 'WARNING PROXIMITY';
      case GeoFenceState.caution:
        return 'CAUTION SECTOR';
      case GeoFenceState.safe:
        return 'SAFE TRANSIT SECTOR';
      case GeoFenceState.gpsUnavailable:
        return 'ACQUIRING GNSS';
      case GeoFenceState.unknown:
        return 'STANDBY';
    }
  }

  Color _colorForRisk(RiskLevel level) {
    switch (level) {
      case RiskLevel.high:
        return BsasColors.criticalRed;
      case RiskLevel.medium:
        return BsasColors.warningOrange;
      case RiskLevel.low:
        return BsasColors.safeGreen;
    }
  }
}
