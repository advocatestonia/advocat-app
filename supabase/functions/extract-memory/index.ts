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
import { recordSpend } from "../_shared/spend_tracker.ts";
import {
  ALLOWED_KEYS,
  buildHaikuRequest,
  buildQuickProfileHaikuRequest,
  partitionFactsForUpsert,
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

  // Quick Profile intake variant (2026-05-05) — when the body has
  // `intake: 'quick_profile'`, use a focused extraction prompt that
  // pulls ONLY legal_status / nationality / residence_status. This
  // avoids polluting memory with tone/preference noise from a one-line
  // intake answer like "I'm an Estonian citizen".
  const isQuickProfileIntake = raw.intake === "quick_profile";

  // -------------------------------------------------------------------------
  // Ask Haiku for facts. Strict JSON schema via tool_use "extract_facts".
  // -------------------------------------------------------------------------
  const haikuBody = isQuickProfileIntake
    ? buildQuickProfileHaikuRequest(messages, HAIKU_MODEL)
    : buildHaikuRequest(messages, HAIKU_MODEL);

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

  // Cost-audit gap 2026-05-27: record Haiku spend on extract-memory. The
  // shape is the standard Anthropic usage block. Best-effort — never block
  // the extract response, never throw.
  try {
    const u = (haikuJson && typeof haikuJson === "object" &&
      (haikuJson as Record<string, unknown>).usage &&
      typeof (haikuJson as Record<string, unknown>).usage === "object")
      ? ((haikuJson as Record<string, unknown>).usage as Record<string, unknown>)
      : null;
    if (u) {
      const inputTokens = Number(u.input_tokens ?? 0) +
        Number(u.cache_creation_input_tokens ?? 0) +
        Number(u.cache_read_input_tokens ?? 0);
      const outputTokens = Number(u.output_tokens ?? 0);
      if (inputTokens > 0 || outputTokens > 0) {
        recordSpend(inputTokens, outputTokens, HAIKU_MODEL, "anthropic_haiku")
          .catch(() => {});
      }
    }
  } catch (_e) { /* never bubble */ }

  const facts = parseHaikuFacts(haikuJson).slice(0, MAX_FACTS_PER_SESSION);

  if (facts.length === 0) {
    return jsonOk({ extracted: 0, stored: 0, duplicates: 0 });
  }

  // -------------------------------------------------------------------------
  // Upsert into user_ai_memory. Unique constraint is
  // (user_id, key, value->>'text') so reinforcement becomes an UPDATE of
  // last_reinforced_at + confidence.
  //
  // BUG#1 fix (2026-04-29): the legacy code ran SELECT + INSERT/UPDATE
  // PER FACT — 10 facts = 21 round-trips. The new code batches:
  //   1) one SELECT with `.in("key", […])` to pull all candidate
  //      collisions for this user;
  //   2) `partitionFactsForUpsert` decides reinforce-vs-new in memory
  //      while preserving the max-confidence rule;
  //   3) one UPSERT with `onConflict: "user_id,key,value->>text"`.
  // Total DB round-trips: 2, regardless of fact count.
  // -------------------------------------------------------------------------
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  // Trim & filter facts up-front (matches legacy guard behaviour).
  const cleanFacts = facts
    .filter((f) => ALLOWED_KEYS.has(f.key))
    .map((f) => ({
      key: f.key,
      value: f.value.slice(0, TEXT_MAX_LEN),
      confidence: f.confidence,
    }))
    .filter((f) => f.value.length > 0);

  if (cleanFacts.length === 0) {
    return jsonOk({ extracted: facts.length, stored: 0, duplicates: 0 });
  }

  // Step 1 — single batched SELECT for every key Haiku returned.
  const candidateKeys = Array.from(new Set(cleanFacts.map((f) => f.key)));
  const { data: existingRows, error: selectError } = await supabase
    .from("user_ai_memory")
    .select("id, key, confidence, value")
    .eq("user_id", gate.user.id)
    .in("key", candidateKeys);

  if (selectError) {
    console.error(
      "extract-memory: batch select error:",
      String(selectError.message ?? selectError).slice(0, 200),
    );
    return jsonError("Database error during fact lookup", 502);
  }

  // Coerce to the helper's input shape — pull the embedded `text` out
  // of the JSON column.
  const existing = (existingRows ?? [])
    .map((r) => {
      const v = (r as { value?: { text?: unknown } }).value;
      const text = v && typeof v.text === "string" ? v.text : "";
      return {
        id: (r as { id: string }).id,
        key: (r as { key: string }).key,
        text,
        confidence: (r as { confidence: number }).confidence,
      };
    })
    .filter((r) => r.text.length > 0);

  // Step 2 — partition in memory.
  const partition = partitionFactsForUpsert({
    facts: cleanFacts,
    existing,
    userId: gate.user.id,
    sessionId,
  });

  // Step 3 — single batched UPSERT.
  let stored = 0;
  let duplicates = partition.duplicates;
  if (partition.rows.length > 0) {
    const { error: upsertError } = await supabase
      .from("user_ai_memory")
      .upsert(partition.rows, {
        onConflict: "user_id,key,value->>text",
        ignoreDuplicates: false,
      });
    if (upsertError) {
      console.error(
        "extract-memory: batch upsert error:",
        String(upsertError.message ?? upsertError).slice(0, 200),
      );
      return jsonError("Database error during memory upsert", 502);
    }
    stored = partition.newCount;
  } else {
    duplicates = 0;
  }

  return jsonOk({
    extracted: facts.length,
    stored,
    duplicates,
  });
});
