// he-fetcher/extractor_prompt.ts — Sonnet prompt for travaux section split.
// -----------------------------------------------------------------------------
// We hand Sonnet the raw text of a free-form legislative document (FI HE PDF/
// HTML or EE eelnõu / seletuskiri PDF/HTML) and ask it to slice the
// explanatory commentary by the statute § it interprets, returning strict JSON.
//
// Free-form bill documents have a predictable structure on both sides:
//
//   FI Hallituksen esitys:
//     0. Esityksen pääasiallinen sisältö      (skip — pure summary, no § ref)
//     1. Yleisperustelut                      (chunk by chapter, optional § hits)
//     2. Yksityiskohtaiset perustelut         (HOT: section-by-section comments,
//        2.1 [statute name]                    contains direct "1 §", "2 §" headings
//        2.1.1 1 §                              that map 1:1 to the act sections)
//     3. Voimaantulo                          (skip — no § ref)
//     4. Suhde perustuslakiin                 (optional, low yield)
//
//   EE seletuskiri / eelnõu (note: structure varies more than FI HE!):
//     Newer bills (post-2007):
//       1. Sissejuhatus                       (skip — preamble)
//       2. Eelnõu sisu ja võrdlev analüüs     (HOT: §-by-§ explanation,
//          2.1 § 1                              "Eelnõu §-ga 12 muudetakse...")
//          2.2 § 2
//       3. Eelnõu terminoloogia               (skip — glossary)
//       4. Eelnõu vastavus Euroopa Liidu õigusele (skip)
//       5. Seaduse mõjud / Mõjuanalüüs        (skip)
//     Older bills (1992-2006 IX/X-coosseis):
//       Often NO seletuskiri exists — only the algtekst (bill text itself).
//       The bill text is structured as `§ 1. ...`, `§ 2. ...` headings.
//       In this case, Sonnet should chunk each § as its own entry with the
//       § number as section_ref and the § body as text.
//
// Our extraction prompt below targets both structures and tells Sonnet to
// detect the input language + structure automatically.
//
// Output contract — STRICT JSON, single top-level array:
//   [
//     { "section_ref": "114", "text": "..." },
//     { "section_ref": "114.1", "text": "..." },   // subsection if available
//     { "section_ref": null, "text": "..." }       // yleisperustelu w/o §
//   ]
//
// section_ref normalisation rules (told to Sonnet, enforced in code):
//   - Use bare statute § number (e.g. "114", "114.1", "12 a").
//   - DROP "§" / "vp" / "lk" / "ptk" prefixes.
//   - "1 mom." / "lg 1" → ".1" suffix on the parent.
//   - Multi-§ chunks (e.g. "114-117 §§") → repeat the entry per §.
//
// Why Sonnet (not Haiku):
//   The HE 217/1995 vp section 2.1.1 "114 §" passage is six pages of dense
//   prose with no machine-readable markers. Haiku splits it at heading
//   boundaries that don't exist, dropping the 5-year rationale text into
//   the wrong section. Sonnet handles it correctly. Cost: ~50K tok in,
//   ~10K tok out, ≈$0.15 per document. Budget for 30 docs ≈ $4.50.
// -----------------------------------------------------------------------------

// Sonnet 4 (May 2025 stable). Matches the model used elsewhere in the codebase
// (claude-proxy SONNET_MODEL). PDF input is supported on this model.
export const HE_FETCHER_MODEL = "claude-sonnet-4-20250514";
/** Output budget. HOL §114 alone is ~3K tok; 30+ §§ × 1.5K each ≈ 45K cap. */
export const HE_FETCHER_MAX_TOKENS = 8000;
/** 180s — Claude native PDF support adds latency, and 30+ page HEs need time. */
export const HE_FETCHER_TIMEOUT_MS = 180_000;
/** Hard cap on the input we send to Sonnet (chars). 200K-tok context = ~600K chars; we leave headroom. */
export const HE_FETCHER_MAX_INPUT_CHARS = 350_000;

export const HE_FETCHER_SYSTEM_PROMPT = [
  "You are a legal-information extractor for the Advocat app.",
  "",
  "Your job: read a Finnish Hallituksen esitys (HE) OR an Estonian eelnõu /",
  "seletuskiri document, and emit STRICT JSON that maps each explanatory or",
  "normative passage to the statute § it interprets / introduces.",
  "",
  "INPUT DETECTION — detect the language and structure BEFORE chunking:",
  "  - Finnish HE: look for `Hallituksen esitys`, `Yksityiskohtaiset",
  "    perustelut`, `Yleisperustelut`, `voimaantulosäännös`. The HOT zone",
  "    is `Yksityiskohtaiset perustelut`, where you find headings like",
  "    `1 §`, `12 §`, `114 §` followed by 1-6 pages of prose per §.",
  "  - Estonian eelnõu/seletuskiri: look for `Eelnõu`, `Seletuskiri`,",
  "    `§ 1.`, `§ 2.`, or phrases like `Eelnõu §-ga 12 muudetakse`,",
  "    `Eelnõu § 3 lõige 1 sätestab`. Modern seletuskirjad have a",
  "    `Eelnõu sisu ja võrdlev analüüs` section organised by §.",
  "    Older bills (IX/X coosseis, pre-2007) often have NO separate",
  "    seletuskiri — the document IS the algtekst (bill text). In that",
  "    case the structure is `§ 1. Title. Body...` `§ 2. Title. Body...`",
  "    and you should output each § body as its own chunk.",
  "",
  "OUTPUT FORMAT — single JSON array, nothing before or after:",
  '  [ { "section_ref": "114", "text": "..." }, ... ]',
  "",
  "RULES:",
  '  1. section_ref is the bare § number — no "§", no "vp", no "art." prefix.',
  '     Examples: "114", "114.1", "12 a", "29 b".',
  "  2. Sub-sections / momentit / lõiked:",
  '     - FI "1 mom." → parent + ".1" suffix (e.g. "114.1")',
  '     - FI "2 mom." → ".2"',
  '     - EE "lg 1" / "lõige 1" → ".1"',
  '     - EE "lg 2" / "lõige 2" → ".2"',
  "  3. If a passage discusses multiple §§ (e.g. FI `114-117 §§` or EE",
  "     `§§ 5-7`), repeat the entry once per §, splitting the prose if",
  "     any sentence is § specific. If the prose is generic across the",
  '     range, emit one entry per § with section_ref set per §.',
  '  4. If the passage is a general motive (FI yleisperustelu /',
  '     EE sissejuhatus) with no § reference, use "section_ref": null.',
  "     Include only if substantive (200+ chars of actual legal reasoning).",
  "  5. SKIP boilerplate: title page, table of contents, voimaantulosäännös,",
  "     säädöskokoelma, ELI-metadata, EU-direktiivi viited, eelnõu menetluse",
  "     etapid, koosseisu liikmete nimekiri. They have no interpretive value.",
  '  6. Each "text" field: 200-3000 characters. If a single § discussion is',
  "     longer than 3000 chars, split into two entries with the SAME section_ref.",
  "  7. Preserve the source language (Finnish / Swedish / Estonian) verbatim.",
  "     Do NOT translate. Do NOT summarise. Output the actual prose.",
  "  8. Output ONLY the JSON array. No markdown fences, no commentary.",
  "",
  "EE-specific extraction tips:",
  "  - References like `Eelnõu §-ga 5 muudetakse` → section_ref `5`.",
  "  - References like `KarS § 199 lg 2` → section_ref `199.2`.",
  "  - If the document is just the algtekst (bill text without seletuskiri),",
  "    each `§ N. Pealkiri. Body...` block is one chunk with section_ref `N`.",
  "    The pealkiri (title) is part of the text.",
  "",
  "If the document is unreadable / pure scan / wrong format / contains no",
  "§-keyed content, emit []. Do not make up section numbers.",
].join("\n");

export interface ExtractedTravauxChunk {
  section_ref: string | null;
  text: string;
}

/** Parse Sonnet's JSON output defensively. Returns [] on any malformed input. */
export function parseTravauxOutput(raw: string): ExtractedTravauxChunk[] {
  if (!raw || typeof raw !== "string") return [];
  // Strip optional ```json fences Sonnet sometimes adds despite instructions.
  const cleaned = raw
    .replace(/^\s*```(?:json)?\s*/i, "")
    .replace(/\s*```\s*$/i, "")
    .trim();
  let parsed: unknown;
  try {
    parsed = JSON.parse(cleaned);
  } catch {
    return [];
  }
  if (!Array.isArray(parsed)) return [];
  const out: ExtractedTravauxChunk[] = [];
  for (const row of parsed) {
    if (!row || typeof row !== "object") continue;
    const r = row as Record<string, unknown>;
    const text = typeof r.text === "string" ? r.text.trim() : "";
    if (text.length < 50) continue; // drop noise
    const rawRef = r.section_ref;
    const section_ref: string | null = typeof rawRef === "string"
      ? normaliseSectionRef(rawRef)
      : null;
    out.push({ section_ref, text });
  }
  return out;
}

/** Strip "§", "vp", trim spaces, etc. Returns null if the result is empty. */
export function normaliseSectionRef(raw: string): string | null {
  const cleaned = raw
    .replace(/§/g, "")
    .replace(/\bvp\b/gi, "")
    .replace(/\bart\.?\b/gi, "")
    .replace(/\bsection\b/gi, "")
    .replace(/[()]/g, "")
    .replace(/\s+/g, " ")
    .trim();
  if (!cleaned) return null;
  // Cap length so a hallucinated paragraph doesn't blow out the column.
  return cleaned.slice(0, 40);
}
