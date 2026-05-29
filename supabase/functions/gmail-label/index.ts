// gmail-label Edge Function — carry-over Task 4
// -----------------------------------------------------------------------------
// Mirror local Inbox actions onto the user's Gmail labels.
//
// Wire format (locked by lib/services/assistant_tools.dart::_archiveThread —
// added with the carry-over patch):
//
//   POST /functions/v1/gmail-label
//   Bearer <user JWT>
//   {
//     "thread_id":     string,    -- email_threads.id (uuid). Server looks
//                                    up gmail_thread_id + ownership in
//                                    one query (cheaper than asking the
//                                    client to know two ids).
//     "add_labels":    string[],  -- ["advocat:auto-archived", ...]   optional
//     "remove_labels": string[]   -- ["INBOX", ...]                    optional
//   }
//
//   200 OK
//   { "ok": true,
//     "applied":     ["advocat:auto-archived"],
//     "removed":     ["INBOX"],
//     "label_ids":   { "advocat:auto-archived": "Label_5483" } }
//
//   200 OK   (Gmail soft-fail — local archive must still succeed)
//   { "ok": false,
//     "error_code": "gmail_unavailable" | "gmail_reauth_required",
//     "detail":     string }
//
// Why a NEW edge fn (not extending send-email):
//   send-email is for OUTGOING messages and writes to `correspondence`.
//   Mixing label management into it is wrong-scope; D7 of the integration
//   spec called this out as a follow-up. We keep the new function tiny:
//   load token (existing _shared/gmail_token.ts), find/create the label,
//   POST to Gmail API users.threads.modify.
//
// Soft-fail policy: any Gmail-side error returns HTTP 200 with
// `{ok:false, error_code}`. The client treats this as "label sync failed,
// local action still succeeded — show undo, don't block UX". This matches
// the policy in §D6 of 09_INTEGRATION_INTO_ADVOCAT.md.
//
// Auth: requires user JWT (no anon, no cron). The thread_id is owned by
// the caller's Gmail account — Gmail's own access control does the
// boundary check.
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import {
  ensureFreshToken,
  loadGmailToken,
} from "../_shared/gmail_token.ts";
import {
  applyLabels,
  sanitiseGmailThreadId,
  sanitiseLabels,
  sanitiseUuid,
} from "./labels.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

interface RequestBody {
  thread_id?: unknown;
  add_labels?: unknown;
  remove_labels?: unknown;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  let body: RequestBody;
  try {
    body = await req.json();
  } catch (_e) {
    return jsonError("Invalid JSON body", 400);
  }

  const localThreadId = sanitiseUuid(body.thread_id);
  if (!localThreadId) return jsonError("thread_id is required", 400);
  const addLabels = sanitiseLabels(body.add_labels);
  const removeLabels = sanitiseLabels(body.remove_labels);
  if (addLabels.length === 0 && removeLabels.length === 0) {
    return jsonError("at least one of add_labels/remove_labels required", 400);
  }

  // SECURITY (Wave-1 2026-05-28, audit P1-10):
  // Previously this fn did `sb.auth.getUser(token)` without the U1 role/aud
  // check AND had no rate limit, so a forged JWT or anon-key-shaped token
  // could call Gmail users.threads.modify at unlimited rate, locking the
  // legitimate user out of Gmail until Google's per-day quota window
  // reset. `requireUserWithRateLimit` closes both holes in one call.
  const gate = await requireUserWithRateLimit(req, {
    bucket: "gmail-label",
    maxPerMinute: 20,
  });
  if (gate.kind === "deny") return gate.response;
  const userId = gate.user.id;
  const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  // Resolve email_threads.id → gmail_thread_id with ownership check in
  // one query. RLS would also enforce this; we use service role for the
  // read but pin user_id to be defensive.
  const { data: threadRow, error: threadErr } = await sb
    .from("email_threads")
    .select("gmail_thread_id, user_id, triage_status")
    .eq("id", localThreadId)
    .eq("user_id", userId)
    .maybeSingle();
  if (threadErr || !threadRow) {
    return jsonError("thread_not_found", 404);
  }
  const gmailThreadId = sanitiseGmailThreadId(threadRow.gmail_thread_id);
  if (!gmailThreadId) {
    return jsonError("missing_gmail_thread_id", 422);
  }

  // Load + refresh Gmail token. Soft-fail: 200 with error_code.
  const tokenRow = await loadGmailToken(sb, userId);
  if (!tokenRow) {
    return jsonOk({
      ok: false,
      error_code: "gmail_not_connected",
      detail: "Gmail not connected for this user.",
    });
  }
  const accessToken = await ensureFreshToken(sb, userId, tokenRow);
  if (!accessToken) {
    return jsonOk({
      ok: false,
      error_code: "gmail_reauth_required",
      detail: "Gmail token expired; reconnect Gmail.",
    });
  }

  try {
    const result = await applyLabels({
      accessToken,
      threadId: gmailThreadId,
      addLabels,
      removeLabels,
    });
    // Mirror in DB: when 'INBOX' is being removed (i.e. archive), flip
    // email_threads.triage_status='archived' so the local Inbox UI is
    // consistent with Gmail. Best-effort.
    if (removeLabels.includes("INBOX") &&
        threadRow.triage_status !== "archived") {
      try {
        await sb
          .from("email_threads")
          .update({ triage_status: "archived" })
          .eq("id", localThreadId);
      } catch (_e) { /* swallow */ }
    }
    return jsonOk({
      ok: true,
      applied: result.applied,
      removed: result.removed,
      label_ids: result.labelIds,
    });
  } catch (e) {
    return jsonOk({
      ok: false,
      error_code: "gmail_unavailable",
      detail: String(e).slice(0, 200),
    });
  }
});
