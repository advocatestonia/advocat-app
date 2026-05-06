@Tags(['fast'])
library;

// =============================================================================
// SystemPrompts phase context — Phase 2 Pkg 5
// =============================================================================
// Pinned by docs/architecture/phase2-pkg5-state-machine.md §6.
//
// Contract:
//   * `buildChatPrompt(casePhase: ...)` injects a `# CASE PHASE — <NAME>`
//     block AFTER the memory block, BEFORE the legal KB.
//   * `casePhase: null` (default) leaves the prompt unchanged — backwards
//     compatible with all existing call-sites.
//   * `injectPhaseContext(existingPrompt, phase, enteredAt)` is the
//     standalone helper claude-proxy uses to fold phase into a prompt
//     it didn't build itself. Idempotent on re-injection.
// =============================================================================

import 'package:advocat/features/case_memory/models/case_phase.dart';
import 'package:advocat/services/system_prompts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SystemPrompts.buildChatPrompt — casePhase parameter', () {
    test('CPS-T05 — strategy phase: block sits between memory and KB', () {
      const memoryBlock = '=== WHAT WE KNOW ABOUT YOU ===\n'
          '- [Tone] Short replies preferred.\n';

      final prompt = SystemPrompts.buildChatPrompt(
        userLanguage: 'en',
        memoryBlock: memoryBlock,
        casePhase: CasePhase.strategy,
      );

      final memIdx = prompt.indexOf('WHAT WE KNOW ABOUT YOU');
      final phaseIdx = prompt.indexOf('# CASE PHASE — STRATEGY');
      final kbIdx = prompt.indexOf('# LEGAL KNOWLEDGE BASE');

      expect(memIdx, greaterThanOrEqualTo(0),
          reason: 'memory block must be present');
      expect(phaseIdx, greaterThanOrEqualTo(0),
          reason: 'phase block must be present for casePhase != null');
      expect(kbIdx, greaterThanOrEqualTo(0),
          reason: 'legal KB header must be present');

      expect(memIdx, lessThan(phaseIdx),
          reason: 'memory block must precede phase block');
      expect(phaseIdx, lessThan(kbIdx),
          reason: 'phase block must precede legal KB');
    });

    test('CPS-T05b — block contains phase-specific guidance', () {
      final intake = SystemPrompts.buildChatPrompt(
        userLanguage: 'en',
        casePhase: CasePhase.intake,
      );
      expect(intake, contains('# CASE PHASE — INTAKE'));
      expect(intake.toLowerCase(), contains('gather'));

      final strategy = SystemPrompts.buildChatPrompt(
        userLanguage: 'en',
        casePhase: CasePhase.strategy,
      );
      expect(strategy, contains('# CASE PHASE — STRATEGY'));
      expect(strategy.toLowerCase(), contains('forum'));

      final draft = SystemPrompts.buildChatPrompt(
        userLanguage: 'en',
        casePhase: CasePhase.draft,
      );
      expect(draft, contains('# CASE PHASE — DRAFT'));
      expect(draft.toLowerCase(), contains('draft'));

      final wait = SystemPrompts.buildChatPrompt(
        userLanguage: 'en',
        casePhase: CasePhase.wait,
      );
      expect(wait, contains('# CASE PHASE — WAIT'));
      expect(wait.toLowerCase(), contains('await'));

      final closed = SystemPrompts.buildChatPrompt(
        userLanguage: 'en',
        casePhase: CasePhase.closed,
      );
      expect(closed, contains('# CASE PHASE — CLOSED'));
      expect(closed.toLowerCase(), contains('archived'));
    });

    test('CPS-T06 — null casePhase: no phase block (backwards compat)', () {
      final prompt = SystemPrompts.buildChatPrompt(userLanguage: 'en');
      expect(prompt, isNot(contains('# CASE PHASE')));
      expect(prompt, isNot(contains('CASE PHASE — ')));
      // Existing call-sites still produce a non-empty prompt.
      expect(prompt.isNotEmpty, isTrue);
    });

    test('CPS-T06b — null casePhase + memoryBlock: existing layout preserved',
        () {
      const memoryBlock = '=== WHAT WE KNOW ABOUT YOU ===\n- [Tone] short.\n';
      final prompt = SystemPrompts.buildChatPrompt(
        userLanguage: 'en',
        memoryBlock: memoryBlock,
      );
      // Memory still precedes KB; no phase block in between.
      final memIdx = prompt.indexOf('WHAT WE KNOW ABOUT YOU');
      final kbIdx = prompt.indexOf('# LEGAL KNOWLEDGE BASE');
      expect(memIdx, greaterThanOrEqualTo(0));
      expect(kbIdx, greaterThanOrEqualTo(0));
      expect(memIdx, lessThan(kbIdx));
      expect(prompt, isNot(contains('# CASE PHASE')));
    });
  });

  group('SystemPrompts.injectPhaseContext — standalone helper', () {
    test('CPS-T07 — empty phase => prompt unchanged', () {
      const base = 'EXISTING PROMPT BODY';
      // Null phase = no-op.
      final out = SystemPrompts.injectPhaseContext(base, null);
      expect(out, equals(base));
    });

    test('CPS-T07b — non-null phase: prepends one phase block', () {
      const base = '# RULES\n1. do thing\n';
      final enteredAt = DateTime.utc(2026, 5, 6, 12);
      final out = SystemPrompts.injectPhaseContext(
        base,
        CasePhase.strategy,
        phaseEnteredAt: enteredAt,
      );
      expect(out, contains('# CASE PHASE — STRATEGY'));
      expect(out, endsWith(base));
      // Single phase header — not duplicated.
      final occurrences = '# CASE PHASE'.allMatches(out).length;
      expect(occurrences, equals(1));
    });

    test('CPS-T07c — idempotent: re-injection does not duplicate block', () {
      const base = '# RULES\n';
      final once = SystemPrompts.injectPhaseContext(base, CasePhase.draft);
      final twice =
          SystemPrompts.injectPhaseContext(once, CasePhase.draft);
      // Re-injection with same phase is a no-op.
      expect(twice, equals(once));
      final headerCount = '# CASE PHASE'.allMatches(twice).length;
      expect(headerCount, equals(1));
    });

    test('CPS-T07d — re-injection with different phase swaps the block', () {
      const base = '# RULES\n';
      final draft = SystemPrompts.injectPhaseContext(base, CasePhase.draft);
      final waited =
          SystemPrompts.injectPhaseContext(draft, CasePhase.wait);
      // Old block gone, new block in.
      expect(waited, contains('# CASE PHASE — WAIT'));
      expect(waited, isNot(contains('# CASE PHASE — DRAFT')));
      final headerCount = '# CASE PHASE'.allMatches(waited).length;
      expect(headerCount, equals(1));
    });
  });
}
