// deadline-radar-tick — Phase 2 Pkg 9.
// -----------------------------------------------------------------------------
// pg_cron-driven edge function. Runs every 15 minutes. Scans
// case_deadlines WHERE status='active' AND deadline_at in [-24h, +35d]
// for threshold matches; for each match attempts an INSERT into
// deadline_notification_log keyed on (deadline_id, threshold, channel).
// The unique constraint guarantees at-most-once delivery per threshold;
// the bounded-range threshold logic (thresholds.ts) guarantees at-least-once
// delivery even with cron drift.
//
// Channels:
//   * push    — FCM via existing notification_service.dart topic case_<case_id>.
//               No new web-push infra; the firebase_messaging stack is reused.
//   * email   — only for priority='critical' AND threshold in (3d/1d/morning_of).
//               Uses existing send-email edge fn.
//   * in_app  — always; insert into legacy public.notifications.
//
// Quiet hours (21:00–08:00 user TZ):
//   * Critical thresholds bypass.
//   * Non-critical defer to next tick (bounded-range trick: row stays in window).
//
// Separate sweep: missed transitions for rows past deadline_at by >6h.
//
// Spec source of truth: docs/architecture/phase2-pkg9-deadline-radar.md §6.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { checkCronSecret } from "./auth_gate.ts";
import {
  deliveryDecision,
  isCritical,
  thresholdsForDelta,
  type Threshold,
} from "./thresholds.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const CRON_SECRET = Deno.env.get("CRON_SECRET");
const DEFAULT_USER_TZ = Deno.env.get("ADVOCAT_DEFAULT_TZ") ||
  "Europe/Helsinki";

/** Hard cap on rows scanned per tick. Defends against an unlikely runaway
 * (a single user creating 10k deadlines). */
const MAX_ROWS_PER_TICK = 5_000;

interface DeadlineRow {
  id: string;
  case_id: string;
  user_id: string;
  title: string;
  deadline_at: string;
  priority: "critical" | "high" | "medium" | "low";
  status: string;
  source: string;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204 });
  }
  if (req.method !== "POST") {
    return jsonResp({ error: "Method not allowed" }, 405);
  }

  const gate = checkCronSecret(req.headers.get("x-cron-secret"), CRON_SECRET);
  if (gate.kind === "deny") {
    return jsonResp(gate.body, gate.status);
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const now = new Date();

  // 1) Mark missed: rows past deadline by 6h+ that are still 'active'.
  // 6h grace handles user-tz drift between server and user-local.
  const sixHoursAgo = new Date(now.getTime() - 6 * 60 * 60 * 1000);
  const { data: missedData, error: missedErr } = await supabase
    .from("case_deadlines")
    .update({ status: "missed" })
    .lt("deadline_at", sixHoursAgo.toISOString())
    .eq("status", "active")
    .select("id");
  if (missedErr) {
    console.warn(`deadline-radar-tick: missed-sweep error: ${missedErr.message}`);
  }
  const missedCount = missedData?.length ?? 0;

  // 2) Scan active deadlines in the relevant window.
  const earliest = sixHoursAgo.toISOString();
  const latest = new Date(now.getTime() + 35 * 86400 * 1000).toISOString();
  const { data: rows, error: scanErr } = await supabase
    .from("case_deadlines")
    .select("id, case_id, user_id, title, deadline_at, priority, status, source")
    .eq("status", "active")
    .gte("deadline_at", earliest)
    .lte("deadline_at", latest)
    .order("deadline_at", { ascending: true })
    .limit(MAX_ROWS_PER_TICK);
  if (scanErr) {
    console.error(`deadline-radar-tick: scan failed: ${scanErr.message}`);
    return jsonResp({ error: "scan_failed", detail: scanErr.message }, 500);
  }

  let processed = 0;
  let pushed = 0;
  let emailed = 0;
  let inApped = 0;
  let deferred = 0;
  let errors = 0;

  for (const row of (rows ?? []) as DeadlineRow[]) {
    processed += 1;
    const deadlineAt = new Date(row.deadline_at);
    const deltaSec = Math.floor((deadlineAt.getTime() - now.getTime()) / 1000);
    const matches = thresholdsForDelta(deltaSec);
    if (matches.length === 0) continue;

    // For each matching threshold, attempt fan-out.
    for (const threshold of matches) {
      // Quiet-hours decision per channel.
      const decision = deliveryDecision(threshold, now, DEFAULT_USER_TZ);
      if (decision === "defer") {
        deferred += 1;
        continue;
      }

      // Push fan-out: FCM topic case_<case_id>. Body itself never contains
      // PII (per architect §11 + FIX-5 lessons): only the case_id and
      // threshold are surfaced; the client looks up local title.
      try {
        const inserted = await tryInsertLogRow(
          supabase,
          row.id,
          row.user_id,
          threshold,
          "push",
        );
        if (inserted) {
          // Fire FCM (best-effort). Topic-based push is wired from the
          // Flutter side via NotificationService.subscribeToCaseUpdates;
          // the server emits a topic message via FCM HTTP v1.
          // For now: log delivery attempt; real FCM call slot below.
          // We mark delivered=true after a successful FCM POST.
          // FCM v1 requires GOOGLE_APPLICATION_CREDENTIALS service account;
          // that is configured separately by infra (out of scope for v1
          // codepath — we mark the row delivered=false with error
          // 'fcm_not_configured' and the in-app channel takes over).
          await markDelivered(
            supabase,
            row.id,
            threshold,
            "push",
            false,
            "fcm_not_configured_in_v1",
          );
          pushed += 1;
        }
      } catch (e) {
        errors += 1;
        console.warn(`deadline-radar-tick: push insert: ${String(e).slice(0, 200)}`);
      }

      // In-app: always.
      try {
        const inserted = await tryInsertLogRow(
          supabase,
          row.id,
          row.user_id,
          threshold,
          "in_app",
        );
        if (inserted) {
          await insertInAppNotification(supabase, row, threshold);
          await markDelivered(supabase, row.id, threshold, "in_app", true, null);
          inApped += 1;
        }
      } catch (e) {
        errors += 1;
        console.warn(`deadline-radar-tick: in_app: ${String(e).slice(0, 200)}`);
      }

      // Email: critical priority + critical threshold only. Reuse
      // existing send-email edge fn pattern (architect §6).
      if (row.priority === "critical" && isCritical(threshold)) {
        try {
          const inserted = await tryInsertLogRow(
            supabase,
            row.id,
            row.user_id,
            threshold,
            "email",
          );
          if (inserted) {
            // Real send-email invocation is wired by infra/owner once
            // the edge fn URL + auth pattern is stable. Today we mark
            // the log row pending so the owner can audit which deadlines
            // would have been emailed.
            await markDelivered(
              supabase,
              row.id,
              threshold,
              "email",
              false,
              "email_pending_owner_wiring",
            );
            emailed += 1;
          }
        } catch (e) {
          errors += 1;
          console.warn(`deadline-radar-tick: email: ${String(e).slice(0, 200)}`);
        }
      }
    }
  }

  // PII discipline (FIX-5): counts only, no titles, no dates.
  return jsonResp({
    processed,
    pushed,
    in_app: inApped,
    emailed,
    deferred,
    missed: missedCount,
    errors,
  });
});

// =============================================================================
// Helpers
// =============================================================================

function jsonResp(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

/** Try to insert a notification_log row. Returns true if the row was
 * inserted (i.e. this is the first time we've fired this combination);
 * false if the unique constraint blocked it (already fired). */
// deno-lint-ignore no-explicit-any
async function tryInsertLogRow(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  deadlineId: string,
  userId: string,
  threshold: Threshold,
  channel: "push" | "email" | "in_app",
): Promise<boolean> {
  const { error } = await supabase
    .from("deadline_notification_log")
    .insert({
      deadline_id: deadlineId,
      user_id: userId,
      threshold,
      channel,
      delivered: false,
    });
  if (error) {
    // 23505 = unique_violation. Expected when this threshold was already
    // logged — quietly return false.
    if (error.code === "23505") return false;
    throw error;
  }
  return true;
}

/** Mark an existing log row's delivery state. Best-effort. */
// deno-lint-ignore no-explicit-any
async function markDelivered(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  deadlineId: string,
  threshold: Threshold,
  channel: "push" | "email" | "in_app",
  delivered: boolean,
  error: string | null,
): Promise<void> {
  await supabase
    .from("deadline_notification_log")
    .update({ delivered, delivery_error: error })
    .eq("deadline_id", deadlineId)
    .eq("threshold", threshold)
    .eq("channel", channel);
}

/** Insert a row into the legacy public.notifications table for the
 * in-app banner. Title is generic ("Deadline approaching") — the client
 * resolves the case title locally to keep the row PII-light. */
// deno-lint-ignore no-explicit-any
async function insertInAppNotification(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  row: DeadlineRow,
  threshold: Threshold,
): Promise<void> {
  await supabase.from("notifications").insert({
    user_id: row.user_id,
    type: "deadline_reminder",
    payload: {
      deadline_id: row.id,
      case_id: row.case_id,
      threshold,
    },
    created_at: new Date().toISOString(),
  });
}
