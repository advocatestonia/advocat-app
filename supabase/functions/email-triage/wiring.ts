// email-triage/wiring.ts
// -----------------------------------------------------------------------------
// Carry-over wiring helpers for the D4 triage pipeline. Pulled out of
// `index.ts` so the unit tests can import them WITHOUT booting the
// `serve()` HTTP listener at module-eval time. (Importing index.ts in a
// Deno test triggers the listener and the test runner errors out on
// `Requires net access to "0.0.0.0:8000"`.)
//
// Each function is small, dependency-injected via the Supabase client,
// and soft-fails on error so the triage critical path is never blocked
// by an outage in a sidecar (RAG, memory, case timeline).
// -----------------------------------------------------------------------------

import type { MemoryBlock } from "./triage_logic.ts";
import type { MemoryUpdate } from "./parse_blocks.ts";

/**
 * Carry-over Task 1: build the MemoryBlock for a user.
 *
 * Sources (per OPERATOR_PROMPT v1 §3.7, ≤ ~2 KB total):
 *   - own_counsel_emails           ← user_settings.own_counsel_emails
 *   - dead_addresses               ← user_settings.dead_address_corrections
 *                                    (jsonb {from: to} → array of pairs)
 *   - identity_markers / known_…   ← user_ai_memory (Tier 2 — keys
 *                                    `name`, `known_party`, `discussed_topic`)
 *   - recent_owner_feedback        ← email_triage_results.user_action over
 *                                    the last 7 days (capped at 5)
 *
 * Soft-fail to a stable empty shape on any error — the model has a
 * stable schema regardless of DB availability.
 */
export async function loadMemoryBlockReal(
  // deno-lint-ignore no-explicit-any
  sb: any,
  userId: string,
): Promise<MemoryBlock> {
  const empty: MemoryBlock = {
    identity_markers: {},
    dead_addresses: [],
    own_counsel_emails: [],
    known_privileged_individuals: [],
    relations: null,
    recent_owner_feedback: undefined,
  };
  if (!userId) return empty;

  type SettingsRow = {
    own_counsel_emails?: string[] | null;
    dead_address_corrections?: Record<string, unknown> | null;
  };
  type MemoryRow = {
    key: string;
    value: { text?: string } | null;
    confidence?: number;
  };

  // Run the reads in parallel — none of them depend on each other.
  // Note: each is wrapped via try/catch (loadRecentOwnerFeedback) or
  // safeQuery so a single throw doesn't reject the Promise.all.
  let settingsRes: SettingsRow | null = null;
  let memoryRes: MemoryRow[] | null = null;
  let feedbackRes: string | undefined;
  try {
    const [s, m, f] = await Promise.all([
      safeQuery<SettingsRow | null>(sb
        .from("user_settings")
        .select("own_counsel_emails, dead_address_corrections")
        .eq("user_id", userId)
        .maybeSingle()),
      safeQuery<MemoryRow[] | null>(sb
        .from("user_ai_memory")
        .select("key, value, confidence")
        .eq("user_id", userId)
        .in("key", ["name", "known_party", "discussed_topic"])
        .order("confidence", { ascending: false })
        .limit(20)),
      loadRecentOwnerFeedback(sb, userId),
    ]);
    settingsRes = s;
    memoryRes = m;
    feedbackRes = f;
  } catch (_e) {
    return empty;
  }

  // own_counsel_emails — array<text>, dedupe + lowercase.
  const ownCounsel: string[] = Array.from(
    new Set(
      ((settingsRes?.own_counsel_emails as string[] | null) ?? [])
        .map((s) => String(s ?? "").trim().toLowerCase())
        .filter((s) => s.length > 0),
    ),
  );

  // dead_addresses — jsonb {from: to} → array<{from, to}>.
  const deadAddresses: Array<{ from: string; to: string }> = [];
  const dac = settingsRes?.dead_address_corrections;
  if (dac && typeof dac === "object" && !Array.isArray(dac)) {
    for (const [from, to] of Object.entries(dac as Record<string, unknown>)) {
      if (typeof from === "string" && typeof to === "string" &&
          from.length > 0 && to.length > 0) {
        deadAddresses.push({ from, to });
      }
    }
  }

  // identity_markers — flatten user_ai_memory rows by key.
  const identityMarkers: Record<string, string> = {};
  const knownPrivileged: string[] = [];
  for (const row of (memoryRes ?? []) as MemoryRow[]) {
    const text = row?.value?.text;
    if (!text) continue;
    if (row.key === "name" && !identityMarkers["name"]) {
      identityMarkers["name"] = String(text).slice(0, 200);
    } else if (row.key === "known_party") {
      // Surface as known_privileged_individuals when the text mentions a
      // role that signals legal-counsel context (lawyer/attorney/advokaat).
      const lower = String(text).toLowerCase();
      if (/(lawyer|attorney|advokaat|asianajaja|advokaadi|адвокат)/.test(lower)
          && knownPrivileged.length < 8) {
        knownPrivileged.push(text);
      }
    }
  }

  return {
    identity_markers: identityMarkers,
    dead_addresses: deadAddresses,
    own_counsel_emails: ownCounsel,
    known_privileged_individuals: knownPrivileged,
    relations: null,
    recent_owner_feedback: feedbackRes,
  };
}

async function loadRecentOwnerFeedback(
  // deno-lint-ignore no-explicit-any
  sb: any,
  userId: string,
): Promise<string | undefined> {
  // Last 7 days of explicit user_action on triage rows.
  const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 3600 * 1000)
    .toISOString();
  try {
    const { data, error } = await sb
      .from("email_triage_results")
      .select("created_at, user_action, draft_subject, draft_to")
      .eq("user_id", userId)
      .gte("created_at", sevenDaysAgo)
      .not("user_action", "is", null)
      .order("created_at", { ascending: false })
      .limit(5);
    if (error || !Array.isArray(data) || data.length === 0) return undefined;
    const lines = data.map((row: Record<string, unknown>) => {
      const date = String(row.created_at ?? "").slice(0, 10);
      const recipient = Array.isArray(row.draft_to) && row.draft_to.length > 0
        ? String(row.draft_to[0])
        : "(no recipient)";
      const verdict = String(row.user_action ?? "");
      return `${date} → ${recipient}: ${verdict}`;
    });
    return lines.join("; ");
  } catch (_e) {
    return undefined;
  }
}

// =============================================================================
// Fix #2 (2026-05-26) — email_attachments → pdf-parser → triage context bridge
// =============================================================================
// Pipeline: D3 sync drops every inbound PDF / image attachment into
// case-documents Storage and inserts an `email_attachments` row (Fix #1).
// At triage time we:
//   1. SELECT every email_attachments row for the thread (PDFs only — image
//      OCR is handled by the chat upload path, not yet by triage).
//   2. For any row with `parsed_text IS NULL`, call pdf-parser (or the
//      injected `parsePdf` stub in tests) with the storage_path, then
//      cache the result back to the row.
//   3. Return `{ filename, mime, parsed_text, parsed_meta }[]` — the
//      orchestrator pours these into the `<inbound_attachments>` block
//      of the system prompt's `<context>` suffix, capped at 5 000 chars
//      per attachment so one giant scan cannot blow the 80 KB context
//      budget.
//
// Soft-fail contract: ANY error (DB outage, pdf-parser fault, row update
// race) → return `[]` and log a console.warn. Identical to
// `loadLawSearchReal` — triage must never block on an attachment-parse
// outage.

/** Shape returned per attachment. `parsed_text` is already capped at 5 000
 *  chars; `parsed_meta` is whatever the parser surfaced (page_count,
 *  doc_type, lang_detected — small JSON sidecar). */
export interface InboundAttachment {
  filename: string;
  mime: string;
  parsed_text: string;
  parsed_meta: Record<string, unknown> | null;
}

/** Per-attachment cap on returned `parsed_text`. One scanned PDF can be
 *  100 KB of OCR'd noise; we want a digest, not the full corpus.
 *  Coordinates with INBOUND_ATTACHMENTS_BLOCK_BUDGET_BYTES — 4 attachments
 *  × 5 000 chars stays comfortably inside the 20 KB block budget. */
const INBOUND_ATTACHMENT_TEXT_CAP = 5_000;

/** Callable used by `loadInboundAttachmentTexts` to convert a stored
 *  PDF/image into text. Default impl calls the pdf-parser edge fn via
 *  HTTP fetch (service-role bearer + `x-internal-call: email-triage`
 *  header — mirrors the email-inbox-sync → email-triage pattern). Tests
 *  inject a stub so the unit suite stays Deno-only. */
export type ParsePdfFn = (args: {
  storage_path: string;
  mime: string;
  filename: string;
  user_id: string;
}) => Promise<{
  parsed_text: string;
  parsed_meta: Record<string, unknown> | null;
}>;

interface EmailAttachmentRow {
  id: string;
  user_id: string;
  filename: string;
  mime: string;
  storage_path: string;
  parsed_text: string | null;
  parsed_meta: Record<string, unknown> | null;
}

/** Load + (lazily) parse every PDF attachment on a thread. Returns the
 *  per-attachment excerpt the orchestrator pours into the system prompt
 *  `<inbound_attachments>` block.
 *
 *  Soft-fails to `[]` on any error — graceful degradation contract.
 *
 *  @param opts.parsePdf — test injection. Production callers leave
 *    undefined to use the default pdf-parser HTTP impl.
 */
export async function loadInboundAttachmentTexts(
  // deno-lint-ignore no-explicit-any
  sb: any,
  threadId: string,
  opts: { parsePdf?: ParsePdfFn } = {},
): Promise<InboundAttachment[]> {
  if (!threadId) return [];

  // 1. Read every PDF row for this thread. We do NOT filter on
  //    `parsed_text IS NULL` in the query — we WANT already-parsed rows
  //    surfaced so the triage prompt sees them too. The lazy-parse pass
  //    below skips the rows that already have text.
  let rows: EmailAttachmentRow[] = [];
  try {
    const { data, error } = await sb
      .from("email_attachments")
      .select(
        "id, user_id, filename, mime, storage_path, parsed_text, parsed_meta",
      )
      .eq("thread_id", threadId)
      .eq("mime", "application/pdf");
    if (error) {
      console.warn(
        `email-triage: load email_attachments err: ${
          String(error.message ?? error).slice(0, 200)
        }`,
      );
      return [];
    }
    if (!Array.isArray(data)) return [];
    rows = data as EmailAttachmentRow[];
  } catch (e) {
    console.warn(
      `email-triage: load email_attachments threw: ${String(e).slice(0, 200)}`,
    );
    return [];
  }

  if (rows.length === 0) return [];

  const parser: ParsePdfFn = opts.parsePdf ?? defaultParsePdf;
  const out: InboundAttachment[] = [];

  for (const row of rows) {
    try {
      // Hot path — text already cached. Use the stored copy verbatim, no
      // pdf-parser round-trip. Cap-on-return so callers always see a
      // bounded blob even if the cache was populated before the cap
      // existed.
      if (row.parsed_text && row.parsed_text.length > 0) {
        out.push({
          filename: row.filename,
          mime: row.mime,
          parsed_text: row.parsed_text.slice(0, INBOUND_ATTACHMENT_TEXT_CAP),
          parsed_meta: row.parsed_meta ?? null,
        });
        continue;
      }

      // Cold path — call pdf-parser and cache the result.
      const parsed = await parser({
        storage_path: row.storage_path,
        mime: row.mime,
        filename: row.filename,
        user_id: row.user_id,
      });
      if (!parsed || typeof parsed.parsed_text !== "string") {
        // Parser returned no text — skip silently. Triage continues
        // without this attachment in context.
        continue;
      }

      // Cache write-back. Best-effort: a missed update only means the
      // next triage run re-parses; never block the current run.
      try {
        await sb
          .from("email_attachments")
          .update({
            parsed_text: parsed.parsed_text,
            parsed_meta: parsed.parsed_meta ?? null,
            parsed_at: new Date().toISOString(),
          })
          .eq("id", row.id);
      } catch (e) {
        console.warn(
          `email-triage: email_attachments cache update failed (${row.id}): ${
            String(e).slice(0, 200)
          }`,
        );
      }

      out.push({
        filename: row.filename,
        mime: row.mime,
        parsed_text: parsed.parsed_text.slice(0, INBOUND_ATTACHMENT_TEXT_CAP),
        parsed_meta: parsed.parsed_meta ?? null,
      });
    } catch (e) {
      // Per directive: ANY error → return [], never throw. A single bad
      // attachment poisons the whole batch — we'd rather triage on the
      // thread text alone than half-parsed attachments. The console.warn
      // surfaces the failure in the edge fn log stream.
      console.warn(
        `email-triage: inbound attachment parse failed (${row.id}): ${
          String(e).slice(0, 200)
        }`,
      );
      return [];
    }
  }

  return out;
}

/** Production `ParsePdfFn` — calls the pdf-parser edge fn via HTTP.
 *  Mirrors the email-inbox-sync → email-triage internal-call pattern
 *  (service-role bearer + `x-internal-call` header). Returns whatever
 *  text the parser surfaces; on any HTTP error throws so the
 *  per-attachment try/catch above can swallow it. */
async function defaultParsePdf(args: {
  storage_path: string;
  mime: string;
  filename: string;
  user_id: string;
}): Promise<{
  parsed_text: string;
  parsed_meta: Record<string, unknown> | null;
}> {
  // deno-lint-ignore no-explicit-any
  const envGet = (globalThis as any).Deno?.env?.get?.bind(
    // deno-lint-ignore no-explicit-any
    (globalThis as any).Deno.env,
  );
  const supabaseUrl = envGet?.("SUPABASE_URL");
  const serviceKey = envGet?.("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceKey) {
    throw new Error("SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY missing");
  }
  const url = `${String(supabaseUrl).replace(/\/$/, "")}/functions/v1/pdf-parser`;
  const resp = await fetch(url, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${serviceKey}`,
      "Content-Type": "application/json",
      "x-internal-call": "email-triage",
    },
    body: JSON.stringify({
      storage_path: args.storage_path,
      mime_type: args.mime,
      filename: args.filename,
      case_id: null,
    }),
  });
  if (!resp.ok) {
    throw new Error(`pdf-parser ${resp.status}`);
  }
  const json = await resp.json() as Record<string, unknown>;
  if (json && typeof json.error === "string") {
    // pdf-parser returns 200 + {error:...} for too_long / scan_too_long /
    // unreadable. Treat as a parse miss — we don't want to pour an error
    // message into the triage context.
    throw new Error(`pdf-parser soft-error: ${json.error}`);
  }
  // The pdf-parser response carries `parsed_summary` (model digest) +
  // `document_id` (FK into case_documents.parsed_text). For our context
  // bridge we prefer the digest — it's compact and the orchestrator's
  // budget is already tight. Full text is available via case_documents
  // when the user clicks through to "view document".
  const summary = typeof json.parsed_summary === "string"
    ? json.parsed_summary
    : "";
  const meta: Record<string, unknown> = {};
  if (typeof json.doc_type === "string") meta.doc_type = json.doc_type;
  if (typeof json.page_count === "number") meta.page_count = json.page_count;
  if (Array.isArray(json.lang_detected)) {
    meta.lang_detected = json.lang_detected;
  }
  if (typeof json.document_id === "string") {
    meta.document_id = json.document_id;
  }
  return { parsed_text: summary, parsed_meta: meta };
}

/**
 * Carry-over Task 2: invoke the existing `law-search` edge fn.
 *
 * Wire-format ref: supabase/functions/law-search/index.ts header.
 * Soft-fail to `[]` on ANY error so the triage critical path is never
 * blocked by RAG outages.
 */
export async function loadLawSearchReal(
  // deno-lint-ignore no-explicit-any
  sb: any,
  query: string,
): Promise<unknown> {
  if (!query || query.trim().length === 0) return [];
  try {
    const { data, error } = await sb.functions.invoke("law-search", {
      body: {
        query: query.trim().slice(0, 1500),
        // Default jurisdiction → Estonian. Caller passes
        // active_case.jurisdiction via extractLegalKeywords-derived
        // context if it's set; in the carry-over wiring we keep the
        // default conservative — the law-search fn validates lang.
        lang: "et",
        match_count: 5,
      },
    });
    if (error) return [];
    if (data && typeof data === "object" && Array.isArray(data.chunks)) {
      // Return only the fields the model actually consumes — keep the
      // injected context tight (§3.7 budget).
      return data.chunks.slice(0, 5).map((c: Record<string, unknown>) => ({
        act_slug: c.act_slug,
        paragraph: c.paragraph,
        title: c.title,
        body: typeof c.body === "string"
          ? (c.body as string).slice(0, 800)
          : c.body,
        source_url: c.source_url,
        similarity: c.similarity,
      }));
    }
    return [];
  } catch (_e) {
    return [];
  }
}

/**
 * Carry-over Task 3: append a typed event to `user_cases.timeline`
 * (jsonb), with idempotency guard.
 *
 * Idempotency hash: `(case_id, type, ref_email_id, occurred_at)`. If a
 * timeline entry with the same hash already exists, the write is a
 * no-op — re-running triage on the same thread does not duplicate
 * events.
 */
export async function appendCaseEventReal(
  // deno-lint-ignore no-explicit-any
  sb: any,
  args: {
    user_id: string;
    case_id: string | null;
    type: string;
    payload: Record<string, unknown>;
  },
): Promise<void> {
  if (!args.case_id) return;
  try {
    const { data: caseRow, error } = await sb
      .from("user_cases")
      .select("timeline")
      .eq("id", args.case_id)
      .eq("user_id", args.user_id)
      .maybeSingle();
    if (error || !caseRow) return;
    const tl = Array.isArray(caseRow.timeline) ? caseRow.timeline : [];
    const occurredAt = new Date().toISOString();
    const refEmailId = String(args.payload?.thread_id ?? "");
    const hash = `${args.case_id}|${args.type}|${refEmailId}|${occurredAt.slice(0, 10)}`;
    // Skip if same-day same-thread same-type already there.
    const dup = (tl as Array<Record<string, unknown>>).some((entry) => {
      const eHash = `${args.case_id}|${entry.type}|${entry.ref_email_id ?? ""}|${
        String(entry.occurred_at ?? entry.ts ?? "").slice(0, 10)
      }`;
      return eHash === hash;
    });
    if (dup) return;
    tl.push({
      type: args.type,
      thread_id: refEmailId || null,
      ref_email_id: refEmailId || null,
      summary: typeof args.payload.summary === "string"
        ? args.payload.summary
        : null,
      metadata: {
        inbound_type: args.payload.inbound ?? null,
        tracks: args.payload.tracks ?? null,
        deadlines: args.payload.deadlines ?? null,
      },
      occurred_at: occurredAt,
      // Legacy `ts` kept for backwards compat with existing readers
      // that still use the case-auto-patch shape.
      ts: occurredAt,
    });
    await sb
      .from("user_cases")
      .update({ timeline: tl })
      .eq("id", args.case_id)
      .eq("user_id", args.user_id);
  } catch (_e) { /* swallow */ }

  // Sidecar: also write the typed event to `case_timeline_events`. This
  // is the table the client-facing Case Timeline UI reads from. Best-
  // effort — RPC failure must not collapse triage (the user_cases.timeline
  // jsonb write above is the canonical record; this is for fast filtered
  // reads + idempotency dedupe).
  try {
    const refEmailIdLocal = String(args.payload?.thread_id ?? "");
    const triageId = typeof args.payload.triage_id === "string"
      ? args.payload.triage_id
      : null;
    const dedupeKey = triageId
      ? `triage:${triageId}`
      : (refEmailIdLocal
        ? `thread:${refEmailIdLocal}:${args.type}`
        : null);
    const severity = typeof args.payload.severity === "string"
      ? args.payload.severity
      : "review";
    const title = `AI triage: ${severity}`;
    const summary = typeof args.payload.summary === "string"
      ? args.payload.summary
      : (typeof args.payload.inbound === "string"
        ? `Inbound classified as ${args.payload.inbound}`
        : null);
    await sb.rpc("record_case_event", {
      p_case_id: args.case_id,
      p_event_type: "consilium_decision",
      p_title: title,
      p_summary: summary,
      p_payload: {
        thread_id: refEmailIdLocal || null,
        triage_id: triageId,
        severity: args.payload.severity ?? null,
        posture: args.payload.posture ?? null,
        send_recommendation: args.payload.send_recommendation ?? null,
        inbound: args.payload.inbound ?? null,
        tracks: args.payload.tracks ?? null,
        deadlines: args.payload.deadlines ?? null,
        dedupe_key: dedupeKey,
      },
    });
  } catch (_e) { /* swallow — sidecar */ }
}

/**
 * Carry-over Task 5: apply `<memory_update>` entries from the parsed
 * Sonnet output back to `user_settings.own_counsel_emails`.
 *
 * Match keys (case-insensitive):
 *   - "own_counsel_email"         (singular, primary)
 *   - "own_counsel_emails"        (plural — alias)
 *   - "confirmed_attorney_email"  (alternative spelling some prompt
 *                                  variants emit)
 *
 * Confidence gate: only `high` or `medium` confidence updates are
 * applied — a `low`-confidence guess from the model must not promote a
 * stranger to own-counsel status.
 */
export async function applyMemoryUpdatesReal(
  // deno-lint-ignore no-explicit-any
  sb: any,
  userId: string,
  updates: MemoryUpdate[],
): Promise<void> {
  if (!userId || !Array.isArray(updates) || updates.length === 0) return;

  const newEmails: string[] = [];
  for (const u of updates) {
    const key = (u.key ?? "").toLowerCase().trim();
    const isOwnCounsel =
      key === "own_counsel_email" ||
      key === "own_counsel_emails" ||
      key === "confirmed_attorney_email";
    if (!isOwnCounsel) continue;
    if (u.confidence !== "high" && u.confidence !== "medium") continue;
    const value = (u.value ?? "").trim().toLowerCase();
    if (!isLikelyEmail(value)) continue;
    newEmails.push(value);
  }
  if (newEmails.length === 0) return;

  try {
    // Read existing row (may not exist).
    const { data: existing } = await sb
      .from("user_settings")
      .select("user_id, own_counsel_emails")
      .eq("user_id", userId)
      .maybeSingle();
    const current: string[] = Array.isArray(existing?.own_counsel_emails)
      ? existing!.own_counsel_emails as string[]
      : [];
    const merged = Array.from(new Set([
      ...current.map((s) => String(s ?? "").trim().toLowerCase())
        .filter((s) => s.length > 0),
      ...newEmails,
    ]));
    if (merged.length === current.length &&
        merged.every((e) => current.includes(e))) {
      // No-op: nothing new to write.
      return;
    }
    if (existing?.user_id) {
      await sb
        .from("user_settings")
        .update({ own_counsel_emails: merged })
        .eq("user_id", userId);
    } else {
      await sb
        .from("user_settings")
        .insert({ user_id: userId, own_counsel_emails: merged });
    }
  } catch (_e) { /* swallow */ }
}

function isLikelyEmail(s: string): boolean {
  // Conservative — anchor on `@`, require a dot in the domain, no
  // whitespace, length 5..254 (RFC 3696 practical bound).
  if (s.length < 5 || s.length > 254) return false;
  if (/\s/.test(s)) return false;
  const at = s.indexOf("@");
  if (at <= 0 || at === s.length - 1) return false;
  const domain = s.slice(at + 1);
  if (!domain.includes(".")) return false;
  return true;
}

// =============================================================================
// Phase 2 Pkg 5 — Conversation State Machine integration
// =============================================================================
//
// Spec: docs/architecture/phase2-pkg5-state-machine.md §8.
//
// When email-triage classifies an inbound thread that is mapped to a
// case, AND that case is currently in `wait`, AND the triage severity
// is HIGH or CRITICAL, flip the case from `wait` → `strategy`. The
// rationale: an HIGH/CRITICAL inbound on a case the user was waiting
// on is exactly the "external event arrived" signal that should pull
// the user back into active strategy mode.
//
// Soft-fail: any RPC error or RLS reject is swallowed (logged) — the
// triage critical path must not depend on phase mechanics.
//
// Pinned by `__tests__/wiring_test.ts` Pkg 5 group.

/** Severity values that warrant a wait → strategy transition. */
const _PHASE_FLIP_SEVERITIES = new Set(["HIGH", "CRITICAL"]);

/**
 * Pkg 5 — flip a case from `wait` to `strategy` when an inbound email
 * thread mapped to that case is triaged at HIGH/CRITICAL severity.
 *
 * Returns the resulting transition shape from `set_case_phase` so
 * tests can assert behaviour, or `null` on any guard miss / error
 * (best-effort by design).
 *
 * Guards (in order — first miss returns `null` without an RPC call):
 *   1. case_id is non-null (unmapped threads are no-ops).
 *   2. severity is HIGH or CRITICAL.
 *   3. The case is currently in `wait` (no other phase is auto-flipped
 *      from email triage — that prevents accidentally pulling a case
 *      out of `draft` mid-letter).
 *
 * Calls the `set_case_phase` RPC with the service-role client. The
 * RPC itself is `security invoker`, but the email-triage edge fn
 * already runs server-side under the service-role client so we
 * preserve the same boundary as `agent_intentions` writes.
 */
export async function maybeTransitionWaitToStrategyOnInbound(
  // deno-lint-ignore no-explicit-any
  sb: any,
  args: {
    case_id: string | null;
    severity: string | null;
    triage_id: string | null;
    thread_id: string | null;
  },
): Promise<{ changed: boolean; from?: string; to?: string } | null> {
  if (!args.case_id) return null;
  if (!args.severity) return null;
  if (!_PHASE_FLIP_SEVERITIES.has(args.severity.toUpperCase())) return null;

  // Read current phase. We could let `set_case_phase` no-op via its
  // own current-phase check, but explicit pre-read keeps the trigger
  // surface narrow (only flip wait → strategy, never anything else
  // from this hook).
  let currentPhase: string | null = null;
  try {
    const { data, error } = await sb
      .from("user_cases")
      .select("phase")
      .eq("id", args.case_id)
      .maybeSingle();
    if (error || !data) return null;
    currentPhase = (data.phase as string | null) ?? null;
  } catch (_e) {
    return null;
  }
  if (currentPhase !== "wait") return null;

  // Idempotency: set_case_phase itself is a no-op when current === target.
  // Source attribution lives in phase_metadata so support / audit can
  // reconstruct WHY a case shifted out of `wait` without touching the
  // triage table.
  try {
    const { data, error } = await sb.rpc("set_case_phase", {
      p_case_id: args.case_id,
      p_phase: "strategy",
      p_metadata: {
        reason: "email_triage_inbound_high_severity",
        source: "email-triage",
        severity: args.severity.toUpperCase(),
        triage_id: args.triage_id,
        thread_id: args.thread_id,
      },
    });
    if (error) {
      // Log via console.warn so the edge fn log stream surfaces the
      // failure but the triage Response stays 200 — phase flip is
      // best-effort.
      console.warn(
        `email-triage: set_case_phase error (${args.case_id}): ` +
          String(error.message ?? error).slice(0, 200),
      );
      return null;
    }
    if (data && typeof data === "object" && !Array.isArray(data)) {
      const obj = data as Record<string, unknown>;
      if (obj.changed === true) {
        return {
          changed: true,
          from: typeof obj.from === "string" ? obj.from : currentPhase,
          to: typeof obj.to === "string" ? obj.to : "strategy",
        };
      }
      return { changed: false };
    }
    return null;
  } catch (e) {
    console.warn(
      `email-triage: set_case_phase threw (${args.case_id}): ` +
        String(e).slice(0, 200),
    );
    return null;
  }
}

/** Wrap a Supabase query promise so a thrown error becomes `null`. */
async function safeQuery<T>(
  // deno-lint-ignore no-explicit-any
  p: PromiseLike<{ data: any; error: unknown }>,
): Promise<T | null> {
  try {
    const { data, error } = await p;
    if (error) return null;
    return data as T;
  } catch (_e) {
    return null;
  }
}
