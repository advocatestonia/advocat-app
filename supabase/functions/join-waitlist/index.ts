// join-waitlist Edge Function
// -----------------------------------------------------------------------------
// Appends an email to public.waitlist when the Founder's Beta cap is full.
// Called from the client after create-checkout returns `beta_cap_full: true`
// or directly from a landing-page CTA.
//
// Unauthenticated on purpose: the whole point is to capture signal from
// visitors who can't check out. Rate-limited by IP (anonymous fallback in
// requireUserWithRateLimit). Email is the unique key — duplicate joins are
// idempotent, not errors.
//
// Contract:
//   POST /functions/v1/join-waitlist
//   Body: { email: string, source?: string }
//
//   Response 200: { ok: true, already_joined: boolean, position: number | null }
//   Response 400: { error: "Invalid email" }
//   Response 429: Rate limit exceeded
//   Response 500: Database error
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

// RFC 5321 permits much more, but this covers 99.9% of real users and
// keeps the regex tractable. Invalid addresses get 400, never a DB write.
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // Anonymous-friendly gate: allow unauthenticated, but rate-limit by IP
  // at 3/min to prevent email enumeration / spam floods.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "join-waitlist",
    maxPerMinute: 5,
    anonymousPerMinute: 3,
  });
  if (gate.kind === "deny") return gate.response;

  let email: string;
  let source: string | null = null;
  try {
    const body = await req.json();
    if (!body || typeof body !== "object") {
      return jsonError("Invalid body", 400);
    }
    const rawEmail = body.email;
    if (typeof rawEmail !== "string" || !EMAIL_RE.test(rawEmail.trim())) {
      return jsonError("Invalid email", 400);
    }
    email = rawEmail.trim().toLowerCase();

    if (typeof body.source === "string" && body.source.length <= 64) {
      source = body.source;
    }
  } catch {
    return jsonError("Invalid JSON", 400);
  }

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Idempotent INSERT: unique(email) constraint means re-joining is a
    // no-op, not an error. We check first so we can tell the client
    // whether this was a new join or a repeat.
    const { data: existing } = await supabase
      .from("waitlist")
      .select("id, created_at")
      .eq("email", email)
      .maybeSingle();

    if (existing) {
      return jsonOk({
        ok: true,
        already_joined: true,
        position: null, // position on repeat joins is not disclosed
      });
    }

    const { error: insertError } = await supabase
      .from("waitlist")
      .insert({ email, source });

    if (insertError) {
      // Race: two concurrent joins. unique(email) catches it.
      const isDup = String(insertError.code ?? "") === "23505";
      if (isDup) {
        return jsonOk({ ok: true, already_joined: true, position: null });
      }
      console.error(
        "join-waitlist insert error:",
        String(insertError.message ?? insertError).slice(0, 200),
      );
      return jsonError("Database error", 500);
    }

    // Compute 1-based position = COUNT(waitlist). We query after the
    // insert so the new row is included.
    const { count, error: countError } = await supabase
      .from("waitlist")
      .select("id", { head: true, count: "exact" });

    if (countError) {
      // Non-fatal: the user is on the list, we just don't know the
      // position. Return null rather than failing the call.
      return jsonOk({ ok: true, already_joined: false, position: null });
    }

    return jsonOk({
      ok: true,
      already_joined: false,
      position: count ?? null,
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("join-waitlist failed:", message.slice(0, 200));
    return jsonError("Internal error", 500);
  }
});
