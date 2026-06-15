// Deno tests for renewal-tick pure reminder-window logic.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read \
//     supabase/functions/renewal-tick/__tests__/tick_logic_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  daysUntilExpiry,
  nextDueWindow,
  reminderCopy,
  type RenewableDocRow,
  selectDue,
  windowsToMark,
} from "../tick_logic.ts";

// Fixed "now" at midday so time-of-day never shifts day boundaries.
const NOW = new Date("2026-06-15T12:00:00.000Z");

function doc(overrides: Partial<RenewableDocRow>): RenewableDocRow {
  return {
    id: "11111111-1111-1111-1111-111111111111",
    user_id: "22222222-2222-2222-2222-222222222222",
    doc_type: "residence_permit",
    label: "Estonian residence permit",
    jurisdiction: "EE",
    expires_on: "2026-12-31",
    reminders_sent: [],
    notifications_enabled: true,
    ...overrides,
  };
}

// ── daysUntilExpiry ──────────────────────────────────────────────────────────

Deno.test("daysUntilExpiry: future date", () => {
  // 2026-06-15 -> 2026-06-25 is 10 days.
  assertEquals(daysUntilExpiry("2026-06-25", NOW), 10);
});

Deno.test("daysUntilExpiry: today is zero", () => {
  assertEquals(daysUntilExpiry("2026-06-15", NOW), 0);
});

Deno.test("daysUntilExpiry: past is negative", () => {
  assertEquals(daysUntilExpiry("2026-06-10", NOW), -5);
});

Deno.test("daysUntilExpiry: time-of-day does not shift boundary", () => {
  const earlyMorning = new Date("2026-06-15T00:01:00.000Z");
  const lateNight = new Date("2026-06-15T23:59:00.000Z");
  assertEquals(daysUntilExpiry("2026-06-22", earlyMorning), 7);
  assertEquals(daysUntilExpiry("2026-06-22", lateNight), 7);
});

Deno.test("daysUntilExpiry: malformed date -> NaN", () => {
  assert(Number.isNaN(daysUntilExpiry("not-a-date", NOW)));
  assert(Number.isNaN(daysUntilExpiry("2026-02-31", NOW))); // overflow rejected
});

// ── nextDueWindow ────────────────────────────────────────────────────────────

Deno.test("90-day window fires at exactly 90 days out", () => {
  // 2026-06-15 + 90 days = 2026-09-13.
  assertEquals(nextDueWindow(doc({ expires_on: "2026-09-13" }), NOW), 90);
});

Deno.test("91 days out -> nothing due yet", () => {
  assertEquals(nextDueWindow(doc({ expires_on: "2026-09-14" }), NOW), null);
});

Deno.test("30-day window fires when inside 30 but 90 already sent", () => {
  const r = doc({ expires_on: "2026-07-10", reminders_sent: ["90"] }); // 25 days
  assertEquals(nextDueWindow(r, NOW), 30);
});

Deno.test("7-day window fires when inside 7 and 90/30 already sent", () => {
  const r = doc({
    expires_on: "2026-06-20",
    reminders_sent: ["90", "30"],
  }); // 5 days
  assertEquals(nextDueWindow(r, NOW), 7);
});

Deno.test("late add inside 7 days -> fires the MOST URGENT window (7)", () => {
  // Added with all windows already reached; we send 7, not 90.
  const r = doc({ expires_on: "2026-06-20" }); // 5 days, nothing sent
  assertEquals(nextDueWindow(r, NOW), 7);
});

Deno.test("already-expired doc never reminded -> fires 7 once", () => {
  const r = doc({ expires_on: "2026-06-01" }); // -14 days
  assertEquals(nextDueWindow(r, NOW), 7);
});

Deno.test("all windows sent -> nothing due", () => {
  const r = doc({
    expires_on: "2026-06-20",
    reminders_sent: ["90", "30", "7"],
  });
  assertEquals(nextDueWindow(r, NOW), null);
});

Deno.test("notifications disabled -> never due", () => {
  const r = doc({ expires_on: "2026-06-20", notifications_enabled: false });
  assertEquals(nextDueWindow(r, NOW), null);
});

Deno.test("malformed expiry -> never due", () => {
  assertEquals(nextDueWindow(doc({ expires_on: "garbage" }), NOW), null);
});

// ── windowsToMark ────────────────────────────────────────────────────────────

Deno.test("marking 90 when only 90 reached marks just 90", () => {
  const r = doc({ expires_on: "2026-09-13" }); // 90 days
  assertEquals(windowsToMark(r, 90, NOW).sort(), ["90"]);
});

Deno.test("firing 7 on a late-add marks all reached looser windows too", () => {
  // 5 days out, nothing sent: 90/30/7 all reached. Fire 7, mark all so a
  // future tick never sends a pointless 90-day notice.
  const r = doc({ expires_on: "2026-06-20" });
  assertEquals(windowsToMark(r, 7, NOW).sort(), ["30", "7", "90"]);
});

Deno.test("firing 30 keeps an already-present 90 and adds 30", () => {
  const r = doc({ expires_on: "2026-07-10", reminders_sent: ["90"] }); // 25 days
  assertEquals(windowsToMark(r, 30, NOW).sort(), ["30", "90"]);
});

// ── selectDue ────────────────────────────────────────────────────────────────

Deno.test("selectDue filters a mixed batch", () => {
  const rows: RenewableDocRow[] = [
    doc({ id: "a", expires_on: "2026-09-13" }), // 90d -> due (90)
    doc({ id: "b", expires_on: "2026-09-14" }), // 91d -> not due
    doc({ id: "c", expires_on: "2026-06-20" }), // 5d -> due (7)
    doc({
      id: "d",
      expires_on: "2026-06-20",
      reminders_sent: ["90", "30", "7"],
    }), // done
    doc({ id: "e", expires_on: "2026-06-20", notifications_enabled: false }), // muted
  ];
  const out = selectDue(rows, NOW);
  assertEquals(out.map((o) => `${o.row.id}:${o.window}`).sort(), [
    "a:90",
    "c:7",
  ]);
});

// ── reminderCopy ─────────────────────────────────────────────────────────────

Deno.test("reminderCopy: future window", () => {
  const { title, body } = reminderCopy(
    doc({ expires_on: "2026-09-13" }),
    90,
    NOW
  );
  assertEquals(title, "Document renewal reminder");
  assert(body.includes("expires in 90 days"));
  assert(body.includes("Estonian residence permit"));
});

Deno.test("reminderCopy: expires today / tomorrow", () => {
  assert(
    reminderCopy(doc({ expires_on: "2026-06-15" }), 7, NOW).body.includes(
      "expires today"
    )
  );
  assert(
    reminderCopy(doc({ expires_on: "2026-06-16" }), 7, NOW).body.includes(
      "expires tomorrow"
    )
  );
});

Deno.test("reminderCopy: overdue copy", () => {
  const { body } = reminderCopy(doc({ expires_on: "2026-06-01" }), 7, NOW);
  assert(body.includes("has expired"));
});

// ── End-to-end watermark progression (the anti-double-notify invariant) ──────

Deno.test(
  "a document progresses 90 -> 30 -> 7 across ticks, never twice",
  () => {
    let r = doc({ expires_on: "2026-09-13", reminders_sent: [] }); // 90 days out
    // Tick at 90 days.
    let w = nextDueWindow(r, NOW);
    assertEquals(w, 90);
    r = { ...r, reminders_sent: windowsToMark(r, w!, NOW) };
    // Same day, second tick: nothing more due.
    assertEquals(nextDueWindow(r, NOW), null);

    // 60 days later we are 30 days out.
    const t30 = new Date("2026-08-14T12:00:00.000Z");
    w = nextDueWindow(r, t30);
    assertEquals(w, 30);
    r = { ...r, reminders_sent: windowsToMark(r, w!, t30) };
    assertEquals(nextDueWindow(r, t30), null);

    // 23 days later we are 7 days out.
    const t7 = new Date("2026-09-06T12:00:00.000Z");
    w = nextDueWindow(r, t7);
    assertEquals(w, 7);
    r = { ...r, reminders_sent: windowsToMark(r, w!, t7) };
    assertEquals(nextDueWindow(r, t7), null);

    // Nothing ever fires after all three.
    assertEquals(nextDueWindow(r, new Date("2026-09-12T12:00:00.000Z")), null);
  }
);
