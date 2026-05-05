// law-search Edge Function
// -----------------------------------------------------------------------------
// pgvector RAG search over the law_chunks table. P0-2 of the legal-brain
// rebuild (2026-05-06).
//
// Wire format (locked by lib/services/law_search_client.dart in P0-3):
//   POST /functions/v1/law-search
//   Bearer <SUPABASE_ANON_KEY>
//   { "query": string, "lang": "et"|"ru"|"en",
//     "match_count"?: number,                 -- default 8,  cap 50
//     "similarity_threshold"?: number }       -- default 0.60, [0..1]
//
//   200 OK
//   { "chunks": [
//       { "id": string, "act_slug": string, "act_name": string,
//         "paragraph": string, "title": string|null, "body": string,
//         "source_url": string|null, "similarity": number }
//     ],
//     "usage": { "tokens": number } }
//
// Graceful-degradation contract (per P0-3):
//   • OpenAI timeout / non-200 / malformed → 200 with `{chunks: [], usage: {tokens: 0}}`.
//   • Real client errors (missing query, invalid lang, oversize match_count)
//     still return 4xx — the client treats those as misuse, not transient failure.
//
// Auth: anon Bearer is sufficient. CORS + IP rate-limit (10/min anon) match
// the existing _shared/auth.ts pattern used by claude-proxy and tts-proxy.
//
// RLS: law_chunks has a public-select policy so the anon client can read.
// We use the service-role key for the RPC call to keep RLS evaluation off
// the hot path; either works given the policy, service role is just safer
// against future RLS tightening.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  jsonError,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import { embedQuery } from "./embed.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";

const SUPPORTED_LANGS = new Set(["et", "ru", "en"]);
const DEFAULT_MATCH_COUNT = 8;
const MAX_MATCH_COUNT = 50;
const DEFAULT_SIM_THRESHOLD = 0.60;
const EMBED_TIMEOUT_MS = 5000;

// Rate-limit knobs match the anon-friendly endpoints in this codebase.
// 10/min/IP for anon is generous enough for a chat turn (1-2 RAG calls per
// message) but cheap enough to bound abuse.
const RATE_LIMIT_PER_MINUTE = 30;
const ANON_RATE_LIMIT_PER_MINUTE = 10;

interface RequestBody {
  query?: unknown;
  lang?: unknown;
  match_count?: unknown;
  similarity_threshold?: unknown;
}

interface RpcChunk {
  id: string;
  act_slug: string;
  act_name: string;
  paragraph: string;
  title: string | null;
  body: string;
  source_url: string | null;
  similarity: number;
}

function emptyOk(tokens = 0): Response {
  return new Response(
    JSON.stringify({ chunks: [], usage: { tokens } }),
    { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
  );
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // ── 1. Auth + rate limit ────────────────────────────────────────────────
  // Anon Bearer is the production case (any logged-in or demo-mode user
  // hits this). Authenticated calls get a higher cap; anon get 10/min/IP.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "law-search",
    maxPerMinute: RATE_LIMIT_PER_MINUTE,
    anonymousPerMinute: ANON_RATE_LIMIT_PER_MINUTE,
  });
  if (gate.kind === "deny") return gate.response;

  // ── 2. Parse + validate body ────────────────────────────────────────────
  let body: RequestBody;
  try {
    body = await req.json() as RequestBody;
  } catch {
    return jsonError("Invalid JSON body", 400);
  }

  const query = typeof body.query === "string" ? body.query.trim() : "";
  if (!query) {
    return jsonError("Missing or empty 'query'", 400);
  }
  if (query.length > 4000) {
    // Embeddings input cap; protects against pathological payloads.
    return jsonError("Query too long (max 4000 chars)", 400);
  }

  const lang = typeof body.lang === "string" ? body.lang : "";
  if (!SUPPORTED_LANGS.has(lang)) {
    return jsonError(
      `Invalid 'lang' (expected one of ${[...SUPPORTED_LANGS].join(", ")})`,
      400,
    );
  }

  let matchCount = DEFAULT_MATCH_COUNT;
  if (body.match_count !== undefined && body.match_count !== null) {
    if (typeof body.match_count !== "number" || !Number.isFinite(body.match_count)) {
      return jsonError("Invalid 'match_count' (must be a number)", 400);
    }
    if (body.match_count <= 0) {
      return jsonError("Invalid 'match_count' (must be > 0)", 400);
    }
    if (body.match_count > MAX_MATCH_COUNT) {
      return jsonError(`'match_count' too large (max ${MAX_MATCH_COUNT})`, 400);
    }
    matchCount = Math.floor(body.match_count);
  }

  let similarityThreshold = DEFAULT_SIM_THRESHOLD;
  if (body.similarity_threshold !== undefined && body.similarity_threshold !== null) {
    if (
      typeof body.similarity_threshold !== "number" ||
      !Number.isFinite(body.similarity_threshold) ||
      body.similarity_threshold < 0 ||
      body.similarity_threshold > 1
    ) {
      return jsonError(
        "Invalid 'similarity_threshold' (must be a number in [0, 1])",
        400,
      );
    }
    similarityThreshold = body.similarity_threshold;
  }

  // ── 3. Embed the query — graceful no-op on any failure ──────────────────
  // 5s timeout; missing key is a server config bug, not a degraded mode,
  // so we still return 200+empty rather than 5xx (per P0-3 contract).
  if (!OPENAI_API_KEY) {
    console.warn("law-search: OPENAI_API_KEY not configured");
    return emptyOk();
  }

  let embed: Awaited<ReturnType<typeof embedQuery>>;
  try {
    embed = await embedQuery(query, {
      apiKey: OPENAI_API_KEY,
      timeoutMs: EMBED_TIMEOUT_MS,
    });
  } catch (err) {
    // EmbeddingError (misconfig) — swallow + degrade.
    console.warn(`law-search: embed threw ${String(err)}`);
    return emptyOk();
  }
  if (!embed) return emptyOk();

  // ── 4. RPC against pgvector ─────────────────────────────────────────────
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    console.warn("law-search: SUPABASE_URL / SERVICE_ROLE_KEY not configured");
    return emptyOk(embed.tokens);
  }

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data, error } = await supabase.rpc("law_search", {
      query_embedding: embed.embedding,
      query_lang: lang,
      match_count: matchCount,
      similarity_threshold: similarityThreshold,
    });
    if (error) {
      console.warn(`law-search: RPC error — ${error.message}`);
      return emptyOk(embed.tokens);
    }

    const rows = Array.isArray(data) ? data as RpcChunk[] : [];
    const chunks = rows.map((r) => ({
      id: r.id,
      act_slug: r.act_slug,
      act_name: r.act_name,
      paragraph: r.paragraph,
      title: r.title ?? null,
      body: r.body,
      source_url: r.source_url ?? null,
      similarity: typeof r.similarity === "number" ? r.similarity : 0,
    }));

    return new Response(
      JSON.stringify({ chunks, usage: { tokens: embed.tokens } }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.warn(`law-search: RPC threw — ${String(err)}`);
    return emptyOk(embed.tokens);
  }
});
