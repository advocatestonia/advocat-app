// Deno tests for Smart Case Follow-ups (Feature #2) — suggestion parser.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/case-followups/__tests__/followup_suggest_prompt_test.ts
//
//   * Pure-function tests for `followup_suggest_prompt.ts` (extract + parse +
//     clamp + offsetToDueAt).
//   * Source-contract tests for `case-followups/index.ts` (imports, RPC names,
//     JWT gating) and `followup-tick/index.ts` (cron gate, push-send).
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  buildFollowupUserBlock,
  extractJsonArray,
  FOLLOWUP_HAIKU_MODEL,
  FOLLOWUP_IDENTITY_MARKER,
  FOLLOWUP_MAX_OFFSET_DAYS,
  FOLLOWUP_MAX_SUGGESTIONS,
  FOLLOWUP_SUGGEST_SYSTEM_PROMPT,
  offsetToDueAt,
  parseFollowupSuggestions,
} from "../../_shared/followup_suggest_prompt.ts";

// ── extractJsonArray ────────────────────────────────────────────────────────

Deno.test("extractJsonArray: plain array", () => {
  assertEquals(extractJsonArray('[{"a":1}]'), '[{"a":1}]');
});

Deno.test("extractJsonArray: strips leading prose", () => {
  const out = extractJsonArray('Here are the steps: [{"title":"x"}] done');
  assertEquals(out, '[{"title":"x"}]');
});

Deno.test("extractJsonArray: unwraps ```json fence", () => {
  const out = extractJsonArray('```json\n[{"title":"x"}]\n```');
  assertEquals(out, '[{"title":"x"}]');
});

Deno.test("extractJsonArray: no array -> null", () => {
  assertEquals(extractJsonArray("no json here"), null);
  assertEquals(extractJsonArray("{}"), null);
});

// ── parseFollowupSuggestions ────────────────────────────────────────────────

Deno.test("parse: well-formed array maps cleanly", () => {
  const raw = JSON.stringify([
    {
      title: "Send records request to police",
      detail: "Cite JulkL 14§",
      due_offset_days: 3,
    },
    { title: "Collect receipts", detail: null, due_offset_days: 0 },
  ]);
  const out = parseFollowupSuggestions(raw);
  assertEquals(out.length, 2);
  assertEquals(out[0].title, "Send records request to police");
  assertEquals(out[0].detail, "Cite JulkL 14§");
  assertEquals(out[0].due_offset_days, 3);
  assertEquals(out[1].detail, null);
  assertEquals(out[1].due_offset_days, 0);
});

Deno.test("parse: malformed JSON -> empty", () => {
  assertEquals(parseFollowupSuggestions("not json"), []);
  assertEquals(parseFollowupSuggestions("[unterminated"), []);
});

Deno.test("parse: non-array JSON -> empty", () => {
  assertEquals(parseFollowupSuggestions('{"title":"x"}'), []);
});

Deno.test("parse: empty array stays empty", () => {
  assertEquals(parseFollowupSuggestions("[]"), []);
});

Deno.test("parse: skips items without a string title", () => {
  const raw = JSON.stringify([
    { detail: "no title" },
    { title: 42 },
    { title: "  " }, // whitespace only -> trimmed to empty -> skipped
    { title: "Valid step" },
  ]);
  const out = parseFollowupSuggestions(raw);
  assertEquals(out.length, 1);
  assertEquals(out[0].title, "Valid step");
});

Deno.test("parse: dedupes case-insensitively by title", () => {
  const raw = JSON.stringify([
    { title: "Call landlord" },
    { title: "call landlord" },
    { title: "CALL LANDLORD" },
  ]);
  const out = parseFollowupSuggestions(raw);
  assertEquals(out.length, 1);
});

Deno.test("parse: caps at FOLLOWUP_MAX_SUGGESTIONS", () => {
  const items = [];
  for (let i = 0; i < FOLLOWUP_MAX_SUGGESTIONS + 4; i++) {
    items.push({ title: `Step ${i}` });
  }
  const out = parseFollowupSuggestions(JSON.stringify(items));
  assertEquals(out.length, FOLLOWUP_MAX_SUGGESTIONS);
});

Deno.test("parse: clamps due_offset_days to [0, MAX]", () => {
  const raw = JSON.stringify([
    { title: "a", due_offset_days: -5 },
    { title: "b", due_offset_days: 99999 },
    { title: "c", due_offset_days: 7 },
    { title: "d", due_offset_days: 2.6 }, // rounds
  ]);
  const out = parseFollowupSuggestions(raw);
  assertEquals(out[0].due_offset_days, 0);
  assertEquals(out[1].due_offset_days, FOLLOWUP_MAX_OFFSET_DAYS);
  assertEquals(out[2].due_offset_days, 7);
  assertEquals(out[3].due_offset_days, 3);
});

Deno.test("parse: missing/non-numeric offset defaults to 0", () => {
  const raw = JSON.stringify([
    { title: "a" },
    { title: "b", due_offset_days: "soon" },
    { title: "c", due_offset_days: NaN },
  ]);
  const out = parseFollowupSuggestions(raw);
  for (const s of out) assertEquals(s.due_offset_days, 0);
});

Deno.test("parse: truncates over-long title/detail", () => {
  const longTitle = "x".repeat(400);
  const longDetail = "y".repeat(800);
  const out = parseFollowupSuggestions(
    JSON.stringify([{ title: longTitle, detail: longDetail }])
  );
  assertEquals(out[0].title.length, 280);
  assertEquals(out[0].detail!.length, 500);
});

// ── offsetToDueAt ───────────────────────────────────────────────────────────

Deno.test("offsetToDueAt: 0 or negative -> null (someday task)", () => {
  const now = new Date("2026-06-14T12:00:00.000Z");
  assertEquals(offsetToDueAt(0, now), null);
  assertEquals(offsetToDueAt(-3, now), null);
});

Deno.test("offsetToDueAt: positive offset -> ISO N days ahead", () => {
  const now = new Date("2026-06-14T12:00:00.000Z");
  assertEquals(offsetToDueAt(3, now), "2026-06-17T12:00:00.000Z");
});

// ── buildFollowupUserBlock ──────────────────────────────────────────────────

Deno.test("buildFollowupUserBlock: wraps snapshot + transcript", () => {
  const block = buildFollowupUserBlock({
    snapshotJson: '{"existing_steps":[]}',
    transcript: "user: what next?",
  });
  assertStringIncludes(block, "<case_snapshot>");
  assertStringIncludes(block, '{"existing_steps":[]}');
  assertStringIncludes(block, "<recent_conversation>");
  assertStringIncludes(block, "user: what next?");
});

// ── prompt constants ────────────────────────────────────────────────────────

Deno.test("system prompt starts with the identity marker", () => {
  assert(FOLLOWUP_SUGGEST_SYSTEM_PROMPT.startsWith(FOLLOWUP_IDENTITY_MARKER));
});

Deno.test("system prompt forbids inventing legal deadlines", () => {
  assertStringIncludes(FOLLOWUP_SUGGEST_SYSTEM_PROMPT, "НЕ придумывай");
});

Deno.test("Haiku model is pinned to the haiku channel", () => {
  assertStringIncludes(FOLLOWUP_HAIKU_MODEL, "haiku");
});

// ── source-contract: case-followups/index.ts ────────────────────────────────

const FN_SRC = await Deno.readTextFile(new URL("../index.ts", import.meta.url));

Deno.test("case-followups: JWT-gated via requireUserWithRateLimit", () => {
  assertStringIncludes(FN_SRC, "requireUserWithRateLimit");
  assertStringIncludes(FN_SRC, 'bucket: "case-followups"');
});

Deno.test("case-followups: uses RLS RPCs, never service-role client", () => {
  assertStringIncludes(FN_SRC, "case_followups_for_case");
  assertStringIncludes(FN_SRC, "complete_case_followup");
  assertStringIncludes(FN_SRC, "snooze_case_followup");
  assertFalse(FN_SRC.includes("SERVICE_ROLE"));
});

Deno.test("case-followups: suggest proves ownership before Haiku", () => {
  // The own-check RPC call must appear before the runHaiku invocation.
  const ownIdx = FN_SRC.indexOf("case_followups_for_case");
  const haikuIdx = FN_SRC.indexOf("runHaiku({");
  assert(ownIdx !== -1 && haikuIdx !== -1);
  assert(ownIdx < haikuIdx, "ownership check must precede Haiku call");
});

Deno.test("case-followups: scrubs Anthropic egress body", () => {
  assertStringIncludes(FN_SRC, "scrubAnthropicBody");
});

Deno.test("case-followups: validates case_id as UUID", () => {
  assertStringIncludes(FN_SRC, "isValidCaseId");
});

// ── source-contract: followup-tick/index.ts ─────────────────────────────────

const TICK_SRC = await Deno.readTextFile(
  new URL("../../followup-tick/index.ts", import.meta.url)
);

Deno.test("followup-tick: cron-secret gated", () => {
  assertStringIncludes(TICK_SRC, "checkCronSecret");
});

Deno.test("followup-tick: routes push through push-send", () => {
  assertStringIncludes(TICK_SRC, "/functions/v1/push-send");
});

Deno.test("followup-tick: stamps reminded_at to avoid double-nudge", () => {
  assertStringIncludes(TICK_SRC, "reminded_at");
  // Optimistic claim: update guarded by .is('reminded_at', null).
  assertStringIncludes(TICK_SRC, '.is("reminded_at", null)');
});

Deno.test("followup-tick: response is counts-only (no PII echo)", () => {
  assertStringIncludes(TICK_SRC, "scanned");
  assertFalse(TICK_SRC.includes("details: rows"));
});
