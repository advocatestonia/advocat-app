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
  };
  cases: {
    cases: unknown[];
    cases_v2: unknown[];
    documents: unknown[];
    deadlines: unknown[];
    correspondence_per_case: unknown[];
  };
  documents: unknown[];
  emails: {
    threads: unknown[];
    messages: unknown[];
    triage_results: unknown[];
  };
  correspondence: unknown[];
  oauth_providers: unknown[];
  consents: {
    dpa_acceptances: unknown[];
    sensitive_consents: unknown[];
    disclaimer_acknowledgments: unknown[];
  };
  payments: {
    payments: unknown[];
    subscriptions: unknown[];
  };
  feedback: unknown[];
  /**
   * v2 (2026-05-25): B2B silent-signal log. Every behavioural signal we
   * recorded about the user under the B2B-lead detection program is
   * personal data under GDPR Art. 4(1) and must be disclosed under Art.
   * 15(1). Includes `signal_type`, `score`, `payload`, `occurred_at`.
   */
  b2b_signals: unknown[];
  audit_log: {
    dsar_requests: unknown[];
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
    const [
      account,
      chatMessages,
      chatCitations,
      chatFeedback,
      cases,
      casesV2,
      caseDocuments,
      caseDeadlines,
      caseCorrespondence,
      legacyDocuments,
      legacyDeadlines,
      emailThreads,
      emailMessages,
      emailTriage,
      correspondence,
      oauthTokens,
      dpaAcceptances,
      sensitiveConsents,
      disclaimerAcks,
      payments,
      subscriptions,
      messageFeedback,
      dsarHistory,
      b2bSignals,
    ] = await Promise.all([
      sb.from("profiles").select("*").eq("id", userId).maybeSingle()
        .then((r: { data: unknown }) => r.data ?? null),
      safeSelect(sb, "chat_messages", "user_id", userId),
      safeSelect(sb, "chat_message_citations", "user_id", userId),
      safeSelect(sb, "message_feedback", "user_id", userId),
      safeSelect(sb, "cases", "user_id", userId),
      safeSelect(sb, "cases_v2", "user_id", userId),
      safeSelect(sb, "case_documents", "user_id", userId),
      safeSelect(sb, "case_deadlines", "user_id", userId),
      safeSelect(sb, "case_correspondence", "user_id", userId),
      safeSelect(sb, "documents", "user_id", userId),
      safeSelect(sb, "deadlines", "user_id", userId),
      safeSelect(sb, "email_threads", "user_id", userId),
      safeSelect(sb, "email_messages", "user_id", userId),
      safeSelect(sb, "email_triage_results", "user_id", userId),
      safeSelect(sb, "correspondence", "user_id", userId),
      // user_oauth_tokens: PRESENCE is part of the DSAR, but the live
      // access/refresh tokens are credentials — never disclose under
      // Art. 15(4) (rights of third parties / security).
      safeSelect(sb, "user_oauth_tokens", "user_id", userId, {
        redactColumns: [
          "access_token",
          "refresh_token",
          "id_token",
          "encrypted_access_token",
          "encrypted_refresh_token",
        ],
      }),
      safeSelect(sb, "dpa_acceptances", "user_id", userId),
      safeSelect(sb, "sensitive_consents", "user_id", userId),
      safeSelect(sb, "disclaimer_acknowledgments", "user_id", userId),
      // payments / subscriptions carry Stripe customer + product IDs,
      // never raw PAN — Stripe SDK never returns it. Safe to include.
      safeSelect(sb, "payments", "user_id", userId),
      safeSelect(sb, "subscriptions", "user_id", userId),
      safeSelect(sb, "feedback_buttons", "user_id", userId),
      safeSelect(sb, "dsar_requests", "user_id", userId),
      // v2 (2026-05-25): include B2B silent-signal log. Read-own via RLS;
      // service-role read here is identical to what the user could see in
      // theory (Art. 15(1)) but the table itself is not exposed to the
      // Flutter client today.
      safeSelect(sb, "b2b_signals", "user_id", userId),
    ]);

    payload = {
      exported_at: new Date().toISOString(),
      user_id: userId,
      schema_version: "1.0",
      notice:
        "GDPR Art. 15 data export. OAuth access/refresh tokens are redacted " +
        "for security (Art. 15(4)). Stripe records contain customer + " +
        "product references only, no card numbers (PCI/DSS).",
      account,
      chat_history: {
        messages: chatMessages,
        citations: chatCitations,
        feedback: chatFeedback,
      },
      cases: {
        cases,
        cases_v2: casesV2,
        documents: caseDocuments,
        deadlines: caseDeadlines,
        correspondence_per_case: caseCorrespondence,
      },
      documents: legacyDocuments,
      emails: {
        threads: emailThreads,
        messages: emailMessages,
        triage_results: emailTriage,
      },
      correspondence,
      oauth_providers: oauthTokens,
      consents: {
        dpa_acceptances: dpaAcceptances,
        sensitive_consents: sensitiveConsents,
        disclaimer_acknowledgments: disclaimerAcks,
      },
      payments: {
        payments,
        subscriptions,
      },
      feedback: messageFeedback,
      b2b_signals: b2bSignals,
      audit_log: {
        // Include the in-flight row too (Art. 15(1)(c): inform of recipients
        // and storage period — the request itself is also personal data).
        dsar_requests: [...(dsarHistory as unknown[])],
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
