// Deno tests for Pkg 1.C — Case Memory background auto-patch.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/case-auto-patch/__tests__/case_auto_patch_test.ts
//
// Spec: memory: project_handoff_smart_lawyer.md "Авто-обновление дела".
//   * Pure-function tests for `case_patch_prompt.ts` (parser + merger).
//   * Source-contract tests for `case-auto-patch/index.ts` (imports,
//     identity marker, RPC name, JWT gating).
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
  assertStrictEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  CASE_PATCH_HAIKU_MODEL,
  CASE_PATCH_HAIKU_TIMEOUT_MS,
  CASE_PATCH_IDENTITY_MARKER,
  CASE_PATCH_SYSTEM_PROMPT,
  emptyPatch,
  isEmptyPatch,
  mergePatchIntoSnapshot,
  parseCasePatch,
} from "../../_shared/case_patch_prompt.ts";
import { ADVOCAT_IDENTITY_MARKERS } from "../../claude-proxy/system_prompt_guard.ts";

// =============================================================================
// 1. Identity marker
// =============================================================================

Deno.test("CAP-T01 — identity marker is whitelisted by system_prompt_guard", () => {
  assert(
    ADVOCAT_IDENTITY_MARKERS.includes(CASE_PATCH_IDENTITY_MARKER),
    `CASE_PATCH_IDENTITY_MARKER (${CASE_PATCH_IDENTITY_MARKER}) is not in ` +
      `ADVOCAT_IDENTITY_MARKERS — system_prompt_guard would 400 the Haiku call`,
  );
});

Deno.test("CAP-T02 — system prompt starts with the identity marker", () => {
  assert(
    CASE_PATCH_SYSTEM_PROMPT.startsWith(CASE_PATCH_IDENTITY_MARKER),
    "System prompt must lead with the identity marker so guard accepts it",
  );
});

Deno.test("CAP-T03 — system prompt contains every required JSON field", () => {
  const required = [
    "case_numbers_add",
    "parties_add",
    "authorities_add",
    "key_dates_add",
    "timeline_add",
    "open_questions_replace",
    "next_actions_replace",
    "summary_replace",
  ];
  for (const k of required) {
    assertStringIncludes(CASE_PATCH_SYSTEM_PROMPT, k);
  }
});

Deno.test("CAP-T04 — Haiku config: model + timeout pinned", () => {
  assertEquals(CASE_PATCH_HAIKU_MODEL, "claude-haiku-4-5-20251001");
  assertEquals(CASE_PATCH_HAIKU_TIMEOUT_MS, 5_000);
});

// =============================================================================
// 2. parseCasePatch — defensive JSON parsing
// =============================================================================

Deno.test("CAP-T10 — parses a happy-path patch", () => {
  const raw = JSON.stringify({
    case_numbers_add: [{ authority: "PPA", number: "5500/R/75170/25" }],
    parties_add: [],
    authorities_add: [{ name: "Helsingin hallinto-oikeus", type: "court" }],
    key_dates_add: [],
    timeline_add: [{ date: "2026-04-12", event: "PPA decision" }],
    open_questions_replace: ["Confirm calendar vs business days"],
    next_actions_replace: ["File appeal by 2026-05-12"],
    summary_replace: "FI deportation appeal in progress",
  });
  const p = parseCasePatch(raw);
  assert(p !== null, "should parse");
  assertEquals(p!.case_numbers_add.length, 1);
  assertEquals(p!.timeline_add.length, 1);
  assertEquals(p!.open_questions_replace, [
    "Confirm calendar vs business days",
  ]);
  assertEquals(p!.summary_replace, "FI deportation appeal in progress");
});

Deno.test("CAP-T11 — invalid JSON returns null", () => {
  assertEquals(parseCasePatch("definitely-not-json"), null);
  assertEquals(parseCasePatch(""), null);
  assertEquals(parseCasePatch("{ unterminated"), null);
});

Deno.test("CAP-T12 — top-level array returns null", () => {
  assertEquals(parseCasePatch("[]"), null);
});

Deno.test("CAP-T13 — non-string raw returns null", () => {
  assertEquals(parseCasePatch(null), null);
  assertEquals(parseCasePatch(undefined), null);
  assertEquals(parseCasePatch(123), null);
  assertEquals(parseCasePatch({}), null);
});

Deno.test("CAP-T14 — strips ```json fence Haiku occasionally adds", () => {
  const raw = "```json\n" + JSON.stringify({
    case_numbers_add: [{ number: "X" }],
    parties_add: [],
    authorities_add: [],
    key_dates_add: [],
    timeline_add: [],
    open_questions_replace: null,
    next_actions_replace: null,
    summary_replace: null,
  }) + "\n```";
  const p = parseCasePatch(raw);
  assert(p !== null);
  assertEquals(p!.case_numbers_add.length, 1);
});

Deno.test("CAP-T15 — non-array array fields default to empty", () => {
  const p = parseCasePatch(
    JSON.stringify({
      case_numbers_add: "oops, a string",
      parties_add: 42,
      authorities_add: null,
      key_dates_add: undefined,
      timeline_add: { not: "array" },
      open_questions_replace: null,
      next_actions_replace: null,
      summary_replace: null,
    }),
  );
  assert(p !== null);
  assertEquals(p!.case_numbers_add, []);
  assertEquals(p!.parties_add, []);
  assertEquals(p!.authorities_add, []);
  assertEquals(p!.key_dates_add, []);
  assertEquals(p!.timeline_add, []);
});

Deno.test("CAP-T16 — empty patch detection", () => {
  const p = emptyPatch();
  assert(isEmptyPatch(p));

  p.case_numbers_add.push({ number: "X" });
  assertFalse(isEmptyPatch(p));

  const p2 = emptyPatch();
  p2.summary_replace = "new summary";
  assertFalse(isEmptyPatch(p2));
});

Deno.test("CAP-T17 — open_questions_replace=null vs []", () => {
  const pNull = parseCasePatch(JSON.stringify({
    ...emptyPatch(),
    open_questions_replace: null,
  }));
  assertEquals(pNull!.open_questions_replace, null);

  const pEmpty = parseCasePatch(JSON.stringify({
    ...emptyPatch(),
    open_questions_replace: [],
  }));
  assertEquals(pEmpty!.open_questions_replace, []);
});

// =============================================================================
// 3. mergePatchIntoSnapshot — append-only dedupe + replace semantics
// =============================================================================

Deno.test("CAP-T20 — append case_numbers, dedupe by number", () => {
  const snap = {
    case_numbers: [{ number: "X", authority: "PPA" }],
    parties: [],
    authorities: [],
    key_dates: [],
    timeline: [],
    open_questions: [],
    next_actions: [],
    summary: null,
  };
  const patch = emptyPatch();
  patch.case_numbers_add = [
    { number: "X", authority: "PPA" }, // dup
    { number: "Y", authority: "Migri" },
  ];
  const r = mergePatchIntoSnapshot(snap, patch);
  assertEquals(r.fields_changed, ["case_numbers"]);
  assertEquals((r.update.case_numbers as unknown[]).length, 2);
});

Deno.test("CAP-T21 — append parties, dedupe by name (case-insensitive)", () => {
  const snap = {
    case_numbers: [],
    parties: [{ name: "PPA", role: "authority" }],
    authorities: [],
    key_dates: [],
    timeline: [],
    open_questions: [],
    next_actions: [],
    summary: null,
  };
  const patch = emptyPatch();
  patch.parties_add = [
    { name: "ppa", role: "authority" }, // dup (case-insensitive)
    { name: "Bolt OÜ", role: "company" },
  ];
  const r = mergePatchIntoSnapshot(snap, patch);
  assertEquals(r.fields_changed, ["parties"]);
  assertEquals((r.update.parties as unknown[]).length, 2);
});

Deno.test("CAP-T22 — timeline dedupe by (date,event) composite", () => {
  const snap = {
    case_numbers: [],
    parties: [],
    authorities: [],
    key_dates: [],
    timeline: [{ date: "2026-04-12", event: "PPA decision" }],
    open_questions: [],
    next_actions: [],
    summary: null,
  };
  const patch = emptyPatch();
  patch.timeline_add = [
    { date: "2026-04-12", event: "PPA Decision" }, // dup, different case
    { date: "2026-04-13", event: "Hearing scheduled" },
  ];
  const r = mergePatchIntoSnapshot(snap, patch);
  assertEquals(r.fields_changed, ["timeline"]);
  assertEquals((r.update.timeline as unknown[]).length, 2);
});

Deno.test("CAP-T23 — empty add arrays produce no field change", () => {
  const snap = {
    case_numbers: [{ number: "X" }],
    parties: [],
    authorities: [],
    key_dates: [],
    timeline: [],
    open_questions: [],
    next_actions: [],
    summary: null,
  };
  const r = mergePatchIntoSnapshot(snap, emptyPatch());
  assertEquals(r.fields_changed, []);
  assertEquals(r.update, {});
});

Deno.test("CAP-T24 — open_questions_replace replaces, null retains", () => {
  const snap = {
    case_numbers: [],
    parties: [],
    authorities: [],
    key_dates: [],
    timeline: [],
    open_questions: ["old q1", "old q2"],
    next_actions: [],
    summary: null,
  };
  // null → no change
  const r1 = mergePatchIntoSnapshot(snap, {
    ...emptyPatch(),
    open_questions_replace: null,
  });
  assertEquals(r1.fields_changed, []);

  // ["new"] → replace
  const r2 = mergePatchIntoSnapshot(snap, {
    ...emptyPatch(),
    open_questions_replace: ["new only"],
  });
  assertEquals(r2.fields_changed, ["open_questions"]);
  assertEquals(r2.update.open_questions, ["new only"]);
});

Deno.test("CAP-T25 — same open_questions_replace value is no-op", () => {
  const snap = {
    case_numbers: [],
    parties: [],
    authorities: [],
    key_dates: [],
    timeline: [],
    open_questions: ["q1", "q2"],
    next_actions: [],
    summary: null,
  };
  const r = mergePatchIntoSnapshot(snap, {
    ...emptyPatch(),
    open_questions_replace: ["q1", "q2"],
  });
  assertEquals(r.fields_changed, []);
});

Deno.test("CAP-T26 — summary replace overwrites; same is no-op", () => {
  const snap = {
    case_numbers: [],
    parties: [],
    authorities: [],
    key_dates: [],
    timeline: [],
    open_questions: [],
    next_actions: [],
    summary: "old summary",
  };
  // Different
  const r1 = mergePatchIntoSnapshot(snap, {
    ...emptyPatch(),
    summary_replace: "new summary",
  });
  assertEquals(r1.fields_changed, ["summary"]);
  assertEquals(r1.update.summary, "new summary");
  // Same (after trim)
  const r2 = mergePatchIntoSnapshot(snap, {
    ...emptyPatch(),
    summary_replace: "  old summary  ",
  });
  assertEquals(r2.fields_changed, []);
});

Deno.test("CAP-T27 — idempotent: same patch run twice = no-op second time", () => {
  let snap = {
    case_numbers: [] as unknown[],
    parties: [] as unknown[],
    authorities: [] as unknown[],
    key_dates: [] as unknown[],
    timeline: [] as unknown[],
    open_questions: [] as unknown[],
    next_actions: [] as unknown[],
    summary: null as string | null,
  };
  const patch = {
    ...emptyPatch(),
    case_numbers_add: [{ number: "X" }],
    summary_replace: "S",
  };
  const r1 = mergePatchIntoSnapshot(snap, patch);
  // Apply
  snap = {
    ...snap,
    case_numbers: r1.update.case_numbers as unknown[] ?? snap.case_numbers,
    summary: (r1.update.summary as string | undefined) ?? snap.summary,
  };
  const r2 = mergePatchIntoSnapshot(snap, patch);
  assertEquals(r2.fields_changed, []);
});

Deno.test("CAP-T28 — partial patch only writes the changed fields", () => {
  const snap = {
    case_numbers: [],
    parties: [],
    authorities: [],
    key_dates: [],
    timeline: [],
    open_questions: [],
    next_actions: [],
    summary: null,
  };
  const patch = { ...emptyPatch(), summary_replace: "S" };
  const r = mergePatchIntoSnapshot(snap, patch);
  assertEquals(r.fields_changed, ["summary"]);
  assertEquals(Object.keys(r.update), ["summary"]);
});

// =============================================================================
// 4. Source-contract tests for case-auto-patch/index.ts
// =============================================================================

const INDEX_TS = await Deno.readTextFile(
  new URL("../index.ts", import.meta.url),
);

Deno.test("CAP-S01 — uses shared auth helper (JWT gate)", () => {
  assertStringIncludes(INDEX_TS, 'from "../_shared/auth.ts"');
  assertStringIncludes(INDEX_TS, "requireUserWithRateLimit");
});

Deno.test("CAP-S02 — imports the shared prompt module", () => {
  assertStringIncludes(INDEX_TS, "_shared/case_patch_prompt.ts");
  assertStringIncludes(INDEX_TS, "CASE_PATCH_SYSTEM_PROMPT");
  assertStringIncludes(INDEX_TS, "parseCasePatch");
  assertStringIncludes(INDEX_TS, "mergePatchIntoSnapshot");
});

Deno.test("CAP-S03 — calls load_active_case RPC for ownership check", () => {
  assertStringIncludes(INDEX_TS, "load_active_case");
});

Deno.test("CAP-S04 — uses service-role client for the merge UPDATE", () => {
  // We expect the file to reference SUPABASE_SERVICE_ROLE_KEY for the
  // write step (after RLS pre-check).
  assertStringIncludes(INDEX_TS, "SUPABASE_SERVICE_ROLE_KEY");
});

Deno.test("CAP-S05 — 5-second Haiku timeout", () => {
  // Timeout constant flows in from the shared module.
  assertStringIncludes(INDEX_TS, "CASE_PATCH_HAIKU_TIMEOUT_MS");
});

Deno.test("CAP-S06 — silent skip on invalid JSON, returns 200 not 500", () => {
  // Spec: "Haiku returns invalid JSON → 200 {patched: false, reason}".
  // Source-grep — we don't run the function here, just assert the contract
  // is encoded in source.
  assertStringIncludes(INDEX_TS, '"invalid_json"');
});

Deno.test("CAP-S07 — UUID validation on case_id (matches Pkg 1.B)", () => {
  // We reuse isValidCaseId from the existing module so the UUID regex
  // stays in one place.
  assertStringIncludes(INDEX_TS, "isValidCaseId");
});

Deno.test("CAP-S08 — Haiku key check before fetch", () => {
  assertStringIncludes(INDEX_TS, "CLAUDE_API_KEY");
});

Deno.test("CAP-S09 — bucket name 'case-auto-patch' for rate-limit isolation", () => {
  assertStringIncludes(INDEX_TS, '"case-auto-patch"');
});

// =============================================================================
// 5. Phase 2 Pkg 5 — phase_transition handling
// =============================================================================

Deno.test("CAP-P01 — system prompt teaches Haiku about phase_transition", () => {
  assertStringIncludes(CASE_PATCH_SYSTEM_PROMPT, "phase_transition");
  assertStringIncludes(CASE_PATCH_SYSTEM_PROMPT, '"strategy"');
  assertStringIncludes(CASE_PATCH_SYSTEM_PROMPT, '"draft"');
  assertStringIncludes(CASE_PATCH_SYSTEM_PROMPT, '"wait"');
});

Deno.test("CAP-P02 — parser carries phase_transition through", () => {
  const raw = JSON.stringify({
    case_numbers_add: [],
    parties_add: [],
    authorities_add: [],
    key_dates_add: [],
    timeline_add: [],
    open_questions_replace: null,
    next_actions_replace: null,
    summary_replace: null,
    phase_transition: { to: "strategy", reason: "we have a docket" },
  });
  const p = parseCasePatch(raw);
  assert(p !== null);
  assertEquals(p!.phase_transition, {
    to: "strategy",
    reason: "we have a docket",
  });
});

Deno.test("CAP-P03 — parser ignores phase_transition.to='closed' (manual-only)", () => {
  const raw = JSON.stringify({
    ...emptyPatch(),
    phase_transition: { to: "closed", reason: "user said done" },
  });
  const p = parseCasePatch(raw);
  assert(p !== null);
  assertEquals(p!.phase_transition, null);
});

Deno.test("CAP-P04 — emptyPatch carries null phase_transition", () => {
  assertStrictEquals(emptyPatch().phase_transition, null);
});

Deno.test("CAP-P05 — phase_transition does NOT count as 'fact change'", () => {
  // isEmptyPatch must still report empty when only phase_transition is
  // set — the caller writes phase via a separate RPC, not the merge.
  const p = emptyPatch();
  p.phase_transition = { to: "draft", reason: "OK draft it" };
  assert(isEmptyPatch(p));
});

Deno.test("CAP-S10 — index.ts wires set_case_phase RPC", () => {
  assertStringIncludes(INDEX_TS, "set_case_phase");
  assertStringIncludes(INDEX_TS, "maybeApplyPhaseTransition");
  // RPC called AS THE USER (RLS-bound), never service-role.
  assertStringIncludes(INDEX_TS, "Authorization: args.authHeader");
});

Deno.test("CAP-S11 — index.ts imports phase rule from shared module", () => {
  assertStringIncludes(INDEX_TS, "_shared/case_phase.ts");
  assertStringIncludes(INDEX_TS, "nextAutoPhase");
});
