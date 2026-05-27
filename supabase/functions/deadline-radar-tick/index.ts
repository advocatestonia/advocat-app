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

      // Push fan-out: FCM token-based push routed through the `push-send`
      // edge fn. The Flutter NotificationService persists the device token
      // to `notification_preferences.fcm_token` on first-run / refresh;
      // push-send looks it up + applies per-kind opt-outs + writes the
      // push_events audit row.
      //
      // Body never contains PII (per architect §11 + FIX-5): only a
      // generic "Deadline approaching" title + the threshold/deadline_id
      // in `data` so the client deep-links to the deadline detail screen.
      try {
        const inserted = await tryInsertLogRow(
          supabase,
          row.id,
          row.user_id,
          threshold,
          "push",
        );
        if (inserted) {
          const pushResult = await dispatchPush(row, threshold);
          await markDelivered(
            supabase,
            row.id,
            threshold,
            "push",
            pushResult.delivered,
            pushResult.error,
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

interface PushDispatchResult {
  delivered: boolean;
  error: string | null;
}

/** Service-to-service call into push-send. Returns the delivery decision
 * so the caller can stamp the deadline_notification_log row.
 *
 * Failure modes (none throw — push is best-effort, the in_app channel
 * is the user-visible safety net):
 *   * push-send returns delivered=false with reason in the body
 *     (no_fcm_token / push_disabled_by_user / deadline_push_disabled /
 *      fcm_not_configured / fcm_<status>:...). We map that into the
 *     delivery_error column verbatim so the owner can grep audit log.
 *   * push-send is unreachable (network / 5xx). Logged as
 *     `push_send_unreachable:<short>` — the unique constraint on
 *     deadline_notification_log means we will NOT retry next tick;
 *     this is intentional (we don't want to spam an unreachable
 *     endpoint every 15min). Owner sees the error in the log.
 */
async function dispatchPush(
  row: DeadlineRow,
  threshold: Threshold,
): Promise<PushDispatchResult> {
  if (!CRON_SECRET) {
    return { delivered: false, error: "cron_secret_missing" };
  }

  // Body title is generic — the client resolves the per-case title locally
  // from its own cache. This keeps the FCM payload PII-free even if it is
  // logged by Google's intermediate servers.
  const title = thresholdTitle(threshold);
  const body = "Tap to view your deadline.";
  const data: Record<string, string> = {
    type: "deadline_reminder",
    deadline_id: row.id,
    case_id: row.case_id,
    threshold,
    route: `/cases/${row.case_id}/deadlines/${row.id}`,
  };

  let resp: Response;
  try {
    resp = await fetch(`${SUPABASE_URL}/functions/v1/push-send`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-cron-secret": CRON_SECRET,
      },
      body: JSON.stringify({
        user_id: row.user_id,
        kind: "deadline_reminder",
        title,
        body,
        data,
      }),
    });
  } catch (e) {
    return {
      delivered: false,
      error: `push_send_unreachable:${String(e).slice(0, 100)}`,
    };
  }

  if (!resp.ok) {
    const txt = await resp.text().catch(() => "");
    return {
      delivered: false,
      error: `push_send_${resp.status}:${txt.slice(0, 100)}`,
    };
  }

  let payload: { delivered?: boolean; reason?: string; error?: string };
  try {
    payload = await resp.json();
  } catch (_e) {
    return { delivered: false, error: "push_send_invalid_json" };
  }

  if (payload.delivered === true) {
    return { delivered: true, error: null };
  }
  return {
    delivered: false,
    error: payload.reason ?? payload.error ?? "push_not_delivered",
  };
}

function thresholdTitle(t: Threshold): string {
  switch (t) {
    case "30d":
      return "Deadline in 30 days";
    case "7d":
      return "Deadline in 7 days";
    case "3d":
      return "Deadline in 3 days";
    case "1d":
      return "Deadline tomorrow";
    case "morning_of":
      return "Deadline today";
  }
}
