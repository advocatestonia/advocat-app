// he-fetcher/extractor_prompt.ts — Sonnet prompt for travaux section split.
// -----------------------------------------------------------------------------
// We hand Sonnet the raw text of a free-form legislative document (HE PDF or
// eelnõu HTML) and ask it to slice the explanatory commentary by the
// statute § it interprets, returning strict JSON.
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
//   EE seletuskiri:
//     1. Sissejuhatus                         (skip — preamble)
//     2. Eelnõu sisu ja võrdlev analüüs       (HOT: §-by-§ explanation)
//        2.1 § 1
//        2.2 § 2
//     3. Eelnõu vastavus Euroopa Liidu õigusele (skip)
//     4. Seaduse mõjud                        (skip)
//
// Our extraction prompt below targets the HOT section explicitly.
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

export const HE_FETCHER_MODEL = "claude-sonnet-4-6";
/** Output budget. HOL §114 alone is ~3K tok; 30+ §§ × 1.5K each ≈ 45K cap. */
export const HE_FETCHER_MAX_TOKENS = 8000;
/** 60s — free-form PDFs are slow to reason over. */
export const HE_FETCHER_TIMEOUT_MS = 60_000;
/** Hard cap on the input we send to Sonnet (chars). 200K-tok context = ~600K chars; we leave headroom. */
export const HE_FETCHER_MAX_INPUT_CHARS = 350_000;

export const HE_FETCHER_SYSTEM_PROMPT = [
  "You are a legal-information extractor for the Advocat app.",
  "",
  "Your job: read a Finnish Hallituksen esitys (HE) PDF text OR an Estonian",
  "eelnõu / seletuskiri HTML text, and emit STRICT JSON that maps each",
  "explanatory passage to the statute § it interprets.",
  "",
  "OUTPUT FORMAT — single JSON array, nothing before or after:",
  '  [ { "section_ref": "114", "text": "..." }, ... ]',
  "",
  "RULES:",
  '  1. section_ref is the bare § number — no "§", no "vp", no "art." prefix.',
  '     Examples: "114", "114.1", "12 a", "29 b".',
  '  2. Sub-sections / "momentit": parent "." subnum. "1 mom." → ".1", "2 mom." → ".2".',
  "  3. If a passage discusses multiple §§ (e.g. 114-117 §§), repeat the entry",
  "     once per §, splitting the prose if any sentence is § specific.",
  '  4. If the passage is a general motive (yleisperustelu / sissejuhatus) with',
  '     no § reference, use "section_ref": null. Include only if substantive.',
  "  5. SKIP boilerplate: title page, table of contents, voimaantulosäännös,",
  "     säädöskokoelma, ELI-metadata. They have no interpretive value.",
  '  6. Each "text" field: 200-3000 characters. If a single § discussion is',
  "     longer than 3000 chars, split into two entries with the SAME section_ref.",
  "  7. Preserve the source language (Finnish / Swedish / Estonian) verbatim.",
  '     Do NOT translate. Do NOT summarise. Output the actual prose.',
  "  8. Output ONLY the JSON array. No markdown fences, no commentary.",
  "",
  "If the document is unreadable / pure scan / wrong format, emit []. Do not",
  "make up section numbers.",
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
