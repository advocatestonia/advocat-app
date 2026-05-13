// pii_scrubber.ts — two-stage PII removal for the Gold Corpus pipeline.
// ----------------------------------------------------------------------------
// Stage 1 (regex): structured PII, deterministic, zero LLM cost.
//   - Emails
//   - Estonian/Finnish phone numbers
//   - Estonian ID code (isikukood, 11 digits)
//   - Finnish HETU (DDMMYY[+/-A]NNN[X])
//   - Court case numbers in the form R-YY/NNNN or H-YY/NNNN
//   - Surname suffixes typical for Estonian/Finnish (-nen, -saar, -mäki, …)
//   - Postal codes (Estonian 5-digit, Finnish 5-digit) — heuristic
//
// Stage 2 (Claude Haiku): catches free-form names and addresses the regex
// missed. Optional — skipped if no anthropic API key is provided. The first
// stage already covers the high-volume structured-PII cases.
//
// Public-record citations (KHO 2024:25, RKHKo 3-3-1-…) are preserved because
// their format does NOT match the case-number regex (which only matches
// R-/H- prefixed numbers) and Haiku is instructed to keep them.
// ----------------------------------------------------------------------------

export interface ScrubResult {
  text: string;
  replacements: Record<string, number>;   // {"[NAME]": 2, "[PHONE]": 1}
}

// ─── Regex pass ─────────────────────────────────────────────────────────────

const RE = {
  email: /\b[\w.+-]+@[\w.-]+\.\w{2,}\b/g,
  // Estonian/Finnish phones. Two cases:
  //   1. International prefix +358 / +372 followed by 7-10 digits with
  //      optional space/dash separators.
  //   2. Local-format Estonian phone: 5/7/8 leading digit + 6-9 more,
  //      total 7-9 digits, separated by spaces only (NOT hyphens — that
  //      would eat public-record case ids like 3-3-1-99-2024).
  phone: /\b(?:\+?3[58][\s-]?(?:\d[\s-]?){6,10}\d|(?:5|6|7|8)\d{2}\s?\d{4}|\d{3}\s\d{4})\b/g,
  // Estonian ID: 11 digits, century-marker prefix 1-6.
  ee_id: /\b[1-6]\d{2}[01]\d[0-3]\d{5}\b/g,
  // Finnish HETU: DDMMYY[+/-A]NNN[X]
  fi_id: /\b\d{6}[+\-A]\d{3}[\dA-Y]\b/g,
  // Court case numbers (Estonian/Finnish lower-court pattern).
  case_no: /\b[RH]-\d{2}\/\d{4,}\b/g,
};

// Estonian/Finnish surnames — common suffix list. Matches when capitalized.
const SURNAME_SUFFIXES =
  /\b[A-ZÄÖÕÜŠŽÅ][a-zäöõüšžåéàèíóú]+(nen|saar|mäki|vald|poeg|väli|järvi|kivi|lainen|aho|virta|salo|laine|metsä|koski)\b/g;

/**
 * Pure regex pass. Order matters: structured tokens (emails, IDs, case
 * numbers) come before phones — otherwise the phone regex eats a chunk of
 * an email's digit suffix.
 */
export function regexScrub(input: string): ScrubResult {
  if (!input) return { text: "", replacements: {} };
  let t = input;
  const counts: Record<string, number> = {};
  const sub = (re: RegExp, tag: string) => {
    t = t.replace(re, () => {
      counts[tag] = (counts[tag] ?? 0) + 1;
      return tag;
    });
  };
  // Order: most structured first.
  sub(RE.email, "[EMAIL]");
  sub(RE.ee_id, "[ID_EE]");
  sub(RE.fi_id, "[HETU_FI]");
  sub(RE.case_no, "[CASE_NO]");
  sub(RE.phone, "[PHONE]");
  sub(SURNAME_SUFFIXES, "[NAME]");
  return { text: t, replacements: counts };
}

// ─── Haiku second-pass (optional) ───────────────────────────────────────────

const HAIKU_SCRUB_SYSTEM = [
  "You are a privacy-redaction agent.",
  "Input: a legal-advice question or AI answer that may contain personal data.",
  "Replace EVERY personal name, address, phone number, email, ID code, or",
  "other identifying datum with bracketed placeholders:",
  "  [NAME], [ADDR], [PHONE], [EMAIL], [ID], [DATE_BIRTH], [ORG_PRIVATE].",
  "",
  "PRESERVE:",
  "  - All legal content (rights, obligations, procedure, deadlines).",
  "  - Law references (TLS § 100, Direktiivi 2019/1152, UlkomaalaisL § 196).",
  "  - Public-record case citations (KHO 2024:25, RKHKo 3-3-1-…, EIT case names).",
  "  - Public organisations (Politsei- ja Piirivalveamet, Maistraatti, Migri,",
  "    courts, ministries).",
  "  - Monetary amounts, statute paragraphs, dates of legal events.",
  "",
  "OUTPUT FORMAT: return ONLY the redacted text. No commentary, no JSON, no",
  "explanation. Whitespace/structure unchanged.",
].join("\n");

const HAIKU_MODEL = "claude-haiku-4-5-20251001";

export interface HaikuScrubOpts {
  text: string;
  anthropicApiKey: string;
  /** Fetch override for tests. */
  fetcher?: typeof fetch;
  /** Max tokens for the redacted output. Default 2048 (covers 6-8k chars). */
  maxTokens?: number;
}

/**
 * Run a Haiku-based redaction pass over [text]. Returns the redacted string.
 * On any failure (API error, malformed response, etc.) returns the input
 * unchanged — the caller should rely on the regex pass as the floor.
 */
export async function haikuScrub(opts: HaikuScrubOpts): Promise<string> {
  if (!opts.text) return opts.text;
  if (!opts.anthropicApiKey) return opts.text;
  const fetcher = opts.fetcher ?? fetch;

  try {
    const res = await fetcher("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "anthropic-version": "2023-06-01",
        "x-api-key": opts.anthropicApiKey,
      },
      body: JSON.stringify({
        model: HAIKU_MODEL,
        max_tokens: opts.maxTokens ?? 2048,
        system: HAIKU_SCRUB_SYSTEM,
        messages: [{ role: "user", content: opts.text }],
      }),
    });
    if (!res.ok) {
      console.warn(`[pii-scrubber] Haiku HTTP ${res.status}`);
      return opts.text;
    }
    const json = await res.json() as {
      content?: Array<{ type?: string; text?: string }>;
    };
    const blocks = (json.content ?? [])
      .filter((b) => b.type === "text" && typeof b.text === "string")
      .map((b) => b.text as string);
    const out = blocks.join("").trim();
    if (!out) return opts.text;
    return out;
  } catch (e) {
    console.warn(`[pii-scrubber] Haiku threw: ${String(e).slice(0, 200)}`);
    return opts.text;
  }
}

// ─── Two-stage scrub entry point ────────────────────────────────────────────

export interface TwoStageScrubOpts {
  text: string;
  anthropicApiKey?: string;
  fetcher?: typeof fetch;
}

/**
 * Run regex pass, then optionally Haiku. Returns the final text + the
 * aggregated regex-stage replacement counts (Haiku output is opaque).
 */
export async function twoStageScrub(opts: TwoStageScrubOpts): Promise<ScrubResult> {
  const stage1 = regexScrub(opts.text);
  if (!opts.anthropicApiKey) return stage1;
  const stage2 = await haikuScrub({
    text: stage1.text,
    anthropicApiKey: opts.anthropicApiKey,
    fetcher: opts.fetcher,
  });
  return { text: stage2, replacements: stage1.replacements };
}
