// supabase/functions/b2b-signal/signals.ts
// -----------------------------------------------------------------------------
// Pure types + constants for the B2B signal allow-list. Kept in its own
// module so tests can import them without booting the HTTP entry point and
// so wire-up edge functions (pdf-parser, claude-proxy, …) can reuse the
// score table when they invoke the RPC directly.
// -----------------------------------------------------------------------------

/**
 * Canonical list of behavioural signals we score.
 *
 * v2 calibration (2026-05-25, post-consilium)
 * -------------------------------------------
 * The v1 table over-fired the modal: a single `law_firm_email_domain` hit
 * at signup (100 pts, threshold 100) would trigger the modal before the
 * user had done anything at all in-app. The 6-expert analyst consilium
 * flagged this as the headline UX bug and we re-tuned per their guidance:
 *
 *  * domain (60)             — strong but no longer instant-trigger by
 *                              itself. Needs ≥1 corroborating in-app signal
 *                              before the modal flips (enforced by the
 *                              compound trigger in the v2 migration).
 *  * doc_burst (25)          — bumped threshold to 5+ docs/day inside
 *                              pdf-parser. Realistic professional churn,
 *                              not a curious browser uploading three files.
 *  * legal_planner (25)      — slightly stronger; planner-heavy is one of
 *                              the cleanest pro-user tells.
 *  * docx (30)               — exporting to DOCX is high-intent (literally
 *                              the "I am drafting" act). Bumped.
 *  * cjeu_echr_query (20)    — niche EU/ECHR queries skew heavily B2B.
 *  * pro_quota_pressure (30) — Pro users banging on the 100 msg/24h
 *                              ceiling are the cleanest team-plan upsell.
 *  * attorney_role_in_doc (40) — uploaded document names the CALLER as an
 *                              attorney/advokaat/asianajaja (we now check
 *                              `is_user_party=true` rather than any party).
 *                              Reduced from 50 because the v2 detector is
 *                              already much tighter — false positives drop
 *                              naturally so we shave the score too.
 *  * session_long_business_hours (20) — NEW. ≥30 min session 9-18 weekday
 *                              local is a quiet professional-use tell.
 *  * multi_case_30d (25)     — NEW. ≥3 distinct cases active in last 30
 *                              days = real practitioner workload.
 *
 * v2 threshold = 110. Domain alone (60) no longer trips it; user has to
 * accrue at least one in-app signal first. Pure-signal combos that DO
 * trip the threshold:
 *   * domain (60) + docx (30) + planner_heavy (25)   = 115
 *   * domain (60) + attorney_role (40) + planner (25) = 125
 *   * attorney (40) + docx (30) + pro_pressure (30) + planner (25) = 125
 *   * 5x planner_heavy (125)                          = 125
 * The compound trigger ALSO requires domain+OTHER, so the 5x-planner
 * org-id-domain user still needs corroboration.
 */
export const SIGNAL_TYPES = [
  "law_firm_email_domain",
  "doc_burst_3plus_day",
  "legal_planner_heavy",
  "docx_export",
  "cjeu_echr_query",
  "pro_quota_pressure",
  "attorney_role_in_doc",
  // v2 additions (2026-05-25):
  "session_long_business_hours",
  "multi_case_30d",
] as const;

export type SignalType = (typeof SIGNAL_TYPES)[number];

const SIGNAL_TYPE_SET: ReadonlySet<string> = new Set(SIGNAL_TYPES);

export function isAllowedSignalType(s: string): s is SignalType {
  return SIGNAL_TYPE_SET.has(s);
}

export const DEFAULT_SCORES: Readonly<Record<SignalType, number>> = {
  law_firm_email_domain: 60,
  doc_burst_3plus_day: 25,
  legal_planner_heavy: 25,
  docx_export: 30,
  cjeu_echr_query: 20,
  pro_quota_pressure: 30,
  attorney_role_in_doc: 40,
  session_long_business_hours: 20,
  multi_case_30d: 25,
};

/**
 * The threshold at which `profiles.b2b_modal_pending` is flipped to TRUE.
 * Mirrors the constant in the migration's `record_b2b_signal` function.
 * Kept here so wire-up code can short-circuit when score is already over
 * the line (avoid extra RPC calls).
 *
 * v2 (2026-05-25): bumped 100 → 110 so domain alone (60) no longer trips
 * the modal. See the compound-trigger SQL in the v2 migration for the
 * additional "must have ≥1 other signal" gate.
 */
export const B2B_MODAL_THRESHOLD = 110;

/**
 * Signal half-life in days (v2). Each signal's effective contribution to
 * the rolling score decays as 0.5^(days_old / DECAY_HALF_LIFE_DAYS) inside
 * `compute_b2b_score`. 14 days picked because a signal from a month ago is
 * still ~1/4 weight — a real B2B prospect would have re-signalled by then.
 */
export const DECAY_HALF_LIFE_DAYS = 14;

/**
 * Set of signal types that, when freshly recorded for a user whose modal
 * has already been shown >30 days ago, can RE-ARM the modal exactly once
 * more (lifetime cap = 2 displays total). Mirrors the
 * `b2b_retrigger_high_intent` SQL set in the v2 migration.
 *
 * Only the highest-intent signals re-arm — we never re-show on a
 * `law_firm_email_domain` hit (the email hasn't changed) or on a
 * `cjeu_echr_query` (too weak alone).
 */
export const RETRIGGER_HIGH_INTENT_SIGNALS: ReadonlySet<SignalType> = new Set([
  "docx_export",
  "pro_quota_pressure",
  "multi_case_30d",
]);

// ---------------------------------------------------------------------------
// Law-firm email domain heuristic
// ---------------------------------------------------------------------------
// We deliberately keep this list small + obviously legal-themed. A long
// allow-list of every law firm on Earth is unmaintainable; instead we
// pattern-match on TLD-ish suffixes and obvious legal prefixes.

const EXACT_FIRM_DOMAINS: ReadonlySet<string> = new Set([
  // Estonia
  "advokaadibüroo.ee",
  "advokaadiburoo.ee", // ASCII fallback
  "advokatuur.ee",
  "law.ee",
  "advokaat.ee",
  // Finland
  "asianajotoimisto.fi",
  "law.fi",
  "asianajaja.fi",
  "lakitoimisto.fi",
  // Germany / DACH
  "kanzlei.de",
  "rechtsanwalt.de",
  "rechtsanwaelte.de",
  "anwalt.de",
  "kanzlei.at",
  "anwalt.at",
  // Sweden / Nordics
  "advokatbyra.se",
  "advokatfirma.no",
  "advokatfirma.dk",
  // UK / Ireland
  "solicitors.co.uk",
  "barristers.co.uk",
  // Generic / EU-wide
  "law-firm.eu",
  "lawfirm.eu",
]);

const FIRM_PREFIX_PATTERNS: ReadonlyArray<RegExp> = [
  /^advokaadi[- ].+\..+/,    // advokaadi-XX.ee, advokaadi XX.tld
  /^advokaat-.+\..+/,         // advokaat-XX.tld
  /^advokatuuri.+\..+/,
  /^asianajo-.+\..+/,         // asianajo-XX.fi
  /^asianajotoimisto-.+\..+/,
  /^kanzlei-.+\..+/,
  /^anwalt-.+\..+/,
  /^advokat-.+\..+/,
  /^lawfirm-.+\..+/,
];

/**
 * Returns true if [domain] looks like a law-firm domain.
 * Case-insensitive. Strips leading whitespace / `@`.
 *
 * Three layers:
 *   1. Exact-match against EXACT_FIRM_DOMAINS.
 *   2. TLD-based: anything ending in `.law` is presumed legal.
 *   3. Prefix-based: domains starting with `advokaat-`, `asianajo-`, etc.
 */
export function isLawFirmEmailDomain(domain: string | null | undefined): boolean {
  if (!domain) return false;
  const d = domain.trim().replace(/^@/, "").toLowerCase();
  if (d.length === 0) return false;
  if (EXACT_FIRM_DOMAINS.has(d)) return true;
  if (d.endsWith(".law")) return true;
  for (const re of FIRM_PREFIX_PATTERNS) {
    if (re.test(d)) return true;
  }
  return false;
}

/**
 * Extract the bare domain from an email address. Returns the empty string
 * for inputs that don't contain a `@`.
 */
export function extractEmailDomain(email: string | null | undefined): string {
  if (!email) return "";
  const at = email.lastIndexOf("@");
  if (at < 0 || at === email.length - 1) return "";
  return email.slice(at + 1).trim().toLowerCase();
}

/**
 * Convenience: is THIS email address from a law-firm domain?
 */
export function isLawFirmEmail(email: string | null | undefined): boolean {
  return isLawFirmEmailDomain(extractEmailDomain(email));
}
