// Overnight isolated test suite — DOES NOT modify production code.
// Widget smoke tests for EmptyState.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/shared/widgets/empty_state.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: child),
    );

void main() {
  group('EmptyState smoke', () {
    testWidgets('renders icon + title', (tester) async {
      await tester.pumpWidget(_wrap(
        const EmptyState(
          icon: Icons.folder_off_outlined,
          title: 'No cases yet',
        ),
      ));
      expect(find.text('No cases yet'), findsOneWidget);
      expect(find.byIcon(Icons.folder_off_outlined), findsOneWidget);
    });

    testWidgets('description renders when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const EmptyState(
          icon: Icons.info_outline,
          title: 'Nothing',
          description: 'Add something to get started.',
        ),
      ));
      expect(find.text('Add something to get started.'), findsOneWidget);
    });

    testWidgets('action button triggers callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(
        EmptyState(
          icon: Icons.add,
          title: 'No items',
          actionLabel: 'Create',
          onAction: () => tapped = true,
        ),
      ));
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      expect(tapped, isTrue);
    });

    testWidgets('compact variant mounts without error', (tester) async {
      await tester.pumpWidget(_wrap(
        const EmptyState(
          icon: Icons.search_off,
          title: 'No results',
          compact: true,
        ),
      ));
      expect(find.text('No results'), findsOneWidget);
    });
  });
}
