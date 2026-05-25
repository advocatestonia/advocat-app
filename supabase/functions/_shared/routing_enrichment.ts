// routing_enrichment.ts — Build an enriched query for the lawyer router so
// keyword/regex jurisdiction detection can fire even when the user message
// itself contains no jurisdiction signal.
// -----------------------------------------------------------------------------
// Why this file exists (P0 bug, 2026-05-25)
// -----------------------------------------
// `claude-proxy/index.ts` runs `selectRolesFromLawyerDept(userMessage, …)`
// with ONLY the raw user message text. For typical "что это?" / "помоги"
// / "explain" turns where the user has uploaded an Estonian fine, the router
// has nothing to scan — three Russian words contain neither "MKS" nor
// "tallinna" nor "Maksu- ja Tolliamet", so the keyword heuristic defaults
// to `senior-asianajaja` (Finnish counsel) — completely wrong.
//
// fact_extractor runs AFTER consilium synthesis (index.ts:1022-1040), so
// the CaseContext seen by the router is whatever was on the user_cases row
// before this turn — empty for the very first message after upload.
//
// Fix: when the request carries `case_id` and the case has parsed documents,
// pre-extract the load-bearing routing signal (statute citations, court
// names, dominant document language, key facts) from the existing
// `case_documents.key_extractions` jsonb + `parsed_summary` text and
// prepend it to the routing query so the keyword scan succeeds.
//
// Scope of this module
// --------------------
//   • Pure function. No I/O, no fetch. Safe to import from anywhere.
//   • NEVER throws. On any malformed input it returns `{ enrichedQuery:
//     userMessage, docLang: undefined }` so the caller can always fall
//     through to the original behaviour.
//   • Caps document inclusion at TOP_DOC_LIMIT (3) to prevent prompt bloat.
//   • Caps each document's summary slice at MAX_SUMMARY_CHARS (500) so the
//     enriched query stays well under the 2 KB regex-scan budget.
//   • Outputs a SCAN-ONLY block — never shown to the model. The output is
//     only fed to the keyword/regex router functions in `lawyer_router.ts`.
//
// What this module does NOT do
// ----------------------------
//   • Does NOT modify the system prompt — `active_case_injection.ts` owns
//     that path and already runs on the request.
//   • Does NOT touch task #23's pdf-parser changes — we only consume the
//     already-stored jsonb shape.
//   • Does NOT expand `CaseContext.language` enum (task #25 owns that).
//     We expose `docLang` as a nullable string so the caller can decide.
// -----------------------------------------------------------------------------

/** Document shape consumed by the enricher. Mirrors the subset of
 *  `recent_documents` returned by `load_active_case` RPC that we care about. */
export interface EnrichableDocument {
  /** OCR / chat summary — primary text source for keyword scanning. */
  parsed_summary?: string | null;
  /** Structured key_extractions jsonb. Shape produced by
   *  `pdf-parser/helpers.ts:extractedToKeyExtractions`:
   *     { doc_type, doc_date, parties, case_numbers, key_facts,
   *       diagnoses_if_medical, monetary_amounts, deadlines, pages_lang } */
  // deno-lint-ignore no-explicit-any
  key_extractions?: any;
  doc_type?: string | null;
  doc_date?: string | null;
  filename?: string | null;
}

/** Result of `buildEnrichedRoutingQuery`. */
export interface EnrichedRoutingQuery {
  /** The original user message with an `[Active document context]` block
   *  appended when documents exist. When no documents are present this is
   *  the user message verbatim. Used ONLY for routing — never sent to the
   *  model. */
  enrichedQuery: string;
  /** Dominant document language across the included docs (ISO-639-1, lower).
   *  Undefined when no documents were enrichable. The caller can promote
   *  this into `CaseContext.language` to break ties in the router's
   *  jurisdiction heuristic. */
  docLang?: string;
}

/** Maximum number of documents to merge into the routing query. Three is
 *  enough to surface routing-relevant signal (court, statute, jurisdiction)
 *  while keeping the regex scan budget under ~2 KB total. */
export const TOP_DOC_LIMIT = 3;

/** Per-document parsed_summary truncation. We only need keyword surface
 *  area — 500 chars typically captures the title block + first paragraph
 *  of an OCR'd court decision / fine. */
export const MAX_SUMMARY_CHARS = 500;

/** Hard cap on the entire `[Active document context]` block size in chars.
 *  Defence-in-depth against pathological key_extractions payloads. */
export const MAX_BLOCK_CHARS = 4_000;

// ─── Pure helpers ────────────────────────────────────────────────────────────

/** Best-effort string array from an unknown jsonb field. Skips falsy /
 *  whitespace-only entries. Also flattens common object shapes (e.g.
 *  `{ name, role }`, `{ number, type }`) into a single line each. */
function asStringArray(v: unknown, max = 8): string[] {
  if (!Array.isArray(v)) return [];
  const out: string[] = [];
  for (const item of v) {
    if (out.length >= max) break;
    if (typeof item === "string") {
      const t = item.trim();
      if (t.length > 0) out.push(t);
    } else if (item && typeof item === "object") {
      const rec = item as Record<string, unknown>;
      const parts = Object.entries(rec)
        .filter(([_, val]) => val != null && String(val).length > 0)
        .map(([k, val]) => `${k}: ${String(val)}`);
      if (parts.length > 0) out.push(parts.join(", "));
    }
  }
  return out;
}

/** Truncate to `max` chars at a word boundary when possible. Never throws. */
function truncate(s: string, max: number): string {
  if (s.length <= max) return s;
  const slice = s.slice(0, max);
  const lastSpace = slice.lastIndexOf(" ");
  if (lastSpace > max * 0.7) return slice.slice(0, lastSpace) + "…";
  return slice + "…";
}

/** Tally page-language counts from `key_extractions.pages_lang`.
 *  Returns the dominant (most-common) language code in lowercase. When
 *  no usable signal exists, returns undefined. */
function tallyDocLangs(docs: ReadonlyArray<EnrichableDocument>): string | undefined {
  const counts = new Map<string, number>();
  for (const d of docs) {
    const ke = d.key_extractions;
    if (!ke || typeof ke !== "object") continue;
    const pagesLang = (ke as { pages_lang?: unknown }).pages_lang;
    if (!Array.isArray(pagesLang)) continue;
    for (const lang of pagesLang) {
      if (typeof lang !== "string") continue;
      const code = lang.trim().toLowerCase();
      if (code.length < 2 || code.length > 5) continue;
      counts.set(code, (counts.get(code) ?? 0) + 1);
    }
  }
  if (counts.size === 0) return undefined;

  // Pick the language with the highest count. Stable on ties via insertion
  // order (Map preserves it), which mirrors document upload order from
  // recent_documents — newest-first is fine for tie-break.
  let bestLang: string | undefined;
  let bestCount = 0;
  for (const [code, n] of counts) {
    if (n > bestCount) {
      bestLang = code;
      bestCount = n;
    }
  }
  return bestLang;
}

/** Render a single document's routing-signal block. Returns "" if the
 *  document has no extractable signal. */
function renderDocBlock(d: EnrichableDocument, idx: number): string {
  const ke = d.key_extractions && typeof d.key_extractions === "object"
    ? d.key_extractions as Record<string, unknown>
    : {};

  const lines: string[] = [];
  const docTypeRaw = d.doc_type ?? (ke.doc_type as string | undefined);
  const docDate = d.doc_date ?? (ke.doc_date as string | undefined);
  const headParts: string[] = [`Doc ${idx + 1}`];
  if (docTypeRaw) headParts.push(`type=${String(docTypeRaw).trim()}`);
  if (docDate) headParts.push(`date=${String(docDate).trim()}`);
  if (d.filename) headParts.push(`file=${String(d.filename).trim()}`);
  lines.push(headParts.join(" | "));

  const parties = asStringArray(ke.parties, 5);
  if (parties.length > 0) lines.push(`Parties: ${parties.join("; ")}`);

  const caseNums = asStringArray(ke.case_numbers, 5);
  if (caseNums.length > 0) lines.push(`Case numbers: ${caseNums.join("; ")}`);

  const keyFacts = asStringArray(ke.key_facts, 5);
  if (keyFacts.length > 0) lines.push(`Key facts: ${keyFacts.join("; ")}`);

  const deadlines = asStringArray(ke.deadlines, 3);
  if (deadlines.length > 0) lines.push(`Deadlines: ${deadlines.join("; ")}`);

  const summary = (d.parsed_summary ?? "").trim();
  if (summary.length > 0) {
    lines.push(`Summary: ${truncate(summary, MAX_SUMMARY_CHARS)}`);
  }

  // If we only emitted the head line (no signal at all), skip this doc — it
  // would just pollute the regex scan with the doc-type word.
  if (lines.length === 1) return "";

  return lines.join("\n");
}

// ─── Public API ──────────────────────────────────────────────────────────────

/** Build a routing-only enriched query.
 *
 *  Behaviour matrix:
 *    • `recentDocs` is null / empty           → enrichedQuery = userMessage,
 *                                                docLang = undefined.
 *    • All docs have empty key_extractions
 *      and empty parsed_summary               → enrichedQuery = userMessage,
 *                                                docLang = undefined.
 *    • Has docs with signal                   → enrichedQuery = userMessage
 *                                                + "\n\n[Active document
 *                                                context]\n" + per-doc
 *                                                blocks (max 3, total ≤ 4 KB),
 *                                                docLang = dominant pages_lang.
 *
 *  NEVER throws. On any unexpected error returns the safe fall-through.
 */
export function buildEnrichedRoutingQuery(
  userMessage: string,
  recentDocs: ReadonlyArray<EnrichableDocument> | null | undefined,
): EnrichedRoutingQuery {
  const safeUserMessage = typeof userMessage === "string" ? userMessage : "";
  try {
    if (!Array.isArray(recentDocs) || recentDocs.length === 0) {
      return { enrichedQuery: safeUserMessage, docLang: undefined };
    }

    const topDocs = recentDocs.slice(0, TOP_DOC_LIMIT);
    const docLang = tallyDocLangs(topDocs);

    const blocks: string[] = [];
    let totalChars = 0;
    for (let i = 0; i < topDocs.length; i++) {
      const block = renderDocBlock(topDocs[i], i);
      if (!block) continue;
      // Defence: stop accumulating before we breach the block cap.
      if (totalChars + block.length > MAX_BLOCK_CHARS) break;
      blocks.push(block);
      totalChars += block.length;
    }

    if (blocks.length === 0) {
      // Docs existed but yielded no extractable signal — return user
      // message verbatim. We still report the doc-lang because pages_lang
      // can be present even when key_extractions is otherwise empty.
      return { enrichedQuery: safeUserMessage, docLang };
    }

    const enriched = `${safeUserMessage}\n\n[Active document context]\n${
      blocks.join("\n\n")
    }`;
    return { enrichedQuery: enriched, docLang };
  } catch (e) {
    // Defensive: never break routing on a malformed payload.
    console.warn(
      `routing_enrichment: build failed (returning userMessage): ${
        String(e).slice(0, 200)
      }`,
    );
    return { enrichedQuery: safeUserMessage, docLang: undefined };
  }
}
