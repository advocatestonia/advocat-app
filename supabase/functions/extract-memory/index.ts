// extract-memory Edge Function (ADR-001 Tier 1)
// -----------------------------------------------------------------------------
// Given a chat session (list of messages), asks Claude Haiku to extract a
// small set of structured facts about the user and upserts them into
// public.user_ai_memory. Triggered from the Flutter client *after* the
// assistant finishes streaming — never blocks the user-visible reply.
//
// Contract:
//   POST /functions/v1/extract-memory
//   Headers:
//     Authorization: Bearer <user JWT>
//   Body:
//     {
//       session_id?: string,              // optional — sets source_session_id
//       messages: Array<{                  // ordered, oldest first
//         role: "user" | "assistant",
//         content: string,
//         timestamp?: string
//       }>
//     }
//   Response 200:
//     { extracted: number, stored: number, duplicates: number }
//   Response 400: { error: "Invalid body" }
//   Response 401: Unauthorized
//   Response 429: Rate limit exceeded
//   Response 502: Upstream Haiku error
//
// Security:
//   - JWT-gated (shared `requireUserWithRateLimit` helper).
//   - CORS locked to advocat.ee.
//   - The body's user_id is NOT trusted — we always use gate.user.id.
//   - Haiku output is validated against a strict JSON schema; any fact
//     with an out-of-vocabulary key or out-of-range confidence is dropped.
//   - Text fields are capped to 500 chars before insert to prevent prompt
//     injection downstream when the memory block is concatenated into the
//     system prompt.
//
// Rate limit: 5 req/min per user — extraction is a per-session event, not
// per-message, so 5/min covers the worst chatty user.
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
  ALLOWED_KEYS,
  buildHaikuRequest,
  parseHaikuFacts,
  TEXT_MAX_LEN,
} from "./memory_schema.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const CLAUDE_API_KEY = Deno.env.get("CLAUDE_API_KEY");
const ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages";
const HAIKU_MODEL = "claude-haiku-4-5-20251001";

// Hard guardrails — defence in depth on top of the schema module.
const MAX_SESSION_MESSAGES = 60;
const MAX_FACTS_PER_SESSION = 10;

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // JWT gate + rate limit. Extraction is low-frequency, so 5/min is ample.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "extract-memory",
    maxPerMinute: 5,
  });
  if (gate.kind === "deny") return gate.response;

  if (!CLAUDE_API_KEY) {
    console.error("extract-memory: CLAUDE_API_KEY not configured");
    return jsonError("Extraction backend not configured", 503);
  }

  // -------------------------------------------------------------------------
  // Parse + validate request body.
  // -------------------------------------------------------------------------
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
  const rawMessages = raw.messages;
  if (!Array.isArray(rawMessages) || rawMessages.length === 0) {
    return jsonError("messages must be a non-empty array", 400);
  }
  // Never trust a body-supplied user_id (defence-in-depth — gate.user.id wins).
  if ("user_id" in raw) {
    return jsonError("user_id must not be in body — JWT identifies user", 400);
  }

  // Coerce messages to the shape Haiku expects.
  const messages: Array<{ role: string; content: string }> = [];
  for (const m of rawMessages.slice(-MAX_SESSION_MESSAGES)) {
    if (!m || typeof m !== "object") continue;
    const role = (m as Record<string, unknown>).role;
    const content = (m as Record<string, unknown>).content;
    if (typeof role !== "string" || typeof content !== "string") continue;
    if (role !== "user" && role !== "assistant") continue;
    const trimmed = content.slice(0, 4000);
    if (trimmed.length === 0) continue;
    messages.push({ role, content: trimmed });
  }
  if (messages.length === 0) {
    return jsonError("No valid messages in payload", 400);
  }

  const sessionId = typeof raw.session_id === "string" && raw.session_id.length > 0
    ? raw.session_id
    : null;

  // -------------------------------------------------------------------------
  // Ask Haiku for facts. Strict JSON schema via tool_use "extract_facts".
  // -------------------------------------------------------------------------
  const haikuBody = buildHaikuRequest(messages, HAIKU_MODEL);

  let haikuResponse: Response;
  try {
    haikuResponse = await fetch(ANTHROPIC_API_URL, {
      method: "POST",
      headers: {
        "x-api-key": CLAUDE_API_KEY,
        "anthropic-version": "2023-06-01",
        "Content-Type": "application/json",
      },
      body: JSON.stringify(haikuBody),
    });
  } catch (e) {
    console.error(
      "extract-memory: Haiku fetch failed:",
      String(e).slice(0, 200),
    );
    return jsonError("Extraction backend unreachable", 502);
  }

  if (!haikuResponse.ok) {
    const snippet = (await haikuResponse.text()).slice(0, 200);
    console.error(
      `extract-memory: Haiku ${haikuResponse.status}: ${snippet}`,
    );
    return jsonError("Extraction backend error", 502);
  }

  const haikuJson = await haikuResponse.json().catch(() => null);
  const facts = parseHaikuFacts(haikuJson).slice(0, MAX_FACTS_PER_SESSION);

  if (facts.length === 0) {
    return jsonOk({ extracted: 0, stored: 0, duplicates: 0 });
  }

  // -------------------------------------------------------------------------
  // Upsert into user_ai_memory. Unique constraint is
  // (user_id, key, value->>'text') so reinforcement becomes an UPDATE of
  // last_reinforced_at + confidence.
  // -------------------------------------------------------------------------
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  let stored = 0;
  let duplicates = 0;

  for (const fact of facts) {
    if (!ALLOWED_KEYS.has(fact.key)) continue;
    const text = fact.value.slice(0, TEXT_MAX_LEN);
    if (text.length === 0) continue;

    // Does a row with the same (user, key, text) already exist?
    const { data: existing, error: selectError } = await supabase
      .from("user_ai_memory")
      .select("id, confidence")
      .eq("user_id", gate.user.id)
      .eq("key", fact.key)
      .eq("value->>text", text)
      .limit(1);

    if (selectError) {
      console.error(
        "extract-memory: select error:",
        String(selectError.message ?? selectError).slice(0, 200),
      );
      continue;
    }

    if (existing && existing.length > 0) {
      // Reinforce — bump last_reinforced_at and take max(confidence).
      const current = existing[0] as { id: string; confidence: number };
      const newConfidence = Math.max(current.confidence, fact.confidence);
      const { error: updateError } = await supabase
        .from("user_ai_memory")
        .update({
          last_reinforced_at: new Date().toISOString(),
          confidence: newConfidence,
        })
        .eq("id", current.id);
      if (!updateError) duplicates++;
      continue;
    }

    const { error: insertError } = await supabase
      .from("user_ai_memory")
      .insert({
        user_id: gate.user.id,
        key: fact.key,
        value: {
          text,
          confidence: fact.confidence,
          extracted_from: sessionId,
        },
        confidence: fact.confidence,
        source_session_id: sessionId,
      });
    if (insertError) {
      console.error(
        "extract-memory: insert error:",
        String(insertError.message ?? insertError).slice(0, 200),
      );
      continue;
    }
    stored++;
  }

  return jsonOk({
    extracted: facts.length,
    stored,
    duplicates,
  });
});
