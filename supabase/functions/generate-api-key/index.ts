// generate-api-key Edge Function
// -----------------------------------------------------------------------------
// Mint a new API key for the org.  Returns the secret EXACTLY ONCE — we only
// store sha256(key) in the DB.
//
// Format: `av_live_<orgid8>_<32 hex>` (= 46 chars). The `<orgid8>` is the
// first 8 chars of the org UUID without dashes, which makes the key
// self-identifying (helps support).
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
import { VALID_SCOPES, type ApiScope } from "../_shared/rateLimit.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const MAX_ACTIVE_KEYS_PER_ORG = 10;
const PLANS_WITH_API = new Set(["firm", "enterprise"]);

interface GenerateKeyBody {
  name?: string;
  scopes?: string[];
  expires_at?: string | null;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  const gate = await requireUserWithRateLimit(req, {
    bucket: "generate-api-key",
    maxPerMinute: 10,
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

  let body: GenerateKeyBody;
  try {
    body = await req.json();
  } catch {
    return jsonError("Invalid JSON body", 400, { reason: "invalid_json" });
  }

  const name = (body.name ?? "").trim();
  const scopes = Array.isArray(body.scopes) ? body.scopes : [];
  const expiresAt = body.expires_at ?? null;

  if (!name || name.length > 80) {
    return jsonError("Invalid name", 400, { reason: "invalid_name" });
  }
  if (scopes.length === 0) {
    return jsonError("At least one scope required", 400, {
      reason: "no_scopes",
    });
  }
  const allowed: ReadonlySet<string> = new Set(VALID_SCOPES);
  const invalid = scopes.filter((s) => !allowed.has(s));
  if (invalid.length > 0) {
    return jsonError("Invalid scopes", 400, {
      reason: "invalid_scopes",
      invalid,
    });
  }
  if (expiresAt) {
    const t = new Date(expiresAt).getTime();
    if (Number.isNaN(t) || t <= Date.now()) {
      return jsonError("Invalid expires_at", 400, {
        reason: "invalid_expires_at",
      });
    }
  }

  // ── Plan supports API? ────────────────────────────────────────────────
  const { data: org } = await supabase
    .from("organizations")
    .select("plan, status")
    .eq("id", ctx.org_id)
    .maybeSingle();
  if (!org) {
    return jsonError("Org not found", 404, { reason: "org_not_found" });
  }
  if (!PLANS_WITH_API.has(org.plan)) {
    return jsonError("Plan does not include API access", 402, {
      reason: "plan_lacks_api",
      plan: org.plan,
    });
  }

  // ── Active-key cap ────────────────────────────────────────────────────
  const { count } = await supabase
    .from("org_api_keys")
    .select("id", { count: "exact", head: true })
    .eq("org_id", ctx.org_id)
    .is("revoked_at", null);
  if ((count ?? 0) >= MAX_ACTIVE_KEYS_PER_ORG) {
    return jsonError("Maximum active API keys reached", 409, {
      reason: "key_limit_reached",
      limit: MAX_ACTIVE_KEYS_PER_ORG,
    });
  }

  // ── Generate key ──────────────────────────────────────────────────────
  const orgIdShort = ctx.org_id.replace(/-/g, "").slice(0, 8);
  const suffix = randomHex(16); // 16 bytes = 32 hex chars
  const fullKey = `av_live_${orgIdShort}_${suffix}`;
  const prefix = `av_live_${orgIdShort}_`;
  const keyHash = await sha256Hex(fullKey);

  const { data: inserted, error: insErr } = await supabase
    .from("org_api_keys")
    .insert({
      org_id: ctx.org_id,
      name,
      prefix,
      key_hash: keyHash,
      scopes: scopes as ApiScope[],
      created_by: ctx.user_id,
      expires_at: expiresAt,
    })
    .select("id, prefix, scopes, expires_at, created_at")
    .single();
  if (insErr) {
    console.error("[generate-api-key] insert failed:", insErr);
    return jsonError("Key creation failed", 500, { reason: "insert_failed" });
  }

  await writeOrgAudit(supabase, {
    org_id: ctx.org_id,
    actor_user_id: ctx.user_id,
    action: "api_key_created",
    target_resource_type: "api_key",
    target_resource_id: inserted.id,
    details: { name, scopes, prefix },
    req,
  });

  return jsonOk(
    {
      key: fullKey, // shown ONCE
      id: inserted.id,
      prefix: inserted.prefix,
      scopes: inserted.scopes,
      expires_at: inserted.expires_at,
    },
    201,
  );
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
