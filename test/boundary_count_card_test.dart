import 'dart:async';

import 'package:border_safety_alert/services/boundary_summary.dart';
import 'package:border_safety_alert/widgets/boundary_count_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(BoundaryCountCard card) => MaterialApp(home: Scaffold(body: card));

void main() {
  group('BoundaryCountCard', () {
    testWidgets('shows count with demo disclaimer', (tester) async {
      await tester.pumpWidget(
        _wrap(
          BoundaryCountCard(
            summary: Future.value(
              const BoundarySummary(count: 2, allDemo: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('boundary-count-card')), findsOneWidget);
      expect(find.text('Offline boundaries: 2'), findsOneWidget);
      expect(find.text('Demo data — non-authoritative'), findsOneWidget);
    });

    testWidgets('shows error state honestly', (tester) async {
      await tester.pumpWidget(
        _wrap(
          BoundaryCountCard(
            summary: Future.value(
              const BoundarySummary(
                count: 0,
                allDemo: true,
                error: 'disk gone',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Offline boundaries unavailable'), findsOneWidget);
      expect(find.textContaining('disk gone'), findsOneWidget);
    });

    testWidgets('shows loading state while waiting', (tester) async {
      await tester.pumpWidget(
        _wrap(BoundaryCountCard(summary: Completer<BoundarySummary>().future)),
      );
      await tester.pump();

      expect(find.text('Loading offline boundaries…'), findsOneWidget);
    });
  });
}
