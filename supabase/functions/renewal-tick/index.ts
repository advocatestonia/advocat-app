// renewal-tick — Permit / Document Renewal Radar (Feature #5) cron pusher.
// -----------------------------------------------------------------------------
// Runs daily on a pg_cron schedule (registered by the migration below via the
// existing invoke_edge_cron path — no new external service). On each tick it:
//   1. Selects enabled renewable_documents whose next un-sent reminder window
//      (90 / 30 / 7 days before expiry) has been reached.
//   2. For each, claims the window by advancing `reminders_sent` FIRST (so a
//      retry / overlapping tick never double-notifies), then dispatches BOTH:
//        * a PII-free push via the existing push-send service, and
//        * a transactional email via Resend (the user-visible safety net if
//          push silently fails — the documented mitigation for "false calm").
//
// Mirrors the followup-tick / deadline-radar-tick pattern:
//   * cron-secret gate (only pg_cron can invoke).
//   * service-role DB client for the cross-user scan.
//   * push routed through push-send (the single FCM-JWT holder).
//   * counts-only response (PII / GDPR Art. 33).
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { checkCronSecret } from "../deadline-radar-tick/auth_gate.ts";
import {
  reminderCopy,
  type RenewableDocRow,
  selectDue,
  windowsToMark,
} from "./tick_logic.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const CRON_SECRET = Deno.env.get("CRON_SECRET");
const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");
const EMAIL_FROM =
  Deno.env.get("RENEWAL_EMAIL_FROM") ?? "Advocat <noreply@advocat.ee>";

/** Hard cap per tick so a backlog can't fan out thousands of notices at once. */
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
  // 90-day horizon: only rows whose nearest window could possibly be reached.
  // (expires_on at most 90 days out, OR already past — overdue still needs the
  // final '7' nudge.) The pure logic does the exact per-window selection.
  const horizon = new Date(now.getTime() + 91 * 24 * 60 * 60 * 1000);
  const horizonIso = horizon.toISOString().slice(0, 10);

  const { data: rows, error: fetchErr } = await supabase
    .from("renewable_documents")
    .select(
      "id, user_id, doc_type, label, jurisdiction, expires_on, reminders_sent, notifications_enabled"
    )
    .eq("notifications_enabled", true)
    .lte("expires_on", horizonIso)
    .order("expires_on", { ascending: true })
    .limit(MAX_ROWS_PER_TICK);

  if (fetchErr) {
    console.error("renewal-tick: fetch failed");
    return jsonResp({ error: "fetch_failed" }, 500);
  }

  const due = selectDue((rows ?? []) as RenewableDocRow[], now);

  let claimed = 0;
  let pushed = 0;
  let emailed = 0;
  let errors = 0;

  for (const { row, window } of due) {
    // Claim FIRST: advance reminders_sent with an optimistic guard so a
    // concurrent tick that already claimed the window touches zero rows.
    const marked = windowsToMark(row, window, now);
    const { data: updated, error: claimErr } = await supabase
      .from("renewable_documents")
      .update({ reminders_sent: marked })
      .eq("id", row.id)
      // Optimistic: only claim if this window is not already present. PostgREST
      // array-contains negation guards against a racing tick.
      .not("reminders_sent", "cs", `{${window}}`)
      .select("id");
    if (claimErr) {
      errors++;
      continue;
    }
    if (!updated || updated.length === 0) {
      // Another tick won the claim — skip silently.
      continue;
    }
    claimed++;

    const copy = reminderCopy(row, window, now);

    // Best-effort push + email. The in-app list is the ultimate safety net.
    if (await dispatchPush(row, copy)) pushed++;
    if (await dispatchEmail(supabase, row, copy)) emailed++;
  }

  // Counts only — never echo labels / numbers / user-ids (PII, GDPR Art. 33).
  return jsonResp({
    scanned: (rows ?? []).length,
    claimed,
    pushed,
    emailed,
    errors,
  });
});

/**
 * Service-to-service push via push-send. PII-free `data` payload (the client
 * deep-links via the route). Returns true only on confirmed delivery.
 */
async function dispatchPush(
  row: RenewableDocRow,
  copy: { title: string; body: string }
): Promise<boolean> {
  if (!CRON_SECRET) return false;
  try {
    const resp = await fetch(`${SUPABASE_URL}/functions/v1/push-send`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-cron-secret": CRON_SECRET,
      },
      body: JSON.stringify({
        user_id: row.user_id,
        // Reuse the deadline_reminder kind: no throttle, respects the user's
        // deadline-push opt-out — the right channel for a renewal nudge.
        kind: "deadline_reminder",
        title: copy.title,
        body: copy.body,
        data: {
          type: "renewal_reminder",
          renewal_id: row.id,
          route: "/renewals",
        },
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

/**
 * Transactional email via Resend. Looks up the user's email from profiles
 * (service-role read). PII (the user's own document label) goes only to the
 * user's own inbox — never echoed in the response. Returns true on a 2xx.
 */
async function dispatchEmail(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  row: RenewableDocRow,
  copy: { title: string; body: string }
): Promise<boolean> {
  if (!RESEND_API_KEY) return false;
  try {
    const { data: profile } = await supabase
      .from("profiles")
      .select("email")
      .eq("id", row.user_id)
      .single();
    const to = profile?.email as string | undefined;
    if (!to) return false;

    const resp = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: EMAIL_FROM,
        to: [to],
        subject: copy.title,
        text: `${copy.body}\n\nOpen Advocat → Renewals to manage this document.`,
      }),
    });
    return resp.ok;
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
