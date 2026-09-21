import 'package:border_safety_alert/app.dart';
import 'package:border_safety_alert/services/gps_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_boundary_provider.dart';
import 'helpers/fake_location_provider.dart';

/// Tapping each bottom-navigation destination must reveal its screen.
Future<void> _tapAndExpect(
  WidgetTester tester,
  String destinationLabel,
  Key screenKey,
) async {
  await tester.tap(find.text(destinationLabel).last);
  await tester.pumpAndSettle();
  expect(find.byKey(screenKey), findsOneWidget);
}

void main() {
  testWidgets('Bottom navigation reaches all six screens', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      BorderSafetyApp(
        gpsService: GpsService(
          provider: FakeLocationProvider(serviceEnabled: false),
        ),
        boundaryProvider: FakeBoundarySummaryProvider(),
      ),
    );
    await tester.pumpAndSettle();

    await _tapAndExpect(tester, 'Map', const Key('screen-map'));
    expect(find.byKey(const Key('map-placeholder')), findsOneWidget);
    expect(find.byKey(const Key('map-gps-line')), findsOneWidget);

    await _tapAndExpect(tester, 'Safety', const Key('screen-safety'));
    await _tapAndExpect(tester, 'Route', const Key('screen-route'));
    await _tapAndExpect(tester, 'History', const Key('screen-history'));
    await _tapAndExpect(tester, 'Settings', const Key('screen-settings'));

    // Settings toggles respond to interaction.
    await tester.tap(find.byKey(const Key('setting-voice')));
    await tester.pump();
    await _tapAndExpect(tester, 'Home', const Key('screen-home'));
  });
}
