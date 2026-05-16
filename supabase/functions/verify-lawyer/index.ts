// verify-lawyer Edge Function
// -----------------------------------------------------------------------------
// Handles the "AI for verified attorneys — free forever" enrollment.
//
// Flow:
//   1. Authenticated POST from the /lawyers form.
//   2. Validate input (country in {FI,EE}, non-empty bar_id, plausible email).
//   3. Cross-reference public bar-association registry (advokatuur.ee or
//      asianajajaliitto.fi) via registry.ts.
//   4. If high-confidence match → set profile.plan='premium_lawyer',
//      is_pro=true, lawyer_verified_at=now(), write 'auto_approved' audit row.
//   5. If borderline → leave profile unchanged, write 'queued' audit row,
//      Telegram-notify the owner for manual review.
//   6. If miss → 'rejected' audit row, 400 to the client with a friendly
//      reason key the UI can localise.
//
// Hard guarantees:
//   * Feature flag LAWYER_PROGRAM_ENABLED gates the entire endpoint. When
//     `false`, return 503 (service unavailable). Default: true.
//   * One enrollment per user. A second POST returns 409 with the existing
//     status. This is enforced by reading the profile row before insert.
//   * Email match: the submitted email must equal the JWT-bound email
//     (case-insensitive). Otherwise reject with 'email_mismatch'.
//   * Registry response excerpt stored in audit row — no full HTML to keep
//     row size bounded.
//
// CORS: advocat.ee only.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import { lookupLawyer, MatchOutcome } from "./registry.ts";
import { RawBody, validateBody, ValidatedBody } from "./validate.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const TELEGRAM_BOT_TOKEN = Deno.env.get("TELEGRAM_BOT_TOKEN") ?? "";
const TELEGRAM_CHAT_ID = Deno.env.get("TELEGRAM_CHAT_ID") ?? "";

/**
 * Feature flag. Default `true` so a fresh deploy of the function is live
 * immediately; the owner can flip the env var without re-deploying code
 * to disable enrollments (e.g. while the bar registries are down for
 * maintenance).
 */
const LAWYER_PROGRAM_ENABLED =
  (Deno.env.get("LAWYER_PROGRAM_ENABLED") ?? "true").toLowerCase() !== "false";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }
  if (!LAWYER_PROGRAM_ENABLED) {
    return jsonError("Lawyer program disabled", 503, {
      reason: "program_disabled",
    });
  }

  // Auth gate. The /lawyers form posts after sign-in; no anonymous path.
  // 5/min/user is generous — the form is single-submit; bursts indicate
  // either a UI bug or a brute-force probe of bar IDs.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "verify-lawyer",
    maxPerMinute: 5,
  });
  if (gate.kind === "deny") return gate.response;
  const userId = gate.user.id;
  const jwtEmail = (gate.user.email ?? "").toLowerCase();
  if (!jwtEmail) {
    return jsonError("User has no verified email", 400, {
      reason: "no_email_on_user",
    });
  }

  // Parse and validate body.
  let raw: RawBody;
  try {
    raw = await req.json();
  } catch {
    return jsonError("Invalid JSON body", 400);
  }
  const parsed = validateBody(raw);
  if (parsed.kind === "error") {
    return jsonError("Validation failed", 400, parsed.payload);
  }
  const body = parsed.body;

  // The submitted email MUST match the JWT email — prevents enrolling a
  // bar member's account from a different user.
  if (body.email.toLowerCase() !== jwtEmail) {
    return jsonError("Submitted email does not match account email", 400, {
      reason: "email_mismatch",
    });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  // One-enrollment-per-user guard.
  const { data: profile, error: profileErr } = await supabase
    .from("profiles")
    .select(
      "lawyer_verified_at, lawyer_verification_status, lawyer_bar_country, lawyer_bar_id",
    )
    .eq("id", userId)
    .maybeSingle();
  if (profileErr) {
    console.error("[verify-lawyer] profile read failed:", profileErr);
    return jsonError("Profile lookup failed", 500, {
      reason: "profile_read_failed",
    });
  }
  if (profile?.lawyer_verified_at) {
    return jsonError("Already verified", 409, {
      reason: "already_verified",
      since: profile.lawyer_verified_at,
    });
  }
  if (profile?.lawyer_verification_status === "pending") {
    return jsonError("Application already pending review", 409, {
      reason: "pending_review",
    });
  }

  // Cross-reference the bar association.
  const outcome: MatchOutcome = await lookupLawyer({
    country: body.country,
    barId: body.barId,
    fullName: body.fullName,
  });

  const ipAddress = (req.headers.get("x-forwarded-for") ?? "").split(",")[0]
    .trim() || null;
  const userAgent = (req.headers.get("user-agent") ?? "").slice(0, 500);

  // Branch on outcome.
  if (outcome.kind === "match") {
    await supabase.from("profiles").update({
      lawyer_verified_at: new Date().toISOString(),
      lawyer_verification_status: "auto_approved",
      lawyer_bar_country: body.country,
      lawyer_bar_id: body.barId,
      lawyer_full_name: body.fullName,
      lawyer_practice_url: body.practiceUrl,
      is_pro: true,
      subscription_tier: "premium_lawyer",
    }).eq("id", userId);

    await writeAudit(supabase, {
      userId,
      body,
      result: "auto_approved",
      details: {
        confidence: outcome.confidence,
        excerpt: outcome.excerpt.slice(0, 1000),
      },
      ipAddress,
      userAgent,
    });

    notifyTelegram(
      `New verified attorney: ${body.fullName} (${body.country}/${body.barId}). ` +
        `confidence=${outcome.confidence}. ${jwtEmail}`,
    ).catch(() => {}); // fire and forget

    return jsonOk({
      ok: true,
      status: "auto_approved",
      verified_at: new Date().toISOString(),
      message: "Welcome — Premium activated.",
    });
  }

  if (outcome.kind === "borderline" || outcome.kind === "unknown") {
    await supabase.from("profiles").update({
      lawyer_verification_status: "pending",
      lawyer_bar_country: body.country,
      lawyer_bar_id: body.barId,
      lawyer_full_name: body.fullName,
      lawyer_practice_url: body.practiceUrl,
    }).eq("id", userId);

    await writeAudit(supabase, {
      userId,
      body,
      result: "queued",
      details: {
        outcome_kind: outcome.kind,
        reason: outcome.kind === "borderline" || outcome.kind === "unknown"
          ? outcome.reason
          : null,
        excerpt: outcome.kind === "borderline"
          ? outcome.excerpt.slice(0, 1000)
          : null,
      },
      ipAddress,
      userAgent,
    });

    notifyTelegram(
      `Lawyer verification needs review: ${body.fullName} ` +
        `(${body.country}/${body.barId}). Reason: ${
          outcome.kind === "borderline" || outcome.kind === "unknown"
            ? outcome.reason
            : "n/a"
        }. ${jwtEmail}`,
    ).catch(() => {});

    return jsonOk({
      ok: true,
      status: "pending",
      message:
        "Your application has been queued for manual review. We typically respond within 24 hours.",
    });
  }

  // outcome.kind === "miss"
  await writeAudit(supabase, {
    userId,
    body,
    result: "rejected",
    details: { reason: outcome.reason },
    ipAddress,
    userAgent,
  });

  return jsonError("Could not verify bar membership", 400, {
    reason: "registry_miss",
    detail: outcome.reason,
  });
});

// ─── Audit ──────────────────────────────────────────────────────────────────

async function writeAudit(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  args: {
    userId: string;
    body: ValidatedBody;
    result: "auto_approved" | "queued" | "manually_approved" | "rejected" | "revoked";
    details: Record<string, unknown>;
    ipAddress: string | null;
    userAgent: string;
  },
): Promise<void> {
  const { error } = await supabase.from("lawyer_verification_audit").insert({
    user_id: args.userId,
    bar_country: args.body.country,
    bar_id: args.body.barId,
    full_name: args.body.fullName,
    submitted_email: args.body.email,
    practice_url: args.body.practiceUrl,
    result: args.result,
    details: args.details,
    ip_address: args.ipAddress,
    user_agent: args.userAgent,
  });
  if (error) {
    // Log but don't fail the user-facing flow — audit miss is recoverable
    // (we still wrote profile state on auto_approve).
    console.error("[verify-lawyer] audit insert failed:", error);
  }
}

// ─── Telegram notify (best-effort) ──────────────────────────────────────────

async function notifyTelegram(text: string): Promise<void> {
  if (!TELEGRAM_BOT_TOKEN || !TELEGRAM_CHAT_ID) return;
  try {
    await fetch(
      `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          chat_id: TELEGRAM_CHAT_ID,
          text,
          // Plain text avoids the MarkdownV2 escape footgun for this short
          // notification. If we ever want links, switch to MarkdownV2 with
          // the helper from support-ticket/telegram.ts.
        }),
      },
    );
  } catch (e) {
    console.warn("[verify-lawyer] telegram notify failed:", e);
  }
}
