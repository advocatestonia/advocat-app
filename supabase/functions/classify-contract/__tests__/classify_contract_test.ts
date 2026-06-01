// classify-contract/__tests__/classify_contract_test.ts
// -----------------------------------------------------------------------------
// Pure-logic tests for the contract auto-detection chip:
//   * validateRequest — case_document_id required / non-empty / ≤128 chars.
//   * classifyDocument — the never-throws gating pipeline:
//       - foreign/missing doc → not_found (the loader is user-scoped; this is
//         the IDOR boundary — a foreign id resolves to null, no oracle).
//       - empty parsed_text → no_text (no Haiku call).
//       - loader throw / Haiku throw → graceful negative with a reason.
//       - threshold is STRICTLY greater than 0.7 (0.70 exactly → low_confidence).
//       - confidence clamped to [0,1]; NaN/негатив → 0.
//       - contract_type_hint only kept on a clean positive AND must be in the
//         allowlist (invented hints dropped).
//
// Run:
//   deno test --allow-net --allow-env --allow-read \
//     supabase/functions/classify-contract/__tests__/classify_contract_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  classifyDocument,
  type ClassifyDeps,
  type DocumentRow,
  type HaikuRequest,
  type HaikuResponse,
  validateRequest,
} from "../handler.ts";

const USER = "11111111-1111-1111-1111-111111111111";
const DOC = "22222222-2222-2222-2222-222222222222";

function doc(parsed: string | null): DocumentRow {
  return { id: DOC, user_id: USER, filename: "f.pdf", parsed_text: parsed };
}

/** Build deps with a scripted loader + Haiku, recording whether Haiku ran. */
function makeDeps(opts: {
  loaded?: DocumentRow | null;
  loadThrows?: boolean;
  haiku?: HaikuResponse;
  haikuThrows?: boolean;
}): { deps: ClassifyDeps; haikuCalled: () => boolean; haikuText: () => string } {
  let called = false;
  let text = "";
  const deps: ClassifyDeps = {
    loadDocument: (_u, _d) => {
      if (opts.loadThrows) return Promise.reject(new Error("db down"));
      return Promise.resolve(opts.loaded ?? null);
    },
    callHaiku: (r: HaikuRequest) => {
      called = true;
      text = r.documentText;
      if (opts.haikuThrows) return Promise.reject(new Error("anthropic 500"));
      return Promise.resolve(
        opts.haiku ?? { is_contract: false, confidence: 0 },
      );
    },
  };
  return { deps, haikuCalled: () => called, haikuText: () => text };
}

// ─── validateRequest ─────────────────────────────────────────────────────────

Deno.test("VAL-01 — valid id accepted", () => {
  const v = validateRequest({ case_document_id: DOC });
  assert(v.ok);
});

Deno.test("VAL-02 — missing / empty / non-string id rejected", () => {
  assert(!validateRequest({}).ok);
  assert(!validateRequest({ case_document_id: "   " }).ok);
  assert(!validateRequest({ case_document_id: 42 }).ok);
  assert(!validateRequest(null).ok);
});

Deno.test("VAL-03 — over-long id rejected", () => {
  assert(!validateRequest({ case_document_id: "x".repeat(129) }).ok);
});

// ─── classifyDocument — IDOR boundary + early exits ──────────────────────────

Deno.test("CLS-01 — foreign/missing doc → not_found, Haiku never called", async () => {
  const { deps, haikuCalled } = makeDeps({ loaded: null });
  const r = await classifyDocument({ userId: USER, documentId: DOC, deps });
  assertEquals(r, { is_contract: false, confidence: 0, reason: "not_found" });
  assert(!haikuCalled(), "must not spend Haiku on an unresolved doc");
});

Deno.test("CLS-02 — loader throw → graceful negative with load_error reason", async () => {
  const { deps, haikuCalled } = makeDeps({ loadThrows: true });
  const r = await classifyDocument({ userId: USER, documentId: DOC, deps });
  assertEquals(r.is_contract, false);
  assertEquals(r.confidence, 0);
  assert(r.reason?.startsWith("load_error"));
  assert(!haikuCalled());
});

Deno.test("CLS-03 — empty parsed_text → no_text, Haiku never called", async () => {
  const { deps, haikuCalled } = makeDeps({ loaded: doc("   ") });
  const r = await classifyDocument({ userId: USER, documentId: DOC, deps });
  assertEquals(r.reason, "no_text");
  assert(!haikuCalled());
});

Deno.test("CLS-04 — Haiku throw → planner_error negative", async () => {
  const { deps } = makeDeps({ loaded: doc("AGREEMENT ..."), haikuThrows: true });
  const r = await classifyDocument({ userId: USER, documentId: DOC, deps });
  assertEquals(r.is_contract, false);
  assert(r.reason?.startsWith("planner_error"));
});

// ─── classifyDocument — threshold + sanitisation ─────────────────────────────

Deno.test("CLS-05 — confidence exactly 0.7 is NOT above threshold → low_confidence", async () => {
  const { deps } = makeDeps({
    loaded: doc("This Agreement ..."),
    haiku: { is_contract: true, confidence: 0.7, contract_type_hint: "nda" },
  });
  const r = await classifyDocument({ userId: USER, documentId: DOC, deps });
  assertEquals(r.is_contract, false);
  assertEquals(r.reason, "low_confidence");
  assertEquals(r.contract_type_hint, undefined); // hint dropped on non-positive
});

Deno.test("CLS-06 — clean positive (>0.7) keeps allowlisted hint", async () => {
  const { deps } = makeDeps({
    loaded: doc("Non-Disclosure Agreement ..."),
    haiku: { is_contract: true, confidence: 0.92, contract_type_hint: "NDA" },
  });
  const r = await classifyDocument({ userId: USER, documentId: DOC, deps });
  assertEquals(r.is_contract, true);
  assertEquals(r.confidence, 0.92);
  assertEquals(r.contract_type_hint, "nda"); // normalised lowercase
});

Deno.test("CLS-07 — invented hint is dropped even on a positive", async () => {
  const { deps } = makeDeps({
    loaded: doc("Some agreement ..."),
    haiku: { is_contract: true, confidence: 0.95, contract_type_hint: "spaceship_lease" },
  });
  const r = await classifyDocument({ userId: USER, documentId: DOC, deps });
  assertEquals(r.is_contract, true);
  assertEquals(r.contract_type_hint, undefined);
});

Deno.test("CLS-08 — out-of-range / NaN confidence is clamped", async () => {
  const { deps } = makeDeps({
    loaded: doc("x"),
    haiku: { is_contract: true, confidence: 5 },
  });
  const r = await classifyDocument({ userId: USER, documentId: DOC, deps });
  assertEquals(r.confidence, 1); // clamped to 1
  assertEquals(r.is_contract, true);

  const { deps: deps2 } = makeDeps({
    loaded: doc("x"),
    haiku: { is_contract: true, confidence: Number.NaN },
  });
  const r2 = await classifyDocument({ userId: USER, documentId: DOC, deps: deps2 });
  assertEquals(r2.confidence, 0);
  assertEquals(r2.is_contract, false);
});

Deno.test("CLS-09 — Haiku says not-contract → not_contract reason", async () => {
  const { deps } = makeDeps({
    loaded: doc("Court decision ..."),
    haiku: { is_contract: false, confidence: 0.9 },
  });
  const r = await classifyDocument({ userId: USER, documentId: DOC, deps });
  assertEquals(r.is_contract, false);
  assertEquals(r.reason, "not_contract");
});

Deno.test("CLS-10 — long text is truncated to the first-page budget before Haiku", async () => {
  const { deps, haikuText } = makeDeps({
    loaded: doc("A".repeat(10_000)),
    haiku: { is_contract: false, confidence: 0 },
  });
  await classifyDocument({ userId: USER, documentId: DOC, deps });
  assertEquals(haikuText().length, 3_000);
});
