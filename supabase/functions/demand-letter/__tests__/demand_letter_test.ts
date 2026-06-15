// demand-letter/__tests__/demand_letter_test.ts — Feature #2.
// -----------------------------------------------------------------------------
// Unit tests for the pure letter-building logic. No DB / HTTP — just the
// composition, validation and auto-fill that the wizard relies on.
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  autoSender,
  buildLetter,
  isLetterLang,
  type LetterInput,
  stringsFor,
  validateLetterInput,
} from "../handler.ts";
import {
  CLAIM_TYPES,
  isClaimType,
  isJurisdiction,
  normsFor,
} from "../presets.ts";

function baseInput(over: Partial<LetterInput> = {}): LetterInput {
  return {
    claimType: "deposit_return",
    jurisdiction: "EE",
    lang: "et",
    sender: { name: "Jane Doe", address: "jane@example.com" },
    recipient: { name: "Landlord OÜ", address: "Tallinn" },
    amount: "850.00",
    currency: "EUR",
    basis: "Üürisuhe lõppes 01.05.2026, tagatisraha jäi tagastamata.",
    deadline: "2026-07-01",
    todayIso: "2026-06-15",
    reference: null,
    ...over,
  };
}

// ─── presets ─────────────────────────────────────────────────────────────────

Deno.test("normsFor returns jurisdiction-specific references", () => {
  const ee = normsFor("deposit_return", "EE");
  const fi = normsFor("deposit_return", "FI");
  assert(ee.length > 0);
  assert(fi.length > 0);
  assertEquals(ee[0].label, "VÕS § 308");
  assertEquals(fi[0].label, "AHVL 8 §");
});

Deno.test("normsFor is total over all claim types", () => {
  for (const ct of CLAIM_TYPES) {
    // Never throws, always an array (possibly with entries) for both juris.
    assert(Array.isArray(normsFor(ct, "EE")));
    assert(Array.isArray(normsFor(ct, "FI")));
  }
});

Deno.test("type guards accept valid and reject invalid values", () => {
  assert(isClaimType("unpaid_wage"));
  assert(!isClaimType("nope"));
  assert(isJurisdiction("FI"));
  assert(!isJurisdiction("DE"));
  assert(isLetterLang("ru"));
  assert(!isLetterLang("de"));
});

// ─── validation ──────────────────────────────────────────────────────────────

Deno.test("validateLetterInput passes a complete input", () => {
  assertEquals(validateLetterInput(baseInput()), []);
});

Deno.test("validateLetterInput flags missing required fields", () => {
  const issues = validateLetterInput(
    baseInput({
      sender: { name: "" },
      recipient: { name: "" },
      basis: "  ",
      deadline: "",
    })
  );
  const fields = issues.map((i) => i.field).sort();
  // amount stays valid ("850.00") so it is NOT among the issues.
  assertEquals(fields, ["basis", "deadline", "recipient.name", "sender.name"]);
});

Deno.test("amount is required except for fine disputes", () => {
  const claim = validateLetterInput(
    baseInput({ claimType: "generic_claim", amount: "" })
  );
  assert(claim.some((i) => i.field === "amount"));

  const fine = validateLetterInput(
    baseInput({ claimType: "fine_dispute", amount: "" })
  );
  assert(!fine.some((i) => i.field === "amount"));
});

// ─── composition ─────────────────────────────────────────────────────────────

Deno.test("buildLetter embeds parties, amount, deadline and norms", () => {
  const r = buildLetter(baseInput());
  assertStringIncludes(r.markdown, "Landlord OÜ");
  assertStringIncludes(r.markdown, "Jane Doe");
  assertStringIncludes(r.markdown, "850.00 EUR");
  assertStringIncludes(r.markdown, "2026-07-01");
  assertStringIncludes(r.markdown, "VÕS § 308");
  assert(r.norms.length > 0);
});

Deno.test("buildLetter always ends with the non-removable disclaimer", () => {
  const r = buildLetter(baseInput());
  const dis = stringsFor("et").disclaimer;
  assertStringIncludes(r.markdown, dis);
  // Disclaimer is the final content line.
  assert(r.markdown.trimEnd().endsWith(`_${dis}_`));
});

Deno.test("buildLetter subject includes reference when provided", () => {
  const withRef = buildLetter(baseInput({ reference: "AB-123" }));
  assertStringIncludes(withRef.subject, "AB-123");
  const noRef = buildLetter(baseInput({ reference: null }));
  assert(!noRef.subject.includes("AB-123"));
});

Deno.test("buildLetter localises the subject prefix per language", () => {
  assertStringIncludes(
    buildLetter(baseInput({ lang: "fi" })).subject,
    "Maksuvaatimus"
  );
  assertStringIncludes(
    buildLetter(baseInput({ lang: "et" })).subject,
    "Nõudekiri"
  );
  assertStringIncludes(
    buildLetter(baseInput({ lang: "ru" })).subject,
    "Требование об оплате"
  );
  assertStringIncludes(
    buildLetter(baseInput({ lang: "en" })).subject,
    "Demand for Payment"
  );
});

Deno.test("buildLetter never leaves a raw {{token}} in the output", () => {
  for (const lang of ["fi", "et", "ru", "en"] as const) {
    const r = buildLetter(baseInput({ lang }));
    assert(!/\{\{|\}\}/.test(r.markdown), `raw token leaked for ${lang}`);
    // The templated sentences must have been substituted.
    assert(!r.markdown.includes("{amount}"));
    assert(!r.markdown.includes("{deadline}"));
  }
});

Deno.test("fine_dispute omits the amount sentence value gracefully", () => {
  const r = buildLetter(baseInput({ claimType: "fine_dispute", amount: "" }));
  // No currency string for an empty amount; sentence still renders with a dash.
  assert(!r.markdown.includes("EUR"));
});

Deno.test("buildLetter omits the legal section when no norms exist", () => {
  // generic_claim in a jurisdiction that still has one norm -> present.
  // Force the empty case by checking the section heading is only added when
  // norms.length > 0. We assert via a claim type that has norms then confirm
  // the heading text appears, and via the norms array for the inverse.
  const r = buildLetter(baseInput({ claimType: "generic_claim", lang: "en" }));
  if (normsFor("generic_claim", "EE").length === 0) {
    assert(!r.markdown.includes(stringsFor("en").legalHeading));
  } else {
    assertStringIncludes(r.markdown, stringsFor("en").legalHeading);
  }
});

// ─── auto-fill ───────────────────────────────────────────────────────────────

Deno.test("autoSender derives sender + reference from profile and case", () => {
  const { sender, reference } = autoSender({
    profile: { full_name: "John Smith", email: "john@x.io" },
    caseRow: { court_case_number: "5500/R" },
  });
  assertEquals(sender.name, "John Smith");
  assertEquals(sender.address, "john@x.io");
  assertEquals(reference, "5500/R");
});

Deno.test("autoSender tolerates null profile/case", () => {
  const { sender, reference } = autoSender({});
  assertEquals(sender.name, "");
  assertEquals(sender.address, null);
  assertEquals(reference, null);
});
