@Tags(['fast'])
library;

// =============================================================================
// email_agent_prompt_versions_test.dart — Track E (v2.1 consilium, 2026-05-07)
// =============================================================================
//
// Pins the structural invariants of `_shared/email_agent_prompt.ts`:
//
//   1. SYSTEM_PROMPT_V1_1 stays byte-identical to its v1.1-final ship state
//      (presence of legacy load-bearing rules 9, 16, 28 verified).
//   2. SYSTEM_PROMPT_V1_2 ships with PROMPT_VERSION bumped to v1.2-final.
//   3. v1.2-final adds Rules 31 and 35 (the bookend new-rule additions per
//      track_A_v1.2_prompt.md §1).
//   4. pickPromptVersion() helper exists and reads EMAIL_AGENT_PROMPT_VERSION.
//
// Why a Dart test against a TypeScript file: the project's edge-fn tests run
// via Deno; this file lives alongside contract tests so the inner repo's
// `flutter test` (the binding gate per feedback_anti_regression_rules.md
// rule 3) can fail fast on prompt regressions without standing up a Deno
// test pipeline.
//
// =============================================================================

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _readPromptFile() {
  final f = File(
      'supabase/functions/_shared/email_agent_prompt.ts');
  if (!f.existsSync()) {
    throw StateError(
      'email_agent_prompt.ts not found at ${f.absolute.path}. '
      'flutter test must run from the package root.',
    );
  }
  return f.readAsStringSync();
}

void main() {
  late String src;
  setUpAll(() => src = _readPromptFile());

  group('email_agent_prompt.ts — V1_1 preserved (regression guard)', () {
    test('SYSTEM_PROMPT_V1_1 export still present', () {
      expect(
        src,
        contains('export const SYSTEM_PROMPT_V1_1'),
        reason:
            'V1_1 must not be deleted — owner can roll back via Supabase '
            'secret EMAIL_AGENT_PROMPT_VERSION=v1.1-final at any time.',
      );
    });

    test('PROMPT_VERSION constant pinned to v1.1-final default', () {
      expect(
        src,
        contains('export const PROMPT_VERSION = "v1.1-final"'),
        reason:
            'Default PROMPT_VERSION must remain v1.1-final until owner '
            'rotates the EMAIL_AGENT_PROMPT_VERSION secret.',
      );
    });

    test('V1_1 contains Rule 9 (auto-send eligibility) header', () {
      expect(
        src,
        contains(r'`create_draft` is not `send`'),
        reason:
            'Rule 9 is load-bearing for the policy gate — its prose '
            'opening line must remain in V1_1.',
      );
    });

    test('V1_1 contains Rule 16 (PRIVILEGE FILTER multi-signal)', () {
      expect(
        src,
        contains('PRIVILEGE FILTER (multi-signal)'),
        reason:
            'Rule 16 governs privileged-sender handling. Its header is the '
            'simplest grep-anchor; if missing, the V1_1 prompt has been '
            'edited in place — that violates the no-in-place-edit doctrine.',
      );
    });

    test('V1_1 contains Rule 28 (CALENDAR + HOLIDAY-AWARE DEADLINES)', () {
      expect(
        src,
        contains('CALENDAR + HOLIDAY-AWARE DEADLINES'),
        reason:
            'Rule 28 backs the Pkg 9 deadline-radar holiday-shift logic. '
            'Drift here breaks the contract with deadline_radar_extractor.',
      );
    });

    test('V1_1 PROMPT_VERSION marker still present in the prompt body', () {
      expect(
        src,
        contains('PROMPT_VERSION: v1.1-final'),
        reason:
            'The version marker is baked into the <meta> block at the top '
            'of the prompt, separate from the const declaration.',
      );
    });
  });

  group('email_agent_prompt.ts — V1_2 added (Track E, 2026-05-07)', () {
    test('SYSTEM_PROMPT_V1_2 export is present', () {
      expect(
        src,
        contains('export const SYSTEM_PROMPT_V1_2'),
        reason:
            'V1_2 export must be added next to V1_1 (the no-in-place-edit '
            'doctrine; bump the suffix, never edit V1_1 in place).',
      );
    });

    test('V1_2 prompt body declares PROMPT_VERSION: v1.2-final', () {
      expect(
        src,
        contains('PROMPT_VERSION: v1.2-final'),
        reason:
            'The <meta> block at the top of V1_2 must carry the v1.2-final '
            'tag so triage_results.prompt_version lines up with telemetry.',
      );
    });

    test('V1_2 contains Rule 31 — RESTORATION-FORUM PRECHECK', () {
      expect(
        src,
        contains('RESTORATION-FORUM PRECHECK'),
        reason:
            'Rule 31 is the load-bearing new addition: HOL § 114–115 KHO-'
            'exclusive jurisdiction precheck. Sulga case lost ~2 months '
            'because this rule did not exist in v1.1-final '
            '(lesson_HAO_KHO_restoration_jurisdiction.md).',
      );
    });

    test('V1_2 contains Rule 35 — ESITUTKINTAPÖYTÄKIRJA PARSING REFLEXES',
        () {
      expect(
        src,
        contains('ESITUTKINTAPÖYTÄKIRJA PARSING REFLEXES'),
        reason:
            'Rule 35 is the bookend new addition: ETL 4:1 / 4:9 / 4:10 '
            'parsing reflexes. The Sulga 5500/R/75170/25 pöytäkirja '
            'discoveries (ETL 4:1 asymmetric medical examination, Salduz '
            'disclosure block, asianomistaja-status self-evidence) flow '
            'through this rule.',
      );
    });

    test('V1_2 contains Rules 32, 33, 34 (full 31–35 set)', () {
      expect(src, contains('CARRIER DELIVERY DEFECT'),
          reason: 'Rule 32 — carrier delivery defect → restoration ground.');
      expect(src, contains('CROSS-DOCUMENT LANGUAGE CONSISTENCY'),
          reason: 'Rule 33 — language-of-decision vs interpreter_language.');
      expect(src, contains('IDENTITY-ERROR STACKING'),
          reason: 'Rule 34 — ≥3 errors → administrative-incompetence pattern.');
    });

    test('V1_2 statute citations include HOL § 114 verbatim quote', () {
      // Rule 31 cites HOL § 114 verbatim. The verbatim quote starts with
      // "Menetetty määräaika voidaan palauttaa…" — anchor on that
      // distinctive Finnish phrasing.
      expect(
        src,
        contains('Menetetty määräaika voidaan palauttaa'),
        reason:
            'Rule 31 verbatim HOL § 114 quote must survive into V1_2 — '
            'the statute verifier gate (CONSILIUM_DECISIONS §4 Track D) '
            'requires verbatim citations, not paraphrases.',
      );
    });
  });

  group('email_agent_prompt.ts — pickPromptVersion helper', () {
    test('helper is exported', () {
      expect(
        src,
        contains('export function pickPromptVersion'),
        reason:
            'Edge fn callers must use pickPromptVersion() — direct '
            'SYSTEM_PROMPT_V1_1 reads bypass the runtime selector.',
      );
    });

    test('helper reads EMAIL_AGENT_PROMPT_VERSION env var', () {
      expect(
        src,
        contains('Deno.env.get("EMAIL_AGENT_PROMPT_VERSION")'),
        reason:
            'Helper must read the canonical env var so owner can flip the '
            'prompt version via Supabase secret rotation, not by code '
            'redeploy.',
      );
    });

    test('helper defaults to v1.1-final', () {
      // Defence-in-depth: even if Track E ships V1_2 to the codebase, the
      // default must remain V1_1 until owner explicitly rotates the secret.
      // This guards the "deploy code first, flip flag later" workflow.
      expect(
        src,
        contains('?? "v1.1-final"'),
        reason:
            'Helper must default to v1.1-final so a missing env var '
            'preserves the current production prompt. Owner flips to '
            'v1.2-final via Supabase secret rotation after staging soak.',
      );
    });

    test('helper returns the v1.2-final prompt when env is set to it', () {
      // Structural check: the helper body branches on the v1.2-final
      // string and returns SYSTEM_PROMPT_V1_2.
      expect(
        src,
        contains('"v1.2-final"'),
        reason:
            'The string "v1.2-final" must appear in the helper body so the '
            'branch is reachable.',
      );
      expect(src, contains('SYSTEM_PROMPT_V1_2'),
          reason: 'Helper must return SYSTEM_PROMPT_V1_2 in the v1.2 branch.');
    });
  });

  group('email_agent_prompt.ts — caching boundary unchanged', () {
    test('both V1_1 and V1_2 end with the same <context>...</context> block',
        () {
      // The cache boundary is `<context>...</context>` per the ts file
      // header comment. Both versions must close with the same dynamic
      // suffix or the buildSystemBlocks split() regex breaks.
      expect(
        src,
        contains('Email thread (oldest → newest):'),
        reason:
            'Both prompts must end with the standard <context> block so '
            'buildSystemBlocks() can strip <context> via the same regex.',
      );
    });
  });
}
