// remove-member Edge Function
// -----------------------------------------------------------------------------
// Owner / admin soft-removes a member. Optionally reassigns the removed
// member's work-product (cases, documents, deadlines) to another member.
//
// "Soft removal" means org_members.removed_at = now(); the user keeps their
// auth account, just loses access to the org. Their personal B2C data and
// other org memberships are untouched.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import { requireOrgContext } from "../_shared/orgAuth.ts";
import { writeOrgAudit } from "../_shared/auditLog.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY") ?? "";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

interface RemoveBody {
  member_user_id?: string;
  reassign_data_to?: string | null;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  const gate = await requireUserWithRateLimit(req, {
    bucket: "remove-member",
    maxPerMinute: 30,
  });
  if (gate.kind === "deny") return gate.response;

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const orgGate = await requireOrgContext(
    req,
    supabase,
    gate.user.id,
    gate.user.email,
    { minRole: "admin" },
  );
  if (orgGate.kind === "deny") return orgGate.response;
  const ctx = orgGate.ctx;

  let body: RemoveBody;
  try {
    body = await req.json();
  } catch {
    return jsonError("Invalid JSON body", 400, { reason: "invalid_json" });
  }

  const memberUserId = (body.member_user_id ?? "").trim();
  const reassignTo = body.reassign_data_to ? body.reassign_data_to.trim() : null;

  if (!UUID_RE.test(memberUserId)) {
    return jsonError("Invalid member_user_id", 400, {
      reason: "invalid_member_id",
    });
  }
  if (reassignTo && !UUID_RE.test(reassignTo)) {
    return jsonError("Invalid reassign_data_to", 400, {
      reason: "invalid_reassign_target",
    });
  }
  if (memberUserId === ctx.user_id) {
    return jsonError("Cannot remove yourself; leave-org is a separate flow", 400, {
      reason: "cannot_remove_self",
    });
  }

  // ── Target lookup ─────────────────────────────────────────────────────
  const { data: target } = await supabase
    .from("org_members")
    .select("id, role")
    .eq("org_id", ctx.org_id)
    .eq("user_id", memberUserId)
    .is("removed_at", null)
    .maybeSingle();
  if (!target) {
    return jsonError("Member not found", 404, { reason: "not_a_member" });
  }

  // Cannot remove the last owner.
  if (target.role === "owner") {
    const { count } = await supabase
      .from("org_members")
      .select("id", { count: "exact", head: true })
      .eq("org_id", ctx.org_id)
      .eq("role", "owner")
      .is("removed_at", null);
    if ((count ?? 0) <= 1) {
      return jsonError("Cannot remove the only owner", 409, {
        reason: "cannot_remove_only_owner",
      });
    }
  }

  // Reassign target must also be an active member of this org.
  if (reassignTo) {
    const { data: rTarget } = await supabase
      .from("org_members")
      .select("id")
      .eq("org_id", ctx.org_id)
      .eq("user_id", reassignTo)
      .is("removed_at", null)
      .maybeSingle();
    if (!rTarget) {
      return jsonError("Reassign target is not a member", 409, {
        reason: "reassign_target_not_member",
      });
    }
  }

  // ── Reassign data (SECURITY DEFINER RPC encapsulates the bulk UPDATEs) ─
  // MUST run (and succeed) BEFORE the soft-remove below: if reassignment fails
  // but we still remove the member, their cases/documents/deadlines are
  // orphaned (owned by a user who no longer has org access).
  if (reassignTo) {
    // deno-lint-ignore no-explicit-any
    const { error: reassignErr } = await (supabase as any).rpc(
      "reassign_org_user_data",
      {
        p_org_id: ctx.org_id,
        p_from_user: memberUserId,
        p_to_user: reassignTo,
      },
    );
    if (reassignErr) {
      // A MISSING RPC (not yet defined in a migration) must NOT be swallowed:
      // the admin explicitly asked to reassign this member's work-product, and
      // silently skipping it while still removing the member orphans that data
      // behind a 200 OK. Refuse loudly so the caller can retry without the
      // reassign flag (or wait until the RPC is deployed) rather than lose the
      // data pointer. Treated as 501 (capability unavailable) vs 500 for a
      // genuine reassignment error.
      const missing = `${reassignErr.message}`.includes("does not exist");
      console.error("[remove-member] reassign RPC failed:", reassignErr);
      return jsonError(
        missing
          ? "Data reassignment is not available; remove without reassignment or contact support"
          : "Data reassignment failed",
        missing ? 501 : 500,
        { reason: missing ? "reassign_unavailable" : "reassign_failed" },
      );
    }
  }

  // ── Soft-remove + decrement seat count ────────────────────────────────
  // Prefer atomic RPC; fall back to two updates.
  let newSeatCount: number | null = null;
  try {
    // deno-lint-ignore no-explicit-any
    const { data: rpcOut, error: rpcErr } = await (supabase as any).rpc(
      "org_remove_member",
      {
        p_org_id: ctx.org_id,
        p_user_id: memberUserId,
      },
    );
    if (!rpcErr && rpcOut) {
      const row = Array.isArray(rpcOut) ? rpcOut[0] : rpcOut;
      newSeatCount = row?.seat_count ?? null;
    } else if (rpcErr && !`${rpcErr.message}`.includes("does not exist")) {
      console.error("[remove-member] RPC failed:", rpcErr);
      return jsonError("Remove failed", 500, { reason: "rpc_failed" });
    }
  } catch (e) {
    console.warn("[remove-member] RPC threw, falling back:", e);
  }

  if (newSeatCount === null) {
    // Fallback (runs when org_remove_member RPC is absent — the case in prod
    // today). CLAIM the removal via a conditional UPDATE guarded on
    // `removed_at IS NULL` FIRST. The line-88 target lookup is TOCTOU: two
    // concurrent removes of the same member both see it active and both pass.
    // Only the request whose conditional UPDATE returns a row "won" the
    // removal; the loser must NOT decrement the seat (else seat_count is
    // double-decremented for one removal — under-counting a seat the org is
    // still paying for, and drifting below the real member count).
    const { data: removed, error: remErr } = await supabase
      .from("org_members")
      .update({ removed_at: new Date().toISOString() })
      .eq("id", target.id)
      .is("removed_at", null)
      .select("id")
      .maybeSingle();
    if (remErr) {
      console.error("[remove-member] soft-remove failed:", remErr);
      return jsonError("Remove failed", 500, { reason: "soft_remove_failed" });
    }
    if (!removed) {
      // Lost the race (or replayed) — already removed by a concurrent call.
      return jsonError("Member not found", 404, { reason: "not_a_member" });
    }

    // org_increment_seats locks the org row FOR UPDATE, clamps at >= 0
    // (raises seats_negative otherwise), and writes org_seat_change_log.
    // A read-modify-write here would race a concurrent accept/remove. Only
    // the request that won the claim above reaches this line, so each removal
    // decrements the seat exactly once.
    const { data: seatAfter, error: seatErr } = await (supabase as any).rpc(
      "org_increment_seats",
      { p_org: ctx.org_id, p_delta: -1 },
    );
    if (seatErr) {
      console.error("[remove-member] seat decrement failed:", seatErr);
      return jsonError("Remove failed", 500, { reason: "seat_decrement_failed" });
    }
    newSeatCount = typeof seatAfter === "number" ? seatAfter : null;
  }

  // ── Stripe quantity sync (best-effort) ────────────────────────────────
  const { data: orgForStripe } = await supabase
    .from("organizations")
    .select("stripe_subscription_id")
    .eq("id", ctx.org_id)
    .maybeSingle();

  if (
    orgForStripe?.stripe_subscription_id && STRIPE_SECRET_KEY &&
    newSeatCount !== null
  ) {
    try {
      const subRes = await fetch(
        `https://api.stripe.com/v1/subscriptions/${orgForStripe.stripe_subscription_id}`,
        {
          headers: { "Authorization": `Bearer ${STRIPE_SECRET_KEY}` },
          signal: AbortSignal.timeout(10_000),
        },
      );
      if (subRes.ok) {
        const sub = await subRes.json();
        const itemId = sub.items?.data?.[0]?.id;
        if (itemId) {
          await fetch(
            `https://api.stripe.com/v1/subscription_items/${itemId}`,
            {
              method: "POST",
              headers: {
                "Authorization": `Bearer ${STRIPE_SECRET_KEY}`,
                "Content-Type": "application/x-www-form-urlencoded",
              },
              body: new URLSearchParams({
                quantity: String(Math.max(1, newSeatCount)),
                proration_behavior: "create_prorations",
              }),
              signal: AbortSignal.timeout(10_000),
            },
          );
        }
      }
    } catch (e) {
      console.error("[remove-member] Stripe quantity sync failed:", e);
    }
  }

  await writeOrgAudit(supabase, {
    org_id: ctx.org_id,
    actor_user_id: ctx.user_id,
    action: "member_removed",
    target_user_id: memberUserId,
    details: { reassign_to: reassignTo, prior_role: target.role },
    req,
  });

  return jsonOk({ ok: true, seat_count: newSeatCount });
});
