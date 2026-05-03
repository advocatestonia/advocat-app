@Tags(['fast'])
library;

// =============================================================================
// MaxWidthWrapper viewport behaviour (Fix #2 from QA report 2026-05-03).
// =============================================================================
//
// On viewports wider than [defaultMaxWidth] (480px) the wrapper must
// constrain its child to that width, centred horizontally. On narrow
// viewports (mobile) it must NOT artificially shrink the child below
// what the surrounding constraint already allows.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/shared/widgets/max_width_wrapper.dart';

void main() {
  group('MaxWidthWrapper', () {
    Future<void> pumpAtSize(WidgetTester tester, Size size) async {
      // Set DPR to 1.0 first so physicalSize maps 1:1 to logical pixels.
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = size;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MaxWidthWrapper(
              child: Container(
                key: const Key('child'),
                color: const Color(0xFF000000),
                // Stretch to fill whatever constraint the wrapper allows.
                width: double.infinity,
                height: 100,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('mobile viewport (400px) — child width is unchanged',
        (tester) async {
      await pumpAtSize(tester, const Size(400, 800));

      final childSize = tester.getSize(find.byKey(const Key('child')));
      // Mobile viewport is narrower than the 480px cap, so the wrapper
      // is a no-op visually — the child fills the available width.
      expect(childSize.width, 400);
    });

    testWidgets('desktop viewport (1440px) — child is capped at 480px',
        (tester) async {
      await pumpAtSize(tester, const Size(1440, 900));

      final childSize = tester.getSize(find.byKey(const Key('child')));
      expect(childSize.width, MaxWidthWrapper.defaultMaxWidth);
      expect(childSize.width, 480);
    });

    testWidgets('desktop viewport — child is centred horizontally',
        (tester) async {
      await pumpAtSize(tester, const Size(1440, 900));

      final childRect = tester.getRect(find.byKey(const Key('child')));
      // Equal gutters on both sides → child is centred.
      final leftGutter = childRect.left;
      final rightGutter = 1440 - childRect.right;
      expect(leftGutter, closeTo(rightGutter, 0.5));
      // And the gutters are non-trivial (>400px each side at 1440 viewport).
      expect(leftGutter, greaterThan(400));
    });

    testWidgets('custom maxWidth is respected', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 800);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MaxWidthWrapper(
              maxWidth: 600,
              child: Container(
                key: const Key('child'),
                color: const Color(0xFF000000),
                width: double.infinity,
                height: 100,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final childSize = tester.getSize(find.byKey(const Key('child')));
      expect(childSize.width, 600);
    });
  });
}
