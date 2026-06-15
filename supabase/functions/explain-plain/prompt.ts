// explain-plain/prompt.ts — pure prompt construction + response parsing.
// -----------------------------------------------------------------------------
// All the business logic that does NOT touch the network or the DB lives here
// so it can be unit-tested without an isolate. The HTTP shim (index.ts) wires
// auth / quota / Anthropic / DB around these helpers.
//
// The explainer is a SINGLE-SHOT, no-history call: it takes one legal text and
// produces a plain-language explanation. It is NOT a chat. The output is a
// strict JSON object the Flutter screen renders into sections.
// -----------------------------------------------------------------------------

/** The two explanation modes the user picks on the screen. */
export type ExplainLevel = "friend" | "with_terms";

/** Supported output locales — mirrors the shared language detector. */
export type ExplainLang =
  | "ru"
  | "fi"
  | "et"
  | "en"
  | "ar"
  | "de"
  | "es"
  | "fa"
  | "fr"
  | "it"
  | "lt"
  | "lv"
  | "pl"
  | "ro"
  | "sv"
  | "tr"
  | "uk";

/** Maximum source length we send to the model (chars). Longer is truncated. */
export const MAX_SOURCE_CHARS = 24_000;

/** Length of the excerpt persisted to history (chars). */
export const EXCERPT_CHARS = 600;

/** Free-tier monthly cap. Pro is unlimited. */
export const FREE_MONTHLY_QUOTA = 3;

/** One glossary entry: a contentious legal term explained in plain words. */
export interface GlossaryEntry {
  /** The legal term as it appears in the source. */
  term: string;
  /** A one-sentence plain-language meaning. */
  plain: string;
  /**
   * Optional corpus reference slug (e.g. "fi-ulkomaalaislaki:150"). The client
   * deep-links this into the legal corpus. Absent when the model has no anchor.
   */
  ref?: string;
}

/** One explained paragraph/section of the source. */
export interface ExplainedParagraph {
  /** A short heading naming what this part of the document is about. */
  heading: string;
  /** The plain-language re-statement of that part. */
  plain: string;
}

/** The structured explanation returned to the client and persisted. */
export interface ExplainOutput {
  /** 1–2 line "bottom line" summary. */
  tldr: string[];
  /** Section-by-section plain re-statement. */
  paragraphs: ExplainedParagraph[];
  /** Contentious terms with plain meanings + optional corpus refs. */
  glossary: GlossaryEntry[];
  /** Concrete, non-advisory next actions the user can take themselves. */
  next_steps: string[];
}

export interface ParsedRequest {
  source_text: string;
  level: ExplainLevel;
  /** Caller-supplied language override; when absent the server auto-detects. */
  language?: ExplainLang;
  /** Optional case link (informational). */
  case_id?: string;
  /** Optional source-document link (informational). */
  source_document_id?: string;
}

export type ValidationResult =
  | { ok: true; value: ParsedRequest }
  | { ok: false; error: string };

const VALID_LEVELS = new Set<ExplainLevel>(["friend", "with_terms"]);
const VALID_LANGS = new Set<ExplainLang>([
  "ru",
  "fi",
  "et",
  "en",
  "ar",
  "de",
  "es",
  "fa",
  "fr",
  "it",
  "lt",
  "lv",
  "pl",
  "ro",
  "sv",
  "tr",
  "uk",
]);

/** Minimum meaningful source length — below this there is nothing to explain. */
export const MIN_SOURCE_CHARS = 20;

/**
 * Validates the inbound JSON body. Pure — no I/O. Trims the source and rejects
 * obviously empty or oversized-beyond-reason payloads early (a hard ceiling of
 * 200k chars guards against someone pasting a whole book to burn tokens; the
 * model input itself is further capped at MAX_SOURCE_CHARS by buildUserPrompt).
 */
export function validateRequest(raw: unknown): ValidationResult {
  if (typeof raw !== "object" || raw === null) {
    return { ok: false, error: "Body must be a JSON object" };
  }
  const r = raw as Record<string, unknown>;

  const sourceRaw = r.source_text;
  if (typeof sourceRaw !== "string") {
    return { ok: false, error: "source_text is required" };
  }
  const source_text = sourceRaw.trim();
  if (source_text.length < MIN_SOURCE_CHARS) {
    return {
      ok: false,
      error: `source_text too short (min ${MIN_SOURCE_CHARS} chars)`,
    };
  }
  if (source_text.length > 200_000) {
    return { ok: false, error: "source_text too long" };
  }

  let level: ExplainLevel = "friend";
  if (r.level !== undefined) {
    if (
      typeof r.level !== "string" ||
      !VALID_LEVELS.has(r.level as ExplainLevel)
    ) {
      return { ok: false, error: "level must be 'friend' or 'with_terms'" };
    }
    level = r.level as ExplainLevel;
  }

  let language: ExplainLang | undefined;
  if (r.language !== undefined && r.language !== null) {
    if (
      typeof r.language !== "string" ||
      !VALID_LANGS.has(r.language as ExplainLang)
    ) {
      return { ok: false, error: "unsupported language" };
    }
    language = r.language as ExplainLang;
  }

  const value: ParsedRequest = { source_text, level };
  if (language) value.language = language;
  if (typeof r.case_id === "string" && r.case_id.length > 0) {
    value.case_id = r.case_id;
  }
  if (
    typeof r.source_document_id === "string" &&
    r.source_document_id.length > 0
  ) {
    value.source_document_id = r.source_document_id;
  }
  return { ok: true, value };
}

/** Human-readable endonym for the target language, for the prompt directive. */
const LANG_NAME: Record<ExplainLang, string> = {
  ru: "Russian",
  fi: "Finnish",
  et: "Estonian",
  en: "English",
  ar: "Arabic",
  de: "German",
  es: "Spanish",
  fa: "Persian (Farsi)",
  fr: "French",
  it: "Italian",
  lt: "Lithuanian",
  lv: "Latvian",
  pl: "Polish",
  ro: "Romanian",
  sv: "Swedish",
  tr: "Turkish",
  uk: "Ukrainian",
};

/**
 * Builds the system prompt. Pure. The halt-rail / disclaimer is appended by the
 * caller (index.ts) when a serious case is detected; this base prompt already
 * forbids individual legal advice to satisfy the UPL mitigation.
 */
export function buildSystemPrompt(
  level: ExplainLevel,
  lang: ExplainLang
): string {
  const langName = LANG_NAME[lang] ?? "English";
  const readability =
    level === "friend"
      ? "Write at an A2–B1 readability level: short sentences, everyday words, " +
        "NO legal jargon at all. Explain as if to a friend who has no legal " +
        "background. If you must mention a legal term, immediately restate it in " +
        "plain words."
      : "Write in plain language but KEEP the key legal terms the reader will " +
        "encounter again (so they can recognise them in their documents). Each " +
        "kept term MUST also appear in the glossary with a one-sentence plain " +
        "meaning.";

  return [
    "You are a plain-language explainer for legal documents. The user has " +
      "received an official document (a Migri/immigration decision, a court " +
      "ruling, a police notice, a contract, etc.) written in dense bureaucratic " +
      "or legal language, and does not understand it.",
    "",
    "Your ONLY job is to RE-STATE what the document already says in clear, " +
      "simple language, and to point out what the document is asking the reader " +
      "to do. You are NOT giving legal advice, NOT predicting outcomes, and NOT " +
      "telling the reader whether they will win or lose. You explain the text " +
      "in front of you — nothing more.",
    "",
    "Hard rules:",
    "  - Do NOT invent facts, deadlines, or sums that are not in the source. " +
      "If the document states a deadline or amount, repeat it exactly.",
    "  - Do NOT recommend a specific legal strategy or tell the reader what " +
      "they 'should' do legally. 'Next steps' may only list neutral, factual " +
      "actions the document itself implies (e.g. 'the decision says you may " +
      "appeal within 30 days to the named court').",
    "  - If something in the document is ambiguous, say so plainly rather " +
      "than guessing.",
    "",
    readability,
    "",
    `Write ALL output text in ${langName}. Keep proper names, statute numbers, ` +
      "case numbers and authority names verbatim.",
    "",
    "Return STRICTLY a single JSON object, no prose around it, no code fences, " +
      "with exactly this shape:",
    "{",
    '  "tldr": ["one or two short bottom-line sentences"],',
    '  "paragraphs": [{"heading": "short label", "plain": "plain re-statement"}],',
    '  "glossary": [{"term": "legal term", "plain": "one-sentence meaning", "ref": "optional-corpus-slug"}],',
    '  "next_steps": ["neutral factual action the document implies"]',
    "}",
    "Omit the 'ref' field when you have no specific statute anchor. Keep " +
      "glossary to the genuinely contentious terms (max ~8). Keep tldr to at " +
      "most 2 entries.",
  ].join("\n");
}

/**
 * Builds the user-turn content: the (possibly truncated) source document.
 * Pure. Truncation is applied at MAX_SOURCE_CHARS with a visible marker so the
 * model knows the tail was cut.
 */
export function buildUserPrompt(sourceText: string): string {
  let body = sourceText;
  if (body.length > MAX_SOURCE_CHARS) {
    body =
      body.slice(0, MAX_SOURCE_CHARS) +
      "\n\n[…document truncated for length — explain what is shown above…]";
  }
  return [
    "Explain the following document in plain language, following the JSON " +
      "contract from the system prompt:",
    "",
    "--- BEGIN DOCUMENT ---",
    body,
    "--- END DOCUMENT ---",
  ].join("\n");
}

/** Builds the short excerpt persisted to history. Pure. */
export function buildExcerpt(sourceText: string): string {
  const trimmed = sourceText.trim().replace(/\s+/g, " ");
  return trimmed.length > EXCERPT_CHARS
    ? trimmed.slice(0, EXCERPT_CHARS)
    : trimmed;
}

/**
 * Parses the model's text response into an ExplainOutput. Tolerant of stray
 * code fences. Throws on non-JSON or a structurally-wrong payload. Pure.
 *
 * Defensive: coerces each section to the expected shape and drops malformed
 * entries rather than trusting the model blindly — a single bad glossary row
 * must not break the whole render.
 */
export function parseExplainResponse(text: string): ExplainOutput {
  const stripped = text
    .replace(/^\s*```(?:json)?\s*/i, "")
    .replace(/\s*```\s*$/i, "")
    .trim();

  let json: unknown;
  try {
    json = JSON.parse(stripped);
  } catch (e) {
    throw new Error(
      `explainer returned non-JSON: ${String(e).slice(
        0,
        80
      )} :: head=${stripped.slice(0, 120)}`
    );
  }
  if (typeof json !== "object" || json === null || Array.isArray(json)) {
    throw new Error("explainer response is not an object");
  }
  const o = json as Record<string, unknown>;

  const toStringArray = (v: unknown): string[] =>
    Array.isArray(v)
      ? v
          .filter((x): x is string => typeof x === "string" && x.trim() !== "")
          .map((x) => x.trim())
      : [];

  const paragraphs: ExplainedParagraph[] = Array.isArray(o.paragraphs)
    ? (o.paragraphs as unknown[])
        .map((p): ExplainedParagraph | null => {
          if (typeof p !== "object" || p === null) return null;
          const pr = p as Record<string, unknown>;
          const plain = typeof pr.plain === "string" ? pr.plain.trim() : "";
          if (plain === "") return null;
          const heading =
            typeof pr.heading === "string" ? pr.heading.trim() : "";
          return { heading, plain };
        })
        .filter((x): x is ExplainedParagraph => x !== null)
    : [];

  const glossary: GlossaryEntry[] = Array.isArray(o.glossary)
    ? (o.glossary as unknown[])
        .map((g): GlossaryEntry | null => {
          if (typeof g !== "object" || g === null) return null;
          const gr = g as Record<string, unknown>;
          const term = typeof gr.term === "string" ? gr.term.trim() : "";
          const plain = typeof gr.plain === "string" ? gr.plain.trim() : "";
          if (term === "" || plain === "") return null;
          const entry: GlossaryEntry = { term, plain };
          if (typeof gr.ref === "string" && gr.ref.trim() !== "") {
            entry.ref = gr.ref.trim();
          }
          return entry;
        })
        .filter((x): x is GlossaryEntry => x !== null)
    : [];

  return {
    tldr: toStringArray(o.tldr),
    paragraphs,
    glossary,
    next_steps: toStringArray(o.next_steps),
  };
}
