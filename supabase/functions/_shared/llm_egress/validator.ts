// validator.ts — deterministic post-scrub leak detector for the egress path.
// ----------------------------------------------------------------------------
// After pseudonymization (and the optional Haiku name-pass), this re-scans the
// outbound payload for HIGH-CONFIDENCE structured PII that should NEVER reach
// an external LLM: ID codes, HETU, emails, IBANs, phone numbers. These are
// deterministic patterns with near-zero false positives — if one survives,
// the scrub failed and the caller must FAIL CLOSED (block the LLM call for
// Art. 9 special-category data) rather than leak.
//
// We deliberately do NOT re-scan for free-form names here: the surname regex
// has false positives, and a missed name is a defence-in-depth gap, not a
// hard structured-identifier leak. The gateway escalates name-coverage to the
// Haiku pass; this validator is the non-negotiable floor for the identifiers
// that uniquely pin a real person (isikukood, HETU, email, IBAN, phone).
// ----------------------------------------------------------------------------

export interface ValidationResult {
  clean: boolean;
  /** Which detectors fired, with match counts (NOT the real values). */
  leaks: Record<string, number>;
}

// High-confidence structured identifiers. Each MUST be gone after scrubbing.
const LEAK_DETECTORS: Array<{ name: string; re: RegExp }> = [
  { name: "email", re: /\b[\w.+-]+@[\w.-]+\.\w{2,}\b/g },
  { name: "ee_id", re: /\b[1-6]\d{2}[01]\d[0-3]\d{5}\b/g },
  { name: "fi_hetu", re: /\b\d{6}[+\-A]\d{3}[\dA-Y]\b/g },
  { name: "iban", re: /\b[A-Z]{2}\d{2}[A-Z0-9]{10,30}\b/g },
  {
    name: "phone",
    re: /\b(?:\+?3[58][\s-]?(?:\d[\s-]?){6,10}\d|(?:5|6|7|8)\d{2}\s?\d{4}|\d{3}\s\d{4})\b/g,
  },
];

/**
 * Scan [text] for surviving structured PII. Returns clean=false with the set
 * of detectors that fired if anything leaked. The caller decides what to do
 * (the gateway fails closed for special-category data).
 */
export function validateNoPii(text: string): ValidationResult {
  const leaks: Record<string, number> = {};
  if (!text) return { clean: true, leaks };
  for (const { name, re } of LEAK_DETECTORS) {
    const m = text.match(re);
    if (m && m.length > 0) leaks[name] = m.length;
  }
  return { clean: Object.keys(leaks).length === 0, leaks };
}
