// Deno tests for deadline-radar-eu calendar-correct date arithmetic.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-all \
//     supabase/functions/deadline-radar-eu/__tests__/iso_duration_test.ts
//
// Why this exists
// ---------------
// The radar previously flattened ISO durations to days (months=30, years=365)
// before adding them to the start date. For statutory filing deadlines a
// monthly/annual period must use CALENDAR-correct arithmetic, otherwise the
// computed due_date drifts by 1-3 days — enough to mis-state a real deadline.
// These tests pin the corrected addIsoDuration / parseIsoDuration helpers.
// -----------------------------------------------------------------------------

import {
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { addIsoDuration, parseIsoDuration } from "../index.ts";

function iso(d: Date): string {
  return d.toISOString().slice(0, 10);
}

Deno.test("DRE-T01 — parseIsoDuration splits Y/M/D without flattening", () => {
  assertEquals(parseIsoDuration("P1Y"), { years: 1, months: 0, days: 0 });
  assertEquals(parseIsoDuration("P3M"), { years: 0, months: 3, days: 0 });
  assertEquals(parseIsoDuration("P30D"), { years: 0, months: 0, days: 30 });
  assertEquals(parseIsoDuration("P1Y2M10D"), {
    years: 1,
    months: 2,
    days: 10,
  });
});

Deno.test("DRE-T02 — parseIsoDuration rejects empty / malformed", () => {
  assertEquals(parseIsoDuration(""), null);
  assertEquals(parseIsoDuration("P0D"), null);
  assertEquals(parseIsoDuration("garbage"), null);
  assertEquals(parseIsoDuration("P1W"), null); // weeks not supported
});

Deno.test("DRE-T03 — 1 month from Jan 15 lands Feb 15 (not Jan 15 + 30d)", () => {
  const start = new Date("2026-01-15T00:00:00Z");
  const due = addIsoDuration(start, { years: 0, months: 1, days: 0 });
  assertEquals(iso(due), "2026-02-15");
  // The 30-day approximation would have given 2026-02-14.
});

Deno.test("DRE-T04 — 1 month from Jan 31 clamps to Feb 28 (non-leap)", () => {
  const start = new Date("2026-01-31T00:00:00Z");
  const due = addIsoDuration(start, { years: 0, months: 1, days: 0 });
  assertEquals(iso(due), "2026-02-28");
});

Deno.test("DRE-T05 — 1 month from Jan 31 clamps to Feb 29 (leap year)", () => {
  const start = new Date("2024-01-31T00:00:00Z");
  const due = addIsoDuration(start, { years: 0, months: 1, days: 0 });
  assertEquals(iso(due), "2024-02-29");
});

Deno.test("DRE-T06 — 3 months crossing year boundary", () => {
  const start = new Date("2025-11-30T00:00:00Z");
  const due = addIsoDuration(start, { years: 0, months: 3, days: 0 });
  // Nov 30 + 3 months = Feb 30 → clamped to Feb 28 (2026 non-leap).
  assertEquals(iso(due), "2026-02-28");
});

Deno.test("DRE-T07 — 1 year is calendar-correct across a leap Feb 29", () => {
  const start = new Date("2024-02-29T00:00:00Z");
  const due = addIsoDuration(start, { years: 1, months: 0, days: 0 });
  // Feb 29 2024 + 1 year → Feb 29 2025 does not exist → clamp to Feb 28.
  assertEquals(iso(due), "2025-02-28");
});

Deno.test("DRE-T08 — plain days are exact", () => {
  const start = new Date("2026-01-01T00:00:00Z");
  const due = addIsoDuration(start, { years: 0, months: 0, days: 30 });
  assertEquals(iso(due), "2026-01-31");
});

Deno.test("DRE-T09 — combined Y+M+D applies in order, calendar-correct", () => {
  const start = new Date("2026-01-31T00:00:00Z");
  // +1 month → Feb 28, +0 years, +5 days → Mar 5.
  const due = addIsoDuration(start, { years: 0, months: 1, days: 5 });
  assertEquals(iso(due), "2026-03-05");
});
