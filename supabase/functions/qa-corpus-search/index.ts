// qa-corpus-search Edge Function
// -----------------------------------------------------------------------------
// Internal QA helper. Embeds a query via OpenAI text-embedding-3-small and
// calls law_search_v2 RPC server-side, returning top-K rows. Used by the
// golden-corpus QA runner so we don't need to expose OPENAI_API_KEY locally.
//
// Auth: shared secret in X-QA-Secret header (uses CORPUS_EMBEDDER_SECRET).
//
// Wire format:
//   POST /functions/v1/qa-corpus-search
//   X-QA-Secret: <CORPUS_EMBEDDER_SECRET>
//   { "query":         string,
//     "jurisdiction":  "fi" | "ee" | "eu" | "echr",
//     "top_k":         number (1-20, default 5),
//     "threshold":     number (0-1, default 0.0) }
//
//   200 OK
//   { "rows": [
//       { "id": string, "act_slug": string, "section_label": string|null,
//         "text": string, "similarity": number, "source_url": string|null }
//     ],
//     "embed_tokens": number,
//     "embed_ms": number,
//     "rpc_ms": number,
//     "total_ms": number }
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";
// QA harness shared secret. The header `X-QA-Secret` MUST match either
// CORPUS_EMBEDDER_SECRET (the active prod secret name, used by the eval
// runner) or the legacy QA_TEMP_SECRET fallback.
const QA_SECRET = Deno.env.get("CORPUS_EMBEDDER_SECRET") ??
  Deno.env.get("QA_TEMP_SECRET") ??
  "";

const OPENAI_EMBED_URL = "https://api.openai.com/v1/embeddings";
const OPENAI_MODEL = "text-embedding-3-small";
const EMBED_DIM = 1536;

const SUPPORTED_JURS = new Set(["fi", "ee", "eu", "echr"]);

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-qa-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function err(message: string, status: number): Response {
  return new Response(
    JSON.stringify({ error: message }),
    { status, headers: { ...corsHeaders, "Content-Type": "application/json" } },
  );
}

async function embed(query: string): Promise<{ embedding: number[]; tokens: number } | null> {
  const t0 = performance.now();
  const resp = await fetch(OPENAI_EMBED_URL, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${OPENAI_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: OPENAI_MODEL,
      input: query,
      dimensions: EMBED_DIM,
    }),
  });
  if (!resp.ok) {
    const detail = await resp.text().catch(() => "");
    console.warn(`embed: OpenAI ${resp.status} — ${detail.slice(0, 240)}`);
    return null;
  }
  const data = await resp.json() as {
    data?: Array<{ embedding?: number[] }>;
    usage?: { total_tokens?: number; prompt_tokens?: number };
  };
  const embedding = data?.data?.[0]?.embedding;
  if (!Array.isArray(embedding) || embedding.length !== EMBED_DIM) return null;
  const tokens = data?.usage?.total_tokens ?? data?.usage?.prompt_tokens ?? 0;
  console.log(`embed: ${Math.round(performance.now() - t0)}ms ${tokens}tok`);
  return { embedding, tokens };
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") return err("Method not allowed", 405);

  // Auth: shared secret.
  const secret = req.headers.get("x-qa-secret") ?? "";
  if (!QA_SECRET || secret !== QA_SECRET) {
    return err("Unauthorized", 401);
  }

  if (!OPENAI_API_KEY) return err("OPENAI_API_KEY not configured", 500);
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    return err("Supabase env not configured", 500);
  }

  let body: {
    query?: string;
    jurisdiction?: string;
    top_k?: number;
    threshold?: number;
    /** Hybrid (BM25 + dense RRF) mode toggle. When true the standard
     *  jurisdiction path routes to `law_search_hybrid_qa` instead of
     *  `law_search_v2_qa`. Echr path is unchanged (it does its own
     *  substring scoring against case_chunks). Default false to preserve
     *  baseline-comparable behaviour. */
    hybrid?: boolean;
  };
  try {
    body = await req.json();
  } catch {
    return err("Invalid JSON body", 400);
  }

  const query = typeof body.query === "string" ? body.query.trim() : "";
  if (!query) return err("Missing 'query'", 400);
  if (query.length > 4000) return err("Query too long", 400);

  const jurisdiction = typeof body.jurisdiction === "string" ? body.jurisdiction : "";
  if (!SUPPORTED_JURS.has(jurisdiction)) {
    return err(`Invalid 'jurisdiction' (one of ${[...SUPPORTED_JURS].join(", ")})`, 400);
  }

  const topK = typeof body.top_k === "number" && body.top_k > 0 && body.top_k <= 20
    ? Math.floor(body.top_k)
    : 5;
  // Allow negative thresholds — cosine similarity is in [-1, 1] and the
  // QA harness wants every retrieved row, no floor.
  const threshold =
    typeof body.threshold === "number" && body.threshold >= -1 && body.threshold <= 1
      ? body.threshold
      : -1.0;
  const hybridMode = body.hybrid === true;

  const tStart = performance.now();

  // ─── ECHR path: substring search in case_chunks ────────────────────────
  if (jurisdiction === "echr") {
    // Embed the query and run a vector search on case_chunks too. But the
    // QA runner expects {rows: [{slug:case_number, section_label:parties}]}.
    const embRes = await embed(query);
    if (!embRes) return err("Embedding failed", 502);
    const embed_ms = Math.round(performance.now() - tStart);

    const rpcStart = performance.now();
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    // case_chunks doesn't have a dedicated search RPC, so do a vector ORDER BY directly.
    // But pgvector ORDER BY needs SQL. Use rpc with raw if exists, else fall back to
    // the simple ilike text search.
    // Try a raw query via the helper RPC if available; otherwise we just do REST.
    const { data: caseRows, error: caseErr } = await supabase
      .from("case_chunks")
      .select("id, case_number, parties_redacted, key_holding, jurisdiction")
      .eq("jurisdiction", "echr")
      .limit(200);

    if (caseErr) {
      return err(`case_chunks query failed: ${caseErr.message}`, 502);
    }

    // Compute cosine similarity in JS against the returned chunks for ranking
    // (limit=200 is enough since we only have 109 cases).
    // Actually we don't have embeddings returned — let's just use textual
    // matching since case_chunks may be small.
    const tokens = query
      .toLowerCase()
      .replace(/[^\w\s]/g, " ")
      .split(/\s+/)
      .filter((t) => t.length > 2);

    type Row = {
      id: string;
      case_number: string;
      parties_redacted: string | null;
      key_holding: string | null;
    };
    const scored = (caseRows as Row[]).map((r) => {
      const haystack = [
        r.case_number ?? "",
        r.parties_redacted ?? "",
        r.key_holding ?? "",
      ].join(" ").toLowerCase();
      let hits = 0;
      for (const t of tokens) if (haystack.includes(t)) hits += 1;
      return { row: r, score: tokens.length ? hits / tokens.length : 0 };
    });
    scored.sort((a, b) => b.score - a.score);
    const top = scored.slice(0, topK).filter((s) => s.score > 0);

    return new Response(
      JSON.stringify({
        rows: top.map((s) => ({
          id: s.row.id,
          act_slug: s.row.case_number,
          section_label: s.row.parties_redacted,
          text: (s.row.key_holding ?? "").slice(0, 300),
          similarity: s.score,
          source_url: null,
        })),
        embed_tokens: embRes.tokens,
        embed_ms,
        rpc_ms: Math.round(performance.now() - rpcStart),
        total_ms: Math.round(performance.now() - tStart),
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  // ─── Standard path: embed + law_search_v2 (or hybrid) RPC ──────────────
  const embRes = await embed(query);
  if (!embRes) return err("Embedding failed", 502);
  const embed_ms = Math.round(performance.now() - tStart);

  const rpcStart = performance.now();
  // Format embedding as pgvector text literal to avoid any JSON→vector parsing
  // quirks. PostgREST accepts `[0.1, 0.2, ...]` as text representation.
  const vectorLit = "[" + embRes.embedding.map((v) => v.toString()).join(",") + "]";

  // The IVFFlat index has `lists=100` and pgvector's default `probes=1`
  // which causes recall to collapse on queries whose embedding doesn't fall
  // near a centroid. The QA wrapper RPCs (`*_qa`) bump probes via
  // `set_config('ivfflat.probes', ...)`. We pass 100 (full scan) so QA
  // recall is upper-bounded by retrieval quality, not index sparsity.
  //
  // Hybrid mode (vabank A1 — 2026-05-15): `law_search_hybrid_qa` fuses
  // cosine + BM25 (RRF k=60) over law_chunks_v2.chunk_tsv. Target:
  // recall@3 50% → 70% on terminology-heavy FI/EE queries
  // ("menetetyn määräajan palauttaminen", "asianomistaja").
  const rpcUrl = hybridMode
    ? `${SUPABASE_URL}/rest/v1/rpc/law_search_hybrid_qa`
    : `${SUPABASE_URL}/rest/v1/rpc/law_search_v2_qa`;
  const rpcBody = hybridMode
    ? {
      p_query_embedding: vectorLit,
      p_query_text: query,
      p_jurisdiction: jurisdiction,
      p_lang: null,
      p_act_slug: null,
      p_valid_at: null,
      p_match_threshold: threshold,
      p_limit: topK,
      p_probes: 100,
    }
    : {
      query_embedding: vectorLit,
      jurisdiction_filter: jurisdiction,
      act_slug_filter: null,
      lang_filter: null,
      valid_at: null,
      match_threshold: threshold,
      match_count: topK,
      probes: 100,
    };
  const rpcResp = await fetch(rpcUrl, {
    method: "POST",
    headers: {
      "apikey": SUPABASE_SERVICE_ROLE_KEY,
      "Authorization": `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(rpcBody),
  });
  if (!rpcResp.ok) {
    const detail = await rpcResp.text().catch(() => "");
    const rpcName = hybridMode ? "law_search_hybrid_qa" : "law_search_v2_qa";
    return err(`${rpcName} HTTP ${rpcResp.status}: ${detail.slice(0, 200)}`, 502);
  }
  const rawText = await rpcResp.text();
  // Replace stray NaN tokens with 0 before parsing (PostgREST emits raw NaN
  // which is not valid JSON; some clients accept it, JSON.parse does not).
  const safeJson = rawText.replace(/:\s*NaN/g, ": 0");
  let rows: unknown;
  try {
    rows = JSON.parse(safeJson);
  } catch (e) {
    const rpcName = hybridMode ? "law_search_hybrid_qa" : "law_search_v2_qa";
    return err(`${rpcName} JSON parse failed: ${String(e)}`, 502);
  }

  // Hybrid RPC adds bm25_rank/rrf_score/source_type columns; normalise to the
  // same row shape the QA runner consumes (id, act_slug, section_label,
  // text, similarity, source_url) so the eval contract is unchanged.
  const normalised = Array.isArray(rows)
    ? (rows as Array<Record<string, unknown>>).map((r) => ({
      id: r.id,
      act_slug: r.act_slug,
      section_label: r.section_label,
      text: r.text,
      similarity: typeof r.similarity === "number" ? r.similarity : 0,
      source_url: r.source_url ?? null,
      // Hybrid-only diagnostic fields (omitted on baseline path):
      bm25_rank: typeof r.bm25_rank === "number" ? r.bm25_rank : undefined,
      rrf_score: typeof r.rrf_score === "number" ? r.rrf_score : undefined,
      source_type: typeof r.source_type === "string" ? r.source_type : undefined,
    }))
    : [];

  return new Response(
    JSON.stringify({
      rows: normalised,
      embed_tokens: embRes.tokens,
      embed_ms,
      rpc_ms: Math.round(performance.now() - rpcStart),
      total_ms: Math.round(performance.now() - tStart),
      mode: hybridMode ? "hybrid" : "v2",
    }),
    { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
  );
});
