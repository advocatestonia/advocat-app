// contract-review/handler.ts — pure business logic for Contract Review mode.
// Split from index.ts so tests can inject fakes for db / planner / pdfWorker /
// storage / now / uuid. The HTTP layer is a thin shim around runContractReview.

import {
  buildContractReviewSystemPrompt,
  type ContractIndustryHint,
  type ContractJurisdictionHint,
  type ContractReviewOutput,
  SUPPORTED_OUTPUT_LANGUAGES,
} from "../_shared/contract_review_prompts.ts";
import {
  buildCorrectivePrompt,
  checkEmailQuality,
  type EmailQualityReport,
} from "../_shared/email_quality_check.ts";

// ─── Tunables ───────────────────────────────────────────────────────────────

export const MAX_DOCS_SYNC = 3;
export const MAX_DOCS_TOTAL = 10;
export const MAX_PAGES_PER_DOC = 50;

export const QUOTA_LIMITS: Record<SubscriptionTier, number> = {
  free: 1, // lifetime
  basic: 5, // per 30-day window
  premium: 20, // per 30-day window
};

export const QUOTA_WINDOW_MS = 30 * 24 * 60 * 60 * 1000;

export const SIGNED_URL_TTL_SEC = 24 * 60 * 60;

const UPGRADE_URL = "/app.html?plan=premium&billing=monthly";

// ─── Public contracts ───────────────────────────────────────────────────────

export type SubscriptionTier = "free" | "basic" | "premium";

export interface ContractReviewRequest {
  case_document_ids: string[];
  output_language: string;
  /** ISO code of the contract itself; drives the counterparty-email language.
   *  Optional — when omitted, the quality verifier accepts whatever language
   *  the planner detected and produced. */
  original_language?: string;
  jurisdiction_hint?: string;
  industry_hint?: string;
  client_name?: string;
  client_company?: string;
}

export interface ContractReviewSuccess {
  kind: "success";
  status: 200;
  body: {
    pdf_url: string | null;
    email_md: string;
    /** ISO code of the contract's original language — drives the email
     *  preview language badge in the Flutter UI. */
    email_language: string;
    /** Non-blocking warnings from the email quality verifier. Empty when
     *  the verifier passed cleanly on the first try. */
    email_quality_warnings: string[];
    summary: string;
    score: number;
    critical_risk_count: number;
    contract_review_id: string;
    pdf_status: "ready" | "worker_not_configured" | "pending";
  };
}

export interface ContractReviewAccepted {
  kind: "accepted";
  status: 202;
  body: { job_id: string; status: "queued" };
}

export interface ContractReviewError {
  kind: "error";
  status: number;
  body: Record<string, unknown>;
}

export type ContractReviewResult =
  | ContractReviewSuccess
  | ContractReviewAccepted
  | ContractReviewError;

// ─── Dependency interfaces ──────────────────────────────────────────────────

export interface CaseDocumentRow {
  id: string;
  user_id: string;
  filename: string;
  parsed_text: string | null;
  page_count?: number | null;
}

export interface QuotaState {
  contract_reviews_used: number;
  contract_reviews_period_start: string;
  tier: SubscriptionTier;
}

export interface DbClient {
  /** Returns the caller's tier and current quota counters. Returns a zeroed
   * row if nothing exists yet. */
  loadQuota(userId: string): Promise<QuotaState>;
  /** Atomically increment the quota counter, optionally rolling the period. */
  incrementQuota(userId: string, rollPeriod: boolean): Promise<void>;
  /** Load case_documents rows the caller owns. Order matches `ids`. */
  loadOwnedDocuments(
    userId: string,
    ids: string[],
  ): Promise<CaseDocumentRow[]>;
  /** Enqueue an async multi-doc job. Returns the job id. */
  enqueueJob(
    userId: string,
    req: ContractReviewRequest,
  ): Promise<string>;
  /** Persist a finalized review. Returns the new row id. */
  insertReview(row: {
    user_id: string;
    document_ids: string[];
    output_language: string;
    jurisdiction_hint?: string;
    industry_hint?: string;
    client_name?: string;
    client_company?: string;
    score: number;
    critical_risk_count: number;
    summary: string;
    email_md: string;
    pdf_storage_path: string | null;
    pdf_status: "ready" | "worker_not_configured" | "pending" | "failed";
    raw_output: ContractReviewOutput;
  }): Promise<string>;
}

export interface PlannerCaller {
  (req: {
    systemPrompt: string;
    userPrompt: string;
  }): Promise<ContractReviewOutput>;
}

export interface PdfWorkerCaller {
  (payload: ContractReviewOutput): Promise<Uint8Array>;
}

export interface StorageUploader {
  /** Upload bytes; return the stored path (NOT the signed URL). */
  upload(path: string, bytes: Uint8Array): Promise<string>;
  /** Create a signed URL for a previously uploaded path. */
  sign(path: string, ttlSec: number): Promise<string>;
}

export interface RunOptions {
  userId: string;
  request: ContractReviewRequest;
  db: DbClient;
  planner: PlannerCaller;
  /** When null, the worker is treated as not configured and we degrade to a
   *  JSON+email-only response. */
  pdfWorker: PdfWorkerCaller | null;
  /** When pdfWorker is null this can also be null. */
  storage: StorageUploader | null;
  now?: () => number;
  uuid?: () => string;
}

// ─── Validation ─────────────────────────────────────────────────────────────

export function validateRequest(
  raw: unknown,
): { ok: true; value: ContractReviewRequest } | { ok: false; error: string } {
  if (!raw || typeof raw !== "object") {
    return { ok: false, error: "body must be a JSON object" };
  }
  const r = raw as Partial<ContractReviewRequest>;
  if (!Array.isArray(r.case_document_ids) || r.case_document_ids.length === 0) {
    return { ok: false, error: "case_document_ids required (1-10 uuids)" };
  }
  if (r.case_document_ids.length > MAX_DOCS_TOTAL) {
    return {
      ok: false,
      error: `case_document_ids exceeds max ${MAX_DOCS_TOTAL}`,
    };
  }
  for (const id of r.case_document_ids) {
    if (typeof id !== "string" || id.length < 8) {
      return { ok: false, error: "case_document_ids entries must be uuid strings" };
    }
  }
  if (
    typeof r.output_language !== "string" ||
    !SUPPORTED_OUTPUT_LANGUAGES.has(r.output_language)
  ) {
    return {
      ok: false,
      error: `output_language must be one of: ${[...SUPPORTED_OUTPUT_LANGUAGES].join(",")}`,
    };
  }
  return {
    ok: true,
    value: {
      case_document_ids: r.case_document_ids,
      output_language: r.output_language,
      original_language: typeof r.original_language === "string"
        ? r.original_language
        : undefined,
      jurisdiction_hint: typeof r.jurisdiction_hint === "string"
        ? r.jurisdiction_hint
        : undefined,
      industry_hint: typeof r.industry_hint === "string"
        ? r.industry_hint
        : undefined,
      client_name: typeof r.client_name === "string" ? r.client_name : undefined,
      client_company: typeof r.client_company === "string"
        ? r.client_company
        : undefined,
    },
  };
}

// ─── Quota policy ───────────────────────────────────────────────────────────

/** Returns true if the user is over their quota for the current window. */
export function isQuotaExceeded(
  state: QuotaState,
  now: number,
): { exceeded: boolean; rollPeriod: boolean } {
  const limit = QUOTA_LIMITS[state.tier] ?? 0;
  if (state.tier === "free") {
    // Lifetime cap. Period never rolls.
    return { exceeded: state.contract_reviews_used >= limit, rollPeriod: false };
  }
  const periodStart = Date.parse(state.contract_reviews_period_start);
  if (Number.isFinite(periodStart) && now - periodStart > QUOTA_WINDOW_MS) {
    // Window expired — counter resets when we increment.
    return { exceeded: false, rollPeriod: true };
  }
  return {
    exceeded: state.contract_reviews_used >= limit,
    rollPeriod: false,
  };
}

// ─── Output verification ────────────────────────────────────────────────────

/** Defensive verification of the planner's JSON. Rejects clearly malformed
 *  shapes so the API never hands an exception to the client. */
export function verifyPlannerOutput(
  out: unknown,
): { ok: true; value: ContractReviewOutput } | { ok: false; error: string } {
  if (!out || typeof out !== "object") {
    return { ok: false, error: "planner returned non-object" };
  }
  const o = out as Partial<ContractReviewOutput>;
  if (!o.cover || typeof o.cover !== "object") {
    return { ok: false, error: "missing cover" };
  }
  if (typeof o.cover.score !== "number") {
    return { ok: false, error: "cover.score must be number" };
  }
  if (typeof o.summary !== "string" || o.summary.length === 0) {
    return { ok: false, error: "summary missing" };
  }
  if (!Array.isArray(o.checklist)) {
    return { ok: false, error: "checklist missing" };
  }
  if (typeof o.email_to_counterparty !== "string") {
    return { ok: false, error: "email_to_counterparty missing" };
  }
  return { ok: true, value: o as ContractReviewOutput };
}

export function countCriticalRisks(output: ContractReviewOutput): number {
  return output.checklist.filter((c) => c.risk_level === "critical").length;
}

// ─── Storage path builder ───────────────────────────────────────────────────

export function buildStoragePath(
  userId: string,
  contractName: string,
  now: number,
): string {
  const safeName = contractName
    .replace(/[^a-zA-Z0-9_-]/g, "_")
    .slice(0, 80) || "contract";
  return `contract-reviews/${userId}/${now}_${safeName}.pdf`;
}

// ─── Main orchestrator ──────────────────────────────────────────────────────

export async function runContractReview(
  opts: RunOptions,
): Promise<ContractReviewResult> {
  const now = opts.now ?? (() => Date.now());
  const uuid = opts.uuid ?? (() => globalThis.crypto.randomUUID());

  // 1) Quota check ─────────────────────────────────────────────────────────
  const quota = await opts.db.loadQuota(opts.userId);
  const decision = isQuotaExceeded(quota, now());
  if (decision.exceeded) {
    return {
      kind: "error",
      status: 402,
      body: {
        error: "quota_exceeded",
        tier: quota.tier,
        limit: QUOTA_LIMITS[quota.tier],
        used: quota.contract_reviews_used,
        upgrade_url: UPGRADE_URL,
      },
    };
  }

  // 2) Document fetch + ownership ─────────────────────────────────────────
  const docs = await opts.db.loadOwnedDocuments(
    opts.userId,
    opts.request.case_document_ids,
  );
  if (docs.length !== opts.request.case_document_ids.length) {
    return {
      kind: "error",
      status: 404,
      body: {
        error: "documents_not_found_or_not_owned",
        requested: opts.request.case_document_ids.length,
        found: docs.length,
      },
    };
  }
  for (const d of docs) {
    if (d.page_count != null && d.page_count > MAX_PAGES_PER_DOC) {
      return {
        kind: "error",
        status: 413,
        body: {
          error: "document_too_long",
          filename: d.filename,
          page_count: d.page_count,
          max_pages: MAX_PAGES_PER_DOC,
        },
      };
    }
    if (!d.parsed_text || d.parsed_text.trim().length === 0) {
      return {
        kind: "error",
        status: 409,
        body: {
          error: "document_not_parsed",
          filename: d.filename,
          document_id: d.id,
        },
      };
    }
  }

  // 3) Async path when 4+ docs ────────────────────────────────────────────
  if (docs.length > MAX_DOCS_SYNC) {
    const jobId = await opts.db.enqueueJob(opts.userId, opts.request);
    return {
      kind: "accepted",
      status: 202,
      body: { job_id: jobId, status: "queued" },
    };
  }

  // 4) Synchronous path — call planner ────────────────────────────────────
  const systemPrompt = buildContractReviewSystemPrompt({
    outputLanguage: opts.request.output_language,
    jurisdictionHint: opts.request.jurisdiction_hint as ContractJurisdictionHint,
    industryHint: opts.request.industry_hint as ContractIndustryHint,
    clientName: opts.request.client_name,
    clientCompany: opts.request.client_company,
  });
  const userPrompt = buildUserPrompt(docs);

  let plannerOutput: ContractReviewOutput;
  try {
    const raw = await opts.planner({ systemPrompt, userPrompt });
    const v = verifyPlannerOutput(raw);
    if (!v.ok) {
      return {
        kind: "error",
        status: 502,
        body: { error: "planner_output_invalid", details: v.error },
      };
    }
    plannerOutput = v.value;
  } catch (e) {
    return {
      kind: "error",
      status: 502,
      body: {
        error: "planner_call_failed",
        details: String(e).slice(0, 500),
      },
    };
  }

  // 4b) Email quality gate — verify language / loaded words / question count.
  // If the first pass fails, retry ONCE with a corrective prompt; if it
  // still fails, surface the warnings to the client (non-blocking).
  const qualityCheck = await runEmailQualityGate({
    plannerOutput,
    expectedLanguage: opts.request.original_language ??
      opts.request.output_language,
    systemPrompt,
    userPrompt,
    planner: opts.planner,
  });
  plannerOutput = qualityCheck.output;
  const emailLanguage = qualityCheck.report.detected_language === "und"
    ? (opts.request.original_language ?? opts.request.output_language)
    : qualityCheck.report.detected_language;
  const emailQualityWarnings: string[] = qualityCheck.report.issues
    .map((i) => `${i.code}: ${i.message}`);

  // 5) PDF rendering ──────────────────────────────────────────────────────
  let pdfStatus: "ready" | "worker_not_configured" | "pending" = "pending";
  let pdfStoragePath: string | null = null;
  let pdfSignedUrl: string | null = null;

  if (opts.pdfWorker && opts.storage) {
    try {
      const bytes = await opts.pdfWorker(plannerOutput);
      const path = buildStoragePath(
        opts.userId,
        plannerOutput.cover.contract_name || "contract",
        now(),
      );
      pdfStoragePath = await opts.storage.upload(path, bytes);
      pdfSignedUrl = await opts.storage.sign(pdfStoragePath, SIGNED_URL_TTL_SEC);
      pdfStatus = "ready";
    } catch (e) {
      console.warn(
        `[contract-review] pdf render failed: ${String(e).slice(0, 200)}`,
      );
      pdfStatus = "pending";
      pdfStoragePath = null;
      pdfSignedUrl = null;
    }
  } else {
    pdfStatus = "worker_not_configured";
  }

  // 6) Persist review row ─────────────────────────────────────────────────
  let reviewId: string;
  try {
    reviewId = await opts.db.insertReview({
      user_id: opts.userId,
      document_ids: opts.request.case_document_ids,
      output_language: opts.request.output_language,
      jurisdiction_hint: opts.request.jurisdiction_hint,
      industry_hint: opts.request.industry_hint,
      client_name: opts.request.client_name,
      client_company: opts.request.client_company,
      score: plannerOutput.cover.score,
      critical_risk_count: countCriticalRisks(plannerOutput),
      summary: plannerOutput.summary,
      email_md: plannerOutput.email_to_counterparty,
      pdf_storage_path: pdfStoragePath,
      pdf_status: pdfStatus,
      raw_output: plannerOutput,
    });
  } catch (e) {
    return {
      kind: "error",
      status: 500,
      body: {
        error: "persistence_failed",
        details: String(e).slice(0, 500),
      },
    };
  }

  // 7) Increment quota — ONLY on success. ─────────────────────────────────
  try {
    await opts.db.incrementQuota(opts.userId, decision.rollPeriod);
  } catch (e) {
    // Non-fatal — log and continue. The user got their answer; quota will
    // self-correct on the next request (the read is authoritative for limit
    // gating).
    console.warn(
      `[contract-review] quota increment failed: ${String(e).slice(0, 200)}`,
    );
  }

  // Fall back uuid generator if the DB returned an empty string.
  if (!reviewId) reviewId = uuid();

  return {
    kind: "success",
    status: 200,
    body: {
      pdf_url: pdfSignedUrl,
      email_md: plannerOutput.email_to_counterparty,
      email_language: emailLanguage,
      email_quality_warnings: emailQualityWarnings,
      summary: plannerOutput.summary,
      score: plannerOutput.cover.score,
      critical_risk_count: countCriticalRisks(plannerOutput),
      contract_review_id: reviewId,
      pdf_status: pdfStatus,
    },
  };
}

/** Run the email quality verifier. On failure, retry the planner ONCE with
 *  a corrective prompt; if the retry also fails, surface the warnings and
 *  return whichever output was best. Never throws — the worst case is the
 *  client gets the original email plus a warning list. */
async function runEmailQualityGate(opts: {
  plannerOutput: ContractReviewOutput;
  expectedLanguage: string;
  systemPrompt: string;
  userPrompt: string;
  planner: PlannerCaller;
}): Promise<{ output: ContractReviewOutput; report: EmailQualityReport }> {
  const first = checkEmailQuality({
    email: opts.plannerOutput.email_to_counterparty,
    expectedLanguage: opts.expectedLanguage,
  });
  if (first.ok) return { output: opts.plannerOutput, report: first };

  // One corrective retry. Surface the issue list to the model and ask it
  // to regenerate only the email_to_counterparty field.
  try {
    const corrective = buildCorrectivePrompt(first);
    const retried = await opts.planner({
      systemPrompt: opts.systemPrompt,
      userPrompt: `${opts.userPrompt}\n\n<retry>${corrective}</retry>`,
    });
    const v = verifyPlannerOutput(retried);
    if (v.ok) {
      const second = checkEmailQuality({
        email: v.value.email_to_counterparty,
        expectedLanguage: opts.expectedLanguage,
      });
      if (second.ok) return { output: v.value, report: second };
      // Retry still failed — return retry output but keep the second
      // report so the client can show the warnings.
      return { output: v.value, report: second };
    }
  } catch (e) {
    console.warn(
      `[contract-review] email quality retry failed: ${String(e).slice(0, 200)}`,
    );
  }
  // Retry path errored or verifier still failed — return the original
  // output with the first report so the user sees the warnings.
  return { output: opts.plannerOutput, report: first };
}

/** Compose the user-message payload for the planner. */
export function buildUserPrompt(docs: CaseDocumentRow[]): string {
  const parts: string[] = [
    "<contracts>",
  ];
  docs.forEach((d, i) => {
    parts.push(`<contract index="${i + 1}" filename="${d.filename}">`);
    parts.push(d.parsed_text ?? "");
    parts.push("</contract>");
  });
  parts.push("</contracts>");
  parts.push("");
  parts.push(
    "Produce a single JSON object matching the ContractReviewOutput shape. Do not wrap it in code fences.",
  );
  return parts.join("\n");
}
