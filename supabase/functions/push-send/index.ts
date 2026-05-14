// push-send/index.ts
// -----------------------------------------------------------------------------
// Retention Loop 2 — smart push notifications (FCM HTTP v1).
//
// This edge fn is a thin auth + audit wrapper around _shared/fcm_push.ts.
// It is callable in two modes:
//
//   1. Service-to-service (CRON_SECRET header) — other edge fns (the
//      deadline radar, the email-inbox-sync counterparty-reply hook, the
//      claude-proxy insight-ready hook) POST here to dispatch a push for
//      a specific user_id. This keeps the FCM service-account JWT path in
//      ONE place rather than duplicating it across functions.
//
//   2. End-user (Bearer JWT) — currently NOT exposed; reserved for a
//      future "send me a test push" debug button. Returns 403 today.
//
// Behaviour when FCM is NOT configured:
//   * sendPush() returns { ok: false, error: "fcm_not_configured" }.
//   * We persist a push_events row with `delivered=false`,
//     `error='fcm_not_configured'` so the owner can later replay these
//     once the service-account JSON is added to Supabase secrets.
//   * Caller sees 200 with `delivered: false` — this is INTENTIONAL.
//     Push is best-effort; the in-app banner / email is the fallback
//     channel.
//
// Throttling:
//   * Hard cap 1 reengagement push / user / 24h (enforced via push_events
//     SELECT before send).
//   * No throttle on deadline_reminder (Pkg 9 has its own dedupe key).
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

import { checkCronSecret } from "../deadline-radar-tick/auth_gate.ts";
import { isFcmConfigured, sendPush } from "../_shared/fcm_push.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const CRON_SECRET = Deno.env.get("CRON_SECRET");

type PushKind =
  | "deadline_reminder"
  | "insight_ready"
  | "counterparty_reply"
  | "reengagement";

const THROTTLED_KINDS: PushKind[] = ["reengagement", "insight_ready"];
const THROTTLE_WINDOW_HOURS: Record<PushKind, number> = {
  deadline_reminder: 0, // no throttle (Pkg 9 dedupes by threshold)
  insight_ready: 6,
  counterparty_reply: 1,
  reengagement: 24,
};

interface PushReq {
  user_id: string;
  kind: PushKind;
  title: string;
  body: string;
  data?: Record<string, string>;
  /** Optional override; defaults to the user's fcm_token from prefs. */
  fcm_token?: string;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204 });
  }
  if (req.method !== "POST") {
    return jsonResp({ error: "Method not allowed" }, 405);
  }

  const gate = checkCronSecret(req.headers.get("x-cron-secret"), CRON_SECRET);
  if (gate.kind === "deny") return jsonResp(gate.body, gate.status);

  let payload: PushReq;
  try {
    payload = await req.json();
  } catch (_) {
    return jsonResp({ error: "Invalid JSON body" }, 400);
  }

  if (!payload.user_id || !payload.kind || !payload.title || !payload.body) {
    return jsonResp(
      { error: "Fields user_id, kind, title, body are required" },
      400,
    );
  }
  const validKinds: PushKind[] = [
    "deadline_reminder",
    "insight_ready",
    "counterparty_reply",
    "reengagement",
  ];
  if (!validKinds.includes(payload.kind)) {
    return jsonResp({ error: "Invalid push kind" }, 400);
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  // Pull preferences + token
  const { data: prefsRaw } = await supabase
    .from("notification_preferences")
    .select(
      "push_enabled, push_deadline_enabled, push_insights_enabled, " +
        "push_counterparty_enabled, fcm_token",
    )
    .eq("user_id", payload.user_id)
    .maybeSingle();

  // Supabase JS types maybeSingle() as T | GenericStringError; we know the
  // shape from the select above, so cast through unknown.
  const prefs = prefsRaw as null | {
    push_enabled: boolean;
    push_deadline_enabled: boolean;
    push_insights_enabled: boolean;
    push_counterparty_enabled: boolean;
    fcm_token: string | null;
  };

  if (prefs && prefs.push_enabled === false) {
    return jsonResp({
      delivered: false,
      reason: "push_disabled_by_user",
    });
  }

  // Per-kind opt-out
  if (prefs) {
    if (payload.kind === "deadline_reminder" && prefs.push_deadline_enabled === false) {
      return jsonResp({ delivered: false, reason: "deadline_push_disabled" });
    }
    if (payload.kind === "insight_ready" && prefs.push_insights_enabled === false) {
      return jsonResp({ delivered: false, reason: "insight_push_disabled" });
    }
    if (
      payload.kind === "counterparty_reply" &&
      prefs.push_counterparty_enabled === false
    ) {
      return jsonResp({ delivered: false, reason: "counterparty_push_disabled" });
    }
  }

  const fcmToken = payload.fcm_token ?? prefs?.fcm_token ?? null;
  if (!fcmToken) {
    // Still write an audit row so we know we tried.
    await supabase.from("push_events").insert({
      user_id: payload.user_id,
      kind: payload.kind,
      title: payload.title,
      body: payload.body,
      delivered: false,
      error: "no_fcm_token",
    });
    return jsonResp({ delivered: false, reason: "no_fcm_token" });
  }

  // Throttling
  const windowH = THROTTLE_WINDOW_HOURS[payload.kind];
  if (THROTTLED_KINDS.includes(payload.kind) && windowH > 0) {
    const cutoff = new Date(Date.now() - windowH * 3600 * 1000).toISOString();
    const { data: recent } = await supabase
      .from("push_events")
      .select("id")
      .eq("user_id", payload.user_id)
      .eq("kind", payload.kind)
      .gte("sent_at", cutoff)
      .limit(1);
    if (recent && recent.length > 0) {
      return jsonResp({ delivered: false, reason: "throttled" });
    }
  }

  // Send
  const fcmConfigured = isFcmConfigured();
  const result = await sendPush({
    fcmToken,
    title: payload.title,
    body: payload.body,
    data: payload.data,
  });

  await supabase.from("push_events").insert({
    user_id: payload.user_id,
    kind: payload.kind,
    title: payload.title,
    body: payload.body,
    fcm_message_id: result.messageId ?? null,
    delivered: result.ok,
    error: result.ok ? null : (result.error ?? "unknown_error"),
  });

  // Also stamp last_push_sent_at
  await supabase
    .from("user_engagement")
    .update({ last_push_sent_at: new Date().toISOString() })
    .eq("user_id", payload.user_id);

  return jsonResp({
    delivered: result.ok,
    message_id: result.messageId ?? null,
    fcm_configured: fcmConfigured,
    error: result.ok ? null : result.error,
  });
});

function jsonResp(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
