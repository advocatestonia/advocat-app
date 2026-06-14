// template-fill/handler.ts — pure fill logic for the Legal Template Library.
// -----------------------------------------------------------------------------
// Feature #5. Takes a template body (with {{placeholder}} tokens) plus a bag of
// auto-resolved values (from profiles/cases) and user-supplied overrides, and
// returns the filled markdown. No IO here so it can be unit-tested without a DB.
//
// Substitution rules:
//   * Token syntax: {{snake_case}} (letters, digits, underscore only).
//   * `today` is always available (caller passes an ISO date string).
//   * User-supplied `fields` override auto values for the same token.
//   * Unresolved tokens are left as a visible placeholder "____" so the user
//     sees exactly what still needs filling — we never silently drop text.
// -----------------------------------------------------------------------------

/** Matches a single {{token}} placeholder, capturing the token name. */
const TOKEN_RE = /\{\{\s*([a-z0-9_]+)\s*\}\}/g;

/** Visible marker left behind for any token we couldn't resolve. */
export const UNRESOLVED_MARKER = "____";

export interface FillInput {
  /** Raw template body with {{placeholder}} tokens. */
  body: string;
  /**
   * Values resolved automatically from case/profile (e.g. full_name, email,
   * case_number, migri_ref, today). Null/empty values are treated as missing.
   */
  auto: Record<string, string | null | undefined>;
  /** User-supplied values for required fields. Override `auto`. */
  fields: Record<string, string | null | undefined>;
}

export interface FillResult {
  /** The filled markdown. */
  filled: string;
  /** Distinct token names found in the body, in first-seen order. */
  tokens: string[];
  /** Tokens that were resolved to a non-empty value. */
  resolved: string[];
  /** Tokens left unresolved (rendered as UNRESOLVED_MARKER). */
  unresolved: string[];
}

/** Extracts the distinct placeholder tokens from [body], first-seen order. */
export function extractTokens(body: string): string[] {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const m of body.matchAll(TOKEN_RE)) {
    const name = m[1];
    if (!seen.has(name)) {
      seen.add(name);
      out.push(name);
    }
  }
  return out;
}

/** Trims and normalises a candidate value; returns null when effectively empty. */
function clean(v: string | null | undefined): string | null {
  if (v == null) return null;
  const t = String(v).trim();
  return t.length === 0 ? null : t;
}

/**
 * Resolves the value for a token: user-supplied `fields` win over `auto`.
 * Returns null when neither source has a usable value.
 */
function resolve(
  token: string,
  auto: FillInput["auto"],
  fields: FillInput["fields"]
): string | null {
  // User override first.
  if (Object.prototype.hasOwnProperty.call(fields, token)) {
    const f = clean(fields[token]);
    if (f != null) return f;
  }
  if (Object.prototype.hasOwnProperty.call(auto, token)) {
    const a = clean(auto[token]);
    if (a != null) return a;
  }
  return null;
}

/**
 * Performs placeholder substitution. Pure — deterministic given its input.
 * Unresolved tokens are replaced with [UNRESOLVED_MARKER] so the output never
 * contains a raw `{{token}}` that could leak into an exported document.
 */
export function fillTemplate(input: FillInput): FillResult {
  const tokens = extractTokens(input.body);
  const resolved: string[] = [];
  const unresolved: string[] = [];

  const filled = input.body.replace(TOKEN_RE, (_full, rawName: string) => {
    const name = rawName;
    const value = resolve(name, input.auto, input.fields);
    if (value != null) {
      if (!resolved.includes(name)) resolved.push(name);
      return value;
    }
    if (!unresolved.includes(name)) unresolved.push(name);
    return UNRESOLVED_MARKER;
  });

  return { filled, tokens, resolved, unresolved };
}

// ─── DB shapes (kept minimal & injectable for tests) ─────────────────────────

export interface TemplateRow {
  id: string;
  slug: string;
  title: string;
  jurisdiction: string;
  locale: string;
  body_markdown: string;
  required_fields: string[];
}

export interface ProfileRow {
  full_name?: string | null;
  email?: string | null;
}

export interface CaseRow {
  title?: string | null;
  court_case_number?: string | null;
  migri_reference_number?: string | null;
  nationality?: string | null;
}

/**
 * Builds the auto-value bag from profile + (optional) case rows. Centralised so
 * the mapping from DB columns to template tokens lives in one place and is
 * unit-testable.
 */
export function buildAutoValues(opts: {
  profile?: ProfileRow | null;
  caseRow?: CaseRow | null;
  todayIso: string;
}): Record<string, string | null> {
  const p = opts.profile ?? {};
  const c = opts.caseRow ?? {};
  return {
    full_name: p.full_name ?? null,
    email: p.email ?? null,
    case_title: c.title ?? null,
    case_number: c.court_case_number ?? null,
    migri_ref: c.migri_reference_number ?? null,
    nationality: c.nationality ?? null,
    today: opts.todayIso,
  };
}
