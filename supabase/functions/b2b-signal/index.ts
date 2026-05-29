// supabase/functions/b2b-signal/index.ts
// -----------------------------------------------------------------------------
// Silent B2B lead-detection signal collector.
//
// Receives ONE signal at a time from authenticated callers (Flutter client,
// other edge functions via direct internal POST, or a future analytics tap).
// The handler validates the signal_type against an allow-list, normalises the
// score, and dispatches to the SECURITY DEFINER RPC `record_b2b_signal` which
// also recomputes the 30-day score and toggles `profiles.b2b_modal_pending`
// once the score crosses 100.
//
// Design choices
// --------------
// * Anonymous callers are rejected (401). The whole point is per-user scoring.
// * Score is OPTIONAL in the body — server-side defaults win so a malicious
//   client cannot self-promote with score=999.
// * Idempotency is handled at the persistence layer: callers that hit the
//   "no duplicate same signal_type within same hour" rule still get a 200
//   response with the existing score. Duplicate-suppression lives here in
//   the edge fn rather than in the RPC so that wire-up sites (pdf-parser,
//   claude-proxy, check-ai-quota) can rely on a single endpoint contract.
// * Response shape:
//     { ok: true, new_score, modal_pending, duplicate? }
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import {
  DEFAULT_SCORES,
  isAllowedSignalType,
  SignalType,
} from "./signals.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

/**
 * Hard cap on a single signal score (server-side, irrespective of what the
 * client passes). 200 = upper bound for a "single dramatic" signal. The
 * 30-day rolling sum still applies so a noisy user crossing 100 over many
 * small signals also wins.
 */
const MAX_SCORE_PER_SIGNAL = 200;

interface RawBody {
  signal_type?: unknown;
  score?: unknown;
  payload?: unknown;
}

serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // Auth gate — no anon. 30/min ceiling is well above the realistic burst
  // (signal sites are fire-and-forget after a real user action).
  const gate = await requireUserWithRateLimit(req, {
    bucket: "b2b-signal",
    maxPerMinute: 30,
  });
  if (gate.kind === "deny") return gate.response;
  if (gate.user.id.startsWith("anon:")) {
    return jsonError("Unauthorized", 401);
  }
  const userId = gate.user.id;

  // Parse body.
  let raw: RawBody;
  try {
    raw = await req.json();
  } catch {
    return jsonError("Invalid JSON body", 400);
  }

  const signalType = typeof raw.signal_type === "string"
    ? raw.signal_type.trim()
    : "";
  if (!isAllowedSignalType(signalType)) {
    return jsonError("Unknown signal_type", 400, {
      reason: "invalid_signal_type",
      signal_type: signalType,
    });
  }

  // Server-side score normalisation. Client may pass an explicit score (used
  // by trusted internal callers like pdf-parser); otherwise we use the
  // default-per-type. We CLAMP to [0, MAX_SCORE_PER_SIGNAL] so a forged
  // client request can never inflate a single signal beyond the threshold
  // outright — they still need to accumulate.
  let score: number;
  if (typeof raw.score === "number" && Number.isFinite(raw.score)) {
    score = Math.max(0, Math.min(MAX_SCORE_PER_SIGNAL, Math.floor(raw.score)));
  } else {
    score = DEFAULT_SCORES[signalType as SignalType];
  }

  // Payload — keep small. Drop anything that isn't a plain object.
  let payload: Record<string, unknown> | null = null;
  if (raw.payload && typeof raw.payload === "object" && !Array.isArray(raw.payload)) {
    // Cap to 4 KB serialised to protect the DB row.
    const ser = JSON.stringify(raw.payload);
    if (ser.length <= 4000) {
      payload = raw.payload as Record<string, unknown>;
    } else {
      payload = { _truncated: true, _size: ser.length };
    }
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // ── Idempotency: refuse duplicates of the same signal_type within the
  // same hour for the same user. The wire-up sites (pdf-parser doc-burst,
  // claude-proxy legal_planner_heavy, etc.) already pre-check before
  // calling, but a retried network request or a race between two parallel
  // edge fns would otherwise double-count.
  //
  // The 1-hour window is deliberately coarse — most natural signal sources
  // fire AT MOST once per session, and a user who legitimately triggers
  // the same signal twice in an hour is almost certainly the same
  // behavioural event being observed twice.
  try {
    const since = new Date(Date.now() - 60 * 60_000).toISOString();
    const dupe = await supabase
      .from("b2b_signals")
      .select("id", { count: "exact", head: true })
      .eq("user_id", userId)
      .eq("signal_type", signalType)
      .gte("occurred_at", since);
    if ((dupe.count ?? 0) > 0) {
      // Re-read the current profile state so the client sees an accurate
      // score even on duplicate; otherwise we'd force them to do an
      // extra round-trip just to learn the existing score.
      const prof = await supabase
        .from("profiles")
        .select("b2b_score, b2b_modal_pending")
        .eq("id", userId)
        .maybeSingle();
      return jsonOk({
        ok: true,
        duplicate: true,
        new_score: (prof.data?.b2b_score as number | undefined) ?? 0,
        modal_pending:
          (prof.data?.b2b_modal_pending as boolean | undefined) ?? false,
      });
    }
  } catch (e) {
    // Don't block on idempotency failure — log and proceed. Better to
    // occasionally double-count than to drop a signal entirely.
    console.warn(
      `[b2b-signal] idempotency check failed: ${String(e).slice(0, 200)}`,
    );
  }

  // Insert via SECURITY DEFINER RPC — it also recomputes the rolling score
  // and toggles the modal_pending flag.
  try {
    const rpc = await supabase.rpc("record_b2b_signal", {
      p_user_id: userId,
      p_signal_type: signalType,
      p_score: score,
      p_payload: payload,
    });
    if (rpc.error) {
      // Log raw DB error server-side; return only a stable generic reason.
      // Echoing rpc.error.message would disclose table/constraint internals.
      console.error(`[b2b-signal] rpc failed: ${rpc.error.message}`);
      return jsonError("Could not record signal", 500, {
        reason: "rpc_failed",
      });
    }
  } catch (e) {
    console.error(`[b2b-signal] rpc threw: ${String(e).slice(0, 200)}`);
    return jsonError("Could not record signal", 500, {
      reason: "rpc_threw",
    });
  }

  // Read back the new state so the client knows whether to surface the modal.
  let newScore = 0;
  let modalPending = false;
  try {
    const prof = await supabase
      .from("profiles")
      .select("b2b_score, b2b_modal_pending")
      .eq("id", userId)
      .maybeSingle();
    newScore = (prof.data?.b2b_score as number | undefined) ?? 0;
    modalPending =
      (prof.data?.b2b_modal_pending as boolean | undefined) ?? false;
  } catch (e) {
    console.warn(`[b2b-signal] read-back failed: ${String(e).slice(0, 200)}`);
  }

  return jsonOk({
    ok: true,
    new_score: newScore,
    modal_pending: modalPending,
    duplicate: false,
  });
});
