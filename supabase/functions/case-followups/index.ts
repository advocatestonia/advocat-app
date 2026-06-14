// case-followups — Smart Case Follow-ups (Feature #2).
// -----------------------------------------------------------------------------
// JWT-gated CRUD + Haiku suggest endpoint for the SOFT next-step task list
// that lives alongside the (statutory) Deadline Radar. The chat client and
// the case-detail "Next steps" widget both call this function.
//
// Contract:
//   POST /functions/v1/case-followups
//   Headers: Authorization: Bearer <user JWT>
//   Body (discriminated on `action`):
//
//   { action: "list",     case_id }
//       -> { items: Followup[] }
//
//   { action: "suggest",  case_id, transcript }
//       -> { suggestions: { title, detail, due_offset_days }[] }
//          (does NOT persist — the client inserts the ones the user keeps)
//
//   { action: "create",   case_id, title, detail?, due_at?, source? }
//       -> { item: Followup }
//
//   { action: "complete", followup_id }
//       -> { changed: boolean }
//
//   { action: "snooze",   followup_id, new_due_at }
//       -> { changed: boolean }
//
//   { action: "dismiss",  followup_id }
//       -> { changed: boolean }
//
// Security model (mirrors case-auto-patch):
//   - JWT-gated; anonymous traffic rejected (no case ownership possible).
//   - Ownership is enforced by RLS: every read/write runs on a per-user
//     client carrying the caller's Authorization header, so the database
//     refuses rows the caller does not own. No service-role writes here.
//   - The suggest action proves case ownership via case_followups_for_case
//     (RLS) BEFORE spending a Haiku call, so a stranger cannot burn our
//     Anthropic budget against a case id they don't own.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import { isValidCaseId } from "../claude-proxy/active_case_injection.ts";
import { recordSpend } from "../_shared/spend_tracker.ts";
import { scrubAnthropicBody } from "../_shared/llm_egress/scrub_body.ts";
import {
  buildFollowupUserBlock,
  FOLLOWUP_HAIKU_MODEL,
  FOLLOWUP_HAIKU_TIMEOUT_MS,
  FOLLOWUP_MAX_TOKENS,
  FOLLOWUP_SUGGEST_SYSTEM_PROMPT,
  parseFollowupSuggestions,
} from "../_shared/followup_suggest_prompt.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const CLAUDE_API_KEY = Deno.env.get("CLAUDE_API_KEY");
const ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages";

/** Hard cap on transcript chars fed to Haiku — keeps the prompt bounded. */
const MAX_TRANSCRIPT_CHARS = 8_000;
/** Title / detail bounds (mirror the DB CHECK + column intent). */
const MAX_TITLE_CHARS = 280;
const MAX_DETAIL_CHARS = 500;

type Action = "list" | "suggest" | "create" | "complete" | "snooze" | "dismiss";

const VALID_ACTIONS: Action[] = [
  "list",
  "suggest",
  "create",
  "complete",
  "snooze",
  "dismiss",
];

const VALID_SOURCES = ["manual", "ai", "suggested"] as const;

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // ── AuthN + rate-limit. Generous: this drives an interactive list UI.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "case-followups",
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

  const authHeader = req.headers.get("Authorization") ?? "";
  const db = createClient(SUPABASE_URL, "", {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  });

  switch (action as Action) {
    case "list":
      return await handleList(db, raw);
    case "suggest":
      return await handleSuggest(db, raw);
    case "create":
      return await handleCreate(db, raw, gate.user.id);
    case "complete":
      return await handleComplete(db, raw);
    case "snooze":
      return await handleSnooze(db, raw);
    case "dismiss":
      return await handleDismiss(db, raw);
  }
});

// =============================================================================
// Action handlers
// =============================================================================

// deno-lint-ignore no-explicit-any
type Db = ReturnType<typeof createClient<any, any, any>>;

async function handleList(
  db: Db,
  raw: Record<string, unknown>
): Promise<Response> {
  const caseId = requireCaseId(raw);
  if (caseId === null) return jsonError("case_id must be a UUID", 400);

  const { data, error } = await db.rpc("case_followups_for_case", {
    p_case_id: caseId,
  });
  if (error) {
    console.warn(`case-followups list error: ${trunc(error.message)}`);
    return jsonError("Could not load follow-ups", 500);
  }
  return jsonOk({ items: data ?? [] });
}

async function handleSuggest(
  db: Db,
  raw: Record<string, unknown>
): Promise<Response> {
  const caseId = requireCaseId(raw);
  if (caseId === null) return jsonError("case_id must be a UUID", 400);

  if (!CLAUDE_API_KEY) {
    return jsonError("Suggestion backend not configured", 503);
  }

  const transcriptRaw = raw.transcript;
  if (typeof transcriptRaw !== "string") {
    return jsonError("transcript must be a string", 400);
  }
  const transcript = transcriptRaw.slice(0, MAX_TRANSCRIPT_CHARS).trim();
  if (transcript.length === 0) {
    return jsonOk({ suggestions: [] });
  }

  // Ownership pre-check via RLS-bound RPC BEFORE spending a Haiku call.
  // The RPC returns the (possibly empty) existing list; an error or a
  // thrown RLS denial both map to a refusal. We also fold the existing
  // titles into the prompt so Haiku does not re-suggest current tasks.
  const { data: existing, error: ownErr } = await db.rpc(
    "case_followups_for_case",
    { p_case_id: caseId }
  );
  if (ownErr) {
    console.warn(`case-followups suggest own-check: ${trunc(ownErr.message)}`);
    return jsonError("Forbidden", 403);
  }
  const existingTitles = Array.isArray(existing)
    ? (existing as Array<{ title?: unknown }>)
        .map((r) => (typeof r.title === "string" ? r.title : ""))
        .filter((t) => t.length > 0)
    : [];

  const snapshotJson = JSON.stringify({ existing_steps: existingTitles });
  const raw_reply = await runHaiku({
    apiKey: CLAUDE_API_KEY!,
    snapshotJson,
    transcript,
  });
  if (raw_reply === null) {
    return jsonOk({ suggestions: [], reason: "haiku_unavailable" });
  }

  const suggestions = parseFollowupSuggestions(raw_reply);
  return jsonOk({ suggestions });
}

async function handleCreate(
  db: Db,
  raw: Record<string, unknown>,
  userId: string
): Promise<Response> {
  const caseId = requireCaseId(raw);
  if (caseId === null) return jsonError("case_id must be a UUID", 400);

  const titleRaw = raw.title;
  if (typeof titleRaw !== "string") {
    return jsonError("title is required", 400);
  }
  const title = titleRaw.trim().slice(0, MAX_TITLE_CHARS);
  if (title.length === 0) {
    return jsonError("title must not be empty", 400);
  }

  let detail: string | null = null;
  if (typeof raw.detail === "string" && raw.detail.trim().length > 0) {
    detail = raw.detail.trim().slice(0, MAX_DETAIL_CHARS);
  }

  let dueAt: string | null = null;
  if (typeof raw.due_at === "string" && raw.due_at.length > 0) {
    const parsed = new Date(raw.due_at);
    if (Number.isNaN(parsed.getTime())) {
      return jsonError("due_at must be an ISO timestamp", 400);
    }
    dueAt = parsed.toISOString();
  }

  let source = "manual";
  if (
    typeof raw.source === "string" &&
    (VALID_SOURCES as readonly string[]).includes(raw.source)
  ) {
    source = raw.source;
  }

  // RLS WITH CHECK guarantees user_id = auth.uid(); we set it explicitly so
  // the NOT NULL column is satisfied and the check passes.
  const { data, error } = await db
    .from("case_followups")
    .insert({
      case_id: caseId,
      user_id: userId,
      title,
      detail,
      due_at: dueAt,
      source,
    })
    .select(
      "id, case_id, title, detail, due_at, status, source, snooze_count, created_at"
    )
    .single();

  if (error) {
    console.warn(`case-followups create error: ${trunc(error.message)}`);
    // A foreign-key / RLS failure here means the case isn't the caller's.
    return jsonError("Could not create follow-up", 400);
  }
  return jsonOk({ item: data });
}

async function handleComplete(
  db: Db,
  raw: Record<string, unknown>
): Promise<Response> {
  const id = requireFollowupId(raw);
  if (id === null) return jsonError("followup_id must be a UUID", 400);

  const { data, error } = await db.rpc("complete_case_followup", {
    p_followup_id: id,
  });
  if (error) {
    console.warn(`case-followups complete error: ${trunc(error.message)}`);
    return jsonError("Could not complete follow-up", 500);
  }
  return jsonOk(data ?? { changed: false });
}

async function handleSnooze(
  db: Db,
  raw: Record<string, unknown>
): Promise<Response> {
  const id = requireFollowupId(raw);
  if (id === null) return jsonError("followup_id must be a UUID", 400);

  const newDueRaw = raw.new_due_at;
  if (typeof newDueRaw !== "string" || newDueRaw.length === 0) {
    return jsonError("new_due_at is required", 400);
  }
  const parsed = new Date(newDueRaw);
  if (Number.isNaN(parsed.getTime())) {
    return jsonError("new_due_at must be an ISO timestamp", 400);
  }

  const { data, error } = await db.rpc("snooze_case_followup", {
    p_followup_id: id,
    p_new_due_at: parsed.toISOString(),
  });
  if (error) {
    console.warn(`case-followups snooze error: ${trunc(error.message)}`);
    return jsonError("Could not snooze follow-up", 500);
  }
  return jsonOk(data ?? { changed: false });
}

async function handleDismiss(
  db: Db,
  raw: Record<string, unknown>
): Promise<Response> {
  const id = requireFollowupId(raw);
  if (id === null) return jsonError("followup_id must be a UUID", 400);

  // Dismiss is a soft delete via RLS-bound UPDATE; no RPC needed.
  const { data, error } = await db
    .from("case_followups")
    .update({ status: "dismissed" })
    .eq("id", id)
    .select("id");
  if (error) {
    console.warn(`case-followups dismiss error: ${trunc(error.message)}`);
    return jsonError("Could not dismiss follow-up", 500);
  }
  return jsonOk({ changed: Array.isArray(data) && data.length > 0 });
}

// =============================================================================
// Helpers
// =============================================================================

function requireCaseId(raw: Record<string, unknown>): string | null {
  const v = raw.case_id;
  if (typeof v !== "string" || !isValidCaseId(v)) return null;
  return v;
}

function requireFollowupId(raw: Record<string, unknown>): string | null {
  const v = raw.followup_id;
  if (typeof v !== "string" || !isValidCaseId(v)) return null;
  return v;
}

function trunc(s: unknown): string {
  return String(s ?? "").slice(0, 200);
}

/**
 * Call Haiku for next-step suggestions. Returns the raw text reply or null on
 * any error (network, non-2xx, malformed). Best-effort spend recording.
 */
async function runHaiku(args: {
  apiKey: string;
  snapshotJson: string;
  transcript: string;
}): Promise<string | null> {
  const userBlock = buildFollowupUserBlock({
    snapshotJson: args.snapshotJson,
    transcript: args.transcript,
  });

  const requestBody = {
    model: FOLLOWUP_HAIKU_MODEL,
    max_tokens: FOLLOWUP_MAX_TOKENS,
    system: FOLLOWUP_SUGGEST_SYSTEM_PROMPT,
    messages: [{ role: "user", content: userBlock }],
  };

  const ctrl = new AbortController();
  const timeout = setTimeout(() => ctrl.abort(), FOLLOWUP_HAIKU_TIMEOUT_MS);
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
      console.warn(`case-followups: Haiku ${res.status}: ${snippet}`);
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

    let raw = "";
    for (const block of json.content) {
      if (block && block.type === "text" && typeof block.text === "string") {
        raw += block.text;
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
          FOLLOWUP_HAIKU_MODEL,
          "anthropic_haiku"
        ).catch(() => {});
      }
    } catch (_e) {
      /* never bubble */
    }

    return raw.length > 0 ? raw : null;
  } catch (e) {
    clearTimeout(timeout);
    console.warn(`case-followups: Haiku fetch failed: ${trunc(e)}`);
    return null;
  }
}
