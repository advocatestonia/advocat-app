// Pure helpers for the rt-fetcher edge function — extracted into a
// separate module so the Deno test suite can import them directly without
// reflecting source text through `new Function()`. Everything in this file
// is dependency-free and side-effect-free; it is safe to import from any
// context (tests, edge runtime, future Node-based backfill scripts).
//
// Targets Riigi Teataja's "tyviseadus" XML schema (currently
// tyviseadus_1_10.02.2010.xsd). The schema is fully documented at
// http://xmlr.eesti.ee/xml/schemas/oigusakt/tyviseadus_1_10.02.2010.xsd and
// is wonderfully stable — the XSD file has not changed since 2010 even as
// the rendering layer has been completely rewritten twice.
//
// Hierarchy we care about (outer → inner):
//   <oigusakt>
//     <metaandmed>  — pealkiri, lyhend, kehtivuseAlgus/Lopp, globaalID
//     <osa>         — optional Part (TsÜS has 8 of these; HMS has none)
//       <peatykk>   — Chapter (almost every act has these)
//         <jagu>    — optional Section/division
//           <paragrahv>  — § — the unit we chunk
//             <paragrahvNr ylaIndeks="?">N</paragrahvNr>  -- "100" or "100¹"
//             <paragrahvPealkiri>...</paragrahvPealkiri>
//             <loige>  — subsection
//               <loigeNr>  — (1), (2), …  -- optional for single-loige §s
//               <sisuTekst><tavatekst>...
//
// We chunk one row per <paragrahv>. Multi-loige paragraphs are joined into
// one text body so the embedding can carry the whole § as context. The §
// number with optional ylaIndeks superscript becomes the `section`; the
// chapter number (from the closest enclosing <peatykk>) becomes `chapter`.

export interface ActMeta {
  act_slug: string;       // "ee-tsus"
  act_abbrev: string;     // "TsÜS"
  act_full_name: string;  // "Tsiviilseadustiku üldosa seadus"
  lang: string;           // "et"
  source_url: string;     // canonical RT XML URL for this act
  global_id?: string;     // RT global act id (e.g. "131122024048")
}

export interface Section {
  num: string;            // "86"  or  "100¹"  (ylaIndeks rendered as superscript)
  chapter?: string;       // "8"  if known
  heading: string;        // "Tehing"
  text: string;           // full paragraph text (joined subsections)
}

// ── Citation utilities — EE convention `TsÜS § 86` ────────────────────────
//
// CRITICAL — EE convention puts § BEFORE the number (opposite of FI). This
// is the BINDING rule for downstream citation matchers; never invert.
//
// Chapter-less form (typical for EE — most EE acts have chapters but users
// rarely cite the chapter): `TsÜS § 86`
// Chapter-bearing form (rare in EE practice but produced when the parser
// has chapter context): `TsÜS § 86 (ptk 4)`  — we DON'T emit this; we emit
// `TsÜS § 86` and store the chapter in the `chapter` column.

/** Canonical EE citation for one section. § BEFORE number — binding. */
export function sectionLabel(
  abbrev: string,
  sectionNum: string,
  _chapter?: string,
): string {
  // _chapter is accepted for API symmetry with finlex-fetcher but EE
  // citation convention does NOT include chapter in the label. The
  // chapter is still preserved in the law_chunks_v2.chapter column.
  return `${abbrev} § ${sectionNum.trim()}`;
}

/**
 * Alias variants for fuzzy lookup. EE conventions we observe in user
 * queries (from chat logs / support tickets / our own DB):
 *
 *   canonical:        "TsÜS § 86"
 *   with full name:   "Tsiviilseadustiku üldosa seadus § 86"
 *   abbrev lowercase: "tsüs § 86"
 *   no space:         "TsÜS §86"
 *   reversed:         "§ 86 TsÜS"   — common_misspelling
 *   compact alt:      "TsÜS-§86"    — common_misspelling (Estonian compound style)
 *
 * pattern_kind values come from the statute_aliases CHECK constraint:
 *   'exact' | 'regex' | 'common_misspelling'
 */
export function aliasVariants(
  meta: ActMeta,
  sectionNum: string,
  _chapter?: string,
): { alias: string; pattern_kind: string }[] {
  const N = sectionNum.trim();
  const A = meta.act_abbrev;
  const F = meta.act_full_name;

  const out: { alias: string; pattern_kind: string }[] = [
    { alias: `${A} § ${N}`, pattern_kind: "exact" },                     // canonical
    { alias: `${F} § ${N}`, pattern_kind: "exact" },                     // full name
    { alias: `${A} §${N}`, pattern_kind: "exact" },                      // compact
    { alias: `${F.toLowerCase()} § ${N}`, pattern_kind: "exact" },       // full lowercase
    { alias: `${A.toLowerCase()} § ${N}`, pattern_kind: "exact" },       // abbrev lowercase
    { alias: `§ ${N} ${A}`, pattern_kind: "common_misspelling" },        // reversed
  ];
  return out;
}

// ── Riigi Teataja XML parsing ─────────────────────────────────────────────

/**
 * Strip XML tags + CDATA shells and decode the entities RT emits.
 * RT's tyviseadus schema is predictable enough that a tag-strip + text-
 * collapse pipeline yields clean Estonian legal text.
 */
export function stripAndDecode(xml: string): string {
  return xml
    // Unwrap CDATA — RT uses it heavily inside <kuvatavNr> and <tavatekst>.
    .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, "$1")
    // Drop all tags (including <sup>, <br/>, <span class="mm">…</span>).
    .replace(/<[^>]+>/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&nbsp;/g, " ")
    .replace(/&#(\d+);/g, (_, n) => String.fromCharCode(Number(n)))
    .replace(/\s+/g, " ")
    .trim();
}

// Superscript digit table — paragrahvNr ylaIndeks="N" becomes "N" as
// Unicode superscript so the citation surfaces as "§ 100¹" not "§ 100/1".
// Matches the rendering at riigiteataja.ee and how Estonian lawyers write.
const SUPERSCRIPT: Record<string, string> = {
  "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴",
  "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹",
};

function toSuperscript(s: string): string {
  return [...s].map((c) => SUPERSCRIPT[c] ?? c).join("");
}

/**
 * Render a (paragrahvNr, ylaIndeks?) pair as the section number string.
 * Examples:
 *   ("86", undefined) → "86"
 *   ("100", "1")      → "100¹"
 *   ("100", "12")     → "100¹²"   (rare but valid)
 */
export function renderSectionNum(numRaw: string, ylaIndeks?: string): string {
  const N = numRaw.trim();
  if (!ylaIndeks || !ylaIndeks.trim()) return N;
  return `${N}${toSuperscript(ylaIndeks.trim())}`;
}

interface MetaInfo {
  pealkiri?: string;
  lyhend?: string;
  globalId?: string;
  kehtivuseAlgus?: string;
  kehtivuseLopp?: string;
}

/** Pull a few useful metadata fields out of <metaandmed>. */
export function parseMetadata(xml: string): MetaInfo {
  // <metaandmed> sits at the top of every RT XML; we don't need to descend
  // deeply because each child we care about is leaf-text.
  const metaM = /<metaandmed\b[^>]*>([\s\S]*?)<\/metaandmed>/i.exec(xml);
  if (!metaM) return {};
  const inner = metaM[1];

  function tag(re: RegExp): string | undefined {
    const m = re.exec(inner);
    if (!m) return undefined;
    return stripAndDecode(m[1]);
  }

  return {
    pealkiri: tag(/<pealkiri\b[^>]*>([\s\S]*?)<\/pealkiri>/i),
    lyhend: tag(/<lyhend\b[^>]*>([\s\S]*?)<\/lyhend>/i),
    globalId: tag(/<globaalID\b[^>]*>([\s\S]*?)<\/globaalID>/i),
    kehtivuseAlgus: tag(/<kehtivuseAlgus\b[^>]*>([\s\S]*?)<\/kehtivuseAlgus>/i),
    kehtivuseLopp: tag(/<kehtivuseLopp\b[^>]*>([\s\S]*?)<\/kehtivuseLopp>/i),
  };
}

/**
 * Walk a tyviseadus RT XML and yield one Section per <paragrahv>. Chapter
 * context (the closest enclosing <peatykk>) is captured for the `chapter`
 * field.
 *
 * Regex-based — RT XML is deterministic and well-formed; pulling in
 * deno-dom for one job is not worth the cold-start cost. If RT ever ships
 * tyviseadus_2 with structural breaks, parser tests in
 * __tests__/rt_fetcher_test.ts will catch the regression.
 */
export function parseStatuteXml(xml: string): Section[] {
  const sections: Section[] = [];

  // We track chapter scope by scanning <peatykk> blocks first and recording
  // their byte ranges, then matching <paragrahv> elements and assigning the
  // enclosing chapter (if any).
  interface ChapterRange {
    num: string;
    lo: number;
    hi: number;
  }
  const chapterRanges: ChapterRange[] = [];

  const chapterRe = /<peatykk\b[^>]*>([\s\S]*?)<\/peatykk>/g;
  let cm: RegExpExecArray | null;
  while ((cm = chapterRe.exec(xml)) !== null) {
    const inner = cm[1];
    const numM = /<peatykkNr\b[^>]*>([^<]+)<\/peatykkNr>/i.exec(inner);
    const num = numM ? stripAndDecode(numM[1]).match(/\d+/)?.[0] : undefined;
    if (!num) continue;
    const innerStart = cm.index + cm[0].indexOf(inner);
    chapterRanges.push({
      num,
      lo: innerStart,
      hi: innerStart + inner.length,
    });
  }

  function chapterFor(offset: number): string | undefined {
    // Innermost wins — chapters don't nest in tyviseadus but a paragrahv
    // sometimes sits at osa-level outside any peatykk (e.g. transitional
    // provisions). Linear scan is fine: max ~30 chapters per act.
    for (let i = chapterRanges.length - 1; i >= 0; i--) {
      const r = chapterRanges[i];
      if (offset >= r.lo && offset <= r.hi) return r.num;
    }
    return undefined;
  }

  const paragrahvRe = /<paragrahv\b([^>]*)>([\s\S]*?)<\/paragrahv>/g;
  let pm: RegExpExecArray | null;
  while ((pm = paragrahvRe.exec(xml)) !== null) {
    const tagAttrs = pm[1];
    const block = pm[2];

    // Pull out <paragrahvNr ylaIndeks="N">N</paragrahvNr>. RT puts ylaIndeks
    // on the OPENING tag of <paragrahvNr>, not on <paragrahv>.
    const nrM = /<paragrahvNr\b([^>]*)>([^<]+)<\/paragrahvNr>/i.exec(block);
    if (!nrM) continue;
    const nrAttrs = nrM[1];
    const numRaw = stripAndDecode(nrM[2]);
    if (!numRaw) continue;
    // Only accept paragrahvNr whose body is digits (skip "kumottu", textual
    // markers, etc. that RT very occasionally emits as a placeholder).
    if (!/^\d+/.test(numRaw)) continue;
    const numDigits = numRaw.match(/\d+/)![0];
    const ylaM = /ylaIndeks="([^"]+)"/i.exec(nrAttrs);
    const ylaIndeks = ylaM ? ylaM[1] : undefined;
    const sectionNum = renderSectionNum(numDigits, ylaIndeks);

    // Heading (paragrahvPealkiri). Optional — some § have no title.
    const headingM = /<paragrahvPealkiri\b[^>]*>([\s\S]*?)<\/paragrahvPealkiri>/i.exec(block);
    const heading = headingM ? stripAndDecode(headingM[1]) : "";

    // Body — concatenate every <tavatekst> in document order. We deliberately
    // keep <loigeNr> kuvatavNr markers like "(1)", "(2)" by reading from
    // <loige> blocks: this preserves the subsection structure in plain text
    // form ("(1) … (2) …") so embeddings see the structural cues humans see.
    const bodyParts: string[] = [];
    const loigeRe = /<loige\b[^>]*>([\s\S]*?)<\/loige>/g;
    let lm: RegExpExecArray | null;
    let loigeCount = 0;
    while ((lm = loigeRe.exec(block)) !== null) {
      loigeCount++;
      const li = lm[1];
      const kuvM = /<kuvatavNr\b[^>]*>([\s\S]*?)<\/kuvatavNr>/i.exec(li);
      const marker = kuvM ? stripAndDecode(kuvM[1]) : "";
      // Strip both kuvatavNr (the rendered "(1)") AND loigeNr (the raw "1")
      // so neither appears in the embedded body. We use the marker we
      // already extracted to prepend instead — that gives clean
      // "(1) Esimene lõige." output, not "(1) 1 Esimene lõige.".
      const liWithoutMarkers = li
        .replace(/<kuvatavNr\b[^>]*>[\s\S]*?<\/kuvatavNr>/gi, "")
        .replace(/<loigeNr\b[^>]*>[\s\S]*?<\/loigeNr>/gi, "");
      const textOnly = stripAndDecode(liWithoutMarkers);
      if (!textOnly) continue;
      if (marker) {
        bodyParts.push(`${marker} ${textOnly}`);
      } else {
        bodyParts.push(textOnly);
      }
    }
    // Fallback: if no <loige> matched (rare — happens for § that contain
    // <tavatekst> directly without an enclosing <loige>), fall back to a
    // wholesale strip of the block minus the metadata bits we already
    // captured.
    let text: string;
    if (loigeCount > 0 && bodyParts.length > 0) {
      text = bodyParts.join(" ");
    } else {
      const stripped = block
        .replace(/<paragrahvNr\b[^>]*>[\s\S]*?<\/paragrahvNr>/gi, " ")
        .replace(/<kuvatavNr\b[^>]*>[\s\S]*?<\/kuvatavNr>/gi, " ")
        .replace(/<loigeNr\b[^>]*>[\s\S]*?<\/loigeNr>/gi, " ")
        .replace(/<paragrahvPealkiri\b[^>]*>[\s\S]*?<\/paragrahvPealkiri>/gi, " ");
      text = stripAndDecode(stripped);
    }

    if (!text || text.length < 5) continue;

    // Silence unused-variable lint — tagAttrs reserved for future use
    // (e.g. handling paragrahv-level kehtivus attributes).
    void tagAttrs;

    sections.push({
      num: sectionNum,
      chapter: chapterFor(pm.index),
      heading,
      text,
    });
  }

  return sections;
}
