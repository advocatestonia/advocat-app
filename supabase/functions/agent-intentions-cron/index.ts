// agent-intentions-cron
// -----------------------------------------------------------------------------
// v24.4 — long-horizon follow-up promises.
//
// Hourly cron Edge Function. Iterates rows in agent_intentions where
// next_check_at <= now() and completed = false, renders a localised
// notification (RU/ET/EN) using conversation_context.summary, writes it
// into the notifications table, and marks the intention complete.
//
// Auth: x-cron-secret header must match the CRON_SECRET env var
// (mirrors deadline-reminder's gate). Response body is PII-scrubbed —
// never echoes user IDs, emails, summaries, or row contents.
//
// Schedule via the existing cron trigger pattern — see
// reference_scheduled_triggers.md memory.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { checkCronSecret } from "./auth_gate.ts";
import {
  type IntentionRow,
  type MinimalSupabase,
  processDueIntentions,
} from "./processor.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204 });
  }
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      { status: 405, headers: { "Content-Type": "application/json" } },
    );
  }

  // Gate before instantiating service-role client.
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
    const client = createClient(supabaseUrl, supabaseKey);

    const adapter: MinimalSupabase = {
      async fetchDueIntentions(now, limit) {
        const { data, error } = await client
          .from("agent_intentions")
          .select(
            "id, user_id, case_id, intent_type, target_id, next_check_at, " +
              "conversation_context, completed",
          )
          .lte("next_check_at", now.toISOString())
          .eq("completed", false)
          .limit(limit);
        if (error) throw error;
        return (data ?? []) as IntentionRow[];
      },
      async fetchUserEmail(userId) {
        const { data, error } = await client
          .from("profiles")
          .select("email")
          .eq("id", userId)
          .maybeSingle();
        if (error) return null;
        return (data?.email as string | undefined) ?? null;
      },
      async insertNotification(row) {
        const { error } = await client.from("notifications").insert({
          ...row,
          read: false,
        });
        if (error) throw error;
      },
      async markIntentionComplete(id, now) {
        const { error } = await client
          .from("agent_intentions")
          .update({
            completed: true,
            last_checked_at: now.toISOString(),
            notification_sent_at: now.toISOString(),
          })
          .eq("id", id);
        if (error) throw error;
      },
    };

    const result = await processDueIntentions(adapter, new Date(), 50);

    // PII-scrubbed response: counts only, never titles/emails/user IDs.
    return new Response(
      JSON.stringify(result),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (_e) {
    // Don't echo error details — Supabase error messages may carry PII.
    return new Response(
      JSON.stringify({ error: "Internal error" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
