// tick_logic.ts — pure reminder-window logic for renewal-tick.
// -----------------------------------------------------------------------------
// No Deno globals, no I/O — imported by the cron fn and exercised by tests.
//
// A renewable document carries an `expires_on` date and three lead windows
// (90 / 30 / 7 days before expiry). On each daily tick we ask: which windows
// have been *reached* (today is at or past the window's trigger date) but have
// NOT yet been dispatched (absent from `reminders_sent`)? We send the single
// most-urgent newly-reached window and add it to the watermark, so each window
// fires at most once even if the cron is late, re-run, or overlaps.
//
// Overdue handling: once the document has expired (today >= expires_on) the
// 7-day window has necessarily been reached, so an already-expired document
// that somehow never got a reminder still gets its final ('7') nudge once.
// -----------------------------------------------------------------------------

/** Lead windows in days before expiry, most-distant first. */
export const REMINDER_WINDOWS = [90, 30, 7] as const;
export type ReminderWindow = (typeof REMINDER_WINDOWS)[number];

/** String keys stored in `reminders_sent` (Postgres text[]). */
export const WINDOW_KEYS: Record<ReminderWindow, string> = {
  90: "90",
  30: "30",
  7: "7",
};

export interface RenewableDocRow {
  id: string;
  user_id: string;
  doc_type: string;
  label: string;
  jurisdiction: string | null;
  /** ISO date 'YYYY-MM-DD'. */
  expires_on: string;
  /** Subset of {'90','30','7'} already dispatched. */
  reminders_sent: string[];
  notifications_enabled: boolean;
}

/**
 * Whole-day difference (expires_on - today), normalised to UTC midnight so the
 * cron's time-of-day never shifts the boundary. Positive = days remaining,
 * 0 = expires today, negative = already expired.
 */
export function daysUntilExpiry(expiresOn: string, now: Date): number {
  const exp = parseIsoDate(expiresOn);
  if (exp === null) return Number.NaN;
  const today = Date.UTC(
    now.getUTCFullYear(),
    now.getUTCMonth(),
    now.getUTCDate()
  );
  const MS_PER_DAY = 24 * 60 * 60 * 1000;
  return Math.floor((exp - today) / MS_PER_DAY);
}

/** Parse 'YYYY-MM-DD' to a UTC-midnight epoch, or null when malformed. */
function parseIsoDate(s: string): number | null {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(s.trim());
  if (!m) return null;
  const [, y, mo, d] = m;
  const epoch = Date.UTC(Number(y), Number(mo) - 1, Number(d));
  if (Number.isNaN(epoch)) return null;
  // Reject overflow dates like 2026-02-31 (Date.UTC silently rolls over).
  const back = new Date(epoch);
  if (
    back.getUTCFullYear() !== Number(y) ||
    back.getUTCMonth() !== Number(mo) - 1 ||
    back.getUTCDate() !== Number(d)
  ) {
    return null;
  }
  return epoch;
}

/**
 * The single window to dispatch on this tick, or null when nothing is due.
 *
 * "Reached" = days-remaining <= window threshold. When several windows are
 * simultaneously reached but unsent (e.g. a doc added 5 days before expiry,
 * so 90/30/7 are all reached at once), we send only the MOST URGENT reached
 * window (smallest day count) and mark just that one — the earlier windows are
 * moot once a tighter one has fired, so we never spam three emails at once.
 * The watermark still advances; later ticks send nothing more.
 */
export function nextDueWindow(
  row: RenewableDocRow,
  now: Date
): ReminderWindow | null {
  if (!row.notifications_enabled) return null;
  const days = daysUntilExpiry(row.expires_on, now);
  if (Number.isNaN(days)) return null;

  const sent = new Set(row.reminders_sent);
  // Iterate most-urgent first (7, 30, 90). The first reached+unsent window is
  // the one we fire; tighter windows take precedence over looser ones.
  for (const w of [...REMINDER_WINDOWS].sort((a, b) => a - b)) {
    if (days <= w && !sent.has(WINDOW_KEYS[w])) {
      return w;
    }
  }
  return null;
}

/** Convenience: rows with a due window this tick, paired with that window. */
export function selectDue(
  rows: RenewableDocRow[],
  now: Date
): Array<{ row: RenewableDocRow; window: ReminderWindow }> {
  const out: Array<{ row: RenewableDocRow; window: ReminderWindow }> = [];
  for (const row of rows) {
    const w = nextDueWindow(row, now);
    if (w !== null) out.push({ row, window: w });
  }
  return out;
}

/**
 * Window keys to persist after firing `window`. Because firing the most-urgent
 * reached window makes any looser still-unsent reached windows moot, we mark
 * the fired window PLUS every looser window that is also already reached — so
 * a future tick doesn't belatedly send a now-pointless 90-day notice.
 */
export function windowsToMark(
  row: RenewableDocRow,
  window: ReminderWindow,
  now: Date
): string[] {
  const days = daysUntilExpiry(row.expires_on, now);
  const sent = new Set(row.reminders_sent);
  for (const w of REMINDER_WINDOWS) {
    // Mark the fired window, and any looser window already reached but unsent.
    if (w >= window && days <= w) sent.add(WINDOW_KEYS[w]);
  }
  sent.add(WINDOW_KEYS[window]);
  return [...sent];
}

/** Human-readable push/email body copy for a fired window. */
export function reminderCopy(
  row: RenewableDocRow,
  window: ReminderWindow,
  now: Date
): { title: string; body: string } {
  const days = daysUntilExpiry(row.expires_on, now);
  const title = "Document renewal reminder";
  let when: string;
  if (days < 0) {
    when = `has expired (was due ${row.expires_on})`;
  } else if (days === 0) {
    when = "expires today";
  } else if (days === 1) {
    when = "expires tomorrow";
  } else {
    when = `expires in ${days} days (${row.expires_on})`;
  }
  return {
    title,
    body: `Your ${row.label} ${when}. Tap to see how to renew it.`,
  };
}
