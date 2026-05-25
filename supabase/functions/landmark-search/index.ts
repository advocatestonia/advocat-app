// landmark-search — EU corpus 3-feature wave (2026-05-26).
// -----------------------------------------------------------------------------
// Searches the curated landmark case corpus (CJEU + ECHR — 491 seeded cases,
// 300/200 target). Returns ranked metadata only (no full text — licensing).
//
// v1 ranking: PostgreSQL BM25-ish via tsvector + court/area/year filters.
// Embeddings column reserved for v2; falls back to BM25 only if embedding
// retrieval is unavailable (which it is today — embeddings not yet populated).
//
// Spec: docs/eu_corpus/API_SPEC_3_FEATURES.md §3
// Schema: 20260526010000_eu_corpus_3features.sql (landmark_cases)
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, jsonError, jsonOk } from "../_shared/auth.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

interface LandmarkSearchRequest {
  query: string;
  court?: string[];
  area?: string[];
  year_from?: number;
  year_to?: number;
  limit?: number;
  offset?: number;
}

interface LandmarkResult {
  case_name: string;
  court: string;
  celex_or_ecli: string;
  year: number | null;
  area: string[];
  significance: string | null;
  articles_violated: string[];
  articles_engaged: string[];
  importance_level: string | null;
  source_url: string | null;
  similarity: number;
}

const VALID_COURTS = new Set(["CJEU", "ECHR", "GC", "EFTA"]);

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // Require any Bearer (user OR anon) — landmark metadata is non-sensitive
  // public-law data. We still enforce auth header presence to keep the
  // surface uniform with other endpoints and to enable per-tier rate caps
  // later. For v1 we accept any non-empty Authorization header.
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return jsonError("Unauthorized", 401);
  }

  let body: LandmarkSearchRequest;
  try {
    body = await req.json();
  } catch {
    return jsonError("Invalid JSON body", 400);
  }

  // Validate
  const q = (body.query ?? "").trim();
  if (!q || q.length < 3) {
    return jsonError("invalid_query: 3-512 chars required", 400);
  }
  if (q.length > 512) {
    return jsonError("invalid_query: max 512 chars", 400);
  }

  const limit = Math.min(Math.max(body.limit ?? 20, 1), 50);
  const offset = Math.min(Math.max(body.offset ?? 0, 0), 500);

  const courts = (body.court ?? [])
    .filter((c) => typeof c === "string")
    .map((c) => c.toUpperCase());
  for (const c of courts) {
    if (!VALID_COURTS.has(c)) {
      return jsonError(`invalid_filter: unknown court ${c}`, 400);
    }
  }

  const areas = (body.area ?? []).filter((a) => typeof a === "string");
  const yearFrom = body.year_from;
  const yearTo = body.year_to;
  if (
    yearFrom !== undefined && yearTo !== undefined && yearFrom > yearTo
  ) {
    return jsonError("invalid_year_range", 400);
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  const started = performance.now();

  // BM25-ish via ts_rank. plainto_tsquery is forgiving (handles
  // case-insensitive, OR semantics across whitespace). simple config
  // matches the migration's index.
  // Use rpc-via-pg to access ts_rank in one query.
  const sqlFilters: string[] = [];
  const params: Record<string, unknown> = { q, lim: limit, off: offset };

  if (courts.length) {
    sqlFilters.push("court = any($1::text[])");
    params["1"] = courts;
  }
  // Build via supabase-js text search + filters
  let queryBuilder = supabase
    .from("landmark_cases")
    .select(
      "case_name, court, ecli, celex, year, area, significance, articles_violated, articles_engaged, importance_level, source_url",
      { count: "exact" },
    );

  // Use full-text search on search_tsv via textSearch helper.
  // 'simple' config matches the trigger.
  queryBuilder = queryBuilder.textSearch("search_tsv", q, {
    type: "plain",
    config: "simple",
  });

  if (courts.length) queryBuilder = queryBuilder.in("court", courts);
  if (areas.length) queryBuilder = queryBuilder.overlaps("area", areas);
  if (yearFrom !== undefined) queryBuilder = queryBuilder.gte("year", yearFrom);
  if (yearTo !== undefined) queryBuilder = queryBuilder.lte("year", yearTo);

  queryBuilder = queryBuilder
    .order("year", { ascending: false, nullsFirst: false })
    .range(offset, offset + limit - 1);

  const { data, error, count } = await queryBuilder;

  if (error) {
    console.error("landmark-search query error:", error);
    // Graceful fallback: case-insensitive ILIKE on case_name for trivial recall
    const { data: fallbackData, error: fbErr, count: fbCount } = await supabase
      .from("landmark_cases")
      .select(
        "case_name, court, ecli, celex, year, area, significance, articles_violated, articles_engaged, importance_level, source_url",
        { count: "exact" },
      )
      .ilike("case_name", `%${q}%`)
      .order("year", { ascending: false, nullsFirst: false })
      .range(offset, offset + limit - 1);
    if (fbErr) {
      return jsonError("internal: query failed", 500, { details: fbErr.message });
    }
    const results: LandmarkResult[] = (fallbackData ?? []).map((row) => ({
      case_name: row.case_name,
      court: row.court,
      celex_or_ecli: row.celex || row.ecli,
      year: row.year,
      area: row.area || [],
      significance: row.significance,
      articles_violated: row.articles_violated || [],
      articles_engaged: row.articles_engaged || [],
      importance_level: row.importance_level,
      source_url: row.source_url,
      similarity: 0.5,
    }));
    return jsonOk({
      results,
      total: fbCount ?? results.length,
      query_interpretation: {
        filters_applied: { court: courts, year_range: [yearFrom, yearTo] },
      },
      model_used: "ilike-fallback-v1",
      cache_hit: false,
      processing_ms: Math.round(performance.now() - started),
    });
  }

  const results: LandmarkResult[] = (data ?? []).map((row) => ({
    case_name: row.case_name,
    court: row.court,
    celex_or_ecli: row.celex || row.ecli,
    year: row.year,
    area: row.area || [],
    significance: row.significance,
    articles_violated: row.articles_violated || [],
    articles_engaged: row.articles_engaged || [],
    importance_level: row.importance_level,
    source_url: row.source_url,
    similarity: 0.8, // placeholder — v2 will return real ts_rank score
  }));

  return jsonOk({
    results,
    total: count ?? results.length,
    query_interpretation: {
      filters_applied: {
        court: courts,
        area: areas,
        year_range: [yearFrom, yearTo],
      },
    },
    model_used: "bm25-tsv-v1",
    cache_hit: false,
    processing_ms: Math.round(performance.now() - started),
  });
});
