// gold-review/pure.ts — env-free, serve-free pure helpers.
// -----------------------------------------------------------------------------
// Kept apart from index.ts so the test suite can import these without pulling in
// _shared/auth.ts (which reads SUPABASE_URL at module load) or booting serve().
// -----------------------------------------------------------------------------

/** Parse GOLD_REVIEWER_IDS. Empty / missing ⇒ empty set ⇒ no one allowed. */
export function parseReviewerIds(raw: string | undefined): Set<string> {
  if (!raw) return new Set();
  return new Set(
    raw.split(",").map((s) => s.trim().toLowerCase()).filter(Boolean),
  );
}

/**
 * queue_id is interpolated raw into PostgREST URLs (id=eq.${queueId}). A value
 * containing "&" / "?" could smuggle extra query params into the request, so we
 * require a canonical UUID before it ever reaches a URL.
 */
export function isUuid(s: unknown): s is string {
  return typeof s === "string" &&
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(s);
}

/**
 * Token-overlap Jaccard similarity. Cheap, deterministic, good enough for
 * "how much did Sofia rewrite". Embedding cosine is reserved for Phase B.
 */
export function editSimilarity(a: string, b: string): number {
  if (!a && !b) return 1;
  if (!a || !b) return 0;
  const ta = tokenize(a);
  const tb = tokenize(b);
  if (ta.size === 0 && tb.size === 0) return 1;
  if (ta.size === 0 || tb.size === 0) return 0;
  let inter = 0;
  for (const t of ta) if (tb.has(t)) inter++;
  const union = ta.size + tb.size - inter;
  return union === 0 ? 1 : inter / union;
}

function tokenize(s: string): Set<string> {
  return new Set(
    s.toLowerCase()
      .replace(/[^\p{L}\p{N}\s]/gu, " ")
      .split(/\s+/)
      .filter((t) => t.length >= 2),
  );
}

export function estimateTokens(s: string): number {
  // Rough estimate: ~4 chars per token. Analytics only; we don't bill on it.
  return Math.ceil((s ?? "").length / 4);
}

export function clampInt(
  raw: string | null,
  min: number,
  max: number,
  fallback: number,
): number {
  if (!raw) return fallback;
  const n = parseInt(raw, 10);
  if (!Number.isFinite(n)) return fallback;
  if (n < min) return min;
  if (n > max) return max;
  return n;
}

export function parseTotalFromContentRange(cr: string): number | null {
  // PostgREST Content-Range: "0-19/237" or "*/0"
  const m = cr.match(/\/(\d+)$/);
  if (!m) return null;
  const n = parseInt(m[1], 10);
  return Number.isFinite(n) ? n : null;
}
