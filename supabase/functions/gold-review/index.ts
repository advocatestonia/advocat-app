// gold-review/index.ts — Sofia's admin endpoint for the Gold Corpus.
// ----------------------------------------------------------------------------
// Auth: caller MUST present an end-user JWT whose user_id is in the
// GOLD_REVIEWER_IDS env var (comma-separated UUIDs). Sofia + Dmitri at
// launch. The function then uses the service-role key for the actual DB
// writes — RLS is service-role-only on both tables.
//
// HTTP API (REST-ish; method + path):
//   GET  /gold-review/queue?limit=20&offset=0      list pending-review rows
//   GET  /gold-review/stats                        gold_corpus_stats view
//   POST /gold-review/decide                       create a pair / record decision
//
// POST /gold-review/decide body shape:
//   { queue_id, status: 'approved'|'edited'|'rejected'|'skipped',
//     gold_answer?, rejection_reason?, reviewer_notes? }
//
// Effect by status:
//   approved → insert pair with gold_answer = ai_answer (from queue),
//              edit_similarity = 1.0
//   edited   → insert pair with provided gold_answer, edit_similarity
//              computed via lightweight Levenshtein-based ratio (no external
//              API call needed — kept synchronous so the UI advances fast).
//   rejected → insert pair with gold_answer=NULL, rejection_reason required
//   skipped  → no pair inserted; queue row marked added_to_pairs=true
// ----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, jsonError, jsonOk } from "../_shared/auth.ts";
import {
  clampInt,
  editSimilarity,
  estimateTokens,
  isUuid,
  parseReviewerIds,
  parseTotalFromContentRange,
} from "./pure.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const REVIEWER_IDS = parseReviewerIds(Deno.env.get("GOLD_REVIEWER_IDS"));

const VALID_STATUS = new Set(["approved", "edited", "rejected", "skipped"]);
const VALID_REJECTION = new Set([
  "wrong_law",
  "hallucination",
  "wrong_tone",
  "off_topic",
  "outdated",
  "other",
]);

interface DecideBody {
  queue_id?: string;
  status?: string;
  gold_answer?: string;
  rejection_reason?: string;
  reviewer_notes?: string;
}

// ─── Reviewer gate ──────────────────────────────────────────────────────────

/**
 * Returns the gate result. Pure-ish (only consults env-loaded constants and
 * supabase auth.getUser). Exported for tests.
 */
export async function gateReviewer(req: Request): Promise<
  | { allow: false; response: Response }
  | { allow: true; userId: string }
> {
  const auth = req.headers.get("authorization") ?? "";
  const m = auth.match(/^Bearer (.+)$/i);
  if (!m) {
    return { allow: false, response: jsonError("missing bearer", 401) };
  }
  if (REVIEWER_IDS.size === 0) {
    return {
      allow: false,
      response: jsonError("reviewer allowlist not configured", 503),
    };
  }
  try {
    const supa = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const { data, error } = await supa.auth.getUser(m[1]);
    if (error || !data?.user) {
      return { allow: false, response: jsonError("invalid session", 401) };
    }
    const uid = String(data.user.id).toLowerCase();
    if (!REVIEWER_IDS.has(uid)) {
      return { allow: false, response: jsonError("forbidden", 403) };
    }
    return { allow: true, userId: data.user.id };
  } catch (e) {
    return {
      allow: false,
      response: jsonError(`auth backend: ${String(e).slice(0, 100)}`, 503),
    };
  }
}

// ─── Handlers ───────────────────────────────────────────────────────────────

async function handleQueueList(url: URL): Promise<Response> {
  const limit = clampInt(url.searchParams.get("limit"), 1, 100, 20);
  const offset = clampInt(url.searchParams.get("offset"), 0, 10_000, 0);
  const lang = url.searchParams.get("language") ?? null;
  const cat = url.searchParams.get("category") ?? null;
  const jur = url.searchParams.get("jurisdiction") ?? null;

  const params: string[] = [
    "pii_scrubbed=eq.true",
    "added_to_pairs=eq.false",
    `order=created_at.desc`,
    `limit=${limit}`,
    `offset=${offset}`,
  ];
  if (lang) params.push(`language=eq.${encodeURIComponent(lang)}`);
  if (cat) params.push(`category=eq.${encodeURIComponent(cat)}`);
  if (jur) params.push(`jurisdiction=eq.${encodeURIComponent(jur)}`);

  const res = await fetch(
    `${SUPABASE_URL}/rest/v1/gold_corpus_queue?select=*&${params.join("&")}`,
    {
      headers: {
        apikey: SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        Prefer: "count=exact",
      },
    },
  );
  if (!res.ok) {
    const err = await res.text();
    return jsonError(`fetch failed: ${err.slice(0, 200)}`, res.status);
  }
  const rows = await res.json();
  const contentRange = res.headers.get("content-range") ?? "";
  const total = parseTotalFromContentRange(contentRange);
  return jsonOk({ ok: true, rows, limit, offset, total });
}

async function handleStats(): Promise<Response> {
  const res = await fetch(
    `${SUPABASE_URL}/rest/v1/gold_corpus_stats?select=*`,
    {
      headers: {
        apikey: SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
      },
    },
  );
  if (!res.ok) {
    const err = await res.text();
    return jsonError(`stats fetch failed: ${err.slice(0, 200)}`, res.status);
  }
  const rows = await res.json() as Array<Record<string, unknown>>;
  const stats = rows[0] ?? {};
  return jsonOk({ ok: true, stats });
}

async function handleDecide(reviewerId: string, body: DecideBody): Promise<Response> {
  const queueId = (body.queue_id ?? "").trim();
  const status = (body.status ?? "").trim();
  if (!queueId) return jsonError("queue_id required", 400);
  if (!isUuid(queueId)) return jsonError("queue_id must be a UUID", 400);
  if (!VALID_STATUS.has(status)) {
    return jsonError(`status must be one of ${[...VALID_STATUS].join(", ")}`, 400);
  }
  if (status === "rejected" && !body.rejection_reason) {
    return jsonError("rejection_reason required when status=rejected", 400);
  }
  if (status === "rejected" && !VALID_REJECTION.has(body.rejection_reason!)) {
    return jsonError(
      `rejection_reason must be one of ${[...VALID_REJECTION].join(", ")}`,
      400,
    );
  }
  if (status === "edited" && !body.gold_answer?.trim()) {
    return jsonError("gold_answer required when status=edited", 400);
  }

  // ── Load queue row ────────────────────────────────────────────────────────
  const qRes = await fetch(
    `${SUPABASE_URL}/rest/v1/gold_corpus_queue?select=*&id=eq.${queueId}`,
    {
      headers: {
        apikey: SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
      },
    },
  );
  if (!qRes.ok) {
    const err = await qRes.text();
    return jsonError(`queue load failed: ${err.slice(0, 200)}`, qRes.status);
  }
  const qRows = await qRes.json() as Array<Record<string, unknown>>;
  if (qRows.length === 0) return jsonError("queue row not found", 404);
  const q = qRows[0];
  if (q.added_to_pairs === true) {
    return jsonError("queue row already processed", 409);
  }
  if (q.pii_scrubbed !== true) {
    return jsonError("queue row not yet scrubbed", 409);
  }

  const userQuestion = String(q.user_question ?? "");
  const aiAnswer = String(q.ai_answer ?? "");

  // ── Build the pair row ────────────────────────────────────────────────────
  let goldAnswer: string | null = null;
  let editSim: number | null = null;

  if (status === "approved") {
    goldAnswer = aiAnswer;
    editSim = 1.0;
  } else if (status === "edited") {
    goldAnswer = body.gold_answer!.trim();
    editSim = editSimilarity(aiAnswer, goldAnswer);
  } else if (status === "rejected") {
    goldAnswer = null;
    editSim = null;
  } else {
    // skipped: no pair row, only mark queue
    const markRes = await fetch(
      `${SUPABASE_URL}/rest/v1/gold_corpus_queue?id=eq.${queueId}`,
      {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          apikey: SUPABASE_SERVICE_ROLE_KEY,
          Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
          Prefer: "return=minimal",
        },
        body: JSON.stringify({ added_to_pairs: true }),
      },
    );
    if (!markRes.ok) {
      const err = await markRes.text();
      return jsonError(`mark skipped failed: ${err.slice(0, 200)}`, markRes.status);
    }
    return jsonOk({ ok: true, status: "skipped", pair_id: null });
  }

  const insertBody: Record<string, unknown> = {
    reviewer_id: reviewerId,
    reviewed_at: new Date().toISOString(),
    source_queue_id: queueId,
    user_question: userQuestion,
    ai_answer: aiAnswer,
    gold_answer: goldAnswer,
    ai_model: q.ai_model ?? null,
    ai_citations: q.ai_citations ?? null,
    language: q.language ?? null,
    category: q.category ?? null,
    jurisdiction: q.jurisdiction ?? "estonia",
    status,
    rejection_reason: status === "rejected" ? body.rejection_reason : null,
    reviewer_notes: body.reviewer_notes ?? null,
    ai_answer_token_count: estimateTokens(aiAnswer),
    gold_answer_token_count: goldAnswer ? estimateTokens(goldAnswer) : null,
    edit_similarity: editSim,
  };

  const insertRes = await fetch(
    `${SUPABASE_URL}/rest/v1/gold_corpus_pairs`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        Prefer: "return=representation",
      },
      body: JSON.stringify(insertBody),
    },
  );
  if (!insertRes.ok) {
    const err = await insertRes.text();
    // Unique constraint on source_queue_id → 23505 wrapped as 409.
    if (insertRes.status === 409 || err.includes("23505")) {
      return jsonError("pair already exists for this queue row", 409);
    }
    return jsonError(`insert failed: ${err.slice(0, 200)}`, insertRes.status);
  }
  const pairRows = await insertRes.json() as Array<{ id: string }>;
  const pairId = pairRows[0]?.id ?? null;

  // ── Mark queue row as processed ───────────────────────────────────────────
  const markRes = await fetch(
    `${SUPABASE_URL}/rest/v1/gold_corpus_queue?id=eq.${queueId}`,
    {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        apikey: SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        Prefer: "return=minimal",
      },
      body: JSON.stringify({ added_to_pairs: true }),
    },
  );
  if (!markRes.ok) {
    console.warn(
      `[gold-review] queue mark failed for ${queueId} — pair ${pairId} already inserted`,
    );
    // Don't fail the request — the pair is the canonical record.
  }

  return jsonOk({
    ok: true,
    status,
    pair_id: pairId,
    edit_similarity: editSim,
  });
}

// ─── Router ─────────────────────────────────────────────────────────────────

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  const gate = await gateReviewer(req);
  if (!gate.allow) return gate.response;

  const url = new URL(req.url);
  // Path tail after /gold-review/
  const path = url.pathname.replace(/^.*\/gold-review/, "").replace(/^\//, "");

  try {
    if (req.method === "GET" && (path === "queue" || path === "")) {
      return await handleQueueList(url);
    }
    if (req.method === "GET" && path === "stats") {
      return await handleStats();
    }
    if (req.method === "POST" && path === "decide") {
      const body = await req.json().catch(() => null) as DecideBody | null;
      if (!body) return jsonError("invalid json", 400);
      return await handleDecide(gate.userId, body);
    }
    return jsonError(`unknown route: ${req.method} /${path}`, 404);
  } catch (e) {
    return jsonError(`handler threw: ${String(e).slice(0, 200)}`, 500);
  }
});

