// citation_grounder.ts — Phase 2 Pkg 2 grounding verifier (shared module).
// -----------------------------------------------------------------------------
// Pure module — no Deno globals, no I/O, no Supabase client. Imported by
//   • supabase/functions/claude-proxy/index.ts (per-turn verification)
//   • any future caller (email-draft-generate, eval-harness) that wants to
//     score grounding without a second Anthropic call.
//
// Spec: docs/architecture/phase2-pkg2-citations.md §4 (grounding verifier
// algorithm) + §3 (response shape).
//
// Marker syntax: `[[ref:ACT:PARAGRAPH]]` or `[[ref:ACT:PARAGRAPH:LANG]]`.
//   • ACT     — alphanumeric act_slug (lowercase preferred, case-insensitive
//                 match against chunk.act_slug). Examples: TLS, kars, 32019L1152.
//   • PARA    — alphanumeric paragraph identifier; allows letters and digits
//                 to support things like "5a" or "art-2". Excludes ':' and ']'.
//   • LANG    — optional locale suffix (e.g. ':en') used only to pick which
//                 translation's body to render in the snippet for EU directives.
//
// Latency budget: <50 ms p95 per design. Pure regex + Map lookup; the only
// non-O(1) work is the .match(/g) which is linear in reply length.
// -----------------------------------------------------------------------------

/** Single canonical regex source string. The exported constant is a string,
 * not a RegExp instance, so callers can build their own RegExp with whatever
 * flags they need (`g` for findAll, none for single-match).
 *
 * The Dart side mirrors this exactly in `lib/core/citations/marker.dart` —
 * the parity is enforced by `test/contract/citation_marker_parity_test.dart`.
 *
 * Pattern shape (verbatim, no JS-only escapes):
 *   \[\[ref:([A-Za-z0-9_-]+):([A-Za-z0-9_-]+)(?::([a-z_]+))?\]\]
 *
 * Capture groups:
 *   1 — act_slug (case-insensitive, normalised to lowercase by the verifier)
 *   2 — paragraph (preserved exactly)
 *   3 — optional locale suffix (e.g. 'en')
 */
export const CITATION_MARKER_PATTERN =
  String.raw`\[\[ref:([A-Za-z0-9_-]+):([A-Za-z0-9_-]+)(?::([a-z_]+))?\]\]`;

/** Snapshot of a RAG chunk that was injected into THIS turn's prompt.
 *  Field set is a strict subset of `law_chunks` (id, act_slug, paragraph,
 *  body, source_url, jurisdiction, in_force) plus the human-readable
 *  act_name + title. The verifier writes these fields straight into
 *  the citation row; no re-fetch from the DB is needed. */
export interface GroundingChunk {
  /** law_chunks.id, e.g. "tls-§88-1". `null` is never expected; the caller
   *  must drop chunks with no id before passing them in. */
  id: string;
  /** law_chunks.act_slug — the marker matches against this case-insensitively. */
  act_slug: string;
  /** law_chunks.paragraph — exact-match, e.g. "88", "art-5", "5a". */
  paragraph: string;
  /** Human-readable act name, e.g. "Töölepingu seadus". */
  act_name?: string | null;
  /** Optional § title, e.g. "Tööandja erakorraline ülesütlemine". */
  title?: string | null;
  /** Verbatim chunk body. Truncated at SNIPPET_MAX_CHARS for the citation
   *  payload but kept whole on the chunk for verification logic. */
  body?: string | null;
  /** Canonical source URL — Riigi Teataja, Finlex, EUR-Lex. */
  source_url?: string | null;
  /** EE / FI / EU / RU / DE — set on every law_chunks row by Pkg 1's
   *  jurisdiction migration. */
  jurisdiction?: string | null;
  /** law_chunks.in_force — drives `historical` status when false. */
  in_force?: boolean | null;
}

/** One marker → one citation row in the response payload (and one row in
 *  `chat_message_citations` once the proxy persists). Mirrors §3 of the
 *  design doc. */
export interface Citation {
  marker: string;
  /** verified — marker matches an in-force retrieved chunk.
   *  unverified — model cited an act/paragraph not in the rag_context.
   *  historical — chunk was retrieved but `in_force = false`. */
  status: "verified" | "unverified" | "historical";
  /** law_chunks.id of the matched chunk. Null when unverified. */
  chunk_id: string | null;
  act_slug: string;
  paragraph: string;
  act_name: string | null;
  title: string | null;
  /** ≤ SNIPPET_MAX_CHARS chars taken verbatim from the head of chunk.body.
   *  Null when unverified (no chunk body to draw from). */
  snippet: string | null;
  source_url: string | null;
  jurisdiction: string | null;
  in_force: boolean | null;
  /** Number of times this marker appeared in the reply text. ≥1. */
  occurrences: number;
}

/** Snippet length cap as specified in the design doc (§3 response shape).
 *  ≤400 chars keeps the JSON payload small while still showing meaningful
 *  context in the bottom sheet. */
export const SNIPPET_MAX_CHARS = 400;

/** Build the lookup index. Keyed by `lower(act_slug):paragraph` so the
 *  marker → chunk join is a single Map.get(). Paragraph stays exact —
 *  e.g. "88" and "88-1" must NOT collide. */
function buildIndex(
  chunks: ReadonlyArray<GroundingChunk>,
): Map<string, GroundingChunk> {
  const idx = new Map<string, GroundingChunk>();
  for (const c of chunks) {
    if (!c?.id || !c.act_slug || !c.paragraph) continue;
    const key = `${c.act_slug.toLowerCase()}:${c.paragraph}`;
    // First-write wins — the proxy already filters by in_force=true via the
    // law_search RPC, so for the common path this is a no-op. If the same
    // (slug, paragraph) appears twice (e.g. an in-force + historical pair
    // both injected), the in-force one comes first from law_search ordering.
    if (!idx.has(key)) idx.set(key, c);
  }
  return idx;
}

/** Truncate body to ≤SNIPPET_MAX_CHARS for the citation payload. Preserves
 *  the head of the body verbatim — the design explicitly states "≤400 chars
 *  from body" without a sentence-aware truncator (the bottom sheet shows
 *  it inside a blockquote, so a hard char cut is acceptable). */
function makeSnippet(body: string | null | undefined): string | null {
  if (!body) return null;
  return body.length <= SNIPPET_MAX_CHARS
    ? body
    : body.slice(0, SNIPPET_MAX_CHARS);
}

/** Verify the assistant reply text against the chunks injected into THIS
 *  turn's system prompt. Returns one Citation per distinct marker (deduped
 *  with `occurrences` counting repeats). Order of returned citations
 *  matches first-occurrence order in the reply for stable rendering.
 *
 *  Algorithm reference: design doc §4. Pure function — no DB call, no
 *  network. Latency: O(N + M) where N is reply length and M is markers. */
export function verifyCitations(
  replyText: string | null | undefined,
  ragChunks: ReadonlyArray<GroundingChunk>,
): Citation[] {
  if (!replyText || replyText.trim().length === 0) return [];

  const index = buildIndex(ragChunks);
  const re = new RegExp(CITATION_MARKER_PATTERN, "g");
  const seen = new Map<string, Citation>();
  const order: string[] = []; // preserve first-occurrence order

  for (const match of replyText.matchAll(re)) {
    const [marker, actRaw, paragraph /*, lang */] = match;
    if (!actRaw || !paragraph) continue; // belt-and-suspenders; regex guards

    const actSlug = actRaw.toLowerCase();
    const key = `${actSlug}:${paragraph}`;

    const existing = seen.get(key);
    if (existing) {
      existing.occurrences += 1;
      continue;
    }

    const chunk = index.get(key);
    let status: Citation["status"];
    if (!chunk) {
      status = "unverified";
    } else if (chunk.in_force === false) {
      status = "historical";
    } else {
      status = "verified";
    }

    const citation: Citation = {
      marker,
      status,
      chunk_id: chunk?.id ?? null,
      act_slug: actSlug,
      paragraph,
      act_name: chunk?.act_name ?? null,
      title: chunk?.title ?? null,
      snippet: chunk ? makeSnippet(chunk.body) : null,
      source_url: chunk?.source_url ?? null,
      jurisdiction: chunk?.jurisdiction ?? null,
      in_force: chunk ? (chunk.in_force ?? null) : null,
      occurrences: 1,
    };
    seen.set(key, citation);
    order.push(key);
  }

  return order.map((k) => seen.get(k)!);
}

// ── Helpers exposed for the proxy wiring step (claude-proxy/index.ts) ──

/** Strip the proxy-only `rag_context` field from a request body so it's
 *  never forwarded to Anthropic. Returns the rag chunks for the verifier
 *  to use post-response. Tolerant: missing field returns []. */
export function extractRagContext(
  body: Record<string, unknown>,
): GroundingChunk[] {
  const raw = body.rag_context;
  // Always strip — even if malformed — so we never leak it to Anthropic.
  delete body.rag_context;
  if (!raw || typeof raw !== "object") return [];
  const chunks = (raw as { chunks?: unknown }).chunks;
  if (!Array.isArray(chunks)) return [];
  const out: GroundingChunk[] = [];
  for (const c of chunks) {
    if (!c || typeof c !== "object") continue;
    const obj = c as Record<string, unknown>;
    const id = obj.id;
    const act_slug = obj.act_slug;
    const paragraph = obj.paragraph;
    if (typeof id !== "string" || typeof act_slug !== "string" ||
        typeof paragraph !== "string") {
      continue;
    }
    out.push({
      id,
      act_slug,
      paragraph,
      act_name: typeof obj.act_name === "string" ? obj.act_name : null,
      title: typeof obj.title === "string" ? obj.title : null,
      body: typeof obj.body === "string" ? obj.body : null,
      source_url: typeof obj.source_url === "string" ? obj.source_url : null,
      jurisdiction: typeof obj.jurisdiction === "string"
        ? obj.jurisdiction
        : null,
      in_force: typeof obj.in_force === "boolean" ? obj.in_force : null,
    });
  }
  return out;
}

/** Concatenate every text block of an Anthropic content array into a single
 *  string for verifier scanning. Tolerant to missing/non-text blocks
 *  (e.g. tool_use blocks pass through untouched). */
export function concatAnthropicTextBlocks(content: unknown): string {
  if (!Array.isArray(content)) return "";
  const parts: string[] = [];
  for (const block of content) {
    if (block && typeof block === "object") {
      const b = block as { type?: unknown; text?: unknown };
      if (b.type === "text" && typeof b.text === "string") {
        parts.push(b.text);
      }
    }
  }
  return parts.join("\n");
}
