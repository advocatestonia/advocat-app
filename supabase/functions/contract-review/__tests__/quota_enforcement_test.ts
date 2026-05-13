// Deno tests for contract-review quota enforcement (Pkg Contract Review).
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/contract-review/__tests__/quota_enforcement_test.ts
//
// Scope: pins the three-tier quota policy and the runContractReview()
// 402 response shape against a fake DbClient whose behaviour mirrors the
// real `user_quotas` schema in migration 20260513130000.
//
// Free        : 1 lifetime hard wall (no period roll, no second review).
// Counsel/Basic: 5 per 30-day rolling window (period rolls when expired).
// Pro/Premium  : 20 per 30-day rolling window (period rolls when expired).
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  type CaseDocumentRow,
  type ContractReviewRequest,
  type DbClient,
  isQuotaExceeded,
  QUOTA_LIMITS,
  QUOTA_WINDOW_MS,
  type QuotaState,
  runContractReview,
  type SubscriptionTier,
} from "../handler.ts";
import type { ContractReviewOutput } from "../../_shared/contract_review_prompts.ts";

// ─── Fake DbClient — mirrors the real user_quotas schema semantics ──────────

interface FakeQuotaRow {
  used: number;
  periodStart: string;
}

class FakeDb implements DbClient {
  // Quota rows keyed by user id (mirrors user_quotas PK).
  readonly quotas = new Map<string, FakeQuotaRow>();
  // Tier resolution table (mirrors what detectTier() does in index.ts).
  readonly tiers = new Map<string, SubscriptionTier>();
  // Document store (mirrors case_documents).
  readonly docs = new Map<string, CaseDocumentRow>();
  // Captured side effects so tests can assert on them.
  readonly insertedReviews: Array<Record<string, unknown>> = [];
  readonly enqueuedJobs: Array<{ userId: string; req: ContractReviewRequest }> = [];

  constructor(opts: {
    quotas?: Record<string, FakeQuotaRow>;
    tiers?: Record<string, SubscriptionTier>;
    docs?: CaseDocumentRow[];
  } = {}) {
    if (opts.quotas) {
      for (const [k, v] of Object.entries(opts.quotas)) {
        this.quotas.set(k, { ...v });
      }
    }
    if (opts.tiers) {
      for (const [k, v] of Object.entries(opts.tiers)) {
        this.tiers.set(k, v);
      }
    }
    if (opts.docs) {
      for (const d of opts.docs) this.docs.set(d.id, d);
    }
  }

  loadQuota(userId: string): Promise<QuotaState> {
    const row = this.quotas.get(userId);
    const tier = this.tiers.get(userId) ?? "free";
    if (!row) {
      return Promise.resolve({
        contract_reviews_used: 0,
        contract_reviews_period_start: new Date().toISOString(),
        tier,
      });
    }
    return Promise.resolve({
      contract_reviews_used: row.used,
      contract_reviews_period_start: row.periodStart,
      tier,
    });
  }

  incrementQuota(userId: string, rollPeriod: boolean): Promise<void> {
    const existing = this.quotas.get(userId);
    if (!existing) {
      this.quotas.set(userId, {
        used: 1,
        periodStart: new Date().toISOString(),
      });
      return Promise.resolve();
    }
    const next = rollPeriod ? 1 : existing.used + 1;
    this.quotas.set(userId, {
      used: next,
      periodStart: rollPeriod ? new Date().toISOString() : existing.periodStart,
    });
    return Promise.resolve();
  }

  loadOwnedDocuments(
    userId: string,
    ids: string[],
  ): Promise<CaseDocumentRow[]> {
    const out: CaseDocumentRow[] = [];
    for (const id of ids) {
      const d = this.docs.get(id);
      if (d && d.user_id === userId) out.push(d);
    }
    return Promise.resolve(out);
  }

  enqueueJob(
    userId: string,
    req: ContractReviewRequest,
  ): Promise<string> {
    this.enqueuedJobs.push({ userId, req });
    return Promise.resolve(`job-${this.enqueuedJobs.length}`);
  }

  insertReview(row: Record<string, unknown>): Promise<string> {
    this.insertedReviews.push(row);
    return Promise.resolve(`rev-${this.insertedReviews.length}`);
  }
}

function fakeDoc(id: string, userId: string): CaseDocumentRow {
  return {
    id,
    user_id: userId,
    filename: `${id}.pdf`,
    parsed_text: "Sample contract text long enough to be non-empty.",
    page_count: 3,
  };
}

function fakeRequest(docIds: string[]): ContractReviewRequest {
  return {
    case_document_ids: docIds,
    output_language: "en",
  };
}

function fakePlannerOutput(): ContractReviewOutput {
  return {
    cover: {
      contract_name: "NDA-2026",
      counterparty: "Acme Oy",
      client_role: "Receiving Party",
      jurisdiction: "FI",
      score: 72,
    },
    summary: "Mostly fair NDA with one critical risk.",
    checklist: [
      {
        clause: "Indemnification",
        risk_level: "critical",
        finding: "Unilateral, no cap.",
        recommendation: "Add mutual indemnification and a cap at fees paid.",
      },
      {
        clause: "Term",
        risk_level: "low",
        finding: "Two-year term — normal.",
        recommendation: "OK.",
      },
    ],
    email_to_counterparty: "Dear Acme, please review clauses 4 and 7. — Best",
  };
}

// ─── isQuotaExceeded — pure policy tests ────────────────────────────────────

Deno.test("CR-Q01 — free tier: 0 used → not exceeded", () => {
  const state: QuotaState = {
    contract_reviews_used: 0,
    contract_reviews_period_start: new Date().toISOString(),
    tier: "free",
  };
  const d = isQuotaExceeded(state, Date.now());
  assertEquals(d.exceeded, false);
  assertEquals(d.rollPeriod, false);
});

Deno.test("CR-Q02 — free tier: 1 used → exceeded (lifetime wall)", () => {
  const state: QuotaState = {
    contract_reviews_used: 1,
    contract_reviews_period_start: new Date().toISOString(),
    tier: "free",
  };
  const d = isQuotaExceeded(state, Date.now());
  assertEquals(d.exceeded, true);
  assertEquals(
    d.rollPeriod,
    false,
    "free tier MUST NEVER roll the period — lifetime cap",
  );
});

Deno.test("CR-Q03 — free tier: 1 used, 60 days later → still exceeded", () => {
  // Free is a lifetime cap. Even after the window would have rolled on
  // basic/premium, free stays denied.
  const periodStart = new Date(Date.now() - 60 * 24 * 3600 * 1000).toISOString();
  const state: QuotaState = {
    contract_reviews_used: 1,
    contract_reviews_period_start: periodStart,
    tier: "free",
  };
  const d = isQuotaExceeded(state, Date.now());
  assertEquals(d.exceeded, true);
  assertEquals(d.rollPeriod, false);
});

Deno.test("CR-Q04 — basic (Counsel): 4 used in window → not exceeded", () => {
  const state: QuotaState = {
    contract_reviews_used: 4,
    contract_reviews_period_start: new Date().toISOString(),
    tier: "basic",
  };
  const d = isQuotaExceeded(state, Date.now());
  assertEquals(d.exceeded, false);
  assertEquals(d.rollPeriod, false);
});

Deno.test("CR-Q05 — basic (Counsel): 5 used in window → exceeded", () => {
  const state: QuotaState = {
    contract_reviews_used: 5,
    contract_reviews_period_start: new Date().toISOString(),
    tier: "basic",
  };
  const d = isQuotaExceeded(state, Date.now());
  assertEquals(d.exceeded, true);
  assertEquals(d.rollPeriod, false);
});

Deno.test("CR-Q06 — basic: 5 used but period expired → not exceeded, roll", () => {
  const periodStart = new Date(
    Date.now() - QUOTA_WINDOW_MS - 60_000,
  ).toISOString();
  const state: QuotaState = {
    contract_reviews_used: 5,
    contract_reviews_period_start: periodStart,
    tier: "basic",
  };
  const d = isQuotaExceeded(state, Date.now());
  assertEquals(d.exceeded, false, "Expired window must reset the counter");
  assertEquals(d.rollPeriod, true);
});

Deno.test("CR-Q07 — premium (Pro): 19 used → not exceeded", () => {
  const state: QuotaState = {
    contract_reviews_used: 19,
    contract_reviews_period_start: new Date().toISOString(),
    tier: "premium",
  };
  const d = isQuotaExceeded(state, Date.now());
  assertEquals(d.exceeded, false);
});

Deno.test("CR-Q08 — premium: 20 used → exceeded", () => {
  const state: QuotaState = {
    contract_reviews_used: 20,
    contract_reviews_period_start: new Date().toISOString(),
    tier: "premium",
  };
  const d = isQuotaExceeded(state, Date.now());
  assertEquals(d.exceeded, true);
  assertEquals(d.rollPeriod, false);
});

Deno.test("CR-Q09 — QUOTA_LIMITS contract is locked (free=1 basic=5 premium=20)", () => {
  // Pinning these values prevents accidental edits — pricing copy in
  // subscription_screen.dart relies on them.
  assertEquals(QUOTA_LIMITS.free, 1);
  assertEquals(QUOTA_LIMITS.basic, 5);
  assertEquals(QUOTA_LIMITS.premium, 20);
});

// ─── runContractReview integration tests ────────────────────────────────────

Deno.test("CR-Q10 — free user with 1 used hits 402 with quota_exceeded body", async () => {
  const db = new FakeDb({
    tiers: { "user-1": "free" },
    quotas: {
      "user-1": { used: 1, periodStart: new Date().toISOString() },
    },
    docs: [fakeDoc("doc-1", "user-1")],
  });

  let plannerCalled = false;
  const result = await runContractReview({
    userId: "user-1",
    request: fakeRequest(["doc-1"]),
    db,
    planner: async () => {
      plannerCalled = true;
      return fakePlannerOutput();
    },
    pdfWorker: null,
    storage: null,
  });

  assertEquals(result.kind, "error");
  if (result.kind === "error") {
    assertEquals(result.status, 402);
    assertEquals(result.body.error, "quota_exceeded");
    assertEquals(result.body.tier, "free");
    assertEquals(result.body.limit, 1);
    assertEquals(result.body.used, 1);
    assertExists(result.body.upgrade_url);
  }
  assertEquals(plannerCalled, false, "Quota gate must short-circuit before planner");
  assertEquals(db.insertedReviews.length, 0);
});

Deno.test("CR-Q11 — free user with 0 used succeeds + counter goes to 1", async () => {
  const db = new FakeDb({
    tiers: { "user-2": "free" },
    docs: [fakeDoc("doc-2", "user-2")],
  });

  const result = await runContractReview({
    userId: "user-2",
    request: fakeRequest(["doc-2"]),
    db,
    planner: () => Promise.resolve(fakePlannerOutput()),
    pdfWorker: null,
    storage: null,
  });

  assertEquals(result.kind, "success");
  assertEquals(db.quotas.get("user-2")?.used, 1);
});

Deno.test("CR-Q12 — basic user at limit (5) hits 402 with tier=basic", async () => {
  const db = new FakeDb({
    tiers: { "user-3": "basic" },
    quotas: {
      "user-3": { used: 5, periodStart: new Date().toISOString() },
    },
    docs: [fakeDoc("doc-3", "user-3")],
  });

  const result = await runContractReview({
    userId: "user-3",
    request: fakeRequest(["doc-3"]),
    db,
    planner: () => Promise.resolve(fakePlannerOutput()),
    pdfWorker: null,
    storage: null,
  });

  assertEquals(result.kind, "error");
  if (result.kind === "error") {
    assertEquals(result.status, 402);
    assertEquals(result.body.tier, "basic");
    assertEquals(result.body.limit, 5);
  }
});

Deno.test("CR-Q13 — premium user at limit (20) hits 402 with tier=premium", async () => {
  const db = new FakeDb({
    tiers: { "user-4": "premium" },
    quotas: {
      "user-4": { used: 20, periodStart: new Date().toISOString() },
    },
    docs: [fakeDoc("doc-4", "user-4")],
  });

  const result = await runContractReview({
    userId: "user-4",
    request: fakeRequest(["doc-4"]),
    db,
    planner: () => Promise.resolve(fakePlannerOutput()),
    pdfWorker: null,
    storage: null,
  });

  assertEquals(result.kind, "error");
  if (result.kind === "error") {
    assertEquals(result.status, 402);
    assertEquals(result.body.tier, "premium");
    assertEquals(result.body.limit, 20);
  }
});

Deno.test("CR-Q14 — basic user past window rolls period and uses 1/5", async () => {
  // Mirrors the real schema flow: contract_reviews_period_start expired,
  // so the function should accept the call, persist a row, AND write the
  // counter as 1 with a fresh periodStart.
  const oldPeriod = new Date(
    Date.now() - QUOTA_WINDOW_MS - 5_000,
  ).toISOString();
  const db = new FakeDb({
    tiers: { "user-5": "basic" },
    quotas: { "user-5": { used: 5, periodStart: oldPeriod } },
    docs: [fakeDoc("doc-5", "user-5")],
  });

  const result = await runContractReview({
    userId: "user-5",
    request: fakeRequest(["doc-5"]),
    db,
    planner: () => Promise.resolve(fakePlannerOutput()),
    pdfWorker: null,
    storage: null,
  });

  assertEquals(result.kind, "success");
  const row = db.quotas.get("user-5");
  assertExists(row);
  assertEquals(row!.used, 1, "Counter must reset to 1 after period roll");
  assert(row!.periodStart > oldPeriod, "periodStart must move forward");
});

Deno.test("CR-Q15 — quota gate is server-side (single source of truth)", async () => {
  // No FREE upgrade credit: the lifetime trial must not be repeatable.
  // We simulate a user who already used their free review, then tier=basic
  // via Stripe checkout. They should now get 5 fresh basic reviews.
  // (Period reset is performed by the stripe webhook hook — tested separately.)
  const db = new FakeDb({
    tiers: { "user-6": "basic" },
    // Webhook reset periodStart to now() and used=0 (see stripe-webhook test).
    quotas: { "user-6": { used: 0, periodStart: new Date().toISOString() } },
    docs: [fakeDoc("doc-6", "user-6")],
  });

  const result = await runContractReview({
    userId: "user-6",
    request: fakeRequest(["doc-6"]),
    db,
    planner: () => Promise.resolve(fakePlannerOutput()),
    pdfWorker: null,
    storage: null,
  });
  assertEquals(result.kind, "success");
  assertEquals(db.quotas.get("user-6")?.used, 1);
});

Deno.test("CR-Q16 — 402 response carries upgrade_url deeplink", async () => {
  const db = new FakeDb({
    tiers: { "user-7": "free" },
    quotas: {
      "user-7": { used: 1, periodStart: new Date().toISOString() },
    },
    docs: [fakeDoc("doc-7", "user-7")],
  });

  const result = await runContractReview({
    userId: "user-7",
    request: fakeRequest(["doc-7"]),
    db,
    planner: () => Promise.resolve(fakePlannerOutput()),
    pdfWorker: null,
    storage: null,
  });

  if (result.kind !== "error") throw new Error("expected error");
  const url = result.body.upgrade_url as string;
  assert(
    url.includes("plan=premium") || url.includes("plan=basic"),
    `upgrade_url should be a tier deep-link, got: ${url}`,
  );
});
