// followup-tick — Smart Case Follow-ups (Feature #2) cron pusher.
// -----------------------------------------------------------------------------
// Runs on a pg_cron schedule (owner installs the cron job — see notes). On
// each tick it:
//   1. Selects OPEN follow-ups with a due_at inside the reminder window
//      (due tomorrow or already overdue) that have NOT yet been reminded.
//   2. For each, dispatches a PII-free push via the existing push-send
//      service (kind 'deadline_reminder' — these are soft reminders and
//      share the user's deadline-push opt-out).
//   3. Stamps reminded_at so the same row is never nudged twice.
//
// Mirrors the deadline-radar-tick pattern exactly:
//   * cron-secret gate (only pg_cron can invoke).
//   * service-role DB client for the cross-user scan.
//   * push routed through push-send (the single FCM-JWT holder).
//   * push is best-effort; reminded_at is still stamped on a non-delivery so
//     we don't spam an unreachable endpoint every tick. The in-app list is
//     the user-visible safety net.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { checkCronSecret } from "../deadline-radar-tick/auth_gate.ts";
import {
  type FollowupRow,
  reminderBody,
  REMINDER_LEAD_MS,
  selectDueRows,
} from "./tick_logic.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const CRON_SECRET = Deno.env.get("CRON_SECRET");

/** Hard cap per tick so a backlog can't fan out thousands of pushes at once. */
const MAX_ROWS_PER_TICK = 200;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204 });
  }
  if (req.method !== "POST") {
    return jsonResp({ error: "Method not allowed" }, 405);
  }

  const gate = checkCronSecret(req.headers.get("x-cron-secret"), CRON_SECRET);
  if (gate.kind === "deny") return jsonResp(gate.body, gate.status);

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const now = new Date();
  const horizon = new Date(now.getTime() + REMINDER_LEAD_MS).toISOString();

  // Pull candidate rows: open, not reminded, with a due_at at/under the
  // horizon (covers "due tomorrow" and "overdue"). The partial index
  // case_followups_cron_scan_idx serves this query.
  const { data: rows, error: fetchErr } = await supabase
    .from("case_followups")
    .select("id, user_id, case_id, title, due_at, status, reminded_at")
    .eq("status", "open")
    .is("reminded_at", null)
    .not("due_at", "is", null)
    .lte("due_at", horizon)
    .order("due_at", { ascending: true })
    .limit(MAX_ROWS_PER_TICK);

  if (fetchErr) {
    console.error("followup-tick: fetch failed");
    return jsonResp({ error: "fetch_failed" }, 500);
  }

  // Defensive re-filter in pure logic (also covers the overdue/horizon edge
  // identically to the SQL, and is unit-tested).
  const due = selectDueRows((rows ?? []) as FollowupRow[], now);

  let pushed = 0;
  let stamped = 0;
  let errors = 0;

  for (const row of due) {
    // Stamp reminded_at FIRST (claim the row) so a second concurrent tick or
    // a retry never double-nudges. Best-effort push follows.
    const { error: stampErr } = await supabase
      .from("case_followups")
      .update({ reminded_at: now.toISOString() })
      .eq("id", row.id)
      .is("reminded_at", null); // optimistic claim
    if (stampErr) {
      errors++;
      continue;
    }
    stamped++;

    const delivered = await dispatchPush(row, now);
    if (delivered) pushed++;
  }

  // Counts only — never echo titles/user-ids (PII / GDPR Art. 33, same rule
  // the deadline-reminder cron follows).
  return jsonResp({ scanned: (rows ?? []).length, stamped, pushed, errors });
});

/**
 * Service-to-service push via push-send. PII-free payload (the client
 * resolves the case title from its own cache via the case_id in data).
 * Returns true only on confirmed delivery; never throws.
 */
async function dispatchPush(row: FollowupRow, now: Date): Promise<boolean> {
  if (!CRON_SECRET) return false;

  const body = reminderBody(row, now);
  const data: Record<string, string> = {
    type: "followup_reminder",
    followup_id: row.id,
    case_id: row.case_id,
    route: `/cases/${row.case_id}`,
  };

  try {
    const resp = await fetch(`${SUPABASE_URL}/functions/v1/push-send`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-cron-secret": CRON_SECRET,
      },
      body: JSON.stringify({
        user_id: row.user_id,
        // Reuse the deadline_reminder kind: it has no throttle and respects
        // the user's deadline-push opt-out, which is the right channel for a
        // soft case reminder. (push-send only knows a fixed set of kinds.)
        kind: "deadline_reminder",
        title: "Follow-up reminder",
        body,
        data,
      }),
    });
    if (!resp.ok) return false;
    const payload = (await resp.json().catch(() => null)) as {
      delivered?: boolean;
    } | null;
    return payload?.delivered === true;
  } catch (_e) {
    return false;
  }
}

function jsonResp(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
