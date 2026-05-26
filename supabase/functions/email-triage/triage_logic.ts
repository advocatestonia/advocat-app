// email-triage/triage_logic.ts
// -----------------------------------------------------------------------------
// Pure orchestration for the D4 triage flow. Anthropic, Supabase, and the
// quota check are injected via `MinimalTriageDeps` so the loop can be
// unit-tested without booting the HTTP listener or hitting a real model.
//
// Steps (per OPERATOR_PROMPT §4):
//   1. Load thread + last-5-messages + active case + memory block + law RAG
//   2. Quota check (`check-ai-quota` mirror, kind=email_triage)
//   3. Privilege pre-classify (Rule 16.bis own_counsel_advisory routing)
//   4. Sonnet 4.6 invocation with prompt caching on the static prefix
//   5. Parse 6 mandatory + 4 optional blocks
//   6. Reviewer regex pass — regenerate ONCE on failure
//   7. Severity computation
//   8. Build `email_triage_results` row + Phase 1 hard-cap to
//      hold_for_user_review
//   9. Persist + write to case_events / agent_intentions when applicable
// -----------------------------------------------------------------------------

import {
  parseAgentBlocks,
  type ParsedTriage,
  type ParseResult,
  type Severity,
  computeSeverity,
} from "./parse_blocks.ts";
import type { InboundAttachment } from "./wiring.ts";
import { runReviewerLocal, type ReviewerResult } from "./reviewer.ts";
import { classifyPrivilege, type PrivilegePreClass } from "./privilege.ts";
import {
  canonicaliseRecipientSet,
  evaluatePolicyGate,
  type GateInput,
  type GateResult,
  issueGateToken,
  sha256Hex,
} from "./policy_gate.ts";
import {
  KNOWN_COURTS_DEFAULT,
  pickPromptVersion,
  PRIVILEGED_DOMAINS_DEFAULT,
} from "../_shared/email_agent_prompt.ts";
// Parallel Actions Panel (2026-05-25) — when the consilium synthesis emits a
// `<proposed_actions>` block with N>=2 child `<action>` entries, the inbox UI
// renders a grouped card with batch-approve. The extractor is additive and
// degrades to a single-action fallback built from the legacy draft_* fields,
// so the existing single-draft path keeps working unchanged.
import {
  extractProposedActions,
  serialiseProposedActions,
} from "../_shared/parallel_actions.ts";

// =============================================================================
// Inputs / outputs
// =============================================================================

export interface ThreadRecord {
  id: string;
  user_id: string;
  case_id: string | null;
  subject: string | null;
  participants: string[];
  messages: ThreadMessage[];
}

export interface ThreadMessage {
  id: string;
  gmail_message_id: string;
  sender_email: string;
  sender_name: string | null;
  to_recipients: string[];
  cc_recipients: string[];
  subject: string | null;
  body_plaintext: string | null;
  sent_at: string;
  has_attachments: boolean;
  attachments_meta: unknown[];
  headers_meta: Record<string, string>;
}

export interface UserPrefs {
  preferred_language: string;
  signature: Record<string, string>;
  tone?: string;
  timezone?: string;
  auto_send_opt_in?: boolean;
  allowed_auto_send_categories?: string[];
}

export interface MemoryBlock {
  identity_markers?: Record<string, string>;
  dead_addresses?: Array<{ from: string; to: string }>;
  own_counsel_emails?: string[];
  known_privileged_individuals?: string[];
  relations?: unknown;
  recent_owner_feedback?: string;
}

export interface QuotaResult {
  allowed: boolean;
  remaining: number | null;
  plan: "free" | "basic" | "premium" | "pro";
}

export interface AnthropicCallArgs {
  systemBlocks: Array<{ type: "text"; text: string; cache_control?: { type: "ephemeral"; ttl?: string } }>;
  userMessage: string;
  maxTokens: number;
  temperature: number;
}

export interface AnthropicResponse {
  content: string;
  input_tokens: number;
  output_tokens: number;
  cache_read_input_tokens?: number;
  cache_creation_input_tokens?: number;
  /**
   * NEW (2026-05-25): when the triage run was routed through the 15-lawyer
   * consilium (EMAIL_TRIAGE_USE_CONSILIUM=true), this carries the per-role
   * opinion payloads so the orchestrator can persist them to
   * `email_triage_results.lawyer_opinions` for audit. `undefined` on the
   * legacy single-Sonnet path.
   *
   * Shape mirrors the consilium SSE `role_opinion` event payload
   * (`ConsiliumRoleOpinionPayload` in _shared/consilium.ts) so the audit row
   * is a faithful capture of what the UI would have rendered if the
   * consilium had been streamed live. Empty array on consilium runs where
   * no role produced an opinion (e.g. all roles failed → sentinel only).
   */
  lawyer_opinions?: LawyerOpinion[];
  /**
   * NEW (2026-05-25): the consilium chairman's synthesis text. Stored
   * verbatim on the audit row alongside the structured blocks so reviewers
   * can compare the synthesis the consilium produced against the v1.1-final
   * blocks the orchestrator parses. `undefined` on the legacy path.
   */
  consilium_synthesis?: string;
}

/**
 * Per-lawyer audit record. One entry per role that produced an opinion.
 * Persisted to `email_triage_results.lawyer_opinions` as a JSONB array.
 * Field names match `ConsiliumRoleOpinionPayload` from
 * supabase/functions/_shared/consilium.ts so the audit row is a faithful
 * capture of the SSE wire shape (FLAT, 2026-05-25).
 */
export interface LawyerOpinion {
  role_id: string;
  role_name: string;
  opinion: string;
  position: string;
  confidence: number | null;
  key_citation: string | null;
}

export interface ConsiliumCallArgs {
  /** Original v1.1-final system blocks (cached prefix + dynamic context). */
  systemBlocks: AnthropicCallArgs["systemBlocks"];
  /** Triage instruction the orchestrator gives Sonnet. */
  userMessage: string;
  /** Token cap for the FINAL formatting call (after consilium synthesis). */
  maxTokens: number;
  /** Temperature for the FINAL formatting call. */
  temperature: number;
  /**
   * Plain-text user query the consilium routes on. The legacy path passes
   * structured `<context>` to Sonnet; the consilium needs a short natural-
   * language description of the inbound to pick the right lawyer roster.
   * The orchestrator builds this from the latest inbound subject + body
   * snippet so the 11-persona router has keywords to score against.
   */
  consiliumQuery: string;
  /** Forwarded to runConsilium.systemPrompt (base lawyer persona). */
  baseLawyerSystemPrompt: string;
  /** Forwarded to runConsilium.ragContext (law-search chunks). */
  ragContext: string;
  /** Forwarded to runConsilium.caseContext (Pkg 1 case memory). */
  caseContext: string;
  /** Forwarded to runConsilium.caseClassification (typed case context). */
  caseClassification?: unknown;
}

export interface MinimalTriageDeps {
  loadThread(threadId: string): Promise<ThreadRecord | null>;
  loadActiveCase(caseId: string | null): Promise<unknown>;
  loadMemoryBlock(userId: string): Promise<MemoryBlock>;
  loadUserPrefs(userId: string): Promise<UserPrefs>;
  loadLawSearch(query: string): Promise<unknown>;
  /**
   * Fix #2 (2026-05-26) — load parsed text for every PDF attachment on
   * this thread. Returns `[]` when the thread has no attachments OR on
   * any error (DB outage, pdf-parser fault). Triage continues without
   * attachment context in either case — graceful degradation contract
   * identical to `loadLawSearch`.
   *
   * Optional dep — when undefined (e.g. legacy callers / older fixtures)
   * the orchestrator skips the attachment-load entirely. Production
   * `index.ts` wires this via `loadInboundAttachmentTexts` in wiring.ts.
   */
  loadInboundAttachments?(threadId: string): Promise<InboundAttachment[]>;
  /** Returns whether the user may run a triage call. */
  checkQuota(userId: string): Promise<QuotaResult>;
  /** Calls Anthropic. Cache headers handled inside the impl. */
  callSonnet(args: AnthropicCallArgs): Promise<AnthropicResponse>;
  /**
   * Optional — when wired by the caller AND the `EMAIL_TRIAGE_USE_CONSILIUM`
   * env flag is true at runTriage time, the orchestrator routes the
   * Anthropic call through the 15-lawyer consilium (see
   * `supabase/functions/_shared/consilium.ts`).
   *
   * The dep MUST:
   *   1. Run the consilium (Promise.all of N parallel lawyer roles + chairman
   *      synthesis) and collect each role_opinion payload.
   *   2. Then call Sonnet once more with the v1.1-final systemBlocks +
   *      consilium synthesis injected so the final output still matches the
   *      6-mandatory-block schema the parser + reviewer + policy gate
   *      expect.
   *   3. Return an AnthropicResponse whose `content` is the structured
   *      Sonnet output AND populate `lawyer_opinions` + `consilium_synthesis`
   *      for audit.
   *
   * Default-off: when the flag is false (default), the orchestrator never
   * invokes this and the legacy `callSonnet` path runs unchanged. Tests can
   * leave this undefined so the consilium branch is skipped even when the
   * flag is set.
   */
  callConsilium?(args: ConsiliumCallArgs): Promise<AnthropicResponse>;
  /** Persist the row. Returns the new id. */
  persistTriageRow(row: TriageInsertRow): Promise<{ id: string }>;
  /** Mark the thread row triage_status; used after a successful run. */
  markThreadTriageStatus(threadId: string, status: string): Promise<void>;
  /** Best-effort: append to case_events / write memory. Failures swallowed. */
  appendCaseEvent(args: {
    user_id: string;
    case_id: string | null;
    type: string;
    payload: Record<string, unknown>;
  }): Promise<void>;
  /** Schedule an agent_intentions row when the deadline is hot. */
  scheduleAgentIntention(args: {
    user_id: string;
    case_id: string | null;
    intent_type: string;
    next_check_at: string;
    summary: string;
    locale: string;
  }): Promise<void>;
  /**
   * Apply `<memory_update>` block entries to durable per-user storage.
   * Carry-over Task 5 — the system prompt v1.1-final §9.2 learning loop:
   * when the model emits an `own_counsel_email` (or compatible)
   * memory_update, persist it so future triage runs surface it via
   * `loadMemoryBlock`. Optional — production deps fully implement;
   * tests may leave undefined so the behaviour is opt-in per fixture.
   */
  applyMemoryUpdates?(args: {
    user_id: string;
    updates: import("./parse_blocks.ts").MemoryUpdate[];
  }): Promise<void>;
}

export interface TriageInsertRow {
  thread_id: string;
  user_id: string;
  privilege_check: string;
  conflict_check: string;
  triage_track: string | null;
  triage_inbound: string;
  triage_summary: string;
  deadlines: unknown;
  contradictions: unknown;
  evidence_gaps: unknown;
  posture: string;
  user_brief: string;
  actions_required: unknown;
  appeal_route: unknown;
  gdpr_basis: unknown;
  attachments_pending: unknown;
  memory_updates: unknown;
  draft_language: string | null;
  draft_subject: string | null;
  draft_body: string | null;
  draft_to: string[];
  draft_cc: string[];
  send_recommendation: string;
  severity: string;
  prompt_version: string;
  model_id: string;
  raw_model_output: string | null;
  reviewer_status: string | null;
  reviewer_failures: unknown;
  /**
   * NEW (2026-05-25): when EMAIL_TRIAGE_USE_CONSILIUM=true, this holds the
   * per-lawyer opinion payloads captured from the consilium SSE
   * `role_opinion` events. NULL on the legacy single-Sonnet path. JSONB on
   * the database side. See migration
   * 20260525200000_email_triage_lawyer_opinions.sql.
   */
  lawyer_opinions: LawyerOpinion[] | null;
  /**
   * NEW (2026-05-25, Parallel Actions Panel): N>=1 structured actions the
   * consilium proposes. When NULL/omitted, the inbox UI falls back to the
   * legacy single-draft TriageCard. When length>=2, the new
   * ParallelActionsCard renders a grouped card with batch-approve. idx=0
   * always mirrors the legacy draft_* columns so existing API consumers
   * (chat assistant tools, approve_send_draft) keep working. JSONB on the
   * database side. See migration 20260525210000_triage_proposed_actions.sql.
   *
   * Field is optional (`?:`) so callers / tests that haven't been updated
   * yet keep compiling — the persistence layer treats `undefined` and
   * `null` identically (column stays NULL).
   */
  proposed_actions?: Array<Record<string, unknown>> | null;
}

export type TriageOutcome =
  | {
    ok: true;
    triage_id: string;
    severity: Severity;
    send_recommendation: string;
    privilege_check: string;
    posture: string;
    gate_result: GateResult | null;
    gate_token: unknown | null;
    parse_attempts: number;
  }
  | {
    ok: false;
    error_code: string;
    detail?: string;
  };

// =============================================================================
// Build the dynamic <context> portion of the prompt
// =============================================================================

const CONTEXT_BUDGET_BYTES = 80_000;

/** Fix #2 (2026-05-26) — total byte budget for the `<inbound_attachments>`
 *  block. 20 KB ≈ 4 attachments × 5 000 chars. Beyond this we truncate to
 *  the first 3 and append an overflow sentinel so the model knows it's
 *  seeing a slice. Coordinates with `loadInboundAttachmentTexts`'
 *  per-attachment cap (5 000 chars) — together they ensure no single
 *  email thread can blow the 80 KB CONTEXT_BUDGET_BYTES ceiling via
 *  scanned PDFs. */
const INBOUND_ATTACHMENTS_BLOCK_BUDGET_BYTES = 20_000;

/** Visible truncation marker when total attachments exceed budget. */
const INBOUND_ATTACHMENTS_OVERFLOW_SENTINEL = "[…overflow truncated]";

export function buildContextSuffix(args: {
  currentDate: string;
  userEmail: string;
  userLang: string;
  userPrefs: UserPrefs;
  userLastTz: string | null;
  memoryBlock: MemoryBlock;
  activeCase: unknown;
  lawCtx: unknown;
  thread: ThreadRecord;
  ownCounselFlag: boolean;
  /** Fix #2 — text excerpts from `email_attachments` for this thread.
   *  Already capped per-attachment by `loadInboundAttachmentTexts`. */
  inboundAttachments?: InboundAttachment[];
}): string {
  const lines: string[] = [];
  lines.push(`Today: ${args.currentDate}`);
  lines.push(`User email: ${args.userEmail}`);
  lines.push(`User language for briefings: ${args.userLang}`);
  lines.push(`User preferences: ${safeJson(args.userPrefs)}`);
  lines.push(`User last-seen TZ (server-derived): ${args.userLastTz ?? "unknown"}`);
  lines.push(`own_counsel_advisory_for_this_thread: ${args.ownCounselFlag ? "true" : "false"}`);
  lines.push(``);
  lines.push(`Stable memory:`);
  lines.push(safeJson(args.memoryBlock));
  lines.push(``);
  lines.push(`Active case dossier:`);
  lines.push(safeJson(args.activeCase));
  lines.push(``);
  lines.push(`Relevant law (RAG):`);
  lines.push(safeJson(args.lawCtx));
  lines.push(``);
  lines.push(`Email thread (oldest → newest):`);
  lines.push(formatThread(args.thread));
  // Fix #2 — inbound_attachments block lands AFTER <thread> so the model
  // reads the thread context first, then the structured attachment
  // excerpts. Pure additive — when no attachments are surfaced, no block
  // is emitted (zero overhead on the legacy path).
  const attachmentsBlock = formatInboundAttachments(
    args.inboundAttachments ?? [],
  );
  if (attachmentsBlock.length > 0) {
    lines.push(``);
    lines.push(attachmentsBlock);
  }
  return lines.join("\n");
}

/** Render the `<inbound_attachments>` block. Caps total block size to
 *  INBOUND_ATTACHMENTS_BLOCK_BUDGET_BYTES. On overflow → keep first 3
 *  attachments only and append the overflow sentinel. Pure function. */
export function formatInboundAttachments(
  attachments: InboundAttachment[],
): string {
  if (attachments.length === 0) return "";

  const enc = new TextEncoder();
  let pool = attachments;
  let truncated = false;
  if (pool.length > 3) {
    // First-line defence: keep the first three — the rest are appended
    // as a single overflow sentinel below.
    pool = pool.slice(0, 3);
    truncated = true;
  }

  const renderOne = (a: InboundAttachment): string => {
    const safeName = (a.filename ?? "").replace(/"/g, "'");
    const safeMime = (a.mime ?? "application/octet-stream").replace(/"/g, "'");
    return `<attachment filename="${safeName}" mime="${safeMime}">\n${
      a.parsed_text ?? ""
    }\n</attachment>`;
  };

  let body = pool.map(renderOne).join("\n");
  let block = `<inbound_attachments>\n${body}${
    truncated ? `\n${INBOUND_ATTACHMENTS_OVERFLOW_SENTINEL}` : ""
  }\n</inbound_attachments>`;

  // Byte-budget defence — even after dropping to first-3, a single 5KB
  // attachment × 3 + wrappers can land around 15 KB. The 20 KB ceiling
  // gives us room for 4-page legal scans; if we're STILL over (e.g.
  // attachments were not pre-capped because the cache held stale large
  // blobs), drop one attachment at a time until we fit and re-emit the
  // overflow sentinel.
  while (
    enc.encode(block).length > INBOUND_ATTACHMENTS_BLOCK_BUDGET_BYTES &&
    pool.length > 0
  ) {
    pool = pool.slice(0, pool.length - 1);
    truncated = true;
    body = pool.map(renderOne).join("\n");
    block = `<inbound_attachments>\n${body}${
      truncated ? `\n${INBOUND_ATTACHMENTS_OVERFLOW_SENTINEL}` : ""
    }\n</inbound_attachments>`;
  }

  return block;
}

function formatThread(t: ThreadRecord): string {
  const out: string[] = [];
  out.push(`# Subject: ${t.subject ?? "(none)"}`);
  out.push(`# Participants: ${t.participants.join(", ")}`);
  for (const m of t.messages) {
    out.push(`---`);
    out.push(`From: ${m.sender_name ? `${m.sender_name} <${m.sender_email}>` : m.sender_email}`);
    out.push(`To: ${m.to_recipients.join(", ")}`);
    if (m.cc_recipients.length > 0) out.push(`Cc: ${m.cc_recipients.join(", ")}`);
    out.push(`Sent: ${m.sent_at}`);
    out.push(`Subject: ${m.subject ?? ""}`);
    if (m.has_attachments) {
      out.push(
        `Attachments: ${(m.attachments_meta as Array<{ filename?: string }>)
          .map((a) => a.filename ?? "(unnamed)")
          .join(", ")}`,
      );
    }
    out.push(``);
    out.push(m.body_plaintext ?? "(empty body)");
  }
  return out.join("\n");
}

function safeJson(v: unknown): string {
  try {
    return JSON.stringify(v ?? null, null, 2);
  } catch (_) {
    return "{}";
  }
}

// =============================================================================
// Build the system blocks (cached static prefix + dynamic suffix)
// =============================================================================

export function buildSystemBlocks(contextSuffix: string): Array<{
  type: "text";
  text: string;
  cache_control?: { type: "ephemeral"; ttl?: string };
}> {
  // Replace placeholders in the static prefix with their constants; the
  // remaining dynamic placeholders inside <context> are NOT in the cached
  // prefix because <context> lives outside the cache boundary in the
  // prompt body. We split on the closing `</memory_protocol>` boundary
  // (per spec §685) and substitute the build-time domain lists.
  // Track E (v2.1 consilium, 2026-05-07): prompt version is picked at
  // runtime from EMAIL_AGENT_PROMPT_VERSION env var (defaults to
  // v1.1-final). v1.2-final adds Rules 31–35 — flip via Supabase secret
  // after staging soak.
  //
  // TTL pinned to "1h" — Anthropic silently regressed the cache_control
  // default from 1h to 5m in March 2026. Email triage prompt prefix is
  // ~30KB of stable system rules; without an explicit TTL each thread's
  // follow-up replies (often 10-60 min apart) miss the 5m window. The 2x
  // write premium pays back inside the first cached re-triage of the
  // thread. Keep in sync with claude-proxy/prompt_caching.ts CACHE_TTL.
  const { prompt: activePrompt } = pickPromptVersion();
  const prefixRaw = activePrompt
    .split(/<context>[\s\S]*<\/context>/)[0]
    .replace(/\{\{PRIVILEGED_DOMAINS\}\}/g, PRIVILEGED_DOMAINS_DEFAULT.join(", "))
    .replace(/\{\{KNOWN_COURTS\}\}/g, KNOWN_COURTS_DEFAULT.join(", "));
  // Append a fresh <context>...</context> as the dynamic suffix.
  const dynamic = `\n<context>\n${contextSuffix}\n</context>\n`;
  return [
    {
      type: "text",
      text: prefixRaw,
      cache_control: { type: "ephemeral", ttl: "1h" },
    },
    {
      type: "text",
      text: dynamic,
    },
  ];
}

// =============================================================================
// Top-level loop
// =============================================================================

export interface RunTriageArgs {
  thread_id: string;
  user_id: string;
  /**
   * `false` for Phase 1 (auto-send disabled — every result lands as
   * `hold_for_user_review`). The gate still runs + emits a token for
   * audit, but the call-site does not consume it.
   */
  auto_send_enabled: boolean;
  /** Required at issue-token time. Provided by the caller from env. */
  gate_secret: string;
}

export async function runTriage(
  deps: MinimalTriageDeps,
  args: RunTriageArgs,
): Promise<TriageOutcome> {
  const thread = await deps.loadThread(args.thread_id);
  if (!thread) {
    return { ok: false, error_code: "thread_not_found" };
  }
  if (thread.user_id !== args.user_id) {
    return { ok: false, error_code: "thread_user_mismatch" };
  }
  if (thread.messages.length === 0) {
    return { ok: false, error_code: "empty_thread" };
  }

  const quota = await deps.checkQuota(args.user_id);
  if (!quota.allowed) {
    return { ok: false, error_code: "quota_exhausted" };
  }

  const [activeCase, memBlock, prefs, lawCtx, inboundAttachments] =
    await Promise.all([
      deps.loadActiveCase(thread.case_id),
      deps.loadMemoryBlock(args.user_id),
      deps.loadUserPrefs(args.user_id),
      deps.loadLawSearch(extractLegalKeywords(thread)),
      // Fix #2 — bridge email_attachments → pdf-parser → triage context.
      // Optional dep: when undefined (older fixtures / tests) the loader
      // is skipped and the attachments block is omitted from the prompt.
      deps.loadInboundAttachments
        ? deps.loadInboundAttachments(args.thread_id).catch(() =>
          [] as InboundAttachment[]
        )
        : Promise.resolve([] as InboundAttachment[]),
    ]);

  // Latest inbound message — what we actually triage (per <definitions>).
  const inbound = pickLatestInbound(thread, prefs);
  const privClass: PrivilegePreClass = classifyPrivilege({
    sender_email: inbound.sender_email,
    sender_name: inbound.sender_name,
    body_plaintext: inbound.body_plaintext,
    reply_to: inbound.headers_meta["Reply-To"] ?? null,
    privileged_domains: PRIVILEGED_DOMAINS_DEFAULT,
    own_counsel_emails: memBlock.own_counsel_emails ?? [],
  });

  const contextSuffix = buildContextSuffix({
    currentDate: new Date().toISOString().slice(0, 10),
    userEmail: prefs.signature?.["en"] ? "" : "", // owner email is in user JWT context
    userLang: prefs.preferred_language ?? "en",
    userPrefs: prefs,
    userLastTz: prefs.timezone ?? null,
    memoryBlock: memBlock,
    activeCase,
    lawCtx,
    thread,
    ownCounselFlag: privClass.is_own_counsel,
    inboundAttachments,
  });

  if (
    new TextEncoder().encode(contextSuffix).length > CONTEXT_BUDGET_BYTES
  ) {
    // Truncation policy is left to the caller's `loadActiveCase` /
    // `loadLawSearch` impls; we hard-fail here only when the suffix
    // BLOWS the 80 KB ceiling so the caller knows to trim aggressively.
    return { ok: false, error_code: "context_overflow", detail: "context_budget_exceeded" };
  }

  const systemBlocks = buildSystemBlocks(contextSuffix);
  const userMessage = "Triage the email thread inside <context>.";

  // 2026-05-25: consilium routing. When EMAIL_TRIAGE_USE_CONSILIUM=true AND
  // the caller wired `deps.callConsilium`, route the model call through the
  // 15-lawyer consilium pipeline. Default-off — legacy single-Sonnet path
  // stays untouched.
  //
  // Why two flags (env + dep-wiring)? The env flag is the runtime toggle.
  // The dep-wiring is the "did the caller plug in the impl" check — keeps
  // tests purely opt-in without env juggling.
  const useConsilium = isConsiliumEnabled() && typeof deps.callConsilium === "function";
  const consiliumQuery = buildConsiliumQuery(thread, inbound);

  let parseAttempts = 0;
  let raw = "";
  let parseResult: ParseResult | null = null;
  let reviewer: ReviewerResult | null = null;
  let parsed: ParsedTriage | null = null;
  let capturedLawyerOpinions: LawyerOpinion[] | null = null;
  let capturedConsiliumSynthesis: string | null = null;

  for (const attempt of [1, 2]) {
    parseAttempts = attempt;
    const resp = useConsilium
      ? await deps.callConsilium!({
          systemBlocks,
          userMessage,
          maxTokens: 4096,
          temperature: 0.0,
          consiliumQuery,
          baseLawyerSystemPrompt: systemBlocks.map((b) => b.text).join("\n"),
          ragContext: typeof lawCtx === "string" ? lawCtx : safeJson(lawCtx),
          caseContext: typeof activeCase === "string" ? activeCase : safeJson(activeCase),
          caseClassification: undefined,
        })
      : await deps.callSonnet({
          systemBlocks,
          userMessage,
          maxTokens: 4096,
          temperature: 0.0,
        });
    raw = resp.content;
    // Capture consilium audit fields on the FIRST successful attempt — the
    // regeneration path keeps the original opinions (re-running the
    // consilium for a formatting retry would be wasteful).
    if (
      useConsilium && capturedLawyerOpinions === null &&
      Array.isArray(resp.lawyer_opinions)
    ) {
      capturedLawyerOpinions = resp.lawyer_opinions;
    }
    if (
      useConsilium && capturedConsiliumSynthesis === null &&
      typeof resp.consilium_synthesis === "string"
    ) {
      capturedConsiliumSynthesis = resp.consilium_synthesis;
    }
    parseResult = parseAgentBlocks(raw);
    if (!parseResult.ok) {
      if (attempt === 1) continue; // regenerate once
      return {
        ok: false,
        error_code: "parse_failed",
        detail: parseResult.message,
      };
    }
    parsed = parseResult.parsed;
    reviewer = runReviewerLocal(parsed, inbound.subject ?? "");
    if (reviewer.ok) break;
    if (attempt === 2) {
      // Reviewer still failing — persist as hold_for_user_review with
      // reviewer_failures, surface to user. Do NOT block the row write.
      break;
    }
  }

  if (!parsed) {
    return { ok: false, error_code: "parse_failed_unknown" };
  }

  const severity: Severity = computeSeverity(parsed);

  // Phase 1: hard-cap auto_send_eligible -> hold_for_user_review
  let finalSendRec: string = parsed.send_recommendation;
  if (!args.auto_send_enabled && finalSendRec === "auto_send_eligible") {
    finalSendRec = "hold_for_user_review";
  }

  // Run the policy gate even when send is disabled — the audit trail
  // benefits from knowing what would have happened.
  let gateResult: GateResult | null = null;
  let gateToken: unknown | null = null;
  if (parsed.send_recommendation === "auto_send_eligible" && parsed.draft) {
    const gateInput: GateInput = {
      draft: {
        category: inferDraftCategory(parsed),
        body: parsed.draft.body,
        body_sha256_from_model: undefined, // model never emits a hash; gate hashes live body
        to: parsed.draft.to,
        cc: parsed.draft.cc,
        subject: parsed.draft.subject,
      },
      user: {
        user_id: args.user_id,
        email: prefs.signature?.["en"] ?? "",
        timezone: prefs.timezone ?? null,
        last_seen_tz: prefs.timezone ?? null,
        allowed_auto_send_categories: prefs.allowed_auto_send_categories ?? [],
        daily_auto_send_count: 0,
        daily_auto_send_cap: 5,
        ai_spend_today_usd: 0,
        ai_spend_cap_usd: 10,
      },
      case_flags: {
        suicide_risk_screening_positive: false,
        mental_health_sensitive: false,
      },
      thread: {
        participants: thread.participants,
        known_courts: KNOWN_COURTS_DEFAULT,
        inbound_sender_email: inbound.sender_email,
      },
      now: new Date(),
    };
    gateResult = evaluatePolicyGate(gateInput);
    if (gateResult.pass) {
      const sha = await sha256Hex(parsed.draft.body);
      gateToken = await issueGateToken({
        draft_id: `pending-${args.thread_id}`,
        body_sha256: sha,
        recipients: [...parsed.draft.to, ...parsed.draft.cc],
        secret: args.gate_secret,
      });
    } else {
      // Gate blocked — degrade send_recommendation regardless of Phase 1.
      finalSendRec = "hold_for_user_review";
    }
  }

  // Build the row + persist
  const row: TriageInsertRow = {
    thread_id: args.thread_id,
    user_id: args.user_id,
    privilege_check: parsed.privilege_check,
    conflict_check: parsed.conflict_check,
    triage_track: parsed.triage.track[0] ?? null,
    triage_inbound: parsed.triage.inbound,
    triage_summary: parsed.triage.reasoning,
    deadlines: parsed.triage.deadlines,
    contradictions: parsed.triage.contradictions,
    evidence_gaps: parsed.triage.evidence_gaps,
    posture: parsed.triage.posture,
    user_brief: parsed.user_brief,
    actions_required: parsed.actions_required,
    appeal_route: parsed.appeal_route,
    gdpr_basis: parsed.gdpr_basis,
    attachments_pending: parsed.attachments,
    memory_updates: parsed.memory_updates,
    draft_language: parsed.draft?.language ?? null,
    draft_subject: parsed.draft?.subject ?? null,
    draft_body: parsed.draft?.body ?? null,
    draft_to: parsed.draft?.to ?? [],
    draft_cc: parsed.draft?.cc ?? [],
    send_recommendation: finalSendRec,
    severity,
    prompt_version: pickPromptVersion().version,
    model_id: "claude-sonnet-4-6",
    raw_model_output: raw.slice(0, 30_000),
    reviewer_status: reviewer == null
      ? null
      : reviewer.ok
        ? (parseAttempts === 1 ? "passed" : "regenerated")
        : "flagged",
    reviewer_failures: reviewer?.failures ?? [],
    lawyer_opinions: capturedLawyerOpinions,
  };
  // When the consilium synthesis is available, append it to the
  // raw_model_output audit field so reviewers can diff the synthesis
  // against the v1.1-final structured blocks the parser consumed. We keep
  // the structured blocks first (the parser-relevant payload) and the
  // synthesis appended under a clear sentinel so future tooling can split
  // them deterministically.
  if (capturedConsiliumSynthesis) {
    const sentinel = "\n\n<!-- consilium_synthesis (audit) -->\n";
    const combined = `${raw}${sentinel}${capturedConsiliumSynthesis}`;
    row.raw_model_output = combined.slice(0, 30_000);
  }

  // Parallel Actions Panel — derive structured action list from the
  // consilium synthesis when available, else from the legacy single draft.
  // Persist only when there are >=2 actions (single-action rows can be
  // served entirely from the legacy draft_* columns; the JSONB column
  // stays NULL so older inbox consumers and the partial index stay tiny).
  // Never block persistence on failure — the extractor catches nothing,
  // but defensive try/catch matches the rest of the orchestrator's
  // best-effort sidecar style.
  try {
    const proposed = extractProposedActions({
      synthesis: capturedConsiliumSynthesis ?? "",
      legacyDraft: parsed.draft
        ? {
          to_addr: parsed.draft.to[0] ?? "",
          cc: parsed.draft.cc,
          subject: parsed.draft.subject,
          body: parsed.draft.body,
          language: parsed.draft.language,
          rationale: parsed.user_brief,
          citations: [],
          gate_token: gateToken,
        }
        : undefined,
    });
    if (proposed.length >= 2) {
      row.proposed_actions = serialiseProposedActions(proposed);
    }
  } catch (_e) { /* ignore */ }

  const insert = await deps.persistTriageRow(row);

  // Carry-over Task 5: write-back loop. The model can promote facts it
  // discovered during triage (e.g. "this Jokela address is now confirmed
  // own counsel") into per-user durable storage. Best-effort — failure
  // here must not collapse the triage row, which has already been
  // persisted.
  if (deps.applyMemoryUpdates && parsed.memory_updates.length > 0) {
    try {
      await deps.applyMemoryUpdates({
        user_id: args.user_id,
        updates: parsed.memory_updates,
      });
    } catch (_e) { /* ignore */ }
  }

  // Update thread + sidecar writes (best-effort)
  const threadStatus = finalSendRec === "archive" ? "archived" : "triaged";
  try {
    await deps.markThreadTriageStatus(args.thread_id, threadStatus);
  } catch (_e) { /* ignore */ }
  try {
    await deps.appendCaseEvent({
      user_id: args.user_id,
      case_id: thread.case_id,
      type: "inbound_classified",
      payload: {
        thread_id: args.thread_id,
        triage_id: insert.id,
        inbound: parsed.triage.inbound,
        tracks: parsed.triage.track,
        deadlines: parsed.triage.deadlines,
        severity,
        reviewer_status: row.reviewer_status,
      },
    });
  } catch (_e) { /* ignore */ }

  // Schedule a hot-deadline intention if any deadline ≤ 7 days.
  const hotDeadline = parsed.triage.deadlines.find((d) =>
    typeof d.delta_days === "number" && d.delta_days <= 7
  );
  if (hotDeadline) {
    try {
      const checkAt = new Date(Date.now() + 60 * 60 * 1000); // +1h
      await deps.scheduleAgentIntention({
        user_id: args.user_id,
        case_id: thread.case_id,
        intent_type: "remind_deadline",
        next_check_at: checkAt.toISOString(),
        summary: `${parsed.triage.inbound} — ${hotDeadline.description}`.slice(0, 500),
        locale: prefs.preferred_language === "ru"
          ? "ru"
          : prefs.preferred_language === "et"
            ? "et"
            : "en",
      });
    } catch (_e) { /* ignore */ }
  }

  return {
    ok: true,
    triage_id: insert.id,
    severity,
    send_recommendation: finalSendRec,
    privilege_check: parsed.privilege_check,
    posture: parsed.triage.posture,
    gate_result: gateResult,
    gate_token: gateToken,
    parse_attempts: parseAttempts,
  };
}

// =============================================================================
// Helpers
// =============================================================================

/** Pick the most-recent message NOT from the user. Falls back to last. */
export function pickLatestInbound(
  thread: ThreadRecord,
  _prefs: UserPrefs,
): ThreadMessage {
  const sorted = [...thread.messages].sort((a, b) =>
    a.sent_at.localeCompare(b.sent_at)
  );
  // We don't reliably know the user's email at this layer; the dynamic
  // <context> contains it. Heuristic: pick the latest message.
  return sorted[sorted.length - 1];
}

/** Cheap keyword extraction for law-search. */
export function extractLegalKeywords(thread: ThreadRecord): string {
  const subject = thread.subject ?? "";
  const lastBody = thread.messages[thread.messages.length - 1]?.body_plaintext
    ?? "";
  return `${subject}\n${lastBody.slice(0, 1000)}`;
}

// =============================================================================
// Consilium feature flag + query builder
// =============================================================================

/** Env flag name. Default OFF — the consilium routing is opt-in per-deploy. */
export const CONSILIUM_FLAG_ENV = "EMAIL_TRIAGE_USE_CONSILIUM";

/** Read the consilium feature flag from Deno env. Defaults to false on any
 *  error (e.g. tests with no Deno global). Mirrors the truthy parsing used
 *  by `isLawyerRouterEnabled` in consilium_lawyer_bridge.ts. */
export function isConsiliumEnabled(): boolean {
  try {
    // deno-lint-ignore no-explicit-any
    const env = (globalThis as any).Deno?.env;
    if (!env || typeof env.get !== "function") return false;
    const raw = env.get(CONSILIUM_FLAG_ENV);
    if (!raw) return false;
    const normalised = String(raw).toLowerCase().trim();
    return normalised === "true" || normalised === "1" || normalised === "yes";
  } catch {
    return false;
  }
}

/** Build the plain-text user query the 15-lawyer consilium routes on. The
 *  legacy path passes a full v1.1-final `<context>` block to Sonnet, but the
 *  lawyer router (and the v2.2 DomainExpert selection) operate on natural-
 *  language keywords. We surface the subject + first ~1.5 KB of the latest
 *  inbound body so the router has enough signal to score domain experts.
 *  Pure function — no I/O. */
export function buildConsiliumQuery(
  thread: ThreadRecord,
  inbound: ThreadMessage,
): string {
  const lines: string[] = [];
  lines.push(`Subject: ${thread.subject ?? inbound.subject ?? "(none)"}`);
  if (inbound.sender_email) {
    lines.push(`From: ${inbound.sender_email}`);
  }
  const body = (inbound.body_plaintext ?? "").trim();
  if (body) {
    lines.push("");
    lines.push(body.slice(0, 1500));
  }
  return lines.join("\n");
}

/** Heuristic — map model output to a draft category. */
export function inferDraftCategory(parsed: ParsedTriage): string {
  const body = (parsed.draft?.body ?? "").toLowerCase();
  const subject = (parsed.draft?.subject ?? "").toLowerCase();
  const corpus = `${subject}\n${body}`;
  if (
    /vahvistan vastaanottaneeni|kinnitan kättesaamist|confirm receipt|acknowledg/i
      .test(corpus)
  ) return "acknowledgement";
  if (
    /päätös vastaanotettu|otsus saadud|document.*received|liite vastaanotettu/i
      .test(corpus)
  ) return "document_receipt";
  if (
    /uudelleenajoittaa|vastaanottoaika|reschedule/i.test(corpus)
  ) return "calendar_reschedule";
  if (
    /toimitan.*viimeistään|will provide.*by|esitan.*hiljemalt/i.test(corpus)
  ) return "will_provide_by_date_deferral";
  if (
    /uudelleenlähetys|re-?send|kordussaadetis/i.test(corpus)
  ) return "bounce_resend";
  return "other";
}
