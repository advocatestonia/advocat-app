// email-send/send_logic.ts
// -----------------------------------------------------------------------------
// Pure-ish logic for D6 "Approve & Send".
//
// Concerns kept here (so tests don't need Deno HTTP):
//   - Validating the inbound `{ triage_id, edited_body? }` payload.
//   - Re-verifying the HMAC `gate_token` against the persisted draft body
//     (or the user's edited body) and recipient set.
//   - Re-running the email-quality gate when the user edited the body.
//   - Picking the body that will actually go out (edited > draft).
//   - Composing the RFC-2822 message + threading headers (In-Reply-To +
//     References + Subject Re:).
//   - Building the structured row update for `email_triage_results`
//     after a successful send.
//
// I/O (Supabase + Gmail API) stays in index.ts so tests can inject a
// minimal `EmailSendDeps`.
// -----------------------------------------------------------------------------

import {
  checkEmailQuality,
  type EmailQualityReport,
} from "../_shared/email_quality_check.ts";
import {
  canonicaliseRecipientSet,
  type GateToken,
  sha256Hex,
  verifyGateToken,
} from "../email-triage/policy_gate.ts";

// =============================================================================
// Types
// =============================================================================

/** Persisted triage row (subset the send path needs). Mirrors the
 *  columns from `email_triage_results` + `email_threads` JOIN. */
export interface TriageRow {
  id: string;
  user_id: string;
  thread_id: string;
  /** email_threads.gmail_thread_id — needed for Gmail send's `threadId`. */
  gmail_thread_id: string;
  draft_language: string | null;
  draft_subject: string | null;
  draft_body: string | null;
  draft_to: string[];
  draft_cc: string[];
  send_recommendation: string;
  /** Persisted HMAC gate token (per 20260525190000 migration). May be
   *  null on older rows triaged before the column existed; the gate
   *  re-verification is skipped in that case with `gate_token_missing`. */
  gate_token: GateToken | null;
  /** Already-dispatched marker — `sent_at IS NOT NULL` means we have
   *  already pushed this draft to Gmail. The HTTP entry point treats
   *  that as an idempotent OK. */
  sent_at: string | null;
  sent_message_id: string | null;
  user_action: string | null;
}

/** RFC-822 Message-Id of the most-recent message in the thread — the
 *  one we are replying to. Used for the In-Reply-To + References
 *  headers so Gmail / Apple Mail / Outlook all thread the reply. */
export interface LastInboundMessage {
  /** Gmail message id (NOT rfc id). */
  gmail_message_id: string;
  /** RFC-2822 Message-ID. Null when the message did not carry one
   *  (rare; some bounces). When null we skip the In-Reply-To header. */
  rfc_message_id: string | null;
  /** Subject of the inbound — used for the Re: subject when the draft
   *  did not include one. */
  subject: string | null;
}

export interface EmailSendDeps {
  /** Load the triage row + thread.gmail_thread_id by id, scoped to the
   *  caller's user_id. Returns null if not found OR if the row belongs
   *  to a different user (RLS-friendly). */
  loadTriageForUser(triageId: string, userId: string): Promise<TriageRow | null>;
  /** Load the most-recent inbound message of the thread for header
   *  threading (`In-Reply-To`, `References`). Returns null on empty
   *  thread (theoretically impossible — triage requires ≥1 message). */
  loadLastInbound(threadId: string): Promise<LastInboundMessage | null>;
  /** Run the actual Gmail API call. Returns the Gmail-side message id. */
  sendViaGmail(args: SendArgs): Promise<{ id: string }>;
  /** Stamp `email_triage_results` after a successful send.
   *  Implementations must use the service-role client (RLS bypass) so
   *  the write happens server-side regardless of policy. */
  markSent(args: {
    triageId: string;
    userId: string;
    gmailMessageId: string;
    sentAt: string;
  }): Promise<void>;
  /** Update `email_threads.triage_status` after dispatch. */
  markThreadStatus(threadId: string, status: string): Promise<void>;
  /** Persist the dispatched message to the `correspondence` audit log. */
  appendCorrespondence(args: {
    userId: string;
    caseId: string | null;
    fromAddress: string;
    toAddress: string;
    ccAddress: string | null;
    subject: string;
    body: string;
    providerMessageId: string;
    sentAt: string;
  }): Promise<void>;
}

export interface SendArgs {
  accessToken: string;
  threadId: string; // Gmail thread id (NOT our internal uuid)
  from: string;
  to: string;
  cc?: string;
  subject: string;
  body: string;
  /** RFC-822 Message-IDs for header threading. */
  inReplyTo?: string | null;
  /** Comma-separated References chain (history). */
  references?: string | null;
}

// =============================================================================
// Validation
// =============================================================================

export interface ValidatedPayload {
  triageId: string;
  editedBody: string | null;
}

export interface PayloadError {
  error: string;
  status: number;
}

/** Coerce + validate the HTTP body. UUID-shape check kept loose so we
 *  don't have to ship a regex for every Postgres UUID variant; the
 *  Supabase query will return null on a malformed id. */
export function validatePayload(
  raw: unknown,
): { ok: true; value: ValidatedPayload } | { ok: false; err: PayloadError } {
  if (raw == null || typeof raw !== "object") {
    return { ok: false, err: { error: "Invalid JSON body", status: 400 } };
  }
  const obj = raw as Record<string, unknown>;
  const triageId = typeof obj.triage_id === "string" ? obj.triage_id.trim() : "";
  if (!triageId) {
    return {
      ok: false,
      err: { error: "triage_id is required", status: 400 },
    };
  }
  // Soft UUID shape check — we want to fail fast on garbage but not
  // gate on the exact variant. 30+ chars + dashes is sufficient noise.
  if (triageId.length < 30 || !triageId.includes("-")) {
    return {
      ok: false,
      err: { error: "triage_id is malformed", status: 400 },
    };
  }
  const editedRaw = obj.edited_body;
  let editedBody: string | null = null;
  if (editedRaw != null) {
    if (typeof editedRaw !== "string") {
      return {
        ok: false,
        err: { error: "edited_body must be a string", status: 400 },
      };
    }
    editedBody = editedRaw;
    // Hard cap — Gmail's per-message limit is 25 MB but we triage tiny
    // replies. 100 KB matches send-email's existing ceiling so a user
    // cannot blow up the audit row.
    if (editedBody.length > 100_000) {
      return {
        ok: false,
        err: { error: "edited_body too large (max 100 KB)", status: 400 },
      };
    }
  }
  return { ok: true, value: { triageId, editedBody } };
}

// =============================================================================
// Body selection
// =============================================================================

/** Pick the body that will actually go out and report whether the user
 *  edited it (drives the quality re-check). */
export function pickOutgoingBody(
  row: TriageRow,
  editedBody: string | null,
): { body: string; wasEdited: boolean } {
  const draft = row.draft_body ?? "";
  if (editedBody == null) {
    return { body: draft, wasEdited: false };
  }
  // Treat whitespace-only edits as no edit — avoids a stray newline in
  // the edit screen tripping a fresh gate check.
  if (editedBody.trim() === draft.trim()) {
    return { body: draft, wasEdited: false };
  }
  return { body: editedBody, wasEdited: true };
}

// =============================================================================
// HMAC gate re-verification
// =============================================================================

export type GateVerifyOutcome =
  | { kind: "ok" }
  | { kind: "skipped"; reason: "gate_token_missing" }
  | { kind: "fail"; reason: string };

/**
 * Re-verify the HMAC gate token against the live body + recipients.
 * Caller is expected to have already swapped the body to the user's
 * edited body when they made edits — the gate intentionally fails on a
 * body mismatch in that case, which is what we want: any edit forces
 * the user to re-confirm via the policy gate (run by claude-proxy /
 * email-triage rerun, not here).
 *
 * Returns `skipped` when the row was triaged before the gate_token
 * column existed (older rows have null). The HTTP layer treats that as
 * an audit-only warning, not a hard block — Phase 1 already dispatched
 * via the existing send-email path without HMAC at all.
 */
export async function verifyTriageGate(args: {
  row: TriageRow;
  outgoingBody: string;
  secret: string;
  now?: number;
}): Promise<GateVerifyOutcome> {
  const token = args.row.gate_token;
  if (!token) {
    return { kind: "skipped", reason: "gate_token_missing" };
  }
  const recipients = [
    ...(args.row.draft_to ?? []),
    ...(args.row.draft_cc ?? []),
  ];
  const expectedBodySha = await sha256Hex(args.outgoingBody);
  const result = await verifyGateToken({
    token,
    expected_draft_id: args.row.id,
    expected_body_sha256: expectedBodySha,
    expected_recipients: recipients,
    secret: args.secret,
    now: args.now,
  });
  if (result.ok) return { kind: "ok" };
  return { kind: "fail", reason: result.reason ?? "unknown_gate_failure" };
}

// =============================================================================
// Threading headers
// =============================================================================

/**
 * Build the In-Reply-To + References header values for a reply. Both
 * fields are RFC-822 Message-IDs wrapped in `<…>`; the References chain
 * concatenates prior message ids if any (we only have the most-recent
 * inbound at this layer, but Gmail's own client will re-stitch the
 * full chain when it imports the sent message).
 *
 * Returns `null` when we don't have a Message-ID to thread against —
 * the reply still goes out, just without explicit threading metadata.
 */
export function buildThreadingHeaders(
  last: LastInboundMessage | null,
): { inReplyTo: string | null; references: string | null } {
  if (!last || !last.rfc_message_id) {
    return { inReplyTo: null, references: null };
  }
  const id = last.rfc_message_id.trim();
  // Some senders forget the angle brackets; normalise.
  const normalised = id.startsWith("<") && id.endsWith(">") ? id : `<${id}>`;
  return { inReplyTo: normalised, references: normalised };
}

// =============================================================================
// Subject Re: handling
// =============================================================================

const RE_PREFIX_RE = /^(?:re|fwd?|vs|vastaus|edasi|пере)\s*:\s*/i;

/** Build a reply subject. Prefer the persisted draft subject; if the
 *  draft did not include one, fall back to the inbound subject with a
 *  `Re:` prefix unless one is already there. */
export function buildReplySubject(
  draftSubject: string | null,
  inboundSubject: string | null,
): string {
  const draft = (draftSubject ?? "").trim();
  if (draft.length > 0) return draft;
  const inbound = (inboundSubject ?? "").trim();
  if (inbound.length === 0) return "Re:";
  if (RE_PREFIX_RE.test(inbound)) return inbound;
  return `Re: ${inbound}`;
}

// =============================================================================
// Edited-body quality re-check
// =============================================================================

/**
 * When the user edited the draft body, re-run the email-quality gate
 * so a hand-written reply still meets the loaded-language /
 * language-match floor. Returns a structured pass/fail.
 *
 * When the user did NOT edit, we trust the original quality run that
 * the email-triage pipeline already did and skip this check.
 *
 * Note: the quality module's `expected_language` is the contract's
 * original language for the Contract Review feature. Here we use the
 * draft's `draft_language` field as the floor — that's the language
 * the model targeted for the reply. If the draft has no language tag,
 * we skip the language-match issue (set "und" so the check is
 * permissive).
 */
export function recheckEditedBody(args: {
  body: string;
  draftLanguage: string | null;
}): EmailQualityReport {
  const expected = (args.draftLanguage ?? "und").toLowerCase().trim();
  return checkEmailQuality({
    email: args.body,
    expectedLanguage: expected || "und",
  });
}

// =============================================================================
// Sentinel for idempotent re-send
// =============================================================================

/** Returns the prior dispatch when the row was already sent. The HTTP
 *  layer turns this into a 200 OK with the original gmail_message_id —
 *  the UI cannot tell the difference, and the user does not get a
 *  second copy of the same reply.  */
export function priorDispatch(
  row: TriageRow,
): { gmailMessageId: string; sentAt: string } | null {
  if (row.sent_at && row.sent_message_id) {
    return {
      gmailMessageId: row.sent_message_id,
      sentAt: row.sent_at,
    };
  }
  return null;
}
