import 'package:border_safety_alert/models/gps_snapshot.dart';
import 'package:border_safety_alert/models/location_model.dart';
import 'package:border_safety_alert/models/safety_state.dart';
import 'package:border_safety_alert/widgets/gps_live_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(GpsLiveCard card) => MaterialApp(home: Scaffold(body: card));

void main() {
  group('GpsLiveCard', () {
    testWidgets('renders live coordinates when locked', (tester) async {
      final snapshot = GpsSnapshot(
        fix: GpsFixState.locked,
        permission: LocationPermissionState.granted,
        serviceEnabled: true,
        location: LocationModel.validated(
          latitude: 10.12345,
          longitude: 78.54321,
          timestamp: DateTime.now(),
          speed: 12.5,
          bearing: 85,
          accuracy: 8,
          altitude: 250,
        ),
      );
      await tester.pumpWidget(_wrap(GpsLiveCard(snapshot: snapshot)));

      expect(find.byKey(const Key('gps-live-card')), findsOneWidget);
      expect(find.textContaining('10.12345'), findsOneWidget);
      expect(find.textContaining('78.54321'), findsOneWidget);
      expect(find.textContaining('12.5 m/s'), findsOneWidget);
      expect(find.textContaining('85°'), findsOneWidget);
    });

    testWidgets('renders honest unavailable state with retry', (tester) async {
      var retried = false;
      const snapshot = GpsSnapshot(
        fix: GpsFixState.unavailable,
        permission: LocationPermissionState.denied,
        serviceEnabled: false,
        message: 'Location services are disabled.',
      );
      await tester.pumpWidget(
        _wrap(GpsLiveCard(snapshot: snapshot, onRetry: () => retried = true)),
      );

      expect(find.text('Location services are disabled.'), findsOneWidget);
      expect(find.textContaining('Latitude'), findsNothing);

      await tester.tap(find.byKey(const Key('gps-retry')));
      expect(retried, isTrue);
    });

    testWidgets('shows stale indicator for outdated fixes', (tester) async {
      final snapshot = GpsSnapshot(
        fix: GpsFixState.locked,
        permission: LocationPermissionState.granted,
        serviceEnabled: true,
        location: LocationModel.validated(
          latitude: 10,
          longitude: 78,
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        stale: true,
      );
      await tester.pumpWidget(_wrap(GpsLiveCard(snapshot: snapshot)));

      expect(find.text('Stale fix'), findsOneWidget);
    });
  });
}
