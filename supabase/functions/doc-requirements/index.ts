// doc-requirements — Document-Collection Checklist (Feature #4).
// -----------------------------------------------------------------------------
// JWT-gated read of the per-problem-type document set, plus a Haiku top-up
// that proposes EXTRA documents for a non-standard situation. The base list
// lives in the seeded `doc_requirement_templates` table; this function never
// writes to the progress table (the client does that via the
// `toggle_doc_requirement` RPC).
//
// Contract:
//   POST /functions/v1/doc-requirements
//   Headers: Authorization: Bearer <user JWT>
//   Body (discriminated on `action`):
//
//   { action: "list", problem_type, jurisdiction? }
//       -> { items: Requirement[] }   (base set + caller's progress)
//
//   { action: "suggest", problem_type, jurisdiction?, situation }
//       -> { suggestions: { title, where_to_get, why_needed }[] }
//          (does NOT persist — purely advisory extras for the UI)
//
// Security model (mirrors case-followups):
//   - JWT-gated; anonymous traffic rejected.
//   - Reads run on a per-user client carrying the caller's Authorization
//     header, so the RLS-bound RPC scopes progress to the caller.
//   - The suggest action runs the SAME `list` read FIRST (cheap, RLS-bound)
//     before spending a Haiku call, and folds the base titles into the prompt
//     so Haiku never re-suggests a document already in the base list.
//   - Suggestions are advisory only and never written server-side.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import { recordSpend } from "../_shared/spend_tracker.ts";
import { scrubAnthropicBody } from "../_shared/llm_egress/scrub_body.ts";
import {
  buildDocSuggestUserBlock,
  DOC_SUGGEST_HAIKU_MODEL,
  DOC_SUGGEST_MAX_TOKENS,
  DOC_SUGGEST_SYSTEM_PROMPT,
  DOC_SUGGEST_TIMEOUT_MS,
  MAX_SITUATION_CHARS,
  parseDocSuggestions,
} from "./suggest_prompt.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const CLAUDE_API_KEY = Deno.env.get("CLAUDE_API_KEY");
const ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages";

/** Problem types the UI offers. Mirrors the seed in the migration; keeps a
 * stranger from probing arbitrary keys against the templates table. */
const VALID_PROBLEM_TYPES = [
  "residence_permit",
  "tenant_rights",
  "dismissal",
  "inheritance",
  "divorce",
] as const;

const VALID_JURISDICTIONS = ["FI", "EE", "*"] as const;

type Action = "list" | "suggest";
const VALID_ACTIONS: Action[] = ["list", "suggest"];

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  const gate = await requireUserWithRateLimit(req, {
    bucket: "doc-requirements",
    maxPerMinute: 40,
  });
  if (gate.kind === "deny") return gate.response;

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return jsonError("Invalid JSON body", 400);
  }
  if (!body || typeof body !== "object") {
    return jsonError("Invalid body", 400);
  }
  const raw = body as Record<string, unknown>;

  const action = raw.action;
  if (typeof action !== "string" || !VALID_ACTIONS.includes(action as Action)) {
    return jsonError("action must be one of: " + VALID_ACTIONS.join(", "), 400);
  }

  const problemType = normaliseProblemType(raw.problem_type);
  if (problemType === null) {
    return jsonError(
      "problem_type must be one of: " + VALID_PROBLEM_TYPES.join(", "),
      400
    );
  }
  const jurisdiction = normaliseJurisdiction(raw.jurisdiction);

  const authHeader = req.headers.get("Authorization") ?? "";
  const db = createClient(SUPABASE_URL, "", {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  });

  switch (action as Action) {
    case "list":
      return await handleList(db, problemType, jurisdiction);
    case "suggest":
      return await handleSuggest(db, raw, problemType, jurisdiction);
  }
});

// =============================================================================
// Action handlers
// =============================================================================

// deno-lint-ignore no-explicit-any
type Db = ReturnType<typeof createClient<any, any, any>>;

async function handleList(
  db: Db,
  problemType: string,
  jurisdiction: string
): Promise<Response> {
  const items = await loadRequirements(db, problemType, jurisdiction);
  if (items === null) return jsonError("Could not load requirements", 500);
  return jsonOk({ items });
}

async function handleSuggest(
  db: Db,
  raw: Record<string, unknown>,
  problemType: string,
  jurisdiction: string
): Promise<Response> {
  if (!CLAUDE_API_KEY) {
    return jsonError("Suggestion backend not configured", 503);
  }

  const situationRaw = raw.situation;
  if (typeof situationRaw !== "string") {
    return jsonError("situation must be a string", 400);
  }
  const situation = situationRaw.slice(0, MAX_SITUATION_CHARS).trim();
  if (situation.length === 0) {
    return jsonOk({ suggestions: [] });
  }

  // Load the base list FIRST (cheap, RLS-bound). Doubles as the de-dup set
  // for Haiku so it never re-suggests a document already shown.
  const base = await loadRequirements(db, problemType, jurisdiction);
  if (base === null) return jsonError("Could not load requirements", 500);

  const baseTitles = base
    .map((r) => (typeof r.title === "string" ? r.title : ""))
    .filter((t) => t.length > 0);

  const rawReply = await runHaiku({
    apiKey: CLAUDE_API_KEY!,
    problemType,
    baseTitles,
    situation,
  });
  if (rawReply === null) {
    return jsonOk({ suggestions: [], reason: "haiku_unavailable" });
  }

  const suggestions = parseDocSuggestions(rawReply, baseTitles);
  return jsonOk({ suggestions });
}

// =============================================================================
// Helpers
// =============================================================================

interface RequirementRow {
  requirement_id?: string;
  sort_order?: number;
  title?: string;
  where_to_get?: string | null;
  why_needed?: string | null;
  optional?: boolean;
  collected?: boolean;
  document_id?: string | null;
}

/**
 * Read the base requirement set + caller progress via the RLS/DEFINER RPC.
 * Returns null on a DB error (so the caller maps it to a 500).
 */
async function loadRequirements(
  db: Db,
  problemType: string,
  jurisdiction: string
): Promise<RequirementRow[] | null> {
  const { data, error } = await db.rpc("get_doc_requirements", {
    p_problem_type: problemType,
    p_jurisdiction: jurisdiction,
  });
  if (error) {
    console.warn(`doc-requirements list error: ${trunc(error.message)}`);
    return null;
  }
  return Array.isArray(data) ? (data as RequirementRow[]) : [];
}

function normaliseProblemType(v: unknown): string | null {
  if (typeof v !== "string") return null;
  return (VALID_PROBLEM_TYPES as readonly string[]).includes(v) ? v : null;
}

function normaliseJurisdiction(v: unknown): string {
  if (
    typeof v === "string" &&
    (VALID_JURISDICTIONS as readonly string[]).includes(v)
  ) {
    return v;
  }
  return "*";
}

function trunc(s: unknown): string {
  return String(s ?? "").slice(0, 200);
}

/**
 * Call Haiku for extra-document suggestions. Returns the raw text reply or
 * null on any error (network, non-2xx, malformed). Best-effort spend record.
 */
async function runHaiku(args: {
  apiKey: string;
  problemType: string;
  baseTitles: string[];
  situation: string;
}): Promise<string | null> {
  const userBlock = buildDocSuggestUserBlock({
    problemType: args.problemType,
    baseTitles: args.baseTitles,
    situation: args.situation,
  });

  const requestBody = {
    model: DOC_SUGGEST_HAIKU_MODEL,
    max_tokens: DOC_SUGGEST_MAX_TOKENS,
    system: DOC_SUGGEST_SYSTEM_PROMPT,
    messages: [{ role: "user", content: userBlock }],
  };

  const ctrl = new AbortController();
  const timeout = setTimeout(() => ctrl.abort(), DOC_SUGGEST_TIMEOUT_MS);
  try {
    const res = await fetch(ANTHROPIC_API_URL, {
      method: "POST",
      headers: {
        "x-api-key": args.apiKey,
        "anthropic-version": "2023-06-01",
        "Content-Type": "application/json",
      },
      body: JSON.stringify(scrubAnthropicBody(requestBody)),
      signal: ctrl.signal,
    });
    clearTimeout(timeout);

    if (!res.ok) {
      const snippet = (await res.text()).slice(0, 200);
      console.warn(`doc-requirements: Haiku ${res.status}: ${snippet}`);
      return null;
    }
    const json = (await res.json().catch(() => null)) as {
      content?: Array<{ type?: string; text?: string }>;
      usage?: {
        input_tokens?: number;
        output_tokens?: number;
        cache_creation_input_tokens?: number;
        cache_read_input_tokens?: number;
      };
    } | null;
    if (!json || !Array.isArray(json.content)) return null;

    let out = "";
    for (const block of json.content) {
      if (block && block.type === "text" && typeof block.text === "string") {
        out += block.text;
      }
    }

    // Best-effort spend tracking.
    try {
      const u = json.usage ?? {};
      const inputTokens =
        (u.input_tokens ?? 0) +
        (u.cache_creation_input_tokens ?? 0) +
        (u.cache_read_input_tokens ?? 0);
      const outputTokens = u.output_tokens ?? 0;
      if (inputTokens > 0 || outputTokens > 0) {
        recordSpend(
          inputTokens,
          outputTokens,
          DOC_SUGGEST_HAIKU_MODEL,
          "anthropic_haiku"
        ).catch(() => {});
      }
    } catch (_e) {
      /* never bubble */
    }

    return out.length > 0 ? out : null;
  } catch (e) {
    clearTimeout(timeout);
    console.warn(`doc-requirements: Haiku fetch failed: ${trunc(e)}`);
    return null;
  }
}
