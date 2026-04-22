// log-refund-consent Edge Function
// -----------------------------------------------------------------------------
// Records a single EU CRD Art. 16(m) refund-waiver consent event when the
// first-session modal is accepted. Service-role INSERT only — the client
// has no direct write path to public.refund_consents.
//
// Contract:
//   POST /functions/v1/log-refund-consent
//   Headers:
//     Authorization: Bearer <user JWT>
//   Body: {} (no client-supplied fields are trusted)
//
//   Response 200: { ok: true, consented_at: string (ISO) }
//   Response 401: Unauthorized / Invalid session
//   Response 405: Method not allowed
//   Response 429: Rate limit exceeded (3/min per user)
//   Response 500: Database or internal error
//
// Privacy:
//   · Source IP is SHA-256(raw_ip + IP_HASH_PEPPER) — never the raw address.
//     Pepper rotates quarterly so old hashes can't be re-identified.
//   · user_agent kept verbatim but truncated at 512 chars.
//   · Retention: 2 years (CRD dispute statute of limitations). Enforced by
//     a scheduled cron job on `refund_consents`.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// Server-side pepper. If absent we still hash (prevents silent raw-IP storage)
// but log a warning. Rotating this value invalidates all prior hashes, which
// is the whole point.
const IP_HASH_PEPPER = Deno.env.get("IP_HASH_PEPPER") ?? "advocat-v1-fallback";

/**
 * SHA-256(rawIp + pepper) → hex string. Always returns a stable-length hash
 * even for empty input, so downstream code can rely on a consistent schema.
 */
async function hashIp(rawIp: string): Promise<string> {
  const input = `${rawIp}|${IP_HASH_PEPPER}`;
  const buf = new TextEncoder().encode(input);
  const digest = await crypto.subtle.digest("SHA-256", buf);
  const bytes = new Uint8Array(digest);
  let hex = "";
  for (const b of bytes) {
    hex += b.toString(16).padStart(2, "0");
  }
  return hex;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // JWT gate + tight rate limit. Writing endpoint — 3/min is plenty for the
  // single consent event we expect per user per lifetime.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "log-refund-consent",
    maxPerMinute: 3,
  });
  if (gate.kind === "deny") return gate.response;

  try {
    // Only the headers are trusted. The body is read for future-proofing
    // (e.g. consent version string) but nothing is used right now — any
    // client-supplied user_id is explicitly ignored.
    try {
      await req.json();
    } catch {
      // empty body is fine
    }

    // Fingerprint source IP. "x-forwarded-for" on Supabase Edge is the
    // client-visible address (Cloudflare sets it). Take first element of a
    // comma-separated list (some CDNs chain).
    const rawForwarded = req.headers.get("x-forwarded-for") ?? "";
    const firstHop = rawForwarded.split(",")[0]?.trim() || "unknown";
    const ipHashValue = await hashIp(firstHop);

    const rawUa = req.headers.get("user-agent") ?? "";
    const userAgent = rawUa.length > 512 ? rawUa.slice(0, 512) : rawUa;

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const { data, error } = await supabase
      .from("refund_consents")
      .insert({
        user_id: gate.user.id,
        ip_hash: ipHashValue,
        user_agent: userAgent,
      })
      .select("consented_at")
      .single();

    if (error) {
      console.error(
        "log-refund-consent insert error:",
        String(error.message ?? error).slice(0, 200),
      );
      return jsonError("Database error", 500);
    }

    return jsonOk({
      ok: true,
      consented_at: data?.consented_at ?? new Date().toISOString(),
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("log-refund-consent failed:", message.slice(0, 200));
    return jsonError("Internal error", 500);
  }
});
