// admin-add-correction Edge Function
// ----------------------------------------------------------------------------
// Lets a human lawyer (or any service-role caller) insert a correction into
// advice_corrections without going through the user-explicit detector.
//
// Auth model:
//   * Caller MUST present an Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>
//     header. This is the only way the function will accept a write.
//   * No anon, no end-user JWT. The endpoint is for trusted backend use
//     only (admin dashboard, eval harness, manual lawyer review tool).
//
// Behaviour:
//   * Embeds `question` via OpenAI text-embedding-3-small if OPENAI_API_KEY
//     is set in the function environment; otherwise stores embedding=NULL
//     and lets a backfill job fix it later.
//   * Validates required fields. correction_source defaults to
//     "lawyer_review" if absent.
//   * Returns the inserted row id on 200.
//
// Auth wiring note (2026-05-13):
//   This project intentionally has no `supabase/config.toml` — see
//   docs/DEPLOY.md §"Known open issues". All functions deploy with the
//   default `verify_jwt=true`. Service-role callers pass the JWT-signed
//   SUPABASE_SERVICE_ROLE_KEY in the Authorization header, which the
//   Supabase JWT verifier accepts AND we re-check below in code (line ~62)
//   to ensure no end-user JWT can reach the insert path. Same pattern as
//   stripe-webhook and email-inbox-sync. Do NOT add a config.toml entry
//   just for this function — it would change the default for all others.
// ----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { corsHeaders, jsonError, jsonOk } from "../_shared/auth.ts";
import { embedText } from "../_shared/corrections_retriever.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";

const VALID_SOURCES = new Set([
  "user_explicit",
  "fact_extractor",
  "lawyer_review",
  "eval_failure",
]);
const VALID_SEVERITY = new Set(["factual", "procedural", "strategic", "citation"]);

interface AddCorrectionBody {
  user_id?: string;
  conversation_id?: string | null;
  question?: string;
  wrong_advice?: string;
  correct_answer?: string;
  why_wrong?: string;
  correction_source?: string;
  jurisdiction?: string | null;
  case_type?: string | null;
  severity?: string;
  metadata?: Record<string, unknown>;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("method not allowed", 405);
  }

  // ── Auth: service role only ───────────────────────────────────────────────
  const auth = req.headers.get("authorization") ?? "";
  const expected = `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`;
  if (auth !== expected) {
    return jsonError("service-role required", 401);
  }

  // ── Body ──────────────────────────────────────────────────────────────────
  let body: AddCorrectionBody;
  try {
    body = await req.json() as AddCorrectionBody;
  } catch {
    return jsonError("invalid json", 400);
  }

  const question = (body.question ?? "").toString().trim();
  const wrong = (body.wrong_advice ?? "").toString().trim();
  const correct = (body.correct_answer ?? "").toString().trim();
  const why = (body.why_wrong ?? "").toString().trim();
  const source = (body.correction_source ?? "lawyer_review").toString();
  const severity = body.severity ? body.severity.toString() : null;

  if (!question || !wrong || !correct || !why) {
    return jsonError(
      "question, wrong_advice, correct_answer, why_wrong are required",
      400,
    );
  }
  if (!VALID_SOURCES.has(source)) {
    return jsonError(`correction_source must be one of ${[...VALID_SOURCES].join(", ")}`, 400);
  }
  if (severity && !VALID_SEVERITY.has(severity)) {
    return jsonError(`severity must be one of ${[...VALID_SEVERITY].join(", ")}`, 400);
  }

  // ── Embed (best-effort) ───────────────────────────────────────────────────
  let embedding: number[] | null = null;
  if (OPENAI_API_KEY) {
    try {
      embedding = await embedText({
        text: question,
        openaiApiKey: OPENAI_API_KEY,
      });
    } catch (e) {
      console.warn(
        `admin-add-correction: embed failed: ${String(e).slice(0, 200)}`,
      );
    }
  }

  // ── Insert ────────────────────────────────────────────────────────────────
  const insertBody: Record<string, unknown> = {
    user_id: body.user_id ?? null,
    conversation_id: body.conversation_id ?? null,
    question,
    wrong_advice: wrong,
    correct_answer: correct,
    why_wrong: why,
    correction_source: source,
    jurisdiction: body.jurisdiction ?? null,
    case_type: body.case_type ?? null,
    severity,
    embedding: embedding ? `[${embedding.join(",")}]` : null,
    metadata: body.metadata ?? {},
  };

  const res = await fetch(`${SUPABASE_URL}/rest/v1/advice_corrections`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      apikey: SUPABASE_SERVICE_ROLE_KEY,
      Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
      Prefer: "return=representation",
    },
    body: JSON.stringify(insertBody),
  });

  if (!res.ok) {
    const err = await res.text();
    return jsonError(`insert failed: ${err.slice(0, 300)}`, res.status);
  }
  const rows = await res.json() as Array<{ id: string }>;
  return jsonOk({
    ok: true,
    id: rows?.[0]?.id ?? null,
    embedded: embedding !== null,
  });
});
