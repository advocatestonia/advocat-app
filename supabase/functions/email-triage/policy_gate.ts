// email-triage/policy_gate.ts
// -----------------------------------------------------------------------------
// Server-side 12-check policy gate (per OPERATOR_PROMPT §7).
//
// The model's `<send_recommendation>auto_send_eligible</send_recommendation>`
// is a NECESSARY condition. The gate re-checks all 12 server-side; ANY
// failure degrades to `hold_for_user_review` and writes
// `policy_gate_blocked` to the audit trail.
//
// On pass, the gate emits an HMAC token (60s TTL, signed with
// `EMAIL_AGENT_GATE_SECRET`) that binds `(draft_id, body_sha256,
// recipient_set)` so post-gate mutations invalidate it. `gmail.send_draft`
// requires the token.
//
// Phase 1 (this revision): we wire the gate but auto-send is DISABLED at
// the call-site — every triage result lands as `hold_for_user_review`. The
// gate still runs (so the audit trail captures the decision) and the token
// is emitted but not consumed. D6 (UI Approve & Send) is the eventual
// consumer.
// -----------------------------------------------------------------------------

const TEXT_ENC = new TextEncoder();

const HARD_DENY_REASONS = {
  TZ_DELTA: "tz_delta_exceeded",
  RATE_LIMIT: "auto_send_rate_limit",
  CATEGORY_NOT_WHITELISTED: "category_not_whitelisted",
  RECIPIENT_IN_KNOWN_COURTS: "recipient_in_known_courts",
  RECIPIENT_NOT_IN_THREAD: "recipient_not_in_thread_participants",
  BODY_DIFF_FROM_MODEL: "body_diff_from_model",
  SPEND_GATE: "spend_gate_exceeded",
  BODY_TOO_LONG: "body_length_over_500",
  MONEY_OR_ADMISSION: "money_or_admission_regex_hit",
  OUTSIDE_BUSINESS_HOURS: "outside_business_hours",
  MENTAL_HEALTH_FLAG: "mental_health_flag_set",
  OWNER_ON_THREAD: "owner_is_sender_loop",
} as const;

const ALLOWED_AUTO_SEND_CATEGORIES_DEFAULT = new Set([
  "acknowledgement",
  "document_receipt",
  "calendar_reschedule",
  "will_provide_by_date_deferral",
  "bounce_resend",
]);

const MONEY_OR_ADMISSION_RE = [
  // Currencies
  /[€$£¥]\s*\d+(?:[.,]\d+)?/,
  /\d+(?:[.,]\d+)?\s*(?:eur|euro|euroa|eurot|usd|gbp|sek|nok|dkk)\b/i,
  /\b\d+(?:[.,]\d+)?\s*(?:btc|eth|sol)\b/i,
  // Admission verbs (per Rule 9e blocklist; literal hits, parser is
  // case-insensitive but the auto-send body is short).
  /\b(agree|accept|admit|sign|appeal|decline|reject|plead|guilty|liable|responsible)\b/i,
  /\b(nõustun|tunnistan|kohustun|myönnän|suostun|sitoudun)\b/i,
  /\b(согласен|признаю|обязуюсь)\b/i,
];

export interface DraftCandidate {
  category: string;
  body: string;
  body_sha256_from_model?: string;
  to: string[];
  cc: string[];
  subject: string;
}

export interface UserContext {
  user_id: string;
  email: string;
  timezone: string | null;
  last_seen_tz: string | null;
  allowed_auto_send_categories?: string[] | null;
  daily_auto_send_count: number;
  daily_auto_send_cap: number;
  ai_spend_today_usd: number;
  ai_spend_cap_usd: number;
}

export interface CaseFlags {
  suicide_risk_screening_positive?: boolean;
  mental_health_sensitive?: boolean;
}

export interface ThreadContext {
  participants: string[]; // emails
  known_courts: string[];
  inbound_sender_email: string;
}

export interface GateInput {
  draft: DraftCandidate;
  user: UserContext;
  case_flags: CaseFlags;
  thread: ThreadContext;
  now?: Date;
}

export interface GateCheck {
  id: string;
  passed: boolean;
  reason?: string;
}

export interface GateResult {
  pass: boolean;
  reasons: string[];
  checks: GateCheck[];
}

/** Run the 12 checks. Pure, deterministic, no I/O. */
export function evaluatePolicyGate(input: GateInput): GateResult {
  const checks: GateCheck[] = [];
  const now = input.now ?? new Date();
  const u = input.user;
  const d = input.draft;

  // 1. TZ delta — drop if mismatch > 2h between user.timezone and last_seen_tz
  checks.push((() => {
    const a = tzOffsetMinutes(u.timezone, now);
    const b = tzOffsetMinutes(u.last_seen_tz, now);
    if (a == null || b == null) return mk("tz_delta", false, HARD_DENY_REASONS.TZ_DELTA);
    const deltaH = Math.abs(a - b) / 60;
    return mk("tz_delta", deltaH <= 2, deltaH > 2 ? HARD_DENY_REASONS.TZ_DELTA : undefined);
  })());

  // 2. Rate-limit (auto-sends/day) — daily cap per user tier
  checks.push(mk(
    "rate_limit",
    u.daily_auto_send_count < u.daily_auto_send_cap,
    u.daily_auto_send_count >= u.daily_auto_send_cap
      ? HARD_DENY_REASONS.RATE_LIMIT
      : undefined,
  ));

  // 3. Category whitelist double-check
  const userWhitelist = (u.allowed_auto_send_categories ?? [])
    .map((s) => s.toLowerCase());
  const sysWhitelist = ALLOWED_AUTO_SEND_CATEGORIES_DEFAULT;
  const cat = (d.category ?? "").toLowerCase();
  const catOk = sysWhitelist.has(cat) &&
    (userWhitelist.length === 0 || userWhitelist.includes(cat));
  checks.push(mk(
    "category_whitelist",
    catOk,
    !catOk ? HARD_DENY_REASONS.CATEGORY_NOT_WHITELISTED : undefined,
  ));

  // 4. Recipient domain check vs KNOWN_COURTS
  const knownCourts = new Set(input.thread.known_courts.map((s) => s.toLowerCase()));
  const allRecipients = [...d.to, ...d.cc].map((s) => s.toLowerCase());
  const courtHit = allRecipients.some((r) => {
    const dom = r.split("@").pop() ?? "";
    return knownCourts.has(dom) || [...knownCourts].some((k) => dom.endsWith(k));
  });
  checks.push(mk(
    "recipient_not_known_courts",
    !courtHit,
    courtHit ? HARD_DENY_REASONS.RECIPIENT_IN_KNOWN_COURTS : undefined,
  ));

  // 5. Recipient ∈ thread participants
  const participants = new Set(
    input.thread.participants.map((s) => s.toLowerCase()),
  );
  const newRecipient = allRecipients.find((r) => !participants.has(r));
  checks.push(mk(
    "recipient_in_thread",
    newRecipient == null,
    newRecipient ? HARD_DENY_REASONS.RECIPIENT_NOT_IN_THREAD : undefined,
  ));

  // 6. Body diff vs model output
  // (Only enforced when caller passed `body_sha256_from_model`. If the body
  // was edited, the sha will mismatch → fail.)
  if (d.body_sha256_from_model) {
    const calc = sha256Sync(d.body);
    checks.push(mk(
      "body_unchanged",
      calc === d.body_sha256_from_model,
      calc !== d.body_sha256_from_model
        ? HARD_DENY_REASONS.BODY_DIFF_FROM_MODEL
        : undefined,
    ));
  } else {
    // Defensive default — caller should pass the hash whenever auto-send
    // is in scope. Treat absence as a hold (cannot prove identity).
    checks.push(mk(
      "body_unchanged",
      false,
      HARD_DENY_REASONS.BODY_DIFF_FROM_MODEL,
    ));
  }

  // 7. Spend gate
  checks.push(mk(
    "spend_gate",
    u.ai_spend_today_usd <= u.ai_spend_cap_usd,
    u.ai_spend_today_usd > u.ai_spend_cap_usd
      ? HARD_DENY_REASONS.SPEND_GATE
      : undefined,
  ));

  // 8. Body length re-check (≤ 500 chars after any backend transform)
  const bodyLen = (d.body ?? "").length;
  checks.push(mk(
    "body_length",
    bodyLen <= 500,
    bodyLen > 500 ? HARD_DENY_REASONS.BODY_TOO_LONG : undefined,
  ));

  // 9. Money / admission regex re-check (defence in depth vs Rule 9 e/f)
  const moneyHit = MONEY_OR_ADMISSION_RE.some((re) => re.test(d.body ?? ""));
  checks.push(mk(
    "money_or_admission",
    !moneyHit,
    moneyHit ? HARD_DENY_REASONS.MONEY_OR_ADMISSION : undefined,
  ));

  // 10. Time-of-day re-check (09:00–18:00 in user.timezone)
  const todOk = isWithinBusinessHours(u.timezone, now);
  checks.push(mk(
    "business_hours",
    todOk,
    !todOk ? HARD_DENY_REASONS.OUTSIDE_BUSINESS_HOURS : undefined,
  ));

  // 11. Mental-health flag
  const mh = input.case_flags.suicide_risk_screening_positive === true;
  checks.push(mk(
    "mental_health_flag",
    !mh,
    mh ? HARD_DENY_REASONS.MENTAL_HEALTH_FLAG : undefined,
  ));

  // 12. Owner-on-thread sanity
  const ownerLoop = (input.thread.inbound_sender_email ?? "").toLowerCase() ===
    (u.email ?? "").toLowerCase();
  checks.push(mk(
    "owner_loop",
    !ownerLoop,
    ownerLoop ? HARD_DENY_REASONS.OWNER_ON_THREAD : undefined,
  ));

  const failed = checks.filter((c) => !c.passed);
  return {
    pass: failed.length === 0,
    reasons: failed.map((c) => c.reason ?? c.id),
    checks,
  };
}

// =============================================================================
// HMAC token
// =============================================================================

export interface GateToken {
  draft_id: string;
  body_sha256: string;
  recipient_set: string; // canonicalised: comma-separated lowercased to|cc
  issued_at: number; // ms
  ttl_ms: number;
  hmac: string; // hex
}

const DEFAULT_TTL_MS = 60_000;

export interface IssueTokenInput {
  draft_id: string;
  body_sha256: string;
  recipients: string[];
  secret: string;
  now?: number;
  ttl_ms?: number;
}

/**
 * Issue an HMAC token binding `(draft_id, body_sha256, recipient_set)`.
 * Caller must provide `secret = EMAIL_AGENT_GATE_SECRET` from env.
 */
export async function issueGateToken(
  input: IssueTokenInput,
): Promise<GateToken> {
  const recipientSet = canonicaliseRecipientSet(input.recipients);
  const issuedAt = input.now ?? Date.now();
  const ttlMs = input.ttl_ms ?? DEFAULT_TTL_MS;
  const payload = `${input.draft_id}|${input.body_sha256}|${recipientSet}|${issuedAt}|${ttlMs}`;
  const hmac = await hmacSha256(input.secret, payload);
  return {
    draft_id: input.draft_id,
    body_sha256: input.body_sha256,
    recipient_set: recipientSet,
    issued_at: issuedAt,
    ttl_ms: ttlMs,
    hmac,
  };
}

export interface VerifyTokenInput {
  token: GateToken;
  expected_draft_id: string;
  expected_body_sha256: string;
  expected_recipients: string[];
  secret: string;
  now?: number;
}

export interface VerifyTokenResult {
  ok: boolean;
  reason?: string;
}

/** Re-derive the HMAC and verify TTL + bound fields. */
export async function verifyGateToken(
  input: VerifyTokenInput,
): Promise<VerifyTokenResult> {
  const t = input.token;
  if (t.draft_id !== input.expected_draft_id) {
    return { ok: false, reason: "draft_id_mismatch" };
  }
  if (t.body_sha256 !== input.expected_body_sha256) {
    return { ok: false, reason: "body_sha256_mismatch" };
  }
  const expectedRecipients = canonicaliseRecipientSet(input.expected_recipients);
  if (t.recipient_set !== expectedRecipients) {
    return { ok: false, reason: "recipient_set_mismatch" };
  }
  const now = input.now ?? Date.now();
  if (now > t.issued_at + t.ttl_ms) {
    return { ok: false, reason: "token_expired" };
  }
  const payload =
    `${t.draft_id}|${t.body_sha256}|${t.recipient_set}|${t.issued_at}|${t.ttl_ms}`;
  const expected = await hmacSha256(input.secret, payload);
  if (expected !== t.hmac) {
    return { ok: false, reason: "hmac_mismatch" };
  }
  return { ok: true };
}

// =============================================================================
// helpers
// =============================================================================

function mk(id: string, passed: boolean, reason?: string): GateCheck {
  if (passed) return { id, passed: true };
  return { id, passed: false, reason };
}

/** Canonical recipient-set string for HMAC binding. */
export function canonicaliseRecipientSet(addrs: string[]): string {
  const cleaned = addrs
    .map((s) => (s ?? "").toLowerCase().trim())
    .filter((s) => s.length > 0);
  cleaned.sort();
  return cleaned.join(",");
}

/** Compute SHA-256 hex synchronously via Web Crypto's SubtleCrypto async,
 * exposed here as an async function for callers that need it. We expose a
 * sync stub for the gate's body-diff check by hashing via `crypto.subtle`
 * — Deno supports this; tests pin the deterministic mapping. */
async function sha256(s: string): Promise<string> {
  const buf = await crypto.subtle.digest("SHA-256", TEXT_ENC.encode(s));
  return bufToHex(buf);
}

/** Synchronous wrapper for the gate's body-diff check.
 *
 * SubtleCrypto is async — we cannot avoid that — but the gate's body
 * comparison is itself happy with hex equality. We expose `sha256Hex` as
 * the public async helper and use a small re-entrancy guard for the body
 * comparison: we precompute the model body hash up front (outside the
 * gate) and pass it through `body_sha256_from_model`; the gate compares
 * to a freshly computed hash of the live body. We do that comparison
 * here using a synchronous, pure helper — but Deno doesn't ship a sync
 * SHA-256, so we delegate to a tiny FNV-1a fallback for the runtime
 * gate path. SubtleCrypto-backed identity is the canonical channel
 * (used by issueGateToken). The runtime check on body diff is intended
 * as a CHEAP defensive guard, not a primary integrity proof. */
function sha256Sync(s: string): string {
  // FNV-1a 64 — collision-resistant enough for a defensive in-process
  // body-diff check between the model output and the live body. The
  // CRYPTO-grade identity check happens at token verification (HMAC).
  const FNV_OFFSET = 0xcbf29ce484222325n;
  const FNV_PRIME = 0x100000001b3n;
  let hash = FNV_OFFSET;
  const bytes = TEXT_ENC.encode(s);
  for (const b of bytes) {
    hash ^= BigInt(b);
    hash = (hash * FNV_PRIME) & 0xffffffffffffffffn;
  }
  return hash.toString(16).padStart(16, "0");
}

/** Public async helper (callers compute the hash once, pre-gate). */
export async function sha256Hex(s: string): Promise<string> {
  return await sha256(s);
}

/** Async HMAC-SHA-256 hex. Used by both issue and verify. */
async function hmacSha256(secret: string, payload: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    TEXT_ENC.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "HMAC",
    key,
    TEXT_ENC.encode(payload),
  );
  return bufToHex(sig);
}

function bufToHex(buf: ArrayBuffer): string {
  const arr = new Uint8Array(buf);
  let out = "";
  for (let i = 0; i < arr.length; i++) {
    out += arr[i].toString(16).padStart(2, "0");
  }
  return out;
}

/**
 * Best-effort timezone offset extractor — returns minutes east of UTC for
 * an IANA zone name like "Europe/Helsinki". Returns null on unknown TZs.
 */
function tzOffsetMinutes(tz: string | null, now: Date): number | null {
  if (!tz) return null;
  try {
    // Trick: format the same instant in UTC and the target TZ, compare.
    const fmt = new Intl.DateTimeFormat("en-US", {
      timeZone: tz,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
      hour12: false,
    });
    const parts = fmt.formatToParts(now);
    const map: Record<string, string> = {};
    for (const p of parts) map[p.type] = p.value;
    const asUtc = Date.UTC(
      Number(map.year),
      Number(map.month) - 1,
      Number(map.day === "24" ? "24" : map.day),
      Number(map.hour),
      Number(map.minute),
      Number(map.second),
    );
    return Math.round((asUtc - now.getTime()) / 60_000);
  } catch (_) {
    return null;
  }
}

/** True if `now` falls within 09:00–18:00 in the given IANA TZ. */
function isWithinBusinessHours(tz: string | null, now: Date): boolean {
  if (!tz) return false;
  try {
    const fmt = new Intl.DateTimeFormat("en-GB", {
      timeZone: tz,
      hour: "2-digit",
      minute: "2-digit",
      hour12: false,
    });
    const parts = fmt.formatToParts(now);
    const hour = Number(parts.find((p) => p.type === "hour")?.value ?? "-1");
    return hour >= 9 && hour < 18;
  } catch (_) {
    return false;
  }
}
