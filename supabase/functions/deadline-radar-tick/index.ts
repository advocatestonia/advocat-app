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
const DEFAULT_USER_TZ = Deno.env.get("ADVOCAT_DEFAULT_TZ") || "Europe/Helsinki";

// Email channel (critical-deadline reminders). Uses the Resend transactional
// path directly — NOT the send-email edge fn (that one requires a per-user JWT
// + Gmail-OAuth/approval and cannot be driven cross-user from a service-role
// cron). The from-domain mirrors the already-verified domain used by
// weekly-digest-send / winback-send, so no new domain verification is needed.
//
// If RESEND_API_KEY is unset the email channel fails SOFT: we do not insert a
// log row, so the row is retried on a future tick once the secret is set
// (rather than being permanently stamped delivered=false). push + in_app remain
// the safety net in the meantime.
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const DEADLINE_EMAIL_FROM =
  Deno.env.get("DEADLINE_EMAIL_FROM") || "Advocat <hello@advocat.ee>";
const APP_BASE_URL = Deno.env.get("APP_BASE_URL") || "https://advocat.ee/app";

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
    console.warn(
      `deadline-radar-tick: missed-sweep error: ${missedErr.message}`
    );
  }
  const missedCount = missedData?.length ?? 0;

  // 2) Scan active deadlines in the relevant window.
  const earliest = sixHoursAgo.toISOString();
  const latest = new Date(now.getTime() + 35 * 86400 * 1000).toISOString();
  const { data: rows, error: scanErr } = await supabase
    .from("case_deadlines")
    .select(
      "id, case_id, user_id, title, deadline_at, priority, status, source"
    )
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
          "push"
        );
        if (inserted) {
          const pushResult = await dispatchPush(row, threshold);
          await markDelivered(
            supabase,
            row.id,
            threshold,
            "push",
            pushResult.delivered,
            pushResult.error
          );
          pushed += 1;
        }
      } catch (e) {
        errors += 1;
        console.warn(
          `deadline-radar-tick: push insert: ${String(e).slice(0, 200)}`
        );
      }

      // In-app: always.
      try {
        const inserted = await tryInsertLogRow(
          supabase,
          row.id,
          row.user_id,
          threshold,
          "in_app"
        );
        if (inserted) {
          await insertInAppNotification(supabase, row, threshold);
          await markDelivered(
            supabase,
            row.id,
            threshold,
            "in_app",
            true,
            null
          );
          inApped += 1;
        }
      } catch (e) {
        errors += 1;
        console.warn(`deadline-radar-tick: in_app: ${String(e).slice(0, 200)}`);
      }

      // Email: critical priority + critical threshold only. Sends a
      // generic, PII-free reminder via the Resend transactional path
      // (see dispatchEmail). The send is attempted FIRST; the log row is
      // only committed on a DEFINITIVE outcome:
      //   * sent      → row stays, delivered=true.
      //   * permanent → row stays, delivered=false + reason
      //                 (no_email_on_file / email_disabled_by_user /
      //                  resend_4xx:… / email_not_configured-as-permanent? no).
      //   * transient → row is REMOVED so a future tick retries
      //                 (resend_unreachable / resend_5xx / resend_not_configured).
      // This mirrors the push channel's "don't permanently mark a transient
      // failure" intent, but goes one step further: because the unique
      // constraint would otherwise block all retries, we DELETE the just-
      // claimed slot on a transient failure instead of leaving a poisoned row.
      if (row.priority === "critical" && isCritical(threshold)) {
        try {
          const inserted = await tryInsertLogRow(
            supabase,
            row.id,
            row.user_id,
            threshold,
            "email"
          );
          if (inserted) {
            const result = await dispatchEmail(supabase, row, threshold);
            if (result.outcome === "transient") {
              // Release the claimed slot so a future tick can retry.
              // (e.g. RESEND_API_KEY not yet set, or Resend 5xx/unreachable.)
              await deleteLogRow(supabase, row.id, threshold, "email");
            } else {
              // sent | permanent: commit the outcome.
              await markDelivered(
                supabase,
                row.id,
                threshold,
                "email",
                result.outcome === "sent",
                result.error
              );
              if (result.outcome === "sent") emailed += 1;
            }
          }
        } catch (e) {
          errors += 1;
          console.warn(
            `deadline-radar-tick: email: ${String(e).slice(0, 200)}`
          );
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
  channel: "push" | "email" | "in_app"
): Promise<boolean> {
  const { error } = await supabase.from("deadline_notification_log").insert({
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

/** Remove a previously-claimed log row. Used by the email channel to release
 * the (deadline_id, threshold, channel) slot after a TRANSIENT failure so a
 * future tick retries the send, rather than leaving a permanent
 * delivered=false row that the unique constraint would never let us retry.
 * Best-effort. */
// deno-lint-ignore no-explicit-any
async function deleteLogRow(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  deadlineId: string,
  threshold: Threshold,
  channel: "push" | "email" | "in_app"
): Promise<void> {
  await supabase
    .from("deadline_notification_log")
    .delete()
    .eq("deadline_id", deadlineId)
    .eq("threshold", threshold)
    .eq("channel", channel);
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
  error: string | null
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
  threshold: Threshold
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
  threshold: Threshold
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

// =============================================================================
// Email channel
// =============================================================================

interface EmailDispatchResult {
  /** sent → delivered=true; permanent → delivered=false (commit, no retry);
   *  transient → release the slot so a future tick retries. */
  outcome: "sent" | "permanent" | "transient";
  /** delivery_error column value (null on success). PII-free by construction. */
  error: string | null;
}

/** Dispatch a PII-free critical-deadline reminder email via the Resend
 * transactional path.
 *
 * PII discipline (architect §11 / FIX-5):
 *   * The user's email address is fetched from `public.users` via the
 *     service-role client ONLY at send time and is handed straight to Resend.
 *     It is never written to deadline_notification_log, never logged, and
 *     never returned in the function's JSON summary.
 *   * The message body contains NO case details — only a generic
 *     "you have a critical legal deadline" line + a deep link into the app +
 *     an unsubscribe link. The recipient resolves the actual deadline by
 *     opening the app (mirrors the push/in_app payload discipline).
 *
 * Outcome mapping (load-bearing for the retry contract):
 *   * RESEND_API_KEY unset .................. transient (degrade to pending;
 *                                              retry once the secret is set).
 *   * user has no email on file ............. permanent (no_email_on_file).
 *   * notification_preferences.all_email_disabled
 *                                       ...... permanent (email_disabled_by_user).
 *   * Resend 2xx ............................ sent.
 *   * Resend 4xx (bad address etc.) ........ permanent (resend_4xx:…) — a retry
 *                                              would just fail identically.
 *   * Resend 5xx / network / timeout ....... transient (resend_unreachable… /
 *                                              resend_5xx:…) — retry next tick.
 */
async function dispatchEmail(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  row: DeadlineRow,
  threshold: Threshold
): Promise<EmailDispatchResult> {
  // Fail SOFT (transient) if no transactional sender is configured: leaving the
  // slot unclaimed means a future tick retries once RESEND_API_KEY is set,
  // instead of permanently stamping delivered=false. push + in_app cover the
  // gap in the meantime.
  if (!RESEND_API_KEY) {
    return { outcome: "transient", error: "resend_not_configured" };
  }

  // Resolve the recipient address at send time (never persisted/logged).
  let toEmail: string | null = null;
  try {
    const { data: u } = await supabase
      .from("users")
      .select("email")
      .eq("id", row.user_id)
      .maybeSingle();
    toEmail = (u?.email as string | null) ?? null;
  } catch (e) {
    // Treat a DB blip on the lookup as transient — a future tick can retry.
    return {
      outcome: "transient",
      error: `email_lookup_failed:${String(e).slice(0, 60)}`,
    };
  }
  if (!toEmail) {
    return { outcome: "permanent", error: "no_email_on_file" };
  }

  // Respect the user's email opt-out + obtain an unsubscribe token (lazy-create
  // the prefs row so the unsubscribe link always works). Mirrors winback-send.
  let unsubToken: string | null = null;
  try {
    const { data: prefs } = await supabase
      .from("notification_preferences")
      .select("unsubscribe_token, all_email_disabled")
      .eq("user_id", row.user_id)
      .maybeSingle();
    if (prefs?.all_email_disabled) {
      return { outcome: "permanent", error: "email_disabled_by_user" };
    }
    unsubToken = (prefs?.unsubscribe_token as string | null) ?? null;
    if (!prefs) {
      const { data: created } = await supabase
        .from("notification_preferences")
        .insert({ user_id: row.user_id })
        .select("unsubscribe_token")
        .single();
      unsubToken = (created?.unsubscribe_token as string | null) ?? null;
    }
  } catch (_e) {
    // prefs lookup is best-effort; absence of an opt-out row defaults to
    // opted-in. Do not block the critical-deadline send on it.
  }

  const subject = thresholdTitle(threshold);
  const deepLink = `${APP_BASE_URL}/cases/${row.case_id}/deadlines/${row.id}`;
  const unsubUrl = unsubToken
    ? `${APP_BASE_URL}/unsubscribe?token=${encodeURIComponent(
        unsubToken
      )}&kind=deadline`
    : null;

  // PII-free body: no case title, no party names, no date — just a generic
  // critical-deadline nudge + deep link. The user sees the detail in-app.
  const text = [
    "You have a critical legal deadline approaching.",
    "",
    "Open Advocat to view it:",
    deepLink,
    ...(unsubUrl ? ["", "To stop deadline emails: " + unsubUrl] : []),
  ].join("\n");
  const html = [
    `<p>You have a <strong>critical legal deadline</strong> approaching.</p>`,
    `<p><a href="${deepLink}">Open Advocat to view it</a>.</p>`,
    ...(unsubUrl
      ? [
          `<p style="color:#888;font-size:12px">` +
            `<a href="${unsubUrl}">Stop deadline emails</a></p>`,
        ]
      : []),
  ].join("");

  let resp: Response;
  try {
    resp = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: DEADLINE_EMAIL_FROM,
        to: [toEmail],
        subject,
        text,
        html,
      }),
      signal: AbortSignal.timeout(15_000),
    });
  } catch (e) {
    // Network / timeout → transient, retry next tick.
    return {
      outcome: "transient",
      error: `resend_unreachable:${String(e).slice(0, 80)}`,
    };
  }

  if (resp.ok) {
    // Drain the body so the connection can be reused; we don't need the id.
    await resp.text().catch(() => "");
    return { outcome: "sent", error: null };
  }

  const errText = await resp.text().catch(() => "");
  if (resp.status >= 500) {
    // Provider-side outage → transient, retry next tick.
    return {
      outcome: "transient",
      error: `resend_${resp.status}:${errText.slice(0, 80)}`,
    };
  }
  // 4xx (e.g. invalid recipient) → permanent; a retry would fail identically.
  return {
    outcome: "permanent",
    error: `resend_${resp.status}:${errText.slice(0, 80)}`,
  };
}
