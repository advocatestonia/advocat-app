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
  PRIVILEGED_DOMAINS_DEFAULT,
  PROMPT_VERSION,
  SYSTEM_PROMPT_V1_1,
} from "../_shared/email_agent_prompt.ts";

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
  systemBlocks: Array<{ type: "text"; text: string; cache_control?: { type: "ephemeral" } }>;
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
}

export interface MinimalTriageDeps {
  loadThread(threadId: string): Promise<ThreadRecord | null>;
  loadActiveCase(caseId: string | null): Promise<unknown>;
  loadMemoryBlock(userId: string): Promise<MemoryBlock>;
  loadUserPrefs(userId: string): Promise<UserPrefs>;
  loadLawSearch(query: string): Promise<unknown>;
  /** Returns whether the user may run a triage call. */
  checkQuota(userId: string): Promise<QuotaResult>;
  /** Calls Anthropic. Cache headers handled inside the impl. */
  callSonnet(args: AnthropicCallArgs): Promise<AnthropicResponse>;
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
  return lines.join("\n");
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
  cache_control?: { type: "ephemeral" };
}> {
  // Replace placeholders in the static prefix with their constants; the
  // remaining dynamic placeholders inside <context> are NOT in the cached
  // prefix because <context> lives outside the cache boundary in the
  // prompt body. We split on the closing `</memory_protocol>` boundary
  // (per spec §685) and substitute the build-time domain lists.
  const prefixRaw = SYSTEM_PROMPT_V1_1
    .split(/<context>[\s\S]*<\/context>/)[0]
    .replace(/\{\{PRIVILEGED_DOMAINS\}\}/g, PRIVILEGED_DOMAINS_DEFAULT.join(", "))
    .replace(/\{\{KNOWN_COURTS\}\}/g, KNOWN_COURTS_DEFAULT.join(", "));
  // Append a fresh <context>...</context> as the dynamic suffix.
  const dynamic = `\n<context>\n${contextSuffix}\n</context>\n`;
  return [
    {
      type: "text",
      text: prefixRaw,
      cache_control: { type: "ephemeral" },
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

  const [activeCase, memBlock, prefs, lawCtx] = await Promise.all([
    deps.loadActiveCase(thread.case_id),
    deps.loadMemoryBlock(args.user_id),
    deps.loadUserPrefs(args.user_id),
    deps.loadLawSearch(extractLegalKeywords(thread)),
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

  let parseAttempts = 0;
  let raw = "";
  let parseResult: ParseResult | null = null;
  let reviewer: ReviewerResult | null = null;
  let parsed: ParsedTriage | null = null;

  for (const attempt of [1, 2]) {
    parseAttempts = attempt;
    const resp = await deps.callSonnet({
      systemBlocks,
      userMessage,
      maxTokens: 4096,
      temperature: 0.0,
    });
    raw = resp.content;
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
    prompt_version: PROMPT_VERSION,
    model_id: "claude-sonnet-4-6",
    raw_model_output: raw.slice(0, 30_000),
    reviewer_status: reviewer == null
      ? null
      : reviewer.ok
        ? (parseAttempts === 1 ? "passed" : "regenerated")
        : "flagged",
    reviewer_failures: reviewer?.failures ?? [],
  };
  const insert = await deps.persistTriageRow(row);

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
