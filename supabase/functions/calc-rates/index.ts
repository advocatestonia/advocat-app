// calc-rates Edge Function
// -----------------------------------------------------------------------------
// Serves versioned statutory rates (state fees, limitation periods, severance
// coefficients, child-support floors) for the Legal Calculators Hub. The client
// caches the response and falls back to baked-in defaults when offline, so this
// endpoint is a freshness layer — never a hard dependency.
//
// Auth: requires a logged-in user + per-minute rate limit (these are public
// reference values, but we gate to keep the function from becoming an open
// scraping target). CORS restricted to advocat.ee.
//
// The pure selection logic lives in ./rates.ts and is unit-tested separately.
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
  buildResponse,
  type CalcRateRow,
  normaliseJurisdiction,
  type SupportedJurisdiction,
} from "./rates.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  const gate = await requireUserWithRateLimit(req, {
    bucket: "calc-rates",
    maxPerMinute: 30,
  });
  if (gate.kind === "deny") return gate.response;

  let jurisdiction: SupportedJurisdiction;
  try {
    const body = await req.json();
    jurisdiction = normaliseJurisdiction(body?.jurisdiction);
  } catch (e) {
    return jsonError((e as Error).message || "invalid request", 400);
  }

  try {
    const sb = createClient(SUPABASE_URL, SERVICE_KEY, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data, error } = await sb
      .from("calc_rates")
      .select(
        "jurisdiction, rate_key, value_numeric, payload, currency, effective_from, source_label, source_url"
      )
      .eq("jurisdiction", jurisdiction);

    if (error) {
      return jsonError("rates lookup failed", 502, { detail: error.message });
    }

    const rows = (data ?? []) as CalcRateRow[];
    return jsonOk(buildResponse(jurisdiction, rows));
  } catch (e) {
    return jsonError("internal error", 500, { detail: (e as Error).message });
  }
});
