// Deno tests for `_shared/holiday_shift.ts` — Phase 2 Pkg 9 deadline radar.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/_shared/__tests__/holiday_shift_test.ts
//
// Spec source of truth: docs/architecture/phase2-pkg9-deadline-radar.md §3.
//
// `shiftDeadline` is the single source of truth for holiday awareness. Both
// the server-side extractor (deadline-extractor) and the cron pusher
// (deadline-radar-tick) consume its output; the Dart client only reads the
// already-shifted timestamps from the DB.
//
// Two policies:
//   * 'next_business_day'  — shift forward over weekends + FI/EE holidays
//     (the default for kaebus / valitus / oikaisuvaatimus / vaie).
//   * 'strict_calendar'    — no shift, never (ECHR Protocol 15).
//
// FI/EE holiday lists are encoded for 2026 + 2027 in
// `_shared/holidays_fi_ee.ts`. The test below pins specific 2026 dates we
// know to be holidays so a typo or a year-rollover regression is caught.
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  computeAbsoluteDeadline,
  isFinnishHoliday,
  isEstonianHoliday,
  isWeekend,
  shiftDeadline,
  type ShiftPolicy,
} from "../holiday_shift.ts";

// =============================================================================
// 1. Weekend detection
// =============================================================================

Deno.test("HS-T01 — Saturdays detected as weekend", () => {
  // 2026-06-13 is a Saturday.
  assert(isWeekend(new Date("2026-06-13T12:00:00Z")));
});

Deno.test("HS-T02 — Sundays detected as weekend", () => {
  // 2026-06-14 is a Sunday.
  assert(isWeekend(new Date("2026-06-14T12:00:00Z")));
});

Deno.test("HS-T03 — Mondays not weekend", () => {
  assertFalse(isWeekend(new Date("2026-06-15T12:00:00Z")));
});

// =============================================================================
// 2. FI/EE holiday lookup (2026)
// =============================================================================

Deno.test("HS-T10 — FI: New Year 2026-01-01 is a holiday", () => {
  assert(isFinnishHoliday(new Date("2026-01-01T12:00:00Z")));
});

Deno.test("HS-T11 — FI: Independence Day 2026-12-06 is a holiday", () => {
  // 2026-12-06 is a Sunday in 2026 — itsenäisyyspäivä regardless.
  assert(isFinnishHoliday(new Date("2026-12-06T12:00:00Z")));
});

Deno.test("HS-T12 — FI: Midsummer Eve 2026 is a holiday (juhannusaatto)", () => {
  // Juhannusaatto = the Friday between 19-25 June. In 2026 that's 2026-06-19.
  assert(isFinnishHoliday(new Date("2026-06-19T12:00:00Z")));
});

Deno.test("HS-T13 — EE: Võidupüha 2026-06-23 is a holiday", () => {
  assert(isEstonianHoliday(new Date("2026-06-23T12:00:00Z")));
});

Deno.test("HS-T14 — EE: Jaanipäev 2026-06-24 is a holiday", () => {
  assert(isEstonianHoliday(new Date("2026-06-24T12:00:00Z")));
});

Deno.test("HS-T15 — EE: Independence Day 2026-02-24 is a holiday", () => {
  assert(isEstonianHoliday(new Date("2026-02-24T12:00:00Z")));
});

Deno.test("HS-T16 — random non-holiday Tuesday is not a holiday", () => {
  assertFalse(isFinnishHoliday(new Date("2026-09-15T12:00:00Z")));
  assertFalse(isEstonianHoliday(new Date("2026-09-15T12:00:00Z")));
});

// =============================================================================
// 3. shiftDeadline — next_business_day policy
// =============================================================================

Deno.test("HS-T20 — Saturday shifts to Monday under next_business_day", () => {
  // 2026-08-08 = Saturday. Mon = 2026-08-10.
  const result = shiftDeadline(new Date("2026-08-08T12:00:00Z"), {
    jurisdiction: "FI",
    policy: "next_business_day",
  });
  assertEquals(result.shiftedAt.toISOString().slice(0, 10), "2026-08-10");
  assert(result.shifted);
});

Deno.test("HS-T21 — Sunday shifts to Monday under next_business_day", () => {
  const result = shiftDeadline(new Date("2026-08-09T12:00:00Z"), {
    jurisdiction: "EE",
    policy: "next_business_day",
  });
  assertEquals(result.shiftedAt.toISOString().slice(0, 10), "2026-08-10");
  assert(result.shifted);
});

Deno.test("HS-T22 — Tuesday stays Tuesday under next_business_day", () => {
  const result = shiftDeadline(new Date("2026-09-15T12:00:00Z"), {
    jurisdiction: "FI",
    policy: "next_business_day",
  });
  assertEquals(result.shiftedAt.toISOString().slice(0, 10), "2026-09-15");
  assertFalse(result.shifted);
});

Deno.test("HS-T23 — FI: deadline on juhannusaatto 2026-06-19 shifts past midsummer weekend", () => {
  // 2026-06-19 = juhannusaatto (Fri holiday). 06-20 Sat, 06-21 Sun — next
  // working day is Mon 2026-06-22.
  const result = shiftDeadline(new Date("2026-06-19T12:00:00Z"), {
    jurisdiction: "FI",
    policy: "next_business_day",
  });
  assertEquals(result.shiftedAt.toISOString().slice(0, 10), "2026-06-22");
  assert(result.shifted);
  assert(result.note.length > 0, "note must explain the shift");
});

Deno.test("HS-T24 — EE: deadline on Jaanipäev 2026-06-24 (Wed) shifts to Thu", () => {
  // 2026-06-23 (Tue) Võidupüha + 2026-06-24 (Wed) Jaanipäev. Skip both,
  // Thu 2026-06-25 is the next business day.
  const result = shiftDeadline(new Date("2026-06-24T12:00:00Z"), {
    jurisdiction: "EE",
    policy: "next_business_day",
  });
  assertEquals(result.shiftedAt.toISOString().slice(0, 10), "2026-06-25");
  assert(result.shifted);
});

Deno.test("HS-T25 — EE: deadline on Võidupüha 2026-06-23 (Tue) shifts past Jaanipäev", () => {
  // Tue 06-23 holiday → Wed 06-24 holiday → Thu 06-25.
  const result = shiftDeadline(new Date("2026-06-23T12:00:00Z"), {
    jurisdiction: "EE",
    policy: "next_business_day",
  });
  assertEquals(result.shiftedAt.toISOString().slice(0, 10), "2026-06-25");
  assert(result.shifted);
});

// =============================================================================
// 4. shiftDeadline — strict_calendar policy (ECHR Protocol 15)
// =============================================================================

Deno.test("HS-T30 — strict_calendar: Saturday stays Saturday (ECHR rule)", () => {
  const result = shiftDeadline(new Date("2026-08-08T12:00:00Z"), {
    jurisdiction: "EU",
    policy: "strict_calendar",
  });
  assertEquals(result.shiftedAt.toISOString().slice(0, 10), "2026-08-08");
  assertFalse(result.shifted);
});

Deno.test("HS-T31 — strict_calendar: holiday-on-Mon stays Monday (ECHR rule)", () => {
  // ECHR doesn't care about FI midsummer, doesn't care about EE võidupüha.
  // Pick a date that's a Finnish holiday: 2026-05-01 (vappu / 1.5).
  // 2026-05-01 is a Friday in 2026.
  const result = shiftDeadline(new Date("2026-05-01T12:00:00Z"), {
    jurisdiction: "EU",
    policy: "strict_calendar",
  });
  assertEquals(result.shiftedAt.toISOString().slice(0, 10), "2026-05-01");
  assertFalse(result.shifted);
});

// =============================================================================
// 5. computeAbsoluteDeadline — full pipeline
// =============================================================================

Deno.test("HS-T40 — FI HOL §164: Migri turvaviesti 2026-05-06 → 2026-06-12 (no shift needed)", () => {
  // Service 2026-05-06 + 7d HL §60 turvaviesti pickup = 2026-05-13 (Wed).
  // + 30 calendar days = 2026-06-12 (Fri). Friday — no shift.
  const result = computeAbsoluteDeadline({
    serviceDate: new Date("2026-05-06T00:00:00Z"),
    serviceClockDays: 7,
    serviceClockKind: "calendar",
    statutoryDays: 30,
    statutoryUnit: "calendar_days",
    jurisdiction: "FI",
    holidayShiftPolicy: "next_business_day",
  });
  assertEquals(result.deadlineAt.toISOString().slice(0, 10), "2026-06-12");
  assertFalse(result.holidayShifted);
});

Deno.test("HS-T41 — FI: deadline that lands on Sat shifts to Mon", () => {
  // Service 2026-05-09 (Sat) + 0d clock + 30d = 2026-06-08 (Mon). Adjust:
  // pick service 2026-05-13 (Wed) + 30d = 2026-06-12 (Fri) ← good.
  // We want a case where final lands on weekend: service 2026-05-15 (Fri)
  // + 30d = 2026-06-14 (Sun) → shift to Mon 2026-06-15.
  const result = computeAbsoluteDeadline({
    serviceDate: new Date("2026-05-15T00:00:00Z"),
    serviceClockDays: 0,
    serviceClockKind: "calendar",
    statutoryDays: 30,
    statutoryUnit: "calendar_days",
    jurisdiction: "FI",
    holidayShiftPolicy: "next_business_day",
  });
  assertEquals(result.deadlineAt.toISOString().slice(0, 10), "2026-06-15");
  assert(result.holidayShifted);
  assert(result.holidayShiftNote.includes("Sun") || result.holidayShiftNote.includes("Sat"));
});

Deno.test("HS-T42 — EE HKMS §46: court_decision served 2026-05-06 + HMS §27 5d e-mail + 30d", () => {
  // 2026-05-06 Wed + 5d e-mail clock = 2026-05-11 Mon
  // + 30 calendar days = 2026-06-10 Wed — non-holiday, no shift.
  const result = computeAbsoluteDeadline({
    serviceDate: new Date("2026-05-06T00:00:00Z"),
    serviceClockDays: 5,
    serviceClockKind: "calendar",
    statutoryDays: 30,
    statutoryUnit: "calendar_days",
    jurisdiction: "EE",
    holidayShiftPolicy: "next_business_day",
  });
  assertEquals(result.deadlineAt.toISOString().slice(0, 10), "2026-06-10");
  assertFalse(result.holidayShifted);
});

Deno.test("HS-T43 — ECHR Protocol 15: 4 calendar months from final domestic judgment, no weekend shift", () => {
  // Final judgment 2026-02-08 (Sun) + 4 months = 2026-06-08 (Mon, ordinary
  // working day). The point of this test is the no-shift rule: even if the
  // result landed on Sat we keep it. To test that, use 2026-02-08 Sun + 4mo
  // = 2026-06-08 Mon (no shift needed — also tests addMonths semantics).
  const result = computeAbsoluteDeadline({
    serviceDate: new Date("2026-02-08T00:00:00Z"),
    serviceClockDays: 0,
    serviceClockKind: "calendar",
    statutoryDays: 4,
    statutoryUnit: "calendar_months",
    jurisdiction: "EU",
    holidayShiftPolicy: "strict_calendar",
  });
  assertEquals(result.deadlineAt.toISOString().slice(0, 10), "2026-06-08");
  assertFalse(result.holidayShifted);
});

Deno.test("HS-T44 — ECHR Protocol 15: result on a Sat stays Sat (regression pin)", () => {
  // Pick an anchor where final date lands on Saturday.
  // 2026-04-08 + 4 calendar months = 2026-08-08 (Saturday).
  const result = computeAbsoluteDeadline({
    serviceDate: new Date("2026-04-08T00:00:00Z"),
    serviceClockDays: 0,
    serviceClockKind: "calendar",
    statutoryDays: 4,
    statutoryUnit: "calendar_months",
    jurisdiction: "EU",
    holidayShiftPolicy: "strict_calendar",
  });
  assertEquals(result.deadlineAt.toISOString().slice(0, 10), "2026-08-08");
  assertFalse(result.holidayShifted);
});

Deno.test("HS-T45 — service-clock 'working': HL §59 +3 working days skips weekend AND holiday", () => {
  // Send Wed 2026-05-13. The next working day count must skip:
  //   Thu 05-14 = helatorstai (FI Ascension Day, holiday)
  //   Fri 05-15 = +1
  //   Sat 05-16 = weekend (skip)
  //   Sun 05-17 = weekend (skip)
  //   Mon 05-18 = +2
  //   Tue 05-19 = +3
  // Then +30 calendar days from 2026-05-19 = 2026-06-18 (Thu).
  const result = computeAbsoluteDeadline({
    serviceDate: new Date("2026-05-13T00:00:00Z"),
    serviceClockDays: 3,
    serviceClockKind: "working",
    statutoryDays: 30,
    statutoryUnit: "calendar_days",
    jurisdiction: "FI",
    holidayShiftPolicy: "next_business_day",
  });
  assertEquals(result.deadlineAt.toISOString().slice(0, 10), "2026-06-18");
  assertFalse(result.holidayShifted);
});

// =============================================================================
// 6. Edge cases
// =============================================================================

Deno.test("HS-T50 — null serviceDate raises", () => {
  let threw = false;
  try {
    computeAbsoluteDeadline({
      // deno-lint-ignore no-explicit-any
      serviceDate: null as any,
      serviceClockDays: 0,
      serviceClockKind: "calendar",
      statutoryDays: 30,
      statutoryUnit: "calendar_days",
      jurisdiction: "FI",
      holidayShiftPolicy: "next_business_day",
    });
  } catch {
    threw = true;
  }
  assert(threw, "computeAbsoluteDeadline should reject null serviceDate");
});

Deno.test("HS-T51 — invalid jurisdiction raises", () => {
  let threw = false;
  try {
    computeAbsoluteDeadline({
      serviceDate: new Date("2026-05-06T00:00:00Z"),
      serviceClockDays: 0,
      serviceClockKind: "calendar",
      statutoryDays: 30,
      statutoryUnit: "calendar_days",
      // deno-lint-ignore no-explicit-any
      jurisdiction: "XX" as any,
      holidayShiftPolicy: "next_business_day",
    });
  } catch {
    threw = true;
  }
  assert(threw, "invalid jurisdiction must throw");
});

Deno.test("HS-T52 — addMonths handles month-end correctly (Jan 31 + 1mo = Feb 28/29)", () => {
  // 2026-01-31 + 1 month: 2026 not a leap year, expect 2026-02-28.
  const result = computeAbsoluteDeadline({
    serviceDate: new Date("2026-01-31T00:00:00Z"),
    serviceClockDays: 0,
    serviceClockKind: "calendar",
    statutoryDays: 1,
    statutoryUnit: "calendar_months",
    jurisdiction: "EU",
    holidayShiftPolicy: "strict_calendar",
  });
  assertEquals(result.deadlineAt.toISOString().slice(0, 10), "2026-02-28");
});

// =============================================================================
// 7. Year coverage
// =============================================================================

Deno.test("HS-T60 — holiday list covers current year AND next year (drift guard)", () => {
  // The CI must catch a stale holiday list BEFORE the table goes stale.
  // A static assertion on a fixed year (e.g. 2027) passes forever and never
  // fires when the calendar rolls past the table's coverage — at which point
  // deadlines that land on an uncovered-year holiday silently fail to shift
  // and a user gets a deadline a day or more early. So the guard is
  // year-RELATIVE: it always demands coverage of the current year and the
  // next year. New Year's Day (FI uudenvuodenpäivä / EE uusaasta) and EE
  // iseseisvuspäev (24 Feb) are fixed annual holidays, ideal anchors.
  const thisYear = new Date().getUTCFullYear();
  for (const year of [thisYear, thisYear + 1]) {
    assert(
      isFinnishHoliday(new Date(`${year}-01-01T12:00:00Z`)),
      `FI holiday list must include ${year}-01-01 — table is stale, ` +
        `add ${year} holidays to FI_HOLIDAYS in holidays_fi_ee.ts`,
    );
    assert(
      isEstonianHoliday(new Date(`${year}-02-24T12:00:00Z`)),
      `EE holiday list must include ${year}-02-24 — table is stale, ` +
        `add ${year} holidays to EE_HOLIDAYS in holidays_fi_ee.ts`,
    );
  }
});
