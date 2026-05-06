// holiday_shift.ts — Phase 2 Pkg 9 deadline radar.
// -----------------------------------------------------------------------------
// Single source of truth for converting a (service_date, statutory_window,
// jurisdiction) tuple into an absolute, holiday-shifted deadline.
//
// Spec source of truth: docs/architecture/phase2-pkg9-deadline-radar.md §3.
//
// Two policies:
//   * 'next_business_day' — shift forward over weekends + FI/EE holidays.
//     Used for kaebus / valitus / oikaisuvaatimus / vaie.
//   * 'strict_calendar'   — never shift. Used ONLY for ECHR Protocol 15.
//     A 4-month strict-calendar deadline that lands on a Saturday stays
//     Saturday (Strasbourg does not extend over weekends).
//
// Pure module — no Deno globals, no I/O. Testable without a Supabase env.
// -----------------------------------------------------------------------------

import {
  EE_HOLIDAYS_SET,
  FI_HOLIDAYS_SET,
} from "./holidays_fi_ee.ts";

/** Jurisdictions we recognize for shift logic. */
export type DeadlineJurisdiction = "FI" | "EE" | "EU";

/** Shift policy. */
export type ShiftPolicy = "next_business_day" | "strict_calendar";

/** Service-clock unit. */
export type ClockKind = "calendar" | "working";

/** Statutory window unit. */
export type StatutoryUnit = "calendar_days" | "working_days" | "calendar_months";

// =============================================================================
// Date helpers (UTC-only — every call should pass dates with the time portion
// at midnight UTC or 12:00 UTC; we operate on the UTC y/m/d).
// =============================================================================

/** Format a Date as ISO yyyy-mm-dd in UTC. */
function toIsoDate(d: Date): string {
  return d.toISOString().slice(0, 10);
}

/** True if d is Saturday (6) or Sunday (0) in UTC. */
export function isWeekend(d: Date): boolean {
  const day = d.getUTCDay();
  return day === 0 || day === 6;
}

/** True if d is on the FI public holiday list. */
export function isFinnishHoliday(d: Date): boolean {
  return FI_HOLIDAYS_SET.has(toIsoDate(d));
}

/** True if d is on the EE public holiday list. */
export function isEstonianHoliday(d: Date): boolean {
  return EE_HOLIDAYS_SET.has(toIsoDate(d));
}

/** True if d is a non-working day in the given jurisdiction. EU = no holiday
 * concept (ECHR is the only EU anchor and it is strict_calendar regardless). */
function isNonWorking(d: Date, jurisdiction: DeadlineJurisdiction): boolean {
  if (isWeekend(d)) return true;
  if (jurisdiction === "FI") return isFinnishHoliday(d);
  if (jurisdiction === "EE") return isEstonianHoliday(d);
  // EU: weekends only (none in practice — ECHR is strict_calendar).
  return false;
}

/** Add N calendar days to d. Returns a new Date (UTC). */
function addDays(d: Date, n: number): Date {
  const result = new Date(d.getTime());
  result.setUTCDate(result.getUTCDate() + n);
  return result;
}

/** Add N working days (skipping weekends + holidays of the given
 * jurisdiction). Used for HL §59 +3 working-days service-clock modifier. */
function addWorkingDays(
  d: Date,
  n: number,
  jurisdiction: DeadlineJurisdiction,
): Date {
  let cur = new Date(d.getTime());
  let remaining = n;
  while (remaining > 0) {
    cur = addDays(cur, 1);
    if (!isNonWorking(cur, jurisdiction)) {
      remaining -= 1;
    }
  }
  return cur;
}

/** Add N calendar months. End-of-month clamping (Jan 31 + 1 month = Feb 28
 * in non-leap years, Feb 29 in leap years). Mirrors Java
 * java.time.LocalDate.plusMonths semantics. */
function addMonths(d: Date, n: number): Date {
  const y = d.getUTCFullYear();
  const m = d.getUTCMonth();
  const day = d.getUTCDate();
  const target = new Date(Date.UTC(y, m + n, 1));
  // Compute the last day of the target month.
  const targetMonth = target.getUTCMonth();
  const targetYear = target.getUTCFullYear();
  const lastDay = new Date(Date.UTC(targetYear, targetMonth + 1, 0)).getUTCDate();
  const clampedDay = Math.min(day, lastDay);
  return new Date(Date.UTC(targetYear, targetMonth, clampedDay));
}

/** Format a date for the holiday-shift note ("Sat 2026-06-13"). */
function fmtNoteDate(d: Date): string {
  const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
  return `${days[d.getUTCDay()]} ${toIsoDate(d)}`;
}

// =============================================================================
// shiftDeadline — apply policy to a pre-computed candidate date
// =============================================================================

export interface ShiftRequest {
  jurisdiction: DeadlineJurisdiction;
  policy: ShiftPolicy;
}

export interface ShiftResult {
  /** The shifted Date (or input unchanged if no shift was applied). */
  shiftedAt: Date;
  /** True iff the input was rolled forward over a weekend/holiday. */
  shifted: boolean;
  /** Human-readable note: "moved from Sat 2026-06-13 → Mon 2026-06-15".
   * Empty string when no shift happened. */
  note: string;
}

/** Roll a date forward over weekends + holidays per the chosen policy.
 * `strict_calendar` always returns the input unchanged. */
export function shiftDeadline(
  candidate: Date,
  req: ShiftRequest,
): ShiftResult {
  if (req.policy === "strict_calendar") {
    return { shiftedAt: candidate, shifted: false, note: "" };
  }
  // next_business_day: roll forward until we hit a working day. Hard cap at
  // 30 iterations defends against a pathological holiday list (the longest
  // FI/EE holiday cluster is ~5 days; 30 iterations is plenty).
  let cur = new Date(candidate.getTime());
  let iterations = 0;
  const original = new Date(candidate.getTime());
  while (isNonWorking(cur, req.jurisdiction)) {
    cur = addDays(cur, 1);
    iterations += 1;
    if (iterations > 30) {
      // Defensive break — should never happen with the curated holiday list.
      break;
    }
  }
  const shifted = iterations > 0;
  const note = shifted
    ? `moved from ${fmtNoteDate(original)} → ${fmtNoteDate(cur)}`
    : "";
  return { shiftedAt: cur, shifted, note };
}

// =============================================================================
// computeAbsoluteDeadline — full pipeline (architect spec §3)
// =============================================================================

export interface DeadlineComputeRequest {
  /** The legal "service date" — the day the document was served. Required. */
  serviceDate: Date;
  /** Service-clock modifier (HL §60 turvaviesti = 7d, HMS §27 = 5d, HL §59
   * = 3 working days). Set to 0 if no modifier applies. */
  serviceClockDays: number;
  /** Whether the service clock counts calendar or working days. */
  serviceClockKind: ClockKind;
  /** Statutory window magnitude (e.g. 30 for kaebetähtaeg, 4 for ECHR). */
  statutoryDays: number;
  /** Statutory window unit. */
  statutoryUnit: StatutoryUnit;
  /** Jurisdiction for holiday lookups. */
  jurisdiction: DeadlineJurisdiction;
  /** Holiday-shift policy. ECHR = 'strict_calendar'; else 'next_business_day'. */
  holidayShiftPolicy: ShiftPolicy;
}

export interface DeadlineComputeResult {
  /** Absolute deadline as a UTC Date (post-shift). */
  deadlineAt: Date;
  /** True iff the result was rolled forward by the holiday-shift step. */
  holidayShifted: boolean;
  /** Human-readable shift note, empty when not shifted. */
  holidayShiftNote: string;
}

/** Apply service-clock + statutory window + holiday shift in one shot.
 *
 * Invariants:
 *   1. ECHR Protocol 15 (`holidayShiftPolicy='strict_calendar'`) NEVER
 *      shifts — even on a Saturday the deadline stays Saturday.
 *   2. `serviceClockKind='working'` skips weekends + holidays during the
 *      service-clock count (e.g. HL §59 +3 working days).
 *   3. `statutoryUnit='calendar_months'` uses Java/POSIX month-arithmetic
 *      end-of-month clamping (Jan 31 + 1 month = Feb 28/29).
 */
export function computeAbsoluteDeadline(
  req: DeadlineComputeRequest,
): DeadlineComputeResult {
  if (!(req.serviceDate instanceof Date) || isNaN(req.serviceDate.getTime())) {
    throw new Error("computeAbsoluteDeadline: serviceDate must be a valid Date");
  }
  if (!["FI", "EE", "EU"].includes(req.jurisdiction)) {
    throw new Error(`computeAbsoluteDeadline: invalid jurisdiction ${req.jurisdiction}`);
  }

  // Step 1 — apply service-clock modifier.
  let after_service: Date;
  if (req.serviceClockDays === 0) {
    after_service = new Date(req.serviceDate.getTime());
  } else if (req.serviceClockKind === "calendar") {
    after_service = addDays(req.serviceDate, req.serviceClockDays);
  } else {
    after_service = addWorkingDays(
      req.serviceDate,
      req.serviceClockDays,
      req.jurisdiction,
    );
  }

  // Step 2 — apply statutory window.
  let candidate: Date;
  if (req.statutoryUnit === "calendar_days") {
    candidate = addDays(after_service, req.statutoryDays);
  } else if (req.statutoryUnit === "working_days") {
    candidate = addWorkingDays(after_service, req.statutoryDays, req.jurisdiction);
  } else {
    // calendar_months — used for ECHR Protocol 15.
    candidate = addMonths(after_service, req.statutoryDays);
  }

  // Step 3 — holiday-shift the candidate per the policy.
  const shift = shiftDeadline(candidate, {
    jurisdiction: req.jurisdiction,
    policy: req.holidayShiftPolicy,
  });

  return {
    deadlineAt: shift.shiftedAt,
    holidayShifted: shift.shifted,
    holidayShiftNote: shift.note,
  };
}
