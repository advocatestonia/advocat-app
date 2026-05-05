// case-auto-patch — Pkg 1.C of Case Memory rebuild.
// -----------------------------------------------------------------------------
// Background patcher fired by the chat client after each AI reply on a
// case-aware turn. Asks Haiku 4.5 to extract a JSON patch describing NEW
// facts (case numbers, parties, dates, timeline, open_questions,
// next_actions, summary) and merges the patch into `user_cases`.
//
// The chat client never awaits this — the response has already shipped to
// the user. Failure is silent (the worst case is the case file lags one
// turn behind reality).
//
// Contract:
//   POST /functions/v1/case-auto-patch
//   Headers:
//     Authorization: Bearer <user JWT>
//   Body:
//     {
//       case_id: uuid,
//       user_msg: string,
//       ai_reply: string
//     }
//   Response 200:
//     { patched: true,  fields_changed: string[] }      // success
//     { patched: false, reason: "no_changes" }          // empty patch
//     { patched: false, reason: "invalid_json" }        // Haiku output garbage
//     { patched: false, reason: "haiku_unavailable" }   // upstream down
//     { patched: false, reason: "load_failed" }         // RPC error
//     { patched: false, reason: "snapshot_missing" }    // case row gone
//   Response 400: malformed body / non-UUID / missing fields
//   Response 401: missing/invalid JWT
//   Response 403: case_id is not owned by the caller (RLS reject)
//   Response 429: rate-limit exceeded
//
// Security:
//   - JWT-gated; we never accept anonymous traffic. Anon users cannot
//     own a case and cannot reach this function.
//   - Ownership pre-check via `load_active_case` RPC executed AS THE
//     USER (security invoker → RLS). RLS returns null for cases the
//     caller does not own → we map null to 403.
//   - Once ownership is proven, the merge runs on the service-role
//     client — necessary because we update jsonb columns on a row the
//     RLS policy already permitted, but the proxy fn pattern keeps the
//     actual write atomic and out of the user's PostgREST hands.
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
  CASE_PATCH_HAIKU_MODEL,
  CASE_PATCH_HAIKU_TIMEOUT_MS,
  CASE_PATCH_MAX_TOKENS,
  CASE_PATCH_SYSTEM_PROMPT,
  type CaseRowSnapshot,
  isEmptyPatch,
  mergePatchIntoSnapshot,
  parseCasePatch,
} from "../_shared/case_patch_prompt.ts";
import { isValidCaseId } from "../claude-proxy/active_case_injection.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const CLAUDE_API_KEY = Deno.env.get("CLAUDE_API_KEY");
const ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages";

/** Hard cap on input chars per side — prevents pathological prompts. */
const MAX_INPUT_CHARS = 8_000;

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // ── 1. AuthN + rate-limit. Auto-patch is per-turn; cap at 30/min/user
  //       (matches the ceiling of streamed chat turns × a couple of retries).
  const gate = await requireUserWithRateLimit(req, {
    bucket: "case-auto-patch",
    maxPerMinute: 30,
  });
  if (gate.kind === "deny") return gate.response;

  if (!CLAUDE_API_KEY) {
    console.error("case-auto-patch: CLAUDE_API_KEY not configured");
    return jsonError("Patch backend not configured", 503);
  }

  // ── 2. Parse body.
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

  const caseId = raw.case_id;
  if (typeof caseId !== "string" || caseId.length === 0) {
    return jsonError("case_id is required", 400);
  }
  if (!isValidCaseId(caseId)) {
    return jsonError("case_id must be a UUID", 400);
  }

  const userMsgRaw = raw.user_msg;
  const aiReplyRaw = raw.ai_reply;
  if (typeof userMsgRaw !== "string" || typeof aiReplyRaw !== "string") {
    return jsonError("user_msg and ai_reply must be strings", 400);
  }
  const userMsg = userMsgRaw.slice(0, MAX_INPUT_CHARS).trim();
  const aiReply = aiReplyRaw.slice(0, MAX_INPUT_CHARS).trim();
  if (userMsg.length === 0 && aiReply.length === 0) {
    return jsonError("user_msg and ai_reply are both empty", 400);
  }

  // ── 3. Ownership pre-check via load_active_case RPC as the user.
  const authHeader = req.headers.get("Authorization") ?? "";
  let snapshot: CaseRowSnapshot | null = null;
  try {
    snapshot = await loadCaseAsUser(caseId, authHeader);
  } catch (e) {
    console.warn(
      `case-auto-patch: load_active_case threw: ${
        String(e).slice(0, 200)
      }`,
    );
    return jsonOk({ patched: false, reason: "load_failed" });
  }
  if (snapshot === null) {
    // Either RLS denied (not the owner) or case doesn't exist. We surface
    // 403 so the client knows not to retry indefinitely with the wrong id.
    return jsonError("Forbidden: case not owned by caller", 403);
  }

  // ── 4. Run Haiku.
  const haikuRaw = await runHaiku({
    apiKey: CLAUDE_API_KEY,
    snapshot,
    userMsg,
    aiReply,
  });
  if (haikuRaw === null) {
    return jsonOk({ patched: false, reason: "haiku_unavailable" });
  }

  const patch = parseCasePatch(haikuRaw);
  if (patch === null) {
    return jsonOk({ patched: false, reason: "invalid_json" });
  }
  if (isEmptyPatch(patch)) {
    return jsonOk({ patched: false, reason: "no_changes" });
  }

  // ── 5. Merge into snapshot, write via service-role client.
  const merge = mergePatchIntoSnapshot(snapshot, patch);
  if (merge.fields_changed.length === 0) {
    return jsonOk({ patched: false, reason: "no_changes" });
  }

  try {
    const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    // Ownership was already proven by the RLS-bound load_active_case call
    // above; the service-role write is constrained to the same case_id and
    // additionally pinned to user_id = gate.user.id for defence-in-depth.
    const { error } = await admin
      .from("user_cases")
      .update(merge.update)
      .eq("id", caseId)
      .eq("user_id", gate.user.id);
    if (error) {
      console.warn(
        `case-auto-patch: update failed: ${
          String(error.message ?? error).slice(0, 200)
        }`,
      );
      return jsonOk({ patched: false, reason: "write_failed" });
    }
  } catch (e) {
    console.warn(
      `case-auto-patch: write threw: ${String(e).slice(0, 200)}`,
    );
    return jsonOk({ patched: false, reason: "write_failed" });
  }

  return jsonOk({
    patched: true,
    fields_changed: merge.fields_changed,
  });
});

// =============================================================================
// Helpers
// =============================================================================

/**
 * Run the `load_active_case` RPC as the calling user, returning the
 * snapshot's jsonb fields needed for the merge. `null` on:
 *   - RLS reject (user does not own the case)
 *   - case missing
 *   - any RPC / network error (we map to load_failed in the caller)
 */
async function loadCaseAsUser(
  caseId: string,
  authHeader: string,
): Promise<CaseRowSnapshot | null> {
  if (!SUPABASE_URL) return null;
  const supabase = createClient(SUPABASE_URL, "", {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await supabase.rpc("load_active_case", {
    p_case_id: caseId,
  });
  if (error) {
    console.warn(
      `case-auto-patch: load_active_case error: ${
        String(error.message ?? error).slice(0, 200)
      }`,
    );
    return null;
  }
  if (!data || typeof data !== "object") return null;
  const obj = data as Record<string, unknown>;
  const c = obj.case;
  if (!c || typeof c !== "object") return null;
  const row = c as Record<string, unknown>;
  return {
    case_numbers: row.case_numbers,
    parties: row.parties,
    authorities: row.authorities,
    key_dates: row.key_dates,
    timeline: row.timeline,
    open_questions: row.open_questions,
    next_actions: row.next_actions,
    summary: row.summary,
  };
}

/**
 * Call Haiku with the patch system prompt. Returns the raw text reply or
 * `null` on any error (network, non-2xx, malformed). 5-second timeout.
 */
async function runHaiku(args: {
  apiKey: string;
  snapshot: CaseRowSnapshot;
  userMsg: string;
  aiReply: string;
}): Promise<string | null> {
  const userBlock = [
    "<current_case_snapshot>",
    JSON.stringify(args.snapshot),
    "</current_case_snapshot>",
    "",
    "<last_user_message>",
    args.userMsg,
    "</last_user_message>",
    "",
    "<last_ai_reply>",
    args.aiReply,
    "</last_ai_reply>",
    "",
    "JSON:",
  ].join("\n");

  const requestBody = {
    model: CASE_PATCH_HAIKU_MODEL,
    max_tokens: CASE_PATCH_MAX_TOKENS,
    system: CASE_PATCH_SYSTEM_PROMPT,
    messages: [{ role: "user", content: userBlock }],
  };

  const ctrl = new AbortController();
  const timeout = setTimeout(() => ctrl.abort(), CASE_PATCH_HAIKU_TIMEOUT_MS);

  try {
    const res = await fetch(ANTHROPIC_API_URL, {
      method: "POST",
      headers: {
        "x-api-key": args.apiKey,
        "anthropic-version": "2023-06-01",
        "Content-Type": "application/json",
      },
      body: JSON.stringify(requestBody),
      signal: ctrl.signal,
    });
    clearTimeout(timeout);

    if (!res.ok) {
      const snippet = (await res.text()).slice(0, 200);
      console.warn(
        `case-auto-patch: Haiku ${res.status}: ${snippet}`,
      );
      return null;
    }
    const json = await res.json().catch(() => null) as
      | { content?: Array<{ type?: string; text?: string }> }
      | null;
    if (!json || !Array.isArray(json.content)) return null;
    // Concatenate text blocks. Haiku may chunk a long JSON across blocks.
    let raw = "";
    for (const block of json.content) {
      if (block && block.type === "text" && typeof block.text === "string") {
        raw += block.text;
      }
    }
    return raw.length > 0 ? raw : null;
  } catch (e) {
    clearTimeout(timeout);
    console.warn(
      `case-auto-patch: Haiku fetch failed: ${String(e).slice(0, 200)}`,
    );
    return null;
  }
}
