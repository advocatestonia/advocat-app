// contract-compare/index.ts — HTTP entry for Contract Version Compare.
// -----------------------------------------------------------------------------
// Internal name: Contract Version Compare. Diffs two versions (v1 -> v2) of the
// SAME contract clause-by-clause and risk-classifies each delta. Sibling of
// contract-review (which analyses ONE contract) — this function does NOT touch
// contract-review/index.ts; it reuses the shared risk vocabulary only.
//
// Thin shim (same shape as contract-review/index.ts):
//   - parse + validate JSON body
//   - require user JWT (anon NEVER accepted)
//   - build DB + planner dependencies
//   - delegate to handler.runContractCompare()
//   - serialise the structured result with CORS headers
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.8";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import {
  type CompareDbClient,
  type ComparePlannerCaller,
  type ContractCompareOutput,
  normalizeCompareOutput,
  runContractCompare,
  validateRequest,
} from "./handler.ts";
import { flagOn } from "../_shared/kill_switches.ts";
import { scrubAnthropicBody } from "../_shared/llm_egress/scrub_body.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANTHROPIC_API_KEY =
  Deno.env.get("CLAUDE_API_KEY") ?? Deno.env.get("ANTHROPIC_API_KEY");
const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";
const ANTHROPIC_MODEL = "claude-sonnet-4-6";
const ANTHROPIC_MAX_TOKENS = 8192;
const ANTHROPIC_FETCH_TIMEOUT_MS = 120_000;

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // Kill switch — shares the contract-review master switch so an incident
  // freezing review also freezes compare (same Anthropic spend surface).
  if (flagOn("CONTRACT_REVIEW_DISABLED")) {
    return jsonError("Contract Review is temporarily unavailable", 503);
  }

  // Auth — user JWT required, anon NEVER accepted.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "contract-compare",
    maxPerMinute: 5,
  });
  if (gate.kind === "deny") return gate.response;
  const userId = gate.user.id;
  if (userId.startsWith("anon:")) {
    return jsonError("Unauthorized", 401);
  }

  let raw: unknown;
  try {
    raw = await req.json();
  } catch {
    return jsonError("Invalid JSON body", 400);
  }
  const parsed = validateRequest(raw);
  if (!parsed.ok) {
    return jsonError(parsed.error, 400);
  }

  const sbAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  const db: CompareDbClient = buildDbClient(sbAdmin);
  const planner: ComparePlannerCaller = buildPlannerCaller();

  try {
    const result = await runContractCompare({
      userId,
      request: parsed.value,
      db,
      planner,
    });
    if (result.kind === "success") return jsonOk(result.body, 200);
    return new Response(JSON.stringify(result.body), {
      status: result.status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("[contract-compare] unhandled:", e);
    return jsonError("Internal error", 500);
  }
});

// ─── DB binding ─────────────────────────────────────────────────────────────

// Sidestep the supabase-js generics (same rationale as contract-review).
// deno-lint-ignore no-explicit-any
type AdminClient = any;

function buildDbClient(sb: AdminClient): CompareDbClient {
  return {
    async loadOwnedDocumentText(
      userId: string,
      documentId: string
    ): Promise<string | null> {
      const { data, error } = await sb
        .from("case_documents")
        .select("parsed_text")
        .eq("user_id", userId)
        .eq("id", documentId)
        .maybeSingle();
      if (error) {
        throw new Error(`case_documents query failed: ${error.message}`);
      }
      if (!data) return null;
      const text = (data.parsed_text as string | null) ?? null;
      return text;
    },
  };
}

// ─── Anthropic planner binding ──────────────────────────────────────────────

function buildPlannerCaller(): ComparePlannerCaller {
  return async (req): Promise<ContractCompareOutput> => {
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
          system: req.systemPrompt,
          messages: [{ role: "user", content: req.userPrompt }],
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
    const stripped = text
      .replace(/^\s*```(?:json)?\s*/i, "")
      .replace(/\s*```\s*$/i, "")
      .trim();
    let parsedJson: unknown;
    try {
      parsedJson = JSON.parse(stripped);
    } catch (e) {
      throw new Error(
        `planner returned non-JSON: ${String(e).slice(
          0,
          100
        )} :: head=${stripped.slice(0, 120)}`
      );
    }
    // Normalise here so the planner contract is always well-typed; the
    // orchestrator re-normalises defensively too (idempotent).
    const normalized = normalizeCompareOutput(parsedJson);
    if (normalized === null) {
      throw new Error("planner returned an unusable shape");
    }
    return normalized;
  };
}
