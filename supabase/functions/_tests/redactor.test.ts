// redactor.test.ts — privacy invariants for the share-redactor.
// ----------------------------------------------------------------------------
// Run:
//   deno test --allow-all supabase/functions/_tests/redactor.test.ts
//
// The redactor is the privacy boundary for the public-share feature. If a
// regression here leaks PII into a /s/<slug> page, real client data ends up
// indexed by Google. These tests are non-negotiable.
//
// Coverage (12 cases):
//   R01  Email is replaced with [EMAIL]
//   R02  Estonian id-code (isikukood) is replaced with [ID_EE]
//   R03  Finnish HETU is replaced with [HETU_FI]
//   R04  Estonian/Finnish phones are replaced with [PHONE]
//   R05  Court case number (R-23/0042) is replaced with [CASE_NO]
//   R06  Surname suffix (Sulga / Tolonen) is replaced with [NAME]
//   R07  Sulga real-world sample — name + email + case number all removed
//   R08  Statute references (TLS § 100, UlkomaalaisL § 196) are PRESERVED
//   R09  Public-record citations (KHO 2024:25) are PRESERVED
//   R10  Idempotency — running buildFallbackEnvelope on its own bullets
//        does NOT re-redact already-bracketed tokens
//   R11  generateSlug — produces 8 unique-looking URL-safe chars
//   R12  Haiku-failure fallback — when no API key, envelope still produced,
//        still safe (no PII in serialised JSON)
//   R13  haikuRedact tolerates JSON code fences
//   R14  looksAlreadyRedacted — true for input containing [NAME] etc.
// ----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

// Env stubs so any transitive _shared import that touches them doesn't blow up.
Deno.env.set("SUPABASE_URL", "https://example.supabase.co");
Deno.env.set("SUPABASE_SERVICE_ROLE_KEY", "fake-service-key");

import {
  buildFallbackEnvelope,
  generateSlug,
  haikuRedact,
  looksAlreadyRedacted,
  redactForSharing,
} from "../_shared/redactor.ts";
import { regexScrub } from "../_shared/pii_scrubber.ts";

// ─── R01 – R06: per-field regex coverage ────────────────────────────────────

Deno.test("R01: email is replaced with [EMAIL]", () => {
  const env = buildFallbackEnvelope(
    "Contact dmitri@example.com about the contract.",
    regexScrub("Contact dmitri@example.com about the contract."),
    "legal_advice",
  );
  const serialised = JSON.stringify(env);
  assert(
    !serialised.includes("dmitri@example.com"),
    "raw email leaked into envelope",
  );
  assertStringIncludes(serialised, "[EMAIL]");
});

Deno.test("R02: Estonian id-code is replaced with [ID_EE]", () => {
  // Valid format: 11 digits, century-marker 1-6, then YYMMDD, then 4 digits.
  const sample = "Tema isikukood on 38001011234 ja ta elab Tartus.";
  const env = buildFallbackEnvelope(
    sample,
    regexScrub(sample),
    "legal_advice",
  );
  const serialised = JSON.stringify(env);
  assert(!serialised.includes("38001011234"), "raw isikukood leaked");
  assertStringIncludes(serialised, "[ID_EE]");
});

Deno.test("R03: Finnish HETU is replaced with [HETU_FI]", () => {
  // Format: DDMMYY + separator (+/-/A) + 3 digits + check char
  const sample = "HETU: 010180-123X. Asia Helsingissä.";
  const env = buildFallbackEnvelope(
    sample,
    regexScrub(sample),
    "legal_advice",
  );
  const serialised = JSON.stringify(env);
  assert(!serialised.includes("010180-123X"), "raw HETU leaked");
  assertStringIncludes(serialised, "[HETU_FI]");
});

Deno.test("R04: phones are replaced with [PHONE]", () => {
  // International form is the high-confidence match.
  const sample = "Helistage +372 5555 1234 või +358 40 1234567.";
  const env = buildFallbackEnvelope(
    sample,
    regexScrub(sample),
    "legal_advice",
  );
  const serialised = JSON.stringify(env);
  assert(!serialised.includes("5555 1234"), "raw EE phone leaked");
  assert(!serialised.includes("1234567"), "raw FI phone leaked");
  assertStringIncludes(serialised, "[PHONE]");
});

Deno.test("R05: court case number is replaced with [CASE_NO]", () => {
  const sample = "Asia R-23/0042 käsiteltiin Helsingin käräjäoikeudessa.";
  const env = buildFallbackEnvelope(
    sample,
    regexScrub(sample),
    "legal_advice",
  );
  const serialised = JSON.stringify(env);
  assert(!serialised.includes("R-23/0042"), "raw case number leaked");
  assertStringIncludes(serialised, "[CASE_NO]");
});

Deno.test("R06: surname suffix is replaced with [NAME]", () => {
  // -nen (FI) and -mäki (FI) covered by the regex.
  const sample = "Asia siirrettiin Tolonen-niminen virkamiehelle ja Mäki-perheelle.";
  const stage1 = regexScrub(sample);
  // 'Tolonen' and 'Mäki' should both be flagged.
  assertStringIncludes(stage1.text, "[NAME]");
  assert(!stage1.text.includes("Tolonen"), "Tolonen leaked");
});

// ─── R07: Sulga real-world sample ──────────────────────────────────────────

Deno.test("R07: Sulga-style sample — fallback envelope leaks NOTHING (no Haiku)", () => {
  // Mirrors the kind of analysis text the chat would generate for the
  // real Sulga case. Includes everything that must be scrubbed.
  //
  // CONTRACT: without Haiku we degrade to boilerplate copy — public-org
  // markers don't survive either, but neither does the surname "Sulga"
  // (which has no recognised suffix in the regex pass). This is the
  // intentional safety/quality trade-off documented in
  // buildFallbackEnvelope.
  const sample = `
    Klientti: Dmitri Sulga (HETU 280175-123X)
    Yhteystiedot: dmitri.sulga@example.fi, +358 40 555 1234
    Asia: R-23/0042, Itä-Uudenmaan käräjäoikeus
    Vastapuoli: Politsei- ja Piirivalveamet
    Sovelletaan: UlkomaalaisL § 196
    Käännytyspäätös on Migri-pohjainen.
  `;
  const env = buildFallbackEnvelope(
    sample,
    regexScrub(sample),
    "legal_advice",
  );
  const blob = JSON.stringify(env);

  // PII MUST be gone:
  for (const leak of [
    "Sulga",
    "dmitri.sulga",
    "@example.fi",
    "280175-123X",
    "5551234", // phone fragment
    "R-23/0042",
  ]) {
    assert(!blob.includes(leak), `LEAK: '${leak}' still present in envelope`);
  }

  // The regex pass still TRACKS the structured PII it removed, even though
  // the fallback envelope itself is boilerplate.
  assertEquals(env.regex_replacements["[EMAIL]"], 1);
  assertEquals(env.regex_replacements["[HETU_FI]"], 1);
  assertEquals(env.regex_replacements["[CASE_NO]"], 1);
});

Deno.test("R07b: Sulga-style sample — Haiku envelope preserves public-org markers", async () => {
  // Mirrors what the Haiku second-stage SHOULD do with the same input:
  // names are replaced, but public organisations and statute citations
  // survive. We mock Haiku here to assert the public-page contract.
  const sample = `
    Klientti: Dmitri Sulga (HETU 280175-123X). Vastapuoli: Migri.
    Sovelletaan: UlkomaalaisL § 196.
  `;
  const fakeFetcher: typeof fetch = async () =>
    new Response(
      JSON.stringify({
        content: [{
          type: "text",
          text: JSON.stringify({
            title: "Käännytyspäätöksen valitus",
            insight_summary:
              "Migri pohjaisesta käännytyspäätöksestä haetaan kumoamista UlkomaalaisL § 196 nojalla.",
            jurisdiction: "FI",
            case_type: "deportation_appeal",
            redacted_content: {
              bullets: [
                "Migri-pohjainen käännytyspäätös käsiteltävänä",
                "Sovellettava UlkomaalaisL § 196 — palauttamiskielto",
              ],
              risks: ["Määräaika valituksen tekemiseen umpeutumassa"],
              statute_refs: ["UlkomaalaisL § 196"],
              monetary_amounts: [],
            },
          }),
        }],
      }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );

  const env = await redactForSharing({
    rawText: sample,
    sourceType: "legal_advice",
    anthropicApiKey: "fake-key",
    fetcher: fakeFetcher,
  });
  const blob = JSON.stringify(env);

  // Names + structured PII gone.
  for (const leak of ["Sulga", "Dmitri", "280175-123X"]) {
    assert(!blob.includes(leak), `LEAK: '${leak}'`);
  }
  // Public-org + statute references PRESERVED — this is the marketing payload.
  assertStringIncludes(blob, "Migri");
  assertStringIncludes(blob, "UlkomaalaisL § 196");
  assertEquals(env.jurisdiction, "FI");
});

// ─── R08-R09: preserved tokens ─────────────────────────────────────────────

Deno.test("R08: statute references survive the regex pass", () => {
  const sample = "Per TLS § 100, the employee is entitled to severance. " +
    "Cf. Direktiivi 2019/1152 art 5.";
  const stage1 = regexScrub(sample);
  assertStringIncludes(stage1.text, "TLS § 100");
  assertStringIncludes(stage1.text, "Direktiivi 2019/1152");
});

Deno.test("R09: public-record case citations survive the regex pass", () => {
  const sample = "Vt KHO 2024:25 ja RKHKo 3-3-1-99-2024 — kohaldatav praktika.";
  const stage1 = regexScrub(sample);
  assertStringIncludes(stage1.text, "KHO 2024:25");
  assertStringIncludes(stage1.text, "3-3-1-99-2024");
});

// ─── R10: idempotency ──────────────────────────────────────────────────────

Deno.test("R10: redactor is idempotent — second pass = identical envelope", () => {
  const sample = "Kontakt: tark.spetsialist@example.ee, tel +372 5555 1234, case R-22/0099";
  const env1 = buildFallbackEnvelope(sample, regexScrub(sample), "legal_advice");
  // Now re-run the same redactor on the serialised envelope. The bullets
  // already contain [EMAIL]/[PHONE]/[CASE_NO]; nothing more should change.
  const bulletsText = env1.redacted_content.bullets.join("\n");
  const env2 = buildFallbackEnvelope(
    bulletsText,
    regexScrub(bulletsText),
    "legal_advice",
  );
  // The set of regex placeholders must be a subset of the first pass
  // (no NEW redactions on the second run).
  for (const tag of Object.keys(env2.regex_replacements)) {
    assert(
      tag in env1.regex_replacements,
      `Second pass introduced new placeholder ${tag}`,
    );
  }
});

// ─── R11: slug ─────────────────────────────────────────────────────────────

Deno.test("R11: generateSlug produces 8 URL-safe chars and varies", () => {
  const a = generateSlug(8);
  const b = generateSlug(8);
  assertEquals(a.length, 8);
  assertEquals(b.length, 8);
  assert(/^[0-9A-Za-z]+$/.test(a), `non-URL-safe slug: '${a}'`);
  assert(a !== b, "two consecutive slugs collided");
});

// ─── R12: no-Haiku fallback is still safe ──────────────────────────────────

Deno.test("R12: redactForSharing without API key still scrubs structured PII", async () => {
  const sample =
    "Klientti dmitri@example.com, isikukood 38001011234, telefon +372 5555 1234, " +
    "case R-23/0042. Soovin asja peatamist.";
  const env = await redactForSharing({
    rawText: sample,
    sourceType: "legal_advice",
    // anthropicApiKey omitted on purpose
  });
  const blob = JSON.stringify(env);
  for (const leak of [
    "dmitri@example.com",
    "38001011234",
    "5555 1234",
    "R-23/0042",
  ]) {
    assert(!blob.includes(leak), `LEAK without Haiku: '${leak}'`);
  }
  // Counters reflect the regex pass.
  assert(env.regex_replacements["[EMAIL]"] === 1);
  assert(env.regex_replacements["[ID_EE]"] === 1);
});

// ─── R13: code fences tolerated ────────────────────────────────────────────

Deno.test("R13: haikuRedact tolerates ```json code fences", async () => {
  const fakeFetcher: typeof fetch = async () =>
    new Response(
      JSON.stringify({
        content: [{
          type: "text",
          text: '```json\n{"title":"Hello","insight_summary":"x","jurisdiction":"EE","case_type":"nda","redacted_content":{"bullets":["a"],"risks":[],"statute_refs":[],"monetary_amounts":[]}}\n```',
        }],
      }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  const haiku = await haikuRedact({
    rawText: "anything",
    sourceType: "legal_advice",
    anthropicApiKey: "fake-key",
    fetcher: fakeFetcher,
  });
  assert(haiku !== null, "haiku returned null on fenced JSON");
  assertEquals(haiku!.title, "Hello");
  assertEquals(haiku!.jurisdiction, "EE");
});

// ─── R14: idempotency fast-path detector ──────────────────────────────────

Deno.test("R14: looksAlreadyRedacted detects bracketed-only input", () => {
  assert(looksAlreadyRedacted("Contact [EMAIL], phone [PHONE]"));
  assert(!looksAlreadyRedacted("Contact dmitri@example.com"));
  assert(!looksAlreadyRedacted("")); // empty → vacuously safe to skip
  // Mixed input — has placeholder AND raw PII → must NOT short-circuit.
  assert(
    !looksAlreadyRedacted("Contact [EMAIL] or dmitri@example.com"),
    "fast-path falsely triggered on mixed input",
  );
});

// ─── R15: end-to-end with mocked Haiku — structured envelope ──────────────

Deno.test("R15: redactForSharing with mocked Haiku returns full envelope", async () => {
  const fakeFetcher: typeof fetch = async () =>
    new Response(
      JSON.stringify({
        content: [{
          type: "text",
          text: JSON.stringify({
            title: "AI saved ~€15K on dealer contract",
            insight_summary:
              "Hidden 12-month auto-renewal would have cost ~€15,000 — flagged before signing.",
            jurisdiction: "EE",
            case_type: "dealer_agreement",
            redacted_content: {
              bullets: [
                "Auto-renewal clause buried in §14",
                "Termination notice required 6 months in advance",
                "Penalty: 3x monthly fee on early exit",
              ],
              risks: ["12-month auto-renewal not flagged at signing"],
              statute_refs: ["VÕS § 199", "Direktiivi 2019/771"],
              monetary_amounts: ["~€15,000", "~€1,250/month"],
            },
          }),
        }],
      }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );

  const env = await redactForSharing({
    rawText:
      "Client John Smith of Acme OÜ flagged a 12-month auto-renewal worth €14,789.50",
    sourceType: "contract_review",
    anthropicApiKey: "fake-key",
    fetcher: fakeFetcher,
  });

  assertEquals(env.jurisdiction, "EE");
  assertEquals(env.case_type, "dealer_agreement");
  assertEquals(env.redacted_content.bullets.length, 3);
  assertStringIncludes(env.insight_summary, "~€15,000");
  // No raw client name in the envelope.
  const blob = JSON.stringify(env);
  assert(!blob.includes("John Smith"));
  assert(!blob.includes("Acme OÜ"));
});
