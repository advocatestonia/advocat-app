// classify_contract.test.ts — Contract auto-detection classifier tests.
// -----------------------------------------------------------------------------
// Run:
//   deno test --allow-all supabase/functions/_tests/classify_contract.test.ts
//
// Scope:
//   T01  validateRequest rejects missing case_document_id       → 400
//   T02  validateRequest accepts a valid UUID-shaped id          → ok
//   T03  classifyDocument with no parsed_text                    → not contract, 0 conf
//   T04  classifyDocument success above threshold (0.7)          → is_contract=true
//   T05  classifyDocument below threshold                        → is_contract=false
//   T06  classifyDocument truncates input to first-page budget   → planner sees ≤budget chars
//   T07  classifyDocument never returns the substring "B2B"      → forbidden marker absent
//   T08  classifyDocument propagates contract_type_hint when high-conf
//   T09  classifyDocument resilient to planner returning garbage → not contract
//   T10  buildSystemPrompt is short (≤ 200 token budget guard)
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

// Stub env BEFORE importing the handler.
Deno.env.set("SUPABASE_URL", "https://example.supabase.co");
Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "fake-service-key");

import {
  buildSystemPrompt,
  CLASSIFY_CONFIDENCE_THRESHOLD,
  classifyDocument,
  FIRST_PAGE_CHAR_BUDGET,
  type ClassifyDeps,
  type ClassifyResult,
  type ContractTypeHint,
  type DocumentLoader,
  type HaikuCaller,
  validateRequest,
} from "../classify-contract/handler.ts";

// ─── Helpers ────────────────────────────────────────────────────────────────

const UUID_1 = "11111111-1111-1111-1111-111111111111";
const USER = "user-abc-123";

function makeDeps(overrides: Partial<ClassifyDeps> = {}): ClassifyDeps {
  const loader: DocumentLoader = async () => ({
    id: UUID_1,
    user_id: USER,
    filename: "doc.pdf",
    parsed_text: "DEALER AGREEMENT between Acme and Beta dated 2025-01-01. " +
      "WHEREAS the parties agree to the following terms...",
  });
  const haiku: HaikuCaller = async () => ({
    is_contract: true,
    confidence: 0.92,
    contract_type_hint: "dealer",
  });
  return { loadDocument: loader, callHaiku: haiku, ...overrides };
}

// =============================================================================
// T01 — validateRequest rejects missing case_document_id
// =============================================================================
Deno.test("T01 — validateRequest rejects missing case_document_id", () => {
  const r = validateRequest({});
  assertEquals(r.ok, false);
  if (!r.ok) assertStringIncludes(r.error, "case_document_id");
});

Deno.test("T01b — validateRequest rejects non-string id", () => {
  const r = validateRequest({ case_document_id: 42 });
  assertEquals(r.ok, false);
});

Deno.test("T01c — validateRequest rejects empty string", () => {
  const r = validateRequest({ case_document_id: "" });
  assertEquals(r.ok, false);
});

// =============================================================================
// T02 — validateRequest accepts a valid id
// =============================================================================
Deno.test("T02 — validateRequest accepts valid UUID", () => {
  const r = validateRequest({ case_document_id: UUID_1 });
  assertEquals(r.ok, true);
  if (r.ok) assertEquals(r.value.case_document_id, UUID_1);
});

// =============================================================================
// T03 — Document with no parsed_text → not contract
// =============================================================================
Deno.test("T03 — empty parsed_text returns is_contract=false", async () => {
  const deps = makeDeps({
    loadDocument: async () => ({
      id: UUID_1,
      user_id: USER,
      filename: "doc.pdf",
      parsed_text: null,
    }),
  });
  const result = await classifyDocument({
    userId: USER,
    documentId: UUID_1,
    deps,
  });
  assertEquals(result.is_contract, false);
  assertEquals(result.confidence, 0);
  assertEquals(result.reason, "no_text");
});

// =============================================================================
// T04 — Above threshold (0.7) → is_contract = true
// =============================================================================
Deno.test("T04 — above 0.7 threshold returns is_contract=true", async () => {
  const deps = makeDeps({
    callHaiku: async () => ({
      is_contract: true,
      confidence: 0.85,
      contract_type_hint: "saas",
    }),
  });
  const result = await classifyDocument({
    userId: USER,
    documentId: UUID_1,
    deps,
  });
  assertEquals(result.is_contract, true);
  assertEquals(result.confidence, 0.85);
  assertEquals(result.contract_type_hint, "saas");
});

// =============================================================================
// T05 — Below threshold → is_contract = false
// =============================================================================
Deno.test("T05 — below 0.7 threshold returns is_contract=false", async () => {
  const deps = makeDeps({
    callHaiku: async () => ({
      is_contract: true,
      confidence: 0.4,
      contract_type_hint: undefined,
    }),
  });
  const result = await classifyDocument({
    userId: USER,
    documentId: UUID_1,
    deps,
  });
  assertEquals(result.is_contract, false);
  assertEquals(result.confidence, 0.4);
});

Deno.test("T05b — exactly at threshold (0.7) is NOT contract (strict > )", async () => {
  const deps = makeDeps({
    callHaiku: async () => ({
      is_contract: true,
      confidence: CLASSIFY_CONFIDENCE_THRESHOLD,
      contract_type_hint: undefined,
    }),
  });
  const result = await classifyDocument({
    userId: USER,
    documentId: UUID_1,
    deps,
  });
  // Threshold is strictly greater-than; 0.7 itself is below the bar.
  assertEquals(result.is_contract, false);
});

// =============================================================================
// T06 — Input truncated to first-page char budget
// =============================================================================
Deno.test("T06 — planner only sees first-page char budget", async () => {
  // Long document — far past the budget.
  const longText = "A".repeat(FIRST_PAGE_CHAR_BUDGET + 5_000);
  let observed = "";
  const deps = makeDeps({
    loadDocument: async () => ({
      id: UUID_1,
      user_id: USER,
      filename: "doc.pdf",
      parsed_text: longText,
    }),
    callHaiku: async (req) => {
      observed = req.documentText;
      return {
        is_contract: false,
        confidence: 0.1,
      };
    },
  });
  await classifyDocument({ userId: USER, documentId: UUID_1, deps });
  assert(
    observed.length <= FIRST_PAGE_CHAR_BUDGET,
    `truncation failed: observed=${observed.length} budget=${FIRST_PAGE_CHAR_BUDGET}`,
  );
});

// =============================================================================
// T07 — System prompt never contains forbidden marker
// =============================================================================
Deno.test("T07 — system prompt never contains 'B2B'", () => {
  const prompt = buildSystemPrompt();
  // Case-insensitive check — forbidden marker is "B2B" in any case.
  assertEquals(prompt.toLowerCase().includes("b2b"), false);
});

Deno.test("T07b — handler source files never contain 'B2B'", async () => {
  const handler = await Deno.readTextFile(
    new URL("../classify-contract/handler.ts", import.meta.url),
  );
  const index = await Deno.readTextFile(
    new URL("../classify-contract/index.ts", import.meta.url),
  );
  // Case-insensitive: any cased variant is forbidden.
  assertEquals(handler.toLowerCase().includes("b2b"), false);
  assertEquals(index.toLowerCase().includes("b2b"), false);
});

// =============================================================================
// T08 — contract_type_hint propagated for high-conf positives
// =============================================================================
Deno.test("T08 — contract_type_hint values accepted", async () => {
  const hints: ContractTypeHint[] = [
    "dealer",
    "saas",
    "nda",
    "employment",
    "m&a",
    "real_estate",
  ];
  for (const hint of hints) {
    const deps = makeDeps({
      callHaiku: async () => ({
        is_contract: true,
        confidence: 0.9,
        contract_type_hint: hint,
      }),
    });
    const r = await classifyDocument({
      userId: USER,
      documentId: UUID_1,
      deps,
    });
    assertEquals(r.contract_type_hint, hint);
  }
});

// =============================================================================
// T09 — Planner garbage → graceful fallback
// =============================================================================
Deno.test("T09 — planner throwing returns safe negative", async () => {
  const deps = makeDeps({
    callHaiku: async () => {
      throw new Error("anthropic 503");
    },
  });
  const result = await classifyDocument({
    userId: USER,
    documentId: UUID_1,
    deps,
  });
  assertEquals(result.is_contract, false);
  assertEquals(result.confidence, 0);
  // reason starts with "planner_error" — body of the message follows.
  assert(
    (result.reason ?? "").startsWith("planner_error"),
    `expected planner_error reason, got ${result.reason}`,
  );
});

Deno.test("T09b — planner returning invalid confidence clamped", async () => {
  const deps = makeDeps({
    callHaiku: async () => ({
      is_contract: true,
      // deno-lint-ignore no-explicit-any
      confidence: ("not-a-number" as any),
    }),
  });
  const result = await classifyDocument({
    userId: USER,
    documentId: UUID_1,
    deps,
  });
  assertEquals(result.is_contract, false);
  assertEquals(result.confidence, 0);
});

// =============================================================================
// T10 — System prompt budget guard
// =============================================================================
Deno.test("T10 — system prompt stays under 1000 chars (~200 token budget)", () => {
  const prompt = buildSystemPrompt();
  // Conservative rule-of-thumb: 1 token ≈ 4–5 chars for English-leaning text.
  // 1000 chars keeps us comfortably under the 200-token budget mandated by
  // the spec.
  assert(
    prompt.length <= 1000,
    `prompt too long: ${prompt.length} chars (target <=1000)`,
  );
  // Must still contain the keyword the JSON contract expects so the model
  // emits the right shape.
  assertStringIncludes(prompt, "is_contract");
  assertStringIncludes(prompt, "confidence");
});

// =============================================================================
// T11 — Document not owned by user → safe negative (defence in depth)
// =============================================================================
Deno.test("T11 — document not found returns safe negative", async () => {
  const deps = makeDeps({
    loadDocument: async () => null,
  });
  const result: ClassifyResult = await classifyDocument({
    userId: USER,
    documentId: UUID_1,
    deps,
  });
  assertEquals(result.is_contract, false);
  assertEquals(result.confidence, 0);
  assertEquals(result.reason, "not_found");
});

// =============================================================================
// T12 — Haiku tells us not_contract — even high confidence stays false
// =============================================================================
Deno.test("T12 — is_contract=false from Haiku overrides confidence", async () => {
  const deps = makeDeps({
    callHaiku: async () => ({
      is_contract: false,
      confidence: 0.95,
    }),
  });
  const result = await classifyDocument({
    userId: USER,
    documentId: UUID_1,
    deps,
  });
  assertEquals(result.is_contract, false);
  assertEquals(result.confidence, 0.95);
});
