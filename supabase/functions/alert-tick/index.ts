// alert-tick — DEPT 7 alert pipeline.
// -----------------------------------------------------------------------------
// pg_cron-driven edge function. Runs every 60s. Evaluates 5 alert conditions,
// POSTs structured Slack messages to `SLACK_WEBHOOK_URL`, and de-dupes via
// `public.recent_alerts` (10-min cooldown per alert key).
//
// Alerts:
//   A) claude-proxy 5xx rate > 2% / 5 min  (count from error_log)
//   B) Anthropic hourly spend > $20.83     (delta from spend_hourly_snapshot)
//   C) Signup error rate > 5% / 10 min     (auth.users vs error_log)
//   D) Stripe webhook delivery failure     (webhook_events status='error')
//   E) RAG empty-result spike              (error_log message='rag_empty')
//
// Failure mode policy:
//   - Each alert is evaluated in its own try/catch. A failed query for one
//     alert never blocks the others (and never 5xxs the tick — pg_cron retries
//     are pointless here, the next tick is 60s away).
//   - SLACK_WEBHOOK_URL unset → log + return 200 (so the cron job doesn't
//     accumulate failure rows). Owner enables Slack when ready.
//
// Spec source: .consilium/2026-05-20/dept7_runbook.md §2.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { checkCronSecret } from "./auth_gate.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const CRON_SECRET = Deno.env.get("CRON_SECRET");
const SLACK_WEBHOOK_URL = Deno.env.get("SLACK_WEBHOOK_URL");
const SLACK_CHANNEL = Deno.env.get("SLACK_CHANNEL") ?? "#advocat-alerts";

// Thresholds (kept in code so they're trivial to tune via redeploy — no DB
// trip on every tick). Numbers mirror the DEPT 7 runbook.
const T = {
  PROXY_5XX_ERRORS_5M: 10,         // ≈ 2% at expected 500 req/5min traffic
  HOURLY_SPEND_CENTS: 2083,        // $20.83 = $500/day cap / 24
  SIGNUP_FAIL_RATIO: 0.05,         // 5%
  SIGNUP_FAIL_FLOOR: 3,            // need >=3 absolute failures before firing
  STRIPE_FAILS_15M: 2,             // Stripe retries; 2 distinct = real problem
  RAG_EMPTY_5M: 10,                // ≥10 empty hits in 5 min = corpus offline
  DEDUP_MINUTES: 10,               // skip if same alert fired in last 10 min
};

type AlertKey = "A_proxy_5xx" | "B_anthropic_spend" | "C_signup_errors" |
                "D_stripe_webhook" | "E_rag_empty";

interface AlertResult {
  key: AlertKey;
  name: string;
  metric: string;     // human-readable "10 errors in 5 min"
  details: Record<string, unknown>;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204 });
  if (req.method !== "POST") return jsonResp({ error: "Method not allowed" }, 405);

  const gate = checkCronSecret(req.headers.get("x-cron-secret"), CRON_SECRET);
  if (gate.kind === "deny") return jsonResp(gate.body, gate.status);

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const fired: AlertResult[] = [];
  const errors: string[] = [];

  await runSafely(errors, "A", async () => {
    const a = await checkProxy5xx(supabase);
    if (a) fired.push(a);
  });
  await runSafely(errors, "B", async () => {
    const b = await checkAnthropicSpend(supabase);
    if (b) fired.push(b);
  });
  await runSafely(errors, "C", async () => {
    const c = await checkSignupErrors(supabase);
    if (c) fired.push(c);
  });
  await runSafely(errors, "D", async () => {
    const d = await checkStripeWebhookFailures(supabase);
    if (d) fired.push(d);
  });
  await runSafely(errors, "E", async () => {
    const e = await checkRagEmpty(supabase);
    if (e) fired.push(e);
  });

  // Apply de-dup + POST to Slack. Each post is independent so a single
  // Slack outage doesn't block the rest of the tick.
  const posted: AlertKey[] = [];
  for (const alert of fired) {
    const dedupKey = `alert_${alert.key}`;
    const shouldFire = await reserveAlertSlot(supabase, dedupKey);
    if (!shouldFire) continue;
    try {
      await postToSlack(alert);
      posted.push(alert.key);
    } catch (e) {
      errors.push(`slack_${alert.key}: ${truncate(String(e), 200)}`);
    }
  }

  return jsonResp({
    ok: true,
    evaluated: 5,
    fired: fired.map((a) => a.key),
    posted,
    errors,
    ts: new Date().toISOString(),
  }, 200);
});

// ── Alert A: claude-proxy 5xx rate ─────────────────────────────────────
async function checkProxy5xx(sb: SupabaseClient): Promise<AlertResult | null> {
  const since = new Date(Date.now() - 5 * 60 * 1000).toISOString();
  const { count, error } = await sb
    .from("error_log")
    .select("id", { count: "exact", head: true })
    .eq("fn_name", "claude-proxy")
    .gte("status_code", 500)
    .gte("occurred_at", since);
  if (error) throw error;
  const n = count ?? 0;
  if (n < T.PROXY_5XX_ERRORS_5M) return null;
  return {
    key: "A_proxy_5xx",
    name: "claude-proxy 5xx spike",
    metric: `${n} 5xx in 5m (threshold ${T.PROXY_5XX_ERRORS_5M})`,
    details: { errors_5m: n, threshold: T.PROXY_5XX_ERRORS_5M, since },
  };
}

// ── Alert B: Anthropic hourly spend ────────────────────────────────────
async function checkAnthropicSpend(sb: SupabaseClient): Promise<AlertResult | null> {
  // Pull the two most recent snapshot rows. Delta = current_cumulative
  // − previous_cumulative. The :00 cron writes one row/hour, so the
  // delta represents one full hour of burn.
  const { data, error } = await sb
    .from("spend_hourly_snapshot")
    .select("hour, cumulative_cents")
    .order("hour", { ascending: false })
    .limit(2);
  if (error) throw error;
  if (!data || data.length < 2) return null;
  const [latest, prev] = data;
  const deltaCents = Number(latest.cumulative_cents) - Number(prev.cumulative_cents);
  if (deltaCents < T.HOURLY_SPEND_CENTS) return null;
  return {
    key: "B_anthropic_spend",
    name: "Anthropic hourly spend over budget",
    metric: `$${(deltaCents / 100).toFixed(2)}/h (threshold $${(T.HOURLY_SPEND_CENTS / 100).toFixed(2)}/h)`,
    details: {
      delta_cents: deltaCents,
      latest_hour: latest.hour,
      prev_hour: prev.hour,
      threshold_cents: T.HOURLY_SPEND_CENTS,
    },
  };
}

// ── Alert C: signup error rate ─────────────────────────────────────────
async function checkSignupErrors(sb: SupabaseClient): Promise<AlertResult | null> {
  const since = new Date(Date.now() - 10 * 60 * 1000).toISOString();
  // auth.users is only reachable via service-role; the rpc avoids a
  // cross-schema-select dance from PostgREST. Fall back to error_log-only
  // ratio if the count query fails — we still detect runaway failure spikes.
  const okPromise = sb.schema("auth").from("users")
    .select("id", { count: "exact", head: true })
    .gte("created_at", since);
  const failPromise = sb.from("error_log")
    .select("id", { count: "exact", head: true })
    .eq("fn_name", "oauth-callback")
    .gte("occurred_at", since);
  const [okRes, failRes] = await Promise.all([okPromise, failPromise]);
  if (failRes.error) throw failRes.error;
  const ok = okRes.error ? 0 : (okRes.count ?? 0);
  const fail = failRes.count ?? 0;
  if (fail < T.SIGNUP_FAIL_FLOOR) return null;
  const ratio = fail / Math.max(ok + fail, 1);
  if (ratio <= T.SIGNUP_FAIL_RATIO) return null;
  return {
    key: "C_signup_errors",
    name: "Signup error rate over 5%",
    metric: `${(ratio * 100).toFixed(1)}% (${fail} fail / ${ok + fail} attempts, last 10m)`,
    details: { fail, ok, ratio, since, threshold: T.SIGNUP_FAIL_RATIO },
  };
}

// ── Alert D: Stripe webhook delivery failure ───────────────────────────
async function checkStripeWebhookFailures(sb: SupabaseClient): Promise<AlertResult | null> {
  const since = new Date(Date.now() - 15 * 60 * 1000).toISOString();
  // Two sources of truth for "Stripe-side failure":
  //   1. Our audit table `webhook_events` flips to status='error' when the
  //      handler itself rejected the event (signature mismatch, idempotency
  //      collision, DB write failed).
  //   2. error_log rows from stripe-webhook with severity ∈ {error, critical}
  //      catch upstream exceptions before the audit row is written.
  // We OR-count both to defend against either path silently breaking.
  const auditPromise = sb.from("webhook_events")
    .select("event_id", { count: "exact", head: true })
    .eq("status", "error")
    .gte("received_at", since);
  const errLogPromise = sb.from("error_log")
    .select("id", { count: "exact", head: true })
    .eq("fn_name", "stripe-webhook")
    .in("severity", ["error", "critical"])
    .gte("occurred_at", since);
  const [auditRes, errLogRes] = await Promise.all([auditPromise, errLogPromise]);
  const audit = auditRes.error ? 0 : (auditRes.count ?? 0);
  const errLog = errLogRes.error ? 0 : (errLogRes.count ?? 0);
  const total = audit + errLog;
  if (total < T.STRIPE_FAILS_15M) return null;
  return {
    key: "D_stripe_webhook",
    name: "Stripe webhook delivery failures",
    metric: `${total} failures in 15m (audit=${audit}, error_log=${errLog})`,
    details: { audit_failures: audit, error_log_failures: errLog, since },
  };
}

// ── Alert E: RAG empty-result spike ────────────────────────────────────
async function checkRagEmpty(sb: SupabaseClient): Promise<AlertResult | null> {
  const since = new Date(Date.now() - 5 * 60 * 1000).toISOString();
  const { count, error } = await sb.from("error_log")
    .select("id", { count: "exact", head: true })
    .eq("fn_name", "claude-proxy")
    .eq("message", "rag_empty")
    .gte("occurred_at", since);
  if (error) throw error;
  const n = count ?? 0;
  if (n < T.RAG_EMPTY_5M) return null;
  return {
    key: "E_rag_empty",
    name: "RAG empty-result spike (corpus likely offline)",
    metric: `${n} empty results in 5m (threshold ${T.RAG_EMPTY_5M})`,
    details: { rag_empty_5m: n, threshold: T.RAG_EMPTY_5M, since },
  };
}

// ── De-dup: returns true if the slot was reserved (alert should fire). ──
async function reserveAlertSlot(sb: SupabaseClient, alertKey: string): Promise<boolean> {
  const cutoff = new Date(Date.now() - T.DEDUP_MINUTES * 60 * 1000).toISOString();
  const { data: existing } = await sb.from("recent_alerts")
    .select("alert_key, fired_at")
    .eq("alert_key", alertKey)
    .gte("fired_at", cutoff)
    .maybeSingle();
  if (existing) return false;
  // Upsert (overwrite stale rows from >10 min ago).
  const { error } = await sb.from("recent_alerts").upsert(
    { alert_key: alertKey, fired_at: new Date().toISOString() },
    { onConflict: "alert_key" },
  );
  if (error) {
    console.warn(`alert-tick: recent_alerts upsert failed: ${error.message}`);
    // Fail open — better a duplicate Slack ping than a silent miss.
  }
  return true;
}

// ── Slack POST ─────────────────────────────────────────────────────────
async function postToSlack(alert: AlertResult): Promise<void> {
  if (!SLACK_WEBHOOK_URL) {
    console.warn(`alert-tick: SLACK_WEBHOOK_URL unset — skipping ${alert.key}`);
    return;
  }
  const payload = {
    channel: SLACK_CHANNEL,
    text: `ALERT: ${alert.name}`,
    blocks: [
      {
        type: "header",
        text: { type: "plain_text", text: `🚨 ${alert.name}`, emoji: true },
      },
      {
        type: "section",
        fields: [
          { type: "mrkdwn", text: `*Metric*\n${alert.metric}` },
          { type: "mrkdwn", text: `*Key*\n\`${alert.key}\`` },
        ],
      },
      {
        type: "context",
        elements: [{
          type: "mrkdwn",
          text: `Details: \`${truncate(JSON.stringify(alert.details), 280)}\` • ` +
                `t=${new Date().toISOString()} • cooldown ${T.DEDUP_MINUTES}m`,
        }],
      },
    ],
  };
  const res = await fetch(SLACK_WEBHOOK_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    throw new Error(`slack_http_${res.status}`);
  }
}

// ── helpers ────────────────────────────────────────────────────────────
async function runSafely(errBucket: string[], label: string, fn: () => Promise<void>) {
  try {
    await fn();
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    errBucket.push(`alert_${label}: ${truncate(msg, 200)}`);
    console.warn(`alert-tick: alert_${label} failed: ${msg}`);
  }
}

function truncate(s: string, max: number): string {
  return s.length <= max ? s : s.slice(0, max - 1) + "…";
}

function jsonResp(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
