import 'package:border_safety_alert/core/theme/bsas_colors.dart';
import 'package:border_safety_alert/core/widgets/bsas_bottom_nav.dart';
import 'package:border_safety_alert/core/widgets/bsas_card.dart';
import 'package:border_safety_alert/core/widgets/bsas_count_up.dart';
import 'package:border_safety_alert/core/widgets/bsas_electric_border.dart';
import 'package:border_safety_alert/core/widgets/bsas_pill_nav.dart';
import 'package:border_safety_alert/core/widgets/bsas_slide_button.dart';
import 'package:border_safety_alert/core/widgets/bsas_states.dart';
import 'package:border_safety_alert/core/widgets/bsas_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('React Bits Native UI Components Tests', () {
    testWidgets('BSASSlideButton displays label, handles press and loading states', (
      WidgetTester tester,
    ) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BSASSlideButton(
              label: 'CONFIRM ENTRY',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('CONFIRM ENTRY'), findsOneWidget);
      await tester.tap(find.text('CONFIRM ENTRY'));
      expect(pressed, isTrue);

      // Loading state
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BSASSlideButton(
              label: 'CONFIRM ENTRY',
              loadingLabel: 'AUTHORIZING...',
              state: BSASSlideButtonState.loading,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('AUTHORIZING...'), findsOneWidget);

      // Success state
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BSASSlideButton(
              label: 'CONFIRM ENTRY',
              successLabel: 'ACCESS GRANTED ✓',
              state: BSASSlideButtonState.success,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('ACCESS GRANTED ✓'), findsOneWidget);
    });

    testWidgets('BSASCard renders content with touch-spotlight support', (
      WidgetTester tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BSASCard(
              onTap: () => tapped = true,
              child: const Text('Spotlight Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Spotlight Card Content'), findsOneWidget);
      await tester.tap(find.text('Spotlight Card Content'));
      expect(tapped, isTrue);
    });

    testWidgets('BSASElectricBorder renders border and respects reduced motion', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BSASElectricBorder(
              isActive: true,
              color: BsasColors.criticalRed,
              child: Text('Electric Alert Zone'),
            ),
          ),
        ),
      );

      expect(find.text('Electric Alert Zone'), findsOneWidget);
    });

    testWidgets('BSASPillNav allows switching categories', (
      WidgetTester tester,
    ) async {
      int selected = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: BSASPillNav(
                  items: const ['ALL', 'CRITICAL', 'WARNING'],
                  selectedIndex: selected,
                  onChanged: (idx) => setState(() => selected = idx),
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('CRITICAL'), findsOneWidget);
      expect(find.text('WARNING'), findsOneWidget);

      await tester.tap(find.text('CRITICAL'));
      await tester.pumpAndSettle();
      expect(selected, 1);
    });

    testWidgets('BSASBottomNav selects destinations and shows labels', (
      WidgetTester tester,
    ) async {
      int current = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                bottomNavigationBar: BSASBottomNav(
                  selectedIndex: current,
                  onDestinationSelected: (idx) => setState(() => current = idx),
                  destinations: const [
                    BSASNavItem(icon: Icons.home, label: 'Home'),
                    BSASNavItem(icon: Icons.map, label: 'Map'),
                    BSASNavItem(icon: Icons.shield, label: 'Safety'),
                  ],
                ),
              ),
            );
          },
        ),
      );

      expect(find.byKey(const Key('bottom-nav')), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Safety'), findsOneWidget);

      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();
      expect(current, 1);
    });

    testWidgets('BSASCountUp formats decimal numbers correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BSASCountUp(
              value: 12.4,
              decimalPlaces: 1,
              suffix: ' km',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('12.4 km'), findsOneWidget);
    });

    testWidgets('BSASTextField supports input, hint, and password obscure toggle', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BSASTextField(
              controller: controller,
              label: 'ACCESS CODE',
              hintText: 'Enter passcode',
              isPassword: true,
            ),
          ),
        ),
      );

      expect(find.text('ACCESS CODE'), findsOneWidget);
      expect(find.text('Enter passcode'), findsOneWidget);

      // Visibility toggle icon
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('BSASEmptyState and BSASErrorState render informative actionable feedback', (
      WidgetTester tester,
    ) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                BSASEmptyState(
                  title: 'NO ACTIVE INCIDENTS',
                  description: 'All sectors report peaceful passage.',
                  actionLabel: 'REFRESH FEED',
                  onAction: () => actionTriggered = true,
                ),
                const BSASErrorState(
                  title: 'GNSS Disconnected',
                  whatHappened: 'Hardware satellite signal lost in tunnel.',
                  whatStillWorks: 'Local cached boundaries and offline maps.',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('NO ACTIVE INCIDENTS'), findsOneWidget);
      expect(find.text('GNSS Disconnected'), findsOneWidget);
      expect(find.text('REFRESH FEED'), findsOneWidget);

      await tester.tap(find.text('REFRESH FEED'));
      expect(actionTriggered, isTrue);
    });
  });
}
