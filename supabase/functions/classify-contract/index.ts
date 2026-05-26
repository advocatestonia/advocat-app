// classify-contract/index.ts — HTTP entry for the contract auto-detection
// chip ("Review this contract") shown after a PDF upload.
// -----------------------------------------------------------------------------
// Thin shim around handler.classifyDocument():
//   - require user JWT (anon NEVER accepted)
//   - rate-limit: 30 req/min/user (UI-driven; one call per upload)
//   - load the case_documents row scoped to the caller
//   - call Claude Haiku 4.5 with the first-page text only (~ 200 tokens)
//   - return { is_contract, confidence, contract_type_hint? }
//
// All real work lives in handler.ts so tests can inject fakes for the
// document loader and the Haiku call.
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
  type ClassifyDeps,
  classifyDocument,
  type ContractTypeHint,
  type DocumentLoader,
  type DocumentRow,
  type HaikuCaller,
  type HaikuResponse,
  validateRequest,
} from "./handler.ts";
import {
  contractReviewDisabledResponse,
  flagOn,
} from "../_shared/kill_switches.ts";
import { recordSpend } from "../_shared/spend_tracker.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANTHROPIC_API_KEY = Deno.env.get("CLAUDE_API_KEY") ??
  Deno.env.get("ANTHROPIC_API_KEY");
const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";
const HAIKU_MODEL = "claude-haiku-4-5";
// Tiny output cap — the JSON shape we want is ~50 tokens; 200 leaves room
// for hint variants without ever blowing the budget.
const HAIKU_MAX_TOKENS = 200;

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // Kill switch: CONTRACT_REVIEW_DISABLED — short-circuit before classify
  // call (Haiku is cheap, but the early return saves a round-trip and
  // gives users a uniform message across both contract-review entry points).
  // See _shared/kill_switches.ts and /tmp/hn_launch_runbook.md.
  if (flagOn("CONTRACT_REVIEW_DISABLED")) {
    return contractReviewDisabledResponse();
  }

  // Auth — user JWT required; anon NEVER accepted (memory:
  // lesson_anon_jwt_bypass).
  const gate = await requireUserWithRateLimit(req, {
    bucket: "classify-contract",
    maxPerMinute: 30,
  });
  if (gate.kind === "deny") return gate.response;
  const userId = gate.user.id;
  if (userId.startsWith("anon:")) {
    return jsonError("Unauthorized", 401);
  }

  // Parse body.
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

  const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  const deps: ClassifyDeps = {
    loadDocument: buildDocumentLoader(sb),
    callHaiku: buildHaikuCaller(),
  };

  try {
    const result = await classifyDocument({
      userId,
      documentId: parsed.value.case_document_id,
      deps,
    });
    return jsonOk(result, 200);
  } catch (e) {
    // classifyDocument is designed to never throw — but defence in depth.
    console.error("[classify-contract] unhandled:", e);
    return jsonOk(
      { is_contract: false, confidence: 0, reason: "internal_error" },
      200,
    );
  }
});

// ─── DB binding ─────────────────────────────────────────────────────────────

// deno-lint-ignore no-explicit-any
type AdminClient = any;

function buildDocumentLoader(sb: AdminClient): DocumentLoader {
  return async (
    userId: string,
    documentId: string,
  ): Promise<DocumentRow | null> => {
    // Try case_documents first (parsed_text lives here per contract-review),
    // then fall back to the generic documents/file_name table used by the
    // chat upload path. Both are scoped to user_id.
    const a = await sb
      .from("case_documents")
      .select("id, user_id, filename, parsed_text")
      .eq("user_id", userId)
      .eq("id", documentId)
      .maybeSingle();
    if (a.data) {
      const row = a.data as Record<string, unknown>;
      return {
        id: row.id as string,
        user_id: row.user_id as string,
        filename: (row.filename as string) ?? "document",
        parsed_text: (row.parsed_text as string | null) ?? null,
      };
    }
    const b = await sb
      .from("documents")
      .select("id, user_id, file_name, parsed_text")
      .eq("user_id", userId)
      .eq("id", documentId)
      .maybeSingle();
    if (b.data) {
      const row = b.data as Record<string, unknown>;
      return {
        id: row.id as string,
        user_id: row.user_id as string,
        filename: (row.file_name as string) ?? "document",
        parsed_text: (row.parsed_text as string | null) ?? null,
      };
    }
    return null;
  };
}

// ─── Haiku planner binding ──────────────────────────────────────────────────

function buildHaikuCaller(): HaikuCaller {
  return async (req): Promise<HaikuResponse> => {
    if (!ANTHROPIC_API_KEY) {
      throw new Error("CLAUDE_API_KEY not configured");
    }
    const userMessage = [
      `Filename: ${req.filename}`,
      "",
      "First-page text:",
      req.documentText,
    ].join("\n");
    const res = await fetch(ANTHROPIC_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: HAIKU_MODEL,
        max_tokens: HAIKU_MAX_TOKENS,
        temperature: 0.0,
        system: req.systemPrompt,
        messages: [{ role: "user", content: userMessage }],
      }),
    });
    if (!res.ok) {
      const err = await res.text();
      throw new Error(`Anthropic ${res.status}: ${err.slice(0, 200)}`);
    }
    const json = await res.json() as {
      content?: Array<{ type: string; text?: string }>;
      usage?: {
        input_tokens?: number;
        output_tokens?: number;
        cache_creation_input_tokens?: number;
        cache_read_input_tokens?: number;
      };
    };
    // Cost-audit gap 2026-05-27: record Haiku spend for the classifier.
    // Best-effort — never block classify output, never throw.
    try {
      const u = json.usage ?? {};
      const inputTokens = (u.input_tokens ?? 0) +
        (u.cache_creation_input_tokens ?? 0) +
        (u.cache_read_input_tokens ?? 0);
      const outputTokens = u.output_tokens ?? 0;
      if (inputTokens > 0 || outputTokens > 0) {
        recordSpend(inputTokens, outputTokens, HAIKU_MODEL, "anthropic_haiku")
          .catch(() => {});
      }
    } catch (_e) { /* never bubble */ }
    const text = (json.content ?? [])
      .filter((b) => b.type === "text" && typeof b.text === "string")
      .map((b) => b.text!)
      .join("");
    const stripped = text
      .replace(/^\s*```(?:json)?\s*/i, "")
      .replace(/\s*```\s*$/i, "")
      .trim();
    let parsed: Record<string, unknown>;
    try {
      parsed = JSON.parse(stripped) as Record<string, unknown>;
    } catch (e) {
      throw new Error(
        `Haiku non-JSON: ${String(e).slice(0, 80)} :: head=${
          stripped.slice(0, 100)
        }`,
      );
    }
    const hint = parsed.contract_type_hint;
    const out: HaikuResponse = {
      is_contract: parsed.is_contract === true,
      confidence: typeof parsed.confidence === "number"
        ? parsed.confidence
        : 0,
    };
    if (typeof hint === "string" && hint.length > 0 && hint !== "null") {
      out.contract_type_hint = hint as ContractTypeHint;
    }
    return out;
  };
}
