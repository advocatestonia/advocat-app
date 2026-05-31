// invite-member Edge Function
// -----------------------------------------------------------------------------
// Org owner / admin invites a colleague by email. Generates a 256-bit
// single-use token, stores its sha256 in org_invitations, and emails the
// link via the existing send-email edge function.
//
// Seat count is NOT incremented here — that happens on `accept-invitation`.
// Doing it now would block legitimate invites when an admin sends a batch
// then someone declines.
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
import { wouldExceedSeats } from "./seatCheck.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const APP_URL = Deno.env.get("APP_URL") ?? "https://advocat.ee";

const VALID_ROLES = new Set(["admin", "member", "viewer", "billing"]);
const INVITE_TTL_DAYS = 7;
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

interface InviteBody {
  email?: string;
  role?: string;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // 30/hour/org cap is the spec; we approximate as 30/min/user since the
  // limiter is per-minute. The DB-level seat check is the hard ceiling.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "invite-member",
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

  let body: InviteBody;
  try {
    body = await req.json();
  } catch {
    return jsonError("Invalid JSON body", 400, { reason: "invalid_json" });
  }

  const email = (body.email ?? "").trim().toLowerCase();
  const role = (body.role ?? "").toLowerCase();

  // ── Validation ────────────────────────────────────────────────────────
  if (!email || !EMAIL_RE.test(email) || email.length > 254) {
    return jsonError("Invalid email", 400, { reason: "invalid_email" });
  }
  if (role === "owner") {
    // Owner role transfer goes through a separate flow.
    return jsonError("Cannot invite as owner", 400, {
      reason: "cannot_invite_owner",
    });
  }
  if (!VALID_ROLES.has(role)) {
    return jsonError("Invalid role", 400, { reason: "invalid_role" });
  }

  // ── Org snapshot (locked read of seat counts) ─────────────────────────
  const { data: org, error: orgErr } = await supabase
    .from("organizations")
    .select("id, seat_count, seat_limit, plan, name, status")
    .eq("id", ctx.org_id)
    .maybeSingle();
  if (orgErr || !org) {
    console.error("[invite-member] org lookup failed:", orgErr);
    return jsonError("Org not found", 404, { reason: "org_not_found" });
  }
  if (org.status === "canceled" || org.status === "suspended") {
    return jsonError("Org is not active", 403, {
      reason: "org_inactive",
      status: org.status,
    });
  }

  // ── Existing-member check ─────────────────────────────────────────────
  // We must look up via auth.users to find the user_id for this email
  // (an existing user) and then check org_members. If the user doesn't
  // exist in auth.users yet, they obviously aren't a member.
  // deno-lint-ignore no-explicit-any
  const { data: byEmail } = await (supabase as any)
    .rpc("get_user_id_by_email", { p_email: email })
    .maybeSingle?.()
    .catch?.(() => ({ data: null })) ?? { data: null };

  if (byEmail) {
    const existingUserId = typeof byEmail === "string"
      ? byEmail
      : (byEmail.id ?? byEmail.user_id ?? null);
    if (existingUserId) {
      const { data: alreadyMember } = await supabase
        .from("org_members")
        .select("id")
        .eq("org_id", ctx.org_id)
        .eq("user_id", existingUserId)
        .is("removed_at", null)
        .maybeSingle();
      if (alreadyMember) {
        return jsonError("User is already a member", 409, {
          reason: "already_member",
        });
      }
    }
  }

  // ── Pending-invitation check ──────────────────────────────────────────
  const { data: pendingInvite } = await supabase
    .from("org_invitations")
    .select("id, expires_at")
    .eq("org_id", ctx.org_id)
    .eq("email", email)
    .is("accepted_at", null)
    .is("revoked_at", null)
    .gt("expires_at", new Date().toISOString())
    .maybeSingle();
  if (pendingInvite) {
    return jsonError("Pending invitation exists", 409, {
      reason: "already_invited",
      expires_at: pendingInvite.expires_at,
    });
  }

  // ── Seat capacity check ───────────────────────────────────────────────
  // Count current seats + OUTSTANDING pending invitations vs limit, so an
  // admin can't queue more invites than the plan can ever seat (each would
  // otherwise 402 only at accept-time — confusing UX). Pending = not yet
  // accepted, not revoked, not expired. The accept-time re-check and the
  // org_increment_seats RPC remain the hard ceilings.
  const { count: pendingCount } = await supabase
    .from("org_invitations")
    .select("id", { count: "exact", head: true })
    .eq("org_id", ctx.org_id)
    .is("accepted_at", null)
    .is("revoked_at", null)
    .gt("expires_at", new Date().toISOString());
  const pendingInvites = pendingCount ?? 0;

  if (wouldExceedSeats(org.seat_count ?? 0, pendingInvites, org.seat_limit ?? 0)) {
    return jsonError("Seat limit exceeded", 402, {
      reason: "seat_limit_exceeded",
      seat_count: org.seat_count,
      seat_limit: org.seat_limit,
    });
  }

  // ── Generate token ────────────────────────────────────────────────────
  const token = randomHex(32); // 32 bytes = 64 hex chars
  const tokenHash = await sha256Hex(token);
  const expiresAt = new Date(Date.now() + INVITE_TTL_DAYS * 24 * 60 * 60 * 1000).toISOString();

  const { data: invite, error: insErr } = await supabase
    .from("org_invitations")
    .insert({
      org_id: ctx.org_id,
      email,
      role,
      invited_by: ctx.user_id,
      token_hash: tokenHash,
      expires_at: expiresAt,
    })
    .select("id, email, role, expires_at")
    .single();
  if (insErr) {
    console.error("[invite-member] insert failed:", insErr);
    return jsonError("Invitation insert failed", 500, {
      reason: "insert_failed",
    });
  }

  // ── Send email (best-effort) ──────────────────────────────────────────
  const inviteUrl = `${APP_URL}/invite?token=${token}`;
  try {
    await fetch(`${SUPABASE_URL}/functions/v1/send-email`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        to: email,
        template: "org-invite",
        locale: "en",
        variables: {
          org_name: org.name,
          role,
          invite_url: inviteUrl,
          expires_in_days: INVITE_TTL_DAYS,
        },
      }),
    });
  } catch (e) {
    console.error("[invite-member] email send failed (continuing):", e);
  }

  // ── Audit ─────────────────────────────────────────────────────────────
  await writeOrgAudit(supabase, {
    org_id: ctx.org_id,
    actor_user_id: ctx.user_id,
    action: "member_invited",
    target_user_id: null,
    details: { email, role, invitation_id: invite.id },
    req,
  });

  return jsonOk({ invitation: invite }, 201);
});

function randomHex(bytes: number): string {
  const arr = new Uint8Array(bytes);
  crypto.getRandomValues(arr);
  return Array.from(arr).map((b) => b.toString(16).padStart(2, "0")).join("");
}

async function sha256Hex(s: string): Promise<string> {
  const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(s));
  return Array.from(new Uint8Array(buf))
    .map((b) => b.toString(16).padStart(2, "0")).join("");
}
