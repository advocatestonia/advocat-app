// agent-approve — Day 4 (2026-05-27) of agent-loop MVP.
// -----------------------------------------------------------------------------
// When claude-proxy halts its agent loop on a WRITE tool, it persists an
// agent_runs row (status='awaiting_approval') + emits an SSE event with
// an HMAC-signed action_id. The Flutter chat UI renders a tool-card with
// Approve / Decline buttons. Tapping Approve POSTs here.
//
// Server-side flow:
//   1. Validate POST + caller JWT.
//   2. Look up the agent_runs row by id. Confirm:
//        - row.user_id == auth.user.id (RLS belt+suspenders)
//        - row.status == 'awaiting_approval'
//        - row.write_pending IS NOT NULL
//   3. Re-compute args_sha256 from row.write_pending.tool_input.
//   4. verifyActionId — checks HMAC + TTL + tool_name + args_sha256
//      bindings. Any mismatch returns 409.
//   5. Dispatch the write tool via executeToolCalls (reuses every
//      defensive guard already in tool_handlers.ts).
//   6. Update agent_runs.status='completed', record completed_at + the
//      audit_trail tail entry.
//   7. Return the tool_result content to the client (Flutter will append
//      it to the chat history as a final agent message).
//
// Decline flow: POST { action_id, run_id, decision: 'decline' } updates
// status='rejected', NO write is executed. Returns 200 with no side-effect.
//
// Contract:
//   POST /functions/v1/agent-approve
//   Authorization: Bearer <user JWT>
//   Content-Type: application/json
//   Body:
//     { run_id: uuid, action_id: string, decision?: 'approve'|'decline' }
//
//   200 OK on approve:
//     { ok: true, executed: true, tool_result: { ... } }
//   200 OK on decline:
//     { ok: true, executed: false, decision: 'declined' }
//   400  malformed body
//   401  no/bad JWT
//   404  run_id not found / not owned by caller
//   409  HMAC verify failed / row state mismatch
//   422  write_pending missing (already executed)
//   429  rate limit
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

import {
  corsHeaders,
  jsonError,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import {
  hashToolInput,
  verifyActionId,
} from "../_shared/agent_action.ts";
import { executeToolCalls } from "../claude-proxy/tool_handlers.ts";
import { withSentry } from "../_shared/sentry.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const EMAIL_AGENT_GATE_SECRET = Deno.env.get("EMAIL_AGENT_GATE_SECRET") ?? "";

interface ApproveBody {
  run_id?: string;
  action_id?: string;
  decision?: "approve" | "decline";
}

function jsonOk(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

serve(withSentry("agent-approve", async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }
  const gate = await requireUserWithRateLimit(req, {
    bucket: "agent-approve",
    maxPerMinute: 30,
  });
  if (gate.kind === "deny") return gate.response;

  if (!EMAIL_AGENT_GATE_SECRET) {
    return jsonError("agent-approve: EMAIL_AGENT_GATE_SECRET not configured", 503);
  }

  let body: ApproveBody;
  try {
    body = (await req.json()) as ApproveBody;
  } catch (_e) {
    return jsonError("Invalid JSON body", 400);
  }
  const runId = (body.run_id ?? "").trim();
  const actionId = (body.action_id ?? "").trim();
  const decision = body.decision === "decline" ? "decline" : "approve";
  if (!runId || !actionId) {
    return jsonError("run_id and action_id required", 400);
  }

  const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // Fetch the row. Service-role bypasses RLS — we enforce owner equality
  // manually below.
  const { data: row, error: rowErr } = await sb
    .from("agent_runs")
    .select("id, user_id, status, write_pending, audit_trail")
    .eq("id", runId)
    .maybeSingle();
  if (rowErr) return jsonError(`agent_runs lookup: ${rowErr.message}`, 500);
  if (!row) return jsonError("run_id not found", 404);
  const r = row as unknown as {
    id: string;
    user_id: string;
    status: string;
    write_pending: Record<string, unknown> | null;
    audit_trail: Array<Record<string, unknown>>;
  };
  if (r.user_id !== gate.user.id) return jsonError("forbidden", 404);
  if (r.status !== "awaiting_approval") {
    return jsonError(
      `run is not awaiting approval (status=${r.status})`,
      422,
    );
  }
  if (!r.write_pending) {
    return jsonError("write_pending missing", 422);
  }
  const pending = r.write_pending as {
    tool_use_id: string;
    tool_name: string;
    tool_input: Record<string, unknown>;
    args_sha256: string;
    action_id: string;
  };

  // Decline path — no write fires.
  if (decision === "decline") {
    await sb
      .from("agent_runs")
      .update({
        status: "rejected",
        write_pending: null,
        completed_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        audit_trail: [
          ...(r.audit_trail ?? []),
          {
            iter: (r.audit_trail?.length ?? 0) + 1,
            tool: pending.tool_name,
            decision: "declined",
            at: new Date().toISOString(),
          },
        ],
      })
      .eq("id", runId);
    return jsonOk({ ok: true, executed: false, decision: "declined" });
  }

  // Approve path — verify HMAC + execute.
  //
  // hashToolInput uses canonical-JSON serialisation (W2-09 fix) so the
  // hash survives the JSONB round-trip Postgres did when persisting
  // pending.tool_input. It also projects user-visible fields (to,
  // subject, body_length, ...) for known write tools (F-008 binding).
  const recomputedArgsSha = await hashToolInput(
    pending.tool_input,
    pending.tool_name,
  );
  if (recomputedArgsSha !== pending.args_sha256) {
    // Persisted args differ from what was originally signed — defence
    // against a malicious update to the DB row. Should not happen via
    // RLS, but belt+suspenders.
    return jsonError("persisted args drift detected", 409);
  }
  const verify = await verifyActionId({
    token: actionId,
    expected_agent_run_id: runId,
    expected_user_id: gate.user.id,
    expected_tool_name: pending.tool_name,
    expected_args_sha256: pending.args_sha256,
    secret: EMAIL_AGENT_GATE_SECRET,
  });
  if (!verify.ok) {
    return jsonError(`action_id verify: ${verify.reason}`, 409);
  }

  // Dispatch the write via the regular tool_handlers pipeline. The auth
  // header from the caller's request is forwarded so handlers that need
  // it (send_email) authenticate properly downstream.
  const authHeader = req.headers.get("Authorization") ?? "";
  const results = await executeToolCalls(
    [
      {
        type: "tool_use",
        id: pending.tool_use_id,
        name: pending.tool_name,
        input: pending.tool_input,
      },
    ],
    authHeader,
    gate.user.id,
  );
  const toolResult = results[0] ?? null;
  const executedOk = toolResult && toolResult.is_error !== true;

  await sb
    .from("agent_runs")
    .update({
      status: executedOk ? "completed" : "errored",
      write_pending: null,
      completed_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      audit_trail: [
        ...(r.audit_trail ?? []),
        {
          iter: (r.audit_trail?.length ?? 0) + 1,
          tool: pending.tool_name,
          decision: "approved",
          executed_ok: !!executedOk,
          at: new Date().toISOString(),
        },
      ],
    })
    .eq("id", runId);

  return jsonOk({
    ok: !!executedOk,
    executed: true,
    decision: "approved",
    tool_result: toolResult,
  });
}));
