import 'package:border_safety_alert/app.dart';
import 'package:border_safety_alert/services/gps_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_boundary_provider.dart';
import 'helpers/fake_location_provider.dart';

/// Quiet fakes: disabled GPS and a 2-item demo boundary store, so no
/// platform channels are touched.
BorderSafetyApp _app() => BorderSafetyApp(
  gpsService: GpsService(provider: FakeLocationProvider(serviceEnabled: false)),
  boundaryProvider: FakeBoundarySummaryProvider(),
);

void main() {
  testWidgets('App launches with Home screen and bottom navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('app-shell')), findsOneWidget);
    expect(find.byKey(const Key('screen-home')), findsOneWidget);
    expect(find.byKey(const Key('safety-state')), findsOneWidget);
    expect(find.byKey(const Key('gps-live-card')), findsOneWidget);
    expect(find.byKey(const Key('boundary-count-card')), findsOneWidget);
    expect(find.text('Offline boundaries: 2'), findsOneWidget);
    expect(find.byKey(const Key('bottom-nav')), findsOneWidget);

    // All six destinations are present.
    for (final label in [
      'Home',
      'Map',
      'Safety',
      'Route',
      'History',
      'Settings',
    ]) {
      expect(find.text(label), findsWidgets);
    }
  });

  testWidgets('Home shows demo disclaimer, not fake live data', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.textContaining('Demo data'), findsWidgets);
    // Honest GPS state: disabled services are reported, not fabricated.
    expect(find.textContaining('disabled'), findsWidgets);
  });
}
