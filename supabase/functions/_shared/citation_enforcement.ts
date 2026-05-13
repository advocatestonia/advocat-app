// citation_enforcement.ts — Phase 2 Pkg 2 hardening (fail-closed verifier).
// -----------------------------------------------------------------------------
// The grounding verifier (citation_grounder.ts) only handles the marker side:
// when the model emits `[[ref:TLS:88]]`, it checks whether a chunk for that
// (act, paragraph) was retrieved this turn and assigns `verified/unverified/
// historical` status. But the verifier is SILENT on a different failure mode:
// the model can write a bare law citation like "TLS § 88" or "Direktiiv
// 96/9/EÜ" WITHOUT emitting any marker at all. The grounder sees no marker,
// returns `citations: []`, and the user sees an unverifiable law claim with
// no red badge — exactly the hallucination footgun this whole pipeline was
// supposed to close.
//
// This module fills that gap. It scans the reply text for known law-citation
// shapes (Estonian act abbreviations + §/lg numbers, EU directive codes,
// ECHR articles) and, for every shape it finds, checks whether the same
// (act, paragraph) is covered by a `[[ref:...:...]]` marker elsewhere in
// the reply. If a paragraph-level citation lacks a marker, we treat it as
// a hallucination and either:
//   • STRIP the bare citation (replacement: act name kept, § number removed)
//   • or RECORD a violation (caller chooses what to do with the text).
//
// Generic mentions are explicitly NOT touched. "vastavalt seadusele",
// "üürilepingu seadustes on sätestatud", "Estonian Employment Contracts Act
// generally allows..." — none of these trigger enforcement because they
// do not name a specific paragraph. Only `<ACT> § <NUMBER>` shapes (and
// EU directive / ECHR equivalents) are gated.
//
// Pure module — same constraints as citation_grounder.ts (no I/O, no Deno
// globals, pure regex). Imported by claude-proxy/index.ts post-verifier.
//
// Design doc: docs/architecture/phase2-pkg2-citations.md §11 (fail-closed
// enforcement, added 2026-05-11).
// -----------------------------------------------------------------------------

import {
  CITATION_MARKER_PATTERN,
  type Citation,
} from "./citation_grounder.ts";

// ── 1. Patterns ──────────────────────────────────────────────────────────────

/** Estonian law abbreviations that the model is instructed to cite as
 *  `<ABBR> § <NUM>` (see services/system_prompts.dart). Lowercase keys
 *  match the act_slug values in the law_chunks table.
 *
 *  Curated from the system prompt's "Estonia" instruction block (line
 *  480 of system_prompts.dart). Order is irrelevant — we build a single
 *  alternation regex from the keys.
 *
 *  Adding a new act here is non-breaking as long as the slug matches
 *  law_chunks.act_slug; tests should be extended in parallel. */
export const ESTONIAN_LAW_ABBREVS: ReadonlyMap<string, string> = new Map([
  // [user-visible abbreviation, lowercase act_slug for marker comparison]
  ["TLS", "tls"],
  ["VÕS", "võs"],
  ["VOS", "vos"], // ASCII-folded variant some models emit
  ["VõS", "võs"],
  ["KarS", "kars"],
  ["KARS", "kars"],
  ["PKS", "pks"],
  ["TsÜS", "tsüs"],
  ["TSÜS", "tsüs"],
  ["TsUS", "tsus"], // ASCII-folded
  ["TsMS", "tsms"],
  ["TSMS", "tsms"],
  ["KrMS", "krms"],
  ["KRMS", "krms"],
  ["HMS", "hms"],
  ["HKMS", "hkms"],
  ["PärS", "pärs"],
  ["PARS", "pars"],
  ["AsjS", "asjs"],
  ["ASJS", "asjs"],
  ["MKS", "mks"],
  ["TuMS", "tums"],
  ["TUMS", "tums"],
  ["KMS", "kms"],
  ["ÄS", "äs"],
  ["AS", "as"],
  ["IKS", "iks"],
  ["LS", "ls"],
  ["LKindlS", "lkindls"],
  ["LKINDLS", "lkindls"],
  ["VõrdKS", "võrdks"],
  ["VORDKS", "vordks"],
  ["VMS", "vms"],
]);

/** Sorted alternation built from the keys above. Longest-first so
 *  `LKindlS` is tried before `LS` (avoids LS swallowing the L of
 *  LKindlS). RegExp-escaped per char — abbreviations are alphanumeric
 *  + the `Õ`/`Ä`/`Ü` glyphs, none of which are regex metas. */
const ABBREV_ALTERNATION = Array.from(ESTONIAN_LAW_ABBREVS.keys())
  .sort((a, b) => b.length - a.length)
  .map((s) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"))
  .join("|");

/** Finnish law abbreviations (Phase 2 Pkg 1, 2026-05-11). Added in
 *  parallel with the Finlex statute ingest. The lowercase value is the
 *  `act_slug` that the Finnish corpus uses; per the design doc §6 those
 *  slugs are prefixed `fi-` to avoid collisions with Estonian acts that
 *  share an abbreviation (e.g. Estonian Töölepingu seadus and Finnish
 *  Työsopimuslaki both abbreviate as TLS/TSL).
 *
 *  When a future Finnish act is added, register it here AND in
 *  `services/system_prompts.dart` so the model is taught to cite it
 *  AND the enforcer can catch un-grounded mentions.
 *
 *  Variants: Finnish legalese uses a mix of upper-case acronyms (TSL)
 *  and CamelCase forms (TyöAikaL). We register both common shapes for
 *  each act so a model regression to either form is still caught. */
export const FINNISH_LAW_ABBREVS: ReadonlyMap<string, string> = new Map([
  // Phase 1 priority acts (matches PHASE_1_ACTS in scripts/scrape_finlex.ts)
  ["TSL", "fi-tsl"],          // Työsopimuslaki 55/2001
  ["UL", "fi-ul"],            // Ulkomaalaislaki 301/2004
  ["HL", "fi-hl"],            // Hallintolaki 434/2003
  ["LOHA", "fi-loha"],        // Laki oikeudenkäynnistä hallintoasioissa 808/2019
  ["HOL", "fi-loha"],         // Alias the model sometimes uses ("hallinto-oikeuslaki")
  ["AL", "fi-al"],            // Avioliittolaki 234/1929
  ["LHL", "fi-lhl"],          // Laki lapsen huollosta ja tapaamisoikeudesta 361/1983
  ["RL", "fi-rl"],            // Rikoslaki 39/1889
  ["KSL", "fi-ksl"],          // Kuluttajansuojalaki 38/1978
  ["VJL", "fi-vjl"],          // Velkajärjestelylaki 57/1993
  ["VjL", "fi-vjl"],          // CamelCase variant
  ["VKL", "fi-vkl"],          // Vahingonkorvauslaki 412/1974
  ["VahKL", "fi-vkl"],        // Common longer spelling
  ["AHVL", "fi-ahvl"],        // Laki asuinhuoneiston vuokrauksesta 481/1995
  // Phase 2 acts (registered ahead of ingest so the enforcer is ready)
  ["OYL", "fi-oyl"],          // Osakeyhtiölaki
  ["AOYL", "fi-aoyl"],        // Asunto-osakeyhtiölaki
  ["TyöAikaL", "fi-tyoaika"],  // Työaikalaki
  ["VuosilomaL", "fi-vuosiloma"], // Vuosilomalaki
  ["YhdenvertaisuusL", "fi-yhdvl"], // Yhdenvertaisuuslaki
  ["KansL", "fi-kansl"],       // Kansalaisuuslaki
]);

/** Sorted alternation for Finnish abbreviations. Longest-first so
 *  `YhdenvertaisuusL` is tried before `L` (no risk currently since `L`
 *  is not registered, but the pattern is defensive). */
const FINNISH_ABBREV_ALTERNATION = Array.from(FINNISH_LAW_ABBREVS.keys())
  .sort((a, b) => b.length - a.length)
  .map((s) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"))
  .join("|");

/** Estonian bare-paragraph citation regex.
 *
 *  Shape: `<ABBR> § <NUM>` with optional `lg <NUM>`/`p <NUM>`/`-<NUM>`
 *  paragraph extensions. The § symbol is REQUIRED — generic mentions
 *  like "TLS reguleerib töösuhteid" don't carry §, so they pass through
 *  untouched.
 *
 *  Capture groups:
 *    1 — act abbreviation (e.g. "TLS", "KarS")
 *    2 — paragraph number (e.g. "88", "88-1", "5a")
 *
 *  Word boundary handling: we use a lookbehind/lookahead pair (`(?<!\w)`,
 *  `(?!\w)`) instead of `\b` because `Õ`/`Ä`/`Ü` aren't word characters
 *  in JS regex `\w` semantics. */
export const BARE_ESTONIAN_CITATION_PATTERN = new RegExp(
  `(?<![A-Za-zÕÄÜõäü0-9])(${ABBREV_ALTERNATION})\\s*§\\s*([0-9]+(?:[a-z]?(?:[-–][0-9]+)?))(?:\\s*lg\\s*[0-9]+)?(?:\\s*p\\s*[0-9]+)?`,
  "gu",
);

/** Finnish bare-paragraph citation regex (Phase 2 Pkg 1, 2026-05-11).
 *
 *  Finnish statutes are organised as `<chapter> luku <section> §`. The two
 *  common shapes the model emits in chat are:
 *    1. `TSL 7 luku 3 §` — abbreviation first, then chapter+section.
 *    2. `7 luku 3 § TSL` — chapter+section first, then abbreviation.
 *    3. `TSL § 7-3`     — compact slug form (chapter-section after §).
 *    4. `Rikoslaki 21 luku 1 §` — full act name + chapter/section.
 *
 *  All four shapes have a `§` glyph and a `luku` (chapter) marker OR a
 *  chapter-section compound after `§`. Generic mentions like `TSL
 *  reguloi työsopimuksia` carry no `§`, so they pass through untouched.
 *
 *  We emit ONE pattern with two alternatives (abbreviation-first and
 *  chapter-first), each capturing 3 groups: act abbrev, chapter (may be
 *  blank), section. The post-processor normalises `chapter-section` so
 *  `act_slug:paragraph` matches the corpus form (`fi-tsl:7-3`).
 *
 *  Capture groups (numbered across all alternations):
 *    Branch A (abbrev first):
 *      1 — act abbreviation
 *      2 — chapter number (optional)
 *      3 — section number
 *    Branch B (chapter first):
 *      4 — chapter number
 *      5 — section number
 *      6 — act abbreviation
 *    Branch C (compact slug after §):
 *      7 — act abbreviation
 *      8 — compound (e.g. "7-3" or "26")
 *
 *  Word-boundary handling uses `(?<![A-Za-zäöÄÖ0-9])` / `(?![A-Za-zäöÄÖ0-9])`
 *  because Finnish abbreviations contain Latin letters only but the
 *  surrounding text may use `ä`/`ö` glyphs that JS `\w` does not include. */
export const BARE_FINNISH_CITATION_PATTERN = new RegExp(
  // Branch A: `TSL 7 luku 3 §`  (chapter+section after abbreviation)
  `(?<![A-Za-zäöÄÖ0-9])(${FINNISH_ABBREV_ALTERNATION})\\s+(\\d+)\\s*luku\\s+(\\d+)\\s*§` +
  `|` +
  // Branch B: `7 luku 3 § TSL`  (abbreviation after chapter+section)
  `(?<![A-Za-zäöÄÖ0-9])(\\d+)\\s*luku\\s+(\\d+)\\s*§\\s*(${FINNISH_ABBREV_ALTERNATION})(?![A-Za-zäöÄÖ0-9])` +
  `|` +
  // Branch C: `TSL § 7-3` or `TSL § 26` (compact slug, chapter-section
  // compound or bare section number after the §)
  `(?<![A-Za-zäöÄÖ0-9])(${FINNISH_ABBREV_ALTERNATION})\\s*§\\s*(\\d+(?:-\\d+)?)(?![A-Za-zäöÄÖ0-9])`,
  "gu",
);

/** EU directive citation regex.
 *
 *  Common shapes the model emits:
 *    • "Direktiiv 96/9/EÜ artikkel 5"
 *    • "Directive 2019/1152, Article 5"
 *    • "Direktiivi 2002/58/EU art 5"
 *    • "EU Directive 2019/1152 (2019/1152/EU)"
 *
 *  We match the YEAR/NUMBER + qualifier shape. The marker form for the
 *  same citation is CELEX-style: `[[ref:32019L1152:5]]`. Building the
 *  CELEX from "2019/1152" is a year-zero-padded prefix:
 *    "2019/1152" → "32019L1152"
 *    "96/9"      → "31996L0009"
 *  which we resolve in `directiveToCelex()` below.
 *
 *  Capture groups:
 *    1 — year (2 or 4 digits)
 *    2 — directive number (1-4 digits)
 *    3 — optional article number ("artikkel 5" / "art 5" / "Article 5") */
export const BARE_EU_DIRECTIVE_PATTERN = new RegExp(
  `(?<![A-Za-z0-9])(?:Direktiivi?|Directive)\\s*(?:nr\\.?\\s*)?(\\d{2,4})/(\\d{1,4})(?:/(?:EÜ|EU|EC|EEC))?(?:[^\\n]{0,40}?(?:artikkel|art\\.?|Article|artikli)\\s*(\\d+[a-z]?))?`,
  "giu",
);

/** ECHR article citation. Shape: "EIÕK artikkel 6", "ECHR Article 8",
 *  "Конвенция, ст. 3". We match the most common forms.
 *
 *  Capture groups:
 *    1 — article number */
export const BARE_ECHR_PATTERN = new RegExp(
  `(?<![A-Za-z])(?:EIÕK|ECHR|ECtHR)\\s*(?:artikkel|art\\.?|Article)\\s*(\\d+[a-z]?)`,
  "giu",
);

// ── 2. Marker coverage check ─────────────────────────────────────────────────

/** Build the (act_slug:paragraph) set covered by markers in the reply.
 *  Both verified AND unverified citations count as "covered" — an
 *  unverified marker still ships through to the UI with a red badge,
 *  which is the right signal. The point of enforcement is to catch
 *  the case where NO marker was emitted at all. */
function buildMarkerCoverageSet(
  replyText: string,
): Set<string> {
  const set = new Set<string>();
  const re = new RegExp(CITATION_MARKER_PATTERN, "g");
  for (const match of replyText.matchAll(re)) {
    const [, act, para] = match;
    if (!act || !para) continue;
    set.add(`${act.toLowerCase()}:${para}`);
  }
  return set;
}

/** Convert a directive shape like "2019/1152" or "96/9" to its CELEX
 *  number (`32019L1152`, `31996L0009`). CELEX format:
 *    "3" + 4-digit year + "L" + 4-digit zero-padded number
 *  2-digit years are folded to 19xx for <50 and 20xx for ≥50 — this
 *  is the EUR-Lex convention. */
function directiveToCelex(year: string, number: string): string {
  let fullYear: string;
  if (year.length === 4) {
    fullYear = year;
  } else if (year.length === 2) {
    const y = parseInt(year, 10);
    fullYear = y < 50 ? `20${year}` : `19${year}`;
  } else {
    fullYear = year.padStart(4, "0");
  }
  const padded = number.padStart(4, "0");
  return `3${fullYear}L${padded}`;
}

// ── 3. Violation taxonomy + replacement strategy ─────────────────────────────

export type ViolationKind =
  | "ee_bare_paragraph"   // e.g. "TLS § 88" with no [[ref:TLS:88]]
  | "fi_bare_paragraph"   // e.g. "TSL 7 luku 3 §" with no [[ref:fi-tsl:7-3]]
  | "eu_bare_directive"   // e.g. "Direktiiv 96/9/EÜ artikkel 5" without marker
  | "echr_bare_article"   // e.g. "ECHR Article 8" without marker
  ;

export interface CitationViolation {
  kind: ViolationKind;
  /** Exact substring that triggered the violation (verbatim from reply). */
  match: string;
  /** Lowercase act_slug we tried to match against markers. */
  act_slug: string;
  /** Paragraph / article number we expected a marker for. */
  paragraph: string;
  /** Character offset of the match in the original reply (for logging). */
  index: number;
  /** What the enforcer replaced the match with (or null = stripped wholesale). */
  replacement: string;
}

export interface EnforcementResult {
  /** Reply text after stripping bare citations that lacked markers.
   *  Identical to input when no violations were found. */
  cleanedText: string;
  /** Every violation found, in first-occurrence order. */
  violations: CitationViolation[];
}

/** Replacement strategy: keep the act abbreviation, drop the § number.
 *  Rationale: stripping the whole substring leaves a discontinuity that
 *  reads worse than a soft degradation. "TLS § 88 forbids X" becomes
 *  "TLS forbids X" — the user still sees a law mention but no longer
 *  sees a hallucinated paragraph. Down-stream UI shows a footer note
 *  ("citation was scrubbed: AI cited a paragraph it could not verify").
 *
 *  Exposed so tests can pin the exact replacement string. */
export function replacementForEstonian(actAbbrev: string): string {
  return actAbbrev;
}

/** Finnish replacement: keep the act abbreviation, drop the chapter/section
 *  reference. Same philosophy as Estonian — soft degradation reads better
 *  than a wholesale strip. */
export function replacementForFinnish(actAbbrev: string): string {
  return actAbbrev;
}

export function replacementForDirective(year: string, number: string): string {
  return `direktiiv ${year}/${number}`;
}

export function replacementForEchr(): string {
  return "ECHR";
}

// ── 4. The enforcer ──────────────────────────────────────────────────────────

/** Scan `replyText` for bare law citations that aren't covered by a
 *  `[[ref:ACT:PARA]]` marker, and produce a cleaned version of the
 *  text with those bare citations replaced. The verifier's pre-computed
 *  `citations` array is accepted but only used for logging context;
 *  the marker coverage set is rebuilt from the reply text directly so
 *  this function is correct even when called with citations=[].
 *
 *  Pure function. Idempotent: enforce(enforce(x)) === enforce(x), provided
 *  the replacement strings themselves don't contain a § symbol.
 *
 *  Algorithm:
 *    1. Build marker-coverage set: every (act_slug:paragraph) that the
 *       model wrapped in a [[ref:...:...]] marker.
 *    2. Scan for Estonian bare citations. For each match, check the
 *       coverage set. If not covered → record violation, replace inline.
 *    3. Same for EU directives (CELEX-normalized) and ECHR articles.
 *    4. Apply replacements in reverse-index order so earlier offsets
 *       remain valid during string mutation.
 *
 *  Returns `{ cleanedText, violations }`. The caller can:
 *    • Use cleanedText (default — strip & ship).
 *    • Use violations.length > 0 to decide to retry the LLM call instead. */
export function enforceCitations(
  replyText: string,
  _citations: ReadonlyArray<Citation> = [],
): EnforcementResult {
  if (!replyText) {
    return { cleanedText: replyText ?? "", violations: [] };
  }

  const coverage = buildMarkerCoverageSet(replyText);
  const violations: CitationViolation[] = [];

  // Collect all violations first WITHOUT mutating text; then splice in
  // reverse order so indices remain valid.
  type Edit = { start: number; end: number; replacement: string };
  const edits: Edit[] = [];

  // ── 4a. Estonian abbreviations ──────────────────────────────────────────
  {
    const re = new RegExp(BARE_ESTONIAN_CITATION_PATTERN.source, "gu");
    for (const m of replyText.matchAll(re)) {
      const fullMatch = m[0];
      const abbrev = m[1];
      const para = m[2];
      const idx = m.index ?? -1;
      if (!abbrev || !para || idx < 0) continue;
      const actSlug = ESTONIAN_LAW_ABBREVS.get(abbrev)
        ?? abbrev.toLowerCase();
      const key = `${actSlug}:${para}`;
      // ALSO accept a marker that points to the same act + a prefix
      // paragraph. e.g. "TLS § 88-1" should be considered covered if
      // the marker `[[ref:TLS:88]]` is present — the granular paragraph
      // exists inside the parent. Conservative: only accept if the
      // paragraph BEFORE the first hyphen has a marker.
      const parentPara = para.split(/[-–]/)[0];
      const parentKey = `${actSlug}:${parentPara}`;
      if (coverage.has(key) || coverage.has(parentKey)) continue;

      const replacement = replacementForEstonian(abbrev);
      // Compute the substring within the original match that corresponds
      // to "§ <num>..." — we keep the abbreviation, strip the rest.
      const abbrevEnd = idx + abbrev.length;
      edits.push({
        start: abbrevEnd,
        end: idx + fullMatch.length,
        replacement: "", // erase everything after the abbreviation
      });
      violations.push({
        kind: "ee_bare_paragraph",
        match: fullMatch,
        act_slug: actSlug,
        paragraph: para,
        index: idx,
        replacement,
      });
    }
  }

  // ── 4a-bis. Finnish abbreviations (Phase 2 Pkg 1) ───────────────────────
  // Finnish citations come in three shapes (see BARE_FINNISH_CITATION_PATTERN):
  //   A: `TSL 7 luku 3 §`  → groups [1,2,3] = (abbrev, chapter, section)
  //   B: `7 luku 3 § TSL`  → groups [4,5,6] = (chapter, section, abbrev)
  //   C: `TSL § 7-3`       → groups [7,8]   = (abbrev, chapter-section)
  //
  // The corpus stores paragraphs as `<chapter>-<section>` (e.g. "7-3") so
  // the marker key is `fi-tsl:7-3`. For branch C the section component is
  // already in the right shape ("7-3" or "26"); for A/B we synthesise it.
  {
    const re = new RegExp(BARE_FINNISH_CITATION_PATTERN.source, "gu");
    for (const m of replyText.matchAll(re)) {
      const fullMatch = m[0];
      const idx = m.index ?? -1;
      if (idx < 0) continue;

      let abbrev: string | undefined;
      let paragraph: string | undefined;
      if (m[1] && m[3]) {
        // Branch A: TSL 7 luku 3 §
        abbrev = m[1];
        const chapter = m[2];
        paragraph = `${chapter}-${m[3]}`;
      } else if (m[6] && m[4] && m[5]) {
        // Branch B: 7 luku 3 § TSL
        abbrev = m[6];
        paragraph = `${m[4]}-${m[5]}`;
      } else if (m[7] && m[8]) {
        // Branch C: TSL § 7-3 (compound) or TSL § 26 (bare)
        abbrev = m[7];
        paragraph = m[8];
      }
      if (!abbrev || !paragraph) continue;

      const actSlug = FINNISH_LAW_ABBREVS.get(abbrev) ??
        // Fall back to lowercase-prefixed form so the key is still
        // diagnostically useful even if a future abbreviation slips
        // through. The marker won't match (correctly flagged as bare).
        `fi-${abbrev.toLowerCase()}`;
      const key = `${actSlug}:${paragraph}`;

      // Parent paragraph rule: `TSL § 7-3` is considered covered by
      // `[[ref:fi-tsl:7]]` (chapter-level marker). This mirrors the
      // Estonian `TLS § 88-1` → `[[ref:TLS:88]]` parent rule.
      const parentPara = paragraph.split(/[-–]/)[0];
      const parentKey = `${actSlug}:${parentPara}`;
      if (coverage.has(key) || coverage.has(parentKey)) continue;

      const replacement = replacementForFinnish(abbrev);
      edits.push({
        start: idx,
        end: idx + fullMatch.length,
        replacement,
      });
      violations.push({
        kind: "fi_bare_paragraph",
        match: fullMatch,
        act_slug: actSlug,
        paragraph,
        index: idx,
        replacement,
      });
    }
  }

  // ── 4b. EU directives ───────────────────────────────────────────────────
  {
    const re = new RegExp(BARE_EU_DIRECTIVE_PATTERN.source, "giu");
    for (const m of replyText.matchAll(re)) {
      const fullMatch = m[0];
      const year = m[1];
      const number = m[2];
      const article = m[3];
      const idx = m.index ?? -1;
      if (!year || !number || idx < 0) continue;
      const celex = directiveToCelex(year, number).toLowerCase();
      // For directives the "paragraph" is the article — if no article was
      // captured, we require a marker for ANY paragraph of this directive
      // (any [[ref:<celex>:*]] suffices). This avoids over-blocking when
      // the model says "Direktiiv 96/9/EÜ" without a specific article.
      if (!article) {
        // Generic mention without article — only flag if NO marker at all
        // for this directive. Otherwise the model has cited specific
        // articles elsewhere and this is a back-reference.
        const anyArticleCovered = Array.from(coverage).some((k) =>
          k.startsWith(`${celex}:`)
        );
        if (anyArticleCovered) continue;
        // No marker for this directive at all → still flag, but use a
        // gentler replacement (just the year/number, no "Direktiiv" word).
        edits.push({
          start: idx,
          end: idx + fullMatch.length,
          replacement: replacementForDirective(year, number),
        });
        violations.push({
          kind: "eu_bare_directive",
          match: fullMatch,
          act_slug: celex,
          paragraph: "(unspecified)",
          index: idx,
          replacement: replacementForDirective(year, number),
        });
        continue;
      }
      const key = `${celex}:${article}`;
      if (coverage.has(key)) continue;
      edits.push({
        start: idx,
        end: idx + fullMatch.length,
        replacement: replacementForDirective(year, number),
      });
      violations.push({
        kind: "eu_bare_directive",
        match: fullMatch,
        act_slug: celex,
        paragraph: article,
        index: idx,
        replacement: replacementForDirective(year, number),
      });
    }
  }

  // ── 4c. ECHR articles ───────────────────────────────────────────────────
  {
    const re = new RegExp(BARE_ECHR_PATTERN.source, "giu");
    for (const m of replyText.matchAll(re)) {
      const fullMatch = m[0];
      const article = m[1];
      const idx = m.index ?? -1;
      if (!article || idx < 0) continue;
      const key = `echr:${article}`;
      const altKey = `echr-${article.toLowerCase()}`;
      if (coverage.has(key) || coverage.has(altKey)) continue;
      edits.push({
        start: idx,
        end: idx + fullMatch.length,
        replacement: replacementForEchr(),
      });
      violations.push({
        kind: "echr_bare_article",
        match: fullMatch,
        act_slug: "echr",
        paragraph: article,
        index: idx,
        replacement: replacementForEchr(),
      });
    }
  }

  // ── 4d. Apply edits in reverse-index order ──────────────────────────────
  // Deduplicate overlapping edits (highest-priority = first inserted).
  edits.sort((a, b) => a.start - b.start);
  const nonOverlapping: Edit[] = [];
  let lastEnd = -1;
  for (const e of edits) {
    if (e.start >= lastEnd) {
      nonOverlapping.push(e);
      lastEnd = e.end;
    }
  }
  nonOverlapping.sort((a, b) => b.start - a.start);
  let cleaned = replyText;
  for (const e of nonOverlapping) {
    cleaned = cleaned.slice(0, e.start) + e.replacement + cleaned.slice(e.end);
  }

  return { cleanedText: cleaned, violations };
}

/** Compact JSON-friendly summary for log lines. Keeps log volume bounded
 *  even when an attacker tries to flood violations (e.g. 100+ fake §
 *  citations in one reply). */
export function summariseViolations(
  violations: ReadonlyArray<CitationViolation>,
): { count: number; samples: Array<{ kind: ViolationKind; match: string; act_slug: string; paragraph: string }> } {
  const samples = violations.slice(0, 5).map((v) => ({
    kind: v.kind,
    match: v.match.slice(0, 80),
    act_slug: v.act_slug,
    paragraph: v.paragraph,
  }));
  return { count: violations.length, samples };
}
