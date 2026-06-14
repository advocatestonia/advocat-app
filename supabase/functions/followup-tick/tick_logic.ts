// tick_logic.ts — pure selection logic for followup-tick.
// -----------------------------------------------------------------------------
// No Deno globals, no I/O — imported by the cron fn and exercised by tests.
//
// A follow-up is "due for a nudge" when it is open, carries a due_at, has not
// yet been reminded, and the due_at falls inside the reminder window
// [now, now + REMINDER_LEAD_MS]. The window is one day so the user is nudged
// the day before — long-overdue tasks (due_at already in the past) are ALSO
// included once, so a task that slipped past its date still gets one reminder.
// -----------------------------------------------------------------------------

/** Reminder lead time: nudge up to 1 day before due_at. */
export const REMINDER_LEAD_MS = 24 * 60 * 60 * 1000;

export interface FollowupRow {
  id: string;
  user_id: string;
  case_id: string;
  title: string;
  due_at: string | null;
  status: string;
  reminded_at: string | null;
}

/** True when this row should be nudged on this tick. */
export function isDueForReminder(
  row: FollowupRow,
  now: Date = new Date()
): boolean {
  if (row.status !== "open") return false;
  if (row.reminded_at !== null) return false;
  if (!row.due_at) return false;

  const due = new Date(row.due_at);
  if (Number.isNaN(due.getTime())) return false;

  const horizon = now.getTime() + REMINDER_LEAD_MS;
  // Fire when due_at is at or before the horizon (covers both "due tomorrow"
  // and "already overdue"). The reminded_at guard ensures it fires once.
  return due.getTime() <= horizon;
}

/** Filter a batch of rows to those needing a nudge this tick. */
export function selectDueRows(
  rows: FollowupRow[],
  now: Date = new Date()
): FollowupRow[] {
  return rows.filter((r) => isDueForReminder(r, now));
}

/** Human-readable lead label for the push body, computed from the gap. */
export function reminderBody(row: FollowupRow, now: Date = new Date()): string {
  if (!row.due_at) return "You have a follow-up step to complete.";
  const due = new Date(row.due_at);
  if (Number.isNaN(due.getTime())) {
    return "You have a follow-up step to complete.";
  }
  const ms = due.getTime() - now.getTime();
  if (ms < 0) return "A follow-up step is overdue.";
  if (ms <= REMINDER_LEAD_MS) return "A follow-up step is due tomorrow.";
  return "You have a follow-up step coming up.";
}
