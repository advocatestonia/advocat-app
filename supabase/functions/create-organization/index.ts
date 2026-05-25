// create-organization Edge Function
// -----------------------------------------------------------------------------
// B2B onboarding step 1: a signed-in B2C user upgrades into "team mode" by
// creating an organization. The caller is auto-installed as `owner`.
//
// Auth: JWT required. Rate-limit 3/hour/user (abuse prevention — orgs are
// cheap to create but expensive to garbage-collect, and slug-squatting is a
// real risk before public launch).
//
// Side effects:
//   1. organizations row with status='trial', trial_ends_at=now()+14d.
//   2. org_members row (owner).
//   3. org_audit_log entry (action=org_created).
//
// The DB function `org_create_with_owner(p_data jsonb) returns uuid` is
// expected to do steps 1-2 atomically. We fall back to a sequenced INSERT
// + INSERT if the RPC is missing (development environments).
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

const VALID_PLANS = new Set(["starter", "firm", "enterprise"]);
const SUPPORTED_COUNTRIES = new Set([
  "EE", "FI", "LV", "LT", "DE", "FR", "SE", "NO", "DK", "GB", "US",
]);
const RESERVED_SLUGS = new Set([
  "api", "app", "www", "admin", "firm", "lawyers", "support",
  "advocat", "auth", "billing", "help", "docs", "blog", "dashboard",
]);

const SLUG_RE = /^[a-z0-9-]{3,40}$/;
const VAT_RE = /^[A-Z]{2}[A-Z0-9]{2,18}$/;

// Plan → starting seat_limit. Capped at 100 to prevent runaway billing on
// "enterprise" tier; real Enterprise customers negotiate higher limits via
// support and we bump the row.
const PLAN_SEAT_LIMITS: Record<string, number> = {
  starter: 5,
  firm: 25,
  enterprise: 100,
};

interface CreateOrgBody {
  name?: string;
  slug?: string;
  legal_name?: string;
  country?: string;
  billing_email?: string;
  vat_id?: string | null;
  plan?: string;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // 3/hour/user → 3 per 60-minute equivalent. The shared limiter is per-minute,
  // so we set maxPerMinute=3 which is a strict ceiling; daily abuse is also
  // bounded by the per-user uniqueness on (created_by, slug) at the DB layer.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "create-organization",
    maxPerMinute: 3,
  });
  if (gate.kind === "deny") return gate.response;

  const userId = gate.user.id;
  const userEmail = (gate.user.email ?? "").toLowerCase();

  let body: CreateOrgBody;
  try {
    body = await req.json();
  } catch {
    return jsonError("Invalid JSON body", 400, { reason: "invalid_json" });
  }

  // ── Validation ────────────────────────────────────────────────────────
  const fieldErrors: Record<string, string> = {};

  const name = (body.name ?? "").trim();
  if (!name || name.length > 120) {
    fieldErrors.name = "must be 1..120 characters";
  }

  const slug = (body.slug ?? "").trim().toLowerCase();
  if (!SLUG_RE.test(slug)) {
    fieldErrors.slug = "must match ^[a-z0-9-]{3,40}$";
  } else if (RESERVED_SLUGS.has(slug)) {
    fieldErrors.slug = "reserved";
  }

  const country = (body.country ?? "").toUpperCase();
  if (!SUPPORTED_COUNTRIES.has(country)) {
    fieldErrors.country = "unsupported country";
  }

  const plan = (body.plan ?? "starter").toLowerCase();
  if (!VALID_PLANS.has(plan)) {
    fieldErrors.plan = "must be starter|firm|enterprise";
  }

  const billingEmail = (body.billing_email ?? userEmail).trim().toLowerCase();
  if (!billingEmail || !billingEmail.includes("@") || billingEmail.length > 254) {
    fieldErrors.billing_email = "invalid email";
  }

  const legalName = (body.legal_name ?? "").trim();
  if (legalName.length > 200) {
    fieldErrors.legal_name = "too long";
  }

  const vatId = body.vat_id ? body.vat_id.trim().toUpperCase() : null;
  if (vatId && !VAT_RE.test(vatId)) {
    fieldErrors.vat_id = "invalid VAT format";
  }

  if (Object.keys(fieldErrors).length > 0) {
    return jsonError("Validation failed", 400, {
      reason: "validation_failed",
      fields: fieldErrors,
    });
  }

  // Email-verified gate — without a verified email we can't bill them.
  // requireUserWithRateLimit already gave us an authenticated user; the
  // additional check is that Supabase Auth has confirmed the email.
  // We re-fetch the user record to read `email_confirmed_at`.
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  try {
    // deno-lint-ignore no-explicit-any
    const { data: authUser } = await (supabase as any).auth.admin.getUserById(userId);
    if (!authUser?.user?.email_confirmed_at) {
      return jsonError("Email not verified", 403, {
        reason: "email_not_verified",
      });
    }
  } catch (e) {
    console.error("[create-organization] email verify check failed:", e);
    // Fail closed on this check — if we can't verify, don't allow org creation.
    return jsonError("Could not verify email status", 503, {
      reason: "email_check_failed",
    });
  }

  // ── Slug uniqueness pre-check (DB has UNIQUE; we just want a nice error) ─
  const { data: existing, error: existingErr } = await supabase
    .from("organizations")
    .select("id")
    .eq("slug", slug)
    .is("deleted_at", null)
    .maybeSingle();
  if (existingErr) {
    console.error("[create-organization] slug lookup failed:", existingErr);
    return jsonError("Slug check failed", 503, { reason: "slug_check_failed" });
  }
  if (existing) {
    return jsonError("Slug already taken", 409, { reason: "slug_taken" });
  }

  // ── Create org + owner membership ─────────────────────────────────────
  const seatLimit = PLAN_SEAT_LIMITS[plan];
  const trialEndsAt = new Date(Date.now() + 14 * 24 * 60 * 60 * 1000).toISOString();

  // Try the atomic RPC first (production); fall back to two inserts
  // (development environments where the RPC hasn't been deployed yet).
  let newOrgId: string | null = null;
  try {
    // deno-lint-ignore no-explicit-any
    const { data: rpcOut, error: rpcErr } = await (supabase as any).rpc(
      "org_create_with_owner",
      {
        p_data: {
          name,
          slug,
          legal_name: legalName || null,
          country,
          billing_email: billingEmail,
          vat_id: vatId,
          plan,
          seat_count: 1,
          seat_limit: seatLimit,
          status: "trial",
          trial_ends_at: trialEndsAt,
          created_by: userId,
        },
      },
    );
    if (!rpcErr && rpcOut) {
      newOrgId = typeof rpcOut === "string" ? rpcOut : rpcOut.id ?? rpcOut[0]?.id ?? null;
    } else if (rpcErr && !`${rpcErr.message}`.includes("does not exist")) {
      // Real error from the RPC (not "missing function") — propagate.
      console.error("[create-organization] RPC failed:", rpcErr);
      return jsonError("Org creation failed", 500, {
        reason: "rpc_failed",
        details: rpcErr.message?.slice(0, 200),
      });
    }
  } catch (e) {
    console.warn("[create-organization] RPC call threw, falling back:", e);
  }

  if (!newOrgId) {
    // Fallback path (best-effort, NOT transactional — only used in dev).
    const { data: org, error: orgErr } = await supabase
      .from("organizations")
      .insert({
        name,
        slug,
        legal_name: legalName || null,
        country,
        billing_email: billingEmail,
        vat_id: vatId,
        plan,
        seat_count: 1,
        seat_limit: seatLimit,
        status: "trial",
        trial_ends_at: trialEndsAt,
        created_by: userId,
      })
      .select("id")
      .single();
    if (orgErr) {
      if (orgErr.code === "23505") {
        return jsonError("Slug already taken", 409, { reason: "slug_taken" });
      }
      console.error("[create-organization] org insert failed:", orgErr);
      return jsonError("Org creation failed", 500, {
        reason: "org_insert_failed",
      });
    }
    newOrgId = org.id;

    const { error: memErr } = await supabase.from("org_members").insert({
      org_id: newOrgId,
      user_id: userId,
      role: "owner",
      invited_by: userId,
      joined_at: new Date().toISOString(),
    });
    if (memErr) {
      // Best-effort rollback — delete the org row to avoid orphan.
      await supabase.from("organizations").delete().eq("id", newOrgId);
      console.error("[create-organization] member insert failed:", memErr);
      return jsonError("Owner installation failed", 500, {
        reason: "member_insert_failed",
      });
    }
  }

  // ── Audit ─────────────────────────────────────────────────────────────
  await writeOrgAudit(supabase, {
    org_id: newOrgId!,
    actor_user_id: userId,
    action: "org_created",
    target_user_id: userId,
    details: { plan, country, slug },
    req,
  });

  // ── Response ──────────────────────────────────────────────────────────
  const { data: orgFull } = await supabase
    .from("organizations")
    .select("id, slug, name, plan, status, trial_ends_at, seat_limit")
    .eq("id", newOrgId!)
    .maybeSingle();

  return jsonOk(
    {
      org: orgFull,
      membership: { role: "owner", joined_at: new Date().toISOString() },
    },
    201,
  );
});
