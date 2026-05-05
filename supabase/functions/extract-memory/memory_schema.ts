// Haiku request builder + response parser for extract-memory.
// -----------------------------------------------------------------------------
// Split out from index.ts so the pure functions are testable without
// spinning up Deno.serve. Keep zero I/O in this file.
// -----------------------------------------------------------------------------

/**
 * Bounded vocabulary of memory keys.
 * MUST stay in sync with:
 *   - the SQL doc comment on public.user_ai_memory.key
 *   - the "key" enum inside the Haiku JSON schema below
 *   - lib/models/user_memory.dart (Dart client)
 *
 * 2026-05-05 expansion (Visioning Council #1 priority): legal_status,
 * nationality, residence_status — these gate which body of law applies
 * to the user (Estonian Aliens Act vs EU directives vs civil/criminal),
 * so they are the highest-leverage facts to remember.
 */
export const ALLOWED_KEYS: Set<string> = new Set([
  "name",
  "tone",
  "emotional_state",
  "case_focus",
  "known_party",
  "deadline",
  "user_goal",
  "preference",
  "background",
  "discussed_topic",
  "legal_status",
  "nationality",
  "residence_status",
]);

/** Hard cap on the `text` field for a single fact. */
export const TEXT_MAX_LEN = 500;

/** Max facts Haiku may return per session — mirror the schema maxItems. */
export const MAX_FACTS = 10;

export interface ExtractedFact {
  key: string;
  value: string;
  confidence: number;
}

/**
 * Row already present in `user_ai_memory` for this (user_id, key, text)
 * triple — used by [partitionFactsForUpsert] to decide whether each
 * incoming fact is a "new" insert or a "reinforcement" of an existing row.
 */
export interface ExistingMemoryRow {
  id: string;
  key: string;
  text: string;
  confidence: number;
}

/**
 * Row shape ready for `supabase.from("user_ai_memory").upsert(rows, …)`.
 *
 * - `last_reinforced_at` is set ONLY for reinforcements, so on a fresh
 *   insert the database default fires.
 * - `value` is the JSON column; `confidence` is the numeric column kept
 *   in sync at the row level (the JSON copy is informational).
 */
export interface MemoryUpsertRow {
  user_id: string;
  key: string;
  value: {
    text: string;
    confidence: number;
    extracted_from: string | null;
  };
  confidence: number;
  source_session_id: string | null;
  last_reinforced_at?: string;
}

export interface PartitionResult {
  rows: MemoryUpsertRow[];
  /** Number of facts that match an existing row (= reinforcements). */
  duplicates: number;
  /** Number of facts that have no existing row (= new inserts). */
  newCount: number;
}

/**
 * Pure helper — split [BUG#1, 2026-04-29].
 *
 * Replaces the legacy per-fact loop in index.ts that ran SELECT then
 * INSERT/UPDATE per fact (= O(N) round-trips). Caller now does:
 *   1) one batched SELECT to pull rows whose `key` is in the new keyset
 *   2) call this helper to decide which rows go to which path
 *   3) one batched UPSERT with `onConflict: "user_id,key,value->>text"`
 *
 * Confidence rule (preserved from legacy code, see index.ts:201-208):
 *   reinforced.confidence = max(existing.confidence, fact.confidence)
 * — a weaker reinforcement must NEVER lower a stronger stored confidence.
 *
 * Duplicate-input rule (NEW):
 *   if Haiku emits the same (key, text) twice in one batch, we collapse
 *   to one row with the max confidence. Without this, the upsert would
 *   conflict-on-itself and Postgres would error.
 */
export function partitionFactsForUpsert(args: {
  facts: ExtractedFact[];
  existing: ExistingMemoryRow[];
  userId: string;
  sessionId: string | null;
}): PartitionResult {
  const { facts, existing, userId, sessionId } = args;

  // Index existing rows by their (key, text) tuple so we can look up in O(1).
  // Multiple existing rows for the same key are possible (different texts);
  // a Map keyed on `${key}\u0000${text}` keeps them apart.
  const existingByTuple = new Map<string, ExistingMemoryRow>();
  for (const row of existing) {
    existingByTuple.set(`${row.key}\u0000${row.text}`, row);
  }

  // Collapse duplicate (key, text) inputs to a single row carrying max
  // confidence. Insertion order is preserved so the test assertion on
  // "first 5 reinforced, last 5 new" holds.
  const collapsedByTuple = new Map<string, ExtractedFact>();
  for (const fact of facts) {
    const tk = `${fact.key}\u0000${fact.value}`;
    const prev = collapsedByTuple.get(tk);
    if (prev === undefined || fact.confidence > prev.confidence) {
      collapsedByTuple.set(tk, fact);
    }
  }

  const rows: MemoryUpsertRow[] = [];
  let duplicates = 0;
  let newCount = 0;
  const nowIso = new Date().toISOString();

  for (const fact of collapsedByTuple.values()) {
    const tk = `${fact.key}\u0000${fact.value}`;
    const existingRow = existingByTuple.get(tk);

    if (existingRow !== undefined) {
      // Reinforcement: keep stronger confidence, bump last_reinforced_at.
      const finalConfidence = Math.max(
        existingRow.confidence,
        fact.confidence,
      );
      rows.push({
        user_id: userId,
        key: fact.key,
        value: {
          text: fact.value,
          confidence: finalConfidence,
          extracted_from: sessionId,
        },
        confidence: finalConfidence,
        source_session_id: sessionId,
        last_reinforced_at: nowIso,
      });
      duplicates++;
    } else {
      rows.push({
        user_id: userId,
        key: fact.key,
        value: {
          text: fact.value,
          confidence: fact.confidence,
          extracted_from: sessionId,
        },
        confidence: fact.confidence,
        source_session_id: sessionId,
      });
      newCount++;
    }
  }

  return { rows, duplicates, newCount };
}

/**
 * Quick Profile intake — bounded vocabulary subset (2026-05-05).
 *
 * The intake message is a one-shot question on first chat. We constrain
 * extraction to the legal-status trio so a one-line answer like
 * "I'm an Estonian citizen" cannot pollute memory with junk facts
 * (tone, emotional_state, etc.). Must be a strict subset of [ALLOWED_KEYS].
 */
export const QUICK_PROFILE_ALLOWED_KEYS: Set<string> = new Set([
  "legal_status",
  "nationality",
  "residence_status",
]);

/**
 * System prompt seen by Haiku — tuned to suppress invention and stay
 * within the bounded vocabulary.
 */
export const SYSTEM_PROMPT = [
  "You extract structured facts about a user from a legal-assistance chat ",
  "transcript. Output JSON only via the extract_facts tool.\n\n",
  "Rules:\n",
  "1. Only include facts EXPLICITLY stated by the user or strongly implied ",
  "by their message. Never invent.\n",
  "2. Skip obvious facts that apply to every user (e.g. \"user is looking ",
  "for legal help\"). Focus on things that differentiate this user.\n",
  "3. Keep each `value` under 500 characters and in the user's primary ",
  "language. Write in the second person (\"You prefer short answers\") so ",
  "it reads naturally back to the model.\n",
  "4. Confidence 0.9+ only for direct quotes. 0.5-0.8 for reasonable ",
  "inference. Below 0.5 — do not include.\n",
  "5. Return at most 10 facts. Prefer fewer, high-value facts over noise.\n",
  "6. Do NOT repeat facts across multiple keys.\n",
  "7. PRIORITY KEYS — extract these aggressively when present, they gate ",
  "which body of law applies:\n",
  "   • legal_status — one of: citizen | eu_citizen | 3rd_country | ",
  "asylum_seeker | refugee | stateless | other. Example: \"3rd country ",
  "national with humanitarian residence permit\".\n",
  "   • nationality — ISO country code (RU, EE, FI, UA, …). Example: \"RU\".\n",
  "   • residence_status — one of: permanent | temporary | humanitarian | ",
  "undefined. Example: \"temporary residence permit, expires 2027\".\n",
  "   These three are MORE valuable than any tone/preference fact — they ",
  "decide whether Estonian Aliens Act, EU directives, or civil/criminal ",
  "law applies. Extract them whenever the user mentions citizenship, a ",
  "residence permit, asylum, or which country they hold a passport from.\n",
].join("");

/**
 * Quick Profile intake system prompt (2026-05-05).
 *
 * Used when the request body has `intake: 'quick_profile'`. The user's
 * single answer is a status declaration ("Estonian citizen", "EU citizen",
 * "I have a residence permit") — we extract ONLY the legal-status trio
 * and nothing else. Pollution from this turn would teach the model
 * spurious tone/preference facts from a one-line reply.
 */
export const QUICK_PROFILE_SYSTEM_PROMPT = [
  "You are processing a one-shot intake answer where the user has just ",
  "told us their legal/citizenship status. Extract ONLY these three keys, ",
  "nothing else:\n",
  "  • legal_status — one of: citizen | eu_citizen | 3rd_country | ",
  "asylum_seeker | refugee | stateless | other.\n",
  "  • nationality — ISO country code (RU, EE, FI, UA, …) when stated.\n",
  "  • residence_status — one of: permanent | temporary | humanitarian | ",
  "undefined, when the user mentions a residence permit.\n\n",
  "Rules:\n",
  "1. Output JSON only via the extract_facts tool.\n",
  "2. Do NOT extract tone, emotional_state, preference, known_party, ",
  "case_focus, or any other key — even if the answer hints at them. ",
  "Pollution from a one-line reply teaches the model spurious facts.\n",
  "3. Keep each `value` under 500 characters and write in the second ",
  "person (\"You are an Estonian citizen\").\n",
  "4. Confidence 0.9+ only when the user states the status directly. ",
  "0.5-0.8 for inference. Below 0.5 — drop.\n",
  "5. If the user skipped or gave a non-status answer, return an empty ",
  "facts array.\n",
].join("");

/**
 * Builds the Anthropic Messages API request for the Quick Profile intake.
 *
 * Differs from [buildHaikuRequest] in two ways:
 *   - the tool schema's `key` enum is restricted to
 *     [QUICK_PROFILE_ALLOWED_KEYS] (the legal-status trio);
 *   - the system prompt is [QUICK_PROFILE_SYSTEM_PROMPT], which forbids
 *     extracting tone/preference/etc. from the intake reply.
 *
 * Everything else (max_tokens, temperature=0, tool_choice, transcript
 * formatting) is identical so the caller in index.ts can swap builders
 * with no other change.
 */
export function buildQuickProfileHaikuRequest(
  messages: Array<{ role: string; content: string }>,
  model: string,
): Record<string, unknown> {
  const transcript = messages
    .map((m) => `[${m.role}]: ${m.content}`)
    .join("\n");

  return {
    model,
    max_tokens: 512, // Smaller — we expect 0..3 facts.
    temperature: 0,
    system: QUICK_PROFILE_SYSTEM_PROMPT,
    tools: [
      {
        name: "extract_facts",
        description:
          "Record between 0 and 3 legal-status facts about the user. " +
          "Return an empty array if the user skipped or gave no usable answer.",
        input_schema: {
          type: "object",
          properties: {
            facts: {
              type: "array",
              maxItems: 3,
              items: {
                type: "object",
                required: ["key", "value", "confidence"],
                properties: {
                  key: {
                    type: "string",
                    enum: Array.from(QUICK_PROFILE_ALLOWED_KEYS),
                  },
                  value: {
                    type: "string",
                    maxLength: TEXT_MAX_LEN,
                  },
                  confidence: {
                    type: "number",
                    minimum: 0,
                    maximum: 1,
                  },
                },
              },
            },
          },
          required: ["facts"],
        },
      },
    ],
    tool_choice: { type: "tool", name: "extract_facts" },
    messages: [
      {
        role: "user",
        content:
          "Here is the intake answer — extract the legal-status facts.\n\n" +
          transcript,
      },
    ],
  };
}

/**
 * Builds the Anthropic Messages API request for Haiku, with the
 * extract_facts tool constraining the schema.
 */
export function buildHaikuRequest(
  messages: Array<{ role: string; content: string }>,
  model: string,
): Record<string, unknown> {
  const transcript = messages
    .map((m) => `[${m.role}]: ${m.content}`)
    .join("\n");

  return {
    model,
    max_tokens: 1024,
    temperature: 0, // Deterministic — extraction is not creative writing.
    system: SYSTEM_PROMPT,
    tools: [
      {
        name: "extract_facts",
        description:
          "Record between 0 and 10 structured facts about the user. " +
          "Return an empty array if the session contains nothing memorable.",
        input_schema: {
          type: "object",
          properties: {
            facts: {
              type: "array",
              maxItems: MAX_FACTS,
              items: {
                type: "object",
                required: ["key", "value", "confidence"],
                properties: {
                  key: {
                    type: "string",
                    enum: Array.from(ALLOWED_KEYS),
                  },
                  value: {
                    type: "string",
                    maxLength: TEXT_MAX_LEN,
                  },
                  confidence: {
                    type: "number",
                    minimum: 0,
                    maximum: 1,
                  },
                },
              },
            },
          },
          required: ["facts"],
        },
      },
    ],
    tool_choice: { type: "tool", name: "extract_facts" },
    messages: [
      {
        role: "user",
        content:
          "Here is the transcript — extract the facts.\n\n" + transcript,
      },
    ],
  };
}

/**
 * Parses Haiku's response and returns the validated fact list.
 * Tolerates:
 *   - nulls / missing fields
 *   - malformed tool_use blocks
 *   - strings instead of numbers (best-effort coercion)
 * Drops any fact that fails validation — never throws.
 */
export function parseHaikuFacts(response: unknown): ExtractedFact[] {
  if (!response || typeof response !== "object") return [];
  const resp = response as Record<string, unknown>;
  const content = resp.content;
  if (!Array.isArray(content)) return [];

  for (const block of content) {
    if (!block || typeof block !== "object") continue;
    const b = block as Record<string, unknown>;
    if (b.type !== "tool_use" || b.name !== "extract_facts") continue;
    const input = b.input;
    if (!input || typeof input !== "object") continue;
    const facts = (input as Record<string, unknown>).facts;
    if (!Array.isArray(facts)) continue;

    const out: ExtractedFact[] = [];
    for (const f of facts) {
      if (!f || typeof f !== "object") continue;
      const fr = f as Record<string, unknown>;
      const key = fr.key;
      const value = fr.value;
      const confidenceRaw = fr.confidence;
      if (typeof key !== "string" || !ALLOWED_KEYS.has(key)) continue;
      if (typeof value !== "string" || value.trim().length === 0) continue;
      const confidence = typeof confidenceRaw === "number"
        ? confidenceRaw
        : Number(confidenceRaw);
      if (!Number.isFinite(confidence) || confidence < 0 || confidence > 1) {
        continue;
      }
      // Anything below 0.5 has already been filtered by the system prompt,
      // but double-enforce here (defence in depth).
      if (confidence < 0.5) continue;
      out.push({
        key,
        value: value.trim().slice(0, TEXT_MAX_LEN),
        confidence,
      });
      if (out.length >= MAX_FACTS) break;
    }
    return out;
  }
  return [];
}
