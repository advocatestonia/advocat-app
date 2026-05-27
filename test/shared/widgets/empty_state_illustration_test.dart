@Tags(['fast'])
library;

// =============================================================================
// EmptyState — illustration parameter tests.
//
// Covers the brand-illustration system added 2026-05-27:
//   * Illustration asset renders via Image.asset when `illustration` provided
//   * Icon fallback rendered when `illustration` is null (backward compat)
//   * Custom `illustrationSize` is respected
//   * Illustration takes precedence over icon (icon NOT shown when both given,
//     unless asset fails to load — fallback path is exercised in widget tree
//     by errorBuilder)
//   * Semantic label on illustration matches the title (a11y)
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

  group('EmptyState — illustration parameter', () {
    testWidgets('renders Image.asset when illustration provided', (tester) async {
      await tester.pumpWidget(_wrap(const EmptyState(
        icon: Icons.inbox_outlined,
        illustration: 'assets/illustrations/empty_inbox.png',
        title: 'No messages',
      )));
      // Don't await full settle — asset load may fail in test sandbox, that's
      // fine: errorBuilder will trip the icon fallback (covered separately).
      await tester.pump();

      expect(find.byType(Image), findsOneWidget,
          reason: 'Image widget must mount when illustration path provided.');
      expect(find.text('No messages'), findsOneWidget);
    });

    testWidgets('falls back to icon when illustration is null', (tester) async {
      await tester.pumpWidget(_wrap(const EmptyState(
        icon: Icons.folder_off_outlined,
        title: 'No cases yet',
      )));
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNothing,
          reason: 'No Image should mount when illustration is null.');
      expect(find.byIcon(Icons.folder_off_outlined), findsOneWidget,
          reason: 'Icon must render as fallback.');
    });

    testWidgets('respects custom illustrationSize', (tester) async {
      const customSize = 240.0;
      await tester.pumpWidget(_wrap(const EmptyState(
        icon: Icons.inbox_outlined,
        illustration: 'assets/illustrations/empty_vault.png',
        title: 'Secure space',
        illustrationSize: customSize,
      )));
      await tester.pump();

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.width, customSize);
      expect(image.height, customSize);
    });

    testWidgets('illustration takes precedence over icon in widget tree',
        (tester) async {
      await tester.pumpWidget(_wrap(const EmptyState(
        icon: Icons.gavel_outlined,
        illustration: 'assets/illustrations/empty_cases.png',
        title: 'No cases',
      )));
      await tester.pump();

      // Image is mounted; the raw fallback Icon is NOT in the tree (it lives
      // only inside errorBuilder which only triggers on load failure).
      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.gavel_outlined), findsNothing,
          reason: 'Icon must not render in primary path when illustration set.');
    });

    testWidgets('illustration carries semanticLabel matching title (a11y)',
        (tester) async {
      const title = 'Your secure vault';
      await tester.pumpWidget(_wrap(const EmptyState(
        icon: Icons.lock_outline,
        illustration: 'assets/illustrations/empty_vault.png',
        title: title,
      )));
      await tester.pump();

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.semanticLabel, title,
          reason: 'Illustration must expose title as a11y label for screen readers.');
    });
  });
}
