import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:sqflite/sqflite.dart';
import 'package:border_safety_alert/screens/map_screen.dart';
import 'package:border_safety_alert/models/gps_snapshot.dart';
import 'package:border_safety_alert/models/location_model.dart';
import 'package:border_safety_alert/models/safety_state.dart';
import 'package:border_safety_alert/models/boundary_model.dart';
import 'package:border_safety_alert/models/geofence_result.dart';
import 'package:border_safety_alert/models/geofence_state.dart';
import 'package:border_safety_alert/services/offline_map_service.dart';

class EmptyOfflineMap extends OfflineMapService {
  @override Future<void> initialize({DatabaseFactory? factory}) async {}
}
GpsSnapshot fix(double latitude, double longitude, {bool stale = false}) => GpsSnapshot(
  fix: GpsFixState.locked, permission: LocationPermissionState.granted, serviceEnabled: true,
  stale: stale, location: LocationModel.validated(latitude:latitude,longitude:longitude,accuracy:10),
);
const boundary = BoundaryModel(id:'test-zone',name:'Configured test zone',riskLevel:RiskLevel.high,polygon:[[
  BoundaryPosition(latitude:10,longitude:77),BoundaryPosition(latitude:10,longitude:77.1),
  BoundaryPosition(latitude:10.1,longitude:77.1),BoundaryPosition(latitude:10,longitude:77),
]]);
void main() {
  Future<void> show(WidgetTester tester, GpsSnapshot gps) async {
    await tester.pumpWidget(MaterialApp(home:MapScreen(gps:gps,
      offlineMapService:EmptyOfflineMap(),checkConnectivity:()async=>true,loadBoundaries:()async=>[boundary],
      geoFence:const GeoFenceResult(state:GeoFenceState.safe,nearestBoundary:boundary))));
    await tester.pump(); await tester.pump(const Duration(milliseconds:100));
  }
  testWidgets('street layer uses labelled tiles and zoom buttons reach world view', (tester) async {
    await show(tester,fix(10.05,77.05));
    expect(tester.widget<TileLayer>(find.byType(TileLayer).first).urlTemplate,contains('tile.openstreetmap.org'));
    for (var i=0;i<15;i++) { await tester.tap(find.byTooltip('Zoom Out')); await tester.pump(); }
    final controller=tester.widget<FlutterMap>(find.byType(FlutterMap)).mapController!;
    expect(controller.camera.zoom,2);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(),isNull);
  });
  testWidgets('configured-boundary action fits zone and stops camera follow', (tester) async {
    await show(tester,fix(10.2,77.2));
    await tester.tap(find.byTooltip('Show configured boundaries')); await tester.pump();
    final controller=tester.widget<FlutterMap>(find.byType(FlutterMap)).mapController!;
    expect(controller.camera.zoom,lessThanOrEqualTo(14));
    expect(find.byTooltip('Free Mode: ON'),findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('fresh fix moves camera but stale fix does not', (tester) async {
    await show(tester,fix(10.05,77.05));
    await show(tester,fix(10.06,77.06));
    final controller=tester.widget<FlutterMap>(find.byType(FlutterMap)).mapController!;
    expect(controller.camera.center.latitude,closeTo(10.06,0.0001));
    await show(tester,fix(20,80,stale:true));
    expect(controller.camera.center.latitude,closeTo(10.06,0.0001));
    await tester.pumpWidget(const SizedBox());
  });
}
