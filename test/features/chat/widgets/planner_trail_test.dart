@Tags(['fast'])
library;

// =============================================================================
// planner_trail_test.dart — Phase 2 Pkg 6 widget contract.
// =============================================================================
//
// Pins what the Reasoning Trail extension must render for a planner trace:
//   1. Sub-questions show as bullet items.
//   2. Counter-arguments + evidence gaps each get their own labelled list
//      when non-empty.
//   3. Critique section title flips between "clean" and "material gap"
//      based on the bool.
//   4. Regenerated-once flag surfaces in the header line.
//   5. fromRpcRow round-trips the planner_trace(uuid) RPC payload.
// =============================================================================

import 'package:advocat/features/chat/widgets/planner_trail.dart';
import 'package:advocat/services/legal_planner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PlannerTraceData _trace({
  bool gap = false,
  bool regen = false,
  List<String> subQs = const ['Was the dismissal valid?'],
  List<String> counterArgs = const [],
  List<String> evidenceGaps = const [],
  List<String> issues = const [],
  int latencyMs = 4500,
}) {
  return PlannerTraceData(
    subQuestions: subQs,
    counterArgs: counterArgs,
    evidenceGaps: evidenceGaps,
    materialGap: gap,
    critiqueIssues: issues,
    regeneratedOnce: regen,
    summary: PlannerSummary(
      regeneratedOnce: regen,
      latencyMs: latencyMs,
      costCents: 8,
    ),
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('renders sub-questions as bullets', (tester) async {
    await tester.pumpWidget(_wrap(PlannerTrail(
      data: _trace(subQs: const ['Q1', 'Q2']),
    )));
    await tester.pumpAndSettle();
    expect(find.textContaining('Q1'), findsOneWidget);
    expect(find.textContaining('Q2'), findsOneWidget);
  });

  testWidgets('header reflects regen-once flag', (tester) async {
    await tester.pumpWidget(_wrap(PlannerTrail(data: _trace(regen: true))));
    await tester.pumpAndSettle();
    expect(find.textContaining('regen'), findsOneWidget);
  });

  testWidgets('critique section title flips with material_gap', (tester) async {
    await tester.pumpWidget(_wrap(PlannerTrail(
      data: _trace(gap: true, issues: const ['§97 unanswered']),
    )));
    await tester.pumpAndSettle();
    expect(find.textContaining('material gap'), findsOneWidget);

    await tester.pumpWidget(_wrap(PlannerTrail(data: _trace(gap: false))));
    await tester.pumpAndSettle();
    expect(find.textContaining('clean'), findsOneWidget);
  });

  testWidgets('renders counter-args and evidence gaps when non-empty',
      (tester) async {
    await tester.pumpWidget(_wrap(PlannerTrail(
      data: _trace(
        counterArgs: const ['Employer claims gross misconduct'],
        evidenceGaps: const ['Termination letter date'],
      ),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Counter-arguments'), findsOneWidget);
    expect(find.text('Evidence gaps'), findsOneWidget);
    expect(find.textContaining('gross misconduct'), findsOneWidget);
    expect(find.textContaining('Termination letter date'), findsOneWidget);
  });

  testWidgets('renders «no items» placeholder when sub-questions empty',
      (tester) async {
    await tester.pumpWidget(_wrap(PlannerTrail(data: _trace(subQs: const []))));
    await tester.pumpAndSettle();
    expect(find.textContaining('no items'), findsAtLeastNWidgets(1));
  });

  testWidgets('tap on Plan section header collapses and re-expands content',
      (tester) async {
    // Sections start expanded by default — sub-question text is visible.
    await tester.pumpWidget(_wrap(PlannerTrail(
      data: _trace(subQs: const ['UNIQUE_PLAN_QUESTION_X42']),
    )));
    await tester.pumpAndSettle();
    expect(find.textContaining('UNIQUE_PLAN_QUESTION_X42'), findsOneWidget);

    // Tap the Plan section title to collapse.
    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('UNIQUE_PLAN_QUESTION_X42'), findsNothing);

    // Tap again to re-expand.
    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('UNIQUE_PLAN_QUESTION_X42'), findsOneWidget);
  });

  // ───────────────────────────────────────────────────────────────────
  // Planner UX gap-fix (2026-05-06, audit d54268c).
  //
  // Pin the Semantics wrapping required for screen-reader a11y.
  // Section headers must announce as both `header` and `button`, with
  // an explicit `toggled` state. Expand-icon is hidden from semantics
  // (decorative — text label is what matters for assistive tech).
  // ───────────────────────────────────────────────────────────────────
  testWidgets('section headers expose Semantics(header: true) for a11y',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_wrap(PlannerTrail(data: _trace())));
    await tester.pumpAndSettle();

    // Plan + Critique rows must each be tagged as a Semantics header
    // so screen readers announce them as section landmarks. We find
    // the explicit Semantics widget (not the Text descendant) by its
    // matching label and check its properties via the semantics tree.
    final planSemanticsFinder = find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.label == 'Plan',
    );
    expect(planSemanticsFinder, findsOneWidget);

    final node = tester.getSemantics(planSemanticsFinder);
    expect(
      node.flagsCollection.isHeader,
      isTrue,
      reason: 'Plan section row must be a Semantics header.',
    );
    expect(
      node.flagsCollection.isButton,
      isTrue,
      reason: 'Plan section row must be a Semantics button (tappable toggle).',
    );
    handle.dispose();
  });

  group('PlannerTraceData.fromRpcRow', () {
    test('unwraps a planner_trace RPC row', () {
      final data = PlannerTraceData.fromRpcRow({
        'plan': {
          'sub_questions': ['Q1', 'Q2'],
          'counter_args': ['CA1'],
          'evidence_gaps': ['EG1'],
        },
        'critique': {
          'material_gap': true,
          'issues': ['I1'],
        },
        'regenerated_once': true,
        'latency_ms': 6000,
        'cost_cents': 9,
      });
      expect(data.subQuestions, ['Q1', 'Q2']);
      expect(data.counterArgs, ['CA1']);
      expect(data.evidenceGaps, ['EG1']);
      expect(data.materialGap, isTrue);
      expect(data.critiqueIssues, ['I1']);
      expect(data.regeneratedOnce, isTrue);
      expect(data.summary.latencyMs, 6000);
    });

    test('safe defaults when RPC row sparse', () {
      final data = PlannerTraceData.fromRpcRow({});
      expect(data.subQuestions, isEmpty);
      expect(data.materialGap, isFalse);
      expect(data.regeneratedOnce, isFalse);
    });
  });
}
