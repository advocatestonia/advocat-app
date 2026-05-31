// lawyer-booking Edge Function
// -----------------------------------------------------------------------------
// Day2-E — "1 human-lawyer call/quarter free" Pro/Premium perk.
//
// Single endpoint, four `op`s:
//
//   op:create   — user books a 15-min call. Server enforces:
//                   * user is Pro or Premium (free has 0 quota)
//                   * quarterly quota not yet spent
//                   * picked lawyer (if any) is an ACTIVE partner
//                   * scheduled_at is in the future and within 60 days
//                 Returns the booking row + AI brief skeleton.
//
//   op:outcome  — partner lawyer fills 1-page post-call form. Sets
//                 outcome_summary, outcome_at, status='completed', and
//                 records payout_cents from the partner's current rate.
//                 Triggers refresh_partner_lawyer_stats.
//
//   op:rate     — user 1-5 rating + optional feedback. Status stays
//                 'completed' (rating is informational only).
//
//   op:cancel   — user OR lawyer cancels. Quota credit is restored
//                 (the row stays for audit but is excluded from quota
//                 by quota_used SQL function).
//
// AI brief generation:
//   The brief is generated on `create` synchronously if scheduled_at is
//   within 2h (or NULL = ASAP), and lazily on later GET-via-cron for
//   future slots. We don't BLOCK the booking on brief — failure is
//   tolerated (see brief.ts skeleton fallback).
//
// Feature gate:
//   LAWYER_PARTNERSHIP_ENABLED env var. Default: "false". Owner flips
//   to "true" after enrolling ≥3 EE solo lawyers (per the task brief).
//
// CORS: advocat.ee only (inherited from _shared/auth.ts).
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
  RawBody,
  validateBody,
  ValidatedCreate,
  ValidatedRate,
  ValidatedCancel,
} from "./validate.ts";
import { generateBrief } from "./brief.ts";
import { handleOutcome } from "./outcome.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

/**
 * Feature flag. Default `false` per the Day2-E brief: do NOT charge any
 * user or take any booking until at least 3 EE solo lawyers have signed
 * up. Owner flips the env var on the Supabase Edge Functions dashboard.
 */
const LAWYER_PARTNERSHIP_ENABLED =
  (Deno.env.get("LAWYER_PARTNERSHIP_ENABLED") ?? "false").toLowerCase() ===
    "true";

/** Quarterly quotas, by subscription_tier value. Free has 0. */
const QUOTA_BY_TIER: Record<string, number> = {
  free: 0,
  pro: 1,
  premium: 2,
  premium_lawyer: 0, // verified-attorney tier — they ARE lawyers
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }
  if (!LAWYER_PARTNERSHIP_ENABLED) {
    return jsonError("Lawyer partnership program not yet open", 503, {
      reason: "program_disabled",
    });
  }

  const gate = await requireUserWithRateLimit(req, {
    bucket: "lawyer-booking",
    // 20/min/user is generous — covers a flurry of "view briefing"
    // dashboard hits without rejecting the partner lawyer mid-list-scroll.
    maxPerMinute: 20,
  });
  if (gate.kind === "deny") return gate.response;
  const userId = gate.user.id;
  const jwtEmail = (gate.user.email ?? "").toLowerCase();

  // Extract the raw JWT for the brief generator (claude-proxy expects a
  // user JWT, not service role).
  const authHeader = req.headers.get("Authorization") ?? "";
  const userJwt = authHeader.replace(/^Bearer\s+/i, "");

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

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  switch (parsed.body.op) {
    case "create":
      return handleCreate(supabase, userId, jwtEmail, userJwt, parsed.body);
    case "outcome":
      return handleOutcome(supabase, userId, parsed.body);
    case "rate":
      return handleRate(supabase, userId, parsed.body);
    case "cancel":
      return handleCancel(supabase, userId, parsed.body);
  }
});

// ─── op:create ──────────────────────────────────────────────────────────────

async function handleCreate(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  userId: string,
  jwtEmail: string,
  userJwt: string,
  body: ValidatedCreate,
): Promise<Response> {
  // 1. Read the user's profile for tier + display name.
  const { data: profile, error: profErr } = await supabase
    .from("profiles")
    .select("id, subscription_tier, is_pro, full_name, email")
    .eq("id", userId)
    .maybeSingle();
  if (profErr) {
    console.error("[lawyer-booking] profile read failed:", profErr);
    return jsonError("Profile read failed", 500, {
      reason: "profile_read_failed",
    });
  }
  const tier = (profile?.subscription_tier as string | null) ??
    (profile?.is_pro ? "pro" : "free");
  const quota = QUOTA_BY_TIER[tier] ?? 0;
  if (quota <= 0) {
    return jsonError("Upgrade to Pro for a free lawyer call", 402, {
      reason: "upgrade_required",
      tier,
    });
  }

  // 2. Check quarterly quota via the SQL helper.
  const { data: usedRows, error: usedErr } = await supabase
    .rpc("lawyer_bookings_quota_used", { p_user: userId });
  if (usedErr) {
    console.error("[lawyer-booking] quota rpc failed:", usedErr);
    return jsonError("Quota check failed", 500, {
      reason: "quota_check_failed",
    });
  }
  const used = typeof usedRows === "number" ? usedRows : Number(usedRows ?? 0);
  if (used >= quota) {
    return jsonError("Quarterly quota exhausted", 429, {
      reason: "quota_exhausted",
      quota,
      used,
    });
  }

  // 3. If a specific lawyer was requested, verify they're ACTIVE.
  let lawyerId: string | null = body.lawyerId;
  let lawyerCountry: string | null = null;
  if (lawyerId) {
    const { data: partnerRow, error: partnerErr } = await supabase
      .from("partner_lawyers")
      .select("lawyer_id, country, active, paused_at, ended_at")
      .eq("lawyer_id", lawyerId)
      .maybeSingle();
    if (partnerErr) {
      console.error("[lawyer-booking] partner read failed:", partnerErr);
      return jsonError("Lawyer lookup failed", 500, {
        reason: "lawyer_lookup_failed",
      });
    }
    if (!partnerRow) {
      return jsonError("Selected lawyer not found", 404, {
        reason: "lawyer_not_found",
      });
    }
    if (!partnerRow.active || partnerRow.paused_at || partnerRow.ended_at) {
      return jsonError("Selected lawyer not currently available", 409, {
        reason: "lawyer_unavailable",
      });
    }
    lawyerCountry = partnerRow.country;
  }

  // 4. Insert the booking row. status='requested' if no lawyer chosen
  //    or no slot picked; 'confirmed' if both are present (skipping
  //    'assigned' for the v1 flow — owner triages manually if needed).
  const status: "requested" | "confirmed" =
    lawyerId && body.scheduledAt ? "confirmed" : "requested";

  const insertRow = {
    user_id: userId,
    lawyer_id: lawyerId,
    topic: body.topic,
    case_id: body.caseId,
    language: body.language,
    user_brief: body.userBrief,
    scheduled_at: body.scheduledAt,
    duration_minutes: 15,
    status,
    // quota_quarter is filled by the BEFORE trigger.
    quota_quarter: deriveQuarter(body.scheduledAt),
  };
  const { data: inserted, error: insErr } = await supabase
    .from("lawyer_bookings")
    .insert(insertRow)
    .select("*")
    .single();
  if (insErr) {
    console.error("[lawyer-booking] insert failed:", insErr);
    return jsonError("Could not create booking", 500, {
      reason: "insert_failed",
      detail: insErr.message,
    });
  }

  // 5. Brief generation — fire-and-forget for far-future slots, awaited
  //    for slots within 2h (so the lawyer dashboard has the brief by the
  //    time they look).
  const within2h = body.scheduledAt
    ? Date.parse(body.scheduledAt) - Date.now() < 2 * 3600 * 1000
    : true;
  if (within2h) {
    try {
      const caseFacts = await loadCaseFactsIfAny(supabase, body.caseId, userId);
      const result = await generateBrief({
        topic: body.topic,
        language: body.language,
        userBrief: body.userBrief,
        userDisplayName: (profile?.full_name as string | null) ?? jwtEmail,
        caseFactsJson: caseFacts,
        caseChatExcerpt: null,
      }, userJwt);
      await supabase
        .from("lawyer_bookings")
        .update({
          ai_brief_md: result.markdown,
          ai_brief_at: new Date().toISOString(),
        })
        .eq("id", inserted.id);
      inserted.ai_brief_md = result.markdown;
      inserted.ai_brief_at = new Date().toISOString();
    } catch (e) {
      console.warn("[lawyer-booking] brief generation skipped:", e);
    }
  }

  return jsonOk({
    ok: true,
    booking: inserted,
    lawyer_country: lawyerCountry,
    quota_remaining: quota - used - 1,
  });
}

// ─── op:outcome ─────────────────────────────────────────────────────────────
// Extracted to ./outcome.ts (pure, injected-client) so it is unit-testable and
// to add the concurrent double-submit CAS guard. See handleOutcome there.

// ─── op:rate ────────────────────────────────────────────────────────────────

async function handleRate(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  userId: string,
  body: ValidatedRate,
): Promise<Response> {
  const { data: booking, error: readErr } = await supabase
    .from("lawyer_bookings")
    .select("id, user_id, lawyer_id, status")
    .eq("id", body.bookingId)
    .maybeSingle();
  if (readErr) {
    return jsonError("Booking read failed", 500, { reason: "read_failed" });
  }
  if (!booking) {
    return jsonError("Booking not found", 404, { reason: "not_found" });
  }
  if (booking.user_id !== userId) {
    return jsonError("Not the booking owner", 403, { reason: "not_owner" });
  }
  if (booking.status !== "completed") {
    return jsonError("Rate only available after completion", 409, {
      reason: "not_completed",
    });
  }

  const { error: updErr } = await supabase
    .from("lawyer_bookings")
    .update({
      user_rating: body.userRating,
      user_feedback: body.userFeedback,
    })
    .eq("id", body.bookingId);
  if (updErr) {
    return jsonError("Rate update failed", 500, {
      reason: "update_failed",
      detail: updErr.message,
    });
  }

  // Refresh stats so avg_rating reflects the new score.
  if (booking.lawyer_id) {
    await supabase.rpc("refresh_partner_lawyer_stats", {
      p_lawyer: booking.lawyer_id,
    })
      .then(() => {})
      .catch((e: unknown) =>
        console.warn("[lawyer-booking] stats refresh failed:", e)
      );
  }
  return jsonOk({ ok: true });
}

// ─── op:cancel ──────────────────────────────────────────────────────────────

async function handleCancel(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  userId: string,
  body: ValidatedCancel,
): Promise<Response> {
  const { data: booking, error: readErr } = await supabase
    .from("lawyer_bookings")
    .select("id, user_id, lawyer_id, status")
    .eq("id", body.bookingId)
    .maybeSingle();
  if (readErr) {
    return jsonError("Booking read failed", 500, { reason: "read_failed" });
  }
  if (!booking) {
    return jsonError("Booking not found", 404, { reason: "not_found" });
  }
  const isOwner = booking.user_id === userId;
  const isLawyer = booking.lawyer_id === userId;
  if (!isOwner && !isLawyer) {
    return jsonError("Not authorised to cancel", 403, {
      reason: "not_authorised",
    });
  }
  if (booking.status === "completed" || booking.status === "cancelled") {
    return jsonError("Cannot cancel in current state", 409, {
      reason: "bad_state",
      state: booking.status,
    });
  }

  const { error: updErr } = await supabase
    .from("lawyer_bookings")
    .update({ status: "cancelled" })
    .eq("id", body.bookingId);
  if (updErr) {
    return jsonError("Cancel update failed", 500, {
      reason: "update_failed",
      detail: updErr.message,
    });
  }
  return jsonOk({ ok: true, status: "cancelled" });
}

// ─── Helpers ────────────────────────────────────────────────────────────────

function deriveQuarter(scheduledAt: string | null): string {
  const d = scheduledAt ? new Date(scheduledAt) : new Date();
  const q = Math.floor(d.getUTCMonth() / 3) + 1;
  return `${d.getUTCFullYear()}-Q${q}`;
}

async function loadCaseFactsIfAny(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  caseId: string | null,
  ownerId: string,
): Promise<Record<string, unknown> | null> {
  if (!caseId) return null;
  try {
    // Case facts live as structured columns on public.user_cases (there is
    // no `case_facts` column on `cases` — the prior query silently errored
    // and always returned null). Read the real fact fields here.
    //
    // IDOR guard: this runs under the service-role client (RLS bypassed),
    // and caseId is caller-supplied. The owner filter pins the read to the
    // caller's own case so a user can't pass someone else's caseId and pull
    // their private facts into the generated brief.
    const { data, error } = await supabase
      .from("user_cases")
      .select(
        "title, jurisdiction, case_type, status, case_numbers, parties, " +
          "key_dates, authorities, timeline, open_questions, next_actions, summary",
      )
      .eq("id", caseId)
      .eq("user_id", ownerId)
      .maybeSingle();
    if (error || !data) return null;
    return data as Record<string, unknown>;
  } catch (e) {
    console.warn("[lawyer-booking] case_facts read failed:", e);
    return null;
  }
}
