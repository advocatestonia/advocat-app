// verify-lawyer/validate.ts
// -----------------------------------------------------------------------------
// Pure validator for the verify-lawyer request body. Lives in its own file
// so the test suite can import it without dragging in serve() side effects.
// -----------------------------------------------------------------------------

const VALID_COUNTRIES = new Set(["FI", "EE"]);
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const NAME_MIN = 2;
const NAME_MAX = 200;
const BAR_ID_MIN = 3;
const BAR_ID_MAX = 64;
const URL_MAX = 500;

// Real EE/FI bar registry numbers are numeric (advokatuur.ee uses short
// numeric member IDs; asianajajaliitto.fi a "Jäsennumero"). A bar_id that
// carries no digits — or only one — is almost certainly NOT a registry
// number. We require at least two digits. This is the front-line guard for
// the auto-approve escalation in index.ts: matchInRegistry does a tolerant
// substring search over the registry HTML, so a 1-char or all-letters
// "bar_id" like "a" or "de" trivially occurs on the page within the 800-char
// proximity window of some unrelated name token and forges a "match" →
// is_pro=true / premium_lawyer for free. Forcing a multi-digit numeric shape
// removes that class of input without touching any legitimate enrollment
// (every known registry ID is numeric, length >= 4).
const BAR_ID_MIN_DIGITS = 2;

export interface RawBody {
  country?: unknown;
  bar_id?: unknown;
  name?: unknown;
  email?: unknown;
  practice_url?: unknown;
}

export interface ValidatedBody {
  country: "FI" | "EE";
  barId: string;
  fullName: string;
  email: string;
  practiceUrl: string | null;
}

export type ValidationResult =
  | { kind: "ok"; body: ValidatedBody }
  | { kind: "error"; payload: Record<string, string> };

/**
 * Validate the inbound JSON body. All fields are trimmed; strings are
 * length-capped. Returns either {kind:'ok'} with a typed body or
 * {kind:'error'} with a `reason` key the UI can localise.
 */
export function validateBody(raw: RawBody): ValidationResult {
  const country = typeof raw.country === "string"
    ? raw.country.toUpperCase()
    : "";
  if (!VALID_COUNTRIES.has(country)) {
    return { kind: "error", payload: { reason: "bad_country" } };
  }

  const barId = typeof raw.bar_id === "string" ? raw.bar_id.trim() : "";
  if (barId.length < BAR_ID_MIN || barId.length > BAR_ID_MAX) {
    return { kind: "error", payload: { reason: "bad_bar_id" } };
  }
  // Must look like a registry number (multi-digit). Blocks all-letters /
  // single-digit inputs that would trivially substring-match the registry
  // HTML and forge an auto-approve. See BAR_ID_MIN_DIGITS rationale above.
  const digitCount = (barId.match(/\d/g) ?? []).length;
  if (digitCount < BAR_ID_MIN_DIGITS) {
    return { kind: "error", payload: { reason: "bad_bar_id" } };
  }

  const fullName = typeof raw.name === "string" ? raw.name.trim() : "";
  if (fullName.length < NAME_MIN || fullName.length > NAME_MAX) {
    return { kind: "error", payload: { reason: "bad_name" } };
  }
  // Reject names that look like nothing useful (a single short token).
  if (!fullName.includes(" ") && fullName.length < 4) {
    return { kind: "error", payload: { reason: "bad_name" } };
  }

  const emailRaw = typeof raw.email === "string"
    ? raw.email.trim().toLowerCase().slice(0, 254)
    : "";
  if (!EMAIL_RE.test(emailRaw)) {
    return { kind: "error", payload: { reason: "bad_email" } };
  }

  let practiceUrl: string | null = null;
  if (typeof raw.practice_url === "string") {
    const u = raw.practice_url.trim();
    if (u.length > 0) {
      if (u.length > URL_MAX || !/^https?:\/\//i.test(u)) {
        return { kind: "error", payload: { reason: "bad_url" } };
      }
      practiceUrl = u;
    }
  }

  return {
    kind: "ok",
    body: {
      country: country as "FI" | "EE",
      barId,
      fullName,
      email: emailRaw,
      practiceUrl,
    },
  };
}
