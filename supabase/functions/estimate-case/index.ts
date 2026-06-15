// estimate-case Edge Function
// -----------------------------------------------------------------------------
// Feature #6 — Case Cost & Risk Estimator.
//
// Single-shot analytical endpoint. The user describes a problem (type, amount,
// jurisdiction) and gets back a ROUGH estimate: cost bands (court fee / lawyer
// fee / total), a duration band, factors for/against, and a coarse strength
// traffic-light (worth_pursuing | contested | weak). NEVER a "% chance of
// winning" — see estimator.ts for the trust-safety rationale.
//
// Contract:
//   POST /functions/v1/estimate-case
//   Headers: Authorization: Bearer <user JWT>
//   Body: {
//     case_type: string,            // required
//     jurisdiction: string,         // required
//     dispute_amount_eur?: number,  // optional (non-monetary matters allowed)
//     description?: string,
//     b2b_mode?: boolean
//   }
//   Response 200: { estimate: CaseEstimate, estimate_id?: string }
//   Response 400 / 401 / 429 / 500 on error.
//
// Read-mostly: the only write is an INSERT into public.case_estimates (the
// user's own history). A persist failure does NOT fail the request — the
// estimate is still returned.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import { scrubAnthropicBody } from "../_shared/llm_egress/scrub_body.ts";
import {
  buildUserPrompt,
  type CaseEstimate,
  ESTIMATOR_SYSTEM_PROMPT,
  normalizeOutput,
  parseModelJson,
  validateInput,
} from "./estimator.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANTHROPIC_API_KEY =
  Deno.env.get("CLAUDE_API_KEY") ?? Deno.env.get("ANTHROPIC_API_KEY") ?? "";

const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";
const ANTHROPIC_MODEL = "claude-sonnet-4-6";
const ANTHROPIC_MAX_TOKENS = 1500;
const ANTHROPIC_FETCH_TIMEOUT_MS = 45_000;

async function callModel(userPrompt: string): Promise<CaseEstimate> {
  if (!ANTHROPIC_API_KEY) {
    throw new Error("CLAUDE_API_KEY not configured");
  }
  const res = await fetch(ANTHROPIC_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify(
      scrubAnthropicBody({
        model: ANTHROPIC_MODEL,
        max_tokens: ANTHROPIC_MAX_TOKENS,
        temperature: 0.0,
        system: ESTIMATOR_SYSTEM_PROMPT,
        messages: [{ role: "user", content: userPrompt }],
      })
    ),
    signal: AbortSignal.timeout(ANTHROPIC_FETCH_TIMEOUT_MS),
  });
  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Anthropic ${res.status}: ${err.slice(0, 200)}`);
  }
  const json = (await res.json()) as {
    content?: Array<{ type: string; text?: string }>;
  };
  const text = (json.content ?? [])
    .filter((b) => b.type === "text" && typeof b.text === "string")
    .map((b) => b.text!)
    .join("");
  return normalizeOutput(parseModelJson(text));
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // JWT gate + rate limit. AI-backed, so keep it modest.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "estimate-case",
    maxPerMinute: 10,
  });
  if (gate.kind === "deny") return gate.response;

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return jsonError("Invalid JSON body", 400);
  }

  const validated = validateInput(body);
  if (!validated.ok) {
    return jsonError(validated.error, 400);
  }
  const input = validated.value;

  let estimate: CaseEstimate;
  try {
    estimate = await callModel(buildUserPrompt(input));
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("estimate-case model error:", message.slice(0, 200));
    return jsonError("Could not generate estimate. Please try again.", 502);
  }

  // Persist to history (best-effort — never blocks the response).
  let estimateId: string | undefined;
  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const { data, error } = await supabase
      .from("case_estimates")
      .insert({
        user_id: gate.user.id,
        case_type: input.caseType,
        jurisdiction: input.jurisdiction,
        dispute_amount_eur: input.disputeAmountEur,
        description: input.description || null,
        b2b_mode: input.b2bMode,
        court_fee_low_eur: estimate.courtFee.low,
        court_fee_high_eur: estimate.courtFee.high,
        lawyer_fee_low_eur: estimate.lawyerFee.low,
        lawyer_fee_high_eur: estimate.lawyerFee.high,
        total_low_eur: estimate.total.low,
        total_high_eur: estimate.total.high,
        duration_low_months: estimate.durationMonths.low,
        duration_high_months: estimate.durationMonths.high,
        strength: estimate.strength,
        factors_for: estimate.factorsFor,
        factors_against: estimate.factorsAgainst,
        recommendation: estimate.recommendation || null,
        next_step: estimate.nextStep || null,
        raw_output: estimate,
      })
      .select("id")
      .single();
    if (error) {
      console.error(
        "estimate-case persist error:",
        String(error.message).slice(0, 200)
      );
    } else {
      estimateId = data?.id as string | undefined;
    }
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("estimate-case persist exception:", message.slice(0, 200));
  }

  return jsonOk({ estimate, estimate_id: estimateId });
});
