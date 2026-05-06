// Deno tests for `_shared/statutory_anchors.ts` — Phase 2 Pkg 9.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/_shared/__tests__/statutory_anchors_test.ts
//
// Spec source of truth: docs/architecture/phase2-pkg9-deadline-radar.md §2.
//
// `STATUTORY_DEADLINE_TEMPLATES` is the single registry of statutory deadline
// templates. The extractor matches against `triggerDocType` + `jurisdiction`
// to apply templates. Modifiers (e.g. HMS §27 e-service) are not deadlines on
// their own — `kind === 'modifier'`.
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertExists,
  assertNotEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  findAnchor,
  STATUTORY_DEADLINE_TEMPLATES,
  type StatutoryAnchor,
} from "../statutory_anchors.ts";

// =============================================================================
// 1. Registry shape
// =============================================================================

Deno.test("SA-T01 — registry has the eight architect-spec entries", () => {
  const requiredKeys = [
    "ee_hkms_46_kaebus",
    "ee_hms_75_vaie",
    "ee_hms_27_e_service",
    "fi_hol_2019_808_khoa",
    "fi_hl_49b_oikaisu",
    "fi_hl_59_regular_email_service",
    "fi_hl_60_turvaviesti_service",
    "fi_posti_omniva_pickup",
    "eu_echr_protocol_15",
  ];
  for (const key of requiredKeys) {
    const a = STATUTORY_DEADLINE_TEMPLATES[key];
    assertExists(a, `template ${key} must be defined`);
    assertEquals(a.key, key, `entry ${key} must self-reference its key`);
  }
});

Deno.test("SA-T02 — every entry has the required fields", () => {
  for (const [key, a] of Object.entries(STATUTORY_DEADLINE_TEMPLATES)) {
    assert(typeof a.key === "string" && a.key.length > 0, `${key}: key`);
    assert(typeof a.jurisdiction === "string", `${key}: jurisdiction`);
    assert(typeof a.statute === "string" && a.statute.length > 0, `${key}: statute`);
    assert(typeof a.kind === "string", `${key}: kind`);
    assert(
      a.kind === "deadline" || a.kind === "modifier",
      `${key}: kind must be 'deadline' | 'modifier'`,
    );
    assert(typeof a.days === "number", `${key}: days`);
    assert(
      a.unit === "calendar_days" || a.unit === "working_days" ||
        a.unit === "calendar_months",
      `${key}: unit must be one of calendar_days|working_days|calendar_months`,
    );
    assert(
      a.holidayShiftPolicy === "next_business_day" ||
        a.holidayShiftPolicy === "strict_calendar",
      `${key}: holidayShiftPolicy`,
    );
    assert(
      typeof a.serviceBasis === "string" && a.serviceBasis.length > 0,
      `${key}: serviceBasis`,
    );
  }
});

// =============================================================================
// 2. Per-entry semantics
// =============================================================================

Deno.test("SA-T10 — ee_hkms_46_kaebus: 30 calendar days, EE jurisdiction, deadline kind", () => {
  const a = STATUTORY_DEADLINE_TEMPLATES["ee_hkms_46_kaebus"];
  assertEquals(a.jurisdiction, "EE");
  assertEquals(a.days, 30);
  assertEquals(a.unit, "calendar_days");
  assertEquals(a.kind, "deadline");
  assertEquals(a.holidayShiftPolicy, "next_business_day");
  assert(a.statute.includes("HKMS"));
  assertExists(a.triggerDocTypes);
  assert(a.triggerDocTypes.includes("court_decision"));
});

Deno.test("SA-T11 — ee_hms_75_vaie: 30 calendar days, vaie", () => {
  const a = STATUTORY_DEADLINE_TEMPLATES["ee_hms_75_vaie"];
  assertEquals(a.jurisdiction, "EE");
  assertEquals(a.days, 30);
  assertEquals(a.kind, "deadline");
  assert(a.statute.includes("HMS"));
});

Deno.test("SA-T12 — ee_hms_27_e_service: modifier, +5 calendar days", () => {
  const a = STATUTORY_DEADLINE_TEMPLATES["ee_hms_27_e_service"];
  assertEquals(a.kind, "modifier");
  assertEquals(a.days, 5);
  assertEquals(a.unit, "calendar_days");
});

Deno.test("SA-T13 — fi_hol_2019_808_khoa: 30 calendar days, deadline kind", () => {
  const a = STATUTORY_DEADLINE_TEMPLATES["fi_hol_2019_808_khoa"];
  assertEquals(a.jurisdiction, "FI");
  assertEquals(a.days, 30);
  assertEquals(a.unit, "calendar_days");
  assertEquals(a.kind, "deadline");
  assertEquals(a.holidayShiftPolicy, "next_business_day");
});

Deno.test("SA-T14 — fi_hl_49b_oikaisu: 30 calendar days, deadline kind", () => {
  const a = STATUTORY_DEADLINE_TEMPLATES["fi_hl_49b_oikaisu"];
  assertEquals(a.jurisdiction, "FI");
  assertEquals(a.days, 30);
  assertEquals(a.kind, "deadline");
});

Deno.test("SA-T15 — fi_hl_59_regular_email_service: modifier, +3 working days", () => {
  const a = STATUTORY_DEADLINE_TEMPLATES["fi_hl_59_regular_email_service"];
  assertEquals(a.kind, "modifier");
  assertEquals(a.days, 3);
  assertEquals(a.unit, "working_days");
});

Deno.test("SA-T16 — fi_hl_60_turvaviesti_service: modifier, +7 calendar days", () => {
  const a = STATUTORY_DEADLINE_TEMPLATES["fi_hl_60_turvaviesti_service"];
  assertEquals(a.kind, "modifier");
  assertEquals(a.days, 7);
  assertEquals(a.unit, "calendar_days");
});

Deno.test("SA-T17 — fi_posti_omniva_pickup: modifier, 14 calendar days", () => {
  const a = STATUTORY_DEADLINE_TEMPLATES["fi_posti_omniva_pickup"];
  assertEquals(a.kind, "modifier");
  assertEquals(a.days, 14);
  assertEquals(a.unit, "calendar_days");
});

Deno.test("SA-T18 — eu_echr_protocol_15: 4 calendar months, strict_calendar (NO shift)", () => {
  // The single most important per-entry test in this file: ECHR Protocol 15
  // is a 4-month strict-calendar deadline. A regression that changed the
  // policy to next_business_day would silently shift Strasbourg deadlines
  // forward and the user would file a day late and lose the right.
  const a = STATUTORY_DEADLINE_TEMPLATES["eu_echr_protocol_15"];
  assertEquals(a.jurisdiction, "EU");
  assertEquals(a.days, 4);
  assertEquals(a.unit, "calendar_months");
  assertEquals(a.kind, "deadline");
  assertEquals(
    a.holidayShiftPolicy,
    "strict_calendar",
    "ECHR Protocol 15 must NOT shift over weekends/holidays",
  );
});

// =============================================================================
// 3. findAnchor lookup helper
// =============================================================================

Deno.test("SA-T30 — findAnchor by key returns the entry", () => {
  const a = findAnchor("ee_hkms_46_kaebus");
  assertExists(a);
  assertEquals(a.jurisdiction, "EE");
});

Deno.test("SA-T31 — findAnchor on unknown key returns null", () => {
  const a = findAnchor("nope_no_such_anchor");
  assertEquals(a, null);
});

// =============================================================================
// 4. UI labels: every deadline kind has at least one localized label
// =============================================================================

Deno.test("SA-T40 — every deadline-kind entry has uiLabels for ET+EN+FI+RU", () => {
  for (const a of Object.values(STATUTORY_DEADLINE_TEMPLATES)) {
    if (a.kind !== "deadline") continue;
    assertExists(a.uiLabels, `${a.key}: missing uiLabels`);
    // EN must always be present (admin / cross-language fallback).
    assertExists(a.uiLabels.en, `${a.key}: missing uiLabels.en`);
    assertNotEquals(a.uiLabels.en.trim(), "", `${a.key}: empty uiLabels.en`);
  }
});

// =============================================================================
// 5. Trigger doc types
// =============================================================================

Deno.test("SA-T50 — every deadline anchor declares at least one triggerDocType", () => {
  for (const a of Object.values(STATUTORY_DEADLINE_TEMPLATES)) {
    if (a.kind !== "deadline") continue;
    assertExists(a.triggerDocTypes);
    assert(
      a.triggerDocTypes.length > 0,
      `${a.key}: triggerDocTypes empty — extractor will never apply`,
    );
  }
});
