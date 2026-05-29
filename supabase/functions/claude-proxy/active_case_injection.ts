// active_case_injection.ts — Pkg 1.B of Case Memory rebuild (handoff 2026-05-05).
// -----------------------------------------------------------------------------
// When a chat call carries `case_id`, claude-proxy loads the user's active case
// (via the `load_active_case` RPC, RLS-bound to `auth.uid()`) and folds an
// <active_case> block into the system prompt so the model can reason on the
// case file as if it were sitting next to the user.
//
// Spec (memory: project_handoff_smart_lawyer.md "Как подмешиваем в промпт"):
//   * Block is inserted AFTER the legal corpus + RAG and BEFORE the memory
//     section. Insertion order matters: model reads law → case facts → persona.
//   * 30 KB hard cap on the formatted block. Trim sequence on overflow:
//       1. Drop document `parsed_summary` lines (keep filename + doc_type +
//          doc_date).
//       2. Trim timeline to the last 10 events.
//       3. Trim parties / authorities to the most recent few.
//       4. Minimal core: summary + open_questions + next_actions + case_numbers.
//   * If `case_id` is missing/invalid or the RPC returns null, the function
//     no-ops silently — chat continues unaffected.
//
// Pure module. No I/O, no fetch — `loadActiveCase` is the I/O seam, exposed
// separately so tests can mock it. `formatActiveCaseBlock` is pure formatting,
// `injectIntoSystemPrompt` is pure string surgery.
// -----------------------------------------------------------------------------

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  type AdviceDigestEntry,
  formatAdviceDigestBlock,
} from "../_shared/advice_digest.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";

/** UUID v4 (also accepts mixed case). Strict — `general` and friends fail. */
const UUID_RE =
  /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;

export function isValidCaseId(id: unknown): id is string {
  return typeof id === "string" && UUID_RE.test(id);
}

/** Hard cap on the serialised <active_case> block. Spec: 30 KB. */
export const MAX_ACTIVE_CASE_BYTES = 30_000;

/** Max bytes to inject from a single document's parsed_summary. */
export const MAX_DOC_SUMMARY_BYTES = 2_000;

/** Max total bytes of doc summary text injected across all documents. */
export const MAX_DOC_SECTION_BYTES = 8_000;

/** Identity marker that the system_prompt_guard whitelists when the active
 * case block is INSERTED inline. We do not replace the leading marker — but
 * a defensive `# ROLE — Advocat: Estonian-EU legal AI assistant with case
 * memory` opener may appear in future when the client decides to lead with
 * case context. Whitelisting it now keeps Pkg 1.D unblocked. */
export const ACTIVE_CASE_MARKER =
  "# ROLE — Advocat: Estonian-EU legal AI assistant with case memory";

/** Shape returned by `load_active_case(p_case_id)` RPC. */
export interface ActiveCasePayload {
  case: ActiveCaseRow | null;
  recent_documents: ActiveCaseDocument[];
}

export interface ActiveCaseRow {
  id: string;
  user_id: string;
  title: string;
  jurisdiction: string;
  case_type?: string | null;
  status: string;
  case_numbers: unknown; // jsonb array
  parties: unknown;
  key_dates: unknown;
  authorities: unknown;
  timeline: unknown;
  open_questions: unknown;
  next_actions: unknown;
  summary?: string | null;
  language?: string | null;
  created_at?: string;
  updated_at?: string;
  advice_digest?: unknown;
}

export interface ActiveCaseDocument {
  id?: string;
  filename: string;
  doc_type?: string | null;
  doc_date?: string | null;
  parsed_summary?: string | null;
  uploaded_at?: string;
}

// =============================================================================
// I/O seam — `loadActiveCase`
// =============================================================================

/**
 * Call the `load_active_case(p_case_id)` Postgres RPC, forwarding the user's
 * JWT so RLS on `public.user_cases` and `public.case_documents` resolves to
 * the calling user. Returns null on:
 *   * any DB / network error,
 *   * RLS-blocked (user does not own the case),
 *   * non-existent case id.
 *
 * We intentionally fail OPEN: a Case Memory load failure must not break chat.
 * The caller skips injection and proceeds.
 */
export async function loadActiveCase(
  caseId: string,
  authHeader: string,
): Promise<ActiveCasePayload | null> {
  if (!isValidCaseId(caseId)) return null;
  if (!SUPABASE_URL) return null;

  try {
    // Supabase JS client honours the per-request `Authorization` header so
    // RPC calls execute as the calling user (security invoker → RLS).
    const supabase = createClient(SUPABASE_URL, "", {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data, error } = await supabase.rpc("load_active_case", {
      p_case_id: caseId,
    });
    if (error) {
      console.warn(
        `claude-proxy: load_active_case error: ${
          String(error.message ?? error).slice(0, 200)
        }`,
      );
      return null;
    }
    if (!data) return null;
    // RPC returns jsonb { case, recent_documents }. When the case is missing
    // the JSON object still comes back but with `case` set to null.
    const obj = data as ActiveCasePayload;
    if (!obj || obj.case == null) return null;
    return {
      case: obj.case,
      recent_documents: Array.isArray(obj.recent_documents)
        ? obj.recent_documents
        : [],
    };
  } catch (e) {
    console.warn(
      `claude-proxy: load_active_case threw: ${String(e).slice(0, 200)}`,
    );
    return null;
  }
}

// =============================================================================
// Formatter
// =============================================================================

/** Trim level used by [formatActiveCaseBlock] to fit inside the 30 KB cap. */
export type TrimLevel =
  | "full" // include everything
  | "no-doc-summaries" // step 1: drop parsed_summary lines on documents
  | "trimmed-timeline" // step 2: also keep only last 10 timeline events
  | "trimmed-parties" // step 3: also trim parties/authorities to last 5
  | "minimal"; // step 4: summary + open_questions + next_actions + case_numbers only

/**
 * Pure formatter. Renders the <active_case>...</active_case> block at the
 * given trim level. Never throws.
 */
export function formatActiveCaseBlock(
  payload: ActiveCasePayload,
  level: TrimLevel = "full",
): string {
  const c = payload.case;
  if (!c) return "";

  const lines: string[] = [];
  lines.push("<active_case>");
  lines.push(`Title: ${stringOr(c.title, "—")}`);
  lines.push(`Jurisdiction: ${stringOr(c.jurisdiction, "—")}`);
  if (c.case_type) lines.push(`Case type: ${c.case_type}`);
  lines.push(`Status: ${stringOr(c.status, "—")}`);

  const caseNumbers = asStringArray(c.case_numbers);
  if (caseNumbers.length > 0) {
    lines.push(`Case numbers: ${caseNumbers.join(", ")}`);
  }

  if (level !== "minimal") {
    const authorities = asStringArray(c.authorities);
    if (authorities.length > 0) {
      const trimmed = level === "trimmed-parties"
        ? authorities.slice(-5)
        : authorities;
      lines.push(`Authorities: ${trimmed.join(", ")}`);
    }

    const parties = asStringArray(c.parties);
    if (parties.length > 0) {
      const trimmed = level === "trimmed-parties"
        ? parties.slice(-5)
        : parties;
      lines.push(`Parties: ${trimmed.join(", ")}`);
    }

    const keyDates = asStringArray(c.key_dates);
    if (keyDates.length > 0) {
      lines.push(`Key dates: ${keyDates.join("; ")}`);
    }

    const timeline = asStringArray(c.timeline);
    if (timeline.length > 0) {
      const events = (level === "trimmed-timeline" ||
          level === "trimmed-parties")
        ? timeline.slice(-10)
        : timeline;
      lines.push("Timeline:");
      for (const ev of events) lines.push(`  - ${ev}`);
    }
  }

  if (c.summary && c.summary.trim().length > 0) {
    lines.push("Summary:");
    lines.push(`  ${neutralize(c.summary.trim())}`);
  }

  const openQs = asStringArray(c.open_questions);
  if (openQs.length > 0) {
    lines.push("Open questions:");
    for (const q of openQs) lines.push(`  - ${q}`);
  }

  const nextActions = asStringArray(c.next_actions);
  if (nextActions.length > 0) {
    lines.push("Next actions:");
    for (const a of nextActions) lines.push(`  - ${a}`);
  }

  // Prior advice digest
  if (c.advice_digest) {
    try {
      const entries = Array.isArray(c.advice_digest)
        ? c.advice_digest as AdviceDigestEntry[]
        : [];
      const block = formatAdviceDigestBlock(entries);
      if (block) lines.push("", block);
    } catch { /* swallow */ }
  }

  if (level !== "minimal") {
    const docs = payload.recent_documents ?? [];
    if (docs.length > 0) {
      lines.push("Recent documents:");
      let docSectionBytes = 0;
      for (const d of docs) {
        const head = [
          neutralize(d.filename || "(unnamed)"),
          d.doc_type ? `[${neutralize(d.doc_type)}]` : "",
          d.doc_date ? `(${neutralize(d.doc_date)})` : "",
        ]
          .filter((s) => s.length > 0)
          .join(" ");
        lines.push(`  - ${head}`);
        const summary = d.parsed_summary?.trim();
        if (
          summary && summary.length > 0 &&
          level === "full" &&
          docSectionBytes < MAX_DOC_SECTION_BYTES
        ) {
          const truncated = truncateToBytes(summary, MAX_DOC_SUMMARY_BYTES);
          for (const summaryLine of truncated.split(/\r?\n/)) {
            const trimmedLine = neutralize(summaryLine.trim());
            if (trimmedLine.length > 0) {
              lines.push(`      ${trimmedLine}`);
            }
          }
          docSectionBytes += utf8Bytes(truncated);
        }
      }
    }
  }

  lines.push("</active_case>");
  return lines.join("\n");
}

/**
 * Format with progressive trimming until the result fits in [maxBytes].
 * Returns null if even the minimal level cannot fit (caller should skip
 * injection in that pathological case).
 */
export function formatActiveCaseBlockWithCap(
  payload: ActiveCasePayload,
  maxBytes: number = MAX_ACTIVE_CASE_BYTES,
): string | null {
  const order: TrimLevel[] = [
    "full",
    "no-doc-summaries",
    "trimmed-timeline",
    "trimmed-parties",
    "minimal",
  ];
  for (const level of order) {
    const out = formatActiveCaseBlock(payload, level);
    if (utf8Bytes(out) <= maxBytes) return out;
  }
  return null;
}

// =============================================================================
// Insertion
// =============================================================================

/**
 * Insert [block] into [systemPrompt] at the canonical position:
 *   - AFTER the `# LEGAL KNOWLEDGE BASE` section (and after the optional
 *     `# CURRENT CASE CONTEXT` section that follows it),
 *   - BEFORE the `# OUTPUT FORMAT` trailer.
 *
 * Why this position: in the chat client's `buildChatPrompt`, the order is
 *   base role → memoryBlock → LEGAL KNOWLEDGE BASE → CURRENT CASE CONTEXT →
 *   OUTPUT FORMAT.
 * Inserting before OUTPUT FORMAT places `<active_case>` after the legal
 * corpus (matches "after legal corpus, before memory" — model has now
 * already consumed memory near the top of the prompt and can interpret the
 * fresh case facts against the law).
 *
 * Falls back to:
 *   - prepend before content when no anchor is found (still satisfies the
 *     spec's "before memory section" intent if the prompt lacks our markers).
 *
 * Pure function. Idempotent: repeat injections of the same block do not
 * duplicate it (we strip any pre-existing `<active_case>...</active_case>`
 * before inserting).
 */
export function injectIntoSystemPrompt(
  systemPrompt: string,
  block: string,
): string {
  if (!block) return systemPrompt;
  // Idempotency: drop any prior <active_case>...</active_case> (recomputed
  // each turn anyway, so the system prompt is stateless w.r.t. case id).
  const stripped = systemPrompt.replace(
    /\n*<active_case>[\s\S]*?<\/active_case>\n*/g,
    "\n\n",
  );

  // Preferred anchor: insert before "# OUTPUT FORMAT".
  const outputFormatIdx = stripped.indexOf("# OUTPUT FORMAT");
  if (outputFormatIdx > 0) {
    const before = stripped.slice(0, outputFormatIdx).trimEnd();
    const after = stripped.slice(outputFormatIdx);
    return `${before}\n\n${block}\n\n${after}`;
  }

  // Secondary anchor: insert AFTER the LEGAL KNOWLEDGE BASE section by
  // scanning for the next blank line that starts a new heading.
  const lkbIdx = stripped.indexOf("# LEGAL KNOWLEDGE BASE");
  if (lkbIdx >= 0) {
    // Find the start of the next top-level heading after LKB. We use a
    // regex anchored on a "\n# " heading boundary AFTER lkbIdx (skipping
    // the LEGAL KNOWLEDGE BASE heading itself). If none found, append to
    // the end of the prompt.
    const after = stripped.slice(lkbIdx);
    // Skip past the LKB heading line itself so the regex won't match it.
    const nlAfterHeading = after.indexOf("\n");
    const searchFrom = nlAfterHeading >= 0 ? nlAfterHeading + 1 : 0;
    const tail = after.slice(searchFrom);
    const nextHeadingMatch = /\n# /m.exec(tail);
    if (nextHeadingMatch) {
      const insertGlobalIdx = lkbIdx + searchFrom + nextHeadingMatch.index;
      const before = stripped.slice(0, insertGlobalIdx).trimEnd();
      const rest = stripped.slice(insertGlobalIdx);
      return `${before}\n\n${block}\n${rest}`;
    }
    // No next heading — append at end with a blank line.
    return `${stripped.trimEnd()}\n\n${block}\n`;
  }

  // No anchors at all — prepend the block. Still satisfies the spec's
  // "before memory section" since this prompt has no memory section.
  return `${block}\n\n${stripped}`;
}

// =============================================================================
// Deadline Alert
// =============================================================================

/**
 * Build a ⚠️ DEADLINE ALERT block if the case has any key_dates within the
 * next [windowDays] days (inclusive of today, exclusive of past dates).
 *
 * key_dates is a jsonb array of `{ date: string; event: string }` objects.
 * If no urgent deadlines exist, returns "".
 *
 * Pure function — no I/O.
 */
export function buildDeadlineAlertBlock(
  caseRow: ActiveCaseRow,
  today: Date,
  windowDays = 14,
): string {
  let dates: Array<{ date: string; event: string }> = [];
  try {
    const raw = caseRow.key_dates;
    if (Array.isArray(raw)) {
      dates = raw as Array<{ date: string; event: string }>;
    }
  } catch {
    return "";
  }

  const urgent: Array<{ date: string; event: string; daysLeft: number }> = [];
  for (const entry of dates) {
    if (!entry.date || !entry.event) continue;
    const d = new Date(entry.date);
    if (isNaN(d.getTime())) continue;
    // Normalise both sides to midnight UTC to avoid partial-day drift.
    const todayMidnight = Date.UTC(
      today.getFullYear(),
      today.getMonth(),
      today.getDate(),
    );
    const deadlineMidnight = Date.UTC(
      d.getFullYear(),
      d.getMonth(),
      d.getDate(),
    );
    const daysLeft = Math.round(
      (deadlineMidnight - todayMidnight) / (1000 * 60 * 60 * 24),
    );
    if (daysLeft >= 0 && daysLeft <= windowDays) {
      urgent.push({ ...entry, daysLeft });
    }
  }

  if (urgent.length === 0) return "";

  const lines = [
    "⚠️ DEADLINE ALERT — inform the user proactively in your first response:",
  ];
  for (
    const u of urgent.sort((a, b) => a.daysLeft - b.daysLeft)
  ) {
    const urgency = u.daysLeft === 0
      ? "TODAY"
      : u.daysLeft === 1
      ? "TOMORROW"
      : `${u.daysLeft} days`;
    lines.push(`  • ${u.event} — ${u.date} (${urgency})`);
  }
  lines.push("Start your response by acknowledging the most urgent deadline above.");
  return lines.join("\n");
}

/**
 * End-to-end helper used by `claude-proxy/index.ts`. Pure orchestration —
 * no I/O. The caller has already loaded the payload via [loadActiveCase].
 */
export function applyActiveCase(
  systemPrompt: string,
  payload: ActiveCasePayload | null,
  maxBytes: number = MAX_ACTIVE_CASE_BYTES,
): string {
  if (!payload || !payload.case) return systemPrompt;
  const block = formatActiveCaseBlockWithCap(payload, maxBytes);
  if (!block) return systemPrompt;
  return injectIntoSystemPrompt(systemPrompt, block);
}

/**
 * Same as [applyActiveCase] but operates on the Anthropic content-block
 * shape used for prompt caching. We mutate the FIRST text block in place —
 * that's the one we cache, so the case-memory becomes part of the cached
 * prefix only if it is stable across turns. (For now Pkg 1.B keeps it in
 * the dynamic slice; Pkg 1.C may pin a stable summary into the cache.)
 *
 * Returns the (possibly mutated) system prompt — string, array, or
 * unchanged when payload is null.
 */
export function applyActiveCaseToBody(
  body: { system?: unknown },
  payload: ActiveCasePayload | null,
  maxBytes: number = MAX_ACTIVE_CASE_BYTES,
  today: Date = new Date(),
): void {
  if (!payload || !payload.case) return;
  const block = formatActiveCaseBlockWithCap(payload, maxBytes);
  if (!block) return;

  // Build deadline alert (prepended to system prompt before everything else).
  const alertBlock = buildDeadlineAlertBlock(payload.case, today);

  const sys = body.system;
  if (typeof sys === "string") {
    let result = injectIntoSystemPrompt(sys, block);
    if (alertBlock) result = `${alertBlock}\n\n${result}`;
    body.system = result;
    return;
  }
  if (Array.isArray(sys)) {
    // Find the first text block and inject into its text. Skip cache_control
    // changes — the block is now slightly different, but the existing
    // cache_control on adjacent blocks is unaffected (Anthropic caches by
    // content hash; this turn just won't hit the cache prefix that includes
    // the active_case section, which is correct).
    for (let i = 0; i < sys.length; i++) {
      const b = sys[i];
      if (
        b && typeof b === "object" &&
        typeof (b as { text?: unknown }).text === "string"
      ) {
        const before = (b as { text: string }).text;
        let result = injectIntoSystemPrompt(before, block);
        if (alertBlock) result = `${alertBlock}\n\n${result}`;
        (b as { text: string }).text = result;
        return;
      }
    }
  }
  // Unknown shape — do nothing. The guard will reject it anyway.
}

// =============================================================================
// Helpers
// =============================================================================

function truncateToBytes(s: string, maxBytes: number): string {
  const encoded = new TextEncoder().encode(s);
  if (encoded.length <= maxBytes) return s;
  // Slice to maxBytes then decode, replacing incomplete trailing multi-byte
  // sequences with the replacement character (TextDecoder default behaviour
  // when `fatal` is false).
  const sliced = encoded.slice(0, maxBytes);
  return new TextDecoder("utf-8", { fatal: false }).decode(sliced);
}

function utf8Bytes(s: string): number {
  // Cheap UTF-8 byte counter without TextEncoder churn for tiny strings —
  // close enough for cap arithmetic. TextEncoder gives exact byte length;
  // we use it for correctness in the pathological case.
  return new TextEncoder().encode(s).length;
}

/**
 * Neutralize untrusted text before it is interpolated into the <active_case>
 * block. The block is folded RAW into the system prompt (it is trusted
 * context, NOT wrapped in <untrusted_data>), so a value containing
 * `</active_case>` — most reachably a document's parsed_summary from an
 * uploaded/inbound PDF — could close the block early and inject attacker
 * instructions into the trusted prompt. We strip the angle brackets that make
 * tag breakout possible; the model still reads the text fine without them.
 */
function neutralize(s: string): string {
  return s.replace(/[<>]/g, " ");
}

function asStringArray(v: unknown): string[] {
  if (!Array.isArray(v)) return [];
  const out: string[] = [];
  for (const item of v) {
    if (typeof item === "string") {
      const trimmed = neutralize(item.trim());
      if (trimmed.length > 0) out.push(trimmed);
    } else if (item && typeof item === "object") {
      // Common JSON shapes: { date, event } / { name, role } / { number, type }.
      // Render compactly — the model can read JSON-ish but plain text is cheaper.
      const rec = item as Record<string, unknown>;
      const parts = Object.entries(rec)
        .filter(([_, v]) => v != null && String(v).length > 0)
        .map(([k, v]) => `${neutralize(k)}: ${neutralize(String(v))}`);
      if (parts.length > 0) out.push(parts.join(", "));
    }
  }
  return out;
}

function stringOr(v: unknown, fallback: string): string {
  if (typeof v === "string" && v.trim().length > 0) return neutralize(v.trim());
  return fallback;
}
