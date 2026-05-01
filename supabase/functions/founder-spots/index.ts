// founder-spots Edge Function — public read-only Early Access counter
// -----------------------------------------------------------------------------
// Returns the current state of the 100-slot founder program:
//
//   GET /functions/v1/founder-spots
//
//   200 OK
//   {
//     "taken": 47,       // active + trialing rows with intro_type='early-access-100'
//     "remaining": 53,   // 100 - taken (clamped to ≥0)
//     "total": 100,      // hardcoded cap; mirrors create-checkout
//     "closed": false    // true iff taken >= 100
//   }
//
// No JWT required — landing page calls this from unauthenticated visitors.
// We use a permissive CORS header (any origin) since the landing is hosted
// on advocat.ee but the function may also be embedded in marketing pages
// or partner sites; the data is non-sensitive aggregate counters.
//
// Caching:
//   Cache-Control: public, max-age=60
//   60 s is short enough that a visitor refreshing after canceling sees
//   their slot freed within a minute, but long enough that a single Reddit
//   post linking to the landing doesn't melt our DB.
//
// Auth on the DB side: this function uses the service-role key to read
// `subscriptions` because that table has RLS that blocks anon SELECT.
// The function itself is the trust boundary — only the count is exposed,
// never row contents.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

export const FOUNDER_TOTAL = 100;
export const INTRO_TYPE = "early-access-100";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
  "Access-Control-Allow-Headers":
    "Authorization, Content-Type, apikey, x-client-info",
  "Vary": "Origin",
};

const cacheHeaders: Record<string, string> = {
  "Cache-Control": "public, max-age=60",
};

/** Build the public response body. Pure for testability. */
export function buildSpotsBody(taken: number) {
  const safeTaken = Math.max(0, Math.floor(taken));
  const remaining = Math.max(0, FOUNDER_TOTAL - safeTaken);
  return {
    taken: safeTaken,
    remaining,
    total: FOUNDER_TOTAL,
    closed: safeTaken >= FOUNDER_TOTAL,
  };
}

/**
 * Count active+trialing subscriptions with the founder intro_type.
 * Typed as `any` because Deno's strict type-checker bristles at the
 * supabase-js generic-default mismatch when the function is called from
 * test code that constructs a client without the generated DB types.
 * The runtime contract is enforced by the source-shape tests.
 */
// deno-lint-ignore no-explicit-any
export async function countFounderSeats(supabase: any): Promise<number> {
  const { count, error } = await supabase
    .from("subscriptions")
    .select("*", { count: "exact", head: true })
    .eq("intro_type", INTRO_TYPE)
    .in("status", ["active", "trialing"]);
  if (error) {
    throw new Error(`founder-spots: count query failed: ${error.message}`);
  }
  return count ?? 0;
}

/** HTTP handler — exported for testability. */
export async function handle(req: Request): Promise<Response> {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "GET") {
    return new Response(
      JSON.stringify({ error: "Method not allowed" }),
      {
        status: 405,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }

  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const taken = await countFounderSeats(supabase);
    const body = buildSpotsBody(taken);
    return new Response(JSON.stringify(body), {
      status: 200,
      headers: {
        ...corsHeaders,
        ...cacheHeaders,
        "Content-Type": "application/json",
      },
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    // Truncate so we don't leak DB internals.
    console.error("founder-spots failed:", message.slice(0, 200));
    // Fail-open with conservative defaults so the landing page renders even
    // if the DB is unreachable: show 0 taken so visitors aren't blocked from
    // attempting checkout. The cap is re-checked in create-checkout anyway.
    return new Response(
      JSON.stringify({
        taken: 0,
        remaining: FOUNDER_TOTAL,
        total: FOUNDER_TOTAL,
        closed: false,
        degraded: true,
      }),
      {
        status: 200,
        headers: {
          ...corsHeaders,
          "Cache-Control": "public, max-age=10",
          "Content-Type": "application/json",
        },
      },
    );
  }
}

// Only bind a TCP listener when this file is the entry point — i.e. when
// the Edge runtime executes it. Importing it from tests must not start a
// server (port-binding requires --allow-net we don't need for tests).
if (import.meta.main) {
  serve(handle);
}
