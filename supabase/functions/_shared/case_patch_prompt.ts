// case_patch_prompt.ts — Pkg 1.C of Case Memory rebuild.
// -----------------------------------------------------------------------------
// Shared prompt + JSON-schema parser for the background `case-auto-patch`
// Edge Function. Pure module — no Deno globals, no I/O. Imported by the
// edge function and exercised directly by Deno tests.
//
// Spec (memory: project_handoff_smart_lawyer.md "Авто-обновление дела"):
//   * Haiku 4.5 reads the current case snapshot + last user msg + AI reply.
//   * Extracts ONLY new facts. Returns strict JSON.
//   * Append-only fields: case_numbers, parties, authorities, key_dates,
//     timeline. Replace-or-keep: open_questions, next_actions, summary.
//   * Identity marker `You are a case-fact extractor for the Advocat app`
//     so the system_prompt_guard whitelist accepts it.
//
// Phase 2 Pkg 5 (2026-05-06): patch shape additionally carries an optional
// `phase_transition` field — Haiku flags clear strategy/draft/wait
// transitions. See `_shared/case_phase.ts` for the parser + rule.
// -----------------------------------------------------------------------------

/** Identity marker whitelisted by `system_prompt_guard.ts`. Must appear as
 * the FIRST line of the system prompt below. Exported so tests can pin it
 * in lockstep with the guard's whitelist. */
export const CASE_PATCH_IDENTITY_MARKER =
  "You are a case-fact extractor for the Advocat app";

/** Haiku model id. Cheap, fast, structured. Pinned to the same release
 * channel claude-proxy uses. */
export const CASE_PATCH_HAIKU_MODEL = "claude-haiku-4-5-20251001";

/** Anthropic max_tokens — small JSON payload, keep tight. */
export const CASE_PATCH_MAX_TOKENS = 800;

/** Haiku call timeout (ms). Best-effort: a 5s ceiling caps the worst-case
 * delay before we give up entirely. */
export const CASE_PATCH_HAIKU_TIMEOUT_MS = 5_000;

/** System prompt fed to Haiku. Russian to match user language; output is
 * strict JSON regardless of the language the chat itself ran in. */
export const CASE_PATCH_SYSTEM_PROMPT = `${CASE_PATCH_IDENTITY_MARKER}.

Ты — извлекатель фактов для досье юридического дела. Тебе дан:
1. Текущий снимок дела (JSON)
2. Последнее сообщение пользователя
3. Последний ответ AI-юриста

Извлеки ТОЛЬКО НОВЫЕ факты, которых ещё нет в снимке: новые номера дел, новые контакты, новые даты, новые open_questions, изменённый next_actions список, обновлённый summary.

Дополнительно ОПРЕДЕЛИ, перешёл ли разговор в новую фазу работы по делу:
- "strategy" — пользователь готов обсуждать стратегию (есть номер дела + стороны + ключевая дата);
- "draft" — пользователь явно согласился на подготовку документа ("да, составь", "yes, draft it", "jah, koosta");
- "wait" — пользователь сообщил, что отправил документ ("отправил", "saatsin", "I sent it").

Верни JSON ровно по схеме:
{
  "case_numbers_add":   [{"authority":"...","number":"...","role":"..."}],
  "parties_add":        [{"name":"...","role":"...","contact":"..."}],
  "authorities_add":    [{"name":"...","type":"...","contact_email":"...","contact_phone":"..."}],
  "key_dates_add":      [{"date":"YYYY-MM-DD","event":"...","source":"..."}],
  "timeline_add":       [{"date":"YYYY-MM-DD","event":"...","source":"..."}],
  "open_questions_replace": ["...","..."] | null,
  "next_actions_replace":   ["...","..."] | null,
  "summary_replace":        "..." | null,
  "phase_transition":       {"to":"strategy"|"draft"|"wait","reason":"<=120 chars"} | null
}

ПРАВИЛА:
- Если ничего нового — все поля пустые/null.
- НЕ выдумывай факты, которых нет в сообщениях.
- НЕ дублируй то, что уже в снимке.
- Даты только в формате YYYY-MM-DD; если только год/месяц — клади null в date и описание в event.
- phase_transition выставляй ТОЛЬКО при явном сигнале; в большинстве ходов это null.
- Никогда не выставляй phase_transition.to = "intake" или "closed" — эти переходы делает только пользователь вручную.
- Ответ — ТОЛЬКО JSON, без markdown, без preamble.`;

// =============================================================================
// Patch shape
// =============================================================================

import {
  parsePhaseTransition,
  type PhaseTransitionPatch,
} from "./case_phase.ts";

export interface CasePatch {
  case_numbers_add: Array<Record<string, unknown>>;
  parties_add: Array<Record<string, unknown>>;
  authorities_add: Array<Record<string, unknown>>;
  key_dates_add: Array<Record<string, unknown>>;
  timeline_add: Array<Record<string, unknown>>;
  open_questions_replace: string[] | null;
  next_actions_replace: string[] | null;
  summary_replace: string | null;
  /** Pkg 5: optional phase transition signal from Haiku. `null` when
   * Haiku didn't flag a transition (the common case — most turns
   * don't change phase). */
  phase_transition: PhaseTransitionPatch | null;
}

/** Empty patch — used as the safe fallback when Haiku output is unparseable
 * or every field is empty. */
export function emptyPatch(): CasePatch {
  return {
    case_numbers_add: [],
    parties_add: [],
    authorities_add: [],
    key_dates_add: [],
    timeline_add: [],
    open_questions_replace: null,
    next_actions_replace: null,
    summary_replace: null,
    phase_transition: null,
  };
}

/** True when the patch carries no new facts — the caller should skip the
 * UPDATE entirely. A phase_transition does NOT count as "facts" for
 * this purpose; the caller checks it separately and may apply the
 * phase change even when the JSONB merge is a no-op. */
export function isEmptyPatch(p: CasePatch): boolean {
  return (
    p.case_numbers_add.length === 0 &&
    p.parties_add.length === 0 &&
    p.authorities_add.length === 0 &&
    p.key_dates_add.length === 0 &&
    p.timeline_add.length === 0 &&
    p.open_questions_replace === null &&
    p.next_actions_replace === null &&
    p.summary_replace === null
  );
}

// =============================================================================
// Parser
// =============================================================================

/**
 * Parse Haiku's raw JSON string into a [CasePatch]. Returns `null` on:
 *   * unparseable JSON,
 *   * top-level not an object,
 *   * pathological shapes (array fields are not arrays, etc.).
 *
 * Defensive: Haiku occasionally wraps JSON in ```json …``` markdown fences
 * despite the prompt forbidding it. We strip those before parsing.
 */
export function parseCasePatch(raw: unknown): CasePatch | null {
  if (typeof raw !== "string") return null;
  const stripped = stripCodeFence(raw).trim();
  if (stripped.length === 0) return null;

  let json: unknown;
  try {
    json = JSON.parse(stripped);
  } catch {
    return null;
  }
  if (!json || typeof json !== "object" || Array.isArray(json)) return null;

  const obj = json as Record<string, unknown>;
  const patch = emptyPatch();

  patch.case_numbers_add = asObjectArray(obj.case_numbers_add);
  patch.parties_add = asObjectArray(obj.parties_add);
  patch.authorities_add = asObjectArray(obj.authorities_add);
  patch.key_dates_add = asObjectArray(obj.key_dates_add);
  patch.timeline_add = asObjectArray(obj.timeline_add);

  patch.open_questions_replace = asStringArrayOrNull(obj.open_questions_replace);
  patch.next_actions_replace = asStringArrayOrNull(obj.next_actions_replace);
  patch.summary_replace = asStringOrNull(obj.summary_replace);
  patch.phase_transition = parsePhaseTransition(obj.phase_transition);

  return patch;
}

function stripCodeFence(s: string): string {
  // Match ```json ... ``` or ``` ... ``` with arbitrary surrounding whitespace.
  const fenceRe = /^[\s`]*(?:json)?\s*\n?([\s\S]*?)\n?\s*```?\s*$/i;
  const m = s.trim().match(fenceRe);
  if (m && m[1]) return m[1];
  // Strip a leading ``` line on its own.
  return s.replace(/^```(?:json)?\s*/i, "").replace(/```\s*$/i, "");
}

function asObjectArray(v: unknown): Array<Record<string, unknown>> {
  if (!Array.isArray(v)) return [];
  const out: Array<Record<string, unknown>> = [];
  for (const item of v) {
    if (item && typeof item === "object" && !Array.isArray(item)) {
      out.push(item as Record<string, unknown>);
    }
  }
  return out;
}

function asStringArrayOrNull(v: unknown): string[] | null {
  if (v === null || v === undefined) return null;
  if (!Array.isArray(v)) return null;
  const out: string[] = [];
  for (const item of v) {
    if (typeof item === "string") {
      const t = item.trim();
      if (t.length > 0) out.push(t);
    }
  }
  return out;
}

function asStringOrNull(v: unknown): string | null {
  if (v === null || v === undefined) return null;
  if (typeof v !== "string") return null;
  const t = v.trim();
  return t.length > 0 ? t : null;
}

// =============================================================================
// Merge — applies a patch to the current case row, returning the
// updated jsonb columns + summary. Append-only with dedupe for the *_add
// arrays; replace semantics for open_questions / next_actions / summary
// when the patch carries non-null values.
// =============================================================================

export interface CaseRowSnapshot {
  case_numbers: unknown;
  parties: unknown;
  authorities: unknown;
  key_dates: unknown;
  timeline: unknown;
  open_questions: unknown;
  next_actions: unknown;
  summary: unknown;
  /** Pkg 5: current phase. Optional for backwards compat with the
   * Pkg 1.A `load_active_case` RPC that pre-dates the column — null
   * is treated as 'intake' by the rule. */
  phase?: unknown;
}

export interface MergeResult {
  /** Field-level diff payload suitable for `update().match({id})`. Only
   * includes fields that actually changed — minimises the row write. */
  update: Record<string, unknown>;
  /** Names of the fields that changed. Returned to the caller for
   * observability (`fields_changed` in the HTTP response). */
  fields_changed: string[];
}

/**
 * Merge [patch] onto [snapshot] using the spec's append-vs-replace rules.
 * Pure: never throws, never reads from the DB, only computes the diff.
 */
export function mergePatchIntoSnapshot(
  snapshot: CaseRowSnapshot,
  patch: CasePatch,
): MergeResult {
  const update: Record<string, unknown> = {};
  const changed: string[] = [];

  // ── Append-only with dedupe ────────────────────────────────────────
  const cn = appendDedupe(
    asArray(snapshot.case_numbers),
    patch.case_numbers_add,
    "number",
  );
  if (cn.changed) {
    update.case_numbers = cn.value;
    changed.push("case_numbers");
  }

  const pa = appendDedupe(
    asArray(snapshot.parties),
    patch.parties_add,
    "name",
  );
  if (pa.changed) {
    update.parties = pa.value;
    changed.push("parties");
  }

  const au = appendDedupe(
    asArray(snapshot.authorities),
    patch.authorities_add,
    "name",
  );
  if (au.changed) {
    update.authorities = au.value;
    changed.push("authorities");
  }

  const kd = appendDedupe(
    asArray(snapshot.key_dates),
    patch.key_dates_add,
    null, // no single key — composite (date+event)
  );
  if (kd.changed) {
    update.key_dates = kd.value;
    changed.push("key_dates");
  }

  const tl = appendDedupe(
    asArray(snapshot.timeline),
    patch.timeline_add,
    null, // composite (date+event)
  );
  if (tl.changed) {
    update.timeline = tl.value;
    changed.push("timeline");
  }

  // ── Replace fields ─────────────────────────────────────────────────
  if (patch.open_questions_replace !== null) {
    if (!sameArray(asArray(snapshot.open_questions), patch.open_questions_replace)) {
      update.open_questions = patch.open_questions_replace;
      changed.push("open_questions");
    }
  }
  if (patch.next_actions_replace !== null) {
    if (!sameArray(asArray(snapshot.next_actions), patch.next_actions_replace)) {
      update.next_actions = patch.next_actions_replace;
      changed.push("next_actions");
    }
  }
  if (patch.summary_replace !== null) {
    const before = typeof snapshot.summary === "string" ? snapshot.summary : "";
    if (before.trim() !== patch.summary_replace.trim()) {
      update.summary = patch.summary_replace;
      changed.push("summary");
    }
  }

  return { update, fields_changed: changed };
}

interface AppendDedupeResult {
  value: unknown[];
  changed: boolean;
}

/**
 * Append items from [add] onto [existing], dropping duplicates either by
 * the [key] field (for object items) or by JSON-canonical equality.
 *
 * Strings dedupe by case-insensitive trimmed equality; objects dedupe by
 * the [key] field if present, falling back to JSON equality.
 */
function appendDedupe(
  existing: unknown[],
  add: Array<Record<string, unknown> | unknown>,
  key: string | null,
): AppendDedupeResult {
  if (add.length === 0) return { value: existing, changed: false };

  const out = [...existing];
  let added = 0;

  // Build a Set of canonical keys for O(1) dedupe lookup.
  const seen = new Set<string>();
  for (const item of out) {
    const k = canonicalKey(item, key);
    if (k !== null) seen.add(k);
  }

  for (const item of add) {
    const k = canonicalKey(item, key);
    if (k === null) continue; // Skip empty/invalid items.
    if (seen.has(k)) continue;
    seen.add(k);
    out.push(item);
    added++;
  }

  return { value: out, changed: added > 0 };
}

function canonicalKey(item: unknown, key: string | null): string | null {
  if (item === null || item === undefined) return null;
  if (typeof item === "string") {
    const t = item.trim().toLowerCase();
    return t.length > 0 ? `s:${t}` : null;
  }
  if (typeof item !== "object" || Array.isArray(item)) {
    // Number, boolean, array — render canonically.
    try {
      return `j:${JSON.stringify(item)}`;
    } catch {
      return null;
    }
  }
  const obj = item as Record<string, unknown>;
  if (key && typeof obj[key] === "string") {
    const v = (obj[key] as string).trim().toLowerCase();
    if (v.length > 0) return `${key}:${v}`;
  }
  // Composite key: date + event for timeline / key_dates.
  if (typeof obj.date === "string" && typeof obj.event === "string") {
    const d = obj.date.trim();
    const e = obj.event.trim().toLowerCase();
    if (d.length > 0 || e.length > 0) return `de:${d}|${e}`;
  }
  // Fall back to whole-object JSON canonical form.
  try {
    const sortedEntries = Object.entries(obj)
      .filter(([_, v]) => v !== null && v !== undefined)
      .sort(([a], [b]) => a.localeCompare(b));
    if (sortedEntries.length === 0) return null;
    return `o:${JSON.stringify(sortedEntries)}`;
  } catch {
    return null;
  }
}

function asArray(v: unknown): unknown[] {
  return Array.isArray(v) ? v : [];
}

function sameArray(a: unknown[], b: string[]): boolean {
  if (a.length !== b.length) return false;
  for (let i = 0; i < a.length; i++) {
    if (a[i] !== b[i]) return false;
  }
  return true;
}
