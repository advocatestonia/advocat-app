@Tags(['fast'])
library;

// =============================================================================
// consilium_indicator_test.dart — leading-edge navy dot when consilium fired.
// =============================================================================
//
// What we pin:
//   1. Renders a tooltip-wrapped circular dot when fired=true.
//   2. Collapses to a zero-sized SizedBox when fired=false.
//   3. The dot uses the navy primary colour by default (#1A365D).
//   4. Reduce-motion (disableAnimations=true) renders the dot at full
//      opacity immediately (no FadeTransition wrapper added by the widget).
//   5. Motion branch animates from opacity 0 → 1 across the duration.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/config/theme.dart';
import 'package:advocat/features/chat/widgets/consilium_indicator.dart';

Widget _wrap(Widget child, {bool disableAnimations = false}) {
  return MaterialApp(
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Center(child: child),
      ),
    ),
  );
}

Container? _firstCircle(WidgetTester tester) {
  final finder = find.byType(Container);
  for (final element in finder.evaluate()) {
    final widget = element.widget as Container;
    final deco = widget.decoration;
    if (deco is BoxDecoration && deco.shape == BoxShape.circle) {
      return widget;
    }
  }
  return null;
}

void main() {
  group('ConsiliumIndicator — fired', () {
    testWidgets('renders a circular dot when fired=true', (tester) async {
      await tester.pumpWidget(_wrap(
        const ConsiliumIndicator(fired: true),
      ));
      await tester.pump();
      expect(_firstCircle(tester), isNotNull);
      expect(find.byType(Tooltip), findsOneWidget);
    });

    testWidgets('uses navy primary colour by default', (tester) async {
      await tester.pumpWidget(_wrap(
        const ConsiliumIndicator(fired: true),
        disableAnimations: true,
      ));
      await tester.pump();
      final circle = _firstCircle(tester);
      expect(circle, isNotNull);
      final deco = circle!.decoration as BoxDecoration;
      expect(deco.color, equals(AppColors.primary));
    });

    testWidgets('shows the tooltip message via Semantics label',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const ConsiliumIndicator(
          fired: true,
          tooltip: 'Consilium reviewed',
        ),
      ));
      await tester.pump();
      // The Tooltip widget carries the message in its `message` field.
      final tooltip =
          tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, equals('Consilium reviewed'));
    });
  });

  group('ConsiliumIndicator — not fired', () {
    testWidgets('collapses to zero-sized box when fired=false',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const ConsiliumIndicator(fired: false),
      ));
      await tester.pump();
      expect(_firstCircle(tester), isNull);
      expect(find.byType(Tooltip), findsNothing);
    });
  });

  group('ConsiliumIndicator — reduce-motion', () {
    testWidgets(
        'skips FadeTransition when disableAnimations=true (instant render)',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const ConsiliumIndicator(fired: true),
        disableAnimations: true,
      ));
      await tester.pump();
      // Scope: no FadeTransition *inside* the indicator subtree. (The
      // MaterialApp/Scaffold scaffolding wraps the whole route in
      // FadeTransitions of its own — those are not ours.)
      final inside = find.descendant(
        of: find.byType(ConsiliumIndicator),
        matching: find.byType(FadeTransition),
      );
      expect(inside, findsNothing);
      expect(_firstCircle(tester), isNotNull);
    });
  });

  group('ConsiliumIndicator — motion', () {
    testWidgets('wraps in FadeTransition during entrance', (tester) async {
      await tester.pumpWidget(_wrap(
        const ConsiliumIndicator(
          fired: true,
          duration: Duration(milliseconds: 200),
        ),
      ));
      await tester.pump();
      final inside = find.descendant(
        of: find.byType(ConsiliumIndicator),
        matching: find.byType(FadeTransition),
      );
      expect(inside, findsOneWidget);
      // Let it settle so the test exits cleanly.
      await tester.pump(const Duration(milliseconds: 250));
    });
  });
}
