// doc-semantic-search/handler.ts
// -----------------------------------------------------------------------------
// Pure handler logic for the doc-semantic-search edge function. Separated from
// HTTP wiring so it can be unit-tested with injected embed + match deps.
//
// Flow:
//   1. Validate query.
//   2. Embed the query (text-embedding-3-small, 1536-dim).
//   3. Call the match_user_doc_chunks RPC (RLS-scoped to caller via auth.uid()).
//   4. Return ranked chunks with a highlight span for the matched phrase.
// -----------------------------------------------------------------------------

import { type EmbedResult } from "../_shared/doc_chunker.ts";

export interface MatchRow {
  id: string;
  source_kind: string;
  source_id: string;
  doc_title: string | null;
  chunk_index: number;
  text: string;
  char_start: number | null;
  char_end: number | null;
  similarity: number;
}

export interface SearchDeps {
  embed(texts: string[]): Promise<EmbedResult>;
  /** Calls match_user_doc_chunks via the caller's RLS-scoped client. */
  match(args: {
    embedding: number[];
    matchCount: number;
    threshold: number;
    orgId: string | null;
    sourceKind: string | null;
    sourceId: string | null;
  }): Promise<MatchRow[]>;
}

export interface SearchResultItem {
  chunk_id: string;
  source_kind: string;
  source_id: string;
  doc_title: string | null;
  chunk_index: number;
  snippet: string;
  similarity: number;
  char_start: number | null;
  char_end: number | null;
  /** Char offsets of the best-matching span WITHIN `snippet`, for highlight. */
  highlight: { start: number; end: number } | null;
}

export interface SearchResult {
  status: number;
  body: Record<string, unknown>;
}

const MAX_QUERY_CHARS = 1000;
const DEFAULT_MATCH_COUNT = 8;
const MAX_MATCH_COUNT = 25;
const DEFAULT_THRESHOLD = 0.2;
const SNIPPET_MAX = 320;

function isUuid(s: unknown): s is string {
  return (
    typeof s === "string" &&
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(s)
  );
}

export interface ParsedQuery {
  query: string;
  matchCount: number;
  threshold: number;
  orgId: string | null;
  sourceKind: string | null;
  sourceId: string | null;
}

export function parseSearchRequest(
  body: unknown
): { ok: true; value: ParsedQuery } | { ok: false; error: string } {
  if (typeof body !== "object" || body === null) {
    return { ok: false, error: "body must be a JSON object" };
  }
  const b = body as Record<string, unknown>;

  const rawQuery = typeof b.query === "string" ? b.query.trim() : "";
  if (rawQuery.length < 2) {
    return { ok: false, error: "query must be at least 2 characters" };
  }
  const query = rawQuery.slice(0, MAX_QUERY_CHARS);

  let matchCount = DEFAULT_MATCH_COUNT;
  if (typeof b.match_count === "number" && Number.isFinite(b.match_count)) {
    matchCount = Math.max(
      1,
      Math.min(Math.floor(b.match_count), MAX_MATCH_COUNT)
    );
  }

  let threshold = DEFAULT_THRESHOLD;
  if (typeof b.threshold === "number" && Number.isFinite(b.threshold)) {
    threshold = Math.max(0, Math.min(b.threshold, 0.99));
  }

  const orgId = isUuid(b.org_id) ? b.org_id : null;
  const sourceId = isUuid(b.source_id) ? b.source_id : null;
  const sourceKind =
    b.source_kind === "case_document" || b.source_kind === "vault_document"
      ? (b.source_kind as string)
      : null;

  return {
    ok: true,
    value: { query, matchCount, threshold, orgId, sourceKind, sourceId },
  };
}

/**
 * Build a tight snippet around the part of the chunk most relevant to the
 * query terms, with a highlight span. Heuristic (no second LLM call): find the
 * earliest occurrence of any query term (case-insensitive) and centre the
 * snippet on it. Falls back to the chunk head when no term matches verbatim
 * (semantic match without lexical overlap).
 */
export function buildSnippet(
  chunkText: string,
  query: string
): { snippet: string; highlight: { start: number; end: number } | null } {
  const terms = query
    .toLowerCase()
    .split(/[^\p{L}\p{N}]+/u)
    .filter((t) => t.length >= 3);

  const lower = chunkText.toLowerCase();
  let hitIdx = -1;
  let hitLen = 0;
  for (const t of terms) {
    const idx = lower.indexOf(t);
    if (idx >= 0 && (hitIdx === -1 || idx < hitIdx)) {
      hitIdx = idx;
      hitLen = t.length;
    }
  }

  if (chunkText.length <= SNIPPET_MAX) {
    const hl = hitIdx >= 0 ? { start: hitIdx, end: hitIdx + hitLen } : null;
    return { snippet: chunkText, highlight: hl };
  }

  if (hitIdx === -1) {
    return {
      snippet: chunkText.slice(0, SNIPPET_MAX).trimEnd() + "…",
      highlight: null,
    };
  }

  const half = Math.floor(SNIPPET_MAX / 2);
  let start = Math.max(0, hitIdx - half);
  let end = Math.min(chunkText.length, start + SNIPPET_MAX);
  start = Math.max(0, end - SNIPPET_MAX);

  const window = chunkText.slice(start, end);
  const trimmedLead = window.length - window.trimStart().length;
  const prefix = start > 0 ? "…" : "";
  const suffix = end < chunkText.length ? "…" : "";
  const snippet = prefix + window.trim() + suffix;

  // Recompute highlight relative to the trimmed+prefixed snippet.
  const hlPos = prefix.length + (hitIdx - start - trimmedLead);
  const highlight =
    hlPos >= 0 && hlPos < snippet.length
      ? { start: hlPos, end: Math.min(snippet.length, hlPos + hitLen) }
      : null;

  return { snippet, highlight };
}

export async function searchDocuments(
  body: unknown,
  deps: SearchDeps
): Promise<SearchResult> {
  const parsed = parseSearchRequest(body);
  if (!parsed.ok) {
    return { status: 400, body: { error: parsed.error } };
  }
  const q = parsed.value;

  let embedding: number[];
  try {
    const res = await deps.embed([q.query]);
    embedding = res.embeddings[0];
    if (!embedding) throw new Error("no embedding returned");
  } catch (e) {
    return { status: 502, body: { error: `embedding failed: ${String(e)}` } };
  }

  const rows = await deps.match({
    embedding,
    matchCount: q.matchCount,
    threshold: q.threshold,
    orgId: q.orgId,
    sourceKind: q.sourceKind,
    sourceId: q.sourceId,
  });

  const results: SearchResultItem[] = rows.map((r) => {
    const { snippet, highlight } = buildSnippet(r.text ?? "", q.query);
    return {
      chunk_id: r.id,
      source_kind: r.source_kind,
      source_id: r.source_id,
      doc_title: r.doc_title,
      chunk_index: r.chunk_index,
      snippet,
      similarity: Number((r.similarity ?? 0).toFixed(4)),
      char_start: r.char_start,
      char_end: r.char_end,
      highlight,
    };
  });

  return {
    status: 200,
    body: { query: q.query, count: results.length, results },
  };
}
