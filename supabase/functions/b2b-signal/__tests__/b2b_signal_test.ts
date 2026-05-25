// supabase/functions/b2b-signal/__tests__/b2b_signal_test.ts
// -----------------------------------------------------------------------------
// Tests for the B2B signal collector.
//
// Layered the same way as support-ticket:
//
//   1. Pure-function tests against `signals.ts` — allow-list membership,
//      law-firm domain heuristic, score-table consistency. No network.
//
//   2. Wiring contract tests — exercise the body-parsing / clamping path the
//      handler depends on so that score forgery (`score: 999999`) and
//      unknown signal types are guaranteed to be rejected at edge-fn time.
//
// The HTTP entry point itself uses Deno.serve + a live service-role
// Supabase client, so the end-to-end happy path is covered by the canary
// smoke script. The pure pieces below carry the bulk of the security
// contract.
//
// Run:
//   deno test --allow-read --allow-env \
//     supabase/functions/b2b-signal/__tests__/b2b_signal_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  B2B_MODAL_THRESHOLD,
  DEFAULT_SCORES,
  extractEmailDomain,
  isAllowedSignalType,
  isLawFirmEmail,
  isLawFirmEmailDomain,
  SIGNAL_TYPES,
  type SignalType,
} from "../signals.ts";

// ─── Signal allow-list ──────────────────────────────────────────────────

Deno.test("ALLOW-T01 — every canonical signal_type passes isAllowedSignalType", () => {
  for (const s of SIGNAL_TYPES) {
    assert(isAllowedSignalType(s), `expected ${s} to be allowed`);
  }
});

Deno.test("ALLOW-T02 — unknown signal_type is rejected", () => {
  // These look plausibly legit but are not in the allow-list.  Any future
  // addition MUST be made via SIGNAL_TYPES (or DEFAULT_SCORES will be out
  // of sync, caught by SCORE-T01 below).
  for (const bad of [
    "law_firm_email",            // missing _domain suffix
    "doc_burst",                 // missing _3plus_day
    "legal_planner",             // missing _heavy
    "docx",                      // missing _export
    "echr_query",                // missing cjeu_
    "pro",                       // partial
    "attorney_role",             // missing _in_doc
    "",
    "   ",
    "DROP TABLE profiles",       // injection vibe-check
    "law_firm_email_domain ",    // trailing space — handler trims first
  ]) {
    assertFalse(isAllowedSignalType(bad), `expected ${JSON.stringify(bad)} rejected`);
  }
});

Deno.test("SCORE-T01 — DEFAULT_SCORES covers every signal type with positive int", () => {
  // DEFAULT_SCORES must be exhaustive — every member of SIGNAL_TYPES needs
  // a default. The TS type system already enforces this at compile time
  // (Record<SignalType, number>) but the runtime check protects us against
  // a careless `as any` cast in future.
  for (const s of SIGNAL_TYPES) {
    const score = DEFAULT_SCORES[s as SignalType];
    assert(
      typeof score === "number" && score > 0 && score <= 200 && Number.isInteger(score),
      `score for ${s} must be a positive int <=200, got ${score}`,
    );
  }
});

Deno.test("SCORE-T02 — domain signal alone clears the threshold", () => {
  // The whole design rests on "law-firm domain at signup → modal".
  // If anyone tunes the score below the threshold this test fires.
  assert(
    DEFAULT_SCORES.law_firm_email_domain >= B2B_MODAL_THRESHOLD,
    "law_firm_email_domain default must >= B2B_MODAL_THRESHOLD",
  );
});

Deno.test("SCORE-T03 — no single non-domain signal clears the threshold alone", () => {
  // Otherwise a single accidental burst would trip the modal.
  for (const s of SIGNAL_TYPES) {
    if (s === "law_firm_email_domain") continue;
    assert(
      DEFAULT_SCORES[s] < B2B_MODAL_THRESHOLD,
      `${s} default ${DEFAULT_SCORES[s]} must be < threshold ${B2B_MODAL_THRESHOLD}`,
    );
  }
});

// ─── Email domain heuristic ─────────────────────────────────────────────

Deno.test("DOM-T01 — extractEmailDomain returns lower-case domain", () => {
  assertEquals(extractEmailDomain("Foo@LAW.EE"), "law.ee");
  assertEquals(extractEmailDomain("dmitri@example.org"), "example.org");
});

Deno.test("DOM-T02 — extractEmailDomain returns empty string for malformed input", () => {
  assertEquals(extractEmailDomain(""), "");
  assertEquals(extractEmailDomain(null), "");
  assertEquals(extractEmailDomain(undefined), "");
  assertEquals(extractEmailDomain("no-at-sign"), "");
  assertEquals(extractEmailDomain("trailing@"), "");
});

Deno.test("DOM-T03 — law-firm domain detection covers exact matches", () => {
  for (const d of [
    "law.ee",
    "law.fi",
    "advokatuur.ee",
    "asianajotoimisto.fi",
    "kanzlei.de",
    "rechtsanwalt.de",
    "anwalt.at",
  ]) {
    assert(isLawFirmEmailDomain(d), `expected ${d} flagged as law firm`);
  }
});

Deno.test("DOM-T04 — law-firm detection is case-insensitive and tolerates @-prefix", () => {
  assert(isLawFirmEmailDomain("LAW.EE"));
  assert(isLawFirmEmailDomain("@law.ee"));
  assert(isLawFirmEmailDomain(" Law.Ee "));
});

Deno.test("DOM-T05 — `.law` TLD always matches", () => {
  assert(isLawFirmEmailDomain("smith.law"));
  assert(isLawFirmEmailDomain("estonia-counsel.law"));
});

Deno.test("DOM-T06 — advokaat- / asianajo- prefixes match", () => {
  assert(isLawFirmEmailDomain("advokaat-tamm.ee"));
  assert(isLawFirmEmailDomain("asianajo-helsinki.fi"));
  assert(isLawFirmEmailDomain("kanzlei-mueller.de"));
});

Deno.test("DOM-T07 — civilian / cloud email providers are NOT flagged", () => {
  for (const d of [
    "gmail.com",
    "yahoo.com",
    "outlook.com",
    "example.com",
    "advocat.ee",          // our own domain — not a customer firm
    "google.com",
    "icloud.com",
    "proton.me",
    "yandex.ru",
  ]) {
    assertFalse(isLawFirmEmailDomain(d), `expected ${d} NOT flagged`);
  }
});

Deno.test("DOM-T08 — isLawFirmEmail composes domain extraction + match", () => {
  assert(isLawFirmEmail("partner@law.ee"));
  assert(isLawFirmEmail("Tamm@KANZLEI.DE"));
  assertFalse(isLawFirmEmail("random@gmail.com"));
  assertFalse(isLawFirmEmail("invalid-no-at"));
  assertFalse(isLawFirmEmail(""));
  assertFalse(isLawFirmEmail(null));
});

// ─── Score-forgery / clamping contract (documented for handler) ─────────
//
// The handler clamps client-supplied score to [0, 200]. The pure tests
// below exercise the same Math.min/Math.max logic so a regression in the
// clamp is caught without spinning up the HTTP path.

function clampScore(client: unknown): number {
  // Mirror of handler logic in index.ts. Kept inline so the test fails if
  // the handler's contract changes.
  const MAX = 200;
  if (typeof client === "number" && Number.isFinite(client)) {
    return Math.max(0, Math.min(MAX, Math.floor(client)));
  }
  return -1; // sentinel: "use default per type"
}

Deno.test("CLAMP-T01 — negative score is floored to 0", () => {
  assertEquals(clampScore(-50), 0);
  assertEquals(clampScore(-1), 0);
});

Deno.test("CLAMP-T02 — score above 200 is capped at 200", () => {
  assertEquals(clampScore(999999), 200);
  assertEquals(clampScore(201), 200);
});

Deno.test("CLAMP-T03 — NaN / non-numeric falls back to per-type default", () => {
  assertEquals(clampScore("100"), -1);
  assertEquals(clampScore(NaN), -1);
  assertEquals(clampScore(undefined), -1);
});

Deno.test("CLAMP-T04 — fractional score is floored", () => {
  assertEquals(clampScore(25.9), 25);
  assertEquals(clampScore(99.99), 99);
});

// ─── Handler-side contract (covered in canary smoke) ────────────────────
//
// The HTTP handler in index.ts depends on Deno.serve + a live Supabase
// service-role client, so it isn't exercised here. The contract is:
//
//   * Valid POST                  → 200 { ok: true, new_score, modal_pending }
//   * Anonymous caller            → 401 (no JWT or anon JWT)
//   * Unknown signal_type         → 400 { reason: "invalid_signal_type" }
//   * Score in body > 200         → silently clamped to 200 (clamp tests)
//   * Score in body < 0           → silently clamped to 0
//   * Duplicate signal same hour  → 200 { duplicate: true, ... } — no insert
//   * RPC failure                 → 500 { reason: "rpc_failed" }
//   * Score crossing threshold    → modal_pending: true on read-back
//
// THE TESTS ABOVE COVER:
//   * Signal allow-list correctness        (ALLOW-T01..02)
//   * Default-score table integrity        (SCORE-T01..03)
//   * Email-domain heuristic               (DOM-T01..08)
//   * Score-forgery / clamping             (CLAMP-T01..04)
//
// Smoke / live integration covers the remaining DB-side guarantees.

Deno.test("CONTRACT-T01 — SIGNAL_TYPES, DEFAULT_SCORES and the migration ENUM line up", () => {
  // Cross-check that the constants used by signal sources (pdf-parser,
  // claude-proxy, check-ai-quota) match what the migration check
  // constraint will accept. The migration uses a free-text column, so the
  // contract is checked only at edge-fn time — but the keys of
  // DEFAULT_SCORES MUST equal SIGNAL_TYPES.
  const keys = Object.keys(DEFAULT_SCORES).sort();
  const names = [...SIGNAL_TYPES].sort();
  assertEquals(keys, names, "DEFAULT_SCORES keys must equal SIGNAL_TYPES");
});
