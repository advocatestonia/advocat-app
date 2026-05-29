// deadline-radar-eu — EU corpus 3-feature wave (2026-05-26).
// -----------------------------------------------------------------------------
// Computes a deadline date for a given (jurisdiction, category) using:
//   - public.deadline_radar_eu (122 windows seeded)
//   - public.holiday_calendars (36 calendars; holiday JSONB arrays)
//
// Pure deterministic — no LLM. Returns due_date + skipped holidays +
// the source statute reference + computation rule.
//
// Spec: docs/eu_corpus/API_SPEC_3_FEATURES.md §2
// Schema: 20260526010000_eu_corpus_3features.sql
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

interface DeadlineRadarRequest {
  jurisdiction: string;
  category: string;
  start_date: string;        // ISO YYYY-MM-DD
  knowledge_date?: string;
  interruption_events?: Array<{ kind: string; date: string }>;
}

interface HolidayEntry {
  date: string;
  name: string;
}

/** Parse an ISO 8601 duration (PnYnMnD) into days approximation.
 *  We treat years=365, months=30 for the upper-bound — UI must always show
 *  the source statute_ref so the user verifies before filing.
 */
function isoDurationToDays(iso: string): number | null {
  if (!iso) return null;
  const m = iso.match(/^P(?:(\d+)Y)?(?:(\d+)M)?(?:(\d+)D)?$/);
  if (!m) return null;
  const years = parseInt(m[1] || "0", 10);
  const months = parseInt(m[2] || "0", 10);
  const days = parseInt(m[3] || "0", 10);
  if (years === 0 && months === 0 && days === 0) return null;
  return years * 365 + months * 30 + days;
}

function addDays(date: Date, days: number): Date {
  const out = new Date(date);
  out.setUTCDate(out.getUTCDate() + days);
  return out;
}

function isoDate(d: Date): string {
  return d.toISOString().slice(0, 10);
}

function isWeekend(d: Date, weekendPattern: number[]): boolean {
  // ISO weekday: 1=Mon..7=Sun. Date.getUTCDay(): 0=Sun..6=Sat → map.
  const jsDay = d.getUTCDay();
  const isoDay = jsDay === 0 ? 7 : jsDay;
  return weekendPattern.includes(isoDay);
}

/** Roll forward to next working day (skipping weekends + holidays). */
function rollForward(
  date: Date,
  weekendPattern: number[],
  holidays: Set<string>,
): { rolled: Date; skipped: HolidayEntry[] } {
  let cur = new Date(date);
  const skipped: HolidayEntry[] = [];
  for (let i = 0; i < 30; i++) {
    const iso = isoDate(cur);
    if (!isWeekend(cur, weekendPattern) && !holidays.has(iso)) {
      return { rolled: cur, skipped };
    }
    if (holidays.has(iso)) {
      skipped.push({ date: iso, name: "" });
    }
    cur = addDays(cur, 1);
  }
  return { rolled: cur, skipped };
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // Auth: require a VALID end-user session (not merely a present header).
  // The previous check accepted any non-empty Authorization value, so
  // `Bearer garbage` passed and then ran a service-role DB query below —
  // effectively unauthenticated. requireUserWithRateLimit validates the
  // JWT via auth.getUser and also caps abuse at 20 req/min/user.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "deadline-radar-eu",
    maxPerMinute: 20,
  });
  if (gate.kind === "deny") return gate.response;

  let body: DeadlineRadarRequest;
  try {
    body = await req.json();
  } catch {
    return jsonError("Invalid JSON body", 400);
  }

  const juris = (body.jurisdiction || "").toUpperCase().trim();
  const category = (body.category || "").trim().toLowerCase();
  const startDateRaw = body.start_date;

  if (!juris) return jsonError("invalid_jurisdiction: required", 400);
  if (!category) return jsonError("invalid_category: required", 400);
  if (!startDateRaw || !/^\d{4}-\d{2}-\d{2}$/.test(startDateRaw)) {
    return jsonError("invalid_date_format: start_date must be ISO YYYY-MM-DD", 400);
  }
  const startDate = new Date(startDateRaw + "T00:00:00Z");
  if (Number.isNaN(startDate.getTime())) {
    return jsonError("invalid_date_format", 400);
  }

  const knowledgeDateRaw = body.knowledge_date || startDateRaw;
  if (!/^\d{4}-\d{2}-\d{2}$/.test(knowledgeDateRaw)) {
    return jsonError("invalid_date_format: knowledge_date", 400);
  }
  const knowledgeDate = new Date(knowledgeDateRaw + "T00:00:00Z");
  if (knowledgeDate < startDate) {
    return jsonError("knowledge_before_start", 400);
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const started = performance.now();

  // Lookup rule. Prefer exact (juris, category) match. If absent, return 404
  // with a hint listing the categories we have for that juris.
  const { data: ruleRows, error: ruleErr } = await supabase
    .from("deadline_radar_eu")
    .select("*")
    .eq("jurisdiction", juris)
    .ilike("category", category)
    .limit(5);

  if (ruleErr) {
    // Do NOT echo the raw Postgres error to the client (leaks schema/internal
    // detail). Log it server-side; return a generic message.
    console.error("deadline-radar-eu: rule lookup failed:", ruleErr.message);
    return jsonError("internal: rule lookup failed", 500);
  }

  if (!ruleRows || ruleRows.length === 0) {
    // No exact category — list available for this juris (404 with hint)
    const { data: avail } = await supabase
      .from("deadline_radar_eu")
      .select("category, subtype, statute_ref")
      .eq("jurisdiction", juris)
      .limit(20);
    return jsonError("no_rule_found", 404, {
      jurisdiction: juris,
      category_requested: category,
      available_categories: (avail || []).map((r) => r.category),
    });
  }

  const rule = ruleRows[0];
  const periodIso: string | null = rule.period_iso;
  const periodDays = periodIso ? isoDurationToDays(periodIso) : null;

  // Try to use the holiday_calendar_id from the rule; else infer 'XX-bundesweit'
  // pattern; else skip holiday roll-forward.
  let calendarId: string | null = rule.holiday_calendar_id || null;
  let calendar: {
    calendar_id: string;
    weekend_pattern: number[];
    holidays: HolidayEntry[];
  } | null = null;

  if (!calendarId) {
    // Heuristic: prefer "<juris-lower>-judicial" then "<juris-lower>-bundesweit" then any.
    const { data: cals } = await supabase
      .from("holiday_calendars")
      .select("calendar_id, weekend_pattern, holidays, jurisdiction")
      .eq("jurisdiction", juris)
      .limit(5);
    if (cals && cals.length) {
      // pick first; weekend_pattern + holidays are usable as-is
      const c = cals[0];
      calendarId = c.calendar_id;
      calendar = {
        calendar_id: c.calendar_id,
        weekend_pattern: c.weekend_pattern || [6, 7],
        holidays: c.holidays || [],
      };
    }
  } else {
    const { data: c } = await supabase
      .from("holiday_calendars")
      .select("calendar_id, weekend_pattern, holidays")
      .eq("calendar_id", calendarId)
      .maybeSingle();
    if (c) {
      calendar = {
        calendar_id: c.calendar_id,
        weekend_pattern: c.weekend_pattern || [6, 7],
        holidays: c.holidays || [],
      };
    }
  }

  const warnings: string[] = [];
  if (!calendar) {
    warnings.push(`holiday_calendar_missing for ${juris}; result uses calendar-day arithmetic only`);
  }
  if (!periodDays) {
    warnings.push(
      `period_iso null or unparseable (${periodIso ?? "null"}) — this category uses tiered or descriptive periods; consult ${rule.statute_ref}`,
    );
  }

  // Compute deadline. If no periodDays, return statute info only.
  let dueDate: Date | null = null;
  let skipped: HolidayEntry[] = [];
  let calendarDaysUsed = 0;
  if (periodDays !== null) {
    dueDate = addDays(startDate, periodDays);
    calendarDaysUsed = periodDays;
    // Roll forward over weekends + holidays
    if (calendar) {
      const holidaySet = new Set<string>();
      const holidayMap = new Map<string, string>();
      for (const h of calendar.holidays) {
        holidaySet.add(h.date);
        holidayMap.set(h.date, h.name);
      }
      const { rolled, skipped: skippedRaw } = rollForward(
        dueDate,
        calendar.weekend_pattern,
        holidaySet,
      );
      dueDate = rolled;
      skipped = skippedRaw.map((s) => ({
        date: s.date,
        name: holidayMap.get(s.date) || "holiday",
      }));
    }
  }

  warnings.push(
    "result depends on holiday_calendar_used; verify against statute_ref before filing",
  );

  return jsonOk({
    due_date: dueDate ? isoDate(dueDate) : null,
    period_iso: periodIso,
    period_display: rule.period,
    calendar_days_used: calendarDaysUsed,
    holidays_skipped: skipped,
    holiday_calendar_used: calendarId,
    computation_rule: rule.computation_rule ||
      "calendar_day (default — confirm against statute)",
    statute_ref: {
      jurisdiction: rule.jurisdiction,
      category: rule.category,
      subtype: rule.subtype,
      statute_ref: rule.statute_ref,
      absolute_cap: rule.absolute_cap,
      trigger_event: rule.trigger_event,
      interruption_events: rule.interruption_events,
      exceptions: rule.exceptions,
    },
    warnings,
    model_used: "deterministic-rules-v1",
    cache_hit: false,
    processing_ms: Math.round(performance.now() - started),
  });
});
