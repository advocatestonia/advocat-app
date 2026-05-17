// lawyer-booking/validate.ts
// -----------------------------------------------------------------------------
// Pure validator for the lawyer-booking request body. Lives in its own file
// so the test suite can import it without dragging in serve() side effects.
//
// Two operation envelopes are accepted by the edge fn:
//
//   { op: "create", topic, language?, lawyer_id?, case_id?,
//                   scheduled_at?, time_preference?, user_brief? }
//
//   { op: "outcome", booking_id, outcome_summary }   ← partner lawyer only
//
//   { op: "rate",    booking_id, user_rating, user_feedback? }   ← user only
//
//   { op: "cancel",  booking_id }
//
// The validator returns either a typed body or a {reason} error key the UI
// can localise (mirrors verify-lawyer/validate.ts shape).
// -----------------------------------------------------------------------------

const TOPIC_MIN = 3;
const TOPIC_MAX = 100;
const BRIEF_MAX = 4000;
const OUTCOME_MAX = 4000;
const FEEDBACK_MAX = 2000;
const TIME_PREF_MAX = 200;

/**
 * UUID v4 regexp — same shape used elsewhere in the codebase.
 * Keeps us off `crypto.randomUUID` validation rabbit holes.
 */
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** Topics the booking form offers. Free-form text is accepted, but the
 *  validator normalises common ones so analytics roll-ups stay clean. */
const KNOWN_TOPICS = new Set([
  "immigration",
  "contract",
  "family",
  "employment",
  "tenancy",
  "criminal",
  "civil",
  "tax",
  "consumer",
  "other",
]);

/** Languages the partner pool covers. Validation only — server does NOT
 *  reject other ISO codes (lawyer pool may grow); we just clamp length. */
const LANG_RE = /^[a-z]{2}$/;

// ─── Op-discriminated body shapes ───────────────────────────────────────────

export interface RawBody {
  op?: unknown;
  topic?: unknown;
  language?: unknown;
  lawyer_id?: unknown;
  case_id?: unknown;
  scheduled_at?: unknown;
  time_preference?: unknown;
  user_brief?: unknown;
  booking_id?: unknown;
  outcome_summary?: unknown;
  user_rating?: unknown;
  user_feedback?: unknown;
}

export type ValidatedBody =
  | ValidatedCreate
  | ValidatedOutcome
  | ValidatedRate
  | ValidatedCancel;

export interface ValidatedCreate {
  op: "create";
  topic: string;
  language: string;
  lawyerId: string | null;
  caseId: string | null;
  scheduledAt: string | null;
  timePreference: string | null;
  userBrief: string | null;
}

export interface ValidatedOutcome {
  op: "outcome";
  bookingId: string;
  outcomeSummary: string;
}

export interface ValidatedRate {
  op: "rate";
  bookingId: string;
  userRating: number;
  userFeedback: string | null;
}

export interface ValidatedCancel {
  op: "cancel";
  bookingId: string;
}

export type ValidationResult =
  | { kind: "ok"; body: ValidatedBody }
  | { kind: "error"; payload: Record<string, string> };

// ─── Entry point ────────────────────────────────────────────────────────────

export function validateBody(raw: RawBody): ValidationResult {
  const op = typeof raw.op === "string" ? raw.op : "create";
  switch (op) {
    case "create":
      return validateCreate(raw);
    case "outcome":
      return validateOutcome(raw);
    case "rate":
      return validateRate(raw);
    case "cancel":
      return validateCancel(raw);
    default:
      return { kind: "error", payload: { reason: "bad_op" } };
  }
}

// ─── op:create ──────────────────────────────────────────────────────────────

function validateCreate(raw: RawBody): ValidationResult {
  const topicRaw = typeof raw.topic === "string" ? raw.topic.trim() : "";
  if (topicRaw.length < TOPIC_MIN || topicRaw.length > TOPIC_MAX) {
    return { kind: "error", payload: { reason: "bad_topic" } };
  }
  // Normalise to the canonical token when one of the known buckets matches
  // case-insensitively; otherwise keep the user's free-form string.
  const topic = KNOWN_TOPICS.has(topicRaw.toLowerCase())
    ? topicRaw.toLowerCase()
    : topicRaw;

  const langRaw = typeof raw.language === "string"
    ? raw.language.trim().toLowerCase()
    : "et";
  if (!LANG_RE.test(langRaw)) {
    return { kind: "error", payload: { reason: "bad_language" } };
  }

  let lawyerId: string | null = null;
  if (typeof raw.lawyer_id === "string" && raw.lawyer_id.length > 0) {
    if (!UUID_RE.test(raw.lawyer_id)) {
      return { kind: "error", payload: { reason: "bad_lawyer_id" } };
    }
    lawyerId = raw.lawyer_id.toLowerCase();
  }

  let caseId: string | null = null;
  if (typeof raw.case_id === "string" && raw.case_id.length > 0) {
    if (!UUID_RE.test(raw.case_id)) {
      return { kind: "error", payload: { reason: "bad_case_id" } };
    }
    caseId = raw.case_id.toLowerCase();
  }

  let scheduledAt: string | null = null;
  if (typeof raw.scheduled_at === "string" && raw.scheduled_at.length > 0) {
    const t = Date.parse(raw.scheduled_at);
    if (!Number.isFinite(t)) {
      return { kind: "error", payload: { reason: "bad_scheduled_at" } };
    }
    // Refuse slots in the past or more than 60 days out.
    const now = Date.now();
    if (t < now - 60_000) {
      return { kind: "error", payload: { reason: "scheduled_in_past" } };
    }
    if (t > now + 60 * 24 * 3600 * 1000) {
      return { kind: "error", payload: { reason: "scheduled_too_far" } };
    }
    scheduledAt = new Date(t).toISOString();
  }

  let timePreference: string | null = null;
  if (typeof raw.time_preference === "string") {
    const tp = raw.time_preference.trim().slice(0, TIME_PREF_MAX);
    timePreference = tp.length > 0 ? tp : null;
  }

  let userBrief: string | null = null;
  if (typeof raw.user_brief === "string") {
    const ub = raw.user_brief.trim();
    if (ub.length > BRIEF_MAX) {
      return { kind: "error", payload: { reason: "user_brief_too_long" } };
    }
    userBrief = ub.length > 0 ? ub : null;
  }

  return {
    kind: "ok",
    body: {
      op: "create",
      topic,
      language: langRaw,
      lawyerId,
      caseId,
      scheduledAt,
      timePreference,
      userBrief,
    },
  };
}

// ─── op:outcome (partner lawyer fills post-call form) ───────────────────────

function validateOutcome(raw: RawBody): ValidationResult {
  if (typeof raw.booking_id !== "string" || !UUID_RE.test(raw.booking_id)) {
    return { kind: "error", payload: { reason: "bad_booking_id" } };
  }
  const summary = typeof raw.outcome_summary === "string"
    ? raw.outcome_summary.trim()
    : "";
  if (summary.length < 10 || summary.length > OUTCOME_MAX) {
    return { kind: "error", payload: { reason: "bad_outcome_summary" } };
  }
  return {
    kind: "ok",
    body: {
      op: "outcome",
      bookingId: raw.booking_id.toLowerCase(),
      outcomeSummary: summary,
    },
  };
}

// ─── op:rate (user 1-5 + optional feedback) ─────────────────────────────────

function validateRate(raw: RawBody): ValidationResult {
  if (typeof raw.booking_id !== "string" || !UUID_RE.test(raw.booking_id)) {
    return { kind: "error", payload: { reason: "bad_booking_id" } };
  }
  const rating = typeof raw.user_rating === "number" ? raw.user_rating : NaN;
  if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
    return { kind: "error", payload: { reason: "bad_user_rating" } };
  }
  let feedback: string | null = null;
  if (typeof raw.user_feedback === "string") {
    const f = raw.user_feedback.trim();
    if (f.length > FEEDBACK_MAX) {
      return { kind: "error", payload: { reason: "user_feedback_too_long" } };
    }
    feedback = f.length > 0 ? f : null;
  }
  return {
    kind: "ok",
    body: {
      op: "rate",
      bookingId: raw.booking_id.toLowerCase(),
      userRating: rating,
      userFeedback: feedback,
    },
  };
}

// ─── op:cancel ──────────────────────────────────────────────────────────────

function validateCancel(raw: RawBody): ValidationResult {
  if (typeof raw.booking_id !== "string" || !UUID_RE.test(raw.booking_id)) {
    return { kind: "error", payload: { reason: "bad_booking_id" } };
  }
  return {
    kind: "ok",
    body: { op: "cancel", bookingId: raw.booking_id.toLowerCase() },
  };
}

// ─── Helpers exposed for tests ──────────────────────────────────────────────

export const __testing = { UUID_RE, KNOWN_TOPICS };
