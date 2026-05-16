// verify-lawyer/validate.ts
// -----------------------------------------------------------------------------
// Pure validator for the verify-lawyer request body. Lives in its own file
// so the test suite can import it without dragging in serve() side effects.
// -----------------------------------------------------------------------------

const VALID_COUNTRIES = new Set(["FI", "EE"]);
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const NAME_MIN = 2;
const NAME_MAX = 200;
const BAR_ID_MIN = 1;
const BAR_ID_MAX = 64;
const URL_MAX = 500;

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
