// Deno TDD — probability_calibration.ts unit tests.
// -----------------------------------------------------------------------------
// Run with:
//   deno test supabase/functions/_shared/__tests__/probability_calibration_test.ts
// -----------------------------------------------------------------------------

import {
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  checkCalibration,
  parseHighEnd,
} from "../probability_calibration.ts";

// ─── parseHighEnd ─────────────────────────────────────────────────────────────

Deno.test("parseHighEnd — extracts high end from en-dash range", () => {
  assertEquals(parseHighEnd("15–25%"), 25);
});

Deno.test("parseHighEnd — extracts high end from em-dash range", () => {
  assertEquals(parseHighEnd("10—30%"), 30);
});

Deno.test("parseHighEnd — extracts high end from hyphen range", () => {
  assertEquals(parseHighEnd("5-8%"), 8);
});

Deno.test("parseHighEnd — tolerates spaces around dash", () => {
  assertEquals(parseHighEnd("20 – 40%"), 40);
});

Deno.test("parseHighEnd — extracts high end from sentence with prefix text", () => {
  assertEquals(
    parseHighEnd("weak — deadline likely missed, < 20% restoration, probability 5–15%"),
    15,
  );
});

Deno.test("parseHighEnd — returns null when no range present", () => {
  assertEquals(parseHighEnd("strong case"), null);
});

Deno.test("parseHighEnd — returns null for bare percentage without range", () => {
  assertEquals(parseHighEnd("~20%"), null);
});

Deno.test("parseHighEnd — returns null for empty string", () => {
  assertEquals(parseHighEnd(""), null);
});

// ─── checkCalibration ────────────────────────────────────────────────────────

Deno.test("checkCalibration — flags overclaim for valituslupa (anchor 20%, stated 70%)", () => {
  const warning = checkCalibration(
    "medium — 50–70% valituslupa chance",
    "client wants to file valituslupa at KHO",
  );
  assertEquals(typeof warning, "string");
  assertStringIncludes(warning!, "calibration-warning");
  assertStringIncludes(warning!, "valituslupa");
  assertStringIncludes(warning!, "70%");
});

Deno.test("checkCalibration — flags overclaim for ECHR (anchor 8%, stated 60%)", () => {
  const warning = checkCalibration(
    "strong — 40–60%",
    "submit echr complaint to Strasbourg",
  );
  assertEquals(typeof warning, "string");
  assertStringIncludes(warning!, "echr");
});

Deno.test("checkCalibration — returns null when within bounds for valituslupa (stated 40%, anchor+25=45)", () => {
  // 40 <= 20 + 25 = 45 — within bounds
  const warning = checkCalibration(
    "medium — 25–40%",
    "filing a valituslupa petition",
  );
  assertEquals(warning, null);
});

Deno.test("checkCalibration — returns null when no range in signal", () => {
  const warning = checkCalibration(
    "strong case overall",
    "valituslupa appeal KHO",
  );
  assertEquals(warning, null);
});

Deno.test("checkCalibration — returns null when no anchor matches context", () => {
  const warning = checkCalibration(
    "50–90%",
    "general contract dispute in civil court",
  );
  assertEquals(warning, null);
});

Deno.test("checkCalibration — flags overclaim for menetetyn määräajan (anchor 15%, stated 60%)", () => {
  const warning = checkCalibration(
    "40–60%",
    "menetetyn määräajan palauttaminen request",
  );
  assertEquals(typeof warning, "string");
  assertStringIncludes(warning!, "menetetyn määräajan");
  assertStringIncludes(warning!, "60%");
});

Deno.test("checkCalibration — compensation within bounds (anchor 70%, stated 90%, diff=20 < 25)", () => {
  // 90 <= 70 + 25 = 95 — just within bounds
  const warning = checkCalibration(
    "70–90%",
    "compensation claim for victim after conviction",
  );
  assertEquals(warning, null);
});

Deno.test("checkCalibration — compensation overclaim (anchor 70%, stated 100%, diff=30 > 25)", () => {
  const warning = checkCalibration(
    "75–100%",
    "compensation claim for victim after conviction",
  );
  assertEquals(typeof warning, "string");
  assertStringIncludes(warning!, "compensation");
});
