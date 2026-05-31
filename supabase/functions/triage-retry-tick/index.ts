// triage-retry-tick
// -----------------------------------------------------------------------------
// Cron worker that drains app.email_triage_queue.
//
// Pulls up to BATCH_SIZE (default 10) ready rows via the claim_next_triage RPC
// (FOR UPDATE SKIP LOCKED), dispatches each one back to email-triage as an
// internal-call, and reports the outcome via complete_triage:
//
//   200 / { ok: true }        → outcome='done'
//   500 / 502 / 503 / 529 / 429 / network → outcome='retry' (exponential backoff)
//   400 / 401 / 403 / 404 / 410 / 422 → outcome='dead_letter' (config/non-transient, no point retrying)
//
// Note: email-triage returns 422 for non-transient failures (parser bug,
// missing thread, quota_exhausted) and 502 for transient ones — so the
// 422-in-dead-letter / 5xx-retry split below matches its contract.
//
// trace_id is propagated from the queue row into the email-triage call so the
// retry chain joins to the original request in app.trace_timeline.
//
// Auth: x-cron-secret header must match CRON_SECRET. Mirrors the pattern in
// agent-intentions-cron / deadline-radar-tick / alert-tick.
//
// Schedule (owner): wire up via pg_cron or an external scheduler at 60s intervals.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { checkCronSecret } from "../agent-intentions-cron/auth_gate.ts";
import {
  getOrCreateTraceId,
  newTraceId,
  propagateTraceId,
  shortTrace,
  withTrace,
} from "../_shared/tracing.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const BATCH_SIZE = Math.max(
  1,
  Math.min(50, Number(Deno.env.get("TRIAGE_RETRY_BATCH_SIZE") ?? "10")),
);

// HTTP statuses that mean "config error — no amount of retrying helps".
// 400 = bad request shape (missing thread_id, wrong payload schema)
// 401/403 = auth wedge
// 404 = thread deleted
// 410 = case archived
// 422 = email-triage non-transient failure (parse_failed_unknown,
//       thread_user_mismatch, quota_exhausted) — first-fail dead-letter,
//       no backoff. Distinct from a bare 500 (transient/unexpected → retry).
const DEAD_LETTER_STATUSES = new Set([400, 401, 403, 404, 410, 422]);

interface QueueRow {
  id: string;
  thread_id: string;
  user_id: string;
  payload: Record<string, unknown> | null;
  attempts: number;
  max_attempts: number;
  trace_id: string | null;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204 });
  }
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers: { "Content-Type": "application/json" } },
    );
  }

  // Cron-secret gate — never expose this to authenticated clients.
  const gate = checkCronSecret(
    req.headers.get("x-cron-secret"),
    Deno.env.get("CRON_SECRET"),
  );
  if (gate.kind === "deny") {
    return new Response(
      JSON.stringify(gate.body),
      { status: gate.status, headers: { "Content-Type": "application/json" } },
    );
  }

  const tickTraceId = getOrCreateTraceId(req);
  return await withTrace(tickTraceId, async () => {
    try {
      const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
      const claimed = await claimBatch(sb);
      if (claimed.length === 0) {
        return jsonOk({ ok: true, claimed: 0, done: 0, retry: 0, dead: 0 });
      }

      let done = 0;
      let retry = 0;
      let dead = 0;
      const errors: string[] = [];

      // Process sequentially: each call hits Anthropic via email-triage and
      // we want to spread cost over the 60 s tick window rather than burst
      // 10 concurrent Sonnet requests. If throughput becomes a bottleneck,
      // bump BATCH_SIZE rather than parallelise.
      for (const row of claimed) {
        const outcome = await dispatchOne(sb, row);
        if (outcome.kind === "done") done++;
        else if (outcome.kind === "retry") retry++;
        else dead++;
        if (outcome.error) errors.push(outcome.error.slice(0, 120));
      }

      return jsonOk({
        ok: true,
        claimed: claimed.length,
        done,
        retry,
        dead,
        // Cap echoed errors at 5 to keep response small; full detail lives in
        // queue.last_error per row.
        errors: errors.slice(0, 5),
      });
    } catch (e) {
      console.error("triage-retry-tick fatal:", String(e).slice(0, 300));
      return new Response(
        JSON.stringify({ error: "Internal error" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }
  });
});

// -----------------------------------------------------------------------------
// claimBatch: ask the DB for up to BATCH_SIZE ready rows.
// -----------------------------------------------------------------------------
async function claimBatch(
  // deno-lint-ignore no-explicit-any
  sb: any,
): Promise<QueueRow[]> {
  const { data, error } = await sb.rpc("claim_next_triage", {
    p_worker_id: "triage-retry-tick",
    p_batch_size: BATCH_SIZE,
  });
  if (error) {
    console.error("claim_next_triage error:", error.message);
    return [];
  }
  return (data ?? []) as QueueRow[];
}

// -----------------------------------------------------------------------------
// dispatchOne: invoke email-triage as an internal call, then mark the queue
// row done / retry / dead_letter based on the response.
// -----------------------------------------------------------------------------
interface Outcome {
  kind: "done" | "retry" | "dead_letter";
  error?: string;
}

async function dispatchOne(
  // deno-lint-ignore no-explicit-any
  sb: any,
  row: QueueRow,
): Promise<Outcome> {
  const traceId = row.trace_id ?? newTraceId();
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    "Authorization": `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
    "x-internal-call": "email-inbox-sync", // email-triage allow-list
  };
  propagateTraceId(headers, traceId);

  console.log(
    `dispatch thread=${row.thread_id} attempt=${row.attempts}/${row.max_attempts} trace=${
      shortTrace(traceId)
    }`,
  );

  try {
    const resp = await fetch(`${SUPABASE_URL}/functions/v1/email-triage`, {
      method: "POST",
      headers,
      body: JSON.stringify({
        thread_id: row.thread_id,
        user_id: row.user_id,
      }),
    });

    if (resp.ok) {
      await reportOutcome(sb, row.id, "done", null);
      return { kind: "done" };
    }

    const bodyText = await resp.text();
    const err = `${resp.status}:${bodyText.slice(0, 160)}`;
    if (DEAD_LETTER_STATUSES.has(resp.status)) {
      await reportOutcome(sb, row.id, "dead_letter", err);
      return { kind: "dead_letter", error: err };
    }
    // 429 / 5xx / 529 / 502 / 503 → exponential-backoff retry.
    await reportOutcome(sb, row.id, "retry", err);
    return { kind: "retry", error: err };
  } catch (e) {
    // Network failure — retry.
    const err = `network:${String(e).slice(0, 160)}`;
    await reportOutcome(sb, row.id, "retry", err);
    return { kind: "retry", error: err };
  }
}

async function reportOutcome(
  // deno-lint-ignore no-explicit-any
  sb: any,
  queueId: string,
  outcome: "done" | "retry" | "dead_letter",
  error: string | null,
): Promise<void> {
  try {
    const { error: rpcErr } = await sb.rpc("complete_triage", {
      p_id: queueId,
      p_outcome: outcome,
      p_error: error,
    });
    if (rpcErr) {
      console.error(
        `complete_triage outcome=${outcome} failed:`,
        rpcErr.message,
      );
    }
  } catch (e) {
    console.error(
      `complete_triage outcome=${outcome} threw:`,
      String(e).slice(0, 200),
    );
  }
}

function jsonOk(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
