@Tags(['fast'])
library;

// Overnight isolated test suite — DOES NOT modify production code.
// Widget smoke tests for StatusChip.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/shared/widgets/status_chip.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('StatusChip smoke', () {
    testWidgets('renders the label', (tester) async {
      await tester.pumpWidget(_wrap(const StatusChip(label: 'Active')));
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('renders for every variant', (tester) async {
      for (final v in StatusChipVariant.values) {
        await tester.pumpWidget(
          _wrap(StatusChip(label: v.name, variant: v)),
        );
        expect(find.text(v.name), findsOneWidget);
      }
    });

    testWidgets('renders with optional icon', (tester) async {
      await tester.pumpWidget(
        _wrap(const StatusChip(label: 'X', icon: Icons.check)),
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('renders without dot when showDot = false', (tester) async {
      await tester.pumpWidget(
        _wrap(const StatusChip(label: 'NoDot', showDot: false)),
      );
      expect(find.text('NoDot'), findsOneWidget);
    });
  });
}
