// dsar-export/index.ts
// -----------------------------------------------------------------------------
// GDPR Art. 15 (right of access) self-service data export.
//
// Endpoint: POST /functions/v1/dsar-export
// Auth:     Bearer <user JWT> (real user session, not anon)
// Rate:     2 requests / minute / user (DSAR is a low-frequency action)
//
// Returns the requesting user's personal data as a downloadable JSON blob
// (Content-Disposition: attachment; filename=advocat-data-export-<uid>-<date>.json).
// Reads every table that stores user-identifiable data. Sensitive credential
// columns (OAuth access/refresh tokens) are redacted — DSAR is the right to
// know the data exists, not the right to extract live access tokens.
//
// If the assembled payload exceeds the 50MB threshold, the function returns
// HTTP 202 with `{ queued: true }` instead — the queued export is logged
// in `dsar_requests` with status='pending' and finished asynchronously
// (currently manual; an async worker is a future deliverable).
//
// Every invocation writes a row to `public.dsar_requests` (GDPR Art. 12(3)
// requires a tamper-evident record of the request and a 30-day SLA).
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  jsonError,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// Soft response cap. Anything bigger gets queued. 50MB chosen so the
// response fits in a single HTTPS frame for any reasonable user; oversize
// users (heavy email-sync history) get an async email link instead.
const MAX_INLINE_RESPONSE_BYTES = 50 * 1024 * 1024;

/** Type alias for service-role Supabase client returned by createClient. */
// deno-lint-ignore no-explicit-any
type SbClient = any;

/**
 * Safe `select * where user_id = ?` helper. Swallows "table does not exist"
 * errors (different deployments have different table sets) so the export
 * never aborts because of a single missing optional table. Returns an empty
 * array on failure and logs a warning.
 */
async function safeSelect(
  sb: SbClient,
  table: string,
  userColumn: string,
  userId: string,
  opts: { redactColumns?: string[] } = {},
): Promise<unknown[]> {
  try {
    const { data, error } = await sb.from(table).select("*").eq(userColumn, userId);
    if (error) {
      // 42P01 = undefined_table, 42703 = undefined_column. Both are acceptable
      // (table not deployed in this env). Anything else we surface to the log.
      const code = (error as { code?: string }).code;
      if (code !== "42P01" && code !== "42703") {
        console.warn(`[dsar-export] ${table} read failed: ${error.message}`);
      }
      return [];
    }
    const rows = (data ?? []) as Record<string, unknown>[];
    if (opts.redactColumns && opts.redactColumns.length > 0) {
      return rows.map((row) => {
        const out: Record<string, unknown> = { ...row };
        for (const col of opts.redactColumns!) {
          if (col in out) out[col] = "[REDACTED]";
        }
        return out;
      });
    }
    return rows;
  } catch (e) {
    console.warn(`[dsar-export] ${table} threw: ${String(e)}`);
    return [];
  }
}

interface ExportPayload {
  exported_at: string;
  user_id: string;
  schema_version: string;
  notice: string;
  account: unknown;
  chat_history: {
    messages: unknown[];
    citations: unknown[];
    feedback: unknown[];
    planner_traces: unknown[];
    case_chat_sessions: unknown[];
  };
  cases: {
    cases: unknown[];
    user_cases: unknown[];
    case_documents: unknown[];
    case_deadlines: unknown[];
    case_timeline_events: unknown[];
    case_phase: unknown[];
    case_facts: unknown[];
    case_file: unknown[];
    case_file_events: unknown[];
    case_file_parties: unknown[];
    case_file_deadlines: unknown[];
    checker_reports: unknown[];
  };
  documents: unknown[];
  deadlines: unknown[];
  vault: {
    document_tags: unknown[];
    tags: unknown[];
  };
  emails: {
    threads: unknown[];
    messages: unknown[];
    attachments: unknown[];
    triage_results: unknown[];
    triage_lawyer_opinions: unknown[];
    triage_proposed_actions: unknown[];
    retry_queue: unknown[];
    connections: unknown[];
    user_settings: unknown[];
  };
  correspondence: unknown[];
  correspondence_audit: unknown[];
  drafting: {
    user_drafts: unknown[];
    draft_versions: unknown[];
  };
  ai_memory: unknown[];
  conversation_summaries: unknown[];
  agent: {
    runs: unknown[];
    quota: unknown[];
    audit_log: unknown[];
    intentions: unknown[];
  };
  consilium_runs: unknown[];
  contract: {
    reviews: unknown[];
    analysis_jobs: unknown[];
  };
  advice: {
    corrections: unknown[];
    digest: unknown[];
  };
  notifications: {
    notifications: unknown[];
    preferences: unknown[];
    push_events: unknown[];
    deadline_log: unknown[];
  };
  account_settings: {
    user_settings: unknown[];
    user_engagement: unknown[];
    user_quotas: unknown[];
    voice_usage: unknown[];
    ai_usage: unknown[];
  };
  lawyer_bookings: unknown[];
  oauth_providers: unknown[];
  encryption_keys: unknown[];
  consents: {
    dpa_acceptances: unknown[];
    sensitive_consents: unknown[];
    disclaimer_acknowledgments: unknown[];
    consent_log: unknown[];
    attorney_privilege_acceptance: unknown[];
  };
  payments: {
    subscriptions: unknown[];
    apple_iap_transactions: unknown[];
  };
  feedback: unknown[];
  /**
   * v2 (2026-05-25): B2B silent-signal log. Every behavioural signal we
   * recorded about the user under the B2B-lead detection program is
   * personal data under GDPR Art. 4(1) and must be disclosed under Art.
   * 15(1). Includes `signal_type`, `score`, `payload`, `occurred_at`.
   */
  b2b_signals: unknown[];
  sharing: {
    shared_results: unknown[];
    referral_codes: unknown[];
    referral_attributions_as_invitee: unknown[];
    referral_attributions_as_inviter: unknown[];
  };
  support: {
    tickets: unknown[];
  };
  experimentation: {
    ab_assignments: unknown[];
    ab_events: unknown[];
  };
  audit_log: {
    dsar_requests: unknown[];
    /**
     * Generic platform audit log. Disclosed under Art. 15(1) even though
     * this row is retained post-deletion under Art. 17(3)(b) (accountability
     * legal obligation); the user is entitled to KNOW it exists.
     */
    audit_log: unknown[];
  };
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // JWT-gated, 2/min/user. GDPR Art. 12(2) "appropriate technical measures":
  // a low rate is enough to prevent abuse without blocking honest users
  // (most people request export once a year, not twice a minute).
  const gate = await requireUserWithRateLimit(req, {
    bucket: "dsar-export",
    maxPerMinute: 2,
  });
  if (gate.kind === "deny") return gate.response;

  const userId = gate.user.id;
  const ipAddress =
    req.headers.get("x-forwarded-for")?.split(",")[0].trim() || null;
  const userAgent = req.headers.get("user-agent") || null;

  const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // ── 1. Audit log: record the request BEFORE we do any reading. If the
  //      export then fails we still have evidence that the request was
  //      received (Art. 12(3) — controller must respond within 30 days).
  let dsarId: string | null = null;
  try {
    const { data: ins, error } = await sb
      .from("dsar_requests")
      .insert({
        user_id: userId,
        request_type: "export",
        status: "pending",
        ip_address: ipAddress,
        user_agent: userAgent,
      })
      .select("id")
      .single();
    if (error) {
      console.warn(`[dsar-export] audit-log insert failed: ${error.message}`);
    } else {
      dsarId = (ins as { id: string }).id;
    }
  } catch (e) {
    console.warn(`[dsar-export] audit-log threw: ${String(e)}`);
  }

  // ── 2. Read every table that may carry personal data. All reads are
  //      explicitly filtered by user_id under service-role — RLS is bypassed
  //      intentionally because the auth gate above already proved identity.
  let payload: ExportPayload;
  try {
    // ── 2026-05-28 WAVE 1 GDPR FIX ─────────────────────────────────────────
    // Mirror of USER_DATA_TABLES in account-delete/handler.ts. Art. 15 must
    // disclose every table that Art. 17 would wipe (plus the Art. 17(3)
    // retained tables that the user has a right to know exist).
    //
    // Sequential await blocks keep the function under the Promise.all limit
    // and make it trivial to grep for "what does the DSAR include?". The
    // perf cost is negligible — each query is a single indexed lookup.
    const account = await sb.from("profiles").select("*").eq("id", userId)
      .maybeSingle().then((r: { data: unknown }) => r.data ?? null);

    // ── Chat history ─────────────────────────────────────────────────────
    const chatMessages = await safeSelect(sb, "chat_messages", "user_id", userId);
    const chatCitations = await safeSelect(sb, "chat_message_citations", "user_id", userId);
    const chatFeedback = await safeSelect(sb, "message_feedback", "user_id", userId);
    const chatPlannerTraces = await safeSelect(sb, "chat_planner_traces", "user_id", userId);
    const caseChatSessions = await safeSelect(sb, "case_chat_sessions", "user_id", userId);

    // ── Cases ─────────────────────────────────────────────────────────────
    const cases = await safeSelect(sb, "cases", "user_id", userId);
    const userCases = await safeSelect(sb, "user_cases", "user_id", userId);
    const caseDocuments = await safeSelect(sb, "case_documents", "user_id", userId);
    const caseDeadlines = await safeSelect(sb, "case_deadlines", "user_id", userId);
    const caseTimelineEvents = await safeSelect(sb, "case_timeline_events", "user_id", userId);
    const casePhase = await safeSelect(sb, "case_phase", "user_id", userId);
    const caseFacts = await safeSelect(sb, "case_facts", "user_id", userId);
    const caseFile = await safeSelect(sb, "case_file", "user_id", userId);
    const caseFileEvents = await safeSelect(sb, "case_file_events", "user_id", userId);
    const caseFileParties = await safeSelect(sb, "case_file_parties", "user_id", userId);
    const caseFileDeadlines = await safeSelect(sb, "case_file_deadlines", "user_id", userId);
    const checkerReports = await safeSelect(sb, "checker_reports", "user_id", userId);

    // ── Legacy docs + correspondence ─────────────────────────────────────
    const legacyDocuments = await safeSelect(sb, "documents", "user_id", userId);
    const legacyDeadlines = await safeSelect(sb, "deadlines", "user_id", userId);
    const correspondence = await safeSelect(sb, "correspondence", "user_id", userId);
    const correspondenceAudit = await safeSelect(sb, "correspondence_audit", "user_id", userId);

    // ── Vault ────────────────────────────────────────────────────────────
    const vaultDocumentTags = await safeSelect(sb, "vault_document_tags", "user_id", userId);
    const vaultTags = await safeSelect(sb, "vault_tags", "user_id", userId);

    // ── Email agent ──────────────────────────────────────────────────────
    const emailThreads = await safeSelect(sb, "email_threads", "user_id", userId);
    const emailMessages = await safeSelect(sb, "email_messages", "user_id", userId);
    const emailAttachments = await safeSelect(sb, "email_attachments", "user_id", userId);
    const emailTriage = await safeSelect(sb, "email_triage_results", "user_id", userId);
    const emailTriageLawyerOpinions = await safeSelect(sb, "email_triage_lawyer_opinions", "user_id", userId);
    const triageProposedActions = await safeSelect(sb, "triage_proposed_actions", "user_id", userId);
    const emailRetryQueue = await safeSelect(sb, "email_retry_queue", "user_id", userId);
    const emailConnections = await safeSelect(sb, "email_connections", "user_id", userId);
    const emailUserSettings = await safeSelect(sb, "email_user_settings", "user_id", userId);

    // ── Drafting ─────────────────────────────────────────────────────────
    const userDrafts = await safeSelect(sb, "user_drafts", "user_id", userId);
    const draftVersions = await safeSelect(sb, "draft_versions", "user_id", userId);

    // ── AI memory + agent loop ───────────────────────────────────────────
    const aiMemory = await safeSelect(sb, "user_ai_memory", "user_id", userId);
    const conversationSummaries = await safeSelect(sb, "conversation_summaries", "user_id", userId);
    const agentRuns = await safeSelect(sb, "agent_runs", "user_id", userId);
    const agentQuota = await safeSelect(sb, "agent_quota", "user_id", userId);
    const agentAuditLog = await safeSelect(sb, "agent_audit_log", "user_id", userId);
    const agentIntentions = await safeSelect(sb, "agent_intentions", "user_id", userId);

    // ── Consilium + contract review + advice corrections ─────────────────
    const consiliumRuns = await safeSelect(sb, "consilium_runs", "user_id", userId);
    const contractReviews = await safeSelect(sb, "contract_reviews", "user_id", userId);
    const contractAnalysisJobs = await safeSelect(sb, "contract_analysis_jobs", "user_id", userId);
    const adviceCorrections = await safeSelect(sb, "advice_corrections", "user_id", userId);
    const adviceDigest = await safeSelect(sb, "advice_digest", "user_id", userId);

    // ── Notifications ────────────────────────────────────────────────────
    const notifications = await safeSelect(sb, "notifications", "user_id", userId);
    const notificationPreferences = await safeSelect(sb, "notification_preferences", "user_id", userId);
    const pushEvents = await safeSelect(sb, "push_events", "user_id", userId);
    const deadlineNotificationLog = await safeSelect(sb, "deadline_notification_log", "user_id", userId);

    // ── Account settings + usage telemetry ───────────────────────────────
    const userSettings = await safeSelect(sb, "user_settings", "user_id", userId);
    const userEngagement = await safeSelect(sb, "user_engagement", "user_id", userId);
    const userQuotas = await safeSelect(sb, "user_quotas", "user_id", userId);
    const voiceUsage = await safeSelect(sb, "voice_usage", "user_id", userId);
    const aiUsage = await safeSelect(sb, "ai_usage", "user_id", userId);

    // ── Lawyer bookings ──────────────────────────────────────────────────
    const lawyerBookings = await safeSelect(sb, "lawyer_bookings", "user_id", userId);

    // ── Identity / OAuth ─────────────────────────────────────────────────
    // user_oauth_tokens: PRESENCE is part of the DSAR, but the live
    // access/refresh tokens are credentials — never disclose under
    // Art. 15(4) (rights of third parties / security).
    const oauthTokens = await safeSelect(sb, "user_oauth_tokens", "user_id", userId, {
      redactColumns: [
        "access_token",
        "refresh_token",
        "id_token",
        "encrypted_access_token",
        "encrypted_refresh_token",
      ],
    });
    const encryptionKeys = await safeSelect(sb, "user_encryption_keys", "user_id", userId, {
      redactColumns: ["wrapped_dek", "wrap_iv", "wrap_tag"],
    });

    // ── Consents ─────────────────────────────────────────────────────────
    const dpaAcceptances = await safeSelect(sb, "dpa_acceptances", "user_id", userId);
    const sensitiveConsents = await safeSelect(sb, "sensitive_consents", "user_id", userId);
    const disclaimerAcks = await safeSelect(sb, "disclaimer_acknowledgments", "user_id", userId);
    const consentLog = await safeSelect(sb, "consent_log", "user_id", userId);
    // Retained post-deletion under Art. 17(3)(e). Disclosed under Art. 15(1).
    const attorneyPrivilegeAcceptance = await safeSelect(sb, "attorney_privilege_acceptance", "user_id", userId);

    // ── Payments. subscriptions carries Stripe customer + product IDs,
    //    never raw PAN — Stripe SDK never returns it. Safe to include.
    //    `payments` table doesn't actually exist (audit P0-7); replaced
    //    with `subscriptions` + `apple_iap_transactions`.
    const subscriptions = await safeSelect(sb, "subscriptions", "user_id", userId);
    const appleIapTransactions = await safeSelect(sb, "apple_iap_transactions", "user_id", userId);

    // ── B2B signals ──────────────────────────────────────────────────────
    const b2bSignals = await safeSelect(sb, "b2b_signals", "user_id", userId);

    // ── Sharing + referrals. `referral_attributions` has TWO user-id
    //    columns: read both perspectives so the DSAR is complete.
    const sharedResults = await safeSelect(sb, "shared_results", "user_id", userId);
    const referralCodes = await safeSelect(sb, "referral_codes", "user_id", userId);
    const referralAsInvitee = await safeSelect(sb, "referral_attributions", "referred_user_id", userId);
    const referralAsInviter = await safeSelect(sb, "referral_attributions", "inviter_user_id", userId);

    // ── Support + experimentation ────────────────────────────────────────
    const supportTickets = await safeSelect(sb, "support_tickets", "user_id", userId);
    const abAssignments = await safeSelect(sb, "ab_assignments", "user_id", userId);
    const abEvents = await safeSelect(sb, "ab_events", "user_id", userId);

    // ── Audit logs ───────────────────────────────────────────────────────
    const dsarHistory = await safeSelect(sb, "dsar_requests", "user_id", userId);
    // Generic platform audit log is retained post-deletion but the user has
    // an Art. 15 right to know it exists (with their entries).
    const auditLog = await safeSelect(sb, "audit_log", "user_id", userId);

    payload = {
      exported_at: new Date().toISOString(),
      user_id: userId,
      schema_version: "2.0",
      notice:
        "GDPR Art. 15 data export. OAuth access/refresh tokens and " +
        "wrapped DEK material are redacted for security (Art. 15(4)). " +
        "Subscriptions / Apple IAP records contain customer + product IDs " +
        "only, no card numbers (PCI/DSS). `audit_log` and `attorney_privilege_acceptance` " +
        "entries are retained after account deletion under Art. 17(3)(b)/(e) " +
        "and are included here for transparency.",
      account,
      chat_history: {
        messages: chatMessages,
        citations: chatCitations,
        feedback: chatFeedback,
        planner_traces: chatPlannerTraces,
        case_chat_sessions: caseChatSessions,
      },
      cases: {
        cases,
        user_cases: userCases,
        case_documents: caseDocuments,
        case_deadlines: caseDeadlines,
        case_timeline_events: caseTimelineEvents,
        case_phase: casePhase,
        case_facts: caseFacts,
        case_file: caseFile,
        case_file_events: caseFileEvents,
        case_file_parties: caseFileParties,
        case_file_deadlines: caseFileDeadlines,
        checker_reports: checkerReports,
      },
      documents: legacyDocuments,
      deadlines: legacyDeadlines,
      vault: {
        document_tags: vaultDocumentTags,
        tags: vaultTags,
      },
      emails: {
        threads: emailThreads,
        messages: emailMessages,
        attachments: emailAttachments,
        triage_results: emailTriage,
        triage_lawyer_opinions: emailTriageLawyerOpinions,
        triage_proposed_actions: triageProposedActions,
        retry_queue: emailRetryQueue,
        connections: emailConnections,
        user_settings: emailUserSettings,
      },
      correspondence,
      correspondence_audit: correspondenceAudit,
      drafting: {
        user_drafts: userDrafts,
        draft_versions: draftVersions,
      },
      ai_memory: aiMemory,
      conversation_summaries: conversationSummaries,
      agent: {
        runs: agentRuns,
        quota: agentQuota,
        audit_log: agentAuditLog,
        intentions: agentIntentions,
      },
      consilium_runs: consiliumRuns,
      contract: {
        reviews: contractReviews,
        analysis_jobs: contractAnalysisJobs,
      },
      advice: {
        corrections: adviceCorrections,
        digest: adviceDigest,
      },
      notifications: {
        notifications,
        preferences: notificationPreferences,
        push_events: pushEvents,
        deadline_log: deadlineNotificationLog,
      },
      account_settings: {
        user_settings: userSettings,
        user_engagement: userEngagement,
        user_quotas: userQuotas,
        voice_usage: voiceUsage,
        ai_usage: aiUsage,
      },
      lawyer_bookings: lawyerBookings,
      oauth_providers: oauthTokens,
      encryption_keys: encryptionKeys,
      consents: {
        dpa_acceptances: dpaAcceptances,
        sensitive_consents: sensitiveConsents,
        disclaimer_acknowledgments: disclaimerAcks,
        consent_log: consentLog,
        attorney_privilege_acceptance: attorneyPrivilegeAcceptance,
      },
      payments: {
        subscriptions,
        apple_iap_transactions: appleIapTransactions,
      },
      feedback: chatFeedback,
      b2b_signals: b2bSignals,
      sharing: {
        shared_results: sharedResults,
        referral_codes: referralCodes,
        referral_attributions_as_invitee: referralAsInvitee,
        referral_attributions_as_inviter: referralAsInviter,
      },
      support: {
        tickets: supportTickets,
      },
      experimentation: {
        ab_assignments: abAssignments,
        ab_events: abEvents,
      },
      audit_log: {
        // Include the in-flight row too (Art. 15(1)(c): inform of recipients
        // and storage period — the request itself is also personal data).
        dsar_requests: [...(dsarHistory as unknown[])],
        audit_log: auditLog,
      },
    };
  } catch (e) {
    // Mark the audit row partial — we received the request but could not fulfil.
    if (dsarId) {
      await sb
        .from("dsar_requests")
        .update({
          status: "partial",
          completed_at: new Date().toISOString(),
          notes: `read failure: ${String(e).slice(0, 500)}`,
        })
        .eq("id", dsarId);
    }
    return jsonError("Export failed while reading data", 500, {
      details: String(e),
    });
  }

  const json = JSON.stringify(payload, null, 2);
  const bytes = new TextEncoder().encode(json);

  // ── 3. Size check. Oversize: queue + 202.
  if (bytes.byteLength > MAX_INLINE_RESPONSE_BYTES) {
    if (dsarId) {
      await sb
        .from("dsar_requests")
        .update({
          status: "pending",
          notes:
            `payload ${bytes.byteLength} bytes exceeds ${MAX_INLINE_RESPONSE_BYTES} ` +
            `byte inline cap — queued for async delivery`,
        })
        .eq("id", dsarId);
    }
    return new Response(
      JSON.stringify({
        queued: true,
        message:
          "Your export is larger than the inline limit. We will email you a " +
          "download link within 30 days as required by GDPR Art. 12(3).",
        size_bytes: bytes.byteLength,
        dsar_request_id: dsarId,
      }),
      {
        status: 202,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json",
        },
      },
    );
  }

  // ── 4. Stamp the audit row as completed.
  if (dsarId) {
    await sb
      .from("dsar_requests")
      .update({
        status: "completed",
        completed_at: new Date().toISOString(),
        notes: `inline export, ${bytes.byteLength} bytes`,
      })
      .eq("id", dsarId);
  }

  // ── 5. Return the JSON as an attachment download.
  const date = new Date().toISOString().slice(0, 10);
  const filename = `advocat-data-export-${userId}-${date}.json`;
  return new Response(bytes, {
    status: 200,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json; charset=utf-8",
      "Content-Disposition": `attachment; filename="${filename}"`,
      "Cache-Control": "no-store",
    },
  });
});
