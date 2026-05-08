// consilium.ts — Phase 2 multi-role legal consilium orchestrator.
// -----------------------------------------------------------------------------
// Pure-ish module — no Deno globals beyond `fetch`. Imported by
//   • supabase/functions/claude-proxy/index.ts (when consilium routing fires)
//   • Deno tests for the consilium contract
//
// What it does:
//   Runs 4 specialised legal-AI roles in PARALLEL (Promise.all), then
//   streams a Sonnet-synthesised answer via an onEvent callback. The caller
//   converts onEvent calls into SSE frames and pipes them to the HTTP response.
//
// Roles (all non-blocking, parallel):
//   • Процессуалист   — procedural questions, deadlines, jurisdiction, form
//   • Материальный юрист — substantive law, EU directives, [[ref:slug:para]] markers
//   • Тактик          — step-by-step tactics, what to say / not say
//   • Risk Auditor    — weak spots and omissions only; no duplication
//
// Routing: shouldRunConsilium() uses Haiku to classify the user message.
// The caller should invoke it BEFORE deciding to call runConsilium().
//
// SSE event sequence (emitted via onEvent):
//   consilium_start → role_done × 4 (order depends on completion) →
//   synthesis_start → delta × N → done
//
// Error handling: per-role try/catch; a failed role passes "[роль недоступна]"
// to synthesis. runConsilium() itself NEVER throws.
// -----------------------------------------------------------------------------

const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";

// Model IDs — pinned; update here if rotated.
const MODEL_SONNET = "claude-sonnet-4-6";
const MODEL_HAIKU = "claude-haiku-4-5-20251001";

// ─── SSE event types ─────────────────────────────────────────────────────────

export type ConsiliumSSEEvent =
  | { type: "consilium_start"; roles: string[] }
  | { type: "role_done"; role: string }
  | { type: "synthesis_start" }
  | { type: "delta"; text: string }
  | { type: "done" };

// ─── Role definitions ────────────────────────────────────────────────────────

interface ConsiliumRole {
  name: string;
  model: string;
  maxTokens: number;
  focus: string;
}

const ROLES: ReadonlyArray<ConsiliumRole> = [
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

const CALIBRATION_BLOCK = `
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
function hasDeadEnd(opinions: Array<{ name: string; opinion: string }>): boolean {
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

function buildAnthropicHeaders(apiKey: string): Record<string, string> {
  return {
    "Content-Type": "application/json",
    "x-api-key": apiKey,
    "anthropic-version": "2023-06-01",
  };
}

/** Call Anthropic non-streaming and return the full text response. */
async function callAnthropicBlocking(opts: {
  model: string;
  system: string;
  userMessage: string;
  maxTokens: number;
  apiKey: string;
}): Promise<string> {
  const res = await fetch(ANTHROPIC_URL, {
    method: "POST",
    headers: buildAnthropicHeaders(opts.apiKey),
    body: JSON.stringify({
      model: opts.model,
      max_tokens: opts.maxTokens,
      system: opts.system,
      messages: [{ role: "user", content: opts.userMessage }],
    }),
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
async function runRole(
  role: ConsiliumRole,
  userMessage: string,
  baseSystemPrompt: string,
  ragContext: string,
  caseContext: string,
  apiKey: string,
): Promise<{ name: string; opinion: string }> {
  const contextParts: string[] = [baseSystemPrompt];

  if (caseContext.trim()) {
    contextParts.push(`\n\n<case_context>\n${caseContext}\n</case_context>`);
  }

  if (ragContext.trim()) {
    contextParts.push(`\n\n<law_context>\n${ragContext}\n</law_context>`);
  }

  contextParts.push(
    `\n\n${CALIBRATION_BLOCK}\n\n` +
    `Ты выступаешь в роли: ${role.name}.\nТвоя задача: ${role.focus}\n` +
      `Максимальная длина ответа: ${role.maxTokens} токенов. ` +
      `Будь конкретен, лаконичен. Отвечай строго в рамках своей роли.`,
  );

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

/** Run the full 4-role consilium and stream synthesis via onEvent.
 *  NEVER throws — all errors are caught internally.
 *
 * @param params.userMessage      The user's legal question.
 * @param params.systemPrompt     Base system prompt (the capable lawyer persona).
 * @param params.ragContext       Law chunks injected from law-search.
 * @param params.caseContext      Active case memory (Pkg 1).
 * @param params.anthropicApiKey  API key for Anthropic.
 * @param params.onEvent          Callback for each SSE event; called synchronously
 *                                in the order: consilium_start, role_done × 4,
 *                                synthesis_start, delta × N, done.
 * @returns Full synthesis text (same text emitted via delta events).
 */
export async function runConsilium(params: {
  userMessage: string;
  systemPrompt: string;
  ragContext: string;
  caseContext: string;
  anthropicApiKey: string;
  onEvent: (event: ConsiliumSSEEvent) => void;
}): Promise<string> {
  const {
    userMessage,
    systemPrompt,
    ragContext,
    caseContext,
    anthropicApiKey,
    onEvent,
  } = params;

  // ── 1. Announce start ───────────────────────────────────────────────────
  onEvent({
    type: "consilium_start",
    roles: ROLES.map((r) => r.name),
  });

  // ── 2. Run all 4 roles in parallel ──────────────────────────────────────
  // Each role resolves independently; Promise.all() waits for all before
  // synthesis. Failures are caught INSIDE runRole — they return the sentinel.
  //
  // We want to emit role_done as each role completes, not in fixed order,
  // so we wrap each promise to call onEvent immediately on settle.
  const rolePromises = ROLES.map((role) => {
    const p = runRole(
      role,
      userMessage,
      systemPrompt,
      ragContext,
      caseContext,
      anthropicApiKey,
    );
    // Fire role_done as soon as this role finishes, regardless of others.
    return p.then((result) => {
      onEvent({ type: "role_done", role: result.name });
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
    opinions = ROLES.map((r) => ({ name: r.name, opinion: "[роль недоступна]" }));
  }

  // ── 3. Synthesise — streaming ────────────────────────────────────────────
  onEvent({ type: "synthesis_start" });

  const deadEnd = hasDeadEnd(opinions);
  const synthesisUserMessage = buildSynthesisUserMessage(userMessage, opinions, deadEnd);

  // Build synthesis system: embed case/rag context so the chairman has the
  // same grounding as the specialists.
  const synthesisContextParts: string[] = [SYNTHESIS_SYSTEM_PROMPT];
  if (caseContext.trim()) {
    synthesisContextParts.push(
      `\n\n<case_context>\n${caseContext}\n</case_context>`,
    );
  }
  if (ragContext.trim()) {
    synthesisContextParts.push(
      `\n\n<law_context>\n${ragContext}\n</law_context>`,
    );
  }
  const synthesisSystem = synthesisContextParts.join("");

  let fullSynthesis = "";

  try {
    const streamRes = await fetch(ANTHROPIC_URL, {
      method: "POST",
      headers: buildAnthropicHeaders(anthropicApiKey),
      body: JSON.stringify({
        model: MODEL_SONNET,
        max_tokens: 2048,
        stream: true,
        system: synthesisSystem,
        messages: [{ role: "user", content: synthesisUserMessage }],
      }),
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
