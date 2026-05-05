@Tags(['fast'])
library;

// =============================================================================
// MaxWidthWrapper viewport behaviour.
// =============================================================================
//
// Original Fix #2 from QA report 2026-05-03 capped EVERYTHING at 480px on
// desktop, which made the main shell (Home/Cases/Deadlines/Settings) look
// like a tiny phone in the middle of a wide page (full-width bottom-nav,
// narrow body) — confirmed P1 visual regression on 2026-05-05.
//
// New behaviour: when no explicit cap is passed, the wrapper picks a
// responsive cap based on viewport width:
//   - viewport <  600px → no constraint (mobile, full-width)
//   - viewport <  1024px → 720px cap (tablet)
//   - viewport >= 1024px → 1200px cap (desktop)
//
// When a caller passes an explicit [maxWidth] (e.g. form screens passing
// 480), that explicit cap always wins regardless of viewport.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/shared/widgets/max_width_wrapper.dart';

void main() {
  group('MaxWidthWrapper — responsive default (no explicit maxWidth)', () {
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

    testWidgets('mobile viewport (400px) — child fills full width',
        (tester) async {
      await pumpAtSize(tester, const Size(400, 800));

      final childSize = tester.getSize(find.byKey(const Key('child')));
      // Below the tablet breakpoint → wrapper imposes no cap, child
      // fills the available width.
      expect(childSize.width, 400);
    });

    testWidgets('mobile/tablet boundary (599px) — still unconstrained',
        (tester) async {
      await pumpAtSize(tester, const Size(599, 800));

      final childSize = tester.getSize(find.byKey(const Key('child')));
      expect(childSize.width, 599);
    });

    testWidgets('tablet viewport (768px) — child capped at 720',
        (tester) async {
      await pumpAtSize(tester, const Size(768, 1024));

      final childSize = tester.getSize(find.byKey(const Key('child')));
      expect(childSize.width, MaxWidthWrapper.tabletMaxWidth);
      expect(childSize.width, 720);
    });

    testWidgets('desktop viewport (1440px) — child capped at 1200, centred',
        (tester) async {
      await pumpAtSize(tester, const Size(1440, 900));

      final childSize = tester.getSize(find.byKey(const Key('child')));
      expect(childSize.width, MaxWidthWrapper.desktopMaxWidth);
      expect(childSize.width, 1200);

      final childRect = tester.getRect(find.byKey(const Key('child')));
      // Equal gutters on both sides → child is centred.
      final leftGutter = childRect.left;
      final rightGutter = 1440 - childRect.right;
      expect(leftGutter, closeTo(rightGutter, 0.5));
      // Gutters are non-trivial but NOT the 480px-of-empty-space-each-side
      // we had with the old hardcoded 480 cap (which would have been ~480
      // on each side at 1440 viewport).
      expect(leftGutter, closeTo(120, 1));
    });

    testWidgets('huge viewport (2560px) — still capped at 1200',
        (tester) async {
      await pumpAtSize(tester, const Size(2560, 1440));

      final childSize = tester.getSize(find.byKey(const Key('child')));
      expect(childSize.width, 1200);
    });
  });

  group('MaxWidthWrapper — explicit maxWidth override', () {
    Future<void> pumpAtSizeWithCap(
      WidgetTester tester,
      Size size,
      double cap,
    ) async {
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
              maxWidth: cap,
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
    }

    testWidgets(
        'explicit 480 wins on desktop (form-screen pattern)',
        (tester) async {
      await pumpAtSizeWithCap(tester, const Size(1440, 900), 480);

      final childSize = tester.getSize(find.byKey(const Key('child')));
      // Forms must stay narrow even when the responsive default would
      // otherwise let them grow to 1200.
      expect(childSize.width, 480);
    });

    testWidgets(
        'explicit 480 is a no-op on mobile (constraint exceeds viewport)',
        (tester) async {
      await pumpAtSizeWithCap(tester, const Size(400, 800), 480);

      final childSize = tester.getSize(find.byKey(const Key('child')));
      // Child cannot grow past the surrounding 400px constraint, but
      // also is not artificially shrunk.
      expect(childSize.width, 400);
    });

    testWidgets('explicit 600 cap is respected on a 1200px viewport',
        (tester) async {
      await pumpAtSizeWithCap(tester, const Size(1200, 800), 600);

      final childSize = tester.getSize(find.byKey(const Key('child')));
      expect(childSize.width, 600);
    });
  });

  // ===========================================================================
  // Regression: every non-shell top-level Scaffold must wrap its body in
  // MaxWidthWrapper so it does not stretch full-width on desktop.
  //
  // Shell routes (home/cases/deadlines/settings) are wrapped via MainShell
  // and rely on the responsive default (no explicit maxWidth).
  //
  // Form / detail screens listed below pass an explicit narrow cap (480)
  // so they stay phone-width on desktop — 1200px-wide form fields and
  // single-column case detail look terrible.
  //
  // We don't render these screens in widget tests (they pull a heavy
  // graph of providers); a source-grep is sufficient and keeps the test
  // fast & resilient.
  // ===========================================================================
  group('MaxWidthWrapper source-grep regression', () {
    final wrappedScreens = <String>[
      'lib/features/auth/screens/login_screen.dart',
      'lib/features/auth/screens/register_screen.dart',
      'lib/features/onboarding/screens/onboarding_screen.dart',
      'lib/features/settings/screens/subscription_screen.dart',
      'lib/features/settings/screens/edit_profile_screen.dart',
      'lib/features/cases/screens/case_detail_screen.dart',
      'lib/features/cases/screens/case_create_screen.dart',
      'lib/features/cases/screens/case_documents_screen.dart',
      'lib/features/cases/screens/case_timeline_screen.dart',
      'lib/shared/widgets/main_shell.dart',
    ];

    for (final relPath in wrappedScreens) {
      test('$relPath imports + uses MaxWidthWrapper', () {
        final file = File(relPath);
        expect(file.existsSync(), isTrue,
            reason: 'expected $relPath to exist');
        final content = file.readAsStringSync();

        expect(
          content.contains('max_width_wrapper.dart'),
          isTrue,
          reason: '$relPath must import MaxWidthWrapper '
              '(found no `max_width_wrapper.dart` import). '
              'Wrap the top-level Scaffold body so the screen does not '
              'stretch full-width on desktop.',
        );
        expect(
          content.contains('MaxWidthWrapper('),
          isTrue,
          reason: '$relPath must instantiate MaxWidthWrapper(...) '
              '— wrap the Scaffold body to keep the desktop layout '
              'phone-width.',
        );
      });
    }

    // Form / detail screens must pass an explicit narrow cap (480) so
    // they don't grow to 1200 on desktop with the new responsive default.
    final formScreens = <String>[
      'lib/features/auth/screens/login_screen.dart',
      'lib/features/auth/screens/register_screen.dart',
      'lib/features/onboarding/screens/onboarding_screen.dart',
      'lib/features/settings/screens/subscription_screen.dart',
      'lib/features/settings/screens/edit_profile_screen.dart',
      'lib/features/cases/screens/case_detail_screen.dart',
      'lib/features/cases/screens/case_create_screen.dart',
      'lib/features/cases/screens/case_documents_screen.dart',
      'lib/features/cases/screens/case_timeline_screen.dart',
    ];

    for (final relPath in formScreens) {
      test('$relPath passes explicit maxWidth: 480', () {
        final file = File(relPath);
        final content = file.readAsStringSync();
        expect(
          content.contains('maxWidth: 480'),
          isTrue,
          reason: '$relPath must pass `maxWidth: 480` to MaxWidthWrapper '
              '— form/detail screens must not grow to 1200 on desktop.',
        );
      });
    }

    // The main shell, by contrast, must NOT pass an explicit maxWidth —
    // it relies on the responsive default so Home/Cases/Deadlines/Settings
    // can breathe out to 720/1200 instead of being stuck at 480.
    test('lib/shared/widgets/main_shell.dart uses responsive default '
        '(no explicit maxWidth)', () {
      final content =
          File('lib/shared/widgets/main_shell.dart').readAsStringSync();
      // The MainShell call site must be plain `MaxWidthWrapper(child: child)`.
      expect(
        content.contains('MaxWidthWrapper(child: child)'),
        isTrue,
        reason: 'MainShell must wrap with MaxWidthWrapper(child: child) '
            'and rely on the responsive default. If you pin an explicit '
            'maxWidth here you reintroduce the 480px-shell P1 regression.',
      );
      // And there must be no `maxWidth:` in the same wrapper invocation
      // (defensive — catches the case where someone adds a parameter on a
      // multi-line call).
      final shellWrapPattern = RegExp(
        r'MaxWidthWrapper\(\s*maxWidth:',
        multiLine: true,
      );
      expect(
        shellWrapPattern.hasMatch(content),
        isFalse,
        reason: 'MainShell must NOT pass an explicit maxWidth to '
            'MaxWidthWrapper — that was the 2026-05-03 regression.',
      );
    });
  });
}
