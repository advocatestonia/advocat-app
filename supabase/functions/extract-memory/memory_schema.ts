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
].join("");

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
