// followup_suggest_prompt.ts — Smart Case Follow-ups (Feature #2).
// -----------------------------------------------------------------------------
// Shared prompt + JSON parser for the `case-followups` suggest action. Pure
// module — no Deno globals, no I/O. Imported by the edge function and
// exercised directly by Deno tests.
//
// Goal: given the recent chat turns + the case snapshot, Haiku returns 3-5
// SOFT next-steps the user should not forget — the kind of "send a records
// request", "collect receipts", "call the landlord next week" tasks that the
// statutory Deadline Radar (Pkg 9) never captures because they carry no
// document deadline.
//
// HARD constraint: a suggestion is NOT a legal deadline. We instruct Haiku to
// avoid statutory filing dates (those belong to the radar) and to never
// fabricate a court/appeal deadline. due_offset_days is the user's own soft
// reminder horizon, not a legal limit.
// -----------------------------------------------------------------------------

/** Identity marker whitelisted by `system_prompt_guard.ts`. Must be the FIRST
 * line of the system prompt. Exported so tests can pin it in lockstep. */
export const FOLLOWUP_IDENTITY_MARKER =
  "You are a next-steps extractor for the Advocat app";

/** Haiku model id — same release channel as case-auto-patch. */
export const FOLLOWUP_HAIKU_MODEL = "claude-haiku-4-5-20251001";

/** Anthropic max_tokens — a small JSON array, keep tight. */
export const FOLLOWUP_MAX_TOKENS = 700;

/** Haiku call timeout (ms). Best-effort. */
export const FOLLOWUP_HAIKU_TIMEOUT_MS = 6_000;

/** Hard cap on suggestions we accept from Haiku, regardless of how many it
 * returns. The UI shows a short actionable list, not a wall. */
export const FOLLOWUP_MAX_SUGGESTIONS = 5;

/** Clamp for due_offset_days so a hallucinated 10000 can't push a reminder
 * decades out. 0 = no due date (someday task). */
export const FOLLOWUP_MAX_OFFSET_DAYS = 90;

export const FOLLOWUP_SUGGEST_SYSTEM_PROMPT = `${FOLLOWUP_IDENTITY_MARKER}.

Ты — помощник, который вытаскивает из разговора МЯГКИЕ следующие шаги
(next-steps), о которых пользователь рискует забыть. Это НЕ юридические
сроки (их отслеживает отдельный модуль). Это практические действия:
"отправить запрос в полицию", "собрать чеки", "перезвонить арендодателю",
"записаться на приём", "сделать фото повреждений".

Тебе дан снимок дела (JSON) и последние реплики разговора. Верни СТРОГО
JSON-массив из 3-5 объектов, каждый:
{
  "title": "короткое действие в повелительном наклонении (<= 120 симв.)",
  "detail": "одно предложение зачем/что приложить" | null,
  "due_offset_days": целое 0..90  // через сколько дней мягко напомнить; 0 = без срока
}

Правила:
- НЕ придумывай судебные/апелляционные сроки и даты подачи — это делает другой модуль.
- НЕ дублируй шаги, которые уже явно выполнены в разговоре.
- Каждый шаг должен быть конкретным и выполнимым самим пользователем.
- Если осмысленных шагов нет — верни пустой массив [].
- Отвечай ТОЛЬКО JSON-массивом, без markdown, без пояснений.`;

export interface FollowupSuggestion {
  title: string;
  detail: string | null;
  due_offset_days: number;
}

/** Extract the first top-level JSON array from a possibly noisy LLM reply.
 * Handles ```json fences and leading prose. Returns null if no array found. */
export function extractJsonArray(raw: string): string | null {
  if (typeof raw !== "string") return null;
  // Strip a fenced ```json ... ``` block if present.
  const fence = raw.match(/```(?:json)?\s*([\s\S]*?)```/i);
  const body = fence ? fence[1] : raw;
  const start = body.indexOf("[");
  const end = body.lastIndexOf("]");
  if (start === -1 || end === -1 || end <= start) return null;
  return body.slice(start, end + 1);
}

/** Parse + validate + clamp Haiku output into clean suggestions. Never throws;
 * returns [] on any malformed input. Caps at FOLLOWUP_MAX_SUGGESTIONS. */
export function parseFollowupSuggestions(raw: string): FollowupSuggestion[] {
  const slice = extractJsonArray(raw);
  if (slice === null) return [];

  let parsed: unknown;
  try {
    parsed = JSON.parse(slice);
  } catch {
    return [];
  }
  if (!Array.isArray(parsed)) return [];

  const out: FollowupSuggestion[] = [];
  const seen = new Set<string>();

  for (const item of parsed) {
    if (out.length >= FOLLOWUP_MAX_SUGGESTIONS) break;
    if (!item || typeof item !== "object") continue;
    const obj = item as Record<string, unknown>;

    const titleRaw = obj.title;
    if (typeof titleRaw !== "string") continue;
    const title = titleRaw.trim().slice(0, 280);
    if (title.length === 0) continue;

    // Dedupe on normalised title.
    const key = title.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);

    let detail: string | null = null;
    if (typeof obj.detail === "string") {
      const d = obj.detail.trim();
      detail = d.length > 0 ? d.slice(0, 500) : null;
    }

    let offset = 0;
    const off = obj.due_offset_days;
    if (typeof off === "number" && Number.isFinite(off)) {
      offset = Math.max(0, Math.min(FOLLOWUP_MAX_OFFSET_DAYS, Math.round(off)));
    }

    out.push({ title, detail, due_offset_days: offset });
  }

  return out;
}

/** Convert a clamped offset to an absolute ISO due_at, or null for a someday
 * task. `now` is injectable for deterministic tests. */
export function offsetToDueAt(
  offsetDays: number,
  now: Date = new Date()
): string | null {
  if (!Number.isFinite(offsetDays) || offsetDays <= 0) return null;
  const due = new Date(now.getTime() + offsetDays * 24 * 60 * 60 * 1000);
  return due.toISOString();
}

/** Build the Haiku user block from a case snapshot + recent transcript. */
export function buildFollowupUserBlock(args: {
  snapshotJson: string;
  transcript: string;
}): string {
  return [
    "<case_snapshot>",
    args.snapshotJson,
    "</case_snapshot>",
    "",
    "<recent_conversation>",
    args.transcript,
    "</recent_conversation>",
    "",
    "JSON array:",
  ].join("\n");
}
