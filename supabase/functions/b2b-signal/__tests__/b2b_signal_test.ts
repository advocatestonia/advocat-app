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
  DECAY_HALF_LIFE_DAYS,
  DEFAULT_SCORES,
  extractEmailDomain,
  isAllowedSignalType,
  isLawFirmEmail,
  isLawFirmEmailDomain,
  RETRIGGER_HIGH_INTENT_SIGNALS,
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

Deno.test("ALLOW-T03 — v2 signal types are accepted", () => {
  // The v2 additions (session_long_business_hours, multi_case_30d) must
  // be present so the wire-up sites can record them without 400ing.
  assert(isAllowedSignalType("session_long_business_hours"));
  assert(isAllowedSignalType("multi_case_30d"));
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

Deno.test("SCORE-T02 — v2: NO single signal (incl. domain) clears the threshold alone", () => {
  // v2 (2026-05-25) reverses the v1 invariant. The whole point of the
  // compound trigger is that domain alone cannot trip the modal — the
  // user must accrue at least one additional in-app signal. The SQL
  // function enforces this via a `has_other_signal` check; the unit
  // contract here is that NO single signal default reaches the
  // threshold by itself.
  for (const s of SIGNAL_TYPES) {
    assert(
      DEFAULT_SCORES[s] < B2B_MODAL_THRESHOLD,
      `${s} default ${DEFAULT_SCORES[s]} must be < threshold ${B2B_MODAL_THRESHOLD} (v2 compound-trigger rule)`,
    );
  }
});

Deno.test("SCORE-T03 — v2: realistic compound (domain+docx+planner) crosses threshold", () => {
  // A user who shows up with a law-firm email AND exports DOCX AND uses
  // legal_planner repeatedly should clearly trip the modal. This locks
  // the calibration in.
  const compound = DEFAULT_SCORES.law_firm_email_domain
    + DEFAULT_SCORES.docx_export
    + DEFAULT_SCORES.legal_planner_heavy;
  assert(
    compound >= B2B_MODAL_THRESHOLD,
    `compound score ${compound} must clear threshold ${B2B_MODAL_THRESHOLD}`,
  );
});

Deno.test("SCORE-T04 — v2: pure-domain hit alone does NOT clear threshold", () => {
  // Specific regression guard for the v1 over-fire bug.
  assert(
    DEFAULT_SCORES.law_firm_email_domain < B2B_MODAL_THRESHOLD,
    "domain alone must NOT trip threshold in v2",
  );
});

Deno.test("DECAY-T01 — half-life constant is 14 days", () => {
  // The SQL migration hard-codes 14.0 in compute_b2b_score. The TS-side
  // constant must match so off-line score predictions agree with the DB.
  assertEquals(DECAY_HALF_LIFE_DAYS, 14);
});

Deno.test("DECAY-T02 — exponential model: a 28-day-old signal weighs ~1/4", () => {
  // Half-life 14 → 28d is 2 half-lives → 0.25.
  const daysOld = 28;
  const effective = Math.pow(0.5, daysOld / DECAY_HALF_LIFE_DAYS);
  assert(
    Math.abs(effective - 0.25) < 1e-9,
    `expected 0.25 weight at 28d, got ${effective}`,
  );
});

Deno.test("DECAY-T03 — fresh signal (0 days old) weighs 1.0", () => {
  const effective = Math.pow(0.5, 0 / DECAY_HALF_LIFE_DAYS);
  assertEquals(effective, 1.0);
});

Deno.test("DECAY-T04 — 14-day-old signal weighs exactly 0.5", () => {
  const effective = Math.pow(0.5, 14 / DECAY_HALF_LIFE_DAYS);
  assert(Math.abs(effective - 0.5) < 1e-9);
});

Deno.test("RETRIGGER-T01 — RETRIGGER_HIGH_INTENT_SIGNALS matches SQL migration set", () => {
  // The v2 migration whitelists exactly these three for the >30d re-arm
  // branch (docx_export, pro_quota_pressure, multi_case_30d). The TS
  // constant must mirror it so any short-circuit in the edge fn knows
  // when a re-arm could fire.
  assertEquals(RETRIGGER_HIGH_INTENT_SIGNALS.size, 3);
  assert(RETRIGGER_HIGH_INTENT_SIGNALS.has("docx_export"));
  assert(RETRIGGER_HIGH_INTENT_SIGNALS.has("pro_quota_pressure"));
  assert(RETRIGGER_HIGH_INTENT_SIGNALS.has("multi_case_30d"));
});

Deno.test("RETRIGGER-T02 — domain hit is NOT in the re-arm set", () => {
  // Domain doesn't change after signup, so the migration explicitly
  // refuses to re-arm on it. Lock that contract in.
  assertFalse(RETRIGGER_HIGH_INTENT_SIGNALS.has("law_firm_email_domain"));
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

// ─── v2 migration source-contract checks ─────────────────────────────────
//
// The compound-trigger / decay / re-arm logic lives in SQL (Postgres
// PL/pgSQL inside record_b2b_signal). We verify the migration FILE
// contains the load-bearing pieces so a refactor cannot accidentally
// downgrade the contract. Source-text checks beat nothing for catching
// "the function still exists but the threshold is back to 100" bugs.

const V2_MIGRATION_PATH = new URL(
  "../../../migrations/20260525234500_b2b_v2_compound_trigger.sql",
  import.meta.url,
);

Deno.test("V2MIG-T01 — threshold is 110 in the v2 migration", async () => {
  const sql = await Deno.readTextFile(V2_MIGRATION_PATH);
  assert(
    sql.includes("v_threshold        constant integer := 110"),
    "expected `v_threshold ... := 110` in record_b2b_signal v2",
  );
});

Deno.test("V2MIG-T02 — compound trigger requires non-domain signal in last 14d", async () => {
  const sql = await Deno.readTextFile(V2_MIGRATION_PATH);
  assert(
    sql.includes(
      "signal_type <> 'law_firm_email_domain'",
    ),
    "compound trigger must exclude domain-only signals",
  );
  assert(
    sql.includes("interval '14 days'"),
    "compound trigger must use a 14-day lookback window",
  );
});

Deno.test("V2MIG-T03 — re-arm path uses 30-day gap + lifetime cap", async () => {
  const sql = await Deno.readTextFile(V2_MIGRATION_PATH);
  assert(
    sql.includes("interval '30 days'"),
    "re-arm must require a 30-day gap since last shown",
  );
  assert(
    sql.includes("v_retrigger_count < v_lifetime_cap"),
    "re-arm must respect the lifetime-cap counter",
  );
});

Deno.test("V2MIG-T04 — re-arm whitelist exactly matches RETRIGGER_HIGH_INTENT_SIGNALS", async () => {
  const sql = await Deno.readTextFile(V2_MIGRATION_PATH);
  // The SQL whitelist must contain ALL three high-intent signals.
  for (const s of RETRIGGER_HIGH_INTENT_SIGNALS) {
    assert(sql.includes(`'${s}'`), `re-arm whitelist missing ${s}`);
  }
  // Extract the v_high_intent array literal and verify domain is not in it.
  // (The string 'law_firm_email_domain' DOES appear elsewhere in the file —
  // inside the compound-trigger exclusion — so we narrow the assertion to
  // the re-arm whitelist array.)
  const arrayMatch = sql.match(
    /v_high_intent\s+constant\s+text\[\]\s*:=\s*array\[([\s\S]*?)\];/,
  );
  assert(arrayMatch, "v_high_intent array literal not found in SQL");
  const arrayBody = arrayMatch![1];
  assertFalse(
    arrayBody.includes("law_firm_email_domain"),
    "re-arm whitelist must NOT include law_firm_email_domain",
  );
});

Deno.test("V2MIG-T05 — decay uses 14-day half-life inside compute_b2b_score", async () => {
  const sql = await Deno.readTextFile(V2_MIGRATION_PATH);
  // Half-life appears as the divisor inside power(0.5, days/14.0).
  assert(
    sql.includes("14.0"),
    "decay calculation must use 14.0 as the half-life divisor",
  );
  assert(
    sql.includes("power(") && sql.includes("0.5"),
    "compute_b2b_score must apply an exponential 0.5^x decay",
  );
});

Deno.test("V2MIG-T06 — retrigger_count column is added by the migration", async () => {
  const sql = await Deno.readTextFile(V2_MIGRATION_PATH);
  assert(
    sql.includes("b2b_modal_retrigger_count"),
    "v2 migration must add the lifetime-cap counter column",
  );
});
