// breach-tick — Data Fortress breach-detection cron.
// ----------------------------------------------------------------------------
// pg_cron-driven edge function (suggested: every 5 min). Evaluates the
// anomaly detectors over the Pillar-3 access log, records each fired alert in
// the append-only breach_alerts table (which establishes T0 for the Art. 33
// 72h clock), and notifies Slack. The affected data subject sees the breach
// via get_my_breach_alerts() (Art. 34 transparency).
//
// Closes the #1 readiness gap from the IR-plan: detection is now automatic,
// not "wait for a human to notice".
//
// Auth: x-cron-secret (same gate as alert-tick / the other crons). MUST be
// deployed with --no-verify-jwt (it's a cron/service endpoint).
// SLACK_WEBHOOK_URL unset → log + 200 (cron stays green).
// ----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { checkCronSecret } from "../alert-tick/auth_gate.ts";
import {
  type BreachAlert,
  fromMassRead,
  fromStaffAccess,
} from "./detectors.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const CRON_SECRET = Deno.env.get("CRON_SECRET");
const SLACK_WEBHOOK_URL = Deno.env.get("SLACK_WEBHOOK_URL");

// Thresholds in code so they're tunable via redeploy.
const MASS_READ_WINDOW_MIN = 10;
const MASS_READ_THRESHOLD = 100; // > this many sensitive reads / window = exfil signature
const STAFF_WINDOW_MIN = 60;

function jsonResp(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204 });
  if (req.method !== "POST") {
    return jsonResp({ error: "Method not allowed" }, 405);
  }

  const gate = checkCronSecret(req.headers.get("x-cron-secret"), CRON_SECRET);
  if (gate.kind === "deny") return jsonResp(gate.body, gate.status);

  const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const nowIso = new Date().toISOString();
  const alerts: BreachAlert[] = [];
  const errors: string[] = [];

  // A. mass_read
  try {
    const { data, error } = await sb.rpc("detect_mass_read", {
      p_window_minutes: MASS_READ_WINDOW_MIN,
      p_threshold: MASS_READ_THRESHOLD,
    });
    if (error) throw error;
    alerts.push(
      ...fromMassRead(
        (data ?? []) as Array<{ affected_user: string; event_count: number }>,
        MASS_READ_WINDOW_MIN,
        MASS_READ_THRESHOLD,
        nowIso
      )
    );
  } catch (e) {
    errors.push(`mass_read: ${String(e).slice(0, 160)}`);
  }

  // B. staff_offsession
  try {
    const { data, error } = await sb.rpc("detect_staff_access", {
      p_window_minutes: STAFF_WINDOW_MIN,
    });
    if (error) throw error;
    alerts.push(
      ...fromStaffAccess(
        (data ?? []) as Array<{
          affected_user: string;
          action: string;
          event_count: number;
        }>,
        STAFF_WINDOW_MIN,
        nowIso
      )
    );
  } catch (e) {
    errors.push(`staff_access: ${String(e).slice(0, 160)}`);
  }

  // Record each alert (dedup handled by the unique index + ON CONFLICT) and
  // notify. recorded=true means it was NEW (not a dedup), so we only Slack new.
  const recorded: string[] = [];
  for (const a of alerts) {
    try {
      const { data: id, error } = await sb.rpc("record_breach_alert", {
        p_kind: a.kind,
        p_severity: a.severity,
        p_actor: a.actor,
        p_affected_user: a.affectedUser,
        p_evidence: a.evidence,
        p_dedup_key: a.dedupKey,
      });
      if (error) throw error;
      if (id) {
        recorded.push(a.dedupKey);
        await notifySlack(a).catch((e) =>
          errors.push(`slack ${a.dedupKey}: ${String(e).slice(0, 120)}`)
        );
      }
    } catch (e) {
      errors.push(`record ${a.dedupKey}: ${String(e).slice(0, 160)}`);
    }
  }

  return jsonResp({
    ok: true,
    evaluated: 2,
    fired: alerts.map((a) => a.dedupKey),
    recorded,
    errors,
    ts: nowIso,
  });
});

async function notifySlack(a: BreachAlert): Promise<void> {
  if (!SLACK_WEBHOOK_URL) {
    console.warn(
      `[breach-tick] (no Slack) ${a.severity} ${a.kind} ${a.dedupKey}`
    );
    return;
  }
  const text =
    `:rotating_light: *BREACH DETECTED* — ${a.kind} (${a.severity})\n` +
    `affected_user: ${a.affectedUser ?? "n/a"} · actor: ${a.actor ?? "n/a"}\n` +
    `evidence: \`${JSON.stringify(a.evidence)}\`\n` +
    `⏱️ This starts the GDPR Art. 33 72h assessment clock — see IR-plan.`;
  const res = await fetch(SLACK_WEBHOOK_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ text }),
  });
  if (!res.ok) throw new Error(`Slack HTTP ${res.status}`);
}
