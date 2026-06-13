import { scrubAnthropicBody } from "./llm_egress/scrub_body.ts";
// subtraction_critic.ts — Senior-lawyer "cut 50-60%" pass.
// -----------------------------------------------------------------------------
// Pure-ish module — no Deno globals beyond `fetch`. Imported by
//   • supabase/functions/_shared/legal_planner.ts (final stage)
//   • supabase/functions/_tests/subtraction_critic.test.ts
//
// Spec (from strategic consilium synthesis, 2026-05-13):
//   "Genius lawyers know when to shut up." Every weak argument poisons
//   the strong ones. Every additional claim gives the opponent a free
//   target. This pass takes the post-red-team draft and cuts 50-60% by
//   STRATEGIC VALUE — keeping only the 2-3 hills worth dying on.
//
// Hard constraints:
//   • CRITICAL warnings (deadlines, statute references, ⚠️ assumption notes)
//     are NEVER cut — they're load-bearing for the user's safety.
//   • Cut ratio target: 40-60% of original length. Outside this band the
//     trim is suspicious (either fluff or content loss); we still ship
//     the trimmed version but flag the ratio in the trace.
//   • Markers [[ref:slug:para]] in kept arguments are preserved verbatim.
//   • Uses Sonnet 4.6 — this is rewrite, not adversarial analysis, so
//     Opus is overkill. Sonnet is cheaper and faster.
//
// Cost model (Sonnet 4.6):
//   Input  : $3 / Mtok   → 300 c/Mtok
//   Output : $15 / Mtok  → 1500 c/Mtok
//   Typical pass: ~3k in / ~1.5k out → ~$0.03/turn.
//   Always runs once per request (no loops, no regen).
// -----------------------------------------------------------------------------

const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";

// Model ID — pinned. Sonnet 4.6 for rewrites.
export const MODEL_SONNET = "claude-sonnet-4-6";

// Token budget — needs to fit the trimmed draft. Worst case the trim
// barely cuts anything (40% of a 16k input is ~9.6k output), so we
// budget generously. Critical: must be ≥ EXECUTOR_MAX_TOKENS * 0.7.
export const SUBTRACTION_MAX_TOKENS = 12000;

// Temperature — low. We want consistent trimming behaviour, not
// creative paraphrasing.
export const SUBTRACTION_TEMPERATURE = 0.1;

// Cost model — cents per million tokens.
const COST_SONNET_IN_C_PER_MTOK = 300;
const COST_SONNET_OUT_C_PER_MTOK = 1500;

export function subtractionCostCents(
  inputTokens: number,
  outputTokens: number,
): number {
  return Math.ceil(
    (inputTokens * COST_SONNET_IN_C_PER_MTOK +
      outputTokens * COST_SONNET_OUT_C_PER_MTOK) /
      1_000_000,
  );
}

// ─── Public types ────────────────────────────────────────────────────────

/** Description of a single cut the Subtraction Critic made. */
export interface SubtractionCut {
  /** Short label of what was cut — e.g. "alternative path #3" or
   *  "secondary statute discussion". */
  section: string;
  /** Why it was cut — strategic value reasoning. */
  reason: string;
}

/** Output of the Subtraction Critic pass. */
export interface SubtractionResult {
  /** The trimmed draft. Ready to ship to the user. */
  trimmed_draft: string;
  /** Length of the input draft (characters). */
  original_length: number;
  /** Length of the trimmed draft (characters). */
  trimmed_length: number;
  /** trimmed / original. Target band 0.40-0.60. */
  ratio: number;
  /** Cuts the model self-reported. May be empty if the model didn't emit
   *  the explanation block — the trim still ran. */
  cuts_made: SubtractionCut[];
  /** Verbatim raw output (trimmed for the trace row). */
  raw: string;
  inputTokens: number;
  outputTokens: number;
  costCents: number;
  /** True if the ratio fell outside the 0.40-0.60 band — ops should
   *  investigate. Common causes: model returned an explanation only
   *  (ratio ≈ 0), model didn't trim at all (ratio ≈ 1). */
  ratio_outside_band: boolean;
}

export interface AnthropicCallResult {
  text: string;
  inputTokens: number;
  outputTokens: number;
}

export type AnthropicCaller = (req: {
  model: string;
  systemPrompt: string;
  messages: Array<{ role: string; content: string }>;
  maxTokens: number;
  temperature: number;
  apiKey: string;
}) => Promise<AnthropicCallResult>;

// ─── Default Anthropic caller ────────────────────────────────────────────

export const defaultSubtractionCaller: AnthropicCaller = async (req) => {
  const res = await fetch(ANTHROPIC_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": req.apiKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify(scrubAnthropicBody({
      model: req.model,
      max_tokens: req.maxTokens,
      temperature: req.temperature,
      system: req.systemPrompt,
      messages: req.messages,
    })),
  });
  if (!res.ok) {
    const err = await res.text();
    throw new Error(
      `Anthropic ${res.status} (${req.model}): ${err.slice(0, 200)}`,
    );
  }
  const json = await res.json() as {
    content?: Array<{ type: string; text?: string }>;
    usage?: { input_tokens?: number; output_tokens?: number };
  };
  const text = (json.content ?? [])
    .filter((b) => b.type === "text" && typeof b.text === "string")
    .map((b) => b.text!)
    .join("");
  return {
    text,
    inputTokens: json.usage?.input_tokens ?? 0,
    outputTokens: json.usage?.output_tokens ?? 0,
  };
};

// ─── System prompt ───────────────────────────────────────────────────────

export const SUBTRACTION_INSTRUCTIONS = String.raw`
You are a senior litigator with 30 years of experience. Your ONLY job is to
make the draft SHORTER and SHARPER.

The draft is verbose. Genius lawyers know when to shut up. Every weak
argument poisons the strong ones. Every additional claim gives the opponent
a free target.

RULES:
1. Cut 50-60% of the draft. Aim for the trimmed version to be 40-50% of the
   original length.
2. Rank every argument by STRATEGIC VALUE, not legal validity. A weak but
   unrebuttable point beats a strong but distracting one.
3. Keep only the top 2-3 arguments.
4. Delete every sentence that doesn't directly help the client win.
5. If you keep an argument, it must answer "is this the hill to die on?" — YES.
6. PRESERVE these ALWAYS — never cut:
   - All CRITICAL warnings about deadlines (any date, "до", "by", "deadline",
     "срок", "määräaika", "tähtaeg")
   - All [[ref:slug:para]] citation markers in kept arguments
   - All ⚠️ assumption notes ("Предполагается:", "Assumed:", "Oletetaan:")
   - The "## Следующие шаги" / "## Next steps" / "## Järgmised sammud" section
   - Any explicit statute / section reference (§, art., kohta, art)
7. Output the trimmed version. No explanation in the body. No apology for cuts.

OUTPUT FORMAT (strict):

<trimmed>
[the trimmed draft, ready to ship to the user]
</trimmed>

<cuts>
[
  { "section": "<short label>", "reason": "<why cut>" },
  ...
]
</cuts>

The <cuts> block is OPTIONAL — if omitted the trim still runs, but ops
loses visibility into what was removed. Aim for 2-5 cut entries.

LANGUAGE: preserve the language of the original draft. Don't translate.
TONE: preserve the original tone. Don't soften or harshen.
`.trim();

// ─── Parser ──────────────────────────────────────────────────────────────

const RAW_TRUNCATE = 4 * 1024;

function truncate(s: string): string {
  return s.length <= RAW_TRUNCATE ? s : s.slice(0, RAW_TRUNCATE);
}

/** Parse the model's output into the trimmed draft + cut list.
 *
 *  Tolerant: if `<trimmed>` tags are missing, treat the entire response as
 *  the trimmed draft. If `<cuts>` is missing or invalid JSON, return an
 *  empty cut list. We never throw — the orchestrator must always get a
 *  trimmed draft to ship. */
export function parseSubtractionOutput(text: string): {
  trimmed_draft: string;
  cuts_made: SubtractionCut[];
  raw: string;
} {
  const trimmedMatch = text.match(/<trimmed>([\s\S]*?)<\/trimmed>/i);
  const trimmed_draft = trimmedMatch ? trimmedMatch[1].trim() : text.trim();

  const cutsMatch = text.match(/<cuts>([\s\S]*?)<\/cuts>/i);
  let cuts_made: SubtractionCut[] = [];
  if (cutsMatch) {
    const jsonMatch = cutsMatch[1].match(/\[[\s\S]*\]/);
    if (jsonMatch) {
      try {
        const parsed = JSON.parse(jsonMatch[0]);
        if (Array.isArray(parsed)) {
          cuts_made = parsed
            .filter((c): c is { section: unknown; reason: unknown } =>
              typeof c === "object" && c !== null
            )
            .map((c) => ({
              section: typeof c.section === "string"
                ? c.section.slice(0, 200)
                : "(unspecified)",
              reason: typeof c.reason === "string"
                ? c.reason.slice(0, 500)
                : "(no reason given)",
            }))
            .slice(0, 10); // bound — model could spam
        }
      } catch (_) {
        // ignore — cuts is optional
      }
    }
  }

  return {
    trimmed_draft,
    cuts_made,
    raw: truncate(text),
  };
}

// ─── Critical-content preservation guard ─────────────────────────────────

/** Patterns that MUST survive the trim. If the trimmed draft is missing
 *  any pattern that was in the original, we treat the trim as broken and
 *  fall back to the original draft (logged for ops). */
const CRITICAL_PATTERNS: Array<{ name: string; pattern: RegExp }> = [
  // [[ref:slug:para]] citation markers — content grounding.
  { name: "ref_markers", pattern: /\[\[ref:[^\]]+\]\]/g },
  // ⚠️ assumption notes.
  { name: "assumption_notes", pattern: /⚠️/g },
  // ## Следующие шаги / Next steps / Järgmised sammud — actionability.
  // Match the header in RU / EN / ET / FI.
  {
    name: "next_steps_header",
    pattern:
      /##\s*(Следующие шаги|Next steps|Järgmised sammud|Seuraavat askeleet)/gi,
  },
];

/** Returns the names of critical patterns that disappeared from the trim.
 *  Empty array => trim is safe. */
export function findLostCriticalContent(
  original: string,
  trimmed: string,
): string[] {
  const lost: string[] = [];
  for (const { name, pattern } of CRITICAL_PATTERNS) {
    const origMatches = original.match(pattern);
    if (!origMatches || origMatches.length === 0) continue;
    const trimmedMatches = trimmed.match(pattern);
    const trimmedCount = trimmedMatches?.length ?? 0;
    // We allow some marker repetition trimming, but we require AT LEAST
    // one of each kind of critical content to survive.
    if (trimmedCount === 0) {
      lost.push(name);
    }
  }
  return lost;
}

// ─── Public API ──────────────────────────────────────────────────────────

export interface RunSubtractionOptions {
  apiKey: string;
  /** Base system prompt (jurisdiction, case memory, RAG). Subtraction
   *  needs the context to judge which arguments are load-bearing. */
  systemPrompt: string;
  /** The post-red-team draft to trim. */
  draft: string;
  /** Plan from the Planner — gives the critic the original strategy so
   *  it can decide which arguments support the primary path. */
  plan: {
    sub_questions: string[];
    counter_args: string[];
    probability_signal: string;
  };
  /** Test override. */
  caller?: AnthropicCaller;
}

/** Run the Subtraction Critic. Always returns a SubtractionResult; on
 *  Anthropic error or critical-content loss, returns the original draft
 *  with ratio_outside_band=true so the trace shows the failure. */
export async function runSubtractionCritic(
  opts: RunSubtractionOptions,
): Promise<SubtractionResult> {
  const call = opts.caller ?? defaultSubtractionCaller;
  const original = opts.draft;
  const original_length = original.length;

  // Edge case — empty draft. Don't waste an API call.
  if (original_length === 0) {
    return {
      trimmed_draft: "",
      original_length: 0,
      trimmed_length: 0,
      ratio: 0,
      cuts_made: [],
      raw: "",
      inputTokens: 0,
      outputTokens: 0,
      costCents: 0,
      ratio_outside_band: false,
    };
  }

  // Build user message — strategy first so the critic knows which
  // arguments support the primary path.
  const planLines: string[] = [];
  if (opts.plan.sub_questions.length > 0) {
    planLines.push("Plan sub-questions (the questions the answer must hit):");
    for (const q of opts.plan.sub_questions) planLines.push(`  - ${q}`);
  }
  if (opts.plan.counter_args.length > 0) {
    planLines.push("Plan counter-arguments (weaknesses you should NOT amplify):");
    for (const a of opts.plan.counter_args) planLines.push(`  - ${a}`);
  }
  if (opts.plan.probability_signal) {
    planLines.push(`Probability signal: ${opts.plan.probability_signal}`);
  }

  const userMessage = [
    planLines.join("\n"),
    "",
    "Verbose draft (your input):",
    "<draft>",
    original,
    "</draft>",
    "",
    "Now trim it. Cut 50-60%. Keep only the hills worth dying on.",
  ].filter((s) => s !== undefined).join("\n");

  const subtractionSystem = `${opts.systemPrompt}\n\n${SUBTRACTION_INSTRUCTIONS}`;

  try {
    const res = await call({
      model: MODEL_SONNET,
      systemPrompt: subtractionSystem,
      messages: [{ role: "user", content: userMessage }],
      maxTokens: SUBTRACTION_MAX_TOKENS,
      temperature: SUBTRACTION_TEMPERATURE,
      apiKey: opts.apiKey,
    });

    const parsed = parseSubtractionOutput(res.text);
    let trimmed = parsed.trimmed_draft;

    // Critical-content preservation guard. If the trim dropped any
    // load-bearing patterns, fall back to the original draft.
    const lost = findLostCriticalContent(original, trimmed);
    if (lost.length > 0) {
      console.warn(
        `subtraction_critic: trim dropped critical content (${
          lost.join(", ")
        }) — falling back to original draft`,
      );
      trimmed = original;
    }

    const trimmed_length = trimmed.length;
    const ratio = trimmed_length / original_length;
    const ratio_outside_band = ratio < 0.40 || ratio > 0.60;

    return {
      trimmed_draft: trimmed,
      original_length,
      trimmed_length,
      ratio,
      cuts_made: parsed.cuts_made,
      raw: parsed.raw,
      inputTokens: res.inputTokens,
      outputTokens: res.outputTokens,
      costCents: subtractionCostCents(res.inputTokens, res.outputTokens),
      ratio_outside_band,
    };
  } catch (e) {
    // Anthropic call failed — return the original draft so the user
    // still gets an answer. ratio_outside_band=true flags the failure.
    console.warn(
      `subtraction_critic: pass failed, returning original draft: ${
        String(e).slice(0, 200)
      }`,
    );
    return {
      trimmed_draft: original,
      original_length,
      trimmed_length: original_length,
      ratio: 1.0,
      cuts_made: [],
      raw: `[subtraction_critic unavailable: ${String(e).slice(0, 200)}]`,
      inputTokens: 0,
      outputTokens: 0,
      costCents: 0,
      ratio_outside_band: true,
    };
  }
}
