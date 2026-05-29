// contract-review/index.ts — HTTP entry for the Contract Review mode.
// -----------------------------------------------------------------------------
// Internal name: Contract Review (never "B2B" in any user-facing string).
//
// Responsibilities (thin shim):
//   - parse + validate JSON body
//   - require user JWT (never accept anon-only — see memory: lesson_anon_jwt_bypass)
//   - build DB / planner / PDF-worker / storage dependencies
//   - delegate to handler.runContractReview()
//   - serialize the structured result back to a Response with CORS headers
//
// All business logic lives in handler.ts so unit tests can inject fakes for
// each dependency. The HTTP layer here is intentionally boring — review it
// once, never touch again.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import type { ContractReviewOutput } from "../_shared/contract_review_prompts.ts";
import {
  type CaseDocumentRow,
  type ContractReviewRequest,
  type DbClient,
  type PdfWorkerCaller,
  type PlannerCaller,
  type QuotaState,
  runContractReview,
  type StorageUploader,
  type SubscriptionTier,
  validateRequest,
} from "./handler.ts";
import {
  contractReviewDisabledResponse,
  flagOn,
} from "../_shared/kill_switches.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANTHROPIC_API_KEY = Deno.env.get("CLAUDE_API_KEY") ??
  Deno.env.get("ANTHROPIC_API_KEY");
const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";
const ANTHROPIC_MODEL = "claude-sonnet-4-6";
const ANTHROPIC_MAX_TOKENS = 16384;

const PDF_WORKER_URL = Deno.env.get("CONTRACT_PDF_WORKER_URL") ?? "";
const PDF_WORKER_SECRET = Deno.env.get("CONTRACT_PDF_WORKER_SECRET") ?? "";

const STORAGE_BUCKET = "contract-reviews";

// Upstream timeouts — without an AbortSignal a hung upstream pins the isolate
// while the (paying) user waits. Anthropic gets a generous budget for the long
// review generation; the Typst PDF worker is fast.
const ANTHROPIC_FETCH_TIMEOUT_MS = 120_000;
const PDF_WORKER_FETCH_TIMEOUT_MS = 30_000;

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // Kill switch: CONTRACT_REVIEW_DISABLED — short-circuit before auth/DB.
  // See _shared/kill_switches.ts and /tmp/hn_launch_runbook.md.
  if (flagOn("CONTRACT_REVIEW_DISABLED")) {
    return contractReviewDisabledResponse();
  }

  // Auth — user JWT required, anon NEVER accepted.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "contract-review",
    maxPerMinute: 5,
    // anonymousPerMinute intentionally omitted → unauthenticated callers get 401.
  });
  if (gate.kind === "deny") return gate.response;
  const userId = gate.user.id;
  if (userId.startsWith("anon:")) {
    return jsonError("Unauthorized", 401);
  }

  // Parse body.
  let raw: unknown;
  try {
    raw = await req.json();
  } catch {
    return jsonError("Invalid JSON body", 400);
  }
  const parsed = validateRequest(raw);
  if (!parsed.ok) {
    return jsonError(parsed.error, 400);
  }

  // Build dependencies.
  const sbAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  const db: DbClient = buildDbClient(sbAdmin);
  const planner: PlannerCaller = buildPlannerCaller();
  const pdfWorker: PdfWorkerCaller | null = PDF_WORKER_URL && PDF_WORKER_SECRET
    ? buildPdfWorkerCaller()
    : null;
  const storage: StorageUploader | null = pdfWorker
    ? buildStorageUploader(sbAdmin)
    : null;

  try {
    const result = await runContractReview({
      userId,
      request: parsed.value,
      db,
      planner,
      pdfWorker,
      storage,
    });
    if (result.kind === "success") return jsonOk(result.body, 200);
    if (result.kind === "accepted") return jsonOk(result.body, 202);
    return new Response(JSON.stringify(result.body), {
      status: result.status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("[contract-review] unhandled:", e);
    return jsonError("Internal error", 500);
  }
});

// ─── DB binding ─────────────────────────────────────────────────────────────

// We sidestep the @supabase/supabase-js generic types here. The strict schema
// generics in 2.39.x don't match our untyped `from()` call sites and we don't
// generate a typed schema (supabase-js gen) in this repo. Using `any` is
// explicit, contained to this file, and matches the pattern in support-ticket
// + check-ai-quota.
// deno-lint-ignore no-explicit-any
type AdminClient = any;

function buildDbClient(sb: AdminClient): DbClient {
  return {
    async loadQuota(userId: string): Promise<QuotaState> {
      // Tier resolution (mirrors check-ai-quota pattern).
      const tier = await detectTier(sb, userId);
      const { data } = await sb
        .from("user_quotas")
        .select("contract_reviews_used, contract_reviews_period_start")
        .eq("user_id", userId)
        .maybeSingle();
      if (data) {
        return {
          contract_reviews_used: (data.contract_reviews_used as number) ?? 0,
          contract_reviews_period_start:
            (data.contract_reviews_period_start as string) ??
              new Date().toISOString(),
          tier,
        };
      }
      // No quota row yet — return zeroed state. The increment writes it.
      return {
        contract_reviews_used: 0,
        contract_reviews_period_start: new Date().toISOString(),
        tier,
      };
    },

    async incrementQuota(userId: string, rollPeriod: boolean): Promise<void> {
      // Upsert pattern: read-modify-write inside one statement-ish flow.
      // We rely on the row's per-user PK uniqueness; on conflict we use
      // an UPDATE keyed by user_id. The race window is small (single-user,
      // human-paced) and the failure mode (over-count by 1) is acceptable.
      const nowIso = new Date().toISOString();
      const existing = await sb
        .from("user_quotas")
        .select("contract_reviews_used")
        .eq("user_id", userId)
        .maybeSingle();
      if (!existing.data) {
        await sb.from("user_quotas").insert({
          user_id: userId,
          contract_reviews_used: 1,
          contract_reviews_period_start: nowIso,
        });
        return;
      }
      const prev = (existing.data.contract_reviews_used as number) ?? 0;
      const next = rollPeriod ? 1 : prev + 1;
      const update: Record<string, unknown> = {
        contract_reviews_used: next,
        updated_at: nowIso,
      };
      if (rollPeriod) update.contract_reviews_period_start = nowIso;
      await sb.from("user_quotas").update(update).eq("user_id", userId);
    },

    async loadOwnedDocuments(
      userId: string,
      ids: string[],
    ): Promise<CaseDocumentRow[]> {
      const { data, error } = await sb
        .from("case_documents")
        .select("id, user_id, filename, parsed_text, key_extractions")
        .eq("user_id", userId)
        .in("id", ids);
      if (error) throw new Error(`case_documents query failed: ${error.message}`);
      // Order to match the request order — Supabase doesn't guarantee it.
      const byId = new Map<string, CaseDocumentRow>();
      for (const row of (data ?? []) as Record<string, unknown>[]) {
        const ext = row.key_extractions as Record<string, unknown> | null;
        const pageCount = ext && typeof ext.page_count === "number"
          ? (ext.page_count as number)
          : null;
        byId.set(row.id as string, {
          id: row.id as string,
          user_id: row.user_id as string,
          filename: row.filename as string,
          parsed_text: (row.parsed_text as string | null) ?? null,
          page_count: pageCount,
        });
      }
      const ordered: CaseDocumentRow[] = [];
      for (const id of ids) {
        const r = byId.get(id);
        if (r) ordered.push(r);
      }
      return ordered;
    },

    async enqueueJob(
      userId: string,
      r: ContractReviewRequest,
    ): Promise<string> {
      const { data, error } = await sb
        .from("contract_analysis_jobs")
        .insert({
          user_id: userId,
          document_ids: r.case_document_ids,
          output_language: r.output_language,
          jurisdiction_hint: r.jurisdiction_hint,
          industry_hint: r.industry_hint,
          client_name: r.client_name,
          client_company: r.client_company,
          status: "queued",
        })
        .select("id")
        .single();
      if (error || !data) {
        throw new Error(
          `enqueue failed: ${error?.message ?? "no data"}`,
        );
      }
      return data.id as string;
    },

    async insertReview(row): Promise<string> {
      const { data, error } = await sb
        .from("contract_reviews")
        .insert(row)
        .select("id")
        .single();
      if (error || !data) {
        throw new Error(
          `insert contract_reviews failed: ${error?.message ?? "no data"}`,
        );
      }
      return data.id as string;
    },
  };
}

async function detectTier(
  sb: AdminClient,
  userId: string,
): Promise<SubscriptionTier> {
  // Premium = plan === 'premium' && active/trialing.
  // Basic   = plan === 'basic'   && active/trialing.
  // Otherwise free.
  try {
    const sub = await sb
      .from("subscriptions")
      .select("status, plan")
      .eq("user_id", userId)
      .in("status", ["active", "trialing"])
      .limit(1)
      .maybeSingle();
    const plan = (sub.data as { plan?: string } | null)?.plan;
    if (plan === "premium") return "premium";
    if (plan === "basic") return "basic";
    // Some legacy rows: any active subscription without plan => basic.
    if (sub.data) return "basic";
  } catch (_) {
    /* fall through */
  }
  return "free";
}

// ─── Anthropic planner binding ──────────────────────────────────────────────

function buildPlannerCaller(): PlannerCaller {
  return async (req): Promise<ContractReviewOutput> => {
    if (!ANTHROPIC_API_KEY) {
      throw new Error("CLAUDE_API_KEY not configured");
    }
    const res = await fetch(ANTHROPIC_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: ANTHROPIC_MODEL,
        max_tokens: ANTHROPIC_MAX_TOKENS,
        temperature: 0.0,
        system: req.systemPrompt,
        messages: [{ role: "user", content: req.userPrompt }],
      }),
      signal: AbortSignal.timeout(ANTHROPIC_FETCH_TIMEOUT_MS),
    });
    if (!res.ok) {
      const err = await res.text();
      throw new Error(`Anthropic ${res.status}: ${err.slice(0, 200)}`);
    }
    const json = await res.json() as {
      content?: Array<{ type: string; text?: string }>;
    };
    const text = (json.content ?? [])
      .filter((b) => b.type === "text" && typeof b.text === "string")
      .map((b) => b.text!)
      .join("");
    // Tolerate code fences if the model emits them despite the instruction.
    const stripped = text
      .replace(/^\s*```(?:json)?\s*/i, "")
      .replace(/\s*```\s*$/i, "")
      .trim();
    try {
      return JSON.parse(stripped) as ContractReviewOutput;
    } catch (e) {
      throw new Error(
        `planner returned non-JSON: ${String(e).slice(0, 100)} :: head=${stripped.slice(0, 120)}`,
      );
    }
  };
}

// ─── PDF worker binding (Typst, deployed in parallel task) ──────────────────

function buildPdfWorkerCaller(): PdfWorkerCaller {
  return async (payload) => {
    const res = await fetch(PDF_WORKER_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${PDF_WORKER_SECRET}`,
      },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(PDF_WORKER_FETCH_TIMEOUT_MS),
    });
    if (!res.ok) {
      const err = await res.text();
      throw new Error(
        `pdf worker ${res.status}: ${err.slice(0, 200)}`,
      );
    }
    const buf = await res.arrayBuffer();
    return new Uint8Array(buf);
  };
}

// ─── Storage binding ────────────────────────────────────────────────────────

function buildStorageUploader(sb: AdminClient): StorageUploader {
  return {
    async upload(path: string, bytes: Uint8Array): Promise<string> {
      // Strip the bucket prefix from the path before sending to .upload(),
      // since the Storage API takes the bucket separately.
      const relative = path.startsWith(`${STORAGE_BUCKET}/`)
        ? path.slice(STORAGE_BUCKET.length + 1)
        : path;
      const { error } = await sb.storage
        .from(STORAGE_BUCKET)
        .upload(relative, bytes, {
          contentType: "application/pdf",
          upsert: true,
        });
      if (error) throw new Error(`storage upload failed: ${error.message}`);
      return path;
    },
    async sign(path: string, ttlSec: number): Promise<string> {
      const relative = path.startsWith(`${STORAGE_BUCKET}/`)
        ? path.slice(STORAGE_BUCKET.length + 1)
        : path;
      const { data, error } = await sb.storage
        .from(STORAGE_BUCKET)
        .createSignedUrl(relative, ttlSec);
      if (error || !data?.signedUrl) {
        throw new Error(
          `storage sign failed: ${error?.message ?? "no url"}`,
        );
      }
      return data.signedUrl;
    },
  };
}
