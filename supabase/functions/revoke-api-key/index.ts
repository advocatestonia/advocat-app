// revoke-api-key Edge Function
// -----------------------------------------------------------------------------
// Soft-delete (revoke) an API key.  Idempotent: calling on an already-revoked
// key returns 200 with `ok: true, already_revoked: true`.
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

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

interface RevokeBody {
  key_id?: string;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  const gate = await requireUserWithRateLimit(req, {
    bucket: "revoke-api-key",
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

  let body: RevokeBody;
  try {
    body = await req.json();
  } catch {
    return jsonError("Invalid JSON body", 400, { reason: "invalid_json" });
  }

  const keyId = (body.key_id ?? "").trim();
  if (!UUID_RE.test(keyId)) {
    return jsonError("Invalid key_id", 400, { reason: "invalid_key_id" });
  }

  // ── Tenant-scoped lookup (defence-in-depth against IDOR) ──────────────
  const { data: row } = await supabase
    .from("org_api_keys")
    .select("id, revoked_at, name, prefix")
    .eq("id", keyId)
    .eq("org_id", ctx.org_id)
    .maybeSingle();
  if (!row) {
    return jsonError("Key not found", 404, { reason: "key_not_found" });
  }
  if (row.revoked_at) {
    return jsonOk({ ok: true, already_revoked: true });
  }

  // ── Revoke ────────────────────────────────────────────────────────────
  const { error: updErr } = await supabase
    .from("org_api_keys")
    .update({ revoked_at: new Date().toISOString() })
    .eq("id", row.id)
    .eq("org_id", ctx.org_id);
  if (updErr) {
    console.error("[revoke-api-key] update failed:", updErr);
    return jsonError("Revoke failed", 500, { reason: "update_failed" });
  }

  await writeOrgAudit(supabase, {
    org_id: ctx.org_id,
    actor_user_id: ctx.user_id,
    action: "api_key_revoked",
    target_resource_type: "api_key",
    target_resource_id: row.id,
    details: { name: row.name, prefix: row.prefix },
    req,
  });

  return jsonOk({ ok: true });
});
