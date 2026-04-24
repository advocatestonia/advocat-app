@Tags(['fast'])
library;

// Overnight isolated test suite — DOES NOT modify production code.
// Widget smoke tests for AppButton.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/shared/widgets/app_button.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('AppButton smoke', () {
    testWidgets('renders the label', (tester) async {
      await tester.pumpWidget(_wrap(
        AppButton(label: 'Save', onPressed: () {}),
      ));
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('invokes onPressed when tapped', (tester) async {
      var count = 0;
      await tester.pumpWidget(_wrap(
        AppButton(label: 'Save', onPressed: () => count++),
      ));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(count, 1);
    });

    testWidgets('renders every variant without throwing', (tester) async {
      for (final v in AppButtonVariant.values) {
        await tester.pumpWidget(_wrap(
          AppButton(label: v.name, variant: v, onPressed: () {}),
        ));
        expect(find.text(v.name), findsOneWidget);
      }
    });

    testWidgets('disabled when onPressed == null', (tester) async {
      await tester.pumpWidget(_wrap(
        const AppButton(label: 'Disabled', onPressed: null),
      ));
      expect(find.text('Disabled'), findsOneWidget);
      // Tap should not throw — button handles null handler.
      await tester.tap(find.text('Disabled'));
      await tester.pump();
    });

    testWidgets('loading state does not throw', (tester) async {
      await tester.pumpWidget(_wrap(
        AppButton(label: 'Loading', isLoading: true, onPressed: () {}),
      ));
      // Not asserting visual — just mount stability.
      await tester.pump();
    });

    testWidgets('renders every size', (tester) async {
      for (final s in AppButtonSize.values) {
        await tester.pumpWidget(_wrap(
          AppButton(label: s.name, size: s, onPressed: () {}),
        ));
        expect(find.text(s.name), findsOneWidget);
      }
    });

    testWidgets('full-width variant mounts', (tester) async {
      await tester.pumpWidget(_wrap(
        AppButton(label: 'Wide', isFullWidth: true, onPressed: () {}),
      ));
      expect(find.text('Wide'), findsOneWidget);
    });
  });
}
