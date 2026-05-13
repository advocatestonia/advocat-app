// red_team.ts — Adversarial pass for the legal_planner pipeline.
// -----------------------------------------------------------------------------
// Pure-ish module — no Deno globals beyond `fetch`. Imported by
//   • supabase/functions/_shared/legal_planner.ts (after Critique)
//   • supabase/functions/_tests/red_team.test.ts
//
// Spec (from strategic consilium synthesis, 2026-05-13):
//   Insert a Red-Team pass between Critique and final output. The Red-Team
//   reads the draft AS THE OPPOSING PARTY (KHO judge / opposing counsel /
//   prosecutor) and finds the SINGLE STRONGEST reason the advice fails in
//   court. Uses Opus (most capable model for adversarial reasoning).
//
// Pipeline impact:
//   • If attack_severity in {serious, fatal} → orchestrator loops back to
//     the Planner with attack_summary appended to blocking_gaps.
//   • If attack_severity = minor (or attack_found = false) → continue.
//   • Hard cap of 2 round-trips per request (enforced by the caller, not here).
//
// Cost model (approximate, Opus 4):
//   Input  : $15 / Mtok  → 1500 c/Mtok
//   Output : $75 / Mtok  → 7500 c/Mtok
//   Typical pass: ~2k in / ~300 out → ~5.25 cents ≈ $0.052/turn.
//   Two loops worst case: ~$0.10/turn extra. Spec budgets ~$0.02 — actual
//   is higher because Opus is pricier than Sonnet, but still bounded.
// -----------------------------------------------------------------------------

const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";

// Model ID — pinned. Opus is the most capable Anthropic model for the kind
// of adversarial, "find the unstated weakness" reasoning the Red-Team needs.
export const MODEL_OPUS = "claude-opus-4-7";

// Token budget — adversarial pass emits a small JSON payload, not prose.
// Bounded so a runaway model can't blow the cost ceiling on the loop guard.
export const RED_TEAM_MAX_TOKENS = 600;

// Temperature — deterministic. We want the same attack found on re-run so
// the orchestrator's blocking_gaps decision is reproducible in evals.
export const RED_TEAM_TEMPERATURE = 0.0;

// Cost model — cents per million tokens. See header for rationale.
const COST_OPUS_IN_C_PER_MTOK = 1500;
const COST_OPUS_OUT_C_PER_MTOK = 7500;

export function redTeamCostCents(
  inputTokens: number,
  outputTokens: number,
): number {
  return Math.ceil(
    (inputTokens * COST_OPUS_IN_C_PER_MTOK +
      outputTokens * COST_OPUS_OUT_C_PER_MTOK) /
      1_000_000,
  );
}

// ─── Public types ────────────────────────────────────────────────────────

/** Severity of an attack found by the Red-Team pass.
 *  - none    : no attack found, draft is sound.
 *  - minor   : opposing counsel could nitpick but draft survives.
 *  - serious : a real flaw that costs the client significant ground.
 *              Triggers a re-plan with the attack appended to blocking_gaps.
 *  - fatal   : the draft would lose the case on this point alone.
 *              Triggers a re-plan, same path as 'serious'. */
export type AttackSeverity = "none" | "minor" | "serious" | "fatal";

/** Output of a single Red-Team pass. */
export interface RedTeamResult {
  attack_found: boolean;
  attack_severity: AttackSeverity;
  /** One-sentence summary of the strongest attack. */
  attack_summary: string;
  /** Specific exploit — what the opposing party would say, citing the
   *  draft's exact words / missing citation / weak premise. */
  exploit_specifics: string;
  /** Verbatim raw text from the model — truncated for the trace row. */
  raw: string;
  /** Token counts for cost telemetry. */
  inputTokens: number;
  outputTokens: number;
  costCents: number;
}

/** Anthropic call shim — same shape as the legal_planner one so tests can
 *  reuse the same caller pattern. */
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

export const defaultRedTeamCaller: AnthropicCaller = async (req) => {
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

// ─── System prompt ───────────────────────────────────────────────────────

export const RED_TEAM_INSTRUCTIONS = String.raw`
You are the Red-Team pass for Advocat's adversarial legal reasoning loop.

ROLE: You are opposing counsel reading the draft advice your colleague just
prepared for the client. You may also be the KHO judge ruling against the
client, the opposing party's lawyer building their reply, or the prosecutor
cross-examining at trial. Pick whichever adversarial frame is sharpest for
this specific draft.

YOUR JOB: Find the SINGLE STRONGEST reason this advice fails in court.
Be brutal. Be specific. Cite the draft's own words back at it.

Look for (in priority order):
  1. MISSED STATUTE — a specific section the draft should cite but doesn't,
     where the opposing party would point and say "your client just lost".
  2. WRONG JURISDICTION — the draft routes to the wrong court / authority
     (e.g. HAO vs KHO, civil vs criminal, FI vs EE).
  3. MISSED DEADLINE — the draft assumes time the client doesn't have, or
     misses a statutory limitation that bars the path entirely.
  4. UNREBUTTED PRECEDENT — the draft ignores a case the opposing party
     will cite that flips the result.
  5. WRONG STANDARD OF PROOF — the draft applies the wrong burden / test
     for this type of proceeding.
  6. OVERCLAIMED PROBABILITY — the draft says "strong case" when the base
     rate makes this clearly weak.
  7. INTERNAL CONTRADICTION — two parts of the draft cannot both be true.

If you find NOTHING serious after honest inspection, say so explicitly.
Do not invent attacks to seem thorough — a false attack wastes a re-plan
budget that the client is paying for.

OUTPUT FORMAT (strict — the orchestrator parses these tags):

<red_team>
{
  "attack_found": <true|false>,
  "attack_severity": "<none|minor|serious|fatal>",
  "attack_summary": "<one sentence, < 200 chars>",
  "exploit_specifics": "<2-4 sentences, what the opposing party would say>"
}
</red_team>

Severity guide:
  - none    : draft is sound — attack_found MUST be false.
  - minor   : opposing counsel could nitpick but the draft survives. No re-plan.
  - serious : a real flaw that costs the client significant ground. RE-PLAN.
  - fatal   : the draft would lose the case on this point alone. RE-PLAN.

Hard rules:
  - If attack_found=false, attack_severity MUST be "none".
  - If attack_severity in {serious, fatal}, attack_found MUST be true.
  - Stay under 600 tokens. Brevity > thoroughness. ONE strongest attack only.
  - Do NOT rewrite the draft. Do NOT suggest fixes. Just the attack.
  - Do NOT include [[ref:...]] markers — you're attacking, not citing.
`.trim();

// ─── Parser ──────────────────────────────────────────────────────────────

const RAW_TRUNCATE = 4 * 1024;

function truncate(s: string): string {
  return s.length <= RAW_TRUNCATE ? s : s.slice(0, RAW_TRUNCATE);
}

/** Parse a `<red_team>{ ... }</red_team>` block. Tolerant — if JSON parsing
 *  fails, we fall back to a no-attack result so a malformed model output
 *  never accidentally triggers a re-plan (which would burn budget). */
export function parseRedTeamOutput(text: string): {
  attack_found: boolean;
  attack_severity: AttackSeverity;
  attack_summary: string;
  exploit_specifics: string;
  raw: string;
} {
  const tagMatch = text.match(/<red_team>([\s\S]*?)<\/red_team>/i);
  const inner = tagMatch ? tagMatch[1].trim() : text.trim();

  const jsonMatch = inner.match(/\{[\s\S]*\}/);
  if (jsonMatch) {
    try {
      const parsed = JSON.parse(jsonMatch[0]) as {
        attack_found?: unknown;
        attack_severity?: unknown;
        attack_summary?: unknown;
        exploit_specifics?: unknown;
      };
      const found = parsed.attack_found === true;
      const sev = normalizeSeverity(parsed.attack_severity);
      const summary = typeof parsed.attack_summary === "string"
        ? parsed.attack_summary.slice(0, 500)
        : "";
      const specifics = typeof parsed.exploit_specifics === "string"
        ? parsed.exploit_specifics.slice(0, 2000)
        : "";

      // Enforce the contract: attack_found=false ⇒ severity=none.
      // attack_severity in {serious,fatal} ⇒ attack_found=true.
      // We normalise here so downstream code can trust the invariants.
      // ORDER MATTERS: we let severity dominate found in the
      // contradicting-input case (severity=serious wins over found=false),
      // because the severity carries more semantic weight.
      let finalFound = found;
      let finalSev: AttackSeverity = sev;
      // 1. Severity in {serious,fatal} ⇒ found must be true (severity wins).
      if (finalSev === "serious" || finalSev === "fatal") finalFound = true;
      // 2. found=false AND severity not promoted ⇒ severity must be none.
      if (!finalFound) finalSev = "none";
      // 3. found=true but severity=none ⇒ minor (incoherent input).
      if (finalFound && finalSev === "none") finalSev = "minor";

      return {
        attack_found: finalFound,
        attack_severity: finalSev,
        attack_summary: finalFound ? summary : "",
        exploit_specifics: finalFound ? specifics : "",
        raw: truncate(text),
      };
    } catch (_) {
      // fall through
    }
  }

  // Malformed output — default to no-attack so we don't burn a re-plan loop.
  return {
    attack_found: false,
    attack_severity: "none",
    attack_summary: "",
    exploit_specifics: "",
    raw: truncate(text),
  };
}

function normalizeSeverity(v: unknown): AttackSeverity {
  if (typeof v !== "string") return "none";
  const lower = v.toLowerCase().trim();
  if (lower === "fatal") return "fatal";
  if (lower === "serious") return "serious";
  if (lower === "minor") return "minor";
  return "none";
}

// ─── Public API ──────────────────────────────────────────────────────────

export interface RunRedTeamOptions {
  apiKey: string;
  /** The original user-facing system prompt (jurisdiction, case memory,
   *  RAG snippets). The Red-Team sees the same grounding as the Executor
   *  so its attack is anchored to real context, not fabricated. */
  systemPrompt: string;
  /** Plan from the Planner pass — gives Red-Team the sub-questions it
   *  should check were actually answered. */
  plan: {
    sub_questions: string[];
    counter_args: string[];
    evidence_gaps: string[];
    probability_signal: string;
  };
  /** The Executor's draft (post-critique-regen if applicable). This is
   *  the actual text the Red-Team attacks. */
  draft: string;
  /** Conversation messages — last entry is the user's question. */
  messages: Array<{ role: string; content: string }>;
  /** Test override. */
  caller?: AnthropicCaller;
}

/** Run the Red-Team pass. Reads the draft as the opposing party and
 *  returns the strongest attack (or none if the draft is sound).
 *
 *  Never throws — on Anthropic error returns a no-attack result so the
 *  pipeline can continue. The orchestrator decides whether to loop back
 *  based on attack_severity, NOT on whether this function succeeded. */
export async function runRedTeam(
  opts: RunRedTeamOptions,
): Promise<RedTeamResult> {
  const call = opts.caller ?? defaultRedTeamCaller;

  // Build the user message — Red-Team sees the question, the plan, and
  // the draft. We frame it as adversarial input so the model knows it's
  // attacking, not summarising.
  const planSummary: string[] = [];
  if (opts.plan.sub_questions.length > 0) {
    planSummary.push("Plan sub-questions:");
    for (const q of opts.plan.sub_questions) planSummary.push(`  - ${q}`);
  }
  if (opts.plan.counter_args.length > 0) {
    planSummary.push("Plan counter-arguments:");
    for (const a of opts.plan.counter_args) planSummary.push(`  - ${a}`);
  }
  if (opts.plan.evidence_gaps.length > 0) {
    planSummary.push("Plan evidence gaps:");
    for (const g of opts.plan.evidence_gaps) planSummary.push(`  - ${g}`);
  }
  if (opts.plan.probability_signal) {
    planSummary.push(`Plan probability signal: ${opts.plan.probability_signal}`);
  }

  const userQuestion = opts.messages.length > 0
    ? opts.messages[opts.messages.length - 1].content
    : "(no user question available)";

  const adversarialUserMessage = [
    "Client's question:",
    userQuestion,
    "",
    planSummary.join("\n"),
    "",
    "Draft advice (your target):",
    "<draft>",
    opts.draft,
    "</draft>",
    "",
    "Now attack this draft. Find the SINGLE STRONGEST reason it fails in court.",
  ].filter((s) => s !== undefined).join("\n");

  const redTeamSystem = `${opts.systemPrompt}\n\n${RED_TEAM_INSTRUCTIONS}`;

  try {
    const res = await call({
      model: MODEL_OPUS,
      systemPrompt: redTeamSystem,
      messages: [{ role: "user", content: adversarialUserMessage }],
      maxTokens: RED_TEAM_MAX_TOKENS,
      temperature: RED_TEAM_TEMPERATURE,
      apiKey: opts.apiKey,
    });

    const parsed = parseRedTeamOutput(res.text);
    return {
      attack_found: parsed.attack_found,
      attack_severity: parsed.attack_severity,
      attack_summary: parsed.attack_summary,
      exploit_specifics: parsed.exploit_specifics,
      raw: parsed.raw,
      inputTokens: res.inputTokens,
      outputTokens: res.outputTokens,
      costCents: redTeamCostCents(res.inputTokens, res.outputTokens),
    };
  } catch (e) {
    // Anthropic call failed — return no-attack so the pipeline continues.
    // The trace will show empty raw + cost=0 so ops can see the pass
    // didn't actually run.
    console.warn(
      `red_team: pass failed, defaulting to no-attack: ${
        String(e).slice(0, 200)
      }`,
    );
    return {
      attack_found: false,
      attack_severity: "none",
      attack_summary: "",
      exploit_specifics: "",
      raw: `[red_team unavailable: ${String(e).slice(0, 200)}]`,
      inputTokens: 0,
      outputTokens: 0,
      costCents: 0,
    };
  }
}

/** Helper: does this severity warrant a re-plan loop?
 *  Centralised so the orchestrator and tests stay in sync. */
export function severityTriggersReplan(s: AttackSeverity): boolean {
  return s === "serious" || s === "fatal";
}
