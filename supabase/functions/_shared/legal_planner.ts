// legal_planner.ts — Phase 2 Pkg 6 three-pass orchestrator.
import { checkCalibration } from "./probability_calibration.ts";
// -----------------------------------------------------------------------------
// Pure-ish module — no Deno globals beyond `fetch`. Imported by
//   • supabase/functions/claude-proxy/index.ts (when mode='legal_planner')
//   • Deno tests for the planner contract
//
// Spec: docs/architecture/phase2-pkg6-planner.md.
//
// Three passes per legal turn:
//   1. Planner   — Sonnet, temp=0.0, ≤500 tok. Emits `<plan>...` with
//                  sub-questions, counter-args, evidence gaps.
//   2. Executor  — Sonnet, temp=0.2, ≤4096 tok. Drafts the answer with
//                  Pkg 2 markers `[[ref:slug:para]]`. Plan is injected
//                  into the system prompt.
//   3. Critique  — Haiku, temp=0.0, ≤300 tok. Emits
//                  `<critique>{ material_gap: bool, issues: [...] }`.
//                  When material_gap is true, the executor is re-run
//                  ONCE with the critique appended to the prompt.
//
// The final reply text leaves this module unchanged — the caller in
// claude-proxy still runs the citation_grounder + UPL footer + persistence
// flow on it. We only return `{ replyText, plan, critique, regeneratedOnce,
// latencyMs, costCents }` so the caller can fold it into the existing
// non-streaming response shape and persist a trace row.
//
// Persistence: the orchestrator is pure with respect to the DB. Trace
// persistence is a side-channel (writeTrace) the caller passes in so the
// module stays unit-testable without a Supabase mock.
// -----------------------------------------------------------------------------

const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";

const MODEL_SONNET = "claude-sonnet-4-6";
const MODEL_HAIKU = "claude-haiku-4-5-20251001";

// Per-pass token budgets — pinned by the spec (§2 Pass shapes).
// 2026-05-07: EXECUTOR raised 4096 → 16384 so planner-routed legal turns
// (contracts, full pleadings, dossier summaries) deliver complete output
// matching claude-proxy MAX_TOKENS_LIMIT. Planner + Critique stay tight —
// they emit small JSON payloads, not user-facing prose.
export const PLANNER_MAX_TOKENS = 500;
export const EXECUTOR_MAX_TOKENS = 16384;
export const CRITIQUE_MAX_TOKENS = 300;

// Per-pass temperatures — Planner is deterministic, Executor mildly
// stochastic for varied phrasings, Critique deterministic again so the
// re-execute decision is reproducible in evals.
export const PLANNER_TEMPERATURE = 0.0;
export const EXECUTOR_TEMPERATURE = 0.2;
export const CRITIQUE_TEMPERATURE = 0.0;

// Hard regen cap. Even if the spec ever changes the heuristic, the
// orchestrator never re-fires the executor more than once per turn — the
// loop guard is enforced HERE so the proxy can't accidentally bill the
// user for an infinite reasoning tail.
const MAX_REGENERATIONS = 1;

// ─── Public types ────────────────────────────────────────────────────────

/** Structured representation of the planner output. We accept either
 *  XML-shaped <plan>...</plan> with nested tags, or a JSON fallback.
 *  Either way the parser normalises down to this shape so the trace
 *  store has a stable jsonb schema. */
export interface PlannerPlan {
  sub_questions: string[];
  counter_args: string[];
  evidence_gaps: string[];
  /** Short honest signal from the planner: "strong", "medium", "weak — ...", or "closed — ...".
   *  Injected into the executor system prompt so it calibrates its tone. */
  probability_signal: string;
  /** True when the planner detected a weak/closed primary path and instructed
   *  the executor to search for alternatives. The consilium module can check
   *  this flag to decide whether to activate the Поисковик альтернатив role. */
  alternatives_needed: boolean;
  /** Gaps that BLOCK the answer — answer would differ >50% without this fact.
   *  Non-empty means the orchestrator should NOT run the executor. */
  blocking_gaps: string[];
  /** Verbatim raw text from the planner — kept for debugging. Truncated
   *  at 4 KB so the jsonb row stays bounded. */
  raw: string;
}

/** Structured representation of the critique output. */
export interface PlannerCritique {
  material_gap: boolean;
  issues: string[];
  raw: string;
}

/** What a single Anthropic call returns. Public so callers (and tests)
 *  can compose the loop differently without re-importing internals. */
export interface AnthropicCallResult {
  text: string;
  inputTokens: number;
  outputTokens: number;
}

export interface PlannerBlockedResult {
  kind: "blocked";
  question: string;
  plan: PlannerPlan;
  latencyMs: number;
  costCents: number;
}

/** Final shape returned by [runLegalPlannerLoop]. */
export interface PlannerLoopResult {
  kind: "completed";
  /** The final executor reply (post-regen if it fired). Caller runs the
   *  citation_grounder + UPL footer over THIS string. */
  replyText: string;
  plan: PlannerPlan;
  critique: PlannerCritique;
  regeneratedOnce: boolean;
  latencyMs: number;
  /** Sum of input+output across all 3-4 passes, in cents. */
  costCents: number;
}

/** Side-channel hook the caller passes in to persist a trace row.
 *  Returning a Promise that throws is allowed; the orchestrator
 *  swallows persistence errors so the user always gets their answer
 *  even if the trace write fails. */
export type TraceWriter = (trace: {
  message_id: string;
  plan: PlannerPlan;
  executor_response: string;
  critique: PlannerCritique;
  regenerated_once: boolean;
  latency_ms: number;
  cost_cents: number;
  calibration_warning?: string | null;
}) => Promise<void>;

/** Anthropic call shim. Injected by tests; falls back to fetch in prod. */
export type AnthropicCaller = (req: {
  model: string;
  systemPrompt: string;
  messages: Array<{ role: string; content: string }>;
  maxTokens: number;
  temperature: number;
  apiKey: string;
}) => Promise<AnthropicCallResult>;

// ─── Default Anthropic caller ────────────────────────────────────────────

export const defaultAnthropicCaller: AnthropicCaller = async (req) => {
  const res = await fetch(ANTHROPIC_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": req.apiKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: req.model,
      max_tokens: req.maxTokens,
      temperature: req.temperature,
      system: req.systemPrompt,
      messages: req.messages,
    }),
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

// ─── Cost model ──────────────────────────────────────────────────────────

// Cents per million tokens. Approximate; matches the values in
// docs/performance/05-cost.md. The trace cost is for ops dashboards, not
// billing — small drift is fine.
const COST_SONNET_IN_C_PER_MTOK = 300;
const COST_SONNET_OUT_C_PER_MTOK = 1500;
const COST_HAIKU_IN_C_PER_MTOK = 100;
const COST_HAIKU_OUT_C_PER_MTOK = 500;

function costCents(
  model: string,
  inputTokens: number,
  outputTokens: number,
): number {
  const inRate = model === MODEL_HAIKU
    ? COST_HAIKU_IN_C_PER_MTOK
    : COST_SONNET_IN_C_PER_MTOK;
  const outRate = model === MODEL_HAIKU
    ? COST_HAIKU_OUT_C_PER_MTOK
    : COST_SONNET_OUT_C_PER_MTOK;
  // Round up — undercounting cost is the worse failure mode for the
  // dashboards. The numbers stay in cents (int).
  return Math.ceil(
    (inputTokens * inRate + outputTokens * outRate) / 1_000_000,
  );
}

// ─── Prompt builders ─────────────────────────────────────────────────────

const PLANNER_INSTRUCTIONS = String.raw`
You are the Planner pass for Advocat's three-pass legal reasoning loop.
Read the user's legal question and the system prompt context (jurisdiction,
case memory, RAG snippets if any) and emit a SHORT plan inside <plan> tags.

Output format (strict — the Executor pass parses these tags):

<plan>
  <sub_questions>
    - one short sub-question per bullet (max 4)
  </sub_questions>
  <counter_args>
    - one short counter-argument or weakness in the user's framing per bullet (max 3)
  </counter_args>
  <evidence_gaps>
    - one short missing-fact / missing-document item per bullet (max 3)
  </evidence_gaps>
  <probability_signal>
    - brief honest signal: is this a strong / medium / weak / closed path?
    - example: "weak — deadline likely missed, < 20% restoration chance"
  </probability_signal>
  <alternatives_needed>true|false</alternatives_needed>
  <blocking_gaps>
    - ONLY list a gap if the answer would differ by MORE THAN 50% without this fact.
    - Emit as a question to the user: "What is the exact filing deadline?"
    - Leave empty for most questions. Max 1 item.
    - If empty: <blocking_gaps></blocking_gaps>
  </blocking_gaps>
</plan>

Hard rules:
- Do NOT answer the user. The Executor will.
- Do NOT cite acts. No [[ref:...]] markers.
- Stay under 500 tokens. Brevity > completeness.
- If the question is not legal-domain after all, emit
  <plan><sub_questions>- (none)</sub_questions></plan> and stop.
- Set <alternatives_needed>true</alternatives_needed> if the primary path is weak or closed.
- <blocking_gaps> MUST be empty for: follow-up turns, general legal questions, any case where all answer paths lead to the same advice.
- Only block when the SPECIFIC missing fact would flip the primary recommendation.

## ДЕДЛАЙН-ФИЛЬТР
Если в контексте дела есть дата дедлайна — КАЖДЫЙ совет проверяй: "мы успеваем до дедлайна?". Если нет — это P0 риск, назови явно.

## ЦЕПОЧКА ДЕДЛАЙНОВ
Если в деле есть финальный дедлайн, выполни обратный расчёт:
- Какие шаги нужны ДО финального дедлайна?
- Сколько времени занимает каждый шаг (realistically)?
- Какая самая ранняя дата когда нужно начать шаг N чтобы успеть к шагу N+1?
Добавь в <evidence_gaps> если какая-то дата в цепочке неизвестна.
Добавь в <sub_questions> если порядок шагов неочевиден.
`.trim();

const EXECUTOR_INSTRUCTIONS_HEADER = String.raw`
You are the Executor pass. The Planner has produced the plan below. Use it
to draft a grounded answer in the user's language. Cite every legal claim
with the Pkg 2 marker syntax: [[ref:ACT_SLUG:PARAGRAPH]] (or with optional
locale, [[ref:ACT_SLUG:PARAGRAPH:lang]]).

Hard rules:
- Address each sub-question.
- Acknowledge the strongest counter-argument briefly.
- Flag any evidence gap the Planner identified — say what the user needs to
  send / clarify to firm up the answer.
- Markers MUST point to acts that the RAG context (if any) actually
  supplied. The post-pass verifier will downgrade unverified markers, so
  inventing citations only hurts the badge.
- ALWAYS end your response with a ## Следующие шаги section (in the user's language).
  List 1-3 concrete actions: specific document to file, office to call, deadline to meet.
  Format each as: "[ ] ACTION — by DATE or ASAP if no deadline known"
  Skip this section ONLY for purely theoretical questions with no actionable steps.
- If your answer depends on an assumed fact that the user has NOT explicitly confirmed,
  add an "⚠️ Этот вывод предполагает:" note immediately after the relevant claim.
  Format: "⚠️ Предполагается: [assumed fact]. Если это не так — [how the answer changes]."
  Max 2 such notes per response. Skip if all key facts are confirmed in the conversation.
`.trim();

const CRITIQUE_INSTRUCTIONS = String.raw`
You are the Critique pass for Advocat's three-pass legal reasoning loop.
You are NOT the user. You read the Executor's draft and decide whether it
has a MATERIAL gap that warrants ONE regeneration with critique injected.

Material gap means:
  • a sub-question from the plan went unanswered, OR
  • a counter-argument was ignored that meaningfully changes the bottom line, OR
  • a specific deadline / right / procedural step was claimed without a
    [[ref:...]] marker and is not common knowledge, OR
  • the answer is materially conditional on an unconfirmed assumption but does NOT
    flag this assumption to the user (missing ⚠️ Предполагается note).

Cosmetic issues (tone, length, ordering) are NOT material — return
material_gap=false for those.

Output format (strict — the orchestrator parses these tags):

<critique>
{
  "material_gap": <true|false>,
  "issues": [
    "one short issue per bullet, max 3",
    "..."
  ]
}
</critique>

Stay under 300 tokens.

## ПРОАКТИВНЫЙ АНАЛИЗ — ОБЯЗАТЕЛЬНО
После своей критики добавь раздел:

**Что клиент не спросил, но должен знать:**
- Если видишь процессуальный риск — назови его (например: "срок подачи истекает через X дней")
- Если видишь упущенный аргумент — назови его
- Если видишь паттерн из нескольких фактов — объедини их в один вывод
- Если ничего критичного нет — напиши "Критических упущений нет"

Максимум 3 пункта. Каждый начинается с ⚠️ если риск, или 💡 если возможность.
`.trim();

// ─── Parsers ─────────────────────────────────────────────────────────────

/** Truncate the raw planner/critique text we stash in the jsonb row.
 *  4 KB is generous (planner is capped at 500 tokens ≈ 2 KB), but the
 *  bound stops a runaway model from blowing up the row size. */
const RAW_TRUNCATE = 4 * 1024;

function truncate(s: string): string {
  return s.length <= RAW_TRUNCATE ? s : s.slice(0, RAW_TRUNCATE);
}

/** Parse a `<plan>...</plan>` block. Tolerant — missing sub-tags become
 *  empty arrays. If <plan> tags are absent entirely we fall back to
 *  treating the whole text as raw notes. */
export function parsePlannerOutput(text: string): PlannerPlan {
  const planMatch = text.match(/<plan>([\s\S]*?)<\/plan>/i);
  const inner = planMatch ? planMatch[1] : text;

  // <probability_signal> — inline text, not a bullet list.
  const probMatch = inner.match(/<probability_signal>([\s\S]*?)<\/probability_signal>/i);
  const probability_signal = probMatch
    ? probMatch[1].trim().replace(/^[-•*]\s*/, "").split(/\r?\n/)[0].trim()
    : "";

  // <alternatives_needed> — literal "true" or "false".
  const altMatch = inner.match(/<alternatives_needed>\s*(true|false)\s*<\/alternatives_needed>/i);
  const alternatives_needed = altMatch ? altMatch[1].toLowerCase() === "true" : false;

  const blocking_gaps = parseBulletSection(inner, "blocking_gaps");

  return {
    sub_questions: parseBulletSection(inner, "sub_questions"),
    counter_args: parseBulletSection(inner, "counter_args"),
    evidence_gaps: parseBulletSection(inner, "evidence_gaps"),
    probability_signal,
    alternatives_needed,
    blocking_gaps,
    raw: truncate(text),
  };
}

function parseBulletSection(inner: string, tag: string): string[] {
  const re = new RegExp(`<${tag}>([\\s\\S]*?)<\\/${tag}>`, "i");
  const m = inner.match(re);
  if (!m) return [];
  const body = m[1];
  // Split on lines that start with `-` or `•` after trimming. Tolerant
  // of indentation; ignores empty lines and the literal "(none)" sentinel.
  const out: string[] = [];
  for (const line of body.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed) continue;
    const stripped = trimmed.replace(/^[-•*]\s*/, "").trim();
    if (!stripped || /^\(?none\)?$/i.test(stripped)) continue;
    out.push(stripped);
  }
  return out;
}

/** Parse a `<critique>{ ... }</critique>` block. The model is told to
 *  emit JSON inside the tags but we tolerate freeform text — if JSON
 *  parsing fails, we infer material_gap heuristically (text contains
 *  "material_gap" and "true"). */
export function parseCritiqueOutput(text: string): PlannerCritique {
  const tagMatch = text.match(/<critique>([\s\S]*?)<\/critique>/i);
  const inner = tagMatch ? tagMatch[1].trim() : text.trim();

  // Try strict JSON first.
  const jsonMatch = inner.match(/\{[\s\S]*\}/);
  if (jsonMatch) {
    try {
      const parsed = JSON.parse(jsonMatch[0]) as {
        material_gap?: unknown;
        issues?: unknown;
      };
      const gap = parsed.material_gap === true;
      const issues = Array.isArray(parsed.issues)
        ? parsed.issues.filter((i): i is string => typeof i === "string")
        : [];
      return { material_gap: gap, issues, raw: truncate(text) };
    } catch (_) {
      // fall through to heuristic
    }
  }

  // Heuristic fallback.
  const heur = /material_gap[^\n]*true/i.test(inner);
  return {
    material_gap: heur,
    issues: heur ? ["unparseable critique — heuristic flagged gap"] : [],
    raw: truncate(text),
  };
}

// ─── Orchestrator ────────────────────────────────────────────────────────

export interface RunLegalPlannerOptions {
  apiKey: string;
  /** Final user-facing system prompt — already includes Pkg 0 UPL footer
   *  guidance, Pkg 1 active_case, Pkg 2 RAG context. The orchestrator
   *  appends its per-pass instructions on top of this. */
  systemPrompt: string;
  /** Conversation messages forwarded to every pass. The user turn is the
   *  last entry. */
  messages: Array<{ role: string; content: string }>;
  /** Used to write the trace row. Optional — when absent (tests / no
   *  message id), the loop still runs but no row is persisted. */
  messageId?: string;
  traceWriter?: TraceWriter;
  /** Test override — falls back to defaultAnthropicCaller in prod. */
  caller?: AnthropicCaller;
  /** Optional clock for deterministic latency in tests. */
  now?: () => number;
}

/** Run the three-pass loop and return the final draft + trace metadata.
 *  The caller (claude-proxy) still owns:
 *    • running citation_grounder over `replyText`
 *    • appending the Pkg 0 UPL footer (already in the system prompt
 *      template, but the executor may strip it; the proxy re-checks)
 *    • persisting message_citations rows
 *
 *  This module is responsible for:
 *    • prompt assembly per pass
 *    • parsing the structured outputs
 *    • the regen-once guard
 *    • computing total latency / cost
 *    • writing the trace row via the injected writer
 */
export async function runLegalPlannerLoop(
  opts: RunLegalPlannerOptions,
): Promise<PlannerLoopResult | PlannerBlockedResult> {
  const call = opts.caller ?? defaultAnthropicCaller;
  const now = opts.now ?? (() => Date.now());
  const startedAt = now();

  let cumulativeCostCents = 0;

  // ── Pass 1 — Planner (Sonnet, temp=0.0) ────────────────────────────
  const plannerSystem = `${opts.systemPrompt}\n\n${PLANNER_INSTRUCTIONS}`;
  const plannerResult = await call({
    model: MODEL_SONNET,
    systemPrompt: plannerSystem,
    messages: opts.messages,
    maxTokens: PLANNER_MAX_TOKENS,
    temperature: PLANNER_TEMPERATURE,
    apiKey: opts.apiKey,
  });
  cumulativeCostCents += costCents(
    MODEL_SONNET,
    plannerResult.inputTokens,
    plannerResult.outputTokens,
  );
  const plan = parsePlannerOutput(plannerResult.text);

  if (plan.blocking_gaps.length > 0) {
    const latencyMs = Math.max(0, now() - startedAt);
    return {
      kind: "blocked",
      question: plan.blocking_gaps[0],
      plan,
      latencyMs,
      costCents: cumulativeCostCents,
    };
  }

  // Calibration guard — log overclaims to trace but never block the user.
  const calibrationWarning = plan.probability_signal
    ? checkCalibration(
        plan.probability_signal,
        opts.messages.map((m) => m.content).join(" ").slice(0, 500),
      )
    : null;
  if (calibrationWarning) {
    console.warn(`legal_planner: ${calibrationWarning}`);
  }

  // ── Pass 2 — Executor (Sonnet, temp=0.2) ──────────────────────────
  const executorSystem = buildExecutorSystem(opts.systemPrompt, plan, null);
  const exec1 = await call({
    model: MODEL_SONNET,
    systemPrompt: executorSystem,
    messages: opts.messages,
    maxTokens: EXECUTOR_MAX_TOKENS,
    temperature: EXECUTOR_TEMPERATURE,
    apiKey: opts.apiKey,
  });
  cumulativeCostCents += costCents(
    MODEL_SONNET,
    exec1.inputTokens,
    exec1.outputTokens,
  );

  // ── Pass 3 — Critique (Haiku, temp=0.0) ───────────────────────────
  const critiqueSystem = `${opts.systemPrompt}\n\n${CRITIQUE_INSTRUCTIONS}`;
  // The critique model sees the executor's draft as if the user posted it.
  const critiqueMessages: Array<{ role: string; content: string }> = [
    {
      role: "user",
      content: `<plan>${plan.raw}</plan>\n\n<draft>${exec1.text}</draft>`,
    },
  ];
  const critiqueResult = await call({
    model: MODEL_HAIKU,
    systemPrompt: critiqueSystem,
    messages: critiqueMessages,
    maxTokens: CRITIQUE_MAX_TOKENS,
    temperature: CRITIQUE_TEMPERATURE,
    apiKey: opts.apiKey,
  });
  cumulativeCostCents += costCents(
    MODEL_HAIKU,
    critiqueResult.inputTokens,
    critiqueResult.outputTokens,
  );
  const critique = parseCritiqueOutput(critiqueResult.text);

  // ── Pass 2b — optional one-shot regen ─────────────────────────────
  let finalDraft = exec1.text;
  let regeneratedOnce = false;
  if (critique.material_gap && MAX_REGENERATIONS > 0) {
    const regenSystem = buildExecutorSystem(opts.systemPrompt, plan, critique);
    const exec2 = await call({
      model: MODEL_SONNET,
      systemPrompt: regenSystem,
      messages: opts.messages,
      maxTokens: EXECUTOR_MAX_TOKENS,
      temperature: EXECUTOR_TEMPERATURE,
      apiKey: opts.apiKey,
    });
    cumulativeCostCents += costCents(
      MODEL_SONNET,
      exec2.inputTokens,
      exec2.outputTokens,
    );
    finalDraft = exec2.text;
    regeneratedOnce = true;
  }

  const latencyMs = Math.max(0, now() - startedAt);

  // Persist trace — best-effort. Errors logged-and-swallowed so a trace
  // failure never blocks the user's answer.
  if (opts.messageId && opts.traceWriter) {
    try {
      await opts.traceWriter({
        message_id: opts.messageId,
        plan,
        executor_response: finalDraft,
        critique,
        regenerated_once: regeneratedOnce,
        latency_ms: latencyMs,
        cost_cents: cumulativeCostCents,
        calibration_warning: calibrationWarning,
      });
    } catch (e) {
      console.warn(
        `legal_planner: trace persist failed: ${String(e).slice(0, 200)}`,
      );
    }
  }

  return {
    kind: "completed",
    replyText: finalDraft,
    plan,
    critique,
    regeneratedOnce,
    latencyMs,
    costCents: cumulativeCostCents,
  };
}

/** Build the executor system prompt. When [critique] is present we're on
 *  the regen pass — inject the issues so the model addresses them
 *  explicitly. */
export function buildExecutorSystem(
  basePrompt: string,
  plan: PlannerPlan,
  critique: PlannerCritique | null,
): string {
  const lines: string[] = [basePrompt, "", EXECUTOR_INSTRUCTIONS_HEADER, ""];

  lines.push("<plan>");
  if (plan.sub_questions.length > 0) {
    lines.push("  <sub_questions>");
    for (const q of plan.sub_questions) lines.push(`    - ${q}`);
    lines.push("  </sub_questions>");
  }
  if (plan.counter_args.length > 0) {
    lines.push("  <counter_args>");
    for (const a of plan.counter_args) lines.push(`    - ${a}`);
    lines.push("  </counter_args>");
  }
  if (plan.evidence_gaps.length > 0) {
    lines.push("  <evidence_gaps>");
    for (const g of plan.evidence_gaps) lines.push(`    - ${g}`);
    lines.push("  </evidence_gaps>");
  }
  if (plan.probability_signal) {
    lines.push(`  <probability_signal>${plan.probability_signal}</probability_signal>`);
  }
  if (plan.alternatives_needed) {
    lines.push("  <alternatives_needed>true</alternatives_needed>");
    lines.push("  <!-- INSTRUCTION: the primary path is weak or closed. You MUST");
    lines.push("       include a section 'Альтернативные пути' with ≥2 independent");
    lines.push("       alternatives the user hasn't considered. Be honest about");
    lines.push("       their probability — do NOT reframe the closed path as viable. -->");
  }
  lines.push("</plan>");

  if (critique) {
    lines.push("");
    lines.push("<critique_for_regen>");
    lines.push(`material_gap=${critique.material_gap}`);
    if (critique.issues.length > 0) {
      lines.push("issues:");
      for (const i of critique.issues) lines.push(`  - ${i}`);
    }
    lines.push(
      "Regenerate the answer addressing each issue above. Keep markers.",
    );
    lines.push("</critique_for_regen>");
  }

  return lines.join("\n");
}
