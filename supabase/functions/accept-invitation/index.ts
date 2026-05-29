// accept-invitation Edge Function
// -----------------------------------------------------------------------------
// Invited user clicks the link → signs in (or signs up) → POSTs the token here.
//
// Security:
//   * JWT required. Email of JWT must equal invitation email (case-insensitive)
//     — prevents re-using someone else's link.
//   * Token is single-use: accepted_at is set inside the same transaction.
//   * Seat-limit re-check inside the txn closes the race window between
//     invite-time and accept-time.
//   * Rate-limit 10/min/IP (the limiter buckets by user OR ip; for an
//     unauthenticated probe attempt this falls back to ip).
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import { writeOrgAudit } from "../_shared/auditLog.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const STRIPE_SECRET_KEY = Deno.env.get("STRIPE_SECRET_KEY") ?? "";

interface AcceptBody {
  token?: string;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  const gate = await requireUserWithRateLimit(req, {
    bucket: "accept-invitation",
    maxPerMinute: 10,
  });
  if (gate.kind === "deny") return gate.response;

  const userId = gate.user.id;
  const userEmail = (gate.user.email ?? "").toLowerCase();
  if (!userEmail) {
    return jsonError("User has no verified email", 400, {
      reason: "no_email_on_user",
    });
  }

  let body: AcceptBody;
  try {
    body = await req.json();
  } catch {
    return jsonError("Invalid JSON body", 400, { reason: "invalid_json" });
  }

  const token = (body.token ?? "").trim();
  if (!/^[0-9a-f]{64}$/i.test(token)) {
    return jsonError("Invalid token format", 400, { reason: "invalid_token" });
  }

  const tokenHash = await sha256Hex(token.toLowerCase());

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // ── Look up invitation ────────────────────────────────────────────────
  const { data: invite, error: invErr } = await supabase
    .from("org_invitations")
    .select("id, org_id, email, role, expires_at, accepted_at, revoked_at")
    .eq("token_hash", tokenHash)
    .maybeSingle();
  if (invErr) {
    console.error("[accept-invitation] lookup failed:", invErr);
    return jsonError("Invitation lookup failed", 503, {
      reason: "lookup_failed",
    });
  }
  if (!invite) {
    return jsonError("Invitation not found", 404, { reason: "invalid_token" });
  }
  if (invite.accepted_at) {
    return jsonError("Already accepted", 409, { reason: "already_accepted" });
  }
  if (invite.revoked_at) {
    return jsonError("Invitation revoked", 410, { reason: "revoked" });
  }
  if (new Date(invite.expires_at).getTime() < Date.now()) {
    return jsonError("Invitation expired", 410, { reason: "token_expired" });
  }
  if ((invite.email ?? "").toLowerCase() !== userEmail) {
    // Hardest check — protects against link-sharing attacks.
    return jsonError("Email does not match invitation", 403, {
      reason: "email_mismatch",
    });
  }

  // ── Org seat re-check ─────────────────────────────────────────────────
  const { data: org } = await supabase
    .from("organizations")
    .select("id, slug, name, seat_count, seat_limit, plan, status, stripe_subscription_id")
    .eq("id", invite.org_id)
    .maybeSingle();
  if (!org) {
    return jsonError("Org not found", 404, { reason: "org_not_found" });
  }
  if (org.status === "canceled" || org.status === "suspended") {
    return jsonError("Org is not active", 403, {
      reason: "org_inactive",
      status: org.status,
    });
  }
  if ((org.seat_count ?? 0) + 1 > (org.seat_limit ?? 0)) {
    return jsonError("Seat limit exceeded", 402, {
      reason: "seat_limit_exceeded",
    });
  }

  // ── Atomic accept: prefer RPC, fall back to sequenced ops ─────────────
  // Expected RPC: org_accept_invitation(p_invite_id uuid, p_user_id uuid)
  //   returns table(ok bool, reason text, seat_count int)
  // It must: upsert org_members, set invite accepted_*, and call
  // org_increment_seats inside a single txn.
  let seatCountAfter: number | null = null;
  let acceptOk = false;
  try {
    // deno-lint-ignore no-explicit-any
    const { data: rpcOut, error: rpcErr } = await (supabase as any).rpc(
      "org_accept_invitation",
      { p_invite_id: invite.id, p_user_id: userId },
    );
    if (!rpcErr && rpcOut) {
      const row = Array.isArray(rpcOut) ? rpcOut[0] : rpcOut;
      if (row?.ok) {
        acceptOk = true;
        seatCountAfter = row.seat_count ?? null;
      } else if (row?.reason === "seat_limit_exceeded") {
        return jsonError("Seat limit exceeded", 402, {
          reason: "seat_limit_exceeded",
        });
      } else if (row?.reason === "already_accepted") {
        return jsonError("Already accepted", 409, {
          reason: "already_accepted",
        });
      }
    } else if (rpcErr && !`${rpcErr.message}`.includes("does not exist")) {
      console.error("[accept-invitation] RPC failed:", rpcErr);
      return jsonError("Accept failed", 500, { reason: "rpc_failed" });
    }
  } catch (e) {
    console.warn("[accept-invitation] RPC threw, falling back:", e);
  }

  if (!acceptOk) {
    // Fallback path: sequenced operations (non-atomic, dev-only).
    // 1. Upsert member.
    const { error: memErr } = await supabase
      .from("org_members")
      .upsert(
        {
          org_id: invite.org_id,
          user_id: userId,
          role: invite.role,
          invited_by: null,
          joined_at: new Date().toISOString(),
          removed_at: null,
        },
        { onConflict: "org_id,user_id" },
      );
    if (memErr) {
      console.error("[accept-invitation] member upsert failed:", memErr);
      return jsonError("Member install failed", 500, {
        reason: "member_upsert_failed",
      });
    }

    // 2. Mark invitation accepted.
    await supabase
      .from("org_invitations")
      .update({
        accepted_at: new Date().toISOString(),
        accepted_by: userId,
      })
      .eq("id", invite.id);

    // 3. Increment seat count atomically. org_increment_seats locks the org
    //    row FOR UPDATE (serializes concurrent accepts), enforces seat_limit,
    //    and writes the forensic org_seat_change_log — a plain read-modify-write
    //    here would race two concurrent accepts and let the org exceed its cap.
    const { data: seatAfter, error: seatErr } = await (supabase as any).rpc(
      "org_increment_seats",
      { p_org: org.id, p_delta: 1 },
    );
    if (seatErr) {
      // 23514 (check_violation) is raised for seat_limit_exceeded.
      if (`${seatErr.message}`.includes("seat_limit_exceeded")) {
        return jsonError("Seat limit exceeded", 402, {
          reason: "seat_limit_exceeded",
        });
      }
      console.error("[accept-invitation] seat increment failed:", seatErr);
      return jsonError("Accept failed", 500, { reason: "seat_increment_failed" });
    }
    seatCountAfter = typeof seatAfter === "number" ? seatAfter : null;
  }

  // ── Stripe quantity sync (best-effort) ────────────────────────────────
  // If the org has an active Stripe subscription, bump quantity. Failures
  // here are reconciled later by the cron job.
  if (org.stripe_subscription_id && STRIPE_SECRET_KEY && seatCountAfter !== null) {
    try {
      // Stripe expects the subscription item ID, not the subscription ID, for
      // quantity updates. We resolve it via the API.
      const subRes = await fetch(
        `https://api.stripe.com/v1/subscriptions/${org.stripe_subscription_id}`,
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
                quantity: String(seatCountAfter),
                proration_behavior: "create_prorations",
              }),
              signal: AbortSignal.timeout(10_000),
            },
          );
        }
      }
    } catch (e) {
      console.error("[accept-invitation] Stripe quantity sync failed:", e);
    }
  }

  // ── Audit ─────────────────────────────────────────────────────────────
  await writeOrgAudit(supabase, {
    org_id: invite.org_id,
    actor_user_id: userId,
    action: "member_joined",
    target_user_id: userId,
    details: { role: invite.role, invitation_id: invite.id },
    req,
  });

  return jsonOk({
    org: { id: org.id, slug: org.slug, name: org.name },
    role: invite.role,
  });
});

async function sha256Hex(s: string): Promise<string> {
  const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(s));
  return Array.from(new Uint8Array(buf))
    .map((b) => b.toString(16).padStart(2, "0")).join("");
}
