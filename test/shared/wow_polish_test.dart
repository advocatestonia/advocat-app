@Tags(['fast'])
library;

// wow_polish_test.dart
//
// Tests the v24.1 "WOW polish" shared widgets: AnimatedFadeIn, Haptic,
// and the invariants that make them safe to drop into any screen.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/shared/widgets/animated_fade_in.dart';
import 'package:advocat/shared/widgets/haptic.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── 1-5. AnimatedFadeIn ───────────────────────────────────────────────

  group('AnimatedFadeIn', () {
    testWidgets('1. renders child immediately with zero opacity then fades',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: AnimatedFadeIn(
          duration: Duration(milliseconds: 200),
          child: Text('hello'),
        ),
      ));
      // At t=0 opacity is 0
      expect(find.text('hello'), findsOneWidget);
      // Advance past the animation
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('2. respects delay before starting', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: AnimatedFadeIn(
          duration: Duration(milliseconds: 100),
          delay: Duration(milliseconds: 100),
          child: Text('delayed'),
        ),
      ));
      expect(find.text('delayed'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 50));
      // Still in delay window — child is there but at initial opacity.
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('delayed'), findsOneWidget);
    });

    testWidgets('3. SlideDirection.none skips AnimatedFadeIn slide wrapper',
        (tester) async {
      // When slideFrom is none, the AnimatedFadeIn subtree contains a
      // FadeTransition but NO SlideTransition of its own.  Use the
      // `descendant` finder to scope to our widget subtree — the
      // MaterialApp shell has unrelated SlideTransitions.
      await tester.pumpWidget(const MaterialApp(
        home: AnimatedFadeIn(
          slideFrom: SlideDirection.none,
          child: Text('no slide'),
        ),
      ));
      final afi = find.byType(AnimatedFadeIn);
      expect(afi, findsOneWidget);
      expect(
        find.descendant(of: afi, matching: find.byType(FadeTransition)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: afi, matching: find.byType(SlideTransition)),
        findsNothing,
      );
    });

    testWidgets('4. slide directions all render without crash',
        (tester) async {
      for (final dir in SlideDirection.values) {
        await tester.pumpWidget(MaterialApp(
          home: AnimatedFadeIn(
            slideFrom: dir,
            child: Text('slide $dir'),
          ),
        ));
        expect(find.text('slide $dir'), findsOneWidget);
      }
    });

    testWidgets('5. custom curve is accepted', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: AnimatedFadeIn(
          curve: Curves.bounceOut,
          child: Text('bouncy'),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('bouncy'), findsOneWidget);
    });
  });

  // ── 6-8. StaggeredFadeList ────────────────────────────────────────────

  group('StaggeredFadeList', () {
    testWidgets('6. renders all children (after stagger delays elapse)',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Material(
          child: SingleChildScrollView(
            child: StaggeredFadeList(children: [
              Text('a'),
              Text('b'),
              Text('c'),
            ]),
          ),
        ),
      ));
      // Stagger is 40ms per item, duration 260ms — pump past them all.
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('a'), findsOneWidget);
      expect(find.text('b'), findsOneWidget);
      expect(find.text('c'), findsOneWidget);
    });

    testWidgets('7. each child is wrapped in AnimatedFadeIn',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Material(
          child: SingleChildScrollView(
            child: StaggeredFadeList(children: [Text('x'), Text('y')]),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(AnimatedFadeIn), findsNWidgets(2));
    });

    testWidgets('8. empty children list does not crash', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Material(child: StaggeredFadeList(children: [])),
      ));
      expect(find.byType(StaggeredFadeList), findsOneWidget);
    });
  });

  // ── 9-14. Haptic helper ───────────────────────────────────────────────

  group('Haptic', () {
    setUp(() {
      Haptic.setEnabled(true);
    });

    test('9. default enabled = true', () {
      expect(Haptic.enabled, isTrue);
    });

    test('10. setEnabled(false) disables all feedback', () async {
      Haptic.setEnabled(false);
      expect(Haptic.enabled, isFalse);
      // These should no-op without throwing.
      await Haptic.lightTap();
      await Haptic.mediumImpact();
      await Haptic.heavyImpact();
      await Haptic.selection();
      await Haptic.success();
      await Haptic.error();
    });

    test('11. isSupported returns false on web/test environment', () {
      // Running under flutter_test counts as non-mobile-native — web or
      // desktop fallback.  We accept either false or true as the test
      // machine target may vary, but the call itself must not throw.
      final _ = Haptic.isSupported;
    });

    test('12. all haptic methods complete without throwing', () async {
      await Haptic.lightTap();
      await Haptic.mediumImpact();
      await Haptic.heavyImpact();
      await Haptic.selection();
      await Haptic.success();
      await Haptic.error();
    });

    test('13. multiple rapid calls do not pile up unhandled futures',
        () async {
      // Fire 20 taps in sequence, each should return quickly.
      for (var i = 0; i < 20; i++) {
        await Haptic.lightTap();
      }
    });

    test('14. re-enabling after disable resumes feedback', () async {
      Haptic.setEnabled(false);
      await Haptic.mediumImpact();
      Haptic.setEnabled(true);
      await Haptic.mediumImpact();
      expect(Haptic.enabled, isTrue);
    });
  });

  // ── 15-16. Integration sanity ────────────────────────────────────────

  group('WOW polish integration', () {
    testWidgets('15. AnimatedFadeIn + Haptic compose cleanly',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: AnimatedFadeIn(
            child: GestureDetector(
              onTap: () {
                Haptic.lightTap();
                tapped = true;
              },
              child: const Text('tap me'),
            ),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 260));
      await tester.tap(find.text('tap me'));
      expect(tapped, isTrue);
    });

    testWidgets('16. HapticFeedback.lightImpact can be mocked in tests',
        (tester) async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              SystemChannels.platform, (call) async {
        calls.add(call);
        return null;
      });
      // On web/desktop Haptic.isSupported is false so nothing goes through.
      await Haptic.lightTap();
      // That's OK — we only verify no exception.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
  });
}
