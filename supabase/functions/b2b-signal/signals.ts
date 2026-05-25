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
 * Calibration rationale
 * ---------------------
 *  * domain (100)            — a law-firm/advokaadibüroo email at signup is
 *                              an instant "yes show the modal" signal.
 *  * doc_burst (30)          — 3+ document uploads in a day implies real case
 *                              workload, not a curious browser.
 *  * legal_planner (20)      — ≥5 legal-planner queries in a day implies a
 *                              pro user grinding through a matter.
 *  * docx (25)               — exporting a draft to DOCX is high-intent.
 *  * cjeu_echr_query (15)    — niche EU/ECHR queries skew heavily B2B.
 *  * pro_quota_pressure (20) — Pro user near the 100 msg/24h ceiling = power
 *                              user candidate for team plan.
 *  * attorney_role_in_doc (50) — uploaded document names the caller as an
 *                              attorney/advokaat/asianajaja. Strong B2B
 *                              signal but not 100 because (a) it may name a
 *                              counterparty's lawyer, (b) we want to wait
 *                              for at least one corroborating signal.
 *
 * Threshold = 100. Single domain hit OR (attorney_role + docx + doc_burst)
 * OR (5x legal_planner + 2x docx) all trip it.
 */
export const SIGNAL_TYPES = [
  "law_firm_email_domain",
  "doc_burst_3plus_day",
  "legal_planner_heavy",
  "docx_export",
  "cjeu_echr_query",
  "pro_quota_pressure",
  "attorney_role_in_doc",
] as const;

export type SignalType = (typeof SIGNAL_TYPES)[number];

const SIGNAL_TYPE_SET: ReadonlySet<string> = new Set(SIGNAL_TYPES);

export function isAllowedSignalType(s: string): s is SignalType {
  return SIGNAL_TYPE_SET.has(s);
}

export const DEFAULT_SCORES: Readonly<Record<SignalType, number>> = {
  law_firm_email_domain: 100,
  doc_burst_3plus_day: 30,
  legal_planner_heavy: 20,
  docx_export: 25,
  cjeu_echr_query: 15,
  pro_quota_pressure: 20,
  attorney_role_in_doc: 50,
};

/**
 * The threshold at which `profiles.b2b_modal_pending` is flipped to TRUE.
 * Mirrors the constant in the migration's `record_b2b_signal` function.
 * Kept here so wire-up code can short-circuit when score is already over
 * the line (avoid extra RPC calls).
 */
export const B2B_MODAL_THRESHOLD = 100;

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
