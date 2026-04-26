// Idempotency + verification helpers for stripe-webhook.
// -----------------------------------------------------------------------------
// Ref: silent-failure mode #3 — webhook returns 2xx but DB write was lost.
// Sofia's manual activation 2026-04-26 surfaced this: profiles.is_pro stayed
// false even though Stripe charged her. After this fix, a failed write throws,
// the catch branch marks status='error', and the function returns 500 so
// Stripe retries. The bug becomes loud instead of silent.
//
// Pure(ish) module: takes a SupabaseClient-shaped object so it can be unit
// tested with a mock. The runtime is Deno; the production caller passes the
// real `@supabase/supabase-js` client.
// -----------------------------------------------------------------------------

// Minimal shape of the supabase client we use here. Keeps tests lightweight.
export interface SupabaseLike {
  // deno-lint-ignore no-explicit-any
  from(table: string): any;
  // deno-lint-ignore no-explicit-any
  rpc(name: string, args?: Record<string, unknown>): any;
}

export type IdempotencyDecision =
  | { kind: "skip" } // already processed successfully
  | { kind: "process" }; // first time or retry of failed event

/**
 * Look up the event in webhook_events. If status='ok', return skip — the
 * caller short-circuits with a 200. Otherwise upsert a processing row and
 * return process.
 *
 * Throws on DB error so the outer catch can mark error+return 500.
 */
export async function checkAndMarkProcessing(
  supabase: SupabaseLike,
  eventId: string,
  eventType: string,
): Promise<IdempotencyDecision> {
  const { data: existing, error: selErr } = await supabase
    .from("webhook_events")
    .select("status")
    .eq("event_id", eventId)
    .maybeSingle();

  if (selErr) {
    // Surface DB errors loudly — better to 500 and retry than to silently
    // double-process or drop the event.
    throw new Error(`webhook_events lookup failed: ${selErr.message}`);
  }

  if (existing?.status === "ok") {
    return { kind: "skip" };
  }

  // Upsert keeps retry_count if a prior attempt existed (status='error' or
  // 'processing') — we only overwrite status back to 'processing'.
  const { error: upErr } = await supabase
    .from("webhook_events")
    .upsert(
      {
        event_id: eventId,
        event_type: eventType,
        status: "processing",
        updated_at: new Date().toISOString(),
      },
      { onConflict: "event_id" },
    );

  if (upErr) {
    throw new Error(`webhook_events upsert failed: ${upErr.message}`);
  }

  return { kind: "process" };
}

/**
 * Mark the event as successfully processed. user_id is recorded when known
 * so we can later audit "did Sofia's evt_xxx land?" without joining four tables.
 */
export async function markOk(
  supabase: SupabaseLike,
  eventId: string,
  userId: string | null,
): Promise<void> {
  const { error } = await supabase
    .from("webhook_events")
    .update({
      status: "ok",
      user_id: userId,
      updated_at: new Date().toISOString(),
    })
    .eq("event_id", eventId);

  if (error) {
    // Don't throw — the actual user-visible work succeeded; we just couldn't
    // log it. Stripe shouldn't retry on this.
    console.error(`webhook_events markOk failed for ${eventId}: ${error.message}`);
  }
}

/**
 * Mark the event as errored. Increments retry_count atomically via RPC.
 * Truncates error message to 500 chars (table constraint-friendly + GDPR).
 */
export async function markError(
  supabase: SupabaseLike,
  eventId: string,
  err: unknown,
): Promise<void> {
  try {
    await supabase.rpc("increment_webhook_retry_count", {
      p_event_id: eventId,
    });
  } catch (e) {
    console.error(`increment_webhook_retry_count failed: ${e}`);
  }

  const msg = (err instanceof Error ? err.message : String(err)).slice(0, 500);
  const { error } = await supabase
    .from("webhook_events")
    .update({
      status: "error",
      error_message: msg,
      updated_at: new Date().toISOString(),
    })
    .eq("event_id", eventId);

  if (error) {
    console.error(`webhook_events markError failed for ${eventId}: ${error.message}`);
  }
}

// ---- Verification helpers ---------------------------------------------------

/**
 * After a profiles upsert/update intended to grant Pro, read the row back and
 * confirm is_pro is the expected value. THIS is the line that would have
 * caught Sofia's bug — without it, the webhook silently returned 200 even
 * when the write evaporated.
 */
export async function verifyProfileWrite(
  supabase: SupabaseLike,
  userId: string,
  expected: { is_pro: boolean; subscription_tier?: string | null },
): Promise<void> {
  const { data, error } = await supabase
    .from("profiles")
    .select("is_pro, subscription_tier")
    .eq("id", userId)
    .single();

  if (error || !data) {
    throw new Error(
      `profile write verification FAILED for user=${userId}: ${
        error?.message ?? "no row returned"
      }`,
    );
  }
  if (data.is_pro !== expected.is_pro) {
    throw new Error(
      `profile write verification FAILED for user=${userId}: ` +
        `is_pro=${data.is_pro} expected=${expected.is_pro}`,
    );
  }
  if (
    expected.subscription_tier !== undefined &&
    expected.subscription_tier !== null &&
    data.subscription_tier !== expected.subscription_tier
  ) {
    throw new Error(
      `profile write verification FAILED for user=${userId}: ` +
        `tier=${data.subscription_tier} expected=${expected.subscription_tier}`,
    );
  }
}

/**
 * Verify the subscriptions row landed with the expected status. We don't
 * verify tier here because some callers (downgrade) intentionally leave tier
 * untouched.
 */
export async function verifySubscriptionWrite(
  supabase: SupabaseLike,
  userId: string,
  expected: { status: string },
): Promise<void> {
  const { data, error } = await supabase
    .from("subscriptions")
    .select("status")
    .eq("user_id", userId)
    .single();

  if (error || !data) {
    throw new Error(
      `subscription write verification FAILED for user=${userId}: ${
        error?.message ?? "no row returned"
      }`,
    );
  }
  if (data.status !== expected.status) {
    throw new Error(
      `subscription write verification FAILED for user=${userId}: ` +
        `status=${data.status} expected=${expected.status}`,
    );
  }
}
