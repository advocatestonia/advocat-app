// consilium.ts — Phase 2 multi-role legal consilium orchestrator.
// -----------------------------------------------------------------------------
// Pure-ish module — no Deno globals beyond `fetch`. Imported by
//   • supabase/functions/claude-proxy/index.ts (when consilium routing fires)
//   • Deno tests for the consilium contract
//
// What it does:
//   Runs N specialised legal-AI roles in PARALLEL (Promise.all), then
//   streams a Sonnet-synthesised answer via an onEvent callback. The caller
//   converts onEvent calls into SSE frames and pipes them to the HTTP response.
//
// Role architecture (v2.2 — two-layer):
//   Layer 1 — DomainExpert (statute-anchored):
//     immigration-fi, criminal-fi, criminal-ee, contract-ee, contract-de,
//     employment-ee, employment-fi, gdpr-eu, tax-ee, family-ee, consumer-eu
//   Layer 2 — StrategicPosition (reasoning patterns):
//     decision-maker-risk, procedural-posture, silent-concession, long-game,
//     23-test, deadline-strategist
//
// The router selectConsiliumRoles(caseContext) picks 2-3 domain + 2-3 strategic
// (4-6 total). If no domain expert applies, the runner falls back to the
// legacy 6 generic roles (kept below) so existing callers don't break.
//
// Routing: shouldRunConsilium() uses Haiku to classify the user message.
// The caller should invoke it BEFORE deciding to call runConsilium().
//
// SSE event sequence (emitted via onEvent):
//   consilium_start → role_done × N (order depends on completion) →
//   synthesis_start → delta × N → done
//
// Error handling: per-role try/catch; a failed role passes "[роль недоступна]"
// to synthesis. runConsilium() itself NEVER throws.
// -----------------------------------------------------------------------------

import {
  type CaseContext,
  type CompiledRole,
  compileRoles,
  DenoMemoryReader,
  type MemoryReader,
  resolveDefaultMemoryDir,
  selectConsiliumRoles,
} from "./consilium_roles/index.ts";
import { scrubAnthropicBody } from "./llm_egress/scrub_body.ts";

export const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";

// Upstream timeout for Anthropic calls. Without it a hung upstream connection
// keeps the isolate (and any holding request) alive indefinitely. 120s is well
// above p99 latency for the Sonnet calls used here.
export const ANTHROPIC_FETCH_TIMEOUT_MS = 120_000;

// Model IDs — pinned; update here if rotated.
export const MODEL_SONNET = "claude-sonnet-4-6";
export const MODEL_HAIKU = "claude-haiku-4-5-20251001";

// ─── SSE event types ─────────────────────────────────────────────────────────
//
// Event timeline (v2 non-adversarial):
//   consilium_start    — emitted once at run start with the full role roster.
//                        `roles` is the legacy string[] of display names;
//                        `roster` (optional) carries {id,name} pairs the new
//                        Flutter UI can render as chips. Both are populated
//                        when the lawyer-department bridge fires; with the
//                        legacy ROLES, `roster` falls back to {id=name,name}.
//   role_done          — emitted as each role finishes (any order). Carries
//                        only the role name (backward-compat — existing
//                        Flutter consumers parse this).
//   role_opinion       — NEW. Emitted immediately after role_done with the
//                        per-role detail the timeline UI needs (opinion text
//                        snippet, position label, confidence hint, optional
//                        key citation). Backward-compat: callers that don't
//                        care can ignore unknown event types.
//   synthesis_start    — Sonnet synthesis begins streaming.
//   delta              — Sonnet text chunks.
//   done               — terminal sentinel.
// -----------------------------------------------------------------------------

/** Position label produced per role. The actual classification heuristic is
 *  intentionally lightweight (keyword scan); the field is informational. */
export type ConsiliumRolePosition =
  | "push" // role advocates pushing the case forward
  | "settle" // role recommends settlement / concession
  | "investigate" // role asks for more evidence first
  | "out_of_scope" // role declined to weigh in
  | "unknown"; // heuristic could not classify

export interface ConsiliumRoleOpinionPayload {
  /** Stable role id (kebab-case when available; falls back to display name). */
  role_id: string;
  /** Display name shown in UI. NOTE: wire-format key is `role_name` (see
   *  ConsiliumSSEEvent.role_opinion). This field name is retained on the
   *  internal payload type for backwards-compat with callers that built it
   *  directly; the SSE event emits `role_name` so the Flutter parser at
   *  lib/services/claude_service.dart finds it top-level. */
  role: string;
  /** 1-2 sentence summary of what the role argued. Trimmed to ~400 chars. */
  opinion: string;
  /** Classification of the role's stance — best-effort heuristic. */
  position: ConsiliumRolePosition;
  /** Heuristic 0-1 confidence the role expressed. `null` when not detectable. */
  confidence: number | null;
  /** First [[ref:slug:para]] marker found in the opinion, if any. */
  key_citation: string | null;
}

// Wire format for the role_opinion SSE event.
// FLAT shape (2026-05-25, Phase 1.1 bug fix): all fields are top-level on the
// SSE frame so the Flutter parser at lib/services/claude_service.dart can
// read parsed['role_id'], parsed['role_name'], parsed['opinion'], etc. The
// older nested `{type:"role_opinion", payload:{...}}` shape was incompatible
// with the Flutter parser and caused empty role cards.
export type ConsiliumSSEEvent =
  | {
      type: "consilium_start";
      /** Legacy field — display names. */
      roles: string[];
      /** New optional field — id/name pairs. Older clients ignore. */
      roster?: Array<{ id: string; name: string }>;
      /** Convenience count for the UI. */
      total?: number;
    }
  | { type: "role_done"; role: string }
  | ({ type: "role_opinion" } & {
      role_id: string;
      role_name: string;
      opinion: string;
      position: ConsiliumRolePosition;
      confidence: number | null;
      key_citation: string | null;
    })
  | { type: "synthesis_start" }
  | { type: "delta"; text: string }
  | { type: "done" };

// ─── Role-opinion heuristics (pure, deterministic) ───────────────────────────

/** First [[ref:slug:para]] marker in `text`, or null. */
export function findKeyCitation(text: string): string | null {
  const m = text.match(/\[\[ref:[^\]]+\]\]/);
  return m ? m[0] : null;
}

/** Best-effort 1-2 sentence summary cut from the start of the opinion.
 *  Falls back to first 300 chars if no sentence boundary is found. */
export function summariseOpinion(text: string, maxLen = 400): string {
  const cleaned = text.trim();
  if (cleaned.length === 0) return "";
  // Look for first 1-2 sentence boundaries. Russian uses ./!/?; account for
  // Estonian/Finnish similarly.
  const re = /([.!?])\s+/g;
  let cutAt = -1;
  let sentences = 0;
  let match: RegExpExecArray | null;
  while ((match = re.exec(cleaned)) !== null) {
    sentences++;
    if (sentences >= 2 || (sentences >= 1 && match.index > 220)) {
      cutAt = match.index + 1;
      break;
    }
  }
  const summary = cutAt > 0 ? cleaned.slice(0, cutAt) : cleaned;
  if (summary.length <= maxLen) return summary.trim();
  // Hard truncate with ellipsis on word boundary.
  const truncated = summary.slice(0, maxLen).replace(/\s+\S*$/, "");
  return `${truncated}…`;
}

/**
 * Neutralize a closing-tag breakout inside untrusted context text before it is
 * embedded in a trusted system-prompt block. caseContext is derived from
 * user-supplied case facts / uploaded-document text, so a crafted
 * `</case_context>` could otherwise close the block and inject forged trusted
 * instructions. NFKC folds Unicode look-alikes into ASCII first so the regex
 * catches compatibility-equivalent closers too (mirrors wrapUntrusted).
 */
function sealContext(tag: string, text: string): string {
  const normalised = typeof (text as { normalize?: unknown }).normalize ===
      "function"
    ? text.normalize("NFKC")
    : text;
  const re = new RegExp(`<\\s*/\\s*${tag}\\s*>`, "gi");
  return normalised.replace(re, `&lt;/${tag}&gt;`);
}

/** Heuristic position label from raw opinion text. Pure / deterministic. */
export function classifyRolePosition(text: string): ConsiliumRolePosition {
  const t = text.toLowerCase();
  if (
    t.includes("[роль недоступна]") ||
    t.includes("out of scope") ||
    t.includes("вне моей специализации")
  ) {
    return "out_of_scope";
  }
  // Settle / concede signals.
  const settle = [
    "settle", "сдат", "мирово", "согласи", "переговор",
    "concede", "признать", "не оспаривать", "asovita", "kokkulep",
  ];
  if (settle.some((kw) => t.includes(kw))) return "settle";
  // Investigate / gather-more signals.
  const investigate = [
    "недостаточно фактов", "запросить", "выяснить", "нужно больше",
    "missing fact", "investigate", "selvit", "uurida", "selvittä",
  ];
  if (investigate.some((kw) => t.includes(kw))) return "investigate";
  // Push signals — affirmative action verbs.
  const push = [
    "подать", "обжалов", "valita", "kaeba", "file ", "appeal", "submit",
    "argue", "наступа", "идти в суд", "kohtuss", "tuomioistuim",
  ];
  if (push.some((kw) => t.includes(kw))) return "push";
  return "unknown";
}

/** Heuristic 0-1 confidence pulled from any probability range in the text.
 *  Returns the midpoint of the first `\d+\s*[–—-]\s*\d+\s*%` range or the
 *  first `\d+\s*%` value, normalised to 0-1. Returns null when no number. */
export function extractConfidenceHint(text: string): number | null {
  const range = text.match(/(\d{1,3})\s*[–—-]\s*(\d{1,3})\s*%/);
  if (range) {
    const lo = parseInt(range[1], 10);
    const hi = parseInt(range[2], 10);
    if (Number.isFinite(lo) && Number.isFinite(hi)) {
      const mid = (lo + hi) / 2;
      if (mid >= 0 && mid <= 100) return mid / 100;
    }
  }
  const single = text.match(/(\d{1,3})\s*%/);
  if (single) {
    const n = parseInt(single[1], 10);
    if (Number.isFinite(n) && n >= 0 && n <= 100) return n / 100;
  }
  return null;
}

/** Build the role_opinion payload from a role name + raw opinion text. */
export function buildRoleOpinionPayload(
  role: { id?: string; name: string },
  opinion: string,
): ConsiliumRoleOpinionPayload {
  return {
    role_id: role.id ?? role.name,
    role: role.name,
    opinion: summariseOpinion(opinion),
    position: classifyRolePosition(opinion),
    confidence: extractConfidenceHint(opinion),
    key_citation: findKeyCitation(opinion),
  };
}

// ─── Role definitions ────────────────────────────────────────────────────────

export interface ConsiliumRole {
  name: string;
  model: string;
  maxTokens: number;
  /** Role focus / specialised body. For legacy roles this is a 1-2 sentence
   *  focus line. For v2.2 compiled roles this is the full pre-built prompt
   *  body (statute shortlist + pitfalls + memory + reasoning pattern). The
   *  runner concatenates this to the base lawyer persona. */
  focus: string;
  /** True for roles compiled from the v2.2 router. Suppresses the legacy
   *  "Ты выступаешь в роли: …" preamble that's redundant for the new style. */
  isCompiled?: boolean;
}

/** Adapter from the v2.2 CompiledRole shape to the runner's ConsiliumRole. */
export function compiledToConsiliumRole(c: CompiledRole): ConsiliumRole {
  return {
    name: c.name,
    model: c.model,
    maxTokens: c.maxTokens,
    focus: c.systemBody,
    isCompiled: true,
  };
}

export const ROLES: ReadonlyArray<ConsiliumRole> = [
  {
    name: "Процессуалист",
    model: MODEL_SONNET,
    maxTokens: 600,
    focus:
      "Процессуальные вопросы: сроки, подсудность, форма подачи, процессуальные нарушения. " +
      "Только установленные факты — никакой спекуляции. Если срок пропущен — скажи прямо.",
  },
  {
    name: "Материальный юрист",
    model: MODEL_SONNET,
    maxTokens: 700,
    focus:
      "Материальное право: нормы, судебная практика, EU директивы, [[ref:slug:para]] маркеры. " +
      "Назови ОДНУ самую сильную норму и ОДНУ самую слабую точку правовой позиции клиента.",
  },
  {
    name: "Реалист",
    model: MODEL_SONNET,
    maxTokens: 500,
    focus:
      "Ты единственный кто говорит правду о шансах. НИКОГДА не ободряй без оснований. " +
      "ОБЯЗАТЕЛЬНО дай числовой диапазон вероятности (например: 15–25%). " +
      "Сначала базовый процент для таких дел в целом, потом корректировка под факты этого дела. " +
      "Если шанс ниже 25% — скажи прямо: 'Это слабый путь. Наиболее вероятный исход: [X].' " +
      "Запрещено: 'сильное дело' без цифр, диапазон уже 10 процентных пунктов, 'зависит от обстоятельств' без цифр.",
  },
  {
    name: "Поисковик альтернатив",
    model: MODEL_SONNET,
    maxTokens: 600,
    focus:
      "Ты активируешься когда основной путь закрыт или слабый (< 25%). " +
      "Найди минимум 2 альтернативных пути которые клиент не рассматривал: " +
      "параллельные административные треки, обходные механизмы, компенсационные пути, временные меры. " +
      "Для каждого: название, механизм, вероятность (%), усилие (низкое/среднее/высокое), первый шаг. " +
      "Если основной путь жизнеспособен — кратко подтверди и добавь 1 дополнительный вариант на случай провала.",
  },
  {
    name: "Risk Auditor",
    model: MODEL_HAIKU,
    maxTokens: 300,
    focus:
      "Только слабые места и что упущено. Без повторения других мнений. " +
      "Если аргумент уже признан нежизнеспособным — не пересматривай его как новый. " +
      "Укажи ОДНО самое критическое упущение которое меняет всю картину.",
  },
  {
    name: "Дедлайн-стратег",
    model: MODEL_SONNET,
    maxTokens: 500,
    focus:
      "Ты единственный кто думает о времени. Для любого финального дедлайна: " +
      "построй цепочку назад — какие шаги нужны до него, сколько времени каждый занимает реально (не оптимистично). " +
      "Назови самую раннюю дату когда надо начать каждый шаг. " +
      "Если сегодня уже поздно начинать какой-то шаг — скажи прямо: 'Шаг X уже невозможно успеть'. " +
      "Если дедлайн неизвестен — запроси его явно.",
  },
];

// ─── Synthesis system prompt ─────────────────────────────────────────────────

const SYNTHESIS_SYSTEM_PROMPT = `Ты председатель юридического консилиума. Синтезируй мнения пяти специалистов в единый ответ клиенту.

СТРУКТУРА ОТВЕТА (строго):

**[Прямой ответ — 2–4 предложения]**
Ответь на вопрос сразу. Включи диапазон вероятности если вопрос о шансах (например: "Реалистичный шанс: 15–25%"). Никогда не пропускай вероятность если вопрос о перспективах.

**[Анализ консилиума]**
Назови 2–3 ключевых довода — один сильный, один слабый. Если специалисты ПРОТИВОРЕЧАТ друг другу — назови противоречие явно, не сглаживай.

**[Альтернативные пути]** (только если основной путь слабый < 25% или закрыт)
Список из 2–3 альтернатив с вероятностью каждой.

**[Конкретные шаги]**
Нумерованный список: кто делает, что, до какой даты.

## Следующие шаги (ОБЯЗАТЕЛЬНО)
В конце синтеза добавь раздел "## Следующие шаги" с 1-3 конкретными действиями.
Каждое действие: "[ ] ЧТО СДЕЛАТЬ — до ДАТЫ (или ASAP)"
Конкретно: какой документ, в какой орган, до какой даты.
НЕ писать: "проконсультируйтесь с юристом" — это не действие.
Пропустить раздел только для чисто теоретических вопросов без действий.

## Временная цепочка (если есть финальный дедлайн)
Если Дедлайн-стратег выявил цепочку — включи её в синтез как отдельный раздел:
"## Временной план"
Формат: обратный отсчёт от финального дедлайна к сегодня.

## Непроверенные предположения
Если синтез основан на факте который пользователь НЕ подтвердил явно —
добавь в конце раздел "⚠️ Предположения этого анализа:" с 1-2 пунктами.
Формат: "• Предполагается [факт] — если это не так, [что меняется в выводе]"
Пропустить если все ключевые факты подтверждены.

ЖЁСТКИЕ ПРАВИЛА:
- Сохрани [[ref:slug:para]] маркеры из мнений специалистов
- Не повторяй структуру консилиума — единый советник с чёткой позицией
- Если ситуация опасная — скажи прямо, без смягчений
- Если Реалист дал < 25% — начни с: "Основной путь слабый. Вот что реально работает:"
- Запрещено: "у вас сильное дело" без цифр, общие ободрения без конкретики`;

// ─── Routing classifier prompt ───────────────────────────────────────────────

const CLASSIFIER_SYSTEM = `Ты классификатор запросов для юридического ИИ-ассистента.
Прочитай сообщение пользователя и реши: нужен ли полный юридический консилиум (4 специалиста)?

Консилиум нужен (consilium=true) для:
- Судебные сроки, дедлайны и последствия их нарушения
- Процессуальные вопросы (что подать, куда, в какой форме)
- "Что мне делать?" при сложной правовой ситуации
- Анализ с нескольких углов: материальное право + тактика + риски
- Угроза депортации, уголовного преследования, значимые имущественные споры

Консилиум НЕ нужен (consilium=false) для:
- Простые справочные вопросы (что означает термин X)
- Загрузка или обработка документа
- Приветствия и общие вопросы
- Подтверждения ("да", "спасибо", "понял")
- Запросы статуса ("как идёт моё дело?")

Ответь ТОЛЬКО валидным JSON без объяснений:
{"consilium": true}
или
{"consilium": false}`;

// ─── Calibration base rates (injected into every role) ───────────────────────
// Anchors probability estimates to real-world outcomes, not case-specific optimism.

export const CALIBRATION_BLOCK = `
## БАЗОВЫЕ ВЕРОЯТНОСТИ (используй как отправную точку для оценок)
- KHO valituslupa (право на обжалование): ~15–20% заявок
- Восстановление пропущенного срока (menetetyn määräajan palauttaminen): ~10–15%
- Приёмлемость жалобы в ЕСПЧ: ~5–8% заявок
- Административное обжалование депортации при доказанных процессуальных нарушениях: ~25–35%
- Компенсация жертве через уголовный процесс при обвинительном приговоре: ~60–70%
- Административная поправка при явной ошибке (неверное гражданство, имя): ~30–40%
Корректируй эти базовые ставки на конкретные факты дела — в обе стороны.
`.trim();

// ─── Dead-end detector ────────────────────────────────────────────────────────

/** Checks if any role opinion signals a dead end (probability < 20% or closed path).
 *  If detected, the Поисковик альтернатив role is forced to activate. */
export function hasDeadEnd(opinions: Array<{ name: string; opinion: string }>): boolean {
  const realistOpinion = opinions.find((o) => o.name === "Реалист")?.opinion ?? "";
  // Look for explicit low probability signals
  const lowProbMatch = realistOpinion.match(/(\d+)\s*[–—-]\s*(\d+)\s*%/);
  if (lowProbMatch) {
    const high = parseInt(lowProbMatch[2], 10);
    if (high <= 25) return true;
  }
  // Look for explicit dead-end language
  const deadEndPhrases = [
    "путь закрыт", "срок пропущен", "невозможно", "слабый путь",
    "path closed", "deadline missed", "not viable", "too late",
  ];
  const allText = opinions.map((o) => o.opinion).join(" ").toLowerCase();
  return deadEndPhrases.some((phrase) => allText.includes(phrase));
}

// ─── Internal helpers ─────────────────────────────────────────────────────────

export function buildAnthropicHeaders(apiKey: string): Record<string, string> {
  return {
    "Content-Type": "application/json",
    "x-api-key": apiKey,
    "anthropic-version": "2023-06-01",
  };
}

/** Call Anthropic non-streaming and return the full text response.
 *
 * COST OPTIMISATION (2026-05-27) — when `cacheSystem` is true, the `system`
 * block is sent as a content array with `cache_control: ephemeral` so the
 * Anthropic prompt-cache covers all parallel lawyer roles that share the
 * same base prompt + RAG context. Cost audit found this was the single
 * biggest leak: 7 lawyers × 15 KB context = 105 KB re-billed per consilium
 * run; with caching, only the first call inside the 5-min TTL window pays
 * full price, the rest get the 90% discount on cache hits.
 *
 * Default is `cacheSystem=true` because every current caller benefits
 * (consilium parallel fan-out is the dominant cost path). Callers passing
 * a unique system prompt per-call should pass `cacheSystem=false` so we
 * don't churn the cache.
 */
export async function callAnthropicBlocking(opts: {
  model: string;
  system: string;
  userMessage: string;
  maxTokens: number;
  apiKey: string;
  cacheSystem?: boolean;
}): Promise<string> {
  const cacheSystem = opts.cacheSystem ?? true;
  // Only worth caching when the system block is ≥ 1024 tokens (Anthropic
  // requires a minimum prefix for cache eligibility). Use 4_000 chars as
  // a conservative proxy for the 1024-token floor.
  const eligibleForCache = cacheSystem && opts.system.length >= 4_000;

  const systemPayload: string | Array<Record<string, unknown>> =
    eligibleForCache
      ? [{
        type: "text",
        text: opts.system,
        cache_control: { type: "ephemeral" },
      }]
      : opts.system;

  const res = await fetch(ANTHROPIC_URL, {
    method: "POST",
    headers: buildAnthropicHeaders(opts.apiKey),
    body: JSON.stringify(scrubAnthropicBody({
      model: opts.model,
      max_tokens: opts.maxTokens,
      system: systemPayload,
      messages: [{ role: "user", content: opts.userMessage }],
    })),
    signal: AbortSignal.timeout(ANTHROPIC_FETCH_TIMEOUT_MS),
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(
      `Anthropic ${res.status} (${opts.model}): ${errText.slice(0, 200)}`,
    );
  }

  const json = await res.json() as {
    content?: Array<{ type: string; text?: string }>;
  };

  return (json.content ?? [])
    .filter((b) => b.type === "text" && typeof b.text === "string")
    .map((b) => b.text!)
    .join("");
}

/** Run a single role non-streaming. Returns the role opinion text.
 *  Catches all errors and returns the unavailable sentinel instead. */
export async function runRole(
  role: ConsiliumRole,
  userMessage: string,
  baseSystemPrompt: string,
  ragContext: string,
  caseContext: string,
  apiKey: string,
): Promise<{ name: string; opinion: string }> {
  const contextParts: string[] = [baseSystemPrompt];

  if (caseContext.trim()) {
    contextParts.push(
      `\n\n<case_context>\n${sealContext("case_context", caseContext)}\n</case_context>`,
    );
  }

  if (ragContext.trim()) {
    contextParts.push(
      `\n\n<law_context>\n${sealContext("law_context", ragContext)}\n</law_context>`,
    );
  }

  if (role.isCompiled) {
    // v2.2 compiled roles ship a self-contained body that already includes
    // statute shortlist, pitfalls, memory, and reasoning pattern. Append the
    // calibration block + token cap reminder.
    contextParts.push(
      `\n\n${CALIBRATION_BLOCK}\n\n${role.focus}\n\n` +
        `Максимальная длина ответа: ${role.maxTokens} токенов. ` +
        `Будь конкретен, лаконичен. Отвечай строго в рамках своей роли.`,
    );
  } else {
    contextParts.push(
      `\n\n${CALIBRATION_BLOCK}\n\n` +
      `Ты выступаешь в роли: ${role.name}.\nТвоя задача: ${role.focus}\n` +
        `Максимальная длина ответа: ${role.maxTokens} токенов. ` +
        `Будь конкретен, лаконичен. Отвечай строго в рамках своей роли.`,
    );
  }

  const system = contextParts.join("");

  try {
    const opinion = await callAnthropicBlocking({
      model: role.model,
      system,
      userMessage,
      maxTokens: role.maxTokens,
      apiKey,
    });
    return { name: role.name, opinion: opinion.trim() || "[роль недоступна]" };
  } catch (e) {
    console.warn(
      `consilium: role "${role.name}" failed: ${String(e).slice(0, 200)}`,
    );
    return { name: role.name, opinion: "[роль недоступна]" };
  }
}

/** Build the synthesis user message from role opinions. */
function buildSynthesisUserMessage(
  originalQuestion: string,
  opinions: Array<{ name: string; opinion: string }>,
  deadEnd: boolean,
): string {
  const lines: string[] = [
    `Вопрос клиента: ${originalQuestion}`,
    "",
    "Мнения специалистов консилиума:",
    "",
  ];

  for (const { name, opinion } of opinions) {
    lines.push(`### ${name}`);
    lines.push(opinion);
    lines.push("");
  }

  if (deadEnd) {
    lines.push(
      "⚠️ DEAD-END DETECTED: Реалист оценил вероятность ниже 25% или путь закрыт. " +
      "ОБЯЗАТЕЛЬНО начни ответ с: 'Основной путь слабый.' и сразу дай альтернативы.",
    );
    lines.push("");
  }

  lines.push(
    "Синтезируй единый ответ клиенту от первого лица единственного числа. " +
    "Следуй структуре из системного промпта строго.",
  );

  return lines.join("\n");
}

// ─── Public API ───────────────────────────────────────────────────────────────

/** Determine whether the user message warrants a full consilium run.
 *  Uses Haiku for speed and low cost (classifier is a cheap binary call).
 *  Returns false on any error so the caller falls back to single-pass. */
export async function shouldRunConsilium(
  message: string,
  anthropicApiKey: string,
): Promise<boolean> {
  try {
    const text = await callAnthropicBlocking({
      model: MODEL_HAIKU,
      system: CLASSIFIER_SYSTEM,
      userMessage: message,
      maxTokens: 20,
      apiKey: anthropicApiKey,
    });

    // Accept either pure JSON or JSON embedded in surrounding text.
    const jsonMatch = text.match(/\{[\s\S]*?\}/);
    if (!jsonMatch) return false;

    const parsed = JSON.parse(jsonMatch[0]) as { consilium?: unknown };
    return parsed.consilium === true;
  } catch (e) {
    console.warn(
      `consilium: classifier failed (defaulting false): ${
        String(e).slice(0, 200)
      }`,
    );
    return false;
  }
}

/** Run the full N-role consilium and stream synthesis via onEvent.
 *  NEVER throws — all errors are caught internally.
 *
 * v2.2 behaviour:
 *   • If `caseClassification` is provided AND the router finds at least one
 *     applicable DomainExpert, the new 4-6 role roster is used.
 *   • Otherwise the legacy 6 generic roles run (full backward compat).
 *
 * @param params.userMessage         The user's legal question.
 * @param params.systemPrompt        Base system prompt (the capable lawyer persona).
 * @param params.ragContext          Law chunks injected from law-search.
 * @param params.caseContext         Active case memory text (Pkg 1).
 * @param params.anthropicApiKey     API key for Anthropic.
 * @param params.onEvent             Callback for each SSE event.
 * @param params.caseClassification  Optional structured case context for the
 *                                   v2.2 router (case type, jurisdiction, …).
 * @param params.memoryReader        Optional custom memory reader (tests).
 * @returns Full synthesis text (same text emitted via delta events).
 */
export async function runConsilium(params: {
  userMessage: string;
  systemPrompt: string;
  ragContext: string;
  caseContext: string;
  anthropicApiKey: string;
  onEvent: (event: ConsiliumSSEEvent) => void;
  caseClassification?: CaseContext;
  memoryReader?: MemoryReader;
  /** Phase 1 (2026-05-25): if the caller has already selected a roster (e.g.
   *  via the lawyer-department bridge), pass it here and the internal v2.2
   *  router is skipped. Empty array falls back to legacy ROLES. */
  overrideRoles?: ReadonlyArray<ConsiliumRole>;
  /** Phase 1: matching roster ids for the consilium_start event, when
   *  overrideRoles was sourced from a router that has stable ids. */
  overrideRoleIds?: ReadonlyArray<string>;
}): Promise<string> {
  const {
    userMessage,
    systemPrompt,
    ragContext,
    caseContext,
    anthropicApiKey,
    onEvent,
    caseClassification,
    memoryReader,
    overrideRoles,
    overrideRoleIds,
  } = params;

  // ── 1. Decide which role roster to run ──────────────────────────────────
  // Priority order:
  //   (0) overrideRoles (caller-supplied, e.g. lawyer-department bridge)
  //   (1) v2.2 router (caseClassification → DOMAIN/STRATEGIC)
  //   (2) legacy ROLES (6 generic roles)
  let activeRoles: ConsiliumRole[] = [...ROLES];
  let usedV22Router = false;
  let usedOverride = false;

  if (overrideRoles && overrideRoles.length > 0) {
    activeRoles = [...overrideRoles];
    usedOverride = true;
  }

  if (!usedOverride && caseClassification) {
    try {
      const selection = selectConsiliumRoles(caseClassification);
      if (selection.hasDomainMatch) {
        const reader = memoryReader ?? new DenoMemoryReader(resolveDefaultMemoryDir());
        const compiled = await compileRoles({
          selection,
          ctx: caseClassification,
          memoryReader: reader,
        });
        activeRoles = compiled.map(compiledToConsiliumRole);
        usedV22Router = true;
      }
    } catch (e) {
      console.warn(
        `consilium: v2.2 router failed, falling back to legacy: ${String(e).slice(0, 200)}`,
      );
      activeRoles = [...ROLES];
    }
  }

  // ── 2. Announce start ───────────────────────────────────────────────────
  // Emit BOTH the legacy `roles: string[]` field (older Flutter clients) AND
  // the new `roster` array of {id,name} pairs (timeline UI). When the caller
  // provided overrideRoleIds (lawyer-department bridge) we use those real
  // ids; otherwise fall back to display name as id.
  const rosterIds: string[] = (usedOverride && overrideRoleIds &&
      overrideRoleIds.length === activeRoles.length)
    ? [...overrideRoleIds]
    : activeRoles.map((r) => r.name);
  const roster = activeRoles.map((r, i) => ({
    id: rosterIds[i] ?? r.name,
    name: r.name,
  }));
  const roleIdByName = new Map<string, string>();
  roster.forEach((r) => roleIdByName.set(r.name, r.id));

  onEvent({
    type: "consilium_start",
    roles: activeRoles.map((r) => r.name),
    roster,
    total: activeRoles.length,
  });

  // ── 3. Run all roles in parallel ────────────────────────────────────────
  // Each role resolves independently; Promise.all() waits for all before
  // synthesis. Failures are caught INSIDE runRole — they return the sentinel.
  //
  // We want to emit role_done as each role completes, not in fixed order,
  // so we wrap each promise to call onEvent immediately on settle. Right
  // after role_done we also emit role_opinion carrying the structured
  // payload the timeline UI consumes (forward-compatible — older clients
  // ignore unknown event types).
  const rolePromises = activeRoles.map((role) => {
    const p = runRole(
      role,
      userMessage,
      systemPrompt,
      ragContext,
      caseContext,
      anthropicApiKey,
    );
    return p.then((result) => {
      onEvent({ type: "role_done", role: result.name });
      // FLAT wire shape — fields top-level on the SSE frame (not nested under
      // `payload`). Matches the Flutter parser at claude_service.dart which
      // reads parsed['role_id'], parsed['role_name'], parsed['opinion'], etc.
      const built = buildRoleOpinionPayload(
        { id: roleIdByName.get(result.name) ?? result.name, name: result.name },
        result.opinion,
      );
      onEvent({
        type: "role_opinion",
        role_id: built.role_id,
        role_name: built.role,
        opinion: built.opinion,
        position: built.position,
        confidence: built.confidence,
        key_citation: built.key_citation,
      });
      return result;
    });
  });

  // Wait for all roles. Because runRole never throws, Promise.all cannot
  // reject here. TypeScript doesn't know that, so we wrap defensively.
  let opinions: Array<{ name: string; opinion: string }>;
  try {
    opinions = await Promise.all(rolePromises);
  } catch (e) {
    // Should never happen — belt-and-suspenders.
    console.error(
      `consilium: unexpected error in Promise.all: ${String(e).slice(0, 200)}`,
    );
    opinions = activeRoles.map((r) => ({ name: r.name, opinion: "[роль недоступна]" }));
  }
  void usedV22Router; // reserved for future telemetry

  // ── 3. Synthesise — streaming ────────────────────────────────────────────
  onEvent({ type: "synthesis_start" });

  const deadEnd = hasDeadEnd(opinions);
  const synthesisUserMessage = buildSynthesisUserMessage(userMessage, opinions, deadEnd);

  // Build synthesis system: embed case/rag context so the chairman has the
  // same grounding as the specialists.
  const synthesisContextParts: string[] = [SYNTHESIS_SYSTEM_PROMPT];
  if (caseContext.trim()) {
    synthesisContextParts.push(
      `\n\n<case_context>\n${sealContext("case_context", caseContext)}\n</case_context>`,
    );
  }
  if (ragContext.trim()) {
    synthesisContextParts.push(
      `\n\n<law_context>\n${sealContext("law_context", ragContext)}\n</law_context>`,
    );
  }
  const synthesisSystem = synthesisContextParts.join("");

  let fullSynthesis = "";

  try {
    const streamRes = await fetch(ANTHROPIC_URL, {
      method: "POST",
      headers: buildAnthropicHeaders(anthropicApiKey),
      body: JSON.stringify(scrubAnthropicBody({
        model: MODEL_SONNET,
        max_tokens: 2048,
        stream: true,
        system: synthesisSystem,
        messages: [{ role: "user", content: synthesisUserMessage }],
      })),
      signal: AbortSignal.timeout(ANTHROPIC_FETCH_TIMEOUT_MS),
    });

    if (!streamRes.ok || streamRes.body === null) {
      // Non-streaming fallback if stream response is broken.
      const errText = await streamRes.text().catch(() => "(unreadable)");
      console.warn(
        `consilium: synthesis stream failed (${streamRes.status}), ` +
          `falling back to blocking call: ${errText.slice(0, 200)}`,
      );
      throw new Error(`stream response ${streamRes.status}`);
    }

    // Read SSE stream from Anthropic and re-emit delta events.
    const reader = streamRes.body.getReader();
    const decoder = new TextDecoder();
    let buffer = "";

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      buffer += decoder.decode(value, { stream: true });

      // Process complete SSE lines from the buffer.
      const lines = buffer.split("\n");
      // Keep the last (potentially incomplete) line in the buffer.
      buffer = lines.pop() ?? "";

      for (const line of lines) {
        const trimmed = line.trim();
        if (!trimmed.startsWith("data:")) continue;

        const dataStr = trimmed.slice(5).trim();
        if (dataStr === "[DONE]") break;

        let event: Record<string, unknown>;
        try {
          event = JSON.parse(dataStr) as Record<string, unknown>;
        } catch {
          continue; // Malformed SSE data — skip.
        }

        // Anthropic streaming event types we care about:
        //   content_block_delta → { delta: { type: "text_delta", text: "..." } }
        if (event.type === "content_block_delta") {
          const delta = event.delta as Record<string, unknown> | undefined;
          if (delta?.type === "text_delta" && typeof delta.text === "string") {
            const chunk = delta.text;
            fullSynthesis += chunk;
            onEvent({ type: "delta", text: chunk });
          }
        }
      }
    }
  } catch (streamError) {
    // Streaming failed — attempt blocking fallback so the user gets an answer.
    console.warn(
      `consilium: streaming synthesis failed, attempting blocking fallback: ${
        String(streamError).slice(0, 200)
      }`,
    );
    try {
      fullSynthesis = await callAnthropicBlocking({
        model: MODEL_SONNET,
        system: synthesisSystem,
        userMessage: synthesisUserMessage,
        maxTokens: 2048,
        apiKey: anthropicApiKey,
      });
      // Emit the full text as a single delta so the caller's SSE pipe still
      // delivers content.
      if (fullSynthesis) {
        onEvent({ type: "delta", text: fullSynthesis });
      }
    } catch (fallbackError) {
      console.error(
        `consilium: blocking fallback also failed: ${
          String(fallbackError).slice(0, 200)
        }`,
      );
      const errorText =
        "Консилиум временно недоступен. Пожалуйста, повторите запрос.";
      fullSynthesis = errorText;
      onEvent({ type: "delta", text: errorText });
    }
  }

  // ── 4. Signal completion ─────────────────────────────────────────────────
  onEvent({ type: "done" });

  return fullSynthesis;
}

// ─── v2.2 re-exports for callers that prefer a single import surface ─────────

export {
  type CaseContext,
  type CompiledRole,
  compileRoles,
  DenoMemoryReader,
  DOMAIN_EXPERTS,
  getDomainExpert,
  getStrategicPosition,
  type MemoryReader,
  type RoleSelection,
  selectConsiliumRoles,
  STRATEGIC_POSITIONS,
  StubMemoryReader,
} from "./consilium_roles/index.ts";
