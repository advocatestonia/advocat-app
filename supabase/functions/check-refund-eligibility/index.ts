// check-refund-eligibility Edge Function
// -----------------------------------------------------------------------------
// Reports whether the currently authenticated user is still within the
// Founder's Beta refund window (14 days OR 7 AI responses, whichever comes
// first). Read-only — never mutates state.
//
// Contract:
//   POST /functions/v1/check-refund-eligibility
//   Headers:
//     Authorization: Bearer <user JWT>
//   Body: {} (or optionally { subscription_id: string } to pick a specific
//     historical subscription; defaults to the most recent active/trialing).
//
//   Response 200:
//     {
//       eligible: boolean,
//       reason: "eligible" | "deadline_passed" | "message_limit_reached",
//       deadline: string (ISO),
//       messages_used: number,
//       messages_remaining: number,
//       subscription_id: string
//     }
//   Response 404: { error: "No active subscription" }
//   Response 401: Unauthorized
//   Response 429: Rate limit exceeded
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import { evaluateRefund } from "../_shared/refund_policy.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // JWT gate + rate limit. Read-only endpoint so we allow 10/min.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "check-refund-eligibility",
    maxPerMinute: 10,
  });
  if (gate.kind === "deny") return gate.response;

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Never trust a body-supplied user_id — use gate.user.id only.
    // subscription_id is the only field read from the body.
    let subscriptionId: string | undefined;
    try {
      const body = await req.json();
      if (body && typeof body === "object") {
        const raw = body.subscription_id;
        if (typeof raw === "string" && raw.length > 0) {
          subscriptionId = raw;
        }
      }
    } catch {
      // empty body is fine
    }

    // Resolve the subscription row. If the client hinted at a specific
    // subscription_id we use it (scoped by user_id for safety); otherwise
    // take the most recent active/trialing row.
    let query = supabase
      .from("subscriptions")
      .select(
        "id, created_at, status, refund_deadline, messages_used_count, refund_eligible",
      )
      .eq("user_id", gate.user.id);

    if (subscriptionId) {
      query = query.eq("id", subscriptionId);
    } else {
      query = query.in("status", ["active", "trialing"]).order(
        "created_at",
        { ascending: false },
      );
    }

    const { data: rows, error } = await query.limit(1);
    if (error) {
      console.error(
        "check-refund-eligibility query error:",
        String(error.message ?? error).slice(0, 200),
      );
      return jsonError("Database error", 500);
    }

    if (!rows || rows.length === 0) {
      return jsonError("No active subscription", 404);
    }

    const sub = rows[0];
    const subscribedAt = new Date(sub.created_at);
    const messagesUsed = sub.messages_used_count ?? 0;
    const now = new Date();

    const evalResult = evaluateRefund({
      subscribedAt,
      messagesUsed,
      now,
    });

    return jsonOk({
      eligible: evalResult.eligible,
      reason: evalResult.reason,
      deadline: evalResult.deadline.toISOString(),
      messages_used: evalResult.messagesUsed,
      messages_remaining: evalResult.messagesRemaining,
      subscription_id: sub.id,
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error(
      "check-refund-eligibility failed:",
      message.slice(0, 200),
    );
    return jsonError("Internal error", 500);
  }
});
