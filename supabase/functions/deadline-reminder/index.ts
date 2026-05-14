// deadline-reminder
// -----------------------------------------------------------------------------
// Sprint 0 — FIX-5 — CRITICAL: deadline-reminder auth + PII scrub
// Ref: docs/security/02-auth-authz.md C1, docs/security/07-business-logic.md
//
// Before FIX-5: this function was publicly callable (no JWT, no cron secret)
// and returned `details: notifications` containing every user's case titles
// and deadline dates. Anyone could scrape PII of all users. GDPR Art. 33
// breach risk — especially critical for a legal-defence product.
//
// After FIX-5:
//   1. Require `x-cron-secret` header matching CRON_SECRET env var.
//     - Missing header -> 401 "Missing cron secret"
//     - Wrong header   -> 401 "Invalid cron secret"
//     - No env var set -> 500 "Cron secret not configured"
//   2. Response body no longer echoes `details` (PII). Owner gets
//      `{ processed, errors }` only. Notifications still inserted into
//      the `notifications` table for in-app delivery.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { checkCronSecret } from "./auth_gate.ts";

serve(async (req) => {
  // Only POST is allowed (cron calls with POST).
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204 });
  }
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers: { "Content-Type": "application/json" } },
    );
  }

  // Gate: cron-secret header must match CRON_SECRET env var.
  const gate = checkCronSecret(
    req.headers.get("x-cron-secret"),
    Deno.env.get("CRON_SECRET"),
  );
  if (gate.kind === "deny") {
    return new Response(
      JSON.stringify(gate.body),
      { status: gate.status, headers: { "Content-Type": "application/json" } },
    );
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Find deadlines in next 3 days.
    const now = new Date();
    const threeDaysFromNow = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);

    // Active deadlines are those not yet completed. Prod schema has no
    // `status` column — it has `is_completed boolean`, `due_date date`,
    // `priority text`. Previous code referenced a non-existent `status`
    // enum, so the cron returned 500 on every run (schema drift).
    const { data: urgentDeadlines, error: fetchError } = await supabase
      .from("deadlines")
      .select("*, cases(title, user_id)")
      .gte("due_date", now.toISOString())
      .lte("due_date", threeDaysFromNow.toISOString())
      .eq("is_completed", false);

    if (fetchError) {
      console.error("deadline-reminder: fetch failed:", fetchError);
      return new Response(
        JSON.stringify({ error: "fetch_failed", detail: fetchError.message }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    if (!urgentDeadlines || urgentDeadlines.length === 0) {
      // Still return the terse shape so the cron caller can rely on it.
      return new Response(
        JSON.stringify({ processed: 0, errors: 0 }),
        { headers: { "Content-Type": "application/json" } },
      );
    }

    // Group by user.
    const byUser: Record<string, any[]> = {};
    for (const d of urgentDeadlines) {
      const userId = d.cases?.user_id || d.user_id;
      if (!userId) continue;
      if (!byUser[userId]) byUser[userId] = [];
      byUser[userId].push(d);
    }

    // For each user, load the profile and build notification rows.
    const notifications: Array<Record<string, unknown>> = [];
    let errors = 0;
    for (const [userId, deadlines] of Object.entries(byUser)) {
      const { data: profile, error: profileError } = await supabase
        .from("profiles")
        .select("email, full_name, preferred_language")
        .eq("id", userId)
        .single();

      if (profileError) {
        errors++;
        continue;
      }
      if (!profile?.email) continue;

      for (const d of deadlines) {
        const daysLeft = Math.ceil(
          (new Date(d.due_date).getTime() - now.getTime()) /
            (1000 * 60 * 60 * 24),
        );
        notifications.push({
          user_id: userId,
          type: "deadline_reminder",
          // Title/body ARE stored in the notifications table — that's fine
          // (they're per-user, RLS-scoped). They MUST NOT be in the response.
          title: `Deadline in ${daysLeft} days: ${d.title}`,
          body:
            `Your deadline "${d.title}" for case "${d.cases?.title ||
              "your case"}" is due on ${d.due_date}`,
          read: false,
        });
      }
    }

    // Insert into notifications table.
    if (notifications.length > 0) {
      const { error: insertError } = await supabase
        .from("notifications")
        .insert(notifications);

      if (insertError) {
        // No user email here — safe to log the error text.
        console.error("deadline-reminder insert failed");
        errors++;
      }
    }

    // PII-scrubbed response: counts only, never titles/emails/user IDs.
    return new Response(
      JSON.stringify({
        processed: notifications.length,
        errors,
      }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (_error) {
    // Do NOT echo error details — they can contain PII (Supabase often
    // includes the failing row data in its error messages).
    return new Response(
      JSON.stringify({ error: "Internal error" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
