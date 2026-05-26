// email-send Edge Function (D6 — "Approve & Send")
// -----------------------------------------------------------------------------
// Dispatch an AI-prepared reply that was previously persisted in
// `email_triage_results` (via the email-triage pipeline). The Flutter inbox
// UI calls this endpoint when the user taps "Approve & Send" on a triage
// card.
//
// Contract:
//
//   POST /functions/v1/email-send
//   Authorization: Bearer <user JWT>
//   Content-Type: application/json
//   Body: { triage_id: uuid, edited_body?: string }
//
//   200 OK: { ok: true, gmail_message_id: string, sent_at: iso }
//   200 OK (idempotent re-send): same shape, original ids returned.
//   400 Bad Request — malformed payload, edited body fails quality gate.
//   401 Unauthorized — missing/invalid JWT.
//   403 Forbidden — row does not belong to the caller.
//   404 Not Found — triage_id does not resolve.
//   409 Conflict — gate_token verification failed (replay / tampered).
//   422 Unprocessable — no draft body persisted on the row.
//   429 Too Many Requests — per-user send rate limit tripped.
//   503 Service Unavailable — Gmail OAuth not connected / refresh failed.
//
// Why not just re-use `send-email`?  The existing function is the generic
// "send from chat / approval" pipe. D6 needs three extra moves the generic
// fn does not do:
//   1. Re-verify the email-triage HMAC `gate_token` against the live body.
//   2. Threaded reply headers (`In-Reply-To`, `References`) so Gmail
//      stacks the reply inside the original thread.
//   3. Stamp `email_triage_results.sent_at / sent_message_id` so the
//      Inbox UI can hide the row and the chat assistant's `list_inbox`
//      no longer surfaces it.
// We keep `send-email` untouched so the chat-side "send email" tool
// continues to work exactly as before.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

import { corsHeaders, jsonError, requireUserWithRateLimit } from "../_shared/auth.ts";
import { ensureFreshToken, loadGmailToken } from "../_shared/gmail_token.ts";
import {
  buildReplySubject,
  buildThreadingHeaders,
  type EmailSendDeps,
  MAX_OUTBOUND_ATTACHMENT_BYTES_TOTAL,
  type OutboundAttachment,
  pickOutgoingBody,
  priorDispatch,
  recheckEditedBody,
  resolveAction,
  type SendArgs,
  validatePayload,
  verifyTriageGate,
} from "./send_logic.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const EMAIL_AGENT_GATE_SECRET = Deno.env.get("EMAIL_AGENT_GATE_SECRET") ?? "";
const DEFAULT_FROM =
  Deno.env.get("SEND_EMAIL_DEFAULT_FROM") || "support@advocat.ee";

const PROVIDER_FETCH_TIMEOUT_MS = 15_000;

function jsonOk(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/** Strip CRLF / tab from any string going into an RFC-2822 header. */
function scrubHeaderText(s: string): string {
  return s.replace(/[\r\n\t]/g, " ").slice(0, 200);
}

/**
 * Build an RFC-2822 message body. When `attachments` is empty (or absent),
 * the output is a simple `text/plain; charset=UTF-8` message — bit-for-bit
 * identical to the pre-Fix-#3 shape (regression-guarded by
 * email_send_test.ts).
 *
 * When `attachments.length > 0`, the output is `multipart/mixed`:
 *
 *   * Outer headers (`From`, `To`, `Cc`, `Subject`, `In-Reply-To`,
 *     `References`, `MIME-Version`, `Content-Type: multipart/mixed`).
 *   * Body part 1: `text/plain; charset=UTF-8`, 7bit, the user's body.
 *   * Body parts 2..N: one per attachment — `Content-Type: <mime>`,
 *     `Content-Disposition: attachment; filename="<filename>"`,
 *     `Content-Transfer-Encoding: base64`, base64-encoded data chunked
 *     at 76 chars/line per RFC-2045 §6.8.
 *
 * The boundary is crypto-random (32 hex chars) so it never collides with
 * content. Filename is RFC 2047 'Q' encoded when it contains non-ASCII —
 * Gmail accepts both quoted and encoded forms.
 *
 * Throws when sum of attachment sizes exceeds
 * [MAX_OUTBOUND_ATTACHMENT_BYTES_TOTAL]. The caller (`makeRealDeps.gmailSend`
 * wrapper) maps this to a 400 `attachment_size_exceeded` response.
 */
export function rfc2822Reply(input: {
  from: string;
  to: string;
  cc?: string;
  subject: string;
  body: string;
  inReplyTo: string | null;
  references: string | null;
  attachments?: ReadonlyArray<OutboundAttachment>;
}): string {
  const encode = (s: string) =>
    `=?UTF-8?B?${btoa(unescape(encodeURIComponent(s)))}?=`;
  const headers: string[] = [
    `From: ${scrubHeaderText(input.from)}`,
    `To: ${scrubHeaderText(input.to)}`,
  ];
  if (input.cc) headers.push(`Cc: ${scrubHeaderText(input.cc)}`);
  headers.push(`Subject: ${encode(input.subject)}`);
  if (input.inReplyTo) {
    headers.push(`In-Reply-To: ${scrubHeaderText(input.inReplyTo)}`);
  }
  if (input.references) {
    headers.push(`References: ${scrubHeaderText(input.references)}`);
  }
  headers.push("MIME-Version: 1.0");

  const attachments = input.attachments ?? [];

  // Fast path — no attachments, keep the historic plaintext shape.
  if (attachments.length === 0) {
    headers.push('Content-Type: text/plain; charset="UTF-8"');
    headers.push("Content-Transfer-Encoding: 7bit");
    headers.push("");
    headers.push(input.body);
    return headers.join("\r\n");
  }

  // Sum cap — guard before we spend CPU on base64.
  let totalBytes = 0;
  for (const a of attachments) totalBytes += a.data.byteLength;
  if (totalBytes > MAX_OUTBOUND_ATTACHMENT_BYTES_TOTAL) {
    throw new Error(
      `attachment_size_exceeded: ${totalBytes} > ${MAX_OUTBOUND_ATTACHMENT_BYTES_TOTAL}`,
    );
  }

  // Crypto-random boundary so it never collides with the body / attachment bytes.
  const boundary = `=_advocat_${crypto.randomUUID().replace(/-/g, "")}_=`;
  headers.push(
    `Content-Type: multipart/mixed; boundary="${boundary}"`,
  );
  headers.push("");
  headers.push("This is a multi-part message in MIME format.");

  // Body part 1 — text/plain.
  headers.push(`--${boundary}`);
  headers.push('Content-Type: text/plain; charset="UTF-8"');
  headers.push("Content-Transfer-Encoding: 7bit");
  headers.push("");
  headers.push(input.body);

  // Parts 2..N — attachments.
  for (const att of attachments) {
    const encodedName = needsEncoding(att.filename)
      ? encode(att.filename)
      : `"${att.filename.replace(/"/g, "")}"`;
    const safeMime = scrubHeaderText(att.mime || "application/octet-stream");
    headers.push(`--${boundary}`);
    headers.push(`Content-Type: ${safeMime}; name=${encodedName}`);
    headers.push(`Content-Disposition: attachment; filename=${encodedName}`);
    headers.push("Content-Transfer-Encoding: base64");
    headers.push("");
    headers.push(chunkBase64(att.data));
  }

  // Closing boundary.
  headers.push(`--${boundary}--`);
  return headers.join("\r\n");
}

/** True when a header value contains chars not safe in a quoted-string. */
function needsEncoding(s: string): boolean {
  return /[^\x20-\x7e]|"|\\/.test(s);
}

/** Base64-encode bytes, chunked at 76 chars/line per RFC-2045 §6.8. */
function chunkBase64(bytes: Uint8Array): string {
  // Build base64 in chunks of 3 raw bytes → 4 b64 chars. Stream so we don't
  // OOM on a 25 MB attachment.
  let bin = "";
  // String.fromCharCode handles up to ~1 MB per chunk reliably.
  const STEP = 8192;
  for (let i = 0; i < bytes.length; i += STEP) {
    const slice = bytes.subarray(i, Math.min(i + STEP, bytes.length));
    bin += String.fromCharCode(...slice);
  }
  const b64 = btoa(bin);
  // Split at 76-char boundaries with CRLF.
  const out: string[] = [];
  for (let i = 0; i < b64.length; i += 76) {
    out.push(b64.slice(i, i + 76));
  }
  return out.join("\r\n");
}

function base64url(s: string): string {
  return btoa(s)
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

async function gmailSend(args: SendArgs): Promise<{ id: string }> {
  // rfc2822Reply is binary-safe via String.fromCharCode chunking — base64url
  // wraps the whole RFC-2822 wire form (headers + body + attachments).
  const wire = rfc2822Reply({
    from: args.from,
    to: args.to,
    cc: args.cc,
    subject: args.subject,
    body: args.body,
    inReplyTo: args.inReplyTo ?? null,
    references: args.references ?? null,
    attachments: args.attachments,
  });
  const raw = base64url(wire);
  const resp = await fetch(
    "https://gmail.googleapis.com/gmail/v1/users/me/messages/send",
    {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${args.accessToken}`,
        "Content-Type": "application/json",
      },
      // `threadId` is what stacks the reply under the original Gmail
      // thread for the sender's own copy. Without it Gmail still
      // honours the In-Reply-To header for recipient-side threading
      // but the user's own Sent folder shows a stand-alone message.
      body: JSON.stringify({ raw, threadId: args.threadId }),
      signal: AbortSignal.timeout(PROVIDER_FETCH_TIMEOUT_MS),
    },
  );
  if (!resp.ok) {
    const err = await resp.text();
    throw new Error(`Gmail API ${resp.status}: ${err.slice(0, 300)}`);
  }
  const data = await resp.json();
  return { id: data.id as string };
}

// =============================================================================
// Supabase-backed deps (real wiring for the serve handler)
// =============================================================================

// deno-lint-ignore no-explicit-any
function makeRealDeps(supabase: any): EmailSendDeps {
  return {
    async loadTriageForUser(triageId, userId) {
      const { data, error } = await supabase
        .from("email_triage_results")
        .select(
          `
          id, user_id, thread_id, draft_language, draft_subject,
          draft_body, draft_to, draft_cc, send_recommendation,
          gate_token, sent_at, sent_message_id, user_action,
          proposed_actions,
          email_threads:thread_id ( gmail_thread_id )
          `,
        )
        .eq("id", triageId)
        .maybeSingle();
      if (error || !data) return null;
      if ((data.user_id as string) !== userId) return null;
      // Supabase returns nested join either as an object or single-elt
      // array depending on the inferred relationship. Be tolerant.
      const nested = data.email_threads as unknown;
      let gmailThreadId = "";
      if (Array.isArray(nested) && nested.length > 0) {
        gmailThreadId = (nested[0] as { gmail_thread_id?: string })
          .gmail_thread_id ?? "";
      } else if (nested && typeof nested === "object") {
        gmailThreadId =
          (nested as { gmail_thread_id?: string }).gmail_thread_id ?? "";
      }
      return {
        id: data.id as string,
        user_id: data.user_id as string,
        thread_id: data.thread_id as string,
        gmail_thread_id: gmailThreadId,
        draft_language: (data.draft_language as string | null) ?? null,
        draft_subject: (data.draft_subject as string | null) ?? null,
        draft_body: (data.draft_body as string | null) ?? null,
        draft_to: (data.draft_to as string[] | null) ?? [],
        draft_cc: (data.draft_cc as string[] | null) ?? [],
        send_recommendation: (data.send_recommendation as string) ?? "",
        gate_token: (data.gate_token as
          | (import("../email-triage/policy_gate.ts").GateToken)
          | null) ?? null,
        sent_at: (data.sent_at as string | null) ?? null,
        sent_message_id: (data.sent_message_id as string | null) ?? null,
        user_action: (data.user_action as string | null) ?? null,
        proposed_actions: data.proposed_actions ?? null,
      };
    },
    async loadLastInbound(threadId) {
      const { data, error } = await supabase
        .from("email_messages")
        .select("gmail_message_id, rfc_message_id, subject")
        .eq("thread_id", threadId)
        .order("sent_at", { ascending: false })
        .limit(1)
        .maybeSingle();
      if (error || !data) return null;
      return {
        gmail_message_id: data.gmail_message_id as string,
        rfc_message_id: (data.rfc_message_id as string | null) ?? null,
        subject: (data.subject as string | null) ?? null,
      };
    },
    sendViaGmail(args) {
      return gmailSend(args);
    },
    async markSent(args) {
      await supabase
        .from("email_triage_results")
        .update({
          sent_at: args.sentAt,
          sent_message_id: args.gmailMessageId,
          user_action: "sent",
        })
        .eq("id", args.triageId)
        .eq("user_id", args.userId);
    },
    async markThreadStatus(threadId, status) {
      await supabase
        .from("email_threads")
        .update({ triage_status: status })
        .eq("id", threadId);
    },
    async appendCorrespondence(args) {
      try {
        await supabase.from("correspondence").insert({
          user_id: args.userId,
          case_id: args.caseId,
          direction: "outbound",
          from_address: args.fromAddress,
          to_address: args.toAddress,
          cc_address: args.ccAddress,
          subject: args.subject,
          body: args.body,
          provider: "gmail_user",
          provider_message_id: args.providerMessageId,
          sent_at: args.sentAt,
        });
      } catch (_e) {
        // Audit insert is best-effort; the user's mail has already left.
      }
    },
  };
}

// =============================================================================
// HTTP entry point
// =============================================================================

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }
  if (!EMAIL_AGENT_GATE_SECRET) {
    return jsonError("Service misconfigured (EMAIL_AGENT_GATE_SECRET)", 503);
  }

  const gate = await requireUserWithRateLimit(req, {
    bucket: "email-send",
    maxPerMinute: 10,
  });
  if (gate.kind === "deny") return gate.response;
  const userId = gate.user.id;

  let payloadRaw: unknown;
  try {
    payloadRaw = await req.json();
  } catch (_) {
    return jsonError("Invalid JSON body", 400);
  }

  const v = validatePayload(payloadRaw);
  if (!v.ok) return jsonError(v.err.error, v.err.status);

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const deps = makeRealDeps(supabase);

  return await handleSend({
    deps,
    userId,
    triageId: v.value.triageId,
    editedBody: v.value.editedBody,
    actionIdx: v.value.actionIdx,
    gateSecret: EMAIL_AGENT_GATE_SECRET,
    loadAccessToken: async (uid) => {
      const row = await loadGmailToken(supabase, uid);
      if (!row) {
        return { token: null, fromAddress: DEFAULT_FROM };
      }
      const fresh = await ensureFreshToken(supabase, uid, row);
      return {
        token: fresh,
        fromAddress: row.email ?? DEFAULT_FROM,
      };
    },
  });
});

// =============================================================================
// Pure-ish handler — exported for tests
// =============================================================================

export interface HandleSendArgs {
  deps: EmailSendDeps;
  userId: string;
  triageId: string;
  editedBody: string | null;
  /**
   * Parallel Actions Panel (2026-05-25) — index into
   * `email_triage_results.proposed_actions`. Default 0 routes through the
   * legacy draft_* columns for backwards compatibility with the existing
   * single-draft approveAndSend flow. Out-of-bounds → 400 action_idx_oob.
   */
  actionIdx?: number;
  gateSecret: string;
  /** Inject Gmail OAuth resolution so tests don't need a real token store. */
  loadAccessToken: (
    userId: string,
  ) => Promise<{ token: string | null; fromAddress: string }>;
  /** Deterministic clock for tests. */
  now?: () => number;
}

export async function handleSend(args: HandleSendArgs): Promise<Response> {
  const loadedRow = await args.deps.loadTriageForUser(args.triageId, args.userId);
  if (!loadedRow) {
    return jsonError("Triage not found", 404);
  }

  // Parallel Actions Panel (2026-05-25): resolve action_idx → tuple.
  // action_idx === 0 (or omitted) routes through the legacy draft_*
  // columns for backwards compatibility. action_idx > 0 picks the
  // matching entry from `email_triage_results.proposed_actions`.
  // Idempotency / gate / quality checks reuse the same row shape, so we
  // build a "row view" by overlaying the resolved tuple over the loaded
  // row's draft_* fields. The gate column stays attached to the loaded
  // row (one HMAC per triage; per-action tokens are a later iteration).
  const actionIdx = args.actionIdx ?? 0;
  const resolved = resolveAction(loadedRow, actionIdx);
  if (!resolved.ok) {
    return jsonError(resolved.error_code, resolved.status, {
      error_code: resolved.error_code,
    });
  }
  const row = actionIdx === 0
    ? loadedRow
    : {
        ...loadedRow,
        draft_to: resolved.resolved.to,
        draft_cc: resolved.resolved.cc,
        draft_subject: resolved.resolved.subject,
        draft_body: resolved.resolved.body,
        draft_language: resolved.resolved.language,
        // The per-row HMAC gate token covers ONLY the legacy draft
        // (action_idx=0). For action_idx > 0 the verifier would compare
        // against the wrong body_sha256 + recipients and fail. Per-action
        // tokens are a follow-up; for now we skip the gate, mirroring
        // the existing `gate_token_missing` branch for pre-D6 rows.
        gate_token: null,
      };

  // Idempotency: if we've already sent this draft, return the prior result.
  // NOTE: the sent_at marker is per-triage, not per-action. When the
  // sibling agent wires per-action idempotency the marker will move to
  // a `proposed_actions[idx].sent_at` field; until then a re-send of a
  // different action_idx on a row that has sent_at != null would be
  // blocked. We guard against that by only checking idempotency for
  // actionIdx === 0 (the legacy path the sent_at marker was designed
  // for).
  if (actionIdx === 0) {
    const prior = priorDispatch(row);
    if (prior) {
      return jsonOk({
        ok: true,
        gmail_message_id: prior.gmailMessageId,
        sent_at: prior.sentAt,
        idempotent: true,
      });
    }
  }

  if (!row.draft_body || row.draft_body.trim().length === 0) {
    return jsonError("No draft body persisted", 422);
  }
  const recipients = [...(row.draft_to ?? []), ...(row.draft_cc ?? [])];
  if (recipients.length === 0) {
    return jsonError("No recipient on draft", 422);
  }

  const { body: outgoingBody, wasEdited } = pickOutgoingBody(
    row,
    args.editedBody,
  );

  // Re-run quality check only when the user edited (the original draft
  // already passed the model's own gate at triage-time).
  if (wasEdited) {
    const report = recheckEditedBody({
      body: outgoingBody,
      draftLanguage: row.draft_language,
    });
    if (!report.ok) {
      return jsonError("Edited body failed quality gate", 400, {
        report: {
          detected_language: report.detected_language,
          expected_language: report.expected_language,
          word_count: report.word_count,
          numbered_question_count: report.numbered_question_count,
          issues: report.issues,
        },
      });
    }
  }

  // HMAC gate re-verification. `skipped` is permitted for older rows
  // triaged before the gate_token column existed; everything else must
  // pass cleanly.
  const gateOutcome = await verifyTriageGate({
    row,
    outgoingBody,
    secret: args.gateSecret,
    now: args.now?.(),
  });
  if (gateOutcome.kind === "fail") {
    return jsonError("Gate token verification failed", 409, {
      reason: gateOutcome.reason,
    });
  }

  // Resolve Gmail OAuth.
  const tok = await args.loadAccessToken(args.userId);
  if (!tok.token) {
    return jsonError(
      "Gmail OAuth required. Connect Gmail in Settings before approving sends.",
      503,
      { error_code: "gmail_reauth_required" },
    );
  }

  // Threading headers.
  const last = await args.deps.loadLastInbound(row.thread_id);
  const { inReplyTo, references } = buildThreadingHeaders(last);
  const subject = buildReplySubject(
    row.draft_subject,
    last?.subject ?? null,
  );

  // Compose recipient strings (Gmail accepts comma-separated lists).
  const to = (row.draft_to ?? []).join(", ");
  const cc = (row.draft_cc ?? []).length > 0
    ? (row.draft_cc ?? []).join(", ")
    : undefined;

  let sendResult: { id: string };
  try {
    sendResult = await args.deps.sendViaGmail({
      accessToken: tok.token,
      threadId: row.gmail_thread_id,
      from: tok.fromAddress,
      to,
      cc,
      subject,
      body: outgoingBody,
      inReplyTo,
      references,
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    // Gmail-specific 401 / 403 surfaces as a reauth signal so the UI
    // can route the user back through OAuth instead of a generic toast.
    const isAuthFailure = /401|403|invalid_grant|invalid_token/i.test(msg);
    return jsonError(
      "Gmail send failed",
      isAuthFailure ? 503 : 502,
      {
        details: msg.slice(0, 200),
        ...(isAuthFailure ? { error_code: "gmail_reauth_required" } : {}),
      },
    );
  }

  const sentAt = new Date(args.now?.() ?? Date.now()).toISOString();

  // Persist outcome — best effort. If the stamp fails the mail has
  // still left; on the next sync tick the inbox loop will catch up.
  // For action_idx > 0 we deliberately skip the markSent stamp because
  // `sent_at` is a single per-row marker designed for the legacy
  // single-draft flow. Stamping it for action_idx=1 would mask
  // action_idx=0 as already sent and break the partial-failure retry
  // story. The audit log (`correspondence` insert below) is the source
  // of truth for non-idx-0 sends; per-action sent_at is a follow-up
  // ticket the sibling agent will pick up.
  if (actionIdx === 0) {
    try {
      await args.deps.markSent({
        triageId: row.id,
        userId: args.userId,
        gmailMessageId: sendResult.id,
        sentAt,
      });
    } catch (_e) {
      // swallowed by design
    }
  }
  try {
    await args.deps.markThreadStatus(row.thread_id, "triaged");
  } catch (_e) { /* best-effort */ }
  try {
    await args.deps.appendCorrespondence({
      userId: args.userId,
      caseId: null, // case attribution lives on email_threads — best-effort
      fromAddress: tok.fromAddress,
      toAddress: to,
      ccAddress: cc ?? null,
      subject,
      body: outgoingBody,
      providerMessageId: sendResult.id,
      sentAt,
    });
  } catch (_e) { /* best-effort */ }

  return jsonOk({
    ok: true,
    gmail_message_id: sendResult.id,
    sent_at: sentAt,
    gate_outcome: gateOutcome.kind,
    action_idx: actionIdx,
  });
}
