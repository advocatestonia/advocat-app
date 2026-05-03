@Tags(['fast'])
library;

// =============================================================================
// Regression guard: MainShell must wrap its body in MaxWidthWrapper, and
// LoginScreen must wrap its content the same way (Fix #2 from QA report
// 2026-05-03 — the desktop "stretched mobile UI" P0 blocker).
// =============================================================================
//
// Source-grep style, matching the convention in
// test/features/home/home_quick_actions_layout_test.dart. We're asserting on
// the structural intent rather than rendering the full Flutter+Riverpod
// shell, which is heavy and not needed to detect this regression.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MainShell uses MaxWidthWrapper around body', () {
    late String source;

    setUpAll(() {
      source =
          File('lib/shared/widgets/main_shell.dart').readAsStringSync();
    });

    test('imports MaxWidthWrapper', () {
      expect(source, contains("import 'max_width_wrapper.dart'"),
          reason:
              'MainShell must import MaxWidthWrapper to constrain mobile UI '
              'on desktop.');
    });

    test('Scaffold body is wrapped in MaxWidthWrapper(child: child)', () {
      // Match the exact wiring (allowing trailing-comma variations).
      expect(source, contains('body: MaxWidthWrapper(child: child)'),
          reason:
              'MainShell.body must be MaxWidthWrapper(child: child) so the '
              'shell tabs (home/cases/deadlines/settings) do not stretch the '
              'mobile UI to desktop width.');
    });

    test('does NOT wire body directly to child (regression sentinel)', () {
      // The OLD code was `body: child,`. If anyone reverts the wrapper
      // this test fires. We check for the literal substring with a
      // trailing comma to avoid matching the wrapped form.
      expect(source, isNot(contains('body: child,')),
          reason:
              'MainShell.body must not be wired directly to `child` — wrap it '
              'in MaxWidthWrapper to fix the desktop stretching bug.');
    });
  });

  group('LoginScreen uses MaxWidthWrapper around its content', () {
    late String source;

    setUpAll(() {
      source = File('lib/features/auth/screens/login_screen.dart')
          .readAsStringSync();
    });

    test('imports MaxWidthWrapper', () {
      expect(
          source,
          contains(
              "import '../../../shared/widgets/max_width_wrapper.dart'"),
          reason:
              'LoginScreen must import MaxWidthWrapper to constrain its form '
              'on desktop viewports.');
    });

    test('LoginScreen body uses MaxWidthWrapper somewhere', () {
      expect(source, contains('MaxWidthWrapper('),
          reason:
              'LoginScreen must wrap its content in MaxWidthWrapper so the '
              'login form does not stretch full-screen on desktop.');
    });
  });
}
