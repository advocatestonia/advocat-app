@Tags(['fast'])
library;

// =============================================================================
// PhaseIndicator widget — Phase 2 Pkg 5
// =============================================================================
// Pinned by docs/architecture/phase2-pkg5-state-machine.md §7.
//
// Contract:
//   * Always renders a PhaseBadge for the current phase.
//   * Renders the localised "entered N <unit> ago" suffix when
//     phaseEnteredAt is non-null and in the past.
//   * Suppresses the "ago" suffix on negative durations (clock skew).
//   * Renders the override popup ONLY when onOverride is non-null.
//   * The popup excludes the current phase from its options.
// =============================================================================

import 'package:advocat/features/case_memory/models/case_phase.dart';
import 'package:advocat/features/case_memory/widgets/phase_badge.dart';
import 'package:advocat/features/case_memory/widgets/phase_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('PhaseIndicator — basic rendering', () {
    testWidgets('CPS-T-IND-01 renders badge for the active phase', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(
        const PhaseIndicator(phase: CasePhase.strategy, locale: 'en'),
      ));

      // The PhaseBadge widget itself should be present.
      expect(find.byType(PhaseBadge), findsOneWidget);
      // And the strategy label should be shown ("Strategy" in en).
      expect(find.text('Strategy'), findsOneWidget);
    });

    testWidgets('CPS-T-IND-02 no entered suffix when phaseEnteredAt is null', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(
        const PhaseIndicator(phase: CasePhase.draft, locale: 'en'),
      ));

      expect(find.byType(PhaseBadge), findsOneWidget);
      // No "ago" / "entered" copy should appear without timestamp.
      expect(find.textContaining('entered'), findsNothing);
      expect(find.textContaining('ago'), findsNothing);
    });

    testWidgets('CPS-T-IND-03 renders entered N days ago in English', (
      tester,
    ) async {
      final entered = DateTime.now().subtract(const Duration(days: 3));
      await tester.pumpWidget(_wrap(
        PhaseIndicator(
          phase: CasePhase.wait,
          phaseEnteredAt: entered,
          locale: 'en',
        ),
      ));

      expect(find.text('entered 3 days ago'), findsOneWidget);
    });

    testWidgets('CPS-T-IND-04 singular "1 day ago" form', (tester) async {
      // Use 25 hours so we land in the days bucket but as 1 day exactly.
      final entered = DateTime.now().subtract(const Duration(hours: 25));
      await tester.pumpWidget(_wrap(
        PhaseIndicator(
          phase: CasePhase.wait,
          phaseEnteredAt: entered,
          locale: 'en',
        ),
      ));
      expect(find.text('entered 1 day ago'), findsOneWidget);
    });

    testWidgets('CPS-T-IND-05 hour bucket for sub-day diffs', (tester) async {
      final entered = DateTime.now().subtract(const Duration(hours: 5));
      await tester.pumpWidget(_wrap(
        PhaseIndicator(
          phase: CasePhase.strategy,
          phaseEnteredAt: entered,
          locale: 'en',
        ),
      ));
      expect(find.textContaining('5 hours'), findsOneWidget);
    });

    testWidgets('CPS-T-IND-06 minute bucket for fresh transitions', (
      tester,
    ) async {
      final entered = DateTime.now().subtract(const Duration(minutes: 7));
      await tester.pumpWidget(_wrap(
        PhaseIndicator(
          phase: CasePhase.strategy,
          phaseEnteredAt: entered,
          locale: 'en',
        ),
      ));
      expect(find.textContaining('7 min'), findsOneWidget);
    });

    testWidgets('CPS-T-IND-07 just-now bucket for <1m transitions', (
      tester,
    ) async {
      final entered = DateTime.now().subtract(const Duration(seconds: 10));
      await tester.pumpWidget(_wrap(
        PhaseIndicator(
          phase: CasePhase.strategy,
          phaseEnteredAt: entered,
          locale: 'en',
        ),
      ));
      expect(find.text('entered just now'), findsOneWidget);
    });

    testWidgets('CPS-T-IND-08 negative diff (clock skew) suppresses suffix', (
      tester,
    ) async {
      // Future timestamp — nonsensical but possible if device clock is
      // behind. The widget must NOT print "entered -3 days ago".
      final entered = DateTime.now().add(const Duration(days: 3));
      await tester.pumpWidget(_wrap(
        PhaseIndicator(
          phase: CasePhase.strategy,
          phaseEnteredAt: entered,
          locale: 'en',
        ),
      ));
      expect(find.textContaining('ago'), findsNothing);
      expect(find.textContaining('-'), findsNothing);
    });
  });

  group('PhaseIndicator — localisation', () {
    testWidgets('CPS-T-IND-09 Estonian entered suffix uses partitive', (
      tester,
    ) async {
      final entered = DateTime.now().subtract(const Duration(days: 4));
      await tester.pumpWidget(_wrap(
        PhaseIndicator(
          phase: CasePhase.wait,
          phaseEnteredAt: entered,
          locale: 'et',
        ),
      ));
      expect(find.text('sisestatud 4 päeva tagasi'), findsOneWidget);
    });

    testWidgets('CPS-T-IND-10 Russian uses correct plural for 2', (
      tester,
    ) async {
      final entered = DateTime.now().subtract(const Duration(days: 2));
      await tester.pumpWidget(_wrap(
        PhaseIndicator(
          phase: CasePhase.draft,
          phaseEnteredAt: entered,
          locale: 'ru',
        ),
      ));
      expect(find.text('на этой стадии 2 дня'), findsOneWidget);
    });

    testWidgets('CPS-T-IND-11 Russian uses correct plural for 5', (
      tester,
    ) async {
      final entered = DateTime.now().subtract(const Duration(days: 5));
      await tester.pumpWidget(_wrap(
        PhaseIndicator(
          phase: CasePhase.draft,
          phaseEnteredAt: entered,
          locale: 'ru',
        ),
      ));
      expect(find.text('на этой стадии 5 дней'), findsOneWidget);
    });

    testWidgets('CPS-T-IND-12 Russian singular for 1', (tester) async {
      final entered = DateTime.now().subtract(const Duration(hours: 25));
      await tester.pumpWidget(_wrap(
        PhaseIndicator(
          phase: CasePhase.strategy,
          phaseEnteredAt: entered,
          locale: 'ru',
        ),
      ));
      expect(find.text('на этой стадии 1 день'), findsOneWidget);
    });

    testWidgets('CPS-T-IND-13 Russian uses correct plural for 21', (
      tester,
    ) async {
      // 21 → singular form: "1 день" rule, since mod10==1 and mod100 != 11.
      final entered = DateTime.now().subtract(const Duration(days: 21));
      await tester.pumpWidget(_wrap(
        PhaseIndicator(
          phase: CasePhase.wait,
          phaseEnteredAt: entered,
          locale: 'ru',
        ),
      ));
      expect(find.text('на этой стадии 21 день'), findsOneWidget);
    });

    testWidgets('CPS-T-IND-14 Russian plural for 11 (should be plural form)', (
      tester,
    ) async {
      // 11 → "много" form: mod100 == 11 always plural.
      final entered = DateTime.now().subtract(const Duration(days: 11));
      await tester.pumpWidget(_wrap(
        PhaseIndicator(
          phase: CasePhase.wait,
          phaseEnteredAt: entered,
          locale: 'ru',
        ),
      ));
      expect(find.text('на этой стадии 11 дней'), findsOneWidget);
    });

    testWidgets('CPS-T-IND-15 Finnish partitive for days', (tester) async {
      final entered = DateTime.now().subtract(const Duration(days: 3));
      await tester.pumpWidget(_wrap(
        PhaseIndicator(
          phase: CasePhase.wait,
          phaseEnteredAt: entered,
          locale: 'fi',
        ),
      ));
      expect(find.text('siirretty 3 päivää sitten'), findsOneWidget);
    });

    testWidgets('CPS-T-IND-16 Unknown locale falls back to English', (
      tester,
    ) async {
      final entered = DateTime.now().subtract(const Duration(days: 3));
      await tester.pumpWidget(_wrap(
        PhaseIndicator(
          phase: CasePhase.wait,
          phaseEnteredAt: entered,
          locale: 'sv',
        ),
      ));
      expect(find.text('entered 3 days ago'), findsOneWidget);
    });
  });

  group('PhaseIndicator — override menu', () {
    testWidgets('CPS-T-IND-17 no menu when onOverride is null', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(
        const PhaseIndicator(phase: CasePhase.strategy, locale: 'en'),
      ));
      expect(find.byIcon(Icons.more_horiz), findsNothing);
    });

    testWidgets('CPS-T-IND-18 menu appears when onOverride is set', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(
        PhaseIndicator(
          phase: CasePhase.strategy,
          locale: 'en',
          onOverride: (_) {},
        ),
      ));
      expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    });

    testWidgets('CPS-T-IND-19 menu opens with all phases except current', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(
        PhaseIndicator(
          phase: CasePhase.strategy,
          locale: 'en',
          onOverride: (_) {},
        ),
      ));

      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();

      // Should show 4 menu items (5 phases minus the current "strategy").
      // Each item label is "Mark as: <phase>" in English.
      expect(find.text('Mark as: Intake'), findsOneWidget);
      expect(find.text('Mark as: Draft'), findsOneWidget);
      expect(find.text('Mark as: Waiting'), findsOneWidget);
      expect(find.text('Mark as: Closed'), findsOneWidget);
      // Current phase must NOT be selectable.
      expect(find.text('Mark as: Strategy'), findsNothing);
    });

    testWidgets('CPS-T-IND-20 onOverride fires with selected phase', (
      tester,
    ) async {
      CasePhase? selected;
      await tester.pumpWidget(_wrap(
        PhaseIndicator(
          phase: CasePhase.strategy,
          locale: 'en',
          onOverride: (p) => selected = p,
        ),
      ));

      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mark as: Draft'));
      await tester.pumpAndSettle();

      expect(selected, CasePhase.draft);
    });
  });
}
