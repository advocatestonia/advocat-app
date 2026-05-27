@Tags(['fast'])
library;

// =============================================================================
// token_shimmer_test.dart — subtle one-shot horizontal sweep on new tokens.
// =============================================================================
//
// What we pin:
//   1. Renders the child immediately.
//   2. Wraps the child in a ShaderMask while the sweep is running (motion
//      branch only).
//   3. After the duration elapses the ShaderMask is gone — child is
//      rendered untouched (cheap for long messages).
//   4. Reduce-motion (MediaQueryData.disableAnimations=true) → never wraps
//      in a ShaderMask.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/chat/widgets/token_shimmer.dart';

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

void main() {
  group('TokenShimmer — motion branch', () {
    testWidgets('renders child immediately', (tester) async {
      await tester.pumpWidget(_wrap(
        const TokenShimmer(child: Text('Hello world')),
      ));
      await tester.pump();
      expect(find.text('Hello world'), findsOneWidget);
    });

    testWidgets('wraps child in ShaderMask during the sweep', (tester) async {
      await tester.pumpWidget(_wrap(
        const TokenShimmer(child: Text('Hello world')),
      ));
      // First frame after didChangeDependencies kicks the controller.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(ShaderMask), findsOneWidget);
    });

    testWidgets('removes ShaderMask after duration elapses', (tester) async {
      await tester.pumpWidget(_wrap(
        const TokenShimmer(
          duration: Duration(milliseconds: 100),
          child: Text('Hello world'),
        ),
      ));
      // Run past the controller duration.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      // Let the status listener's setState flush.
      await tester.pump();
      expect(find.byType(ShaderMask), findsNothing);
      expect(find.text('Hello world'), findsOneWidget);
    });
  });

  group('TokenShimmer — reduce-motion', () {
    testWidgets('skips ShaderMask entirely when disableAnimations=true',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const TokenShimmer(child: Text('Reduced')),
        disableAnimations: true,
      ));
      // Pump immediately and well past the default duration.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ShaderMask), findsNothing);
      expect(find.text('Reduced'), findsOneWidget);
    });
  });
}
