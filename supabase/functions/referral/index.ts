// supabase/functions/referral/index.ts
// -----------------------------------------------------------------------------
// HTTP entry-point for the referral edge function.
//
// Routes:
//   POST /referral/code        → handler.handleCode
//   POST /referral/attribute   → handler.handleAttribute
//   POST /referral/stats       → handler.handleStats
//
// All routes require an authenticated user JWT (Authorization: Bearer …).
// Rate-limited via _shared/auth.requireUserWithRateLimit; the buckets are
// generous because the screen does at most ~3 calls per visit.
//
// The conversion + credit paths are NOT exposed here — they are invoked by
// stripe-webhook directly via conversion.ts. That keeps the public surface
// small and means a compromised user JWT cannot forge credit events.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import { routeReferral } from "./handler.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

/** Extract trailing path segment as the action ("code" / "attribute" / "stats"). */
function actionFromUrl(url: string): string {
  try {
    const u = new URL(url);
    const parts = u.pathname.split("/").filter(Boolean);
    // Path shape under Supabase functions:
    //   /functions/v1/referral/<action>
    // We want the last segment, but fall back gracefully if invoked at
    // /referral with a body.action.
    const last = parts[parts.length - 1] ?? "";
    if (last === "referral" || last === "") return "";
    return last;
  } catch {
    return "";
  }
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // 30/min/user is generous — Settings screen does ~3 calls/visit, mobile
  // share sheets occasionally retry on cold start.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "referral",
    maxPerMinute: 30,
  });
  if (gate.kind === "deny") return gate.response;
  const userId = gate.user.id;
  // Anonymous principals get `anon:<ip>` — rejected here because referral
  // actions require a real user. anonymousPerMinute is 0 in the gate above
  // so we should never see this in practice; defence-in-depth.
  if (userId.startsWith("anon:")) {
    return jsonError("Unauthorized", 401);
  }

  // Parse body (optional — most routes have no payload).
  let body: Record<string, unknown> = {};
  if (req.headers.get("Content-Length") !== "0") {
    try {
      const raw = await req.text();
      if (raw.length > 0) {
        body = JSON.parse(raw);
        if (typeof body !== "object" || body === null) body = {};
      }
    } catch {
      return jsonError("Invalid JSON body", 400);
    }
  }

  // Action from URL (preferred) or body.action (fallback).
  let action = actionFromUrl(req.url);
  if (!action && typeof body.action === "string") action = body.action;
  if (!action) return jsonError("Missing action", 400);

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  try {
    const result = await routeReferral(supabase, {
      action,
      userId,
      body,
    });
    return new Response(JSON.stringify(result.body), {
      status: result.status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.error(`referral: unhandled error: ${msg.slice(0, 500)}`);
    return jsonError("Internal error", 500);
  }
});

// Marker so other modules can detect when the entry point is loaded (used
// by smoke tests).
export const __referralEntryLoaded = true;
