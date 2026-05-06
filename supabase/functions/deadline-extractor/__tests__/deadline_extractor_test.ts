// Deno tests for deadline-extractor — Phase 2 Pkg 9.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/deadline-extractor/__tests__/deadline_extractor_test.ts
//
// Pure-function tests for routing helpers + the Sonnet output parser.
// HTTP-level tests are covered by the contract test in
// `test/contract/deadline_radar_migration_contract_test.dart`.
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  applyConfidenceFloor,
  DEADLINE_EXTRACTOR_CONFIDENCE_FLOOR,
  DEADLINE_EXTRACTOR_IDENTITY_MARKER,
  DEADLINE_EXTRACTOR_MODEL,
  DEADLINE_EXTRACTOR_SYSTEM_PROMPT,
  DEADLINE_EXTRACTOR_TIMEOUT_MS,
  parseExtractedDeadlines,
} from "../../_shared/deadline_extractor_prompt.ts";
import { ADVOCAT_IDENTITY_MARKERS } from "../../claude-proxy/system_prompt_guard.ts";
import {
  handleIntakePayload,
  handleManualPayload,
  handlePdfPayload,
  isoToUtcMidnight,
  isValidUuid,
  normalizeJurisdiction,
  wizardServiceClock,
} from "../index.ts";

// =============================================================================
// 1. Identity marker / system_prompt_guard parity
// =============================================================================

Deno.test("DLE-T01 — identity marker is whitelisted by system_prompt_guard", () => {
  assert(
    ADVOCAT_IDENTITY_MARKERS.includes(DEADLINE_EXTRACTOR_IDENTITY_MARKER),
    `${DEADLINE_EXTRACTOR_IDENTITY_MARKER} must be in ADVOCAT_IDENTITY_MARKERS`,
  );
});

Deno.test("DLE-T02 — system prompt starts with identity marker", () => {
  assert(DEADLINE_EXTRACTOR_SYSTEM_PROMPT.startsWith(
    DEADLINE_EXTRACTOR_IDENTITY_MARKER,
  ));
});

Deno.test("DLE-T03 — Sonnet model + timeout pinned", () => {
  // Sonnet, not Haiku, per consilium 2026-05.
  assert(DEADLINE_EXTRACTOR_MODEL.includes("sonnet"));
  assert(DEADLINE_EXTRACTOR_TIMEOUT_MS >= 5_000);
  assert(DEADLINE_EXTRACTOR_TIMEOUT_MS <= 30_000);
});

Deno.test("DLE-T04 — system prompt enumerates anchor registry keys", () => {
  // The Sonnet prompt embeds the static registry. If a new entry lands in
  // statutory_anchors.ts but the prompt was built once at import, this test
  // would fail. (Verifies that buildAnchorList() ran with our keys.)
  assert(DEADLINE_EXTRACTOR_SYSTEM_PROMPT.includes("ee_hkms_46_kaebus"));
  assert(DEADLINE_EXTRACTOR_SYSTEM_PROMPT.includes("fi_hol_2019_808_khoa"));
  assert(DEADLINE_EXTRACTOR_SYSTEM_PROMPT.includes("eu_echr_protocol_15"));
});

// =============================================================================
// 2. parseExtractedDeadlines — defensive JSON parsing
// =============================================================================

Deno.test("DLE-T10 — parses a happy-path Sonnet response", () => {
  const raw = JSON.stringify({
    deadlines: [{
      date: "2026-06-12",
      anchor_key: "fi_hol_2019_808_khoa",
      statute_basis: "HOL §164",
      title: "Valitus KHO:hon",
      priority: "critical",
      confidence: 0.92,
      reasoning: "Migri päätös served via turvaviesti, 30d clock.",
    }],
  });
  const result = parseExtractedDeadlines(raw);
  assertEquals(result.deadlines.length, 1);
  assertEquals(result.deadlines[0].date, "2026-06-12");
  assertEquals(result.deadlines[0].priority, "critical");
});

Deno.test("DLE-T11 — strips ```json fence", () => {
  const raw = "```json\n" + JSON.stringify({
    deadlines: [{
      date: "2026-06-12",
      anchor_key: "ee_hkms_46_kaebus",
      statute_basis: "HKMS §46",
      title: "Kaebus",
      priority: "critical",
      confidence: 0.88,
      reasoning: "x",
    }],
  }) + "\n```";
  const result = parseExtractedDeadlines(raw);
  assertEquals(result.deadlines.length, 1);
});

Deno.test("DLE-T12 — rejects unknown anchor_key", () => {
  const raw = JSON.stringify({
    deadlines: [{
      date: "2026-06-12",
      anchor_key: "fake_anchor_zzz",
      statute_basis: "x",
      title: "x",
      priority: "high",
      confidence: 0.9,
      reasoning: "x",
    }],
  });
  const result = parseExtractedDeadlines(raw);
  assertEquals(result.deadlines.length, 0);
});

Deno.test("DLE-T13 — rejects malformed date", () => {
  const raw = JSON.stringify({
    deadlines: [{
      date: "06/12/2026",
      anchor_key: "ee_hkms_46_kaebus",
      statute_basis: "x",
      title: "x",
      priority: "high",
      confidence: 0.9,
      reasoning: "x",
    }],
  });
  const result = parseExtractedDeadlines(raw);
  assertEquals(result.deadlines.length, 0);
});

Deno.test("DLE-T14 — non-JSON returns empty", () => {
  const result = parseExtractedDeadlines("nope");
  assertEquals(result.deadlines.length, 0);
});

Deno.test("DLE-T15 — null/undefined returns empty", () => {
  assertEquals(parseExtractedDeadlines(null).deadlines.length, 0);
  assertEquals(parseExtractedDeadlines(undefined).deadlines.length, 0);
});

Deno.test("DLE-T16 — clamps confidence to [0,1]", () => {
  const raw = JSON.stringify({
    deadlines: [{
      date: "2026-06-12",
      anchor_key: "ee_hkms_46_kaebus",
      statute_basis: "x",
      title: "x",
      priority: "high",
      confidence: 1.7,
      reasoning: "x",
    }],
  });
  const r = parseExtractedDeadlines(raw);
  assertEquals(r.deadlines[0].confidence, 1.0);
});

// =============================================================================
// 3. applyConfidenceFloor
// =============================================================================

Deno.test("DLE-T20 — confidence below floor downgrades to medium", () => {
  const r = applyConfidenceFloor({
    deadlines: [
      {
        date: "2026-06-12",
        anchor_key: "ee_hkms_46_kaebus",
        statute_basis: "x",
        title: "x",
        priority: "critical",
        confidence: DEADLINE_EXTRACTOR_CONFIDENCE_FLOOR - 0.1,
        reasoning: "x",
      },
    ],
  });
  assertEquals(r.deadlines[0].priority, "medium");
});

Deno.test("DLE-T21 — confidence at-or-above floor preserves priority", () => {
  const r = applyConfidenceFloor({
    deadlines: [
      {
        date: "2026-06-12",
        anchor_key: "ee_hkms_46_kaebus",
        statute_basis: "x",
        title: "x",
        priority: "critical",
        confidence: DEADLINE_EXTRACTOR_CONFIDENCE_FLOOR + 0.05,
        reasoning: "x",
      },
    ],
  });
  assertEquals(r.deadlines[0].priority, "critical");
});

// =============================================================================
// 4. PDF payload routing
// =============================================================================

Deno.test("DLE-T30 — PDF payload with FI court_decision matches HOL §164", () => {
  const rows = handlePdfPayload({
    doc_type: "court_decision",
    deadlines: [{
      date: "2026-06-12",
      what: "Valitus KHO:hon 30 päivän kuluessa",
      statute: "HOL §164",
    }],
    source_doc_id: "00000000-0000-0000-0000-000000000001",
  }, "FI");
  assert(rows.length >= 1);
  // At least one row must have the FI HOL anchor.
  const anchorRow = rows.find((r) => r.anchor_key === "fi_hol_2019_808_khoa");
  assert(anchorRow, "expected fi_hol_2019_808_khoa anchor match");
});

Deno.test("DLE-T31 — PDF payload with EE court_decision matches HKMS §46", () => {
  const rows = handlePdfPayload({
    doc_type: "court_decision",
    deadlines: [{
      date: "2026-06-10",
      what: "Kaebus halduskohtule",
      statute: "HKMS §46",
    }],
  }, "EE");
  const anchorRow = rows.find((r) => r.anchor_key === "ee_hkms_46_kaebus");
  assert(anchorRow);
  assertEquals((anchorRow as Record<string, unknown>).deadline_at,
    "2026-06-10T00:00:00.000Z");
});

Deno.test("DLE-T32 — PDF payload with no doc_type still emits row (anchor=null)", () => {
  const rows = handlePdfPayload({
    deadlines: [{ date: "2026-06-10", what: "Some date", statute: "" }],
  }, "EE");
  assertEquals(rows.length, 1);
  assertEquals(rows[0].anchor_key, null);
});

Deno.test("DLE-T33 — PDF payload with malformed date drops the entry", () => {
  const rows = handlePdfPayload({
    doc_type: "court_decision",
    deadlines: [
      { date: "junk", what: "x", statute: "x" },
      { date: "2026-06-10", what: "x", statute: "x" },
    ],
  }, "EE");
  // Only the well-formed date survives.
  assertEquals(rows.length, 1);
});

// =============================================================================
// 5. Intake payload routing
// =============================================================================

Deno.test("DLE-T40 — intake with service_date computes deadline via anchor", () => {
  // FI HOL §164 + 7d HL §60 turvaviesti default + 30d.
  // 2026-05-06 + 7d = 2026-05-13 + 30d = 2026-06-12 (Fri).
  const rows = handleIntakePayload({
    doc_type: "court_decision",
    service_date: "2026-05-06",
  }, "FI");
  assert(rows.length >= 1);
  const row = rows.find((r) => r.anchor_key === "fi_hol_2019_808_khoa");
  assert(row);
  // deadline_at is "2026-06-12T00:00:00.000Z" (midnight UTC).
  const isoDate = String((row as Record<string, unknown>).deadline_at).slice(0, 10);
  assertEquals(isoDate, "2026-06-12");
});

Deno.test("DLE-T41 — intake with service_date=null returns 0 rows (architect §10 #6)", () => {
  // The "do no harm" guarantee from the architect spec.
  const rows = handleIntakePayload({
    doc_type: "court_decision",
    service_date: null,
  }, "FI");
  assertEquals(rows.length, 0);
});

Deno.test("DLE-T42 — intake with malformed service_date returns 0 rows", () => {
  const rows = handleIntakePayload({
    doc_type: "court_decision",
    service_date: "06/05/2026",
  }, "EE");
  assertEquals(rows.length, 0);
});

Deno.test("DLE-T43 — intake with no anchor match for jurisdiction returns 0 rows", () => {
  // No EE anchor for 'final_domestic_judgment' (that's ECHR-only).
  const rows = handleIntakePayload({
    doc_type: "final_domestic_judgment",
    service_date: "2026-05-06",
  }, "EE");
  assertEquals(rows.length, 0);
});

Deno.test("DLE-T44 — intake EE court_decision computes 5d HMS §27 + 30d", () => {
  // 2026-05-06 (Wed) + 5d = 2026-05-11 (Mon) + 30d = 2026-06-10 (Wed).
  const rows = handleIntakePayload({
    doc_type: "court_decision",
    service_date: "2026-05-06",
  }, "EE");
  const row = rows.find((r) => r.anchor_key === "ee_hkms_46_kaebus");
  assert(row);
  assertEquals(
    String((row as Record<string, unknown>).deadline_at).slice(0, 10),
    "2026-06-10",
  );
});

// =============================================================================
// 6. Manual payload
// =============================================================================

Deno.test("DLE-T50 — manual payload with explicit deadline_at returns 1 row", () => {
  const rows = handleManualPayload({
    title: "Custom deadline",
    deadline_at: "2026-09-15T00:00:00Z",
    priority: "high",
  }, "EE");
  assertEquals(rows.length, 1);
  assertEquals(rows[0].title, "Custom deadline");
  assertEquals(rows[0].priority, "high");
});

Deno.test("DLE-T51 — manual payload with no deadline_at returns 0 rows", () => {
  assertEquals(handleManualPayload({ title: "x" }, "EE").length, 0);
});

Deno.test("DLE-T52 — manual payload with anchor_key links statute basis", () => {
  const rows = handleManualPayload({
    title: "Kaebus",
    deadline_at: "2026-09-15T00:00:00Z",
    anchor_key: "ee_hkms_46_kaebus",
  }, "EE");
  assertEquals(rows.length, 1);
  assertEquals(rows[0].anchor_key, "ee_hkms_46_kaebus");
  assertEquals(rows[0].statute_basis, "HKMS §46");
});

// =============================================================================
// 7. Helpers
// =============================================================================

Deno.test("DLE-T60 — wizardServiceClock defaults", () => {
  assertEquals(wizardServiceClock({}, "EE"), { days: 5, kind: "calendar" });
  assertEquals(wizardServiceClock({}, "FI"), { days: 7, kind: "calendar" });
  assertEquals(wizardServiceClock({}, "EU"), { days: 0, kind: "calendar" });
});

Deno.test("DLE-T61 — wizardServiceClock honors explicit override", () => {
  assertEquals(
    wizardServiceClock({ service_clock: { days: 3, kind: "working" } }, "FI"),
    { days: 3, kind: "working" },
  );
});

Deno.test("DLE-T62 — isoToUtcMidnight rejects bad strings", () => {
  assertEquals(isoToUtcMidnight("06/05/2026"), null);
  assertEquals(isoToUtcMidnight(""), null);
  assert(isoToUtcMidnight("2026-05-06") instanceof Date);
});

Deno.test("DLE-T63 — isValidUuid", () => {
  assert(isValidUuid("00000000-0000-0000-0000-000000000001"));
  assertFalse(isValidUuid("nope"));
  assertFalse(isValidUuid("00000000-0000-0000-0000-00000000000Z"));
});

Deno.test("DLE-T64 — normalizeJurisdiction", () => {
  assertEquals(normalizeJurisdiction("EE"), "EE");
  assertEquals(normalizeJurisdiction("ee"), "EE");
  assertEquals(normalizeJurisdiction("FI"), "FI");
  assertEquals(normalizeJurisdiction("EU"), "EU");
  assertEquals(normalizeJurisdiction("XX"), null);
  assertEquals(normalizeJurisdiction(undefined), null);
});
