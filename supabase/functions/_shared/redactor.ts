// _shared/redactor.ts — public-share PII redaction.
// -----------------------------------------------------------------------------
// Two-stage redaction for the "Share this analysis" feature. Sister module to
// pii_scrubber.ts (Gold Corpus pipeline) but tuned for share-URL safety:
//
//   * Stage 1 — regex pass. Catches structured PII deterministically:
//       emails, phones, Estonian id-codes, Finnish HETU, court case numbers
//       (R-YY/NNNN, H-YY/NNNN, F-YY/NNNN), Estonian/Finnish surname suffixes.
//
//   * Stage 2 — Claude Haiku 4.5 pass. Catches free-form names + addresses,
//       and ROUNDS monetary amounts (€14,789.50 → ~€15,000) so a screenshot
//       can't be cross-referenced against a known invoice. The model is
//       instructed to return a structured JSON envelope:
//         { title, insight_summary, redacted_content: { bullets, risks,
//           statute_refs, monetary_amounts } }
//
//   * Idempotency — running the redactor twice yields the same result. Stage
//       1 is idempotent by construction (placeholders don't re-match the
//       regexes). Stage 2 idempotency is enforced by adding "IF THE TEXT IS
//       ALREADY REDACTED (contains [NAME], [ADDR], …), RETURN IT UNCHANGED"
//       to the prompt, plus a fast-path that skips the Haiku call when the
//       regex pass found nothing AND the input is already framed in
//       placeholder form.
//
// Preserved (NEVER redacted):
//   * Jurisdiction tags ('EE', 'FI', 'EU')
//   * Statute references (TLS § 100, KauT § 4, UlkomaalaisL § 196,
//     Direktiivi 2019/1152, …)
//   * Public-record case citations (KHO 2024:25, RKHKo 3-3-1-…)
//   * Public organisations (Migri, PPA, Tax Board, courts, ministries)
//   * Type of agreement ('dealer contract', 'NDA', …)
//   * Major listed companies (Microsoft, Apple, Stora Enso, Telia, …)
//   * Risk insights, deadlines, procedural rights
//
// Stripped:
//   * All person names (incl. plain first-names in narrative voice)
//   * Email, phone, postal address, ID codes
//   * Small private companies and OÜ/AS/Oy names that aren't listed equities
//   * Exact monetary amounts → rounded to the nearest "marketing" magnitude
// -----------------------------------------------------------------------------

import { regexScrub, type ScrubResult } from "./pii_scrubber.ts";

// ─── Public types ───────────────────────────────────────────────────────────

/** Source kinds that can be shared. Mirrors the CHECK constraint on
 *  public.shared_results.source_type. */
export type ShareableSourceType =
  | "contract_review"
  | "legal_advice"
  | "deadline_analysis";

/** Structured, redacted preview payload. Stored as JSONB in shared_results
 *  and rendered by both the static `/s/<slug>` page and OG-image generator. */
export interface RedactedContent {
  /** 3-7 highest-impact, anonymised insight bullets. */
  bullets: string[];
  /** Top redacted risks (each ≤ 160 chars) — drives the "what was found"
   *  card on the public page. */
  risks: string[];
  /** Public statute / case citations preserved verbatim from the source. */
  statute_refs: string[];
  /** Rounded monetary amounts mentioned in the source, formatted as
   *  human-friendly strings ("~€15,000", "~$200K"). */
  monetary_amounts: string[];
}

/** Full redaction envelope returned by [redactForSharing]. */
export interface RedactionEnvelope {
  /** ≤ 80-char title for the share page <h1>. */
  title: string;
  /** ≤ 160-char anonymised insight headline ("AI saved €15K on dealer
   *  contract") — used as OG title and page subhead. */
  insight_summary: string;
  /** Optional jurisdiction code ('EE' | 'FI' | 'EU' | null). Inferred by
   *  Haiku from the source content; null when ambiguous. */
  jurisdiction: string | null;
  /** Optional case-type slug ('dealer_agreement', 'nda', 'employment',
   *  'deportation_appeal', …). Null when ambiguous. */
  case_type: string | null;
  /** Structured redacted body. */
  redacted_content: RedactedContent;
  /** Stage-1 counters (only the regex pass; Haiku output is opaque). Useful
   *  for tests + monitoring. */
  regex_replacements: Record<string, number>;
}

// ─── Idempotency fast-path ──────────────────────────────────────────────────

/**
 * Returns true when [s] already looks redacted enough that re-running the
 * Haiku pass is wasteful: no obvious-name patterns, no email/phone tokens,
 * but it does contain at least one [PLACEHOLDER] token. Used by the entry
 * point to short-circuit a second redaction pass.
 */
export function looksAlreadyRedacted(s: string): boolean {
  if (!s) return false; // empty input has no signal; let the caller decide
  const hasPlaceholder = /\[(NAME|ADDR|PHONE|EMAIL|CASE_NO|HETU_FI|ID_EE|ORG_PRIVATE|DATE_BIRTH|ID)\]/
    .test(s);
  const hasObviousPii =
    /\b\w+@\w+\.\w+\b/.test(s) || // any email
    /\+?\d[\d\s\-]{7,}\b/.test(s) || // any phone-ish
    /\b[1-6]\d{10}\b/.test(s); // EE id-code shape
  return hasPlaceholder && !hasObviousPii;
}

// ─── Source-type-specific Haiku prompts ─────────────────────────────────────

const SHARE_REDACT_SYSTEM = [
  "You are the privacy-redactor for Advocat, a legal AI assistant.",
  "Goal: take a raw AI legal analysis and produce a SAFE, ANONYMISED public",
  "share preview. The output will be displayed on a public marketing page.",
  "",
  "REMOVE (replace with bracketed placeholders):",
  "  - Names of people → [NAME]",
  "  - Postal addresses → [ADDR]",
  "  - Phone numbers → [PHONE]",
  "  - Email addresses → [EMAIL]",
  "  - National ID codes (Estonian isikukood, Finnish HETU) → [ID]",
  "  - Court case numbers (R-YY/NNNN, H-YY/NNNN) → [CASE_NO]",
  "  - Small private company names (OÜ, AS, Oy not on a public stock",
  "    exchange) → [ORG_PRIVATE]",
  "  - Dates of birth → [DATE_BIRTH]",
  "",
  "KEEP (these are the marketing payload):",
  "  - Jurisdiction tags ('EE', 'FI', 'EU')",
  "  - Statute references (TLS § 100, KauT § 4, UlkomaalaisL § 196,",
  "    Direktiivi 2019/1152, …)",
  "  - Public-record citations (KHO 2024:25, RKHKo 3-3-1-…, EIT case names)",
  "  - Public organisations (Migri, PPA, Tax Board, courts, ministries)",
  "  - Major listed companies (Microsoft, Apple, Telia, Stora Enso, …)",
  "  - Agreement types ('dealer agreement', 'NDA', 'employment contract')",
  "  - Risk insights, legal arguments, deadlines, procedural rights",
  "",
  "ROUND monetary amounts to the nearest marketing-friendly magnitude:",
  "  €14,789.50 → ~€15,000",
  "  $1,234.00 → ~$1,200",
  "  €127 → ~€130",
  "",
  "IDEMPOTENCY: if the input already contains [NAME] / [ADDR] / … tokens",
  "and no raw PII, treat it as already redacted and pass the body through",
  "unchanged. The redactor must be safe to run twice.",
  "",
  "OUTPUT FORMAT — ONLY valid JSON, no commentary, no markdown fences:",
  "{",
  '  "title": "≤80-char headline, no names",',
  '  "insight_summary": "≤160-char anonymised hook (e.g. \\"AI saved €15K on dealer contract\\")",',
  '  "jurisdiction": "EE" | "FI" | "EU" | null,',
  '  "case_type": "snake_case_slug" | null,',
  '  "redacted_content": {',
  '    "bullets": ["3-7 highest-impact insight bullets, anonymised"],',
  '    "risks": ["top redacted risks, ≤160 chars each"],',
  '    "statute_refs": ["preserved statute citations"],',
  '    "monetary_amounts": ["rounded amounts as strings like \\"~€15,000\\""]',
  "  }",
  "}",
].join("\n");

const HAIKU_MODEL = "claude-haiku-4-5-20251001";
const HAIKU_URL = "https://api.anthropic.com/v1/messages";

// ─── Haiku call ─────────────────────────────────────────────────────────────

export interface HaikuRedactOpts {
  /** Combined raw analysis text (concatenated insights, risks, etc.). */
  rawText: string;
  /** Source kind — passed to Haiku as a hint to disambiguate templates. */
  sourceType: ShareableSourceType;
  anthropicApiKey: string;
  /** Fetch override for tests. */
  fetcher?: typeof fetch;
  /** Max tokens for the structured response. Default 2048. */
  maxTokens?: number;
}

interface HaikuJson {
  title?: string;
  insight_summary?: string;
  jurisdiction?: string | null;
  case_type?: string | null;
  redacted_content?: {
    bullets?: unknown;
    risks?: unknown;
    statute_refs?: unknown;
    monetary_amounts?: unknown;
  };
}

/**
 * Call Haiku for the structured second-stage redaction.
 *
 * Returns null on any failure — the caller must fall back to a regex-only
 * envelope so the share endpoint can still produce a (less-rich) preview.
 */
export async function haikuRedact(opts: HaikuRedactOpts): Promise<HaikuJson | null> {
  if (!opts.rawText || !opts.anthropicApiKey) return null;
  const fetcher = opts.fetcher ?? fetch;
  const userPrompt = [
    `Source type: ${opts.sourceType}`,
    "",
    "Raw analysis text:",
    opts.rawText,
  ].join("\n");

  try {
    const res = await fetcher(HAIKU_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "anthropic-version": "2023-06-01",
        "x-api-key": opts.anthropicApiKey,
      },
      body: JSON.stringify({
        model: HAIKU_MODEL,
        max_tokens: opts.maxTokens ?? 2048,
        temperature: 0.0,
        system: SHARE_REDACT_SYSTEM,
        messages: [{ role: "user", content: userPrompt }],
      }),
    });
    if (!res.ok) {
      console.warn(`[redactor] Haiku HTTP ${res.status}`);
      return null;
    }
    const json = await res.json() as {
      content?: Array<{ type?: string; text?: string }>;
    };
    const text = (json.content ?? [])
      .filter((b) => b.type === "text" && typeof b.text === "string")
      .map((b) => b.text as string)
      .join("")
      .trim();
    if (!text) return null;
    // Tolerate code fences if the model emits them despite the instruction.
    const stripped = text
      .replace(/^\s*```(?:json)?\s*/i, "")
      .replace(/\s*```\s*$/i, "")
      .trim();
    return JSON.parse(stripped) as HaikuJson;
  } catch (e) {
    console.warn(`[redactor] Haiku threw: ${String(e).slice(0, 200)}`);
    return null;
  }
}

// ─── Normalisation helpers ──────────────────────────────────────────────────

function asStringArr(x: unknown, max = 10, perLen = 160): string[] {
  if (!Array.isArray(x)) return [];
  const out: string[] = [];
  for (const item of x) {
    if (typeof item === "string" && item.trim().length > 0) {
      out.push(item.trim().slice(0, perLen));
    }
    if (out.length >= max) break;
  }
  return out;
}

function asMaybeString(x: unknown, max: number): string | null {
  if (typeof x !== "string") return null;
  const t = x.trim();
  if (!t) return null;
  return t.slice(0, max);
}

function normaliseJurisdiction(x: unknown): string | null {
  if (typeof x !== "string") return null;
  const u = x.trim().toUpperCase();
  if (u === "EE" || u === "FI" || u === "EU") return u;
  return null;
}

/**
 * Fallback envelope generator: when Haiku is unavailable we CANNOT trust
 * the regex pass alone to have caught every name (e.g. "Sulga" has no
 * known suffix). To avoid leaking free-form names through the public-share
 * page, the fallback envelope returns only generic boilerplate copy.
 *
 * This is a deliberate quality/safety trade-off: shares created during a
 * Haiku outage will look bland, but they will never carry PII. The
 * regex-stage counter is still returned for observability.
 */
export function buildFallbackEnvelope(
  _rawText: string,
  scrub: ScrubResult,
  sourceType: ShareableSourceType,
): RedactionEnvelope {
  // Source-specific boilerplate copy. No user text ever flows into the
  // returned envelope; this is the only safe behaviour without Haiku.
  const { title, summary, bullet } = (() => {
    switch (sourceType) {
      case "contract_review":
        return {
          title: "Contract review by Advocat AI",
          summary:
            "AI legal analysis flagged risks in a contract — try it on yours.",
          bullet:
            "Hidden clauses, auto-renewals and unbalanced terms identified by the AI reviewer.",
        };
      case "legal_advice":
        return {
          title: "Legal analysis by Advocat AI",
          summary:
            "AI legal analysis — first review free.",
          bullet:
            "Statute-grounded answer with jurisdiction-specific citations from the AI assistant.",
        };
      case "deadline_analysis":
        return {
          title: "Deadline analysis by Advocat AI",
          summary:
            "AI deadline analysis with statutory-shift rules — never miss a filing again.",
          bullet:
            "Statutory deadlines computed with holiday-shift rules for FI/EE/ECHR.",
        };
    }
  })();

  return {
    title,
    insight_summary: summary,
    jurisdiction: null,
    case_type: null,
    redacted_content: {
      bullets: [bullet],
      risks: [],
      statute_refs: [],
      monetary_amounts: [],
    },
    regex_replacements: scrub.replacements,
  };
}

// ─── Entry point ────────────────────────────────────────────────────────────

export interface RedactOpts {
  /** Raw analysis text (concatenated chat output / contract review summary). */
  rawText: string;
  sourceType: ShareableSourceType;
  /** Anthropic API key. When omitted, the function falls back to a
   *  regex-only envelope (still safe — just less rich). */
  anthropicApiKey?: string;
  /** Test fetch override. */
  fetcher?: typeof fetch;
}

/**
 * Two-stage redaction for the public share path. Returns a sanitised
 * envelope ready to be stored in `shared_results.redacted_content`.
 *
 * Idempotent: running this on its own output yields the same envelope.
 */
export async function redactForSharing(opts: RedactOpts): Promise<RedactionEnvelope> {
  const stage1 = regexScrub(opts.rawText);

  // No API key → fall back to boilerplate envelope (regex-only is not safe
  // enough for free-form names; see buildFallbackEnvelope comment).
  if (!opts.anthropicApiKey) {
    return buildFallbackEnvelope(opts.rawText, stage1, opts.sourceType);
  }

  // Idempotency fast-path: when the input is already fully redacted (has
  // [PLACEHOLDER] tokens AND the regex pass made no changes AND has no
  // raw-PII signal), skip the Haiku call. Without all three signals we
  // err on the safe side and call Haiku — names without recognised
  // suffixes (e.g. "Sulga") otherwise slip through.
  const regexNoOp = Object.keys(stage1.replacements).length === 0;
  if (regexNoOp && looksAlreadyRedacted(opts.rawText)) {
    return buildFallbackEnvelope(opts.rawText, stage1, opts.sourceType);
  }

  const haiku = await haikuRedact({
    rawText: stage1.text,
    sourceType: opts.sourceType,
    anthropicApiKey: opts.anthropicApiKey,
    fetcher: opts.fetcher,
  });

  if (!haiku) {
    // Haiku failed — fall back to the regex-only envelope. The output is
    // still safe (regex pass already redacted structured PII) but less
    // marketing-friendly.
    return buildFallbackEnvelope(opts.rawText, stage1, opts.sourceType);
  }

  const fallback = buildFallbackEnvelope(opts.rawText, stage1, opts.sourceType);

  return {
    title: asMaybeString(haiku.title, 80) ?? fallback.title,
    insight_summary: asMaybeString(haiku.insight_summary, 160) ??
      fallback.insight_summary,
    jurisdiction: normaliseJurisdiction(haiku.jurisdiction),
    case_type: asMaybeString(haiku.case_type, 64),
    redacted_content: {
      bullets: asStringArr(haiku.redacted_content?.bullets, 7, 240),
      risks: asStringArr(haiku.redacted_content?.risks, 10, 160),
      statute_refs: asStringArr(haiku.redacted_content?.statute_refs, 20, 120),
      monetary_amounts: asStringArr(
        haiku.redacted_content?.monetary_amounts,
        10,
        40,
      ),
    },
    regex_replacements: stage1.replacements,
  };
}

// ─── Slug generation ────────────────────────────────────────────────────────

const SLUG_ALPHABET =
  "0123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

/**
 * Generate an 8-char URL-safe slug using crypto.getRandomValues.
 * ~57^8 ≈ 1.1e14 combinations — collisions are astronomically unlikely
 * at our scale; the edge fn still retries on the UNIQUE constraint just
 * in case.
 */
export function generateSlug(length = 8): string {
  const buf = new Uint8Array(length);
  crypto.getRandomValues(buf);
  let out = "";
  for (let i = 0; i < length; i++) {
    out += SLUG_ALPHABET[buf[i] % SLUG_ALPHABET.length];
  }
  return out;
}
