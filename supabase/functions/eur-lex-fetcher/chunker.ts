// eur-lex-fetcher/chunker.ts
// -----------------------------------------------------------------------------
// Pure article-level chunker for EUR-Lex directives + regulations.
//
// EUR-Lex serves consolidated acts in two formats:
//   1. FORMEX XML (the canonical authoring format) — structured, but the API
//      surface for it is brittle and requires SPARQL/CELLAR navigation.
//   2. HTML — rendered from FORMEX; structure is preserved through CSS
//      classes (`ti-art`, `oj-ti-art`, etc.) and headings that always carry
//      the literal "Article N" / "Artikkel N" / "Artikla N" string.
//
// We chunk from HTML because:
//   * it is the format EUR-Lex returns most reliably at the public REST
//     surface (`/legal-content/EN/TXT/?uri=CELEX:...&format=HTML`);
//   * the per-article boundary is preserved across all 24 EU languages, so
//     one regex strategy works for FI/ET/EN/DE/SV without per-locale forks;
//   * paragraph numbers ("1.", "2.", ...) within an article are stable
//     across consolidated revisions, so an Article-N + para-K key is a good
//     citation anchor for `[[ref:eu-dir-2004-38:art-7-1]]` style markers.
//
// This module ONLY does string → chunks. The fetcher.ts handles network and
// the index.ts handles the worker loop. Pure-function shape lets us test
// the chunker against frozen HTML fixtures without hitting EUR-Lex.
// -----------------------------------------------------------------------------

export interface EurLexChunk {
  /** "art-7" or "art-7-1" or "recital-23" or "preamble". */
  section: string;
  /** Human-readable "Article 7" / "Artikkel 7" / "Artikla 7" for citations. */
  section_label: string;
  /** Body text — paragraph(s) for this article, plain text, trimmed. */
  text: string;
  /** Optional paragraph number within the article ("1", "2a", etc.). */
  subsection: string | null;
}

// =============================================================================
// Language-aware article markers
// =============================================================================
// EUR-Lex consolidated HTML uses these exact patterns at section heads.
// We match defensively — both the canonical "Article N" form and the
// uppercase variants that appear in some older directives. The number-or-
// roman-numeral capture deliberately includes letters (e.g. "Article 7a")
// because consolidating amendments often add suffixed articles.
const ARTICLE_HEAD_PATTERNS: Record<string, RegExp> = {
  // English: "Article 7", "Article 7a", "Article 7 (1)"
  en: /^\s*Article\s+([0-9]+[a-z]?)\b/i,
  // Finnish: "1 artikla", "7 artikla", "7 a artikla"
  // Note: Finnish puts the number FIRST. We also accept "Artikla 7" as a
  // tolerant fallback for the (rare) inverted form.
  fi: /^\s*(?:([0-9]+(?:\s*[a-z])?)\s+artikla|Artikla\s+([0-9]+[a-z]?))\b/i,
  // Estonian: "Artikkel 7", "Artikkel 7a"
  et: /^\s*Artikkel\s+([0-9]+[a-z]?)\b/i,
};

/**
 * Sentinel inserted before each true article-header line so the chunker can
 * tell `<p class="oj-ti-art">Article 16</p>` (a real heading) apart from
 * `<p class="oj-normal">Article 16(1) of the Charter...</p>` (a back-reference
 * inside a recital). EUR-Lex CONVEX XHTML reliably uses `oj-ti-art` for the
 * canonical article head across all 24 languages.
 *
 * Exported only for tests; emitted onto its own line by `htmlToText`.
 */
export const ARTICLE_HEAD_MARKER = "\u0001ARTHEAD\u0001";

/** Strip HTML tags and collapse whitespace.
 *
 *  Side effect: any `<p class="oj-ti-art">` (CONVEX/CELLAR article-head class)
 *  gets a `\nARTICLE_HEAD_MARKER ` injected before it so the line-by-line
 *  chunker can recognise true heads even after tag-stripping. This survives
 *  the whitespace pass because the marker uses control chars that are
 *  preserved by the existing replace rules.
 */
export function htmlToText(html: string): string {
  return html
    // drop <script>/<style> blocks wholesale
    .replace(/<(script|style)[^>]*>[\s\S]*?<\/\1>/gi, " ")
    // Mark real article heads BEFORE we strip tags. We only trust
    // class="oj-ti-art" — that's the EUR-Lex canonical authoring class.
    // Without this, lines like "Article 16(2) TFEU mandates..." inside a
    // recital body get mis-detected as new article boundaries.
    .replace(
      /<p\b[^>]*class="[^"]*\boj-ti-art\b[^"]*"[^>]*>/gi,
      `\n${ARTICLE_HEAD_MARKER} `,
    )
    // normalise <br> and block-level closes to newlines so paragraph
    // boundaries survive the strip
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<\/(p|div|h[1-6]|li|tr)>/gi, "\n")
    // drop everything else
    .replace(/<[^>]+>/g, " ")
    // HTML entities we actually see in EUR-Lex
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&apos;/g, "'")
    // collapse runs of whitespace but preserve newlines as paragraph cues
    .replace(/[ \t]+/g, " ")
    .replace(/\n[ \t]+/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

/**
 * Extract the article number from a candidate heading line.
 *
 * To avoid false-positives on back-references inside recitals
 * (e.g. "Article 16(2) TFEU mandates..."), this matcher only accepts lines
 * that start with the {@link ARTICLE_HEAD_MARKER} sentinel injected by
 * {@link htmlToText}. Plain-text input without the sentinel is supported
 * too (legacy path / unit tests that feed pre-stripped text).
 *
 * Returns null if the line is not a recognised article head.
 */
export function matchArticleHead(line: string, lang: "en" | "fi" | "et"): string | null {
  const pat = ARTICLE_HEAD_PATTERNS[lang];
  if (!pat) return null;
  // Strip the sentinel if present. If the input was produced by `htmlToText`
  // we REQUIRE the sentinel — otherwise a back-reference inside recital body
  // could match. We detect "htmlToText output" by presence of the sentinel
  // anywhere in the document, but since we only see one line at a time here,
  // we accept both forms: sentinel-prefixed (definitely a head) or plain
  // (legacy / hand-fed test input).
  let candidate = line;
  if (candidate.startsWith(ARTICLE_HEAD_MARKER)) {
    candidate = candidate.slice(ARTICLE_HEAD_MARKER.length).trimStart();
  }
  const m = candidate.match(pat);
  if (!m) return null;
  // The pattern has up to two capture groups (Finnish has two alternatives).
  // Pick the first non-empty one and normalise whitespace within (e.g. "7 a" → "7a").
  const raw = (m[1] ?? m[2] ?? "").replace(/\s+/g, "").toLowerCase();
  return raw || null;
}

/**
 * Build the citation label in the requested language.
 *
 *   buildLabel("7", "en") → "Article 7"
 *   buildLabel("7", "fi") → "7 artikla"
 *   buildLabel("7", "et") → "Artikkel 7"
 */
export function buildLabel(art: string, lang: "en" | "fi" | "et"): string {
  switch (lang) {
    case "fi":
      return `${art} artikla`;
    case "et":
      return `Artikkel ${art}`;
    case "en":
    default:
      return `Article ${art}`;
  }
}

/**
 * Detect numbered paragraphs within an article body.
 *
 * EUR-Lex paragraphs render as "1.", "2.", "(a)", "(b)" — we split on the
 * "<digit>." form because that is the canonical paragraph marker that
 * cross-references like "Article 7(1)" point to. Sub-letters are kept
 * inside the parent paragraph chunk to avoid micro-chunking that would
 * blow our embedding budget.
 *
 * Heuristic: a paragraph head is a line that starts with `N.` where N is
 * 1-3 digits and is followed by whitespace + text. This intentionally
 * does NOT match "Article 7." or "Annex II.1." because those have
 * non-digit prefixes consumed by `splitIntoArticles`.
 */
const PARA_HEAD = /^(\d{1,3})\.\s+(\S)/;

export function splitArticleIntoParagraphs(
  articleText: string,
): Array<{ subsection: string | null; text: string }> {
  const lines = articleText.split("\n");
  const paras: Array<{ subsection: string | null; text: string }> = [];
  let current: { subsection: string | null; text: string[] } = {
    subsection: null,
    text: [],
  };

  for (const line of lines) {
    const m = line.match(PARA_HEAD);
    if (m) {
      // flush previous
      if (current.text.length > 0) {
        const joined = current.text.join("\n").trim();
        if (joined) paras.push({ subsection: current.subsection, text: joined });
      }
      current = { subsection: m[1], text: [line] };
    } else {
      current.text.push(line);
    }
  }
  if (current.text.length > 0) {
    const joined = current.text.join("\n").trim();
    if (joined) paras.push({ subsection: current.subsection, text: joined });
  }

  // If we never found a numbered paragraph the whole article body is one
  // chunk — that is correct for short articles (definitions, scope, etc.).
  if (paras.length === 0 && articleText.trim()) {
    paras.push({ subsection: null, text: articleText.trim() });
  }
  return paras;
}

/**
 * Top-level chunker — converts a full EUR-Lex HTML body into article+
 * paragraph chunks. Recitals are emitted as a single `preamble` chunk
 * because individual recitals are seldom cited and chunking them per-recital
 * would inflate the embedding count by 4-5x.
 */
export function chunkEurLexHtml(
  html: string,
  lang: "en" | "fi" | "et",
): EurLexChunk[] {
  const text = htmlToText(html);
  // If the source contained the canonical `oj-ti-art` class anywhere, we have
  // sentinel-marked heads and MUST trust only those — otherwise back-refs
  // inside recital bodies pollute article boundaries. If the source has no
  // `oj-ti-art` (legacy fixtures, third-party scrapes), fall back to loose
  // text-pattern matching.
  const requireSentinel = text.includes(ARTICLE_HEAD_MARKER);
  const lines = text.split("\n");

  const chunks: EurLexChunk[] = [];
  let currentArticle: { num: string; lines: string[] } | null = null;
  let preambleLines: string[] = [];
  let sawAnyArticle = false;

  for (const line of lines) {
    if (requireSentinel && !line.startsWith(ARTICLE_HEAD_MARKER)) {
      // In sentinel mode, lines without the marker can NEVER be heads.
      // Treat as body content for the current section.
      if (currentArticle) currentArticle.lines.push(line);
      else preambleLines.push(line);
      continue;
    }
    const art = matchArticleHead(line, lang);
    if (art !== null) {
      // flush previous article
      if (currentArticle) {
        emitArticle(chunks, currentArticle, lang);
      }
      currentArticle = { num: art, lines: [line] };
      sawAnyArticle = true;
    } else {
      if (currentArticle) currentArticle.lines.push(line);
      else preambleLines.push(line);
    }
  }
  if (currentArticle) emitArticle(chunks, currentArticle, lang);

  // Emit preamble only when we actually parsed articles — otherwise the
  // whole document is preamble (parse failure) and we don't want to
  // silently store a 100-page blob as a single chunk.
  //
  // Threshold: 60 chars — short enough to keep useful test preambles, long
  // enough to filter out single-line stubs ("OFFICIAL JOURNAL OF THE…").
  if (sawAnyArticle && preambleLines.length > 0) {
    const preambleText = preambleLines.join("\n").trim();
    if (preambleText.length > 60) {
      chunks.unshift({
        section: "preamble",
        section_label: lang === "fi"
          ? "Johdanto"
          : lang === "et"
          ? "Preambul"
          : "Preamble",
        // Hard cap so the chunk fits OpenAI text-embedding-3-small's 8192-token
        // window. ET tokenises at ~2.8-3.0 chars/token (worst case among our
        // three langs), so 20k chars ≈ 7100 tokens — safe headroom under 8192.
        // EN is ~4 chars/token; same cap is conservative but fine.
        text: preambleText.slice(0, 20_000),
        subsection: null,
      });
    }
  }

  return chunks;
}

function emitArticle(
  out: EurLexChunk[],
  art: { num: string; lines: string[] },
  lang: "en" | "fi" | "et",
): void {
  const body = art.lines.slice(1).join("\n").trim();
  if (!body) return;
  const label = buildLabel(art.num, lang);
  const paras = splitArticleIntoParagraphs(body);

  if (paras.length === 1 && paras[0].subsection === null) {
    out.push({
      section: `art-${art.num}`,
      section_label: label,
      text: paras[0].text,
      subsection: null,
    });
    return;
  }

  for (const p of paras) {
    out.push({
      section: p.subsection ? `art-${art.num}-${p.subsection}` : `art-${art.num}`,
      section_label: label,
      text: p.text,
      subsection: p.subsection,
    });
  }
}
