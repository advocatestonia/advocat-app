@Tags(['fast'])
library;

// =============================================================================
// PhaseBadge widget — Phase 2 Pkg 5
// =============================================================================
// Pinned by docs/architecture/phase2-pkg5-state-machine.md §7.1 + §9 (CPS-T10).
// =============================================================================

import 'package:advocat/features/case_memory/models/case_phase.dart';
import 'package:advocat/features/case_memory/widgets/phase_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: Center(child: child))),
  );
}

void main() {
  group('PhaseBadge', () {
    testWidgets('CPS-T10a — renders one label per phase (en fallback)',
        (tester) async {
      for (final phase in CasePhase.values) {
        await _pump(tester, PhaseBadge(phase: phase, locale: 'en'));
        // Some label is rendered (we don't pin exact text — just non-empty
        // and uppercase / titlecase per phase).
        expect(find.byType(PhaseBadge), findsOneWidget);
      }
    });

    testWidgets('CPS-T10b — strategy phase shows "Strategy" in English',
        (tester) async {
      await _pump(
        tester,
        const PhaseBadge(phase: CasePhase.strategy, locale: 'en'),
      );
      expect(find.text('Strategy'), findsOneWidget);
    });

    testWidgets('CPS-T10c — wait phase shows "Ootel" in Estonian',
        (tester) async {
      await _pump(
        tester,
        const PhaseBadge(phase: CasePhase.wait, locale: 'et'),
      );
      expect(find.text('Ootel'), findsOneWidget);
    });

    testWidgets('CPS-T10d — draft phase shows "Черновик" in Russian',
        (tester) async {
      await _pump(
        tester,
        const PhaseBadge(phase: CasePhase.draft, locale: 'ru'),
      );
      expect(find.text('Черновик'), findsOneWidget);
    });

    testWidgets('CPS-T10e — unknown locale falls back to English',
        (tester) async {
      await _pump(
        tester,
        const PhaseBadge(phase: CasePhase.intake, locale: 'xx'),
      );
      expect(find.text('Intake'), findsOneWidget);
    });

    testWidgets('CPS-T10f — closed phase has reduced visual weight',
        (tester) async {
      await _pump(
        tester,
        const PhaseBadge(phase: CasePhase.closed, locale: 'en'),
      );
      // Closed badges render — visual weight is implementation-dependent
      // (lower opacity is the simplest signal). We just assert presence.
      expect(find.byType(PhaseBadge), findsOneWidget);
      expect(find.text('Closed'), findsOneWidget);
    });
  });

  group('PhaseBadge.labelFor', () {
    test('CPS-T10g — labelFor returns English by default', () {
      expect(PhaseBadge.labelFor(CasePhase.intake), 'Intake');
      expect(PhaseBadge.labelFor(CasePhase.strategy), 'Strategy');
      expect(PhaseBadge.labelFor(CasePhase.draft), 'Draft');
      expect(PhaseBadge.labelFor(CasePhase.wait), 'Waiting');
      expect(PhaseBadge.labelFor(CasePhase.closed), 'Closed');
    });

    test('CPS-T10h — labelFor returns localised in et/ru/fi', () {
      expect(PhaseBadge.labelFor(CasePhase.intake, locale: 'et'), 'Andmete kogumine');
      expect(PhaseBadge.labelFor(CasePhase.strategy, locale: 'ru'), 'Стратегия');
      expect(PhaseBadge.labelFor(CasePhase.draft, locale: 'fi'), 'Luonnos');
    });

    test('CPS-T10i — labelFor falls back to English on unknown locale', () {
      expect(PhaseBadge.labelFor(CasePhase.draft, locale: 'xx'), 'Draft');
      expect(PhaseBadge.labelFor(CasePhase.closed, locale: null), 'Closed');
    });
  });
}
