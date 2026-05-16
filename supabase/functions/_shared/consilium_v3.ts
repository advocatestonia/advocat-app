// consilium_v3.ts — Adversarial 4-round consilium engine.
// -----------------------------------------------------------------------------
// Replaces the v2 "6 parallel monologues" pattern with a real debate:
//
//   Round 1 — Parallel opinions (same as v2; reuses runRole + ROLES)
//   Round 2 — Adversarial critique: 3 attackers SEE all Round 1 opinions and
//             MUST attack ≥3 weak points in OTHER roles. One attacker is
//             Devil's Advocate (specifically targets consensus).
//   Round 3 — Defense + revise: top-attacked roles see attacks on themselves
//             and either revise or defend with stronger evidence.
//   Synthesis — Chairman sees all 3 rounds. HARD RULE: if 2+ roles disagree
//               by >20pp on probability, MUST surface disagreement explicitly,
//               never average it away.
//   Verifier — Haiku regex/probability check on synthesis. If fail → retry
//              with stricter prompt (max 1 retry).
//
// SSE event sequence (emitted via onEvent):
//   consilium_start → role_done × N → round_1_done →
//   round_2_attack × 3 → round_2_done →
//   round_3_defense × M → round_3_done →
//   synthesis_start → delta × M → synthesis_done →
//   verifier_ok | verifier_retry → done
//
// Cost: ~$0.13–0.18 per consilium (vs ~$0.05 for v2).
// Latency: 25–40s (vs 8s).
//
// Feature flag: caller (claude-proxy) gates v3 behind `CONSILIUM_V3_ENABLED`.
// runConsiliumV3 itself NEVER throws — all errors caught internally.
// -----------------------------------------------------------------------------

import {
  ANTHROPIC_URL,
  buildAnthropicHeaders,
  CALIBRATION_BLOCK,
  callAnthropicBlocking,
  compiledToConsiliumRole,
  type ConsiliumRole,
  hasDeadEnd,
  MODEL_HAIKU,
  MODEL_SONNET,
  ROLES,
  runRole,
} from "./consilium.ts";
import {
  type CaseContext,
  compileRoles,
  DenoMemoryReader,
  type MemoryReader,
  resolveDefaultMemoryDir,
  selectConsiliumRoles,
} from "./consilium_roles/index.ts";
import {
  type LawyerAgent,
  resolveModelId,
} from "./lawyer_agents/index.ts";
import {
  type LawyerRouterDecision,
  routeToLawyers,
} from "./lawyer_router.ts";

// ─── Types ───────────────────────────────────────────────────────────────────

export interface RoleOpinion {
  name: string;
  opinion: string;
}

export interface Attack {
  /** The attacker who produced this attack. */
  attacker: string;
  /** The name of the Round-1 role being criticised. */
  target_role: string;
  /** Short label for the weak point ("ignores §114 timing", etc.). */
  weak_point: string;
  /** Concrete counter-evidence — statute, case, fact, base rate. */
  counter_evidence: string;
}

export interface RevisedOpinion {
  /** Original Round-1 role name. */
  name: string;
  /** "revise" = the role changed its position; "defend" = stood by it with
   *  stronger evidence; "concede" = explicitly conceded the attack was right. */
  stance: "revise" | "defend" | "concede";
  /** Free-text new statement of the role's position after seeing attacks. */
  new_opinion: string;
}

export interface ConsiliumV3SSEEvent {
  type:
    | "consilium_start"
    | "role_done"
    | "round_1_done"
    | "round_2_attack"
    | "round_2_done"
    | "round_3_defense"
    | "round_3_done"
    | "synthesis_start"
    | "delta"
    | "synthesis_done"
    | "verifier_ok"
    | "verifier_retry"
    | "done";
  roles?: string[];
  role?: string;
  attack?: Attack;
  defense?: RevisedOpinion;
  text?: string;
  reason?: string;
}

/** Pluggable Anthropic caller — lets tests script every round deterministically. */
export interface AnthropicCaller {
  blocking(opts: {
    model: string;
    system: string;
    userMessage: string;
    maxTokens: number;
  }): Promise<string>;
  /** Streaming caller — yields text deltas. Should also accumulate the full
   *  text and return it once the stream completes. */
  streaming(opts: {
    model: string;
    system: string;
    userMessage: string;
    maxTokens: number;
    onDelta: (chunk: string) => void;
  }): Promise<string>;
}

export interface VerifierReport {
  ok: boolean;
  /** Human-readable reason — emitted via SSE. */
  reason: string;
  /** When `ok === false`, the hint to append to a retry synthesis prompt. */
  retryHint?: string;
}

// ─── Constants ───────────────────────────────────────────────────────────────

/** Numerical threshold (percentage points) above which the chairman MUST
 *  surface disagreement explicitly rather than averaging. */
export const DISAGREEMENT_THRESHOLD_PP = 20;

const ATTACKERS_PER_ROUND = 3;
const MAX_DEFENDERS = 3;
const MAX_VERIFIER_RETRIES = 1;

// ─── Lawyer department feature flag ──────────────────────────────────────────
// Default OFF. Owner enables via env LAWYER_DEPARTMENT_ENABLED=true once the
// canary deploy is green. When OFF, consilium uses the legacy v2.2 roster
// (DOMAIN_EXPERTS + STRATEGIC_POSITIONS) — identical to pre-P10 behaviour.
export const LAWYER_DEPARTMENT_FLAG_ENV = "LAWYER_DEPARTMENT_ENABLED";

/** Read the lawyer-department feature flag from the runtime env. Defaults to
 *  false on any error (e.g. permission denied). */
export function isLawyerDepartmentEnabled(): boolean {
  try {
    // Deno.env may be undefined in tests / some build steps — guard for it.
    // deno-lint-ignore no-explicit-any
    const env = (globalThis as any).Deno?.env;
    if (!env || typeof env.get !== "function") return false;
    const raw = env.get(LAWYER_DEPARTMENT_FLAG_ENV);
    if (!raw) return false;
    const normalised = raw.toLowerCase().trim();
    return normalised === "true" || normalised === "1" || normalised === "yes";
  } catch {
    return false;
  }
}

/** Convert a LawyerAgent to a ConsiliumRole the runner can consume in Round 1.
 *  The role's `focus` is the agent's compiled system prompt. */
export function lawyerToConsiliumRole(
  agent: LawyerAgent,
  query: string,
  ctx: CaseContext,
): ConsiliumRole {
  return {
    name: agent.name,
    model: resolveModelId(agent.model),
    maxTokens: agent.maxTokens,
    focus: agent.systemPrompt(query, ctx),
    isCompiled: true,
  };
}

// ─── Round 2 prompts ─────────────────────────────────────────────────────────

const ATTACKER_PROMPTS = {
  devils_advocate:
    "Ты — Devil's Advocate. Твоя задача: атаковать КОНСЕНСУС между ролями. " +
    "Если несколько ролей сошлись на одной оценке — это самое опасное место, " +
    "потому что они могли пропустить контрфакт. Атакуй сходство мнений. " +
    "Если все согласны что шанс ~30%, найди причину почему он реально 10% или 60%. " +
    "Запрещено соглашаться. Поведение 'хороший вопрос' = провал.",
  statute_counter:
    "Ты — атакующий по нормам. Твоя задача: найти статью/прецедент которые ПРОТИВОРЕЧАТ " +
    "выводам ролей. Не подтверждай — оспаривай. Цитируй конкретные нормы которые меняют вывод. " +
    "Если роль ссылается на §114 HOL — найди §115 или прецедент KHO который ограничивает её применение. " +
    "Запрещено: общая критика без конкретной нормы.",
  probability_skeptic:
    "Ты — атакующий по вероятностям. Твоя задача: оспорить ЧИСЛОВЫЕ оценки. " +
    "Если Реалист дал 25%, найди базовую ставку из реальной судебной статистики, " +
    "которая ниже или выше. Атакуй необоснованный оптимизм И необоснованный пессимизм. " +
    "Запрещено: 'согласен с Реалистом'. Если Реалист не дал числа — это первая атака.",
} as const;

const ATTACKER_HARD_CONTRACT = `
ЖЁСТКИЙ КОНТРАКТ ОТВЕТА (нарушение = провал, ответ будет отвергнут):

1. Ты ОБЯЗАН атаковать минимум 3 слабые точки в мнениях ДРУГИХ ролей.
2. Каждая атака должна указывать на КОНКРЕТНУЮ роль по имени.
3. Каждая атака должна содержать КОНТР-ДОКАЗАТЕЛЬСТВО: статью, прецедент, базовую ставку или факт.
4. Запрещено выражать согласие, поддержку, "хороший анализ", "правильно отмечено".
5. Если атаковать нечего — найди что атаковать, это всегда есть.

ФОРМАТ ОТВЕТА (строго валидный JSON, без обёртки markdown):
{
  "attacks": [
    {
      "target_role": "ИмяРоли1",
      "weak_point": "короткая метка слабой точки",
      "counter_evidence": "конкретная статья/прецедент/факт/ставка которая опровергает"
    },
    { ... минимум 3 атак всего ... }
  ]
}
`.trim();

// ─── Round 3 prompts ─────────────────────────────────────────────────────────

const DEFENDER_SYSTEM = `Ты получил атаки на свою позицию из Round 2. Тебе нужно либо:
1. REVISE — пересмотреть позицию если атака сильнее твоего исходного мнения,
2. DEFEND — отстоять позицию с УСИЛЕННЫМ доказательством (новая статья, новый прецедент),
3. CONCEDE — признать что атакующий прав и зафиксировать корректное мнение.

ОБЯЗАТЕЛЬНО: если атакующий привёл конкретную норму или прецедент — ты ДОЛЖЕН её адресовать.
Игнорирование = автоматический provoke "слабая защита".

ФОРМАТ ОТВЕТА (строго валидный JSON):
{
  "stance": "revise" | "defend" | "concede",
  "new_opinion": "обновлённая позиция в 3-6 предложениях с конкретными ссылками"
}`;

// ─── Synthesis prompt (revised for v3) ───────────────────────────────────────

const SYNTHESIS_V3_SYSTEM = `Ты — председатель адверсариального юридического консилиума.
Ты видел три раунда:
  Round 1: 6 ролей дали мнения параллельно.
  Round 2: 3 атакующих оспорили мнения, требуя контр-доказательств.
  Round 3: атакованные роли пересмотрели позиции или защитили их сильнее.

ТВОЯ РАБОТА: дать клиенту ответ, который ОТРАЖАЕТ настоящий спор, а не средневзвешенное.

ЖЁСТКИЕ ПРАВИЛА (нарушение = провал):

1. **Сохрани разногласие.** Если 2+ роли расходятся по вероятности больше чем на 20 процентных пунктов,
   ты ОБЯЗАН явно сказать:
     "Эксперты расходятся: A оценивает 30%, B оценивает 10%. Источник расхождения: [причина]. Рекомендация: [что]."
   Запрещено: брать медиану, "примерно 20%", "около 15-25%". Это ЛОЖНАЯ ГАРМОНИЯ.

2. **Перенеси успешные атаки в финальный ответ.** Если Round 2 атака не была опровергнута в Round 3,
   она ДОЛЖНА появиться в синтезе как фактор риска или как обоснование смены оценки.

3. **Приведи числа.** Реалистичный диапазон вероятности всегда. Если они расходятся — оба диапазона.

4. **Сохрани [[ref:slug:para]] маркеры** из мнений ролей и атак.

5. **Запрещено sycophancy:** "сильное дело", "хорошие шансы", "у вас неплохие перспективы" — без цифр это ложь.

СТРУКТУРА ОТВЕТА:

**[Прямой ответ — 2-4 предложения, с диапазоном вероятности]**

**[Где эксперты разошлись и почему]** (только если разногласие >20 п.п.)
Явно перечисли позиции и источник спора.

**[Сильные стороны позиции клиента]**
2-3 пункта со ссылками.

**[Слабые стороны и риски — из Round 2]**
Атаки которые не были опровергнуты. С контр-доказательствами.

**[Альтернативные пути]** (если основной < 25% или закрыт)
Список 2-3 альтернатив с вероятностями.

**[Конкретные шаги]**
Нумерованный список: кто, что, до какой даты.

## Следующие шаги
Чек-лист: "[ ] действие — до даты".

## Непроверенные предположения
Если синтез опирается на неподтверждённый факт — перечисли.`;

const SYNTHESIS_RETRY_HINT = `
⚠️ ПРЕДЫДУЩАЯ ВЕРСИЯ НЕ ПРОШЛА VERIFIER. Исправь:
{retryHint}

Перепиши синтез строго по правилам. Не пропускай числа. Не сглаживай разногласия.`.trim();

// ─── Verifier prompt ─────────────────────────────────────────────────────────

const VERIFIER_SYSTEM = `Ты — verifier синтеза юридического консилиума. Твоя задача — проверить что синтез выполнил жёсткие правила.

Проверь и верни валидный JSON:
{
  "ok": true | false,
  "reason": "1-2 предложения почему",
  "retryHint": "если ok=false, конкретная инструкция что переписать"
}

ПРАВИЛА ПРОВЕРКИ:
1. Есть ли числовой диапазон вероятности? (например "15-25%", "10–20 %")
2. Если в Round-1/Round-3 мнениях была вероятность ниже 25% — упомянуты ли альтернативы?
3. Если в Round 2 атаки были НЕ опровергнуты в Round 3 — отражены ли они как риски?
4. Не использует ли синтез запрещённые фразы без цифр: "сильное дело", "хорошие шансы", "хорошие перспективы"?
5. Если в Round 1+3 были две вероятности расходящиеся больше чем на 20 п.п. — явно ли это сказано в синтезе?`;

// ─── Default Anthropic caller ────────────────────────────────────────────────

/** Production caller — talks to the real Anthropic API. Used by runConsiliumV3
 *  when no caller is injected. Tests pass a deterministic stub. */
export function defaultAnthropicCaller(apiKey: string): AnthropicCaller {
  return {
    async blocking(opts) {
      return await callAnthropicBlocking({ ...opts, apiKey });
    },
    async streaming(opts) {
      let full = "";
      const res = await fetch(ANTHROPIC_URL, {
        method: "POST",
        headers: buildAnthropicHeaders(apiKey),
        body: JSON.stringify({
          model: opts.model,
          max_tokens: opts.maxTokens,
          stream: true,
          system: opts.system,
          messages: [{ role: "user", content: opts.userMessage }],
        }),
      });
      if (!res.ok || res.body === null) {
        throw new Error(`Anthropic stream ${res.status}`);
      }
      const reader = res.body.getReader();
      const decoder = new TextDecoder();
      let buffer = "";
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split("\n");
        buffer = lines.pop() ?? "";
        for (const line of lines) {
          const t = line.trim();
          if (!t.startsWith("data:")) continue;
          const dataStr = t.slice(5).trim();
          if (dataStr === "[DONE]") break;
          try {
            const ev = JSON.parse(dataStr) as Record<string, unknown>;
            if (ev.type === "content_block_delta") {
              const d = ev.delta as Record<string, unknown> | undefined;
              if (d?.type === "text_delta" && typeof d.text === "string") {
                full += d.text;
                opts.onDelta(d.text);
              }
            }
          } catch {
            continue;
          }
        }
      }
      return full;
    },
  };
}

// ─── Helpers — parsing + analysis ────────────────────────────────────────────

/** Strip a model's response down to the first JSON object found. Resilient to
 *  Markdown code fences and surrounding chatter. Returns null if no JSON. */
export function extractJson(text: string): unknown | null {
  const fenced = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  const candidate = (fenced?.[1] ?? text).trim();
  // Try whole string first.
  try {
    return JSON.parse(candidate);
  } catch {
    // Fall through to substring scan.
  }
  // Look for first balanced { ... } block.
  const start = candidate.indexOf("{");
  if (start === -1) return null;
  let depth = 0;
  for (let i = start; i < candidate.length; i++) {
    const c = candidate[i];
    if (c === "{") depth++;
    else if (c === "}") {
      depth--;
      if (depth === 0) {
        const block = candidate.slice(start, i + 1);
        try {
          return JSON.parse(block);
        } catch {
          return null;
        }
      }
    }
  }
  return null;
}

/** Parse an attacker's JSON response into a list of Attacks. Returns [] on
 *  parse failure or schema mismatch — Round 3 will see no attacks for that
 *  attacker (which is the "attacker failed" sentinel). */
export function parseAttackerOutput(
  attackerName: string,
  raw: string,
): Attack[] {
  const obj = extractJson(raw);
  if (!obj || typeof obj !== "object") return [];
  const attacks = (obj as { attacks?: unknown }).attacks;
  if (!Array.isArray(attacks)) return [];
  const out: Attack[] = [];
  for (const a of attacks) {
    if (!a || typeof a !== "object") continue;
    const target = (a as { target_role?: unknown }).target_role;
    const weak = (a as { weak_point?: unknown }).weak_point;
    const evid = (a as { counter_evidence?: unknown }).counter_evidence;
    if (
      typeof target === "string" &&
      typeof weak === "string" &&
      typeof evid === "string" &&
      target.trim() &&
      weak.trim() &&
      evid.trim()
    ) {
      out.push({
        attacker: attackerName,
        target_role: target.trim(),
        weak_point: weak.trim(),
        counter_evidence: evid.trim(),
      });
    }
  }
  return out;
}

/** Parse a defender's JSON response. Returns null on parse failure. */
export function parseDefenderOutput(
  roleName: string,
  raw: string,
): RevisedOpinion | null {
  const obj = extractJson(raw);
  if (!obj || typeof obj !== "object") return null;
  const stance = (obj as { stance?: unknown }).stance;
  const newOp = (obj as { new_opinion?: unknown }).new_opinion;
  if (
    (stance === "revise" || stance === "defend" || stance === "concede") &&
    typeof newOp === "string" &&
    newOp.trim()
  ) {
    return { name: roleName, stance, new_opinion: newOp.trim() };
  }
  return null;
}

/** Extract the highest-bound percentage from an opinion's first probability
 *  range. Returns null if no `\d+\s*[–—-]\s*\d+\s*%` pattern is found. */
export function extractHighProbability(text: string): number | null {
  const m = text.match(/(\d+)\s*[–—-]\s*(\d+)\s*%/);
  if (!m) {
    // Try single-number `\d+%` as a fallback.
    const single = text.match(/(\d+)\s*%/);
    if (!single) return null;
    const n = parseInt(single[1], 10);
    return Number.isFinite(n) ? n : null;
  }
  const high = parseInt(m[2], 10);
  return Number.isFinite(high) ? high : null;
}

/** Detect a disagreement of >threshold percentage points between any two
 *  opinions in the set. Returns the pair of {name, prob} that disagrees most. */
export function detectDisagreement(
  opinions: RoleOpinion[],
  thresholdPp: number = DISAGREEMENT_THRESHOLD_PP,
): { a: { name: string; prob: number }; b: { name: string; prob: number } } | null {
  const withProb: Array<{ name: string; prob: number }> = [];
  for (const o of opinions) {
    const p = extractHighProbability(o.opinion);
    if (p !== null) withProb.push({ name: o.name, prob: p });
  }
  if (withProb.length < 2) return null;
  let best: { a: { name: string; prob: number }; b: { name: string; prob: number } } | null = null;
  let bestDelta = thresholdPp;
  for (let i = 0; i < withProb.length; i++) {
    for (let j = i + 1; j < withProb.length; j++) {
      const delta = Math.abs(withProb[i].prob - withProb[j].prob);
      if (delta > bestDelta) {
        bestDelta = delta;
        best = { a: withProb[i], b: withProb[j] };
      }
    }
  }
  return best;
}

/** Pick the top-N most-attacked roles from a list of Round-2 attacks.
 *  Used to decide which roles enter Round 3 (defenders). */
export function pickTopAttackedRoles(
  attacks: Attack[],
  maxRoles: number = MAX_DEFENDERS,
): string[] {
  const counts = new Map<string, number>();
  for (const a of attacks) {
    counts.set(a.target_role, (counts.get(a.target_role) ?? 0) + 1);
  }
  return Array.from(counts.entries())
    .sort((a, b) => b[1] - a[1])
    .slice(0, maxRoles)
    .map(([name]) => name);
}

// ─── Round 2 — Adversarial critique ──────────────────────────────────────────

export interface AttackerSpec {
  name: string;
  systemPersona: string;
}

export const DEFAULT_ATTACKERS: AttackerSpec[] = [
  { name: "Devil's Advocate", systemPersona: ATTACKER_PROMPTS.devils_advocate },
  { name: "Statute Counter-Attack", systemPersona: ATTACKER_PROMPTS.statute_counter },
  { name: "Probability Skeptic", systemPersona: ATTACKER_PROMPTS.probability_skeptic },
];

/** Build the user message handed to each Round-2 attacker. Includes ALL
 *  Round-1 opinions so attackers can find weak points across roles. */
export function buildAttackerUserMessage(
  originalQuestion: string,
  round1: RoleOpinion[],
): string {
  const lines: string[] = [
    `Изначальный вопрос клиента: ${originalQuestion}`,
    "",
    "Мнения Round 1:",
    "",
  ];
  for (const op of round1) {
    lines.push(`### ${op.name}`);
    lines.push(op.opinion);
    lines.push("");
  }
  lines.push("Атакуй сейчас. Минимум 3 атаки. Только JSON.");
  return lines.join("\n");
}

/** Run all 3 attackers in parallel. Each gets the full Round-1 set. */
export async function runRound2Adversarial(params: {
  originalQuestion: string;
  round1: RoleOpinion[];
  attackers?: AttackerSpec[];
  caller: AnthropicCaller;
  onAttack?: (attack: Attack) => void;
}): Promise<Attack[]> {
  const attackers = params.attackers ?? DEFAULT_ATTACKERS;
  const userMessage = buildAttackerUserMessage(
    params.originalQuestion,
    params.round1,
  );

  const results = await Promise.all(
    attackers.map(async (attacker) => {
      const system = `${attacker.systemPersona}\n\n${ATTACKER_HARD_CONTRACT}`;
      try {
        const raw = await params.caller.blocking({
          model: MODEL_SONNET,
          system,
          userMessage,
          maxTokens: 800,
        });
        const attacks = parseAttackerOutput(attacker.name, raw);
        for (const a of attacks) {
          params.onAttack?.(a);
        }
        return attacks;
      } catch (e) {
        console.warn(
          `consilium_v3: attacker "${attacker.name}" failed: ${
            String(e).slice(0, 200)
          }`,
        );
        return [];
      }
    }),
  );

  // Flatten + ensure ATTACKERS_PER_ROUND attackers were attempted.
  void ATTACKERS_PER_ROUND;
  return results.flat();
}

// ─── Round 3 — Defense + revise ──────────────────────────────────────────────

/** Build the defender's user message: their original opinion + attacks
 *  targeting them. */
export function buildDefenderUserMessage(
  originalQuestion: string,
  roleName: string,
  originalOpinion: string,
  attacksOnMe: Attack[],
): string {
  const lines: string[] = [
    `Вопрос клиента: ${originalQuestion}`,
    "",
    `Твоя исходная позиция (Round 1, роль "${roleName}"):`,
    originalOpinion,
    "",
    "Атаки на твою позицию из Round 2:",
    "",
  ];
  for (const a of attacksOnMe) {
    lines.push(`- [${a.attacker}] ${a.weak_point}`);
    lines.push(`  Контр-доказательство: ${a.counter_evidence}`);
  }
  lines.push("");
  lines.push(
    "Ответь JSON-ом. Если контр-доказательство сильнее твоего мнения — REVISE или CONCEDE.",
  );
  return lines.join("\n");
}

/** Run Round 3 defenders. Defenders are the top-N most-attacked Round-1 roles.
 *  Roles not attacked are skipped (their Round-1 opinion stands). */
export async function runRound3Defense(params: {
  originalQuestion: string;
  round1: RoleOpinion[];
  attacks: Attack[];
  caller: AnthropicCaller;
  onDefense?: (defense: RevisedOpinion) => void;
}): Promise<RevisedOpinion[]> {
  const topAttacked = pickTopAttackedRoles(params.attacks);
  if (topAttacked.length === 0) return [];

  const round1Map = new Map(params.round1.map((o) => [o.name, o.opinion]));
  const attacksByRole = new Map<string, Attack[]>();
  for (const a of params.attacks) {
    const list = attacksByRole.get(a.target_role) ?? [];
    list.push(a);
    attacksByRole.set(a.target_role, list);
  }

  const defenders = topAttacked.filter((name) => round1Map.has(name));

  const results = await Promise.all(
    defenders.map(async (name) => {
      const originalOpinion = round1Map.get(name) ?? "";
      const attacksOnMe = attacksByRole.get(name) ?? [];
      const userMessage = buildDefenderUserMessage(
        params.originalQuestion,
        name,
        originalOpinion,
        attacksOnMe,
      );
      try {
        const raw = await params.caller.blocking({
          model: MODEL_SONNET,
          system: DEFENDER_SYSTEM,
          userMessage,
          maxTokens: 500,
        });
        const parsed = parseDefenderOutput(name, raw);
        if (parsed) {
          params.onDefense?.(parsed);
          return parsed;
        }
        return null;
      } catch (e) {
        console.warn(
          `consilium_v3: defender "${name}" failed: ${String(e).slice(0, 200)}`,
        );
        return null;
      }
    }),
  );

  return results.filter((r): r is RevisedOpinion => r !== null);
}

// ─── Synthesis ──────────────────────────────────────────────────────────────

/** Build the synthesis user message containing all 3 rounds + the
 *  disagreement summary so the chairman cannot accidentally drop it. */
export function buildSynthesisV3UserMessage(params: {
  originalQuestion: string;
  round1: RoleOpinion[];
  attacks: Attack[];
  round3: RevisedOpinion[];
  deadEnd: boolean;
  disagreement: ReturnType<typeof detectDisagreement>;
  retryHint?: string;
}): string {
  const lines: string[] = [
    `Вопрос клиента: ${params.originalQuestion}`,
    "",
    "━━━ ROUND 1 — мнения специалистов ━━━",
    "",
  ];
  for (const o of params.round1) {
    lines.push(`### ${o.name}`);
    lines.push(o.opinion);
    lines.push("");
  }

  lines.push("━━━ ROUND 2 — атаки ━━━");
  lines.push("");
  if (params.attacks.length === 0) {
    lines.push("(атак не было — все ответы атакующих провалились)");
    lines.push("");
  } else {
    for (const a of params.attacks) {
      lines.push(
        `[${a.attacker} → ${a.target_role}] ${a.weak_point}`,
      );
      lines.push(`  Контр: ${a.counter_evidence}`);
    }
    lines.push("");
  }

  lines.push("━━━ ROUND 3 — защита / пересмотр ━━━");
  lines.push("");
  if (params.round3.length === 0) {
    lines.push("(никто не пересматривал; Round 1 позиции остаются в силе)");
    lines.push("");
  } else {
    for (const r of params.round3) {
      lines.push(`### ${r.name} (${r.stance})`);
      lines.push(r.new_opinion);
      lines.push("");
    }
  }

  if (params.disagreement) {
    lines.push("⚠️ ОБНАРУЖЕНО РАЗНОГЛАСИЕ:");
    lines.push(
      `  ${params.disagreement.a.name} даёт ${params.disagreement.a.prob}% (верхняя граница).`,
    );
    lines.push(
      `  ${params.disagreement.b.name} даёт ${params.disagreement.b.prob}% (верхняя граница).`,
    );
    lines.push(
      "ОБЯЗАТЕЛЬНО яви это расхождение в синтезе по правилу 1.",
    );
    lines.push("");
  }

  if (params.deadEnd) {
    lines.push(
      "⚠️ DEAD-END DETECTED: основной путь < 25%. Начни ответ с признания этого и сразу дай альтернативы.",
    );
    lines.push("");
  }

  if (params.retryHint) {
    lines.push(SYNTHESIS_RETRY_HINT.replace("{retryHint}", params.retryHint));
    lines.push("");
  }

  lines.push(
    "Синтезируй ответ от первого лица единственного числа. Следуй структуре из системного промпта.",
  );
  return lines.join("\n");
}

// ─── Verifier ────────────────────────────────────────────────────────────────

export function buildVerifierUserMessage(params: {
  synthesis: string;
  disagreement: ReturnType<typeof detectDisagreement>;
  attacks: Attack[];
  round3: RevisedOpinion[];
}): string {
  const lines: string[] = [
    "Синтез для проверки:",
    "",
    params.synthesis,
    "",
    "━━━ Контекст для проверки ━━━",
  ];
  if (params.disagreement) {
    lines.push(
      `В Round 1/3 было расхождение >20 п.п.: ${params.disagreement.a.name}=${params.disagreement.a.prob}% vs ${params.disagreement.b.name}=${params.disagreement.b.prob}%.`,
    );
    lines.push(
      "Проверь что в синтезе явно показано это расхождение (правило 5).",
    );
  } else {
    lines.push("Существенного расхождения вероятностей не было.");
  }
  lines.push(`Round 2 атак было: ${params.attacks.length}.`);
  lines.push(`Round 3 пересмотров было: ${params.round3.length}.`);
  lines.push("");
  lines.push("Верни валидный JSON по схеме из системного промпта.");
  return lines.join("\n");
}

/** Run the verifier. Tolerant: any parse / API error returns {ok:true} so a
 *  flaky Haiku call doesn't kill an otherwise-good consilium. */
export async function runVerifier(params: {
  synthesis: string;
  disagreement: ReturnType<typeof detectDisagreement>;
  attacks: Attack[];
  round3: RevisedOpinion[];
  caller: AnthropicCaller;
}): Promise<VerifierReport> {
  // First: hard local checks (no API call required).
  const localChecks = runLocalVerifierChecks(params);
  if (!localChecks.ok) return localChecks;

  // Then: ask Haiku for a semantic check.
  try {
    const raw = await params.caller.blocking({
      model: MODEL_HAIKU,
      system: VERIFIER_SYSTEM,
      userMessage: buildVerifierUserMessage(params),
      maxTokens: 250,
    });
    const obj = extractJson(raw);
    if (!obj || typeof obj !== "object") {
      return { ok: true, reason: "verifier-unparseable-allowing" };
    }
    const ok = (obj as { ok?: unknown }).ok === true;
    const reason = String((obj as { reason?: unknown }).reason ?? "").slice(0, 300);
    const hint = String((obj as { retryHint?: unknown }).retryHint ?? "").slice(0, 500);
    return {
      ok,
      reason: reason || (ok ? "ok" : "verifier-rejected"),
      retryHint: ok ? undefined : hint,
    };
  } catch (e) {
    console.warn(
      `consilium_v3: verifier failed (allowing): ${String(e).slice(0, 200)}`,
    );
    return { ok: true, reason: "verifier-error-allowing" };
  }
}

/** Cheap deterministic checks that don't need an API call.
 *  Runs BEFORE the Haiku semantic check so obvious failures retry instantly. */
export function runLocalVerifierChecks(params: {
  synthesis: string;
  disagreement: ReturnType<typeof detectDisagreement>;
  attacks: Attack[];
  round3: RevisedOpinion[];
}): VerifierReport {
  const s = params.synthesis;

  // 1. Probability range OR single % present.
  const probMatch = s.match(/(\d+)\s*[–—-]\s*(\d+)\s*%/) ?? s.match(/(\d+)\s*%/);
  if (!probMatch) {
    return {
      ok: false,
      reason: "no probability range or percentage in synthesis",
      retryHint:
        "Добавь конкретный числовой диапазон вероятности (например '15-25%').",
    };
  }

  // 2. If disagreement >20pp existed, both numbers must appear in synthesis.
  if (params.disagreement) {
    const aOk = s.includes(`${params.disagreement.a.prob}%`) ||
      s.includes(`${params.disagreement.a.prob} %`);
    const bOk = s.includes(`${params.disagreement.b.prob}%`) ||
      s.includes(`${params.disagreement.b.prob} %`);
    if (!(aOk && bOk)) {
      return {
        ok: false,
        reason: "disagreement >20pp present but not surfaced in synthesis",
        retryHint:
          `Эксперты расходятся: ${params.disagreement.a.name}=${params.disagreement.a.prob}%, ${params.disagreement.b.name}=${params.disagreement.b.prob}%. Покажи это явно.`,
      };
    }
  }

  // 3. Banned sycophancy phrases without numbers nearby.
  const banned = [
    /сильное\s+дело/iu,
    /хорошие\s+шансы/iu,
    /хорошие\s+перспективы/iu,
    /strong\s+case/i,
    /good\s+chances/i,
  ];
  for (const re of banned) {
    const m = s.match(re);
    if (m && m.index !== undefined) {
      // Allow if a % appears within 80 chars of the phrase.
      const window = s.slice(
        Math.max(0, m.index - 40),
        Math.min(s.length, m.index + (m[0].length) + 80),
      );
      if (!/\d+\s*%/.test(window)) {
        return {
          ok: false,
          reason: `sycophancy phrase "${m[0]}" without nearby probability`,
          retryHint:
            `Убери фразу "${m[0]}" или поставь рядом конкретный процент.`,
        };
      }
    }
  }

  return { ok: true, reason: "local-checks-passed" };
}

// ─── Main entry point ────────────────────────────────────────────────────────

export interface RunConsiliumV3Params {
  userMessage: string;
  systemPrompt: string;
  ragContext: string;
  caseContext: string;
  anthropicApiKey: string;
  onEvent: (event: ConsiliumV3SSEEvent) => void;
  caseClassification?: CaseContext;
  memoryReader?: MemoryReader;
  /** Optional injected caller — tests pass a deterministic stub. */
  caller?: AnthropicCaller;
  /** Custom attackers (tests). Defaults to DEFAULT_ATTACKERS. */
  attackers?: AttackerSpec[];
  /** Override the LAWYER_DEPARTMENT_ENABLED env flag for tests and callers
   *  that want explicit control. Defaults to reading the env. */
  lawyerDepartmentEnabled?: boolean;
  /** When true AND `lawyerDepartmentEnabled === true`, force the lawyer
   *  department to fire even on low-complexity queries. Used by tests and
   *  callers who already know this is a high-value request. */
  forceLawyerDepartment?: boolean;
}

/** Run the v3 adversarial consilium and stream synthesis via onEvent.
 *  NEVER throws — all errors are caught internally. Returns the (possibly
 *  retried) synthesis text. */
export async function runConsiliumV3(
  params: RunConsiliumV3Params,
): Promise<string> {
  const caller = params.caller ?? defaultAnthropicCaller(params.anthropicApiKey);

  // ── 1. Pick role roster ─────────────────────────────────────────────────
  // Priority order:
  //   (a) Lawyer department (if feature-flagged on AND complexity ≥ 7
  //       OR jurisdiction = "mixed" OR hasHardDeadline). Real specialised
  //       lawyers — 3 to 5 selected by lawyer_router.
  //   (b) v2.2 router (DOMAIN_EXPERTS + STRATEGIC_POSITIONS) — current
  //       production default.
  //   (c) Legacy 6 generic roles — fallback when nothing else matches.
  let activeRoles: ConsiliumRole[] = [...ROLES];
  let lawyerDecision: LawyerRouterDecision | null = null;

  const flagOn = params.lawyerDepartmentEnabled ?? isLawyerDepartmentEnabled();
  if (flagOn && params.caseClassification) {
    try {
      const ctx = params.caseClassification;
      const lang = (ctx.language ?? "ru") as NonNullable<CaseContext["language"]>;
      const decision = routeToLawyers(params.userMessage, lang, ctx);
      // Only fire when complexity / jurisdiction / deadline justifies it.
      // The router exposes highStakes; we additionally allow it when caller
      // forces it via `forceLawyerDepartment`.
      if (decision.highStakes || params.forceLawyerDepartment) {
        lawyerDecision = decision;
        activeRoles = decision.agents.map((a) =>
          lawyerToConsiliumRole(a, params.userMessage, ctx)
        );
      }
    } catch (e) {
      console.warn(
        `consilium_v3: lawyer_router failed, falling back: ${
          String(e).slice(0, 200)
        }`,
      );
    }
  }

  // Fallback to v2.2 router only if the lawyer department did NOT take over.
  if (!lawyerDecision && params.caseClassification) {
    try {
      const selection = selectConsiliumRoles(params.caseClassification);
      if (selection.hasDomainMatch) {
        const reader = params.memoryReader ??
          new DenoMemoryReader(resolveDefaultMemoryDir());
        const compiled = await compileRoles({
          selection,
          ctx: params.caseClassification,
          memoryReader: reader,
        });
        activeRoles = compiled.map(compiledToConsiliumRole);
      }
    } catch (e) {
      console.warn(
        `consilium_v3: v2.2 router failed, using legacy roster: ${
          String(e).slice(0, 200)
        }`,
      );
    }
  }

  params.onEvent({
    type: "consilium_start",
    roles: activeRoles.map((r) => r.name),
  });

  // ── 2. Round 1 — parallel opinions ───────────────────────────────────────
  // Use the existing runRole exported from consilium.ts so v2 ↔ v3 stay
  // consistent. runRole catches its own errors.
  const round1Promises = activeRoles.map((role) =>
    runRole(
      role,
      params.userMessage,
      params.systemPrompt,
      params.ragContext,
      params.caseContext,
      params.anthropicApiKey,
    ).then((opinion) => {
      params.onEvent({ type: "role_done", role: opinion.name });
      return opinion;
    })
  );

  let round1: RoleOpinion[];
  try {
    round1 = await Promise.all(round1Promises);
  } catch (e) {
    // runRole never throws; defensive fallback.
    console.error(
      `consilium_v3: round 1 Promise.all unexpectedly threw: ${
        String(e).slice(0, 200)
      }`,
    );
    round1 = activeRoles.map((r) => ({ name: r.name, opinion: "[роль недоступна]" }));
  }
  params.onEvent({ type: "round_1_done" });

  // ── 3. Round 2 — adversarial critique ────────────────────────────────────
  const attacks = await runRound2Adversarial({
    originalQuestion: params.userMessage,
    round1,
    attackers: params.attackers,
    caller,
    onAttack: (a) => params.onEvent({ type: "round_2_attack", attack: a }),
  });
  params.onEvent({ type: "round_2_done" });

  // ── 4. Round 3 — defense / revise ────────────────────────────────────────
  const round3 = await runRound3Defense({
    originalQuestion: params.userMessage,
    round1,
    attacks,
    caller,
    onDefense: (d) => params.onEvent({ type: "round_3_defense", defense: d }),
  });
  params.onEvent({ type: "round_3_done" });

  // ── 5. Synthesis (with possible 1 retry) ─────────────────────────────────
  // Build the combined opinion set used for disagreement detection — Round 3
  // revisions take priority over Round 1 originals.
  const round3Map = new Map(round3.map((r) => [r.name, r.new_opinion]));
  const finalOpinions: RoleOpinion[] = round1.map((o) =>
    round3Map.has(o.name)
      ? { name: o.name, opinion: round3Map.get(o.name)! }
      : o
  );
  const disagreement = detectDisagreement(finalOpinions);
  const deadEnd = hasDeadEnd(finalOpinions);

  const synthesisContextParts: string[] = [SYNTHESIS_V3_SYSTEM];
  if (params.caseContext.trim()) {
    synthesisContextParts.push(
      `\n\n<case_context>\n${params.caseContext}\n</case_context>`,
    );
  }
  if (params.ragContext.trim()) {
    synthesisContextParts.push(
      `\n\n<law_context>\n${params.ragContext}\n</law_context>`,
    );
  }
  synthesisContextParts.push(`\n\n${CALIBRATION_BLOCK}`);
  const synthesisSystem = synthesisContextParts.join("");

  params.onEvent({ type: "synthesis_start" });

  let synthesis = "";
  let retryHint: string | undefined = undefined;

  for (let attempt = 0; attempt <= MAX_VERIFIER_RETRIES; attempt++) {
    synthesis = "";
    const userMsg = buildSynthesisV3UserMessage({
      originalQuestion: params.userMessage,
      round1,
      attacks,
      round3,
      deadEnd,
      disagreement,
      retryHint,
    });

    try {
      synthesis = await caller.streaming({
        model: MODEL_SONNET,
        system: synthesisSystem,
        userMessage: userMsg,
        maxTokens: 2048,
        onDelta: (chunk) => {
          params.onEvent({ type: "delta", text: chunk });
        },
      });
    } catch (e) {
      console.warn(
        `consilium_v3: streaming failed, attempting blocking: ${
          String(e).slice(0, 200)
        }`,
      );
      try {
        synthesis = await caller.blocking({
          model: MODEL_SONNET,
          system: synthesisSystem,
          userMessage: userMsg,
          maxTokens: 2048,
        });
        if (synthesis) {
          params.onEvent({ type: "delta", text: synthesis });
        }
      } catch (e2) {
        console.error(
          `consilium_v3: blocking fallback failed: ${String(e2).slice(0, 200)}`,
        );
        synthesis =
          "Консилиум временно недоступен. Пожалуйста, повторите запрос.";
        params.onEvent({ type: "delta", text: synthesis });
        // Don't retry an error-message synthesis.
        break;
      }
    }

    params.onEvent({ type: "synthesis_done" });

    // ── 6. Verifier ───────────────────────────────────────────────────────
    const verifier = await runVerifier({
      synthesis,
      disagreement,
      attacks,
      round3,
      caller,
    });

    if (verifier.ok) {
      params.onEvent({ type: "verifier_ok", reason: verifier.reason });
      break;
    }

    if (attempt >= MAX_VERIFIER_RETRIES) {
      // Out of retries — accept the current synthesis but log the failure.
      params.onEvent({
        type: "verifier_retry",
        reason: `verifier-failed-no-retries-left: ${verifier.reason}`,
      });
      break;
    }

    params.onEvent({
      type: "verifier_retry",
      reason: verifier.reason,
    });
    retryHint = verifier.retryHint;
    // Next loop iteration re-streams synthesis with retryHint appended.
  }

  params.onEvent({ type: "done" });
  return synthesis;
}

// ─── Re-exports for convenience ──────────────────────────────────────────────

export { ROLES } from "./consilium.ts";
