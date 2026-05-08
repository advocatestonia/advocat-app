// deadline_alert_test.ts — unit tests for buildDeadlineAlertBlock
// Run with: deno test supabase/functions/_shared/__tests__/deadline_alert_test.ts

import {
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.177.0/testing/asserts.ts";
import { buildDeadlineAlertBlock } from "../../claude-proxy/active_case_injection.ts";
import type { ActiveCaseRow } from "../../claude-proxy/active_case_injection.ts";

// Minimal ActiveCaseRow factory — only key_dates matters for these tests.
function makeRow(
  key_dates: unknown,
): ActiveCaseRow {
  return {
    id: "00000000-0000-0000-0000-000000000001",
    user_id: "00000000-0000-0000-0000-000000000002",
    title: "Test Case",
    jurisdiction: "FI",
    status: "active",
    case_numbers: [],
    parties: [],
    key_dates,
    authorities: [],
    timeline: [],
    open_questions: [],
    next_actions: [],
  };
}

// ---------------------------------------------------------------------------
// 1. Returns empty string when no deadlines within 14 days
// ---------------------------------------------------------------------------
Deno.test("buildDeadlineAlertBlock — returns empty string when no deadlines within 14 days", () => {
  const today = new Date("2026-05-08");
  const row = makeRow([
    // 30 days in the future — outside the 14-day window
    { date: "2026-06-07", event: "Court hearing" },
    // Already past
    { date: "2026-04-01", event: "Filing deadline" },
  ]);
  const result = buildDeadlineAlertBlock(row, today);
  assertEquals(result, "");
});

// ---------------------------------------------------------------------------
// 2. Returns alert for deadline in 3 days
// ---------------------------------------------------------------------------
Deno.test("buildDeadlineAlertBlock — returns alert block for deadline in 3 days", () => {
  const today = new Date("2026-05-08");
  const row = makeRow([
    { date: "2026-05-11", event: "Submit evidence bundle" },
  ]);
  const result = buildDeadlineAlertBlock(row, today);
  assertStringIncludes(result, "⚠️ DEADLINE ALERT");
  assertStringIncludes(result, "Submit evidence bundle");
  assertStringIncludes(result, "2026-05-11");
  assertStringIncludes(result, "3 days");
  assertStringIncludes(result, "Start your response by acknowledging");
});

// ---------------------------------------------------------------------------
// 3. Sorts by urgency — soonest deadline appears first
// ---------------------------------------------------------------------------
Deno.test("buildDeadlineAlertBlock — sorts by urgency, soonest first", () => {
  const today = new Date("2026-05-08");
  const row = makeRow([
    { date: "2026-05-18", event: "Late deadline" },       // 10 days
    { date: "2026-05-09", event: "Urgent deadline" },     // 1 day (TOMORROW)
    { date: "2026-05-13", event: "Medium deadline" },     // 5 days
  ]);
  const result = buildDeadlineAlertBlock(row, today);
  // All three should appear
  assertStringIncludes(result, "Urgent deadline");
  assertStringIncludes(result, "Medium deadline");
  assertStringIncludes(result, "Late deadline");
  // Soonest must precede later ones in the output
  const urgentPos = result.indexOf("Urgent deadline");
  const mediumPos = result.indexOf("Medium deadline");
  const latePos = result.indexOf("Late deadline");
  assertEquals(urgentPos < mediumPos, true, "Urgent should come before Medium");
  assertEquals(mediumPos < latePos, true, "Medium should come before Late");
  // TOMORROW label on the 1-day deadline
  assertStringIncludes(result, "TOMORROW");
});

// ---------------------------------------------------------------------------
// Bonus: TODAY label when deadline is today
// ---------------------------------------------------------------------------
Deno.test("buildDeadlineAlertBlock — labels deadline today as TODAY", () => {
  const today = new Date("2026-05-08");
  const row = makeRow([
    { date: "2026-05-08", event: "Appeal deadline" },
  ]);
  const result = buildDeadlineAlertBlock(row, today);
  assertStringIncludes(result, "TODAY");
  assertStringIncludes(result, "Appeal deadline");
});

// ---------------------------------------------------------------------------
// Bonus: ignores entries with missing date/event fields
// ---------------------------------------------------------------------------
Deno.test("buildDeadlineAlertBlock — ignores malformed entries", () => {
  const today = new Date("2026-05-08");
  const row = makeRow([
    { date: "", event: "No date" },
    { date: "2026-05-10", event: "" },
    { date: "not-a-date", event: "Bad date" },
    { date: "2026-05-10", event: "Valid entry" },
  ]);
  const result = buildDeadlineAlertBlock(row, today);
  assertStringIncludes(result, "Valid entry");
  assertEquals(result.includes("No date"), false);
  assertEquals(result.includes("Bad date"), false);
});
