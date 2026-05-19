// pdf_extractor_prompt.ts — Pkg 2 of Case Memory rebuild.
// -----------------------------------------------------------------------------
// Shared prompt + JSON-schema parser for the structured-extraction step
// inside the `pdf-parser` Edge Function. Pure module — no Deno globals,
// no I/O. Imported by the edge function and exercised directly by Deno
// tests.
//
// Spec (memory: project_handoff_smart_lawyer.md "Рабочий пакет 2 — Полный
// PDF-парсинг"):
//   * After raw text is extracted from the PDF (text-layer or Vision OCR),
//     a Sonnet 4.6 call is asked to produce strict JSON metadata describing
//     the document's legal essentials: doc_type, doc_date, parties,
//     case_numbers, key_facts, diagnoses_if_medical, monetary_amounts,
//     deadlines.
//   * Identity marker `You are a legal document extractor for the Advocat
//     app` so the system_prompt_guard whitelist accepts it (mirrors the
//     pattern used by case_patch_prompt.ts at commit 3106087 and the
//     case_file_extractor prompt at the same point).
//   * Strict JSON only — no markdown fences, no preamble.
// -----------------------------------------------------------------------------

/** Identity marker whitelisted by `system_prompt_guard.ts`. Must appear as
 * the FIRST line of the system prompt below. Exported so tests can pin it
 * in lockstep with the guard's whitelist. */
export const PDF_EXTRACTOR_IDENTITY_MARKER =
  "You are a legal document extractor for the Advocat app";

/** Sonnet model id — the same release channel claude-proxy uses for
 * heavy legal reasoning. Spec asks for "Sonnet 4.6 (smart enough)". */
export const PDF_EXTRACTOR_MODEL = "claude-sonnet-4-6";

/** Anthropic max_tokens — JSON metadata for a 50-page legal doc rarely
 * exceeds 1500 tokens; 2000 leaves headroom for long key_facts arrays. */
export const PDF_EXTRACTOR_MAX_TOKENS = 2_000;

/** Sonnet call timeout (ms). Generous because the prompt may be tens of
 * thousands of tokens of stitched OCR text. */
export const PDF_EXTRACTOR_TIMEOUT_MS = 120_000;

/** Hard cap on pages parsed in a single request. Above this, the function
 * returns `too_long` with what it managed to parse (or 0 for scans). */
export const PDF_MAX_PAGES = 100;

/** Hard cap on pages parsed via Vision OCR (no text layer). Vision is
 * ~3-5s per page; 25 keeps the worst case inside Supabase's 5min hard
 * timeout. Above this we return `scan_too_long` with no row written. */
export const PDF_MAX_VISION_PAGES = 25;

/** Below this many chars of extracted text per page, the page is treated
 * as a scan (or empty) and Vision fallback is invoked. */
export const PDF_SCAN_THRESHOLD_CHARS = 50;

/** Below this many chars of TOTAL extracted text across the whole PDF,
 * the document is treated as scan-only and Vision fallback is invoked
 * for every page. Tune up if false positives on very short legal letters. */
export const PDF_TOTAL_SCAN_THRESHOLD_CHARS = 500;

/** Vision response that is shorter than this is treated as "unreadable"
 * (model returned "no readable text" or similar). */
export const PDF_VISION_MIN_USABLE_CHARS = 50;

/** System prompt fed to Sonnet for structured extraction. Output is
 * STRICT JSON regardless of the document's source language. */
export const PDF_EXTRACTOR_SYSTEM_PROMPT =
  `${PDF_EXTRACTOR_IDENTITY_MARKER}.

You receive the FULL plain text of a legal or medical document
(possibly stitched from multiple pages with "--- PAGE N ---" markers).
The document may be in Estonian, Finnish, Russian, English, or another
language. Extract structured metadata.

Return JSON ONLY — no markdown, no preamble, no commentary — matching
EXACTLY this schema:

{
  "doc_type": "court_decision" | "medical" | "police_report" | "correspondence" | "evidence" | "other",
  "doc_date": "YYYY-MM-DD" | null,
  "parties": [{"name": "...", "role": "..."}],
  "case_numbers": [{"authority": "...", "number": "..."}],
  "key_facts": ["...", "..."],
  "diagnoses_if_medical": [{"icd_code": "F43.1", "description": "...", "severity": "..."}],
  "monetary_amounts": [{"amount": 1234.56, "currency": "EUR", "what": "..."}],
  "deadlines": [{"date": "YYYY-MM-DD", "what": "...", "statute": "..."}]
}

RULES:
- Extract ONLY facts visible in the text. NEVER invent.
- Dates strictly YYYY-MM-DD; if only year/month visible, put null in date and put the partial date in the relevant 'what' field.
- doc_date is the date the document was issued / signed / effective — pick the most authoritative one.
- doc_type: pick the single best match. Police protocols including esitutkintapöytäkirja → police_report. Medical reports including epicrisis / epikriis → medical.
- parties.role examples: plaintiff, defendant, victim, accused, witness, attorney, prosecutor, judge, doctor, patient.
- case_numbers.authority: the issuing body — e.g. "Helsingin poliisilaitos", "Helsingin hallinto-oikeus", "Tallinna Halduskohus", "PPA".
- key_facts: 3-10 short factual statements, ordered by importance. Don't quote the whole document.
- diagnoses_if_medical: empty array if not a medical document. ICD codes verbatim (F43.1, T74.0, etc.).
- monetary_amounts: include compensation requests, fines, fees, damages. Currency 3-letter ISO (EUR, USD, RUB).
- deadlines: appeal windows, statute of limitations, court hearing dates the reader must keep. 'statute' is the legal reference if cited (e.g. "HKMS § 46").
- If a list has no entries, return an empty array, not null.
- summary_replace is NOT in this schema — that's a different prompt.`;

// =============================================================================
// Patch shape
// =============================================================================

export interface ExtractedParty {
  name: string;
  role?: string;
}

export interface ExtractedCaseNumber {
  authority?: string;
  number: string;
}

export interface ExtractedDiagnosis {
  icd_code?: string;
  description?: string;
  severity?: string;
}

export interface ExtractedMoney {
  amount: number;
  currency?: string;
  what?: string;
}

export interface ExtractedDeadline {
  date?: string;
  what?: string;
  statute?: string;
}

export type DocType =
  | "court_decision"
  | "medical"
  | "police_report"
  | "correspondence"
  | "evidence"
  | "other";

export interface ExtractedDoc {
  doc_type: DocType;
  doc_date: string | null;
  parties: ExtractedParty[];
  case_numbers: ExtractedCaseNumber[];
  key_facts: string[];
  diagnoses_if_medical: ExtractedDiagnosis[];
  monetary_amounts: ExtractedMoney[];
  deadlines: ExtractedDeadline[];
}

const VALID_DOC_TYPES: readonly DocType[] = [
  "court_decision",
  "medical",
  "police_report",
  "correspondence",
  "evidence",
  "other",
];

/** Empty extraction — the safe fallback when Sonnet output is unparseable. */
export function emptyExtraction(): ExtractedDoc {
  return {
    doc_type: "other",
    doc_date: null,
    parties: [],
    case_numbers: [],
    key_facts: [],
    diagnoses_if_medical: [],
    monetary_amounts: [],
    deadlines: [],
  };
}

// =============================================================================
// Parser
// =============================================================================

/**
 * Parse Sonnet's raw JSON string into an [ExtractedDoc]. Returns `null` on:
 *   * unparseable JSON,
 *   * top-level not an object,
 *   * pathological shapes (array fields are not arrays, etc.).
 *
 * Defensive: Sonnet occasionally wraps JSON in ```json …``` markdown fences
 * despite the prompt forbidding it. We strip those before parsing.
 */
export function parseExtractedDoc(raw: unknown): ExtractedDoc | null {
  if (typeof raw !== "string") return null;
  const stripped = stripCodeFence(raw).trim();
  if (stripped.length === 0) return null;

  let json: unknown;
  try {
    json = JSON.parse(stripped);
  } catch {
    return null;
  }
  if (!json || typeof json !== "object" || Array.isArray(json)) return null;

  const obj = json as Record<string, unknown>;
  const out = emptyExtraction();

  out.doc_type = asDocType(obj.doc_type);
  out.doc_date = asIsoDateOrNull(obj.doc_date);
  out.parties = asPartyArray(obj.parties);
  out.case_numbers = asCaseNumberArray(obj.case_numbers);
  out.key_facts = asStringArray(obj.key_facts);
  out.diagnoses_if_medical = asDiagnosisArray(obj.diagnoses_if_medical);
  out.monetary_amounts = asMoneyArray(obj.monetary_amounts);
  out.deadlines = asDeadlineArray(obj.deadlines);

  return out;
}

function stripCodeFence(s: string): string {
  // Match ```json ... ``` or ``` ... ``` with arbitrary surrounding whitespace.
  const fenceRe = /^[\s`]*(?:json)?\s*\n?([\s\S]*?)\n?\s*```?\s*$/i;
  const m = s.trim().match(fenceRe);
  if (m && m[1]) return m[1];
  // Strip a leading ``` line on its own.
  return s.replace(/^```(?:json)?\s*/i, "").replace(/```\s*$/i, "");
}

function asDocType(v: unknown): DocType {
  if (typeof v !== "string") return "other";
  const lower = v.toLowerCase().trim();
  for (const t of VALID_DOC_TYPES) {
    if (t === lower) return t;
  }
  return "other";
}

function asIsoDateOrNull(v: unknown): string | null {
  if (typeof v !== "string") return null;
  const t = v.trim();
  if (t.length === 0) return null;
  // Strict YYYY-MM-DD shape; reject anything else (Sonnet sometimes emits
  // partial dates like "2026" when the prompt forbids it).
  if (!/^\d{4}-\d{2}-\d{2}$/.test(t)) return null;
  return t;
}

function asPartyArray(v: unknown): ExtractedParty[] {
  if (!Array.isArray(v)) return [];
  const out: ExtractedParty[] = [];
  for (const item of v) {
    if (!item || typeof item !== "object" || Array.isArray(item)) continue;
    const o = item as Record<string, unknown>;
    const name = typeof o.name === "string" ? o.name.trim() : "";
    if (name.length === 0) continue;
    const role = typeof o.role === "string" ? o.role.trim() : undefined;
    out.push({ name, role: role && role.length > 0 ? role : undefined });
  }
  return out;
}

function asCaseNumberArray(v: unknown): ExtractedCaseNumber[] {
  if (!Array.isArray(v)) return [];
  const out: ExtractedCaseNumber[] = [];
  for (const item of v) {
    if (!item || typeof item !== "object" || Array.isArray(item)) continue;
    const o = item as Record<string, unknown>;
    const number = typeof o.number === "string" ? o.number.trim() : "";
    if (number.length === 0) continue;
    const authority =
      typeof o.authority === "string" ? o.authority.trim() : undefined;
    out.push({
      number,
      authority: authority && authority.length > 0 ? authority : undefined,
    });
  }
  return out;
}

function asStringArray(v: unknown): string[] {
  if (!Array.isArray(v)) return [];
  const out: string[] = [];
  for (const item of v) {
    if (typeof item !== "string") continue;
    const t = item.trim();
    if (t.length > 0) out.push(t);
  }
  return out;
}

function asDiagnosisArray(v: unknown): ExtractedDiagnosis[] {
  if (!Array.isArray(v)) return [];
  const out: ExtractedDiagnosis[] = [];
  for (const item of v) {
    if (!item || typeof item !== "object" || Array.isArray(item)) continue;
    const o = item as Record<string, unknown>;
    const icd = typeof o.icd_code === "string" ? o.icd_code.trim() : undefined;
    const desc =
      typeof o.description === "string" ? o.description.trim() : undefined;
    const severity =
      typeof o.severity === "string" ? o.severity.trim() : undefined;
    if (!icd && !desc) continue;
    out.push({
      icd_code: icd && icd.length > 0 ? icd : undefined,
      description: desc && desc.length > 0 ? desc : undefined,
      severity: severity && severity.length > 0 ? severity : undefined,
    });
  }
  return out;
}

function asMoneyArray(v: unknown): ExtractedMoney[] {
  if (!Array.isArray(v)) return [];
  const out: ExtractedMoney[] = [];
  for (const item of v) {
    if (!item || typeof item !== "object" || Array.isArray(item)) continue;
    const o = item as Record<string, unknown>;
    const amt = o.amount;
    if (typeof amt !== "number" || !Number.isFinite(amt)) continue;
    const currency =
      typeof o.currency === "string" ? o.currency.trim().toUpperCase() : undefined;
    const what = typeof o.what === "string" ? o.what.trim() : undefined;
    out.push({
      amount: amt,
      currency: currency && currency.length > 0 ? currency : undefined,
      what: what && what.length > 0 ? what : undefined,
    });
  }
  return out;
}

function asDeadlineArray(v: unknown): ExtractedDeadline[] {
  if (!Array.isArray(v)) return [];
  const out: ExtractedDeadline[] = [];
  for (const item of v) {
    if (!item || typeof item !== "object" || Array.isArray(item)) continue;
    const o = item as Record<string, unknown>;
    const date = asIsoDateOrNull(o.date) ?? undefined;
    const what = typeof o.what === "string" ? o.what.trim() : undefined;
    const statute =
      typeof o.statute === "string" ? o.statute.trim() : undefined;
    if (!date && !what) continue;
    out.push({
      date,
      what: what && what.length > 0 ? what : undefined,
      statute: statute && statute.length > 0 ? statute : undefined,
    });
  }
  return out;
}

// =============================================================================
// parsed_summary builder
// =============================================================================

/**
 * Compose a short, embedding-friendly summary from the extracted JSON +
 * the first chunk of raw text. The result is what we feed to OpenAI's
 * embedding endpoint and what we store in `case_documents.parsed_summary`.
 *
 * Spec ("step 7"): "first 500 chars + extracted facts joined".
 */
export function buildParsedSummary(
  extracted: ExtractedDoc,
  parsedTextHead: string,
  maxChars = 1500,
): string {
  const head = parsedTextHead.trim().slice(0, 500);
  const facts: string[] = [];
  if (extracted.doc_type !== "other") {
    facts.push(`type=${extracted.doc_type}`);
  }
  if (extracted.doc_date) {
    facts.push(`date=${extracted.doc_date}`);
  }
  for (const p of extracted.parties.slice(0, 4)) {
    facts.push(p.role ? `${p.role}: ${p.name}` : p.name);
  }
  for (const cn of extracted.case_numbers.slice(0, 3)) {
    facts.push(cn.authority ? `${cn.authority} ${cn.number}` : cn.number);
  }
  for (const f of extracted.key_facts.slice(0, 5)) {
    facts.push(f);
  }
  for (const dx of extracted.diagnoses_if_medical.slice(0, 3)) {
    const code = dx.icd_code ?? "";
    const desc = dx.description ?? "";
    facts.push(`${code} ${desc}`.trim());
  }
  for (const dl of extracted.deadlines.slice(0, 3)) {
    const date = dl.date ?? "";
    const what = dl.what ?? "";
    facts.push(`deadline ${date} ${what}`.trim());
  }
  const joined = facts.join(" | ");
  const combined = `${head}\n\n${joined}`.trim();
  return combined.length > maxChars ? combined.slice(0, maxChars) : combined;
}

// =============================================================================
// Per-page language detection — heuristic, no API call.
// Spec calls for cheap classification; we use char-frequency ranges. The
// prompt-language label only ever feeds the UI / stored key_extractions —
// it does NOT change extraction logic.
// =============================================================================

export type LangCode = "et" | "fi" | "ru" | "en" | "uk" | "other";

/**
 * Classify a single page's language by Unicode-block counts in the first
 * ~400 chars. Bias toward Estonian (õäöü) and Finnish (åäö without õ);
 * Cyrillic ranges resolve ru/uk by ′i,ї,є,ґ presence. Falls back to
 * "other" when no signal dominates.
 */
export function detectPageLang(text: string): LangCode {
  const head = text.slice(0, 400);
  if (head.length === 0) return "other";

  let cyr = 0;
  let lat = 0;
  let hasUk = false; // ї є і ґ
  let hasOgEt = 0; // õ — Estonian-only
  let hasAoFi = 0; // ä ö (also Estonian, but combined with NO õ → Finnish)

  for (const ch of head) {
    const code = ch.codePointAt(0)!;
    if (code >= 0x0400 && code <= 0x04FF) {
      cyr++;
      if (ch === "ї" || ch === "є" || ch === "і" || ch === "ґ" ||
          ch === "Ї" || ch === "Є" || ch === "І" || ch === "Ґ") {
        hasUk = true;
      }
    } else if (code >= 0x41 && code <= 0x7A) {
      lat++;
    } else if (ch === "õ" || ch === "Õ") {
      hasOgEt++;
      lat++;
    } else if (
      ch === "ä" || ch === "Ä" || ch === "ö" || ch === "Ö" ||
      ch === "å" || ch === "Å" || ch === "ü" || ch === "Ü"
    ) {
      hasAoFi++;
      lat++;
    }
  }

  if (cyr > lat) return hasUk ? "uk" : "ru";
  if (lat === 0) return "other";

  if (hasOgEt > 0) return "et";
  if (hasAoFi > 2) return "fi";
  // Plain ASCII Latin → english.
  return "en";
}
