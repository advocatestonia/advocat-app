// correction_detector.ts — detect when a user is correcting the assistant.
// ----------------------------------------------------------------------------
// Runs on every user turn (fire-and-forget). Uses Haiku 4.5 with a 200-token
// prompt to decide whether the latest user message is a CORRECTION of the
// previous assistant turn. If yes, it extracts the structured triple
// {what_was_wrong, correct_answer, why} and persists it to advice_corrections.
//
// Design choices:
//   * Haiku (cheap + fast) — the false-positive cost is one tiny insert,
//     the false-negative cost is a lost training signal. Haiku is calibrated
//     enough for binary detection.
//   * 200 tokens out hard cap — the detector must NEVER inflate to a full
//     legal answer; we ONLY want the triple.
//   * Strict JSON contract — model must emit {detected, what_was_wrong,
//     correct_answer, why} OR {detected: false}.
//   * Embedding step is OPTIONAL — when the OpenAI key is absent the row
//     is still inserted with embedding=NULL. Retrieval will skip it (RPC
//     filters on embedding IS NOT NULL) until a backfill job runs.
//
// File budget: keep ≤ 500 lines per CLAUDE.md.
// ----------------------------------------------------------------------------

import { embedText } from "./corrections_retriever.ts";
import { recordSpend } from "./spend_tracker.ts";

const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";
const MODEL_HAIKU = "claude-haiku-4-5-20251001";

/** Public — what the detector returns to its caller. */
export interface CorrectionDetectionResult {
  detected: boolean;
  what_was_wrong?: string;
  correct_answer?: string;
  why?: string;
  /** Raw model output, truncated to 4 KB, for debugging. */
  raw?: string;
}

/** Options for [detectAndRecordCorrection]. */
export interface DetectCorrectionOpts {
  userId: string;
  conversationId?: string | null;
  /** The new user message — the candidate correction. */
  userMessage: string;
  /** The previous assistant message — what's allegedly wrong. */
  previousAssistantMessage: string;
  /** Optional jurisdiction tag (e.g. "FI", "EE"). */
  jurisdiction?: string | null;
  /** Optional case type (e.g. "deportation", "employment"). */
  caseType?: string | null;
  supabaseUrl: string;
  serviceRoleKey: string;
  anthropicApiKey: string;
  /** OpenAI key for embeddings. Optional — row still saved without embedding
   *  when absent; a backfill job can fill it later. */
  openaiApiKey?: string;
  /** Anthropic caller injection seam — for tests. */
  caller?: HaikuCaller;
}

/** Caller signature — same shape as legal_planner.AnthropicCaller but
 *  trimmed to what the detector needs. */
export type HaikuCaller = (req: {
  systemPrompt: string;
  userMessage: string;
  maxTokens: number;
  apiKey: string;
}) => Promise<string>;

// ─── Detection prompt (~ 200 tok) ───────────────────────────────────────────

const DETECTOR_SYSTEM = `You analyse the latest user turn in a legal-assistant conversation and decide whether the user is CORRECTING the assistant's previous answer.

Output ONLY a single JSON object — no markdown, no preamble:

{
  "detected": <true|false>,
  "what_was_wrong": "<verbatim quote or short paraphrase of the WRONG claim from the assistant>",
  "correct_answer": "<the user-supplied corrected version>",
  "why": "<one sentence explaining the underlying confusion / mistake>"
}

If detected=false, output {"detected": false} and STOP.

Detection rules:
- A correction explicitly contradicts a specific claim: "that's wrong", "actually it's X", "no — it should be Y", "you got Z wrong", "Tegelikult ei ole nii", "Itse asiassa", "Ei pidä paikkaansa".
- A correction may be implicit: user states a fact that flatly contradicts the assistant ("HAO cannot hear that — only KHO can").
- New information that the assistant didn't have ≠ correction. Only fire when the assistant's previous claim is being overturned.
- Generic disagreement ("hmm not sure") without a counter-claim ≠ correction.
- Stay under 200 tokens. Brevity is the constraint.`;

// ─── Default caller ─────────────────────────────────────────────────────────

const defaultCaller: HaikuCaller = async (req) => {
  const res = await fetch(ANTHROPIC_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": req.apiKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: MODEL_HAIKU,
      max_tokens: req.maxTokens,
      temperature: 0.0,
      system: req.systemPrompt,
      messages: [{ role: "user", content: req.userMessage }],
    }),
  });
  if (!res.ok) {
    const err = await res.text();
    throw new Error(`Anthropic ${res.status}: ${err.slice(0, 200)}`);
  }
  const json = await res.json() as {
    content?: Array<{ text?: string }>;
    usage?: {
      input_tokens?: number;
      output_tokens?: number;
      cache_creation_input_tokens?: number;
      cache_read_input_tokens?: number;
    };
  };
  // Cost-audit gap 2026-05-27: record Haiku spend on the detector. Runs on
  // every plausible-correction user turn — invisible spend before this fix.
  // Best-effort.
  try {
    const u = json.usage ?? {};
    const inputTokens = (u.input_tokens ?? 0) +
      (u.cache_creation_input_tokens ?? 0) +
      (u.cache_read_input_tokens ?? 0);
    const outputTokens = u.output_tokens ?? 0;
    if (inputTokens > 0 || outputTokens > 0) {
      recordSpend(inputTokens, outputTokens, MODEL_HAIKU, "anthropic_haiku")
        .catch(() => {});
    }
  } catch (_e) { /* never bubble */ }
  return json.content?.[0]?.text?.trim() ?? "";
};

// ─── Parser ─────────────────────────────────────────────────────────────────

/** Parse the Haiku JSON output into a [CorrectionDetectionResult].
 *  Tolerant of code-fences and tag wrappers. */
export function parseDetectorOutput(raw: string): CorrectionDetectionResult {
  const cleaned = raw.trim()
    .replace(/^```json?\s*/i, "")
    .replace(/```\s*$/, "")
    .trim();
  const m = cleaned.match(/\{[\s\S]*\}/);
  if (!m) return { detected: false, raw: cleaned.slice(0, 4096) };
  try {
    const parsed = JSON.parse(m[0]) as {
      detected?: unknown;
      what_was_wrong?: unknown;
      correct_answer?: unknown;
      why?: unknown;
    };
    const detected = parsed.detected === true;
    if (!detected) return { detected: false, raw: cleaned.slice(0, 4096) };
    return {
      detected: true,
      what_was_wrong: typeof parsed.what_was_wrong === "string"
        ? parsed.what_was_wrong.slice(0, 2000)
        : "",
      correct_answer: typeof parsed.correct_answer === "string"
        ? parsed.correct_answer.slice(0, 2000)
        : "",
      why: typeof parsed.why === "string" ? parsed.why.slice(0, 1000) : "",
      raw: cleaned.slice(0, 4096),
    };
  } catch {
    return { detected: false, raw: cleaned.slice(0, 4096) };
  }
}

/** Heuristic guard — short user replies like "ок" / "спасибо" / "kiitos"
 *  never trigger the Haiku call. Saves cost on every turn. */
export function isPlausibleCorrection(
  userMessage: string,
  previousAssistantMessage: string,
): boolean {
  const u = userMessage.trim();
  if (u.length < 8) return false; // too short to encode a correction
  if (!previousAssistantMessage || previousAssistantMessage.length < 20) {
    return false; // no real prior claim to correct
  }
  // Cheap signal — at least one of these markers in a few common
  // languages we serve. Caller can still force the Haiku check by
  // calling [detectAndRecordCorrection] directly with skipHeuristic=true.
  const markers = [
    "wrong", "incorrect", "actually", "not true", "should be", "got it wrong",
    "неправильно", "неверно", "ошиб", "на самом деле", "должно быть",
    "väärin", "ei ole", "itse asiassa", "ei pidä paikkaansa",
    "vale", "tegelikult", "ei vasta", "peaks olema",
  ];
  const lower = u.toLowerCase();
  return markers.some((mk) => lower.includes(mk));
}

// ─── Public entrypoint ──────────────────────────────────────────────────────

/**
 * Fire-and-forget detector. Caller does `.catch()` on the returned Promise.
 * Returns the detection result for tests / telemetry; callers in prod can
 * ignore it.
 *
 * Side effect: when detected=true, inserts a row into advice_corrections.
 */
export async function detectAndRecordCorrection(
  opts: DetectCorrectionOpts,
): Promise<CorrectionDetectionResult> {
  // ── 0. Cheap heuristic gate (skip Haiku for trivial turns) ──────────────
  if (!isPlausibleCorrection(opts.userMessage, opts.previousAssistantMessage)) {
    return { detected: false };
  }

  // ── 1. Call Haiku to classify + extract triple ──────────────────────────
  const call = opts.caller ?? defaultCaller;
  // Escape closing-tag breakout in the untrusted framing.
  const sealTags = (s: string) =>
    s.replace(
      /<\s*\/\s*(previous_assistant|user_new_turn)\s*>/gi,
      "&lt;/$1&gt;",
    );
  const userPayload =
    `<previous_assistant>\n${sealTags(opts.previousAssistantMessage.slice(0, 3000))}\n</previous_assistant>\n\n` +
    `<user_new_turn>\n${sealTags(opts.userMessage.slice(0, 2000))}\n</user_new_turn>`;
  let raw: string;
  try {
    raw = await call({
      systemPrompt: DETECTOR_SYSTEM,
      userMessage: userPayload,
      maxTokens: 200,
      apiKey: opts.anthropicApiKey,
    });
  } catch (e) {
    console.warn(
      `correction_detector: Haiku call failed: ${String(e).slice(0, 200)}`,
    );
    return { detected: false };
  }

  const parsed = parseDetectorOutput(raw);
  if (!parsed.detected) return parsed;
  if (!parsed.what_was_wrong || !parsed.correct_answer) return parsed;

  // ── 2. Embed the question (best-effort) ─────────────────────────────────
  // The question we embed is "the topic the user is correcting on" — we use
  // the previous assistant message as the question proxy because it is what
  // a future similar question would also produce. For richer retrieval the
  // caller can pass a dedicated question via opts (future extension).
  let embedding: number[] | null = null;
  if (opts.openaiApiKey) {
    try {
      embedding = await embedText({
        text: opts.previousAssistantMessage.slice(0, 8000),
        openaiApiKey: opts.openaiApiKey,
      });
    } catch (e) {
      console.warn(
        `correction_detector: embedding failed: ${String(e).slice(0, 200)}`,
      );
    }
  }

  // ── 3. Insert into advice_corrections ───────────────────────────────────
  try {
    const body = {
      user_id: opts.userId,
      conversation_id: opts.conversationId ?? null,
      question: opts.previousAssistantMessage.slice(0, 4000),
      wrong_advice: parsed.what_was_wrong,
      correct_answer: parsed.correct_answer,
      why_wrong: parsed.why ?? "user correction",
      correction_source: "user_explicit",
      jurisdiction: opts.jurisdiction ?? null,
      case_type: opts.caseType ?? null,
      severity: "factual",
      embedding: embedding ? `[${embedding.join(",")}]` : null,
      metadata: { detected_by: "correction_detector_v1" },
    };
    const res = await fetch(
      `${opts.supabaseUrl}/rest/v1/advice_corrections`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          apikey: opts.serviceRoleKey,
          Authorization: `Bearer ${opts.serviceRoleKey}`,
          Prefer: "return=minimal",
        },
        body: JSON.stringify(body),
      },
    );
    if (!res.ok) {
      const errText = await res.text();
      console.warn(
        `correction_detector: insert failed ${res.status}: ${errText.slice(0, 200)}`,
      );
    }
  } catch (e) {
    console.warn(
      `correction_detector: insert threw: ${String(e).slice(0, 200)}`,
    );
  }

  return parsed;
}
