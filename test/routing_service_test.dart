import 'package:flutter_test/flutter_test.dart';
import 'package:border_safety_alert/models/boundary_model.dart';
import 'package:border_safety_alert/models/location_model.dart';
import 'package:border_safety_alert/models/routing_result.dart';
import 'package:border_safety_alert/services/routing_service.dart';
import 'package:border_safety_alert/models/safety_state.dart';
import 'package:border_safety_alert/services/geo_math.dart';

void main() {
  group('RoutingService Tests', () {
    late RoutingService routingService;

    setUp(() {
      routingService = RoutingService();
    });

    // 6. UNKNOWN / MISSING DATA TEST
    test('missing data returns alreadySafe or unavailable depending on boundaries', () async {
      final loc = LocationModel.validated(latitude: 10, longitude: 10);
      final result = await routingService.calculateSafeRoute(loc, []);
      expect(result.status, RoutingStatus.alreadySafe);
    });

    test('alreadySafe when location is outside boundary and clearance', () async {
      final loc = LocationModel.validated(latitude: 0, longitude: 0);
      final boundary = BoundaryModel(
        id: '1',
        name: 'test',
        riskLevel: RiskLevel.high,
        polygon: [
          [
            BoundaryPosition(longitude: 10.0, latitude: 10.0),
            BoundaryPosition(longitude: 10.0, latitude: 11.0),
            BoundaryPosition(longitude: 11.0, latitude: 11.0),
            BoundaryPosition(longitude: 11.0, latitude: 10.0),
            BoundaryPosition(longitude: 10.0, latitude: 10.0),
          ]
        ],
      );
      final result = await routingService.calculateSafeRoute(loc, [boundary]);
      expect(result.status, RoutingStatus.alreadySafe);
    });

    test('calculates route when inside a simple polygon', () async {
      double off = 0.0009;
      final boundary = BoundaryModel(
        id: '1',
        name: 'test',
        riskLevel: RiskLevel.high,
        polygon: [
          [
            BoundaryPosition(longitude: off, latitude: off),
            BoundaryPosition(longitude: off, latitude: -off),
            BoundaryPosition(longitude: -off, latitude: -off),
            BoundaryPosition(longitude: -off, latitude: off),
            BoundaryPosition(longitude: off, latitude: off),
          ]
        ],
      );

      final loc = LocationModel.validated(latitude: 0, longitude: 0);
      final result = await routingService.calculateSafeRoute(loc, [boundary]);
      
      expect(result.status, RoutingStatus.available, reason: result.message);
      expect(result.routePoints, isNotEmpty);
      expect(result.totalDistanceMeters, greaterThan(0));
      expect(result.destination, isNotNull);
    });

    // 5. NO-ROUTE TEST
    test('unavailable when completely surrounded', () async {
      final boundary = BoundaryModel(
        id: '1',
        name: 'test',
        riskLevel: RiskLevel.high,
        polygon: [
          [
            BoundaryPosition(longitude: 10, latitude: 10),
            BoundaryPosition(longitude: 10, latitude: -10),
            BoundaryPosition(longitude: -10, latitude: -10),
            BoundaryPosition(longitude: -10, latitude: 10),
            BoundaryPosition(longitude: 10, latitude: 10),
          ]
        ],
      );

      final loc = LocationModel.validated(latitude: 0, longitude: 0);
      final result = await routingService.calculateSafeRoute(loc, [boundary]);
      
      expect(result.status, RoutingStatus.unavailable);
    });

    // 3. MULTIPLE-BOUNDARY TEST
    test('route respects multiple boundaries without crossing them', () async {
      // User is inside Polygon A
      double offA = 0.0009;
      final boundaryA = BoundaryModel(
        id: 'A',
        name: 'Polygon A',
        riskLevel: RiskLevel.high,
        polygon: [
          [
            BoundaryPosition(longitude: offA, latitude: offA),
            BoundaryPosition(longitude: offA, latitude: -offA),
            BoundaryPosition(longitude: -offA, latitude: -offA),
            BoundaryPosition(longitude: -offA, latitude: offA),
            BoundaryPosition(longitude: offA, latitude: offA),
          ]
        ],
      );

      // Polygon B is blocking one escape route (just north of A)
      final boundaryB = BoundaryModel(
        id: 'B',
        name: 'Polygon B',
        riskLevel: RiskLevel.high,
        polygon: [
          [
            BoundaryPosition(longitude: offA, latitude: 0.002),
            BoundaryPosition(longitude: offA, latitude: 0.001),
            BoundaryPosition(longitude: -offA, latitude: 0.001),
            BoundaryPosition(longitude: -offA, latitude: 0.002),
            BoundaryPosition(longitude: offA, latitude: 0.002),
          ]
        ],
      );

      // Polygon C is somewhere else in search area
      final boundaryC = BoundaryModel(
        id: 'C',
        name: 'Polygon C',
        riskLevel: RiskLevel.high,
        polygon: [
          [
            BoundaryPosition(longitude: 0.005, latitude: 0.005),
            BoundaryPosition(longitude: 0.005, latitude: 0.004),
            BoundaryPosition(longitude: 0.004, latitude: 0.004),
            BoundaryPosition(longitude: 0.004, latitude: 0.005),
            BoundaryPosition(longitude: 0.005, latitude: 0.005),
          ]
        ],
      );

      final loc = LocationModel.validated(latitude: 0, longitude: 0);
      final boundaries = [boundaryA, boundaryB, boundaryC];
      final result = await routingService.calculateSafeRoute(loc, boundaries);
      
      expect(result.status, RoutingStatus.available, reason: result.message);

      // Verify route points do not intersect B or C, and eventually exit A
      bool exitedA = false;
      for (final p in result.routePoints!) {
        expect(isPointInPolygon(latitude: p.latitude, longitude: p.longitude, polygon: boundaryB.polygon), false, reason: "Route enters Polygon B");
        expect(isPointInPolygon(latitude: p.latitude, longitude: p.longitude, polygon: boundaryC.polygon), false, reason: "Route enters Polygon C");
        
        if (!isPointInPolygon(latitude: p.latitude, longitude: p.longitude, polygon: boundaryA.polygon)) {
            exitedA = true;
        }
      }
      expect(exitedA, true, reason: "Route never exited Polygon A");
    });
    
    // 4. SAFETY BUFFER TEST
    
    test('route maintains clearance distance from boundaries', () async {
       // A is a tiny restricted box where the user is
      final boundaryA = BoundaryModel(
        id: 'A',
        name: 'Polygon A',
        riskLevel: RiskLevel.high,
        polygon: [
          [
            BoundaryPosition(longitude: 0.0001, latitude: 0.0001),
            BoundaryPosition(longitude: 0.0001, latitude: -0.0001),
            BoundaryPosition(longitude: -0.0001, latitude: -0.0001),
            BoundaryPosition(longitude: -0.0001, latitude: 0.0001),
            BoundaryPosition(longitude: 0.0001, latitude: 0.0001),
          ]
        ],
      );

       // B is a polygon to the east that we must avoid with clearance
       final boundary = BoundaryModel(
        id: 'B',
        name: 'Polygon B',
        riskLevel: RiskLevel.high,
        polygon: [
          [
            BoundaryPosition(longitude: 0.0010, latitude: 0.0010),
            BoundaryPosition(longitude: 0.0010, latitude: -0.0010),
            BoundaryPosition(longitude: 0.0005, latitude: -0.0010),
            BoundaryPosition(longitude: 0.0005, latitude: 0.0010),
            BoundaryPosition(longitude: 0.0010, latitude: 0.0010),
          ]
        ],
      );
      final loc = LocationModel.validated(latitude: 0, longitude: 0);
      
      final boundaries = [boundaryA, boundary];
      final result = await routingService.calculateSafeRoute(loc, boundaries);
      expect(result.status, RoutingStatus.available, reason: result.message);
      
      for (final p in result.routePoints!) {
          if (!isPointInPolygon(latitude: p.latitude, longitude: p.longitude, polygon: boundaryA.polygon)) {
             final closest = closestPointOnPolygon(latitude: p.latitude, longitude: p.longitude, polygon: boundary.polygon);
             if (closest != null) {
                 expect(closest.distanceMeters, greaterThanOrEqualTo(RoutingService.safetyClearanceMeters - 1.0)); // allow 1m floating point leeway
             }
          }
      }
    });


  });
}
