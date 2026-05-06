// thresholds.ts — pure threshold + quiet-hours logic for deadline-radar-tick.
// -----------------------------------------------------------------------------
// Spec source of truth: docs/architecture/phase2-pkg9-deadline-radar.md §6.
//
// Threshold windows are BOUNDED RANGES (not single instants). This guarantees
// at-least-once delivery even when pg_cron is 30 min late. The unique
// constraint on deadline_notification_log (deadline_id, threshold, channel)
// guarantees at-most-once.
//
// Quiet hours: 21:00–08:00 in user TZ. Critical thresholds (3d/1d/morning_of)
// bypass; informational thresholds (30d/7d) defer to next 08:00.
// -----------------------------------------------------------------------------

export type Threshold = "30d" | "7d" | "3d" | "1d" | "morning_of";

/** Threshold ranges in seconds (delta = deadline_at - now()). */
const THRESHOLD_WINDOWS: ReadonlyArray<{
  threshold: Threshold;
  /** Inclusive lower bound of delta seconds. */
  minDeltaSec: number;
  /** Inclusive upper bound of delta seconds. */
  maxDeltaSec: number;
  /** Whether this threshold is "critical" and bypasses quiet hours. */
  critical: boolean;
}> = [
  // 30d window: 27d < delta ≤ 30d. ~ 27..30 days.
  {
    threshold: "30d",
    minDeltaSec: 27 * 86400 + 1,
    maxDeltaSec: 30 * 86400,
    critical: false,
  },
  // 7d window: 5d < delta ≤ 7d.
  {
    threshold: "7d",
    minDeltaSec: 5 * 86400 + 1,
    maxDeltaSec: 7 * 86400,
    critical: false,
  },
  // 3d window: 36h < delta ≤ 72h. ~ 1.5..3 days.
  {
    threshold: "3d",
    minDeltaSec: 36 * 3600 + 1,
    maxDeltaSec: 72 * 3600,
    critical: true,
  },
  // 1d window: 8h < delta ≤ 36h.
  {
    threshold: "1d",
    minDeltaSec: 8 * 3600 + 1,
    maxDeltaSec: 36 * 3600,
    critical: true,
  },
  // morning_of: 0 ≤ delta ≤ 8h. Same-day window.
  {
    threshold: "morning_of",
    minDeltaSec: 0,
    maxDeltaSec: 8 * 3600,
    critical: true,
  },
];

/** Compute every threshold the row currently falls into.
 *
 * A typical row falls into AT MOST ONE threshold per tick (windows are
 * disjoint by ~6h). The `morning_of` window can overlap with `1d` only at
 * the exact boundary; `notification_log` unique-constraint dedupes. */
export function thresholdsForDelta(deltaSec: number): Threshold[] {
  const out: Threshold[] = [];
  for (const w of THRESHOLD_WINDOWS) {
    if (deltaSec >= w.minDeltaSec && deltaSec <= w.maxDeltaSec) {
      out.push(w.threshold);
    }
  }
  return out;
}

/** True iff the threshold is critical (bypasses quiet hours). */
export function isCritical(threshold: Threshold): boolean {
  return THRESHOLD_WINDOWS.find((w) => w.threshold === threshold)?.critical
    ?? false;
}

// =============================================================================
// Quiet hours
// =============================================================================

/** Default quiet-hours window. 21:00–08:00 user-local. */
export const QUIET_START_HOUR = 21;
export const QUIET_END_HOUR = 8;

/** Compute the user-local hour for a given moment + IANA timezone.
 *
 * Uses Intl.DateTimeFormat which is available in Deno. The TZ string
 * "Europe/Helsinki" is the production default. */
export function userLocalHour(now: Date, tz: string): number {
  const fmt = new Intl.DateTimeFormat("en-GB", {
    timeZone: tz,
    hour: "2-digit",
    hourCycle: "h23",
  });
  const parts = fmt.formatToParts(now);
  const hourPart = parts.find((p) => p.type === "hour");
  if (!hourPart) return 12; // safe default
  return parseInt(hourPart.value, 10);
}

/** True iff the moment is within the user's quiet hours (21:00..08:00). */
export function isInQuietHours(
  now: Date,
  tz: string,
  startHour: number = QUIET_START_HOUR,
  endHour: number = QUIET_END_HOUR,
): boolean {
  const h = userLocalHour(now, tz);
  // Window crosses midnight: 21..23 OR 0..7.
  if (startHour > endHour) {
    return h >= startHour || h < endHour;
  }
  // Window doesn't cross midnight: startHour..endHour.
  return h >= startHour && h < endHour;
}

/** Decide whether to send now, defer, or skip.
 *
 * Returns:
 *   - 'send' : fire immediately
 *   - 'defer': skip this tick, will retry next time bounds match
 *   - 'skip' : skip permanently (row should be marked missed by sweep) */
export type DeliveryDecision = "send" | "defer" | "skip";

export function deliveryDecision(
  threshold: Threshold,
  now: Date,
  tz: string,
): DeliveryDecision {
  if (isCritical(threshold)) return "send";
  // Non-critical: respect quiet hours.
  return isInQuietHours(now, tz) ? "defer" : "send";
}
