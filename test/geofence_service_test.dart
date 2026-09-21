import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:border_safety_alert/database/app_database.dart';
import 'package:border_safety_alert/models/boundary_model.dart';
import 'package:border_safety_alert/models/geofence_state.dart';
import 'package:border_safety_alert/models/location_model.dart';
import 'package:border_safety_alert/models/safety_state.dart';
import 'package:border_safety_alert/services/boundary_repository.dart';
import 'package:border_safety_alert/services/geo_math.dart';
import 'package:border_safety_alert/services/geofence_service.dart';

BoundaryModel squareBoundary({
  String id = 'zone',
  String name = 'Demo Forest Zone',
  bool enabled = true,
  double size = 0.01,
}) {
  return BoundaryModel(
    id: id,
    name: name,
    type: 'forest',
    riskLevel: RiskLevel.medium,
    enabled: enabled,
    source: 'synthetic demo',
    polygon: [
      [
        const BoundaryPosition(longitude: -0.01, latitude: -0.01),
        BoundaryPosition(longitude: size, latitude: -0.01),
        BoundaryPosition(longitude: size, latitude: size),
        const BoundaryPosition(longitude: -0.01, latitude: 0.01),
      ],
    ],
  );
}

LocationModel location(double latitude, double longitude, {double? bearing}) {
  return LocationModel.validated(
    latitude: latitude,
    longitude: longitude,
    bearing: bearing,
    timestamp: DateTime(2026, 9, 10),
  );
}

GeoFenceService serviceWith(List<BoundaryModel> boundaries) {
  return GeoFenceService(
    config: const GeoFenceConfig(
      cautionRadiusMeters: 2000,
      warningRadiusMeters: 1000,
      criticalRadiusMeters: 500,
    ),
    loadEnabledBoundaries: () async => boundaries,
  );
}

void main() {
  group('geo math', () {
    final square = squareBoundary().polygon;

    test('classifies inside, outside, edge, and invalid polygons', () {
      expect(
        isPointInPolygon(latitude: 0, longitude: 0, polygon: square),
        isTrue,
      );
      expect(
        isPointInPolygon(latitude: 1, longitude: 1, polygon: square),
        isFalse,
      );
      expect(
        isPointInPolygon(latitude: 0, longitude: 0.01, polygon: square),
        isTrue,
      );
      expect(
        isPointInPolygon(latitude: 0, longitude: 0.011, polygon: square),
        isFalse,
      );
      expect(
        isPointInPolygon(latitude: 0, longitude: 0, polygon: const []),
        isFalse,
      );
      expect(
        isPointInPolygon(
          latitude: 0,
          longitude: 0,
          polygon: [
            [
              const BoundaryPosition(longitude: 0, latitude: 0),
              const BoundaryPosition(longitude: double.nan, latitude: 1),
              const BoundaryPosition(longitude: 1, latitude: 0),
            ],
          ],
        ),
        isFalse,
      );
    });

    test('measures polygon edge distance in meters', () {
      final closest = closestPointOnPolygon(
        latitude: 0,
        longitude: 0.02,
        polygon: square,
      );
      expect(closest, isNotNull);
      expect(closest!.distanceMeters, closeTo(1111, 8));
      expect(
        closestPointOnPolygon(latitude: 0, longitude: 0, polygon: const []),
        isNull,
      );
    });

    test('calculates cardinal bearings and wrap-around difference', () {
      expect(bearingDegrees(0, 0, 1, 0), closeTo(0, 0.001));
      expect(bearingDegrees(0, 0, 0, 1), closeTo(90, 0.001));
      expect(bearingDegrees(1, 0, 0, 0), closeTo(180, 0.001));
      expect(bearingDegrees(0, 1, 0, 0), closeTo(270, 0.001));
      expect(bearingDifferenceDegrees(359, 1), closeTo(2, 0.001));
    });
  });

  group('GeoFenceService', () {
    test('returns gpsUnavailable without a location; unknown without usable boundaries', () async {
      final service = serviceWith([]);
      expect((await service.evaluate(null)).state, GeoFenceState.gpsUnavailable);
      expect(
        (await serviceWith([
          squareBoundary(enabled: false),
        ]).evaluate(location(1, 1))).state,
        GeoFenceState.unknown,
      );
    });

    test('selects deterministic threshold states and inside state', () async {
      final service = serviceWith([squareBoundary()]);
      expect(
        (await service.evaluate(location(0, 0.05))).state,
        GeoFenceState.safe,
      );
      expect(
        (await service.evaluate(location(0, 0.025))).state,
        GeoFenceState.caution,
      );
      expect(
        (await service.evaluate(location(0, 0.018))).state,
        GeoFenceState.warning,
      );
      expect(
        (await service.evaluate(location(0, 0.014))).state,
        GeoFenceState.critical,
      );
      final inside = await service.evaluate(location(0, 0));
      expect(inside.state, GeoFenceState.insideRestrictedArea);
      expect(inside.distanceToBoundaryMeters, 0);
      expect(inside.boundaryRisk, RiskLevel.medium);
    });

    test(
      'reports nearest enabled boundary and movement relationship',
      () async {
        final service = serviceWith([
          squareBoundary(id: 'far', name: 'Far'),
          squareBoundary(id: 'near', name: 'Near', size: 0.02),
        ]);
        final result = await service.evaluate(location(0, 0.03, bearing: 270));
        expect(result.nearestBoundary?.name, 'Near');
        expect(result.directionToBoundaryDegrees, closeTo(270, 1));
        expect(result.bearingDifferenceDegrees, closeTo(0, 1));
        expect(result.movingTowardBoundary, isTrue);
      },
    );
  });

  group('repository integration', () {
    late AppDatabase database;
    late BoundaryRepository repository;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      database = await AppDatabase.inMemory(databaseFactory);
      repository = BoundaryRepository(database.db);
    });

    tearDown(() => database.close());

    test('ignores disabled rows and chooses the nearest enabled row', () async {
      await repository.insertBoundaries([
        squareBoundary(id: 'disabled', name: 'Disabled', enabled: false),
        squareBoundary(id: 'enabled', name: 'Enabled', size: 0.02),
      ]);
      final result = await serviceWith([]).evaluate(location(0, 0.03));
      final repositoryResult = await GeoFenceService(
        repository: repository,
      ).evaluate(location(0, 0.03));
      expect(result.state, GeoFenceState.unknown);
      expect(repositoryResult.nearestBoundary?.name, 'Enabled');
      expect(repositoryResult.nearestBoundary?.enabled, isTrue);
    });
  });
}
