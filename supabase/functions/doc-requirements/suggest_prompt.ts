// doc-requirements/suggest_prompt.ts — pure prompt + parser for the AI
// "extra documents" top-up. Kept dependency-free so the parser is unit
// testable without a network or Deno-runtime stub.
// -----------------------------------------------------------------------------
// The base document list comes from the seeded `doc_requirement_templates`.
// For a non-standard situation a user can ask the assistant to propose
// EXTRA documents specific to their description. Haiku returns a small JSON
// array; we parse it defensively and the client renders the result under
// the same "basic list — your situation may need more" disclaimer. These
// suggestions are NEVER persisted server-side and never advice on the
// merits — only "what else you might want to bring".
// -----------------------------------------------------------------------------

export const DOC_SUGGEST_HAIKU_MODEL = "claude-3-5-haiku-20241022";
export const DOC_SUGGEST_MAX_TOKENS = 600;
export const DOC_SUGGEST_TIMEOUT_MS = 12_000;

/** Hard cap on the user's free-text situation fed to Haiku. */
export const MAX_SITUATION_CHARS = 2_000;
/** Defensive caps mirroring sensible UI bounds. */
export const MAX_SUGGESTIONS = 8;
export const MAX_SUGGEST_TITLE_CHARS = 120;
export const MAX_SUGGEST_FIELD_CHARS = 240;

export const DOC_SUGGEST_SYSTEM_PROMPT = [
  "You help a person assemble the paperwork they need before contacting an",
  "authority, court, or lawyer. You are given a problem type, a base list of",
  "documents they were already shown, and a free-text description of their",
  "specific situation.",
  "",
  "Propose ONLY ADDITIONAL documents the base list does not already cover and",
  "that are clearly relevant to their description. Each item names a concrete",
  "document, where to get it, and why it matters. Do NOT repeat anything in the",
  "base list. Do NOT give legal advice, predict outcomes, or tell them what to",
  "argue — only WHAT to collect.",
  "",
  "Return STRICT JSON and nothing else: an array (possibly empty) of objects",
  '{ "title": string, "where_to_get": string, "why_needed": string }.',
  "Return at most 8 items. If nothing extra is clearly needed, return [].",
].join("\n");

/** One parsed extra-document suggestion. */
export interface DocSuggestion {
  title: string;
  where_to_get: string;
  why_needed: string;
}

/** Build the user-turn block fed to Haiku. */
export function buildDocSuggestUserBlock(args: {
  problemType: string;
  baseTitles: string[];
  situation: string;
}): string {
  const base = args.baseTitles
    .filter((t) => typeof t === "string" && t.length > 0)
    .slice(0, 40);
  const payload = {
    problem_type: args.problemType,
    base_list: base,
    situation: args.situation,
  };
  return [
    "Here is the context as JSON:",
    "```json",
    JSON.stringify(payload),
    "```",
    "List only ADDITIONAL documents, as the JSON array described.",
  ].join("\n");
}

/** Clamp + sanitise a single string field. */
function cleanField(v: unknown, max: number): string {
  if (typeof v !== "string") return "";
  return v.trim().slice(0, max);
}

/**
 * Parse Haiku's reply into a bounded, de-duplicated list of suggestions.
 * Tolerant of code fences and leading/trailing prose: extracts the first
 * top-level JSON array. Returns [] on anything malformed — never throws.
 * `baseTitles` (lower-cased) are filtered out so we never echo the base list.
 */
export function parseDocSuggestions(
  raw: string,
  baseTitles: string[] = []
): DocSuggestion[] {
  if (typeof raw !== "string" || raw.length === 0) return [];

  const arr = extractJsonArray(raw);
  if (!Array.isArray(arr)) return [];

  const seen = new Set<string>(
    baseTitles
      .filter((t) => typeof t === "string")
      .map((t) => t.trim().toLowerCase())
  );

  const out: DocSuggestion[] = [];
  for (const entry of arr) {
    if (out.length >= MAX_SUGGESTIONS) break;
    if (!entry || typeof entry !== "object") continue;
    const rec = entry as Record<string, unknown>;

    const title = cleanField(rec.title, MAX_SUGGEST_TITLE_CHARS);
    if (title.length === 0) continue;

    const key = title.toLowerCase();
    if (seen.has(key)) continue; // de-dup vs base list + earlier suggestions
    seen.add(key);

    out.push({
      title,
      where_to_get: cleanField(rec.where_to_get, MAX_SUGGEST_FIELD_CHARS),
      why_needed: cleanField(rec.why_needed, MAX_SUGGEST_FIELD_CHARS),
    });
  }
  return out;
}

/** Extract the first top-level JSON array from a possibly-fenced string. */
function extractJsonArray(raw: string): unknown {
  const start = raw.indexOf("[");
  const end = raw.lastIndexOf("]");
  if (start === -1 || end === -1 || end <= start) return null;
  const slice = raw.slice(start, end + 1);
  try {
    return JSON.parse(slice);
  } catch {
    return null;
  }
}
