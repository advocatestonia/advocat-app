// update-member-role Edge Function
// -----------------------------------------------------------------------------
// Owner changes another member's role.
//
// Guardrails:
//   * Cannot change own role (use a separate "transfer ownership" flow).
//   * Cannot demote the last owner.
//   * Target must be an active member (removed_at IS NULL).
//   * Only `owner` can promote to `owner` (a.k.a. ownership transfer); for v1
//     we forbid setting role=owner here altogether — transfer is a separate
//     ceremony to be added later.
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

const VALID_ROLES = new Set(["admin", "member", "viewer", "billing"]);
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

interface UpdateRoleBody {
  member_user_id?: string;
  role?: string;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  const gate = await requireUserWithRateLimit(req, {
    bucket: "update-member-role",
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
    { minRole: "owner" }, // owner only
  );
  if (orgGate.kind === "deny") return orgGate.response;
  const ctx = orgGate.ctx;

  let body: UpdateRoleBody;
  try {
    body = await req.json();
  } catch {
    return jsonError("Invalid JSON body", 400, { reason: "invalid_json" });
  }

  const memberUserId = (body.member_user_id ?? "").trim();
  const newRole = (body.role ?? "").toLowerCase();

  if (!UUID_RE.test(memberUserId)) {
    return jsonError("Invalid member_user_id", 400, {
      reason: "invalid_member_id",
    });
  }
  if (!VALID_ROLES.has(newRole)) {
    return jsonError("Invalid role", 400, { reason: "invalid_role" });
  }
  if (memberUserId === ctx.user_id) {
    return jsonError("Cannot change own role", 400, {
      reason: "cannot_change_own_role",
    });
  }

  // ── Target membership lookup ──────────────────────────────────────────
  const { data: target, error: targetErr } = await supabase
    .from("org_members")
    .select("id, role, user_id")
    .eq("org_id", ctx.org_id)
    .eq("user_id", memberUserId)
    .is("removed_at", null)
    .maybeSingle();
  if (targetErr) {
    console.error("[update-member-role] target lookup failed:", targetErr);
    return jsonError("Member lookup failed", 503, {
      reason: "lookup_failed",
    });
  }
  if (!target) {
    return jsonError("Member not found", 404, { reason: "not_a_member" });
  }
  if (target.role === newRole) {
    // No-op — still write an audit row? We choose to short-circuit silently.
    return jsonOk({ ok: true, unchanged: true });
  }

  // ── Owner safety: cannot demote the last owner ────────────────────────
  if (target.role === "owner" && newRole !== "owner") {
    const { count } = await supabase
      .from("org_members")
      .select("id", { count: "exact", head: true })
      .eq("org_id", ctx.org_id)
      .eq("role", "owner")
      .is("removed_at", null);
    if ((count ?? 0) <= 1) {
      return jsonError("Cannot demote the last owner", 409, {
        reason: "cannot_demote_last_owner",
      });
    }
  }

  // ── Update ────────────────────────────────────────────────────────────
  const { error: updErr } = await supabase
    .from("org_members")
    .update({ role: newRole })
    .eq("id", target.id);
  if (updErr) {
    console.error("[update-member-role] update failed:", updErr);
    return jsonError("Role update failed", 500, { reason: "update_failed" });
  }

  await writeOrgAudit(supabase, {
    org_id: ctx.org_id,
    actor_user_id: ctx.user_id,
    action: "role_changed",
    target_user_id: memberUserId,
    details: { from: target.role, to: newRole },
    req,
  });

  return jsonOk({ ok: true });
});
