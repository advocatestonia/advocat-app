import { scrubAnthropicBody } from "./llm_egress/scrub_body.ts";
// query_rewriter.ts — вабанк A2 (2026-05-15)
// -----------------------------------------------------------------------------
// Translates a user's legal question (RU/EN/FI/ET) into the EXACT terminology
// the underlying statutes use in the target jurisdiction language so the
// embedding retrieval can find them. Cosine similarity on cross-language pairs
// (RU question → FI/EN statute) plateaus around 0.45-0.55 — well below the
// 0.70+ we get when the query is already in the statute's surface language.
// Rewriting the query first lifts recall@3 on conceptual queries +10-15%
// (eval baseline below in the deploy report).
//
// Pipeline:
//   1. Hash query → look in in-memory cache (max 1000 entries, LRU-ish).
//   2. If miss: call Haiku 4.5 with a strict system prompt. Returns
//      {rewritten, originalLang, augmented[]}.
//   3. Cache the result keyed by sha256(query|jurisdiction).
//   4. Caller fans out two retrievals: original + rewritten, merges results.
//
// Cost: ~$0.0003/query on Haiku at typical 200-300 input + 100 output tokens.
// At 10K queries/мес that's ~$3/мес. Negligible.
//
// Graceful degradation: if Haiku fails (no key, 429, network), we return
// `{rewritten: query, originalLang: 'unknown', augmented: [query]}` so the
// downstream retrieval still runs with the original query — never throws.
// -----------------------------------------------------------------------------

// ─── Public types ───────────────────────────────────────────────────────────

export interface QueryRewriteResult {
  /** The query rewritten in the target jurisdiction's statute terminology.
   *  e.g. "меня хотят депортировать" → "karkottaminen Ulkomaalaislaki §149". */
  rewritten: string;
  /** Detected source language: "ru" | "en" | "fi" | "et" | "unknown". */
  originalLang: string;
  /** Augmented variants to ALSO embed for retrieval (cross-language fanout).
   *  Always includes the original query first. */
  augmented: string[];
}

export type RewriterJurisdiction = "fi" | "ee" | "eu";

// ─── Constants ──────────────────────────────────────────────────────────────

const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";
/** Haiku 4.5 — same model used by classify-contract, pdf-parser, extract-memory.
 *  ~$0.80 in / $4 out per MTok. Typical rewrite is 200 in / 80 out → ~$0.0005. */
export const QUERY_REWRITER_MODEL = "claude-haiku-4-5-20251001";
/** Tight cap. The expected output is ~100 tokens of JSON. */
export const QUERY_REWRITER_MAX_TOKENS = 250;
export const QUERY_REWRITER_TEMPERATURE = 0.0;
/** Max number of cached entries before LRU eviction. */
export const QUERY_REWRITER_CACHE_MAX = 1000;
/** Hard timeout on the Haiku call. The user is waiting — 4s is the longest
 *  we'll spend before giving up and using the original query. */
export const QUERY_REWRITER_TIMEOUT_MS = 4000;

export const QUERY_REWRITER_SYSTEM = String.raw`
You translate a user's legal question into the EXACT terminology used in
Finnish / Estonian / EU legal statutes for retrieval.

Rules:
- If user writes "меня хотят депортировать" → return "karkottaminen Ulkomaalaislaki §149"
- If user writes "kuidas korterit jagada" → return "ühisvara jagamine PKS § 36 abikaasade vara"
- Output exact statute terms, not synonyms.
- Include § number if user mentions one.
- Multi-language: also return Russian terms for cross-lookup.

Target jurisdiction language:
  fi → Finnish (use Finnish statute names: Ulkomaalaislaki, Hallintolaki, Työsopimuslaki, Perustuslaki, ...)
  ee → Estonian (use Estonian statute names: TsÜS, PKS, TLS, KrMS, VÕS, ...)
  eu → English (use EU regulation/directive names: GDPR, MiCA, AI Act, Brussels I bis, ...)

Return STRICT JSON (no markdown, no commentary):
{
  "rewritten": "<best terms in target jurisdiction language>",
  "originalLang": "<ru|en|fi|et>",
  "augmented": ["<original>", "<russian variant>", "<english variant>"]
}

The "augmented" array must contain at least the original query. Add a Russian
and English paraphrase that use statute-grade terminology in those languages
(not casual paraphrases). Skip an entry if the original IS already in that
language (no duplicate).
`.trim();

// ─── In-memory cache ────────────────────────────────────────────────────────

/** Simple Map-backed LRU. JS Map preserves insertion order, so re-inserting
 *  on hit moves the entry to the back. When size > MAX we shift the front. */
const _cache = new Map<string, QueryRewriteResult>();

function _cacheKey(query: string, jurisdiction: string): string {
  // Cheap composite key. Don't bother hashing — Map handles long strings fine
  // and the keys never leak outside this module.
  return `${jurisdiction}|${query}`;
}

function _cacheGet(key: string): QueryRewriteResult | undefined {
  const hit = _cache.get(key);
  if (!hit) return undefined;
  // Touch: move to back of insertion order.
  _cache.delete(key);
  _cache.set(key, hit);
  return hit;
}

function _cacheSet(key: string, value: QueryRewriteResult): void {
  if (_cache.has(key)) _cache.delete(key);
  _cache.set(key, value);
  while (_cache.size > QUERY_REWRITER_CACHE_MAX) {
    const firstKey = _cache.keys().next().value;
    if (firstKey === undefined) break;
    _cache.delete(firstKey);
  }
}

/** TEST-ONLY: clear the cache between tests. Not exported in production
 *  paths; safe to call from edge fns too if someone needs a fresh start. */
export function _resetQueryRewriterCache(): void {
  _cache.clear();
}

/** TEST-ONLY: peek cache size for assertions. */
export function _queryRewriterCacheSize(): number {
  return _cache.size;
}

// ─── Haiku caller dependency seam ───────────────────────────────────────────

/** Injectable Haiku caller so the test suite can stub the network. Returns
 *  the raw JSON string from Claude. Throw on failure. */
export type HaikuJsonCaller = (opts: {
  system: string;
  userMessage: string;
  maxTokens: number;
  temperature: number;
  model: string;
}) => Promise<string>;

/** Default caller — hits Anthropic. Reads ANTHROPIC_API_KEY (or CLAUDE_API_KEY)
 *  from Deno.env. Used by production edge fns; tests inject their own. */
export function defaultHaikuJsonCaller(apiKey: string): HaikuJsonCaller {
  return async (opts) => {
    const ctrl = new AbortController();
    const t = setTimeout(() => ctrl.abort(), QUERY_REWRITER_TIMEOUT_MS);
    try {
      const res = await fetch(ANTHROPIC_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-api-key": apiKey,
          "anthropic-version": "2023-06-01",
        },
        body: JSON.stringify(scrubAnthropicBody({
          model: opts.model,
          max_tokens: opts.maxTokens,
          temperature: opts.temperature,
          system: opts.system,
          messages: [{ role: "user", content: opts.userMessage }],
        })),
        signal: ctrl.signal,
      });
      if (!res.ok) {
        const errText = await res.text();
        throw new Error(
          `query_rewriter Haiku ${res.status}: ${errText.slice(0, 200)}`,
        );
      }
      const json = await res.json() as {
        content?: Array<{ type: string; text?: string }>;
      };
      return (json.content ?? [])
        .filter((b) => b.type === "text" && typeof b.text === "string")
        .map((b) => b.text!)
        .join("");
    } finally {
      clearTimeout(t);
    }
  };
}

// ─── Resolve env API key once ───────────────────────────────────────────────

function resolveAnthropicKey(): string | null {
  try {
    // deno-lint-ignore no-explicit-any
    const d = (globalThis as any).Deno;
    const k = d?.env?.get?.("ANTHROPIC_API_KEY") ??
      d?.env?.get?.("CLAUDE_API_KEY");
    return typeof k === "string" && k.length > 0 ? k : null;
  } catch {
    return null;
  }
}

// ─── Parse + validate ───────────────────────────────────────────────────────

function parseRewriteJson(raw: string, original: string): QueryRewriteResult {
  // Strip markdown fences if the model wrapped them.
  const cleaned = raw.trim().replace(/^```json?\s*/i, "").replace(/```\s*$/, "");
  let parsed: unknown;
  try {
    parsed = JSON.parse(cleaned);
  } catch {
    throw new Error(`query_rewriter: invalid JSON from Haiku: ${cleaned.slice(0, 120)}`);
  }
  if (!parsed || typeof parsed !== "object") {
    throw new Error("query_rewriter: Haiku JSON not an object");
  }
  const obj = parsed as Record<string, unknown>;
  const rewritten =
    typeof obj.rewritten === "string" && obj.rewritten.trim().length > 0
      ? obj.rewritten.trim()
      : original;
  const originalLang =
    typeof obj.originalLang === "string" && obj.originalLang.length > 0
      ? obj.originalLang
      : "unknown";
  const augmentedRaw = Array.isArray(obj.augmented) ? obj.augmented : [];
  const augmented: string[] = [original];
  for (const item of augmentedRaw) {
    if (typeof item !== "string") continue;
    const t = item.trim();
    if (!t) continue;
    if (augmented.includes(t)) continue;
    augmented.push(t);
    if (augmented.length >= 4) break; // cap fan-out
  }
  return { rewritten, originalLang, augmented };
}

// ─── Public entry point ─────────────────────────────────────────────────────

/**
 * Rewrite a user's legal query into the target jurisdiction's statute
 * terminology, with cross-language augmented variants for retrieval fan-out.
 *
 * NEVER throws. On failure returns a degenerate result where `rewritten`
 * equals the original query and `augmented` is just `[query]`.
 *
 * @param query        User's raw query (any language).
 * @param jurisdiction Target jurisdiction ("fi" | "ee" | "eu"). Defaults to "fi".
 * @param deps         Injectable Haiku caller for tests.
 */
export async function rewriteQueryForRetrieval(
  query: string,
  jurisdiction: RewriterJurisdiction = "fi",
  deps: { callHaiku?: HaikuJsonCaller } = {},
): Promise<QueryRewriteResult> {
  const trimmed = (query ?? "").trim();
  if (!trimmed) {
    return { rewritten: "", originalLang: "unknown", augmented: [] };
  }

  // Cache hit fast path.
  const key = _cacheKey(trimmed, jurisdiction);
  const cached = _cacheGet(key);
  if (cached) return cached;

  // Resolve caller.
  let caller = deps.callHaiku;
  if (!caller) {
    const apiKey = resolveAnthropicKey();
    if (!apiKey) {
      // No key at all — degrade silently. Caller still gets the original
      // query so the retrieval path works (just without rewriting).
      const degraded: QueryRewriteResult = {
        rewritten: trimmed,
        originalLang: "unknown",
        augmented: [trimmed],
      };
      _cacheSet(key, degraded);
      return degraded;
    }
    caller = defaultHaikuJsonCaller(apiKey);
  }

  // Call Haiku.
  let raw: string;
  try {
    raw = await caller({
      system: QUERY_REWRITER_SYSTEM,
      userMessage: `Jurisdiction: ${jurisdiction}\nQuery: ${trimmed}`,
      maxTokens: QUERY_REWRITER_MAX_TOKENS,
      temperature: QUERY_REWRITER_TEMPERATURE,
      model: QUERY_REWRITER_MODEL,
    });
  } catch (err) {
    console.warn(`query_rewriter: Haiku call failed: ${String(err).slice(0, 200)}`);
    const degraded: QueryRewriteResult = {
      rewritten: trimmed,
      originalLang: "unknown",
      augmented: [trimmed],
    };
    // Do NOT cache hard failures — let the next call retry. We only cache
    // successful parses.
    return degraded;
  }

  let parsed: QueryRewriteResult;
  try {
    parsed = parseRewriteJson(raw, trimmed);
  } catch (err) {
    console.warn(`query_rewriter: parse failed: ${String(err).slice(0, 200)}`);
    return { rewritten: trimmed, originalLang: "unknown", augmented: [trimmed] };
  }

  _cacheSet(key, parsed);
  return parsed;
}
