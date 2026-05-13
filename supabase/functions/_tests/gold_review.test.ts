// gold_review.test.ts — Sofia Gold Corpus Phase A.
// ----------------------------------------------------------------------------
// Run with:
//   deno test --allow-net --allow-read --allow-env \
//     supabase/functions/_tests/gold_review.test.ts
//
// Coverage:
//   - parseReviewerIds tolerates whitespace, lowercases, drops empties.
//   - editSimilarity returns 1.0 for identical strings.
//   - editSimilarity returns 0.0 for fully disjoint strings.
//   - editSimilarity returns a sane mid-range value for partial overlap.
//   - shouldEnqueueGold (helper) rejects anon, short, and sampled-out rows.
//   - shouldEnqueueGold accepts authenticated long-enough rows at 100% rate.
// ----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  editSimilarity,
  parseReviewerIds,
} from "../gold-review/index.ts";
import { shouldEnqueueGold } from "../_shared/gold_enqueue.ts";

// ─── parseReviewerIds ───────────────────────────────────────────────────────

Deno.test("parseReviewerIds — undefined returns empty set", () => {
  const s = parseReviewerIds(undefined);
  assertEquals(s.size, 0);
});

Deno.test("parseReviewerIds — empty string returns empty set", () => {
  const s = parseReviewerIds("");
  assertEquals(s.size, 0);
});

Deno.test("parseReviewerIds — single id", () => {
  const s = parseReviewerIds("11111111-1111-1111-1111-111111111111");
  assertEquals(s.size, 1);
  assert(s.has("11111111-1111-1111-1111-111111111111"));
});

Deno.test("parseReviewerIds — comma list with whitespace, lowercased", () => {
  const s = parseReviewerIds(
    "11111111-1111-1111-1111-111111111111 , AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE",
  );
  assertEquals(s.size, 2);
  assert(s.has("11111111-1111-1111-1111-111111111111"));
  assert(s.has("aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"));
});

Deno.test("parseReviewerIds — drops empty tokens from trailing commas", () => {
  const s = parseReviewerIds("a,,b,");
  assertEquals(s.size, 2);
  assert(s.has("a"));
  assert(s.has("b"));
});

// ─── editSimilarity ─────────────────────────────────────────────────────────

Deno.test("editSimilarity — identical strings → 1.0", () => {
  const r = editSimilarity(
    "Üldjuhul ei. TLS § 100 sätestab koondamishüvitise.",
    "Üldjuhul ei. TLS § 100 sätestab koondamishüvitise.",
  );
  assertEquals(r, 1);
});

Deno.test("editSimilarity — disjoint strings → 0.0", () => {
  const r = editSimilarity("alpha beta gamma", "delta epsilon zeta");
  assertEquals(r, 0);
});

Deno.test("editSimilarity — partial overlap is in [0,1]", () => {
  const r = editSimilarity(
    "TLS § 100 sätestab koondamishüvitise tähtajatu lepingu lõpetamisel",
    "TLS § 100 reguleerib koondamishüvitist tähtajatu lepingu lõpetamise korral",
  );
  assert(r > 0, `expected > 0, got ${r}`);
  assert(r < 1, `expected < 1, got ${r}`);
});

Deno.test("editSimilarity — both empty → 1.0", () => {
  assertEquals(editSimilarity("", ""), 1);
});

Deno.test("editSimilarity — one empty → 0.0", () => {
  assertEquals(editSimilarity("non-empty", ""), 0);
  assertEquals(editSimilarity("", "non-empty"), 0);
});

// ─── shouldEnqueueGold ──────────────────────────────────────────────────────

const LONG_Q =
  "Tööandja ütles, et koondamishüvitist ei maksa, kuna ma olin tähtajalise lepinguga. Kas see on õige?";

Deno.test("shouldEnqueueGold — anon userId rejected", () => {
  assertEquals(
    shouldEnqueueGold({
      userId: null,
      userQuestion: LONG_Q,
      sampleRate: 1.0,
      rng: () => 0,
    }),
    false,
  );
  assertEquals(
    shouldEnqueueGold({
      userId: "anon:1.2.3.4",
      userQuestion: LONG_Q,
      sampleRate: 1.0,
      rng: () => 0,
    }),
    false,
  );
});

Deno.test("shouldEnqueueGold — too-short question rejected", () => {
  assertEquals(
    shouldEnqueueGold({
      userId: "real-user-id",
      userQuestion: "tere",
      sampleRate: 1.0,
      rng: () => 0,
    }),
    false,
  );
});

Deno.test("shouldEnqueueGold — sampleRate=0 rejects everything", () => {
  assertEquals(
    shouldEnqueueGold({
      userId: "real-user-id",
      userQuestion: LONG_Q,
      sampleRate: 0,
      rng: () => 0.0001,
    }),
    false,
  );
});

Deno.test("shouldEnqueueGold — sampleRate=1 accepts authenticated long Q", () => {
  assertEquals(
    shouldEnqueueGold({
      userId: "real-user-id",
      userQuestion: LONG_Q,
      sampleRate: 1.0,
      rng: () => 0.999,
    }),
    true,
  );
});

Deno.test("shouldEnqueueGold — sampleRate=0.5 honours rng outcome", () => {
  // rng returns 0.6 → above the 0.5 cutoff → reject.
  assertEquals(
    shouldEnqueueGold({
      userId: "real-user-id",
      userQuestion: LONG_Q,
      sampleRate: 0.5,
      rng: () => 0.6,
    }),
    false,
  );
  // rng returns 0.1 → below 0.5 → accept.
  assertEquals(
    shouldEnqueueGold({
      userId: "real-user-id",
      userQuestion: LONG_Q,
      sampleRate: 0.5,
      rng: () => 0.1,
    }),
    true,
  );
});
