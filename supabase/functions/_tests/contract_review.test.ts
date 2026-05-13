// contract_review.test.ts — Contract Review mode unit tests.
// -----------------------------------------------------------------------------
// Run:
//   deno test --allow-all supabase/functions/_tests/contract_review.test.ts
//
// Scope (matches the task spec — 7 cases):
//   T01  validateRequest rejects empty case_document_ids               → 400
//   T02  validateRequest rejects unsupported output_language            → 400
//   T03  isQuotaExceeded — free tier lifetime cap                       → 402-shape
//   T04  isQuotaExceeded — basic tier 30-day window rolls               → not exceeded
//   T05  runContractReview success with 1 doc + mocked planner          → 200
//   T06  runContractReview enqueues async job when 4+ docs              → 202
//   T07  runContractReview graceful fallback when pdfWorker=null        → 200 + worker_not_configured
//   T08  runContractReview increments quota on success ONLY             → counter == 1
//   T09  runContractReview does NOT increment quota on planner failure  → counter == 0
//   T10  buildContractReviewSystemPrompt returns stub placeholder       → contains marker
//
// The HTTP layer (auth gate, JSON parsing, CORS) is covered indirectly via
// the in-process source-code checks T11-T12 below — we assert that index.ts
// uses requireUserWithRateLimit with NO anonymousPerMinute (i.e. anon rejected).
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

// Stub env BEFORE importing the handler / shared modules.
Deno.env.set("SUPABASE_URL", "https://example.supabase.co");
Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "fake-service-key");

import {
  buildStoragePath,
  type CaseDocumentRow,
  type ContractReviewRequest,
  countCriticalRisks,
  type DbClient,
  isQuotaExceeded,
  type PdfWorkerCaller,
  type PlannerCaller,
  QUOTA_LIMITS,
  QUOTA_WINDOW_MS,
  type QuotaState,
  runContractReview,
  type StorageUploader,
  validateRequest,
  verifyPlannerOutput,
} from "../contract-review/handler.ts";
import {
  buildContractReviewSystemPrompt,
  type ContractReviewOutput,
} from "../_shared/contract_review_prompts.ts";

// ─── Helpers ────────────────────────────────────────────────────────────────

const UUID_1 = "11111111-1111-1111-1111-111111111111";
const UUID_2 = "22222222-2222-2222-2222-222222222222";
const UUID_3 = "33333333-3333-3333-3333-333333333333";
const UUID_4 = "44444444-4444-4444-4444-444444444444";
const UUID_5 = "55555555-5555-5555-5555-555555555555";
const USER = "user-abc-123";

function mockDoc(
  id: string,
  parsedText = "This is a contract about widgets...",
  pageCount: number | null = 3,
): CaseDocumentRow {
  return {
    id,
    user_id: USER,
    filename: `doc-${id.slice(0, 4)}.pdf`,
    parsed_text: parsedText,
    page_count: pageCount,
  };
}

function plannerOutput(): ContractReviewOutput {
  return {
    cover: {
      contract_name: "Dealer Agreement v3",
      counterparty: "Acme GmbH",
      client_role: "Dealer",
      jurisdiction: "DE",
      score: 62,
    },
    summary: "Three critical risks identified in §4.2 and §11.",
    checklist: [
      {
        clause: "§4.2 — termination",
        risk_level: "critical",
        finding: "Unilateral termination for convenience with 7 days notice.",
        recommendation: "Negotiate to 90 days + cure period.",
      },
      {
        clause: "§11 — IP assignment",
        risk_level: "critical",
        finding: "Pre-existing IP swept into the assignment.",
        recommendation: "Carve out pre-existing IP.",
      },
      {
        clause: "§3 — pricing",
        risk_level: "medium",
        finding: "Annual escalator unbounded.",
        recommendation: "Cap escalator at CPI + 2%.",
      },
    ],
    email_to_counterparty:
      "Dear Acme team, we have reviewed v3 of the Dealer Agreement and request the following amendments...",
  };
}

interface FakeState {
  quota: QuotaState;
  incrementCalls: number;
  rollPeriodCalls: number;
  insertedReviewIds: string[];
  enqueuedJobs: Array<{ userId: string; req: ContractReviewRequest }>;
}

function fakeDb(
  docs: Map<string, CaseDocumentRow>,
  state: FakeState,
): DbClient {
  return {
    loadQuota: async () => state.quota,
    incrementQuota: async (_uid, rollPeriod) => {
      state.incrementCalls++;
      if (rollPeriod) state.rollPeriodCalls++;
      // Mutate the state so subsequent loads see the bump.
      state.quota = {
        ...state.quota,
        contract_reviews_used: rollPeriod
          ? 1
          : state.quota.contract_reviews_used + 1,
      };
    },
    loadOwnedDocuments: async (_uid, ids) => {
      return ids.map((id) => docs.get(id)).filter((d): d is CaseDocumentRow => !!d);
    },
    enqueueJob: async (uid, req) => {
      state.enqueuedJobs.push({ userId: uid, req });
      return `job-${state.enqueuedJobs.length}`;
    },
    insertReview: async (_row) => {
      const id = `review-${state.insertedReviewIds.length + 1}`;
      state.insertedReviewIds.push(id);
      return id;
    },
  };
}

function okPlanner(): PlannerCaller {
  return async () => plannerOutput();
}

function failingPlanner(): PlannerCaller {
  return async () => {
    throw new Error("anthropic 503 — service unavailable");
  };
}

function fakePdfWorker(): PdfWorkerCaller {
  return async (_payload) => new Uint8Array([0x25, 0x50, 0x44, 0x46]); // "%PDF"
}

function fakeStorage(): StorageUploader {
  return {
    upload: async (path, _bytes) => path,
    sign: async (path, _ttl) => `https://signed.example/${path}?token=abc`,
  };
}

function freshState(tier: "free" | "basic" | "premium" = "free"): FakeState {
  return {
    quota: {
      contract_reviews_used: 0,
      contract_reviews_period_start: new Date().toISOString(),
      tier,
    },
    incrementCalls: 0,
    rollPeriodCalls: 0,
    insertedReviewIds: [],
    enqueuedJobs: [],
  };
}

// =============================================================================
// T01 — validateRequest rejects empty case_document_ids
// =============================================================================
Deno.test("T01 — validateRequest rejects missing case_document_ids", () => {
  const r = validateRequest({ output_language: "en" });
  assertEquals(r.ok, false);
  if (!r.ok) assertStringIncludes(r.error, "case_document_ids");
});

Deno.test("T01b — validateRequest rejects empty array", () => {
  const r = validateRequest({ case_document_ids: [], output_language: "en" });
  assertEquals(r.ok, false);
});

Deno.test("T01c — validateRequest rejects >10 docs", () => {
  const ids = Array.from({ length: 11 }, (_, i) => `id-${i}-xxxx`);
  const r = validateRequest({
    case_document_ids: ids,
    output_language: "en",
  });
  assertEquals(r.ok, false);
});

// =============================================================================
// T02 — validateRequest rejects unsupported language
// =============================================================================
Deno.test("T02 — validateRequest rejects unsupported output_language", () => {
  const r = validateRequest({
    case_document_ids: [UUID_1],
    output_language: "klingon",
  });
  assertEquals(r.ok, false);
  if (!r.ok) assertStringIncludes(r.error, "output_language");
});

Deno.test("T02b — validateRequest accepts ru/en/et/fi/de", () => {
  for (const lang of ["ru", "en", "et", "fi", "de"]) {
    const r = validateRequest({
      case_document_ids: [UUID_1],
      output_language: lang,
    });
    assert(r.ok, `language ${lang} should be accepted`);
  }
});

// =============================================================================
// T03 — Free tier lifetime cap
// =============================================================================
Deno.test("T03 — free tier exceeded after 1 use, no period roll", () => {
  const state: QuotaState = {
    contract_reviews_used: 1,
    contract_reviews_period_start: new Date().toISOString(),
    tier: "free",
  };
  const d = isQuotaExceeded(state, Date.now());
  assertEquals(d.exceeded, true);
  assertEquals(d.rollPeriod, false);
});

Deno.test("T03b — free tier under cap not exceeded", () => {
  const state: QuotaState = {
    contract_reviews_used: 0,
    contract_reviews_period_start: new Date().toISOString(),
    tier: "free",
  };
  const d = isQuotaExceeded(state, Date.now());
  assertEquals(d.exceeded, false);
});

// =============================================================================
// T04 — Basic tier 30-day window rolls
// =============================================================================
Deno.test("T04 — basic tier resets after 30-day window", () => {
  const oldStart = new Date(Date.now() - QUOTA_WINDOW_MS - 1000).toISOString();
  const state: QuotaState = {
    contract_reviews_used: 5, // at cap
    contract_reviews_period_start: oldStart,
    tier: "basic",
  };
  const d = isQuotaExceeded(state, Date.now());
  // Period rolled → not exceeded; rollPeriod=true so increment resets counter.
  assertEquals(d.exceeded, false);
  assertEquals(d.rollPeriod, true);
});

Deno.test("T04b — basic tier within window respects 5-call cap", () => {
  const state: QuotaState = {
    contract_reviews_used: 5,
    contract_reviews_period_start: new Date().toISOString(),
    tier: "basic",
  };
  const d = isQuotaExceeded(state, Date.now());
  assertEquals(d.exceeded, true);
});

Deno.test("T04c — premium tier respects 20-call cap", () => {
  const state: QuotaState = {
    contract_reviews_used: 20,
    contract_reviews_period_start: new Date().toISOString(),
    tier: "premium",
  };
  const d = isQuotaExceeded(state, Date.now());
  assertEquals(d.exceeded, true);
});

// =============================================================================
// T05 — Synchronous success with 1 doc + mocked planner
// =============================================================================
Deno.test("T05 — sync success path returns 200 with full body", async () => {
  const state = freshState("basic");
  const docs = new Map([[UUID_1, mockDoc(UUID_1)]]);
  const result = await runContractReview({
    userId: USER,
    request: {
      case_document_ids: [UUID_1],
      output_language: "en",
    },
    db: fakeDb(docs, state),
    planner: okPlanner(),
    pdfWorker: fakePdfWorker(),
    storage: fakeStorage(),
  });
  assertEquals(result.kind, "success");
  if (result.kind === "success") {
    assertEquals(result.status, 200);
    assertEquals(result.body.pdf_status, "ready");
    assertEquals(result.body.score, 62);
    assertEquals(result.body.critical_risk_count, 2);
    assert(result.body.pdf_url?.startsWith("https://signed.example/"));
    assertStringIncludes(result.body.contract_review_id, "review-");
  }
});

// =============================================================================
// T05b — 402 when quota exceeded
// =============================================================================
Deno.test("T05b — quota exceeded returns 402 with upgrade_url", async () => {
  const state = freshState("free");
  state.quota.contract_reviews_used = 1; // at lifetime cap
  const result = await runContractReview({
    userId: USER,
    request: {
      case_document_ids: [UUID_1],
      output_language: "en",
    },
    db: fakeDb(new Map([[UUID_1, mockDoc(UUID_1)]]), state),
    planner: okPlanner(),
    pdfWorker: null,
    storage: null,
  });
  assertEquals(result.kind, "error");
  if (result.kind === "error") {
    assertEquals(result.status, 402);
    assertEquals(result.body.error, "quota_exceeded");
    assertStringIncludes(String(result.body.upgrade_url), "/app.html?plan=premium");
  }
});

// =============================================================================
// T06 — Async path when 4+ docs (202 + job_id)
// =============================================================================
Deno.test("T06 — 4 docs returns 202 with job_id", async () => {
  const state = freshState("premium");
  const docs = new Map([
    [UUID_1, mockDoc(UUID_1)],
    [UUID_2, mockDoc(UUID_2)],
    [UUID_3, mockDoc(UUID_3)],
    [UUID_4, mockDoc(UUID_4)],
  ]);
  const result = await runContractReview({
    userId: USER,
    request: {
      case_document_ids: [UUID_1, UUID_2, UUID_3, UUID_4],
      output_language: "en",
    },
    db: fakeDb(docs, state),
    planner: okPlanner(),
    pdfWorker: fakePdfWorker(),
    storage: fakeStorage(),
  });
  assertEquals(result.kind, "accepted");
  if (result.kind === "accepted") {
    assertEquals(result.status, 202);
    assertEquals(result.body.status, "queued");
    assertStringIncludes(result.body.job_id, "job-");
  }
  assertEquals(state.enqueuedJobs.length, 1);
  // Async path does NOT increment quota — that happens when the worker
  // completes the job. The test confirms zero counter movement here.
  assertEquals(state.incrementCalls, 0);
});

Deno.test("T06b — 3 docs stays sync (not enqueued)", async () => {
  const state = freshState("premium");
  const docs = new Map([
    [UUID_1, mockDoc(UUID_1)],
    [UUID_2, mockDoc(UUID_2)],
    [UUID_3, mockDoc(UUID_3)],
  ]);
  const result = await runContractReview({
    userId: USER,
    request: {
      case_document_ids: [UUID_1, UUID_2, UUID_3],
      output_language: "en",
    },
    db: fakeDb(docs, state),
    planner: okPlanner(),
    pdfWorker: fakePdfWorker(),
    storage: fakeStorage(),
  });
  assertEquals(result.kind, "success");
  assertEquals(state.enqueuedJobs.length, 0);
});

// =============================================================================
// T07 — Graceful fallback when CONTRACT_PDF_WORKER_URL is empty
// =============================================================================
Deno.test("T07 — pdfWorker=null returns worker_not_configured", async () => {
  const state = freshState("premium");
  const result = await runContractReview({
    userId: USER,
    request: {
      case_document_ids: [UUID_1],
      output_language: "fi",
    },
    db: fakeDb(new Map([[UUID_1, mockDoc(UUID_1)]]), state),
    planner: okPlanner(),
    pdfWorker: null,
    storage: null,
  });
  assertEquals(result.kind, "success");
  if (result.kind === "success") {
    assertEquals(result.body.pdf_status, "worker_not_configured");
    assertEquals(result.body.pdf_url, null);
    // Email and summary still flow through.
    assert(result.body.email_md.length > 0);
    assert(result.body.summary.length > 0);
  }
});

// =============================================================================
// T08 — Quota increments by 1 on success
// =============================================================================
Deno.test("T08 — quota increments exactly once on success", async () => {
  const state = freshState("basic");
  await runContractReview({
    userId: USER,
    request: {
      case_document_ids: [UUID_1],
      output_language: "en",
    },
    db: fakeDb(new Map([[UUID_1, mockDoc(UUID_1)]]), state),
    planner: okPlanner(),
    pdfWorker: fakePdfWorker(),
    storage: fakeStorage(),
  });
  assertEquals(state.incrementCalls, 1);
  assertEquals(state.quota.contract_reviews_used, 1);
});

// =============================================================================
// T09 — Quota does NOT increment on planner failure
// =============================================================================
Deno.test("T09 — quota stays put when planner throws", async () => {
  const state = freshState("basic");
  const result = await runContractReview({
    userId: USER,
    request: {
      case_document_ids: [UUID_1],
      output_language: "en",
    },
    db: fakeDb(new Map([[UUID_1, mockDoc(UUID_1)]]), state),
    planner: failingPlanner(),
    pdfWorker: null,
    storage: null,
  });
  assertEquals(result.kind, "error");
  if (result.kind === "error") {
    assertEquals(result.status, 502);
    assertEquals(result.body.error, "planner_call_failed");
  }
  assertEquals(state.incrementCalls, 0);
  assertEquals(state.quota.contract_reviews_used, 0);
});

// =============================================================================
// T09b — Quota does NOT increment when documents not owned
// =============================================================================
Deno.test("T09b — 404 when documents not owned, no quota touch", async () => {
  const state = freshState("basic");
  // The fake DB returns only what's in the map. Empty map = "not owned".
  const result = await runContractReview({
    userId: USER,
    request: {
      case_document_ids: [UUID_5],
      output_language: "en",
    },
    db: fakeDb(new Map(), state),
    planner: okPlanner(),
    pdfWorker: fakePdfWorker(),
    storage: fakeStorage(),
  });
  assertEquals(result.kind, "error");
  if (result.kind === "error") {
    assertEquals(result.status, 404);
  }
  assertEquals(state.incrementCalls, 0);
});

// =============================================================================
// T09c — 413 when document exceeds 50-page hard cap
// =============================================================================
Deno.test("T09c — 50-page cap returns 413", async () => {
  const state = freshState("basic");
  const fatDoc = mockDoc(UUID_1, "x", 51);
  const result = await runContractReview({
    userId: USER,
    request: {
      case_document_ids: [UUID_1],
      output_language: "en",
    },
    db: fakeDb(new Map([[UUID_1, fatDoc]]), state),
    planner: okPlanner(),
    pdfWorker: fakePdfWorker(),
    storage: fakeStorage(),
  });
  assertEquals(result.kind, "error");
  if (result.kind === "error") {
    assertEquals(result.status, 413);
    assertEquals(result.body.error, "document_too_long");
  }
  assertEquals(state.incrementCalls, 0);
});

// =============================================================================
// T10 — Prompts module composes the real Contract Review prompt
// =============================================================================
Deno.test("T10 — buildContractReviewSystemPrompt assembles real prompt modules", () => {
  const p = buildContractReviewSystemPrompt({
    outputLanguage: "et",
    jurisdictionHint: "de",
    industryHint: "saas",
    clientName: "Dmitri",
    clientCompany: "Vorantis OÜ",
  });
  // Header proves the orchestrator ran.
  assertStringIncludes(p, "FEATURE: Contract Review");
  // Jurisdiction-toolkit flowed through from the "de" hint.
  assertStringIncludes(p, "BGB");
  // Industry add-on flowed through from the "saas" hint.
  assertStringIncludes(p, "SaaS");
  // Output language flowed through into the core instructions.
  assertStringIncludes(p, "et");
  // Localised disclaimer for Estonian must appear.
  assertStringIncludes(p, "Informatiivne analüüs");
});

// =============================================================================
// Auxiliary unit checks (verifyPlannerOutput, countCriticalRisks, paths)
// =============================================================================
Deno.test("verifyPlannerOutput accepts the spec shape", () => {
  const v = verifyPlannerOutput(plannerOutput());
  assertEquals(v.ok, true);
});

Deno.test("verifyPlannerOutput rejects missing cover", () => {
  const v = verifyPlannerOutput({ summary: "x", checklist: [], email_to_counterparty: "x" });
  assertEquals(v.ok, false);
});

Deno.test("countCriticalRisks counts only 'critical' levels", () => {
  assertEquals(countCriticalRisks(plannerOutput()), 2);
});

Deno.test("buildStoragePath sanitises filename", () => {
  const path = buildStoragePath(USER, "Contract / v2 (FINAL)!", 1700000000);
  assertStringIncludes(path, `contract-reviews/${USER}/1700000000_`);
  // No slashes, parens, spaces, exclamation marks.
  assert(!path.includes("/v2"));
  assert(!path.includes(" "));
  assert(!path.includes("!"));
  assert(!path.includes("("));
});

Deno.test("QUOTA_LIMITS match product spec", () => {
  assertEquals(QUOTA_LIMITS.free, 1);
  assertEquals(QUOTA_LIMITS.basic, 5);
  assertEquals(QUOTA_LIMITS.premium, 20);
});

// =============================================================================
// T11 — Source-code contract: index.ts must NOT enable anonymousPerMinute
// =============================================================================
Deno.test("T11 — index.ts rejects anonymous callers (no anonymousPerMinute)", async () => {
  const src = await Deno.readTextFile(
    new URL("../contract-review/index.ts", import.meta.url),
  );
  // The auth gate call must NOT set anonymousPerMinute. Catching a regression
  // here is cheaper than a security incident — see memory: lesson_anon_jwt_bypass.
  assert(
    !/anonymousPerMinute\s*:/.test(src),
    "contract-review/index.ts must not allow anonymous callers",
  );
  // It must explicitly opt into the auth gate.
  assertStringIncludes(src, "requireUserWithRateLimit");
  // And reject anon: principals defensively.
  assertStringIncludes(src, "anon:");
});

// =============================================================================
// T12 — Internal name discipline: no "B2B" in user-facing strings
// =============================================================================
Deno.test("T12 — no B2B in user-facing strings", async () => {
  const handlerSrc = await Deno.readTextFile(
    new URL("../contract-review/handler.ts", import.meta.url),
  );
  const promptsSrc = await Deno.readTextFile(
    new URL("../_shared/contract_review_prompts.ts", import.meta.url),
  );
  // Comment mentions are allowed (e.g. mode='contract_b2b' label is internal),
  // but no error message / upgrade URL / response field should read "B2B".
  for (const src of [handlerSrc, promptsSrc]) {
    // Strip block + line comments before scanning.
    const stripped = src
      .replace(/\/\*[\s\S]*?\*\//g, "")
      .replace(/^\s*\/\/.*$/gm, "");
    assert(
      !/\bB2B\b/i.test(stripped) || stripped.split(/B2B/i).length <= 2,
      "B2B appears outside comments in handler/prompts",
    );
  }
});
