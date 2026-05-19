// citation_verifier.ts — P0 hallucination guard (2026-05-19).
// -----------------------------------------------------------------------------
// Closes the gap that the hallucination eval (2026-05-19) opened:
// the model writes "§121 covers basic assault, and related §§118-120
// cover bodily injury" after only looking up §121, leaving §118/§119/§120
// invented. Result: 37.7% cite_without_lookup_rate (target <5%).
//
// HOW THIS DIFFERS FROM citation_enforcement.ts
// ---------------------------------------------
// `citation_enforcement.ts` operates on the marker layer: it scans the reply
// for known act-abbrev shapes (e.g. `TLS § 88`) and requires a matching
// `[[ref:TLS:88]]` marker EARLIER in the same reply. That works when the
// model is in Pkg-2-grounded mode (planner loop) because the grounder uses
// the rag_context chunks to emit markers.
//
// The new failure mode is OUTSIDE that scope. In tool-use mode the model
// emits PROSE citations (`§118`, `§§118-120`, `Article 6`) WITHOUT any
// `[[ref:...]]` marker. We cannot demand markers there because the markers
// pipeline is not active for ad-hoc tool-use turns. Instead we cross-check
// each prose citation against the (act_slug, paragraph) actually returned
// by `legal_lookup` tool calls in the SAME TURN.
//
// CONTRACT
// --------
//   verifyResponseCitations(text, toolUseResults) →
//     { verified, unverified, marked_text, stripped_text, hallucination_score }
//
// `toolUseResults` is the union of every `legal_lookup` call made in this
// turn. Each entry exposes the input (so we honour `specific_statute` hints)
// AND the returned chunks (act_slug + section_label + paragraph).
//
// VERIFICATION RULES (ported from eval/hallucination_detector.ts)
// ---------------------------------------------------------------
//   1. Extract every §N / §N:M / Article N / art. N from the text.
//   2. Expand inline ranges: "§§ 118-120" → [§118, §119, §120].
//   3. For each cite, normalise to a bare number form ("121", "1:3", "6").
//   4. A cite is "verified" iff at least one tool_use call covered it. A
//      tool call covers a cite when:
//        • the input.specific_statute substring-matches the cite, OR
//        • any returned chunk's section_label OR paragraph
//          equals/substring-matches the cite number.
//   5. Anything not covered is "unverified".
//
// OUTPUT
// ------
//   • marked_text  → reply with `[?§120]` inline near each unverified cite,
//                    plus a footer note. Default mode.
//   • stripped_text → reply with the bare cite removed (mode: "strip",
//                    used when STRICT_MODE env var is on or the caller
//                    asks for it).
//
// Pure module. No I/O. No Deno globals. Same constraint as
// citation_enforcement.ts so it can be unit-tested with `deno test` alone.
// -----------------------------------------------------------------------------

// ── Public types ────────────────────────────────────────────────────────────

/** Subset of an Anthropic `tool_use` block + the corpus rows that came back.
 *  Caller passes one entry per `legal_lookup` invocation in the turn.
 *
 *  Shape is intentionally minimal — the verifier only reads
 *  `input.specific_statute`, `input.query`, and the chunk
 *  (act_slug, paragraph, section_label) fields. Anything else is ignored.
 */
export interface ToolUseResult {
  /** Tool name. Verifier only acts on `legal_lookup`; others are skipped. */
  tool_name: string;
  /** Echo of the tool_use input. Used to honour `specific_statute` hints. */
  input?: {
    query?: string;
    jurisdiction?: string;
    specific_statute?: string;
    [k: string]: unknown;
  };
  /** The chunks the tool returned. At least act_slug + (paragraph |
   *  section_label) must be present for the chunk to count. */
  returned_chunks: Array<{
    act_slug?: string | null;
    paragraph?: string | null;
    section_label?: string | null;
    similarity?: number | null;
  }>;
}

/** A single extracted citation. */
export interface ExtractedCitation {
  /** Verbatim match from text, e.g. "§118", "Article 6", "art. 5". */
  raw: string;
  /** Normalised number ("118", "6", "1:3"). Lowercase. */
  section: string;
  /** Original index in the reply text. */
  index: number;
  /** Length of the matched substring. */
  length: number;
  /** True when this citation was synthesised from a range expansion
   *  ("§§ 118-120" → §118, §119, §120). Synthetic ones don't get a
   *  text edit on their own; the parent range is edited. */
  synthetic: boolean;
}

/** Final verifier output. */
export interface VerifierResult {
  /** Verbatim reply text in. */
  raw_response: string;
  /** Citations cross-referenced against tool_use logs. Each string is the
   *  normalised key, e.g. "§118", "art:6". Deduped. */
  verified_citations: string[];
  /** Citations the verifier could NOT find in any tool_use result. */
  unverified_citations: string[];
  /** Reply with `[?]` inserted next to each unverified cite + footer. */
  marked_text: string;
  /** Reply with unverified cite text removed (mode=strip). */
  stripped_text: string;
  /** unverified / total. 0 when no citations at all. */
  hallucination_score: number;
  /** Detailed cite-level diagnostics for the logger. */
  details: Array<{
    raw: string;
    section: string;
    verified: boolean;
    index: number;
  }>;
}

export interface VerifierOptions {
  /** "mark" inserts a `[?]` marker; "strip" deletes the cite. Default "mark". */
  mode?: "mark" | "strip";
  /** Custom footer for marked mode. Default: a bilingual EN warning. */
  footer?: string;
}

// ── Regexes ─────────────────────────────────────────────────────────────────

/** Inline RANGE shape: "§§ 118-120", "§§118 – 120", "§ 118–120".
 *  Captures (start, end). Range expansion fires BEFORE single-cite extraction
 *  so the spans aren't double-counted. */
const RANGE_PATTERN_PARA =
  /§{1,2}\s*(\d+)\s*[-–—]\s*(\d+)(?![:\d])/g;

/** Article range shape: "Articles 6-8", "art. 6-8". */
const RANGE_PATTERN_ARTICLE =
  /\b(?:Articles?|Art\.?|artiklid|artikkelit)\s*(\d+)\s*[-–—]\s*(\d+)/gi;

/** Single FI/EE statute paragraph: §114, §1:3, §86a. Single § OK.
 *  Note: the §§ double-glyph is consumed by the range pattern first. */
const PARA_PATTERN = /§\s*(\d+(?:[:.]\d+)?[a-z]?)/g;

/** EU / ECHR article shape. "Article 6", "Art. 5", "art 17". Case-insensitive.
 *  Bounded to avoid catching "art" inside another word (artwork, etc.). */
const ARTICLE_PATTERN = /\b(?:Article|Art\.?)\s+(\d+(?:\(\d+\))?[a-z]?)\b/gi;

// ── Extraction ──────────────────────────────────────────────────────────────

/** Expand any "§§ N-M" range into M-N+1 synthetic cites. The range itself
 *  also stays in the cite list (so when we strip, we strip the whole "§§
 *  118-120" span — not just the head); synthetic siblings get index=-1 so
 *  the marker pass doesn't try to edit them.
 *
 *  Hard cap: any range >20 paragraphs is treated as range-too-wide → we
 *  emit the head + tail only. Protects against `§§ 1-9999` flooding the
 *  unverified list. */
function expandRanges(text: string): ExtractedCitation[] {
  const out: ExtractedCitation[] = [];
  const seen = new Set<string>();

  // FI/EE paragraph ranges (§§118-120)
  const rePara = new RegExp(RANGE_PATTERN_PARA.source, "g");
  for (const m of text.matchAll(rePara)) {
    const start = parseInt(m[1], 10);
    const end = parseInt(m[2], 10);
    if (!Number.isFinite(start) || !Number.isFinite(end)) continue;
    if (end < start) continue;
    const idx = m.index ?? -1;
    const span = m[0];
    // The range itself counts as a single cite (the head paragraph).
    const headKey = `§${start}`;
    if (!seen.has(headKey)) {
      seen.add(headKey);
      out.push({
        raw: span,
        section: String(start),
        index: idx,
        length: span.length,
        synthetic: false,
      });
    }
    // Now synthesise siblings.
    const limit = Math.min(end, start + 20);
    for (let n = start + 1; n <= limit; n++) {
      const key = `§${n}`;
      if (seen.has(key)) continue;
      seen.add(key);
      out.push({
        raw: `§${n}`,
        section: String(n),
        index: -1,
        length: 0,
        synthetic: true,
      });
    }
    if (end > start + 20) {
      // tail-only when range too wide
      const key = `§${end}`;
      if (!seen.has(key)) {
        seen.add(key);
        out.push({
          raw: `§${end}`,
          section: String(end),
          index: -1,
          length: 0,
          synthetic: true,
        });
      }
    }
  }

  // EU article ranges (Articles 6-8)
  const reArt = new RegExp(RANGE_PATTERN_ARTICLE.source, "gi");
  for (const m of text.matchAll(reArt)) {
    const start = parseInt(m[1], 10);
    const end = parseInt(m[2], 10);
    if (!Number.isFinite(start) || !Number.isFinite(end)) continue;
    if (end < start) continue;
    const idx = m.index ?? -1;
    const span = m[0];
    const headKey = `art:${start}`;
    if (!seen.has(headKey)) {
      seen.add(headKey);
      out.push({
        raw: span,
        section: String(start),
        index: idx,
        length: span.length,
        synthetic: false,
      });
    }
    const limit = Math.min(end, start + 20);
    for (let n = start + 1; n <= limit; n++) {
      const key = `art:${n}`;
      if (seen.has(key)) continue;
      seen.add(key);
      out.push({
        raw: `Article ${n}`,
        section: String(n),
        index: -1,
        length: 0,
        synthetic: true,
      });
    }
  }
  return out;
}

/** Extract every individual §N and Article-N citation. Excludes anything
 *  already inside a `[[ref:...]]` marker (the grounder already verified
 *  those) and anything overlapping a range head we already captured. */
function extractSingleCites(
  text: string,
  takenSpans: Array<{ start: number; end: number }>,
): ExtractedCitation[] {
  const out: ExtractedCitation[] = [];

  function isInsideTakenSpan(start: number, end: number): boolean {
    for (const s of takenSpans) {
      // Range head consumes the whole "§§ 118-120" text — anything inside
      // it is already represented by synthetic siblings.
      if (start >= s.start && end <= s.end) return true;
    }
    return false;
  }

  function isInsideMarker(start: number): boolean {
    // Look back ~30 chars for `[[ref:` opening without a `]]` close yet.
    const lookback = text.slice(Math.max(0, start - 60), start);
    const lastOpen = lookback.lastIndexOf("[[ref:");
    if (lastOpen === -1) return false;
    const lastClose = lookback.lastIndexOf("]]");
    return lastClose < lastOpen;
  }

  // FI/EE §
  const rePara = new RegExp(PARA_PATTERN.source, "g");
  for (const m of text.matchAll(rePara)) {
    const idx = m.index ?? -1;
    if (idx < 0) continue;
    const len = m[0].length;
    if (isInsideTakenSpan(idx, idx + len)) continue;
    if (isInsideMarker(idx)) continue;
    out.push({
      raw: m[0],
      section: m[1].toLowerCase(),
      index: idx,
      length: len,
      synthetic: false,
    });
  }

  // EU / ECHR Article
  const reArt = new RegExp(ARTICLE_PATTERN.source, "gi");
  for (const m of text.matchAll(reArt)) {
    const idx = m.index ?? -1;
    if (idx < 0) continue;
    const len = m[0].length;
    if (isInsideTakenSpan(idx, idx + len)) continue;
    if (isInsideMarker(idx)) continue;
    out.push({
      raw: m[0],
      section: m[1].toLowerCase(),
      index: idx,
      length: len,
      synthetic: false,
    });
  }
  return out;
}

// ── Coverage check ──────────────────────────────────────────────────────────

/** Normalise a section label so "§ 121", "§121", "  121", "121 a" all map
 *  to the same comparison shape. Lowercase. */
function normaliseSection(s: string | null | undefined): string {
  if (!s) return "";
  return s.toString().toLowerCase().replace(/§/g, "").replace(/\s+/g, "").trim();
}

/** Pull a paragraph token out of a free-form label, e.g. "Pykälä 114",
 *  "§ 121", "Section 6", "Artikkel 5", "Article 17(1)" → "114" / "121" /
 *  "6" / "5" / "17". Returns "" when no number found. */
function extractParaToken(label: string | null | undefined): string {
  if (!label) return "";
  const m = label.toString().match(/(\d+(?:[:.]\d+)?[a-z]?)/);
  return m ? m[1].toLowerCase() : "";
}

/** Returns true if a single citation is covered by at least one tool call. */
function isCovered(
  cite: ExtractedCitation,
  tools: ReadonlyArray<ToolUseResult>,
): boolean {
  const target = normaliseSection(cite.section);
  if (!target) return false;
  const targetNum = extractParaToken(target);

  for (const lk of tools) {
    if (lk.tool_name !== "legal_lookup") continue;
    // 1) Honour `specific_statute` — if the model passed e.g.
    //    "HOL §114" we accept §114 even if the returned chunks were
    //    mis-tagged.
    const ss = normaliseSection(lk.input?.specific_statute);
    if (ss) {
      if (ss === target) return true;
      if (ss.includes(target)) return true;
      if (targetNum && ss.includes(targetNum)) return true;
      const ssNum = extractParaToken(ss);
      if (ssNum && ssNum === targetNum) return true;
    }
    // 2) Match against the returned chunks. We check BOTH `paragraph`
    //    and `section_label` (different RPC paths populate different
    //    columns). Compare both the full normalised string AND just the
    //    paragraph-number token so labels like "Pykälä 114" still match
    //    the cite "§114".
    for (const ch of lk.returned_chunks ?? []) {
      const labels = [ch.section_label, ch.paragraph];
      for (const l of labels) {
        const norm = normaliseSection(l);
        if (!norm) continue;
        if (norm === target) return true;
        if (norm === targetNum) return true;
        if (targetNum && norm.endsWith(`:${targetNum}`)) return true;
        if (target.endsWith(`:${norm}`)) return true;
        const labelNum = extractParaToken(norm);
        if (labelNum && labelNum === targetNum) return true;
      }
    }
  }
  return false;
}

// ── Public verifier ─────────────────────────────────────────────────────────

const DEFAULT_FOOTER_MARK = (n: number) =>
  `\n\n⚠️ ${n} citation${n === 1 ? "" : "s"} could not be verified ` +
  `against retrieved sources (marked [?]). Please confirm against the ` +
  `primary statute before relying on these references.`;

const DEFAULT_FOOTER_STRIP = (n: number) =>
  `\n\n⚠️ ${n} citation${n === 1 ? "" : "s"} were removed because they ` +
  `could not be verified against retrieved legal sources.`;

/**
 * Cross-reference every prose citation in `responseText` against the
 * `legal_lookup` tool calls made in the same turn. Returns the original text,
 * marked/stripped variants, and the verified / unverified split.
 *
 * Pure function. p99 latency well under 5 ms on typical 4-cite turns.
 */
export function verifyResponseCitations(
  responseText: string,
  toolUseResults: ReadonlyArray<ToolUseResult>,
  options: VerifierOptions = {},
): VerifierResult {
  const mode = options.mode ?? "mark";
  if (!responseText) {
    return {
      raw_response: responseText ?? "",
      verified_citations: [],
      unverified_citations: [],
      marked_text: responseText ?? "",
      stripped_text: responseText ?? "",
      hallucination_score: 0,
      details: [],
    };
  }

  // 1) Expand ranges first. Their text spans are reserved so single-cite
  //    extraction does not pick up §118 again from "§§118-120".
  const ranges = expandRanges(responseText);
  const taken: Array<{ start: number; end: number }> = ranges
    .filter((c) => !c.synthetic && c.index >= 0)
    .map((c) => ({ start: c.index, end: c.index + c.length }));

  // 2) Single cites.
  const singles = extractSingleCites(responseText, taken);

  // 3) Combine + sort by reply order (synthetic siblings come right after
  //    their range head).
  const all: ExtractedCitation[] = [];
  for (const r of ranges) all.push(r);
  for (const s of singles) all.push(s);
  all.sort((a, b) => {
    const ai = a.index >= 0 ? a.index : 1e9;
    const bi = b.index >= 0 ? b.index : 1e9;
    return ai - bi;
  });

  // 4) Verify each cite.
  const verified: string[] = [];
  const unverified: string[] = [];
  const details: VerifierResult["details"] = [];
  const seenKey = new Set<string>();

  for (const c of all) {
    const covered = isCovered(c, toolUseResults);
    const key = c.raw.toLowerCase().replace(/\s+/g, " ").trim();
    if (!seenKey.has(key)) {
      seenKey.add(key);
      if (covered) verified.push(c.raw);
      else unverified.push(c.raw);
    }
    details.push({
      raw: c.raw,
      section: c.section,
      verified: covered,
      index: c.index,
    });
  }

  // 5) Marked/Stripped text. We apply edits only to NON-synthetic
  //    unverified cites — synthetics are already represented by their
  //    parent range span. Apply right-to-left so indices stay valid.
  const edits = details
    .filter((d) => !d.verified)
    .map((d) => {
      const orig = all.find((x) => x.raw === d.raw && x.index === d.index);
      if (!orig || orig.synthetic || orig.index < 0) return null;
      return orig;
    })
    .filter((x): x is ExtractedCitation => !!x)
    .sort((a, b) => b.index - a.index); // right-to-left

  let marked = responseText;
  for (const e of edits) {
    const before = marked.slice(0, e.index);
    const cite = marked.slice(e.index, e.index + e.length);
    const after = marked.slice(e.index + e.length);
    marked = `${before}${cite} [?]${after}`;
  }
  if (unverified.length > 0) {
    marked = marked + (options.footer ?? DEFAULT_FOOTER_MARK(unverified.length));
  }

  let stripped = responseText;
  for (const e of edits) {
    const before = stripped.slice(0, e.index);
    const after = stripped.slice(e.index + e.length);
    // Collapse a possible orphan double-space / leading punctuation
    // ("Article 6, ECHR" → "ECHR" loses the leading ", "). Trim trailing
    // whitespace from `before`, drop a leading "," or "and" from `after`.
    const beforeTrimmed = before.replace(/[\s,;]+$/, "");
    const afterCleaned = after.replace(/^([\s,;]+|\sand\s|\sja\s)/, " ");
    stripped = beforeTrimmed + afterCleaned;
  }
  if (unverified.length > 0) {
    stripped = stripped +
      (options.footer ?? DEFAULT_FOOTER_STRIP(unverified.length));
  }

  const total = verified.length + unverified.length;
  const score = total > 0 ? unverified.length / total : 0;

  return {
    raw_response: responseText,
    verified_citations: verified,
    unverified_citations: unverified,
    marked_text: marked,
    stripped_text: stripped,
    hallucination_score: score,
    details,
  };
}

/** Compact log summary; safe to JSON.stringify even when 100+ violations. */
export function summariseVerifierResult(r: VerifierResult): {
  verified: number;
  unverified: number;
  score: number;
  samples: Array<{ raw: string; section: string }>;
} {
  return {
    verified: r.verified_citations.length,
    unverified: r.unverified_citations.length,
    score: Number(r.hallucination_score.toFixed(3)),
    samples: r.details
      .filter((d) => !d.verified)
      .slice(0, 5)
      .map((d) => ({ raw: d.raw, section: d.section })),
  };
}
