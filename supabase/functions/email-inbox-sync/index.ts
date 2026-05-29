// supabase/functions/email-inbox-sync/index.ts
// -----------------------------------------------------------------------------
// D3 — proactive Gmail inbox sync. Fired every 5 min by pg_cron OR by a
// user clicking "sync now" in the Inbox UI. Polls the user's Gmail with
// the gmail.readonly scope (D1), upserts threads + last-5-messages into
// the Postgres tables created in D2, and best-effort enqueues each
// new/changed thread for triage (D4).
//
// The HTTP entrypoint accepts two modes:
//
//   1. POST with `Authorization: Bearer <user JWT>` and `{ "user_id": "..." }`
//      optional — runs a sync tick for the calling user (Inbox UI hook).
//
//   2. POST with `x-cron-secret: <CRON_SECRET>` — runs a sync tick for every
//      user that has a Gmail token row. Used by pg_cron.
//
// Hard rules:
//   * Body cap 50 KB per persisted message (sync_logic#truncateBody).
//   * Quoted reply chains older than 30 days dropped (sync_logic#dropOldQuoteChains).
//   * Idempotency by (user_id, gmail_thread_id) on threads, gmail_message_id on
//     messages. Same thread re-fetched without changes is a no-op (the
//     upsertThread helper checks last_message_at advanced).
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "@supabase/supabase-js";

import { corsHeaders, jsonError, jsonOk } from "../_shared/auth.ts";
import { ensureFreshToken, loadGmailToken } from "../_shared/gmail_token.ts";
import { checkCronSecret } from "../agent-intentions-cron/auth_gate.ts";
import { downloadAttachment, getThreadFull, listThreads } from "./gmail_api.ts";
import {
  type MessageUpsertRow,
  type MinimalSyncDeps,
  runSyncTick,
  type SyncResult,
  type ThreadUpsertRow,
} from "./sync_logic.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const TRIAGE_FN_URL = (Deno.env.get("SUPABASE_URL") ?? "")
  .replace(/\/$/, "") + "/functions/v1/email-triage";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  const cronHeader = req.headers.get("x-cron-secret");
  if (cronHeader) {
    const gate = checkCronSecret(cronHeader, Deno.env.get("CRON_SECRET"));
    if (gate.kind === "deny") {
      return jsonError(gate.body.error, gate.status);
    }
    return await handleCronTick();
  }

  // Per-user mode — JWT-authed.
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return jsonError("Unauthorized", 401);
  }
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const token = authHeader.replace("Bearer ", "");
  const { data: userData, error: authError } = await supabase.auth
    .getUser(token);
  if (authError || !userData?.user) {
    return jsonError("Invalid session", 401);
  }
  const result = await syncUser(userData.user.id);
  return jsonOk(result);
});

// =============================================================================
// Cron path — sync every user with a Gmail token
// =============================================================================

async function handleCronTick(): Promise<Response> {
  const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  // Bounded fan-out — at most 50 users per tick.
  const { data: tokens, error } = await sb
    .from("user_oauth_tokens")
    .select("user_id")
    .eq("provider", "gmail")
    .not("refresh_token", "is", null)
    .limit(50);
  if (error) {
    return jsonError("Token table read failed", 500, {
      details: String(error.message ?? error),
    });
  }
  const userIds = [...new Set((tokens ?? []).map((r) => r.user_id as string))];
  let totalThreads = 0;
  let totalErrors = 0;
  for (const uid of userIds) {
    try {
      const r = await syncUser(uid);
      // syncUser returns SyncResult-shaped JSON wrapped in jsonOk; here
      // we just touched it to drive the cron and don't aggregate the
      // body — keep response compact for telemetry.
      const body = await r.json();
      totalThreads += (body?.threads_synced ?? 0) as number;
      totalErrors += (body?.errors ?? 0) as number;
    } catch (_e) {
      totalErrors++;
    }
  }
  return jsonOk({
    users: userIds.length,
    threads_synced: totalThreads,
    errors: totalErrors,
  });
}

// =============================================================================
// Per-user sync
// =============================================================================

async function syncUser(userId: string): Promise<Response> {
  const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const tokenRow = await loadGmailToken(sb, userId);
  if (!tokenRow) {
    return jsonError("gmail_not_connected", 400);
  }
  const accessToken = await ensureFreshToken(sb, userId, tokenRow);
  if (!accessToken) {
    return jsonError("gmail_reauth_required", 401);
  }

  const deps = makeProdDeps(sb, userId);
  let result: SyncResult;
  try {
    result = await runSyncTick(deps, {
      userId,
      accessToken,
    });
  } catch (e) {
    return jsonError("sync_failed", 502, {
      details: String(e).slice(0, 200),
    });
  }
  return jsonOk({ ok: true, ...result });
}

// =============================================================================
// Production deps — Supabase + Gmail wiring
// =============================================================================

function makeProdDeps(
  // deno-lint-ignore no-explicit-any
  sb: any,
  _userId: string,
): MinimalSyncDeps {
  return {
    async getLastSyncedAt(userId: string): Promise<Date | null> {
      const { data, error } = await sb
        .from("email_threads")
        .select("last_synced_at")
        .eq("user_id", userId)
        .order("last_synced_at", { ascending: false, nullsFirst: false })
        .limit(1)
        .maybeSingle();
      if (error || !data?.last_synced_at) return null;
      const ms = Date.parse(data.last_synced_at as string);
      return isFinite(ms) ? new Date(ms) : null;
    },

    async listThreads(args) {
      return await listThreads(args);
    },

    async getThread(args) {
      return await getThreadFull(args);
    },

    async upsertThread(row: ThreadUpsertRow) {
      // First check whether the row exists to decide isNewOrAdvanced. We do
      // a read-then-upsert (two round-trips) intentionally — the alternative
      // (`returning=representation` on a unique conflict update) doesn't
      // tell us whether the row's last_message_at was actually advanced.
      const { data: prior } = await sb
        .from("email_threads")
        .select("id, last_message_at")
        .eq("user_id", row.user_id)
        .eq("gmail_thread_id", row.gmail_thread_id)
        .maybeSingle();
      let isNewOrAdvanced = false;
      let id: string;
      if (!prior) {
        const { data: ins, error: insErr } = await sb
          .from("email_threads")
          .insert(row)
          .select("id")
          .single();
        if (insErr || !ins) {
          throw new Error(`upsert insert: ${insErr?.message ?? "unknown"}`);
        }
        id = ins.id as string;
        isNewOrAdvanced = true;
      } else {
        const priorMs = Date.parse(prior.last_message_at as string);
        const newMs = Date.parse(row.last_message_at);
        if (isFinite(newMs) && (!isFinite(priorMs) || newMs > priorMs)) {
          isNewOrAdvanced = true;
        }
        // Always refresh the cursor + label_ids etc; only flip
        // triage_status to 'pending' when something advanced.
        const updateRow: Partial<ThreadUpsertRow> = {
          last_message_at: row.last_message_at,
          last_synced_at: row.last_synced_at,
          snippet: row.snippet,
          subject: row.subject,
          participants: row.participants,
          label_ids: row.label_ids,
          last_history_id: row.last_history_id,
        };
        if (isNewOrAdvanced) {
          updateRow.triage_status = "pending";
        }
        const { error: upErr } = await sb
          .from("email_threads")
          .update(updateRow)
          .eq("id", prior.id);
        if (upErr) {
          throw new Error(`upsert update: ${upErr.message}`);
        }
        id = prior.id as string;
      }
      return { id, isNewOrAdvanced };
    },

    async upsertMessages(rows: MessageUpsertRow[]) {
      if (rows.length === 0) return { count: 0, idByGmailId: {} };
      // Insert new rows (ignoreDuplicates keeps prior PK on conflict).
      const { data: inserted, error } = await sb
        .from("email_messages")
        .upsert(rows, { onConflict: "gmail_message_id", ignoreDuplicates: true })
        .select("id, gmail_message_id");
      if (error) throw new Error(`upsertMessages: ${error.message}`);

      const idByGmailId: Record<string, string> = {};
      for (const r of (inserted ?? []) as Array<
        { id: string; gmail_message_id: string }
      >) {
        idByGmailId[r.gmail_message_id] = r.id;
      }

      // For PRE-EXISTING rows we still need the uuid PK — attachment
      // downloads keyed by gmail_message_id need to FK back. Fetch any
      // missing ids in one round-trip.
      const missing = rows
        .map((r) => r.gmail_message_id)
        .filter((gid) => !(gid in idByGmailId));
      if (missing.length > 0) {
        const { data: existing, error: e2 } = await sb
          .from("email_messages")
          .select("id, gmail_message_id")
          .in("gmail_message_id", missing);
        if (e2) throw new Error(`upsertMessages select: ${e2.message}`);
        for (const r of (existing ?? []) as Array<
          { id: string; gmail_message_id: string }
        >) {
          idByGmailId[r.gmail_message_id] = r.id;
        }
      }

      return { count: inserted?.length ?? 0, idByGmailId };
    },

    /**
     * Fix #1 (2026-05-26) — download one Gmail attachment + upload to
     * Storage + insert email_attachments row. Idempotent on
     * (message_id, gmail_attachment_id) per the unique constraint. On
     * any error or duplicate we return `inserted=false` rather than
     * throwing — the caller treats it as a "skipped" not "errored" so
     * one bad attachment does not poison the whole thread.
     */
    async downloadAndStoreAttachment(args) {
      const att = args.attachment;
      // Cheap idempotency probe — if a row already exists, skip the fetch.
      const probe = await sb
        .from("email_attachments")
        .select("id")
        .eq("message_id", args.messageDbId)
        .eq("gmail_attachment_id", att.gmail_attachment_id)
        .maybeSingle();
      if (probe.data) return { inserted: false, skipped_reason: "duplicate" };

      // Pull bytes. downloadAttachment enforces 50 MB cap + base64url decode.
      let payload: { data: Uint8Array; size: number };
      try {
        payload = await downloadAttachment({
          accessToken: args.accessToken,
          messageId: args.gmailMessageId,
          attachmentId: att.gmail_attachment_id,
        });
      } catch (e) {
        console.warn(
          `email-inbox-sync: downloadAttachment ${att.gmail_attachment_id} failed: ${
            String(e).slice(0, 200)
          }`,
        );
        return { inserted: false, skipped_reason: "fetch_failed" };
      }

      // Storage path: case-documents/{user_id}/email_attachments/{rand}/{filename}.
      // SECURITY: att.filename is the attacker-controllable Gmail MIME part
      // name. Sanitize it before it enters a service-role storage path — an
      // unsanitized `../` could traverse out of the caller's `{userId}/`
      // prefix. The original (display) name is still kept verbatim in the
      // email_attachments.filename column below (parameterized write).
      const safeName = att.filename
        .replace(/[^a-zA-Z0-9._-]/g, "_")
        .replace(/\.{2,}/g, "_")
        .slice(0, 120) || "attachment";
      const rand = crypto.randomUUID();
      const storagePath =
        `${args.userId}/email_attachments/${rand}/${safeName}`;
      const { error: upErr } = await sb.storage
        .from("case-documents")
        .upload(storagePath, payload.data, {
          contentType: att.mime || "application/octet-stream",
          upsert: false,
        });
      if (upErr) {
        console.warn(
          `email-inbox-sync: storage upload failed for ${att.filename}: ${upErr.message}`,
        );
        return { inserted: false, skipped_reason: "storage_failed" };
      }

      const { error: insErr } = await sb.from("email_attachments").insert({
        message_id: args.messageDbId,
        thread_id: args.threadDbId,
        user_id: args.userId,
        filename: att.filename,
        mime: att.mime || "application/octet-stream",
        size_bytes: payload.size,
        storage_path: storagePath,
        gmail_attachment_id: att.gmail_attachment_id,
      });
      if (insErr) {
        console.warn(
          `email-inbox-sync: email_attachments insert failed: ${insErr.message}`,
        );
        // Best-effort cleanup of the orphaned blob.
        try {
          await sb.storage.from("case-documents").remove([storagePath]);
        } catch (_e) { /* swallow */ }
        return { inserted: false, skipped_reason: "insert_failed" };
      }
      return { inserted: true };
    },

    async enqueueTriage(args) {
      // Best-effort fire-and-forget POST to the email-triage edge fn.
      // We intentionally do not await the response body — the triage
      // function is async and will write its own row.
      try {
        await fetch(TRIAGE_FN_URL, {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
            "Content-Type": "application/json",
            "x-internal-call": "email-inbox-sync",
          },
          body: JSON.stringify({
            thread_id: args.threadId,
            user_id: args.userId,
          }),
        });
      } catch (_e) {
        // Failure is recoverable; cron will re-discover the thread.
      }
    },

    async recordTimelineEvent(args) {
      // Read the thread's current case_id — when null (most common path)
      // we no-op. When linked, append an `email_in` event idempotently
      // keyed by the gmail thread db id.
      try {
        const { data: row } = await sb
          .from("email_threads")
          .select("case_id")
          .eq("id", args.threadDbId)
          .maybeSingle();
        const caseId = row?.case_id as string | null;
        if (!caseId) return;
        await sb.rpc("record_case_event", {
          p_case_id: caseId,
          p_event_type: "email_in",
          p_title: (args.subject ?? "(no subject)").slice(0, 200),
          p_summary: args.snippet ? args.snippet.slice(0, 500) : null,
          p_payload: {
            thread_id: args.threadDbId,
            subject: args.subject,
            dedupe_key: `thread:${args.threadDbId}:${args.lastMessageAt}`,
          },
          p_occurred_at: args.lastMessageAt,
        });
      } catch (_e) { /* swallow — sidecar */ }
    },
  };
}
