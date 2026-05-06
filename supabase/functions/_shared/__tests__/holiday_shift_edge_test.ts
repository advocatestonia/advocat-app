// holiday_shift_edge_test.ts — Phase 2 Pkg 9 deadline radar regression pins.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read --allow-env --allow-net \
//     supabase/functions/_shared/__tests__/holiday_shift_edge_test.ts
//
// Companion to holiday_shift_test.ts (HS-T01..HS-T60). The neighbour file
// covers the happy path; this one drills in on the gnarly cases the architect
// pinned in §3 + §10:
//
//   * FI Jouluaatto on a Friday → next working day is Monday (or whichever
//     post-Christmas weekday is non-holiday).
//   * EE Võidupüha 23.6 + Jaanipäev 24.6 consecutive → shift skips both.
//   * ECHR 4mo + result on a Sunday → no shift (strict_calendar).
//   * Sat + Sun + Monday-holiday triple → shift to Tuesday.
//   * Year-boundary: deadline computed 2025-12-31 + 30d → 2026-01-30 with
//     correct 2026 holidays applied (catches a year-rollover regression).
//   * addMonths leap-year semantics around 2027-02 (next year, not 2026).
//
// Naming convention: HS-T100..HS-T199 to leave breathing room above the
// upstream HS-T60.
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  computeAbsoluteDeadline,
  isEstonianHoliday,
  isFinnishHoliday,
  isWeekend,
  shiftDeadline,
} from "../holiday_shift.ts";

// =============================================================================
// 1. FI Jouluaatto cluster (24.12) on Friday-Sat-Sun-Mon-Tue-Wed (typical year)
// =============================================================================

Deno.test(
  "HS-T100 — FI: 2026 Jouluaatto Thu 24.12 + Joulupäivä Fri 25.12 + Tapaninpäivä Sat 26.12 cluster",
  () => {
    // 2026-12-24 = Thursday (Jouluaatto, FI holiday)
    // 2026-12-25 = Friday   (Joulupäivä, FI holiday)
    // 2026-12-26 = Saturday (Tapaninpäivä, FI holiday + weekend)
    // 2026-12-27 = Sunday
    // 2026-12-28 = Monday — first working day after the cluster.
    //
    // A deadline that lands on Jouluaatto Thu must shift forward over
    // the entire weekend cluster.
    assert(isFinnishHoliday(new Date("2026-12-24T12:00:00Z")));
    assert(isFinnishHoliday(new Date("2026-12-25T12:00:00Z")));
    assert(isFinnishHoliday(new Date("2026-12-26T12:00:00Z")));

    const result = shiftDeadline(new Date("2026-12-24T12:00:00Z"), {
      jurisdiction: "FI",
      policy: "next_business_day",
    });
    assertEquals(
      result.shiftedAt.toISOString().slice(0, 10),
      "2026-12-28",
      "Jouluaatto Thu must shift through the FI Christmas cluster to Monday",
    );
    assert(result.shifted);
    assert(result.note.includes("Thu"));
    assert(result.note.includes("Mon"));
  },
);

Deno.test(
  "HS-T101 — FI: deadline on Pyhäinpäivä Sat 31.10.2026 + Sunday → Monday",
  () => {
    // 2026-10-31 = Saturday (Pyhäinpäivä, FI holiday)
    // 2026-11-01 = Sunday
    // 2026-11-02 = Monday — next working day.
    assert(isFinnishHoliday(new Date("2026-10-31T12:00:00Z")));
    const result = shiftDeadline(new Date("2026-10-31T12:00:00Z"), {
      jurisdiction: "FI",
      policy: "next_business_day",
    });
    assertEquals(result.shiftedAt.toISOString().slice(0, 10), "2026-11-02");
    assert(result.shifted);
  },
);

// =============================================================================
// 2. EE Võidupüha (23.6) + Jaanipäev (24.6) consecutive holiday pair
// =============================================================================

Deno.test(
  "HS-T110 — EE: deadline on Mon 22.6.2026 → Tue=Võidupüha → Wed=Jaanipäev → Thu next working",
  () => {
    // 2026-06-22 = Monday (working day)
    // 2026-06-23 = Tuesday (Võidupüha, EE holiday)
    // 2026-06-24 = Wednesday (Jaanipäev, EE holiday)
    // 2026-06-25 = Thursday (working)
    //
    // A deadline that lands on Mon 22.6 stays on Mon (no shift).
    const result = shiftDeadline(new Date("2026-06-22T12:00:00Z"), {
      jurisdiction: "EE",
      policy: "next_business_day",
    });
    assertEquals(result.shiftedAt.toISOString().slice(0, 10), "2026-06-22");
    assertFalse(result.shifted);
  },
);

Deno.test(
  "HS-T111 — EE: deadline on Tue Võidupüha shifts past Jaanipäev to Thu",
  () => {
    // Tue 23.6 (Võidupüha) → Wed 24.6 (Jaanipäev) → Thu 25.6 (working).
    assert(isEstonianHoliday(new Date("2026-06-23T12:00:00Z")));
    assert(isEstonianHoliday(new Date("2026-06-24T12:00:00Z")));
    const result = shiftDeadline(new Date("2026-06-23T12:00:00Z"), {
      jurisdiction: "EE",
      policy: "next_business_day",
    });
    assertEquals(result.shiftedAt.toISOString().slice(0, 10), "2026-06-25");
    assert(result.shifted);
  },
);

Deno.test(
  "HS-T112 — EE: deadline on Sat 20.6.2026 shifts past Sun + Mon-(working) … wait, Mon IS working. So Sat → Mon 22.6.",
  () => {
    // 2026-06-20 = Saturday (no holiday).
    // 2026-06-21 = Sunday.
    // 2026-06-22 = Monday (working — Võidupüha is Tue 23.6).
    const result = shiftDeadline(new Date("2026-06-20T12:00:00Z"), {
      jurisdiction: "EE",
      policy: "next_business_day",
    });
    assertEquals(result.shiftedAt.toISOString().slice(0, 10), "2026-06-22");
    assert(result.shifted);
  },
);

// =============================================================================
// 3. ECHR Protocol 15 strict_calendar regression pins
// =============================================================================

Deno.test(
  "HS-T120 — ECHR: 4 months from 2026-02-15 lands on Mon 2026-06-15 (no shift even if year-end variant lands on Sun)",
  () => {
    // Architect §10 #3 verbatim: 4 months from 2026-02-15 → 2026-06-15.
    // (NB: 2026-06-15 is in fact a Monday, so this also doubles as a
    // sanity check on addMonths semantics.)
    const result = computeAbsoluteDeadline({
      serviceDate: new Date("2026-02-15T00:00:00Z"),
      serviceClockDays: 0,
      serviceClockKind: "calendar",
      statutoryDays: 4,
      statutoryUnit: "calendar_months",
      jurisdiction: "EU",
      holidayShiftPolicy: "strict_calendar",
    });
    assertEquals(result.deadlineAt.toISOString().slice(0, 10), "2026-06-15");
    assertFalse(result.holidayShifted);
  },
);

Deno.test(
  "HS-T121 — ECHR: result lands on Sunday → stays Sunday (strict_calendar invariant)",
  () => {
    // 2026-02-08 (Sun) + 4 calendar months = 2026-06-08 (Mon). To force
    // the Sun-stays-Sun invariant we use 2026-02-14 (Sat) + 4mo =
    // 2026-06-14 (Sun).
    const result = computeAbsoluteDeadline({
      serviceDate: new Date("2026-02-14T00:00:00Z"),
      serviceClockDays: 0,
      serviceClockKind: "calendar",
      statutoryDays: 4,
      statutoryUnit: "calendar_months",
      jurisdiction: "EU",
      holidayShiftPolicy: "strict_calendar",
    });
    // Confirm result is a Sunday.
    assert(isWeekend(result.deadlineAt));
    assertEquals(result.deadlineAt.toISOString().slice(0, 10), "2026-06-14");
    assertFalse(result.holidayShifted);
  },
);

Deno.test(
  "HS-T122 — ECHR: result lands on FI New Year's Day (holiday) → stays anyway",
  () => {
    // 2026-09-01 + 4 months = 2027-01-01 (FI public holiday + Friday).
    // Strict calendar: deadline stays.
    const result = computeAbsoluteDeadline({
      serviceDate: new Date("2026-09-01T00:00:00Z"),
      serviceClockDays: 0,
      serviceClockKind: "calendar",
      statutoryDays: 4,
      statutoryUnit: "calendar_months",
      jurisdiction: "EU",
      holidayShiftPolicy: "strict_calendar",
    });
    assertEquals(result.deadlineAt.toISOString().slice(0, 10), "2027-01-01");
    assertFalse(result.holidayShifted);
  },
);

// =============================================================================
// 4. Triple-day weekend + Monday-holiday cluster
// =============================================================================

Deno.test(
  "HS-T130 — FI: Sat + Sun + Mon-holiday triple → shift to Tuesday",
  () => {
    // Pick a Monday that's a FI holiday: 2026-04-06 = 2. pääsiäispäivä
    // (Easter Monday). The cluster is:
    //   Sat 2026-04-04
    //   Sun 2026-04-05 (Pääsiäispäivä = Easter Sunday holiday too)
    //   Mon 2026-04-06 (2. pääsiäispäivä = Easter Monday holiday)
    //   Tue 2026-04-07 (working)
    //
    // Deadline hitting Sat 2026-04-04 must walk Sun→Mon→Tue.
    assert(isFinnishHoliday(new Date("2026-04-05T12:00:00Z")));
    assert(isFinnishHoliday(new Date("2026-04-06T12:00:00Z")));
    const result = shiftDeadline(new Date("2026-04-04T12:00:00Z"), {
      jurisdiction: "FI",
      policy: "next_business_day",
    });
    assertEquals(result.shiftedAt.toISOString().slice(0, 10), "2026-04-07");
    assert(result.shifted);
  },
);

Deno.test(
  "HS-T131 — EE: Sat + Sun + Mon (working) → shift Sat → Mon",
  () => {
    // 2026-08-22 = Saturday (no EE holiday)
    // 2026-08-23 = Sunday
    // 2026-08-24 = Monday (working — Taasiseseisvumispäev was 20.8 Thu)
    const result = shiftDeadline(new Date("2026-08-22T12:00:00Z"), {
      jurisdiction: "EE",
      policy: "next_business_day",
    });
    assertEquals(result.shiftedAt.toISOString().slice(0, 10), "2026-08-24");
    assert(result.shifted);
  },
);

// =============================================================================
// 5. Year-boundary regression: 2026-01 edge applies 2026 holidays not 2025
// =============================================================================

Deno.test(
  "HS-T140 — year-boundary: deadline computed late-2025 + 30d crosses into 2026 with FI 2026 holidays applied",
  () => {
    // We don't have 2025 holidays in the table — but the test models the
    // case where a service date in late 2025 produces a deadline in
    // early 2026. The shift step must look up 2026 holidays.
    //
    // Service 2025-12-30 + 0d clock + 30 calendar days = 2026-01-29 (Thu,
    // working day in FI). No shift expected.
    const r1 = computeAbsoluteDeadline({
      serviceDate: new Date("2025-12-30T00:00:00Z"),
      serviceClockDays: 0,
      serviceClockKind: "calendar",
      statutoryDays: 30,
      statutoryUnit: "calendar_days",
      jurisdiction: "FI",
      holidayShiftPolicy: "next_business_day",
    });
    assertEquals(r1.deadlineAt.toISOString().slice(0, 10), "2026-01-29");
    assertFalse(r1.holidayShifted);

    // And: service 2025-12-07 + 30d = 2026-01-06 (Tue) — FI loppiainen
    // (Epiphany). Must shift forward to Wed 2026-01-07.
    const r2 = computeAbsoluteDeadline({
      serviceDate: new Date("2025-12-07T00:00:00Z"),
      serviceClockDays: 0,
      serviceClockKind: "calendar",
      statutoryDays: 30,
      statutoryUnit: "calendar_days",
      jurisdiction: "FI",
      holidayShiftPolicy: "next_business_day",
    });
    assertEquals(r2.deadlineAt.toISOString().slice(0, 10), "2026-01-07");
    assert(r2.holidayShifted);
  },
);

Deno.test(
  "HS-T141 — year-boundary: 2026 → 2027 rollover uses 2027 holidays (loppiainen shift)",
  () => {
    // Service 2026-12-07 (Mon) + 30 calendar days = 2027-01-06 (Wed)
    // which is FI loppiainen (Epiphany, public holiday). The shift step
    // MUST recognize this 2027 holiday — otherwise we silently fail at
    // year-rollover. Result: shift forward to Thu 2027-01-07.
    const r = computeAbsoluteDeadline({
      serviceDate: new Date("2026-12-07T00:00:00Z"),
      serviceClockDays: 0,
      serviceClockKind: "calendar",
      statutoryDays: 30,
      statutoryUnit: "calendar_days",
      jurisdiction: "FI",
      holidayShiftPolicy: "next_business_day",
    });
    assertEquals(r.deadlineAt.toISOString().slice(0, 10), "2027-01-07");
    assert(
      r.holidayShifted,
      "2027-01-06 loppiainen MUST shift forward; if this fails the 2027 "
        + "holiday list isn't loaded",
    );
    assert(r.holidayShiftNote.includes("Wed 2027-01-06"));
    assert(r.holidayShiftNote.includes("Thu 2027-01-07"));
  },
);

// =============================================================================
// 6. addMonths semantics across year boundaries
// =============================================================================

Deno.test(
  "HS-T150 — addMonths: ECHR 4mo from 2026-10-31 = 2027-02-28 (clamps to last day)",
  () => {
    // 2026-10-31 + 4 months: target month = Feb 2027 (28 days).
    // Day 31 clamps to 28.
    const r = computeAbsoluteDeadline({
      serviceDate: new Date("2026-10-31T00:00:00Z"),
      serviceClockDays: 0,
      serviceClockKind: "calendar",
      statutoryDays: 4,
      statutoryUnit: "calendar_months",
      jurisdiction: "EU",
      holidayShiftPolicy: "strict_calendar",
    });
    assertEquals(r.deadlineAt.toISOString().slice(0, 10), "2027-02-28");
  },
);

Deno.test(
  "HS-T151 — addMonths: ECHR 4mo from 2026-08-29 = 2026-12-29 (no clamp needed)",
  () => {
    const r = computeAbsoluteDeadline({
      serviceDate: new Date("2026-08-29T00:00:00Z"),
      serviceClockDays: 0,
      serviceClockKind: "calendar",
      statutoryDays: 4,
      statutoryUnit: "calendar_months",
      jurisdiction: "EU",
      holidayShiftPolicy: "strict_calendar",
    });
    assertEquals(r.deadlineAt.toISOString().slice(0, 10), "2026-12-29");
  },
);

// =============================================================================
// 7. Service-clock + statutory composition edge cases
// =============================================================================

Deno.test(
  "HS-T160 — FI HL §60 turvaviesti 7d clock that lands on a holiday is itself NOT shifted before the +30d",
  () => {
    // The architect spec applies service-clock first, THEN statutory
    // window, THEN one final shift. The intermediate after-service date
    // is NOT individually shifted (that would compound shifts and risk
    // double-counting weekends).
    //
    // Service 2025-12-30 (Tue) + 7d turvaviesti = 2026-01-06 (Tue, FI
    // loppiainen — but we don't shift here). + 30d calendar = 2026-02-05
    // (Thu, working). Final shift step: not needed.
    //
    // Note: this is testing the implementation matches the spec, not
    // that the spec is right. If the spec changes to "shift after every
    // step" this test would fail and force a deliberate update.
    const r = computeAbsoluteDeadline({
      serviceDate: new Date("2025-12-30T00:00:00Z"),
      serviceClockDays: 7,
      serviceClockKind: "calendar",
      statutoryDays: 30,
      statutoryUnit: "calendar_days",
      jurisdiction: "FI",
      holidayShiftPolicy: "next_business_day",
    });
    assertEquals(r.deadlineAt.toISOString().slice(0, 10), "2026-02-05");
    assertFalse(r.holidayShifted);
  },
);

Deno.test(
  "HS-T161 — FI HL §59 working-days clock skips Easter cluster within the +3wd",
  () => {
    // Send Wed 2026-04-01. Working-day clock +3:
    //   Thu 04-02 = +1 (working)
    //   Fri 04-03 = pitkäperjantai (FI holiday, skipped)
    //   Sat 04-04 = weekend (skipped)
    //   Sun 04-05 = pääsiäispäivä (holiday + weekend, skipped)
    //   Mon 04-06 = 2. pääsiäispäivä (holiday, skipped)
    //   Tue 04-07 = +2 (working)
    //   Wed 04-08 = +3 (working)
    // After-service = Wed 2026-04-08. + 30 calendar days = Fri 2026-05-08
    // (working — vappu was 1.5 Fri, helatorstai is 14.5 Thu).
    const r = computeAbsoluteDeadline({
      serviceDate: new Date("2026-04-01T00:00:00Z"),
      serviceClockDays: 3,
      serviceClockKind: "working",
      statutoryDays: 30,
      statutoryUnit: "calendar_days",
      jurisdiction: "FI",
      holidayShiftPolicy: "next_business_day",
    });
    assertEquals(r.deadlineAt.toISOString().slice(0, 10), "2026-05-08");
    assertFalse(r.holidayShifted);
  },
);

// =============================================================================
// 8. Weekend-only jurisdictions (EU shift = no holiday lookup)
// =============================================================================

Deno.test(
  "HS-T170 — EU jurisdiction with next_business_day still shifts off weekends (defensive)",
  () => {
    // EU is normally only used with strict_calendar for ECHR. But if a
    // hypothetical future anchor uses EU + next_business_day, weekends
    // must still be skipped (FI/EE holidays don't apply for EU).
    const r = shiftDeadline(new Date("2026-08-08T12:00:00Z"), {
      jurisdiction: "EU",
      policy: "next_business_day",
    });
    assertEquals(r.shiftedAt.toISOString().slice(0, 10), "2026-08-10");
    assert(r.shifted);
  },
);

// =============================================================================
// 9. Note formatting regression
// =============================================================================

Deno.test(
  "HS-T180 — shift note format: 'moved from <Day> <yyyy-mm-dd> → <Day> <yyyy-mm-dd>'",
  () => {
    const r = shiftDeadline(new Date("2026-08-08T12:00:00Z"), {
      jurisdiction: "FI",
      policy: "next_business_day",
    });
    // Format must be exactly "moved from <Day> <yyyy-mm-dd> → <Day>
    // <yyyy-mm-dd>". The UI tooltip pins this format; rewording requires
    // a coordinated translation update.
    assert(r.note.startsWith("moved from "));
    assert(r.note.includes(" → "));
    assert(r.note.includes("Sat 2026-08-08"));
    assert(r.note.includes("Mon 2026-08-10"));
  },
);

Deno.test(
  "HS-T181 — strict_calendar shift produces empty note (never shifted)",
  () => {
    const r = shiftDeadline(new Date("2026-08-08T12:00:00Z"), {
      jurisdiction: "EU",
      policy: "strict_calendar",
    });
    assertEquals(r.note, "");
    assertFalse(r.shifted);
  },
);
