@Tags(['fast'])
library;

// =============================================================================
// CaseResumeBanner widget — Phase 2 Pkg 5 (§7.2)
// =============================================================================
// Renders a top banner when the user opens a case chat after a gap and the
// case is in a non-trivial phase (strategy / draft / wait). Pinned tests
// cover:
//   * Banner shown for strategy/draft/wait when gap >24h.
//   * Banner hidden for intake / closed regardless of gap.
//   * Banner hidden when gap <= 24h (no need to remind).
//   * Dismiss callback fires on close button tap.
// =============================================================================

import 'package:advocat/features/case_memory/models/case_phase.dart';
import 'package:advocat/features/case_memory/widgets/case_resume_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  group('CaseResumeBanner', () {
    testWidgets('shows banner for strategy phase when gap > 24h',
        (tester) async {
      await _pump(
        tester,
        CaseResumeBanner(
          phase: CasePhase.strategy,
          phaseEnteredAt: DateTime.now().subtract(const Duration(days: 5)),
          lastSessionEndedAt:
              DateTime.now().subtract(const Duration(days: 5)),
          locale: 'en',
          onDismiss: () {},
        ),
      );
      expect(find.byType(CaseResumeBanner), findsOneWidget);
      // Some textual cue is rendered (we don't pin the exact copy).
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });

    testWidgets('hides banner for intake phase even with long gap',
        (tester) async {
      await _pump(
        tester,
        CaseResumeBanner(
          phase: CasePhase.intake,
          phaseEnteredAt: DateTime.now().subtract(const Duration(days: 10)),
          lastSessionEndedAt:
              DateTime.now().subtract(const Duration(days: 10)),
          locale: 'en',
          onDismiss: () {},
        ),
      );
      // Renders nothing visible (SizedBox.shrink under the hood) — assert
      // by absence of any phase-cue icon.
      expect(find.byIcon(Icons.lightbulb_outline), findsNothing);
      expect(find.byIcon(Icons.edit_note), findsNothing);
      expect(find.byIcon(Icons.hourglass_empty), findsNothing);
    });

    testWidgets('hides banner for closed phase', (tester) async {
      await _pump(
        tester,
        CaseResumeBanner(
          phase: CasePhase.closed,
          phaseEnteredAt: DateTime.now().subtract(const Duration(days: 5)),
          lastSessionEndedAt:
              DateTime.now().subtract(const Duration(days: 5)),
          locale: 'en',
          onDismiss: () {},
        ),
      );
      expect(find.byIcon(Icons.archive_outlined), findsNothing);
    });

    testWidgets('hides banner when gap is <= 24h', (tester) async {
      await _pump(
        tester,
        CaseResumeBanner(
          phase: CasePhase.strategy,
          phaseEnteredAt: DateTime.now().subtract(const Duration(hours: 5)),
          lastSessionEndedAt:
              DateTime.now().subtract(const Duration(hours: 5)),
          locale: 'en',
          onDismiss: () {},
        ),
      );
      // Within the same session window — no resume banner.
      expect(find.byIcon(Icons.lightbulb_outline), findsNothing);
    });

    testWidgets('hides banner when lastSessionEndedAt is null', (tester) async {
      // Brand new case, never resumed.
      await _pump(
        tester,
        CaseResumeBanner(
          phase: CasePhase.strategy,
          phaseEnteredAt: DateTime.now().subtract(const Duration(days: 5)),
          lastSessionEndedAt: null,
          locale: 'en',
          onDismiss: () {},
        ),
      );
      expect(find.byIcon(Icons.lightbulb_outline), findsNothing);
    });

    testWidgets('dismiss button fires onDismiss callback', (tester) async {
      var dismissCount = 0;
      await _pump(
        tester,
        CaseResumeBanner(
          phase: CasePhase.draft,
          phaseEnteredAt: DateTime.now().subtract(const Duration(days: 3)),
          lastSessionEndedAt:
              DateTime.now().subtract(const Duration(days: 3)),
          locale: 'en',
          onDismiss: () => dismissCount++,
        ),
      );
      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(dismissCount, 1);
    });
  });
}
