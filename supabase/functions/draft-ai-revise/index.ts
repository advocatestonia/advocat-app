// draft-ai-revise/index.ts — HTTP shim for the Drafting Studio AI revise tool.
// -----------------------------------------------------------------------------
// Pkg 7 Drafting Studio MVP — POST endpoint that takes a selected text fragment
// and returns Claude's suggested revision. The actual orchestration lives in
// handler.ts; this file only wires up CORS, auth, rate-limit, the Anthropic
// client, and the DB client.
//
// Endpoint:
//   POST /functions/v1/draft-ai-revise
//   Body: { draft_id, selected_text, context?, instruction?, language? }
//   Auth: Bearer <user_jwt> required (no anonymous traffic).
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
  type AnthropicCaller,
  type AnthropicRequest,
  type AnthropicResponse,
  type DraftDbClient,
  runDraftRevise,
} from "./handler.ts";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// ─── Anthropic caller — real HTTP. ──────────────────────────────────────────

const realAnthropic: AnthropicCaller = async (
  req: AnthropicRequest,
): Promise<AnthropicResponse> => {
  const r = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify(req),
  });
  if (!r.ok) {
    const text = await r.text();
    throw new Error(`Anthropic ${r.status}: ${text}`);
  }
  return (await r.json()) as AnthropicResponse;
};

// ─── DB client — real Supabase service-role lookup. ─────────────────────────

const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

const realDb: DraftDbClient = {
  async isOwner(draftId: string, userId: string): Promise<boolean> {
    const { data, error } = await supabaseAdmin
      .from("user_drafts")
      .select("id")
      .eq("id", draftId)
      .eq("user_id", userId)
      .maybeSingle();
    if (error) {
      // Treat lookup errors as not-owner so we fail closed.
      console.error("draft-ai-revise isOwner error", error);
      return false;
    }
    return data !== null;
  },
};

// ─── HTTP entry point ───────────────────────────────────────────────────────

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // Auth + 30/min user rate limit (AI revisions are short, but we don't want
  // to let a runaway script burn through tokens).
  const gate = await requireUserWithRateLimit(req, {
    bucket: "draft-ai-revise",
    maxPerMinute: 30,
  });
  if (gate.kind === "deny") return gate.response;

  let body: unknown;
  try {
    body = await req.json();
  } catch (_e) {
    return jsonError("Request body must be valid JSON", 400);
  }

  const result = await runDraftRevise(body, gate.user.id, {
    db: realDb,
    callAnthropic: realAnthropic,
  });

  if (result.kind === "success") {
    return jsonOk(result.body, result.status);
  }
  return jsonError(result.body.error, result.status);
});
