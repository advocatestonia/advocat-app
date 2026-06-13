// pseudonymizer.ts — reversible PII pseudonymization for the LLM egress path.
// ----------------------------------------------------------------------------
// Unlike pii_scrubber.ts (which replaces PII with opaque [NAME]/[EMAIL] tags
// for the irreversible gold-corpus pipeline), this module produces STABLE,
// REVERSIBLE tokens — PERSON_1, EMAIL_1, ID_EE_1, … — and returns the mapping
// so a downstream draft can be re-hydrated with the real values AFTER the LLM
// round-trip. The same real value always maps to the same token within one
// call, so the model can co-refer ("PERSON_1 signed the contract that
// PERSON_2 …") without ever seeing the real identity.
//
// Design rules (from the 2026-06-13 Data Fortress consilium, must-fix items):
//   * DETERMINISTIC ordering: structured tokens (email/id/hetu/case) before
//     names, so a phone regex can't eat an email's digit suffix.
//   * REVERSIBLE: returns {token -> realValue} so case-drafting paths can
//     rehydrate. Generic Q&A paths simply ignore the map.
//   * The regex layer is the deterministic floor. A name the regex misses is
//     caught by the optional Haiku pass in the gateway (fail-CLOSED there).
//   * Public-record citations (KHO 2024:25, RKHKo 3-3-1-…) are NOT matched by
//     these patterns and are preserved verbatim.
// ----------------------------------------------------------------------------

export interface PseudonymizeResult {
  /** Text with real PII replaced by stable PERSON_N / EMAIL_N / … tokens. */
  text: string;
  /** token -> original real value, for rehydration after the LLM round-trip. */
  map: Record<string, string>;
  /** tag -> count, for telemetry (no real values). */
  counts: Record<string, number>;
}

// Each pattern carries a `class`:
//   "identifier" — a DIRECT government/financial identifier the LLM never
//                  needs for reasoning (isikukood, HETU, IBAN). Stripping it
//                  doesn't degrade answers or tool calls. Always scrubbed.
//   "contextual" — a value the LLM may need to reason or call tools with
//                  (names, emails, phones, case numbers). Scrubbed only in
//                  full mode; KEPT in identifiers-only mode (the main-chat
//                  tier, where EU-residency is the backstop and tool-calling /
//                  draft fidelity require the real value).
// Ordered most-structured-first. Surnames last (loosest pattern).
type PiiClass = "identifier" | "contextual";
const PATTERNS: Array<{ re: RegExp; prefix: string; cls: PiiClass }> = [
  { re: /\b[\w.+-]+@[\w.-]+\.\w{2,}\b/g, prefix: "EMAIL", cls: "contextual" },
  // Estonian ID (isikukood): 11 digits, century-marker prefix 1-6.
  { re: /\b[1-6]\d{2}[01]\d[0-3]\d{5}\b/g, prefix: "ID_EE", cls: "identifier" },
  // Finnish HETU: DDMMYY[+/-A]NNN[X]
  { re: /\b\d{6}[+\-A]\d{3}[\dA-Y]\b/g, prefix: "HETU_FI", cls: "identifier" },
  // IBAN (EE/FI and generic) — financial identifier.
  {
    re: /\b[A-Z]{2}\d{2}[A-Z0-9]{10,30}\b/g,
    prefix: "IBAN",
    cls: "identifier",
  },
  // Lower-court case numbers R-YY/NNNN, H-YY/NNNN.
  { re: /\b[RH]-\d{2}\/\d{4,}\b/g, prefix: "CASE_NO", cls: "contextual" },
  // EE/FI phones: +358/+372 international, or local Estonian formats.
  {
    re: /\b(?:\+?3[58][\s-]?(?:\d[\s-]?){6,10}\d|(?:5|6|7|8)\d{2}\s?\d{4}|\d{3}\s\d{4})\b/g,
    prefix: "PHONE",
    cls: "contextual",
  },
  // Estonian/Finnish surnames — capitalized word with a typical suffix.
  {
    re: /\b[A-ZÄÖÕÜŠŽÅ][a-zäöõüšžåéàèíóú]+(?:nen|saar|mäki|vald|poeg|väli|järvi|kivi|lainen|aho|virta|salo|laine|metsä|koski)\b/g,
    prefix: "PERSON",
    cls: "contextual",
  },
];

export interface PseudonymizeOpts {
  /**
   * When true, scrub ONLY direct "identifier"-class PII (isikukood, HETU,
   * IBAN) and leave contextual PII (names, emails, phones, case numbers)
   * intact. Used by the main-chat tier where the LLM needs real names/emails
   * for tool-calling and draft fidelity, and EU-residency is the backstop for
   * the rest. Default false = full scrub.
   */
  identifiersOnly?: boolean;
}

/**
 * Replace PII with stable reversible tokens. The same real value maps to the
 * same token throughout one call (so co-reference survives). Returns the
 * tokenized text plus the reverse map for rehydration.
 */
export function pseudonymize(
  input: string,
  opts: PseudonymizeOpts = {}
): PseudonymizeResult {
  if (!input) return { text: "", map: {}, counts: {} };

  const patterns = opts.identifiersOnly
    ? PATTERNS.filter((p) => p.cls === "identifier")
    : PATTERNS;

  let t = input;
  const map: Record<string, string> = {};
  const counts: Record<string, number> = {};
  // realValue -> token, so identical values reuse one token.
  const seen = new Map<string, string>();
  const nextN: Record<string, number> = {};

  for (const { re, prefix } of patterns) {
    t = t.replace(re, (match) => {
      let token = seen.get(match);
      if (!token) {
        nextN[prefix] = (nextN[prefix] ?? 0) + 1;
        token = `${prefix}_${nextN[prefix]}`;
        seen.set(match, token);
        map[token] = match;
      }
      counts[prefix] = (counts[prefix] ?? 0) + 1;
      return token;
    });
  }

  return { text: t, map, counts };
}

/**
 * Re-hydrate tokens back to real values in an LLM's output (e.g. a generated
 * draft). Replaces longest tokens first so PERSON_10 isn't clobbered by
 * PERSON_1. Tokens with no map entry are left untouched.
 */
export function rehydrate(text: string, map: Record<string, string>): string {
  if (!text || !map) return text ?? "";
  const tokens = Object.keys(map).sort((a, b) => b.length - a.length);
  let out = text;
  for (const token of tokens) {
    // Word-boundary-ish replace: tokens are [A-Z_0-9], match all occurrences.
    out = out.split(token).join(map[token]);
  }
  return out;
}
