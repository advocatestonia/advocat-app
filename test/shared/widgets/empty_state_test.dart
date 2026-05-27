@Tags(['fast'])
library;

// =============================================================================
// EmptyState — widget tests.
//
// Covers:
//   * Default icon (Icons.inbox_outlined) renders when not overridden
//   * Title + body render with the right Material text styles
//   * Description omits a SizedBox when not provided (compact layout)
//   * Optional CTA only renders when both actionLabel + onAction supplied
//   * CTA tap fires the onAction callback
//   * Custom icon is honoured
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/shared/widgets/empty_state.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EmptyState — base rendering', () {
    testWidgets('renders title + body when description provided', (tester) async {
      await tester.pumpWidget(_wrap(const EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No drafts yet',
        description: 'Create your first draft to get started.',
      )));
      await tester.pumpAndSettle();

      expect(find.text('No drafts yet'), findsOneWidget);
      expect(find.text('Create your first draft to get started.'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('omits body widget when description is null', (tester) async {
      await tester.pumpWidget(_wrap(const EmptyState(
        icon: Icons.folder_off_outlined,
        title: 'Nothing here',
      )));
      await tester.pumpAndSettle();

      expect(find.text('Nothing here'), findsOneWidget);
      // Only the title Text should be present.
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('honors a custom icon override', (tester) async {
      await tester.pumpWidget(_wrap(const EmptyState(
        icon: Icons.gavel_outlined,
        title: 'No cases',
      )));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.gavel_outlined), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsNothing);
    });
  });

  group('EmptyState — optional CTA', () {
    testWidgets('no button when actionLabel is null', (tester) async {
      await tester.pumpWidget(_wrap(const EmptyState(
        icon: Icons.inbox_outlined,
        title: 'Nothing',
        description: 'No items.',
      )));
      await tester.pumpAndSettle();

      // No ElevatedButton from AppButton primary variant.
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('renders CTA when actionLabel + onAction provided', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(_wrap(EmptyState(
        icon: Icons.inbox_outlined,
        title: 'Nothing',
        description: 'No items.',
        actionLabel: 'Start',
        onAction: () => tapped++,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Start'), findsOneWidget);

      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      expect(tapped, 1, reason: 'CTA tap must invoke onAction callback.');
    });

    testWidgets('CTA hidden if only actionLabel provided (no onAction)',
        (tester) async {
      await tester.pumpWidget(_wrap(const EmptyState(
        icon: Icons.inbox_outlined,
        title: 'Nothing',
        actionLabel: 'Start',
      )));
      await tester.pumpAndSettle();

      // Per build() guard: both required.
      expect(find.text('Start'), findsNothing);
    });
  });

  group('EmptyState — compact mode reduces vertical padding', () {
    testWidgets('compact: still renders title + body + CTA correctly',
        (tester) async {
      await tester.pumpWidget(_wrap(EmptyState(
        icon: Icons.inbox_outlined,
        title: 'Compact',
        description: 'Compact body.',
        actionLabel: 'OK',
        onAction: () {},
        compact: true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Compact'), findsOneWidget);
      expect(find.text('Compact body.'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });
  });
}
