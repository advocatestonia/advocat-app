@Tags(['fast'])
library;

// =============================================================================
// streaming_cursor_test.dart — signature pulsing-dot cursor for streaming.
// =============================================================================
//
// What we pin:
//   1. Renders a dot (Container with BoxShape.circle) when active.
//   2. Collapses to a zero-size widget when active=false.
//   3. The animation controller actually runs while active (pump twice and
//      verify the rendered dot diameter changes between frames).
//   4. Reduce-motion (MediaQueryData.disableAnimations=true) → static dot,
//      no animation frames driving rebuilds.
//   5. Toggling active=false stops the controller (verified by checking
//      the widget collapses to zero size).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/chat/widgets/streaming_cursor.dart';

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

double? _circleDiameterAt(WidgetTester tester) {
  // Walk the rendered subtree and find the first Container with a circular
  // decoration — that's the dot.
  final finder = find.byType(Container);
  if (finder.evaluate().isEmpty) return null;
  for (final element in finder.evaluate()) {
    final widget = element.widget as Container;
    final deco = widget.decoration;
    if (deco is BoxDecoration && deco.shape == BoxShape.circle) {
      final renderBox = element.renderObject as RenderBox?;
      return renderBox?.size.width;
    }
  }
  return null;
}

void main() {
  group('StreamingCursor — active', () {
    testWidgets('renders a circular dot when active=true', (tester) async {
      await tester.pumpWidget(_wrap(const StreamingCursor(active: true)));
      await tester.pump(const Duration(milliseconds: 16));
      expect(_circleDiameterAt(tester), isNotNull);
    });

    testWidgets('returns zero-sized SizedBox when active=false',
        (tester) async {
      await tester.pumpWidget(_wrap(const StreamingCursor(active: false)));
      await tester.pump();
      // No circular dot at all.
      expect(_circleDiameterAt(tester), isNull);
    });

    testWidgets('animation drives the dot size across frames', (tester) async {
      await tester.pumpWidget(_wrap(const StreamingCursor(active: true)));
      // Sample at two distinct points in the pulse cycle.
      await tester.pump(const Duration(milliseconds: 50));
      final sizeA = _circleDiameterAt(tester);
      await tester.pump(const Duration(milliseconds: 400));
      final sizeB = _circleDiameterAt(tester);
      expect(sizeA, isNotNull);
      expect(sizeB, isNotNull);
      // The two samples should differ — proves the controller is running.
      expect(sizeA == sizeB, isFalse,
          reason: 'cursor should pulse: sizes at t=50ms and t=450ms differ');
      // Pump a few more frames so the test exits cleanly.
      await tester.pump(const Duration(milliseconds: 16));
    });
  });

  group('StreamingCursor — reduce-motion', () {
    testWidgets('paints a static dot when disableAnimations=true',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const StreamingCursor(active: true),
        disableAnimations: true,
      ));
      // Pump several frames — none should change the dot diameter because
      // the controller is stopped.
      await tester.pump(const Duration(milliseconds: 16));
      final sizeA = _circleDiameterAt(tester);
      await tester.pump(const Duration(milliseconds: 500));
      final sizeB = _circleDiameterAt(tester);
      expect(sizeA, isNotNull);
      expect(sizeA, equals(sizeB),
          reason: 'reduce-motion: dot must not pulse');
      // The static dot uses the maxSize (8px by spec default).
      expect(sizeA, closeTo(8.0, 0.01));
    });
  });

  group('StreamingCursor — toggle', () {
    testWidgets('switching active=true → false hides the dot',
        (tester) async {
      // ignore: prefer_function_declarations_over_variables
      final mountActive = (bool active) => _wrap(StreamingCursor(active: active));

      await tester.pumpWidget(mountActive(true));
      await tester.pump(const Duration(milliseconds: 16));
      expect(_circleDiameterAt(tester), isNotNull);

      await tester.pumpWidget(mountActive(false));
      await tester.pump();
      expect(_circleDiameterAt(tester), isNull);
    });
  });
}
