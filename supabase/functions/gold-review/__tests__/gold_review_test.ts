// gold-review/__tests__/gold_review_test.ts
// -----------------------------------------------------------------------------
// Pure-logic regression for the Gold Corpus admin endpoint:
//   * parseReviewerIds — comma-split, trim, lowercase, drop empties; missing
//     env ⇒ empty set ⇒ NO reviewer allowed (fail-closed gate).
//   * isUuid — queue_id is interpolated raw into PostgREST id=eq.${queueId};
//     only a canonical UUID may pass so "&"/"?" can't smuggle query params.
//   * editSimilarity — token Jaccard, used to score how much Sofia rewrote.
//   * clampInt / parseTotalFromContentRange — pagination + count parsing.
//
// Run:
//   deno test --allow-read \
//     supabase/functions/gold-review/__tests__/gold_review_test.ts
// -----------------------------------------------------------------------------

import { assert, assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  clampInt,
  editSimilarity,
  isUuid,
  parseReviewerIds,
  parseTotalFromContentRange,
} from "../pure.ts";

const UUID = "22222222-2222-2222-2222-222222222222";

// ─── parseReviewerIds ─────────────────────────────────────────────────────────

Deno.test("RID-01 — missing env ⇒ empty set (no one allowed)", () => {
  assertEquals(parseReviewerIds(undefined).size, 0);
  assertEquals(parseReviewerIds("").size, 0);
});

Deno.test("RID-02 — split / trim / lowercase / drop empties", () => {
  const s = parseReviewerIds(`  ${UUID.toUpperCase()} , ,  ${UUID}  `);
  assertEquals(s.size, 1); // both normalise to the same lowercase id
  assert(s.has(UUID));
});

// ─── isUuid (queue_id PostgREST-injection guard) ─────────────────────────────

Deno.test("IDU-01 — canonical UUIDs pass (any case)", () => {
  assert(isUuid(UUID));
  assert(isUuid(UUID.toUpperCase()));
});

Deno.test("IDU-02 — query-smuggling / malformed rejected", () => {
  for (
    const bad of [
      `${UUID}&added_to_pairs=eq.false`,
      `${UUID}?select=*`,
      "not-a-uuid",
      "22222222222222222222222222222222",
      "",
      `${UUID} `,
    ]
  ) {
    assert(!isUuid(bad), `expected ${JSON.stringify(bad)} rejected`);
  }
});

Deno.test("IDU-03 — non-string rejected (no throw)", () => {
  for (const bad of [null, undefined, 123, {}, []]) {
    assert(!isUuid(bad as unknown));
  }
});

// ─── editSimilarity ───────────────────────────────────────────────────────────

Deno.test("SIM-01 — identical text ⇒ 1, disjoint ⇒ 0", () => {
  assertEquals(editSimilarity("the quick brown fox", "the quick brown fox"), 1);
  assertEquals(editSimilarity("alpha beta", "gamma delta"), 0);
});

Deno.test("SIM-02 — empty handling", () => {
  assertEquals(editSimilarity("", ""), 1);
  assertEquals(editSimilarity("text", ""), 0);
  assertEquals(editSimilarity("", "text"), 0);
});

Deno.test("SIM-03 — partial overlap is a fraction in (0,1)", () => {
  // {a,b,c} vs {b,c,d}: inter=2, union=4 ⇒ 0.5
  const sim = editSimilarity("aa bb cc", "bb cc dd");
  assertEquals(sim, 0.5);
});

// ─── clampInt / content-range ────────────────────────────────────────────────

Deno.test("CLAMP-01 — bounds + fallback", () => {
  assertEquals(clampInt(null, 1, 100, 20), 20);
  assertEquals(clampInt("0", 1, 100, 20), 1);
  assertEquals(clampInt("999", 1, 100, 20), 100);
  assertEquals(clampInt("abc", 1, 100, 20), 20);
  assertEquals(clampInt("50", 1, 100, 20), 50);
});

Deno.test("CR-01 — parse total from PostgREST Content-Range", () => {
  assertEquals(parseTotalFromContentRange("0-19/237"), 237);
  assertEquals(parseTotalFromContentRange("*/0"), 0);
  assertEquals(parseTotalFromContentRange(""), null);
  assertEquals(parseTotalFromContentRange("garbage"), null);
});
