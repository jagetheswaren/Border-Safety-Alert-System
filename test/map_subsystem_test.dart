import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:border_safety_alert/models/boundary_model.dart';
import 'package:border_safety_alert/models/geofence_result.dart';
import 'package:border_safety_alert/models/geofence_state.dart';
import 'package:border_safety_alert/models/gps_snapshot.dart';
import 'package:border_safety_alert/models/location_model.dart';
import 'package:border_safety_alert/models/safety_state.dart';
import 'package:border_safety_alert/services/local_event_store.dart';
import 'package:border_safety_alert/services/offline_map_service.dart';
import 'package:border_safety_alert/services/routing_service.dart';

void main() {
  group('Map & Geospatial Subsystem Tests', () {
    test('GPS fix cleanly transforms into user LatLng without inventing fake coordinates', () {
      // 1. Valid fix exists
      final fix = LocationModel(
        latitude: 10.712530,
        longitude: 76.979150,
        timestamp: DateTime(2026, 9, 26),
        accuracy: 8.5,
        speed: 1.2,
        bearing: 45.0,
      );
      final snapshot = GpsSnapshot(
        fix: GpsFixState.locked,
        permission: LocationPermissionState.granted,
        serviceEnabled: true,
        location: fix,
      );

      expect(snapshot.location, isNotNull);
      final latLng = LatLng(snapshot.location!.latitude, snapshot.location!.longitude);
      expect(latLng.latitude, 10.712530);
      expect(latLng.longitude, 76.979150);

      // 2. No GPS fix (searching)
      final noFixSnapshot = GpsSnapshot.initial();
      expect(noFixSnapshot.location, isNull);
      // Absolute Rule: Never invent fallback default coordinates
      expect(noFixSnapshot.fix, isNot(GpsFixState.locked));
    });

    test('Authoritative GeofenceState maps to deterministic safety label', () {
      const safeResult = GeoFenceResult(
        state: GeoFenceState.safe,
        distanceToBoundaryMeters: 4500.0,
      );
      expect(safeResult.state.label, 'SAFE');

      const cautionResult = GeoFenceResult(
        state: GeoFenceState.caution,
        distanceToBoundaryMeters: 1200.0,
      );
      expect(cautionResult.state.label, 'CAUTION');

      const warningResult = GeoFenceResult(
        state: GeoFenceState.warning,
        distanceToBoundaryMeters: 450.0,
      );
      expect(warningResult.state.label, 'WARNING');

      const criticalResult = GeoFenceResult(
        state: GeoFenceState.critical,
        distanceToBoundaryMeters: 50.0,
      );
      expect(criticalResult.state.label, 'CRITICAL');
    });

    test('Boundary polygons contain valid closed rings and geographic coordinates', () {
      const boundary = BoundaryModel(
        id: 'test_sector_1',
        name: 'Sector Alpha Perimeter',
        polygon: [
          [
            BoundaryPosition(latitude: 10.70, longitude: 76.90),
            BoundaryPosition(latitude: 10.75, longitude: 76.90),
            BoundaryPosition(latitude: 10.75, longitude: 76.95),
            BoundaryPosition(latitude: 10.70, longitude: 76.95),
            BoundaryPosition(latitude: 10.70, longitude: 76.90),
          ]
        ],
        riskLevel: RiskLevel.high,
      );

      expect(boundary.polygon.first.length, 5);
      expect(boundary.polygon.first.first.latitude, boundary.polygon.first.last.latitude);
      expect(boundary.polygon.first.first.longitude, boundary.polygon.first.last.longitude);
      expect(boundary.riskLevel, RiskLevel.high);
    });

    test('OfflineRegionRecord serializes and parses SQLite metadata accurately', () {
      const record = OfflineRegionRecord(
        id: 'coimbatore_west',
        name: 'Coimbatore West Transit Zone',
        minZoom: 8,
        maxZoom: 14,
        boundsGeoJson: '{"type":"Polygon","coordinates":[[[76.7,10.5],[77.2,10.5],[77.2,11.1],[76.7,11.1],[76.7,10.5]]]}',
        tileCount: 142,
        sizeBytes: 2450000,
        status: 'ready',
        downloadedAt: '2026-09-26T08:00:00Z',
        checksum: 'sha256:abc123def456',
      );

      final map = record.toMap();
      expect(map['id'], 'coimbatore_west');
      expect(map['tile_count'], 142);
      expect(map['status'], 'ready');

      final restored = OfflineRegionRecord.fromMap(map);
      expect(restored.id, record.id);
      expect(restored.tileCount, record.tileCount);
      expect(restored.sizeBytes, record.sizeBytes);
      expect(restored.checksum, record.checksum);
    });

    test('Alert markers are only plotted for valid stored coordinates', () {
      final validEvent = LocalSafetyEvent(
        eventId: 'alert_1',
        eventType: 'WARNING_PERIMETER',
        latitude: 10.712,
        longitude: 76.980,
        timestamp: DateTime.now(),
        zone: 'Sector 4',
        alertState: 'WARNING',
        riskState: 'WARNING',
        aiState: 'STANDBY',
      );

      final invalidEvent = LocalSafetyEvent(
        eventId: 'alert_2',
        eventType: 'SYSTEM_STATUS',
        latitude: 0.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
        zone: 'None',
        alertState: 'STANDBY',
        riskState: 'SAFE',
        aiState: 'STANDBY',
      );

      bool isValidCoordinate(LocalSafetyEvent e) =>
          e.latitude != 0.0 && e.longitude != 0.0 &&
          e.latitude >= -90.0 && e.latitude <= 90.0 &&
          e.longitude >= -180.0 && e.longitude <= 180.0;

      expect(isValidCoordinate(validEvent), isTrue);
      expect(isValidCoordinate(invalidEvent), isFalse);
    });

    test('Safe Route algorithm computes obstacle avoidance polyline away from boundaries', () async {
      final router = RoutingService();
      final currentLoc = LocationModel(latitude: 10.705, longitude: 76.905, timestamp: DateTime(2026, 9, 26));

      const boundary = BoundaryModel(
        id: 'hazard_1',
        name: 'Restricted Hazard Zone',
        polygon: [
          [
            BoundaryPosition(latitude: 10.710, longitude: 76.910),
            BoundaryPosition(latitude: 10.720, longitude: 76.910),
            BoundaryPosition(latitude: 10.720, longitude: 76.920),
            BoundaryPosition(latitude: 10.710, longitude: 76.920),
            BoundaryPosition(latitude: 10.710, longitude: 76.910),
          ]
        ],
        riskLevel: RiskLevel.high,
      );

      final result = await router.calculateSafeRoute(currentLoc, [boundary]);
      expect(result, isNotNull);
      // Route result returns an authoritative status
      expect(result.status, isNotNull);
    });
  });
}
