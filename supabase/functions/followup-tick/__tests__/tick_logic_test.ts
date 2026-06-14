// Deno tests for followup-tick pure selection logic.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read \
//     supabase/functions/followup-tick/__tests__/tick_logic_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  type FollowupRow,
  isDueForReminder,
  reminderBody,
  REMINDER_LEAD_MS,
  selectDueRows,
} from "../tick_logic.ts";

const NOW = new Date("2026-06-14T12:00:00.000Z");

function row(overrides: Partial<FollowupRow>): FollowupRow {
  return {
    id: "11111111-1111-1111-1111-111111111111",
    user_id: "22222222-2222-2222-2222-222222222222",
    case_id: "33333333-3333-3333-3333-333333333333",
    title: "Send records request",
    due_at: null,
    status: "open",
    reminded_at: null,
    ...overrides,
  };
}

// ── isDueForReminder ────────────────────────────────────────────────────────

Deno.test("due tomorrow -> nudge", () => {
  const r = row({ due_at: "2026-06-15T10:00:00.000Z" });
  assert(isDueForReminder(r, NOW));
});

Deno.test("overdue -> still nudge once", () => {
  const r = row({ due_at: "2026-06-10T10:00:00.000Z" });
  assert(isDueForReminder(r, NOW));
});

Deno.test("far future (3 days out) -> no nudge yet", () => {
  const r = row({ due_at: "2026-06-17T12:00:01.000Z" });
  assertFalse(isDueForReminder(r, NOW));
});

Deno.test("exactly at the horizon -> nudge (inclusive)", () => {
  const horizon = new Date(NOW.getTime() + REMINDER_LEAD_MS).toISOString();
  const r = row({ due_at: horizon });
  assert(isDueForReminder(r, NOW));
});

Deno.test("already reminded -> never nudge again", () => {
  const r = row({
    due_at: "2026-06-15T10:00:00.000Z",
    reminded_at: "2026-06-14T11:00:00.000Z",
  });
  assertFalse(isDueForReminder(r, NOW));
});

Deno.test("non-open status -> no nudge", () => {
  for (const status of ["done", "snoozed", "dismissed"]) {
    const r = row({ due_at: "2026-06-15T10:00:00.000Z", status });
    assertFalse(isDueForReminder(r, NOW));
  }
});

Deno.test("no due_at (someday task) -> no nudge", () => {
  assertFalse(isDueForReminder(row({ due_at: null }), NOW));
});

Deno.test("invalid due_at -> no nudge (defensive)", () => {
  assertFalse(isDueForReminder(row({ due_at: "not-a-date" }), NOW));
});

// ── selectDueRows ───────────────────────────────────────────────────────────

Deno.test("selectDueRows filters a mixed batch", () => {
  const rows: FollowupRow[] = [
    row({ id: "a", due_at: "2026-06-15T10:00:00.000Z" }), // due tomorrow -> in
    row({ id: "b", due_at: "2026-06-30T10:00:00.000Z" }), // far future -> out
    row({ id: "c", due_at: null }), // someday -> out
    row({ id: "d", due_at: "2026-06-10T10:00:00.000Z" }), // overdue -> in
    row({ id: "e", due_at: "2026-06-15T10:00:00.000Z", reminded_at: "x" }), // out
  ];
  const out = selectDueRows(rows, NOW).map((r) => r.id);
  assertEquals(out.sort(), ["a", "d"]);
});

// ── reminderBody ────────────────────────────────────────────────────────────

Deno.test("reminderBody: overdue copy", () => {
  assertEquals(
    reminderBody(row({ due_at: "2026-06-10T10:00:00.000Z" }), NOW),
    "A follow-up step is overdue."
  );
});

Deno.test("reminderBody: due-tomorrow copy", () => {
  assertEquals(
    reminderBody(row({ due_at: "2026-06-15T10:00:00.000Z" }), NOW),
    "A follow-up step is due tomorrow."
  );
});

Deno.test("reminderBody: upcoming copy", () => {
  assertEquals(
    reminderBody(row({ due_at: "2026-06-20T10:00:00.000Z" }), NOW),
    "You have a follow-up step coming up."
  );
});

Deno.test("reminderBody: no due_at fallback", () => {
  assertEquals(
    reminderBody(row({ due_at: null }), NOW),
    "You have a follow-up step to complete."
  );
});
