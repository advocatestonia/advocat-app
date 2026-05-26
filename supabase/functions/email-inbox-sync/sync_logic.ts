// email-inbox-sync/sync_logic.ts
// -----------------------------------------------------------------------------
// Pure logic helpers for the D3 inbox-sync edge function.
//
// We split logic from index.ts (HTTP serve + Supabase client wiring) so the
// loop can be tested without booting Deno's HTTP listener. The Gmail API +
// Supabase client are passed in as a `MinimalSyncDeps` interface; tests
// inject a fake.
//
// Body cap: each persisted message is hard-capped at 50 KB (`BODY_CAP_BYTES`).
// `truncateBody` cuts at the byte boundary using TextEncoder so multi-byte
// UTF-8 chars do not split. `dropOldQuoteChains` drops quoted reply chains
// older than 30 days — Layer 3 of memory protocol does not need them.
// -----------------------------------------------------------------------------

/** Hard body cap per persisted message (50 KB per spec). */
export const BODY_CAP_BYTES = 50_000;

/** Quoted reply chain cutoff — drop quotes older than this (per spec). */
export const QUOTE_CHAIN_CUTOFF_DAYS = 30;

/** Cron tick window — only fetch threads since (now - DEFAULT_LOOKBACK_MS). */
export const DEFAULT_LOOKBACK_MS = 7 * 24 * 3600 * 1000;

/** Max threads fetched per tick — bounded so a backlogged inbox cannot DoS the model. */
export const MAX_THREADS_PER_TICK = 50;

/** Max attachments downloaded per thread per tick — Fix #1 (2026-05-26). */
export const MAX_ATTACHMENTS_PER_THREAD = 10;

/** MIME prefixes we will download. Other binaries (zip, exe, …) are ignored. */
export const DOWNLOADABLE_MIME_PREFIXES = [
  "application/pdf",
  "image/",
];

/**
 * Decide whether an attachment is one we know how to deal with downstream
 * (pdf-parser handles PDFs; images route through Vision OCR). Other types
 * are intentionally skipped — D4 triage cannot make use of them and the
 * 50 MB cap is per-attachment, so an unused 50 MB zip would just burn
 * Storage quota.
 */
export function isDownloadableMime(mime: string): boolean {
  const m = (mime || "").toLowerCase();
  return DOWNLOADABLE_MIME_PREFIXES.some((p) => m === p || m.startsWith(p));
}

// =============================================================================
// Types
// =============================================================================

export interface GmailMessage {
  id: string;
  threadId: string;
  rfcMessageId?: string | null;
  senderEmail: string;
  senderName?: string | null;
  toRecipients: string[];
  ccRecipients: string[];
  subject?: string | null;
  bodyPlaintext?: string | null;
  snippet?: string | null;
  sentAt: string; // ISO
  hasAttachments: boolean;
  attachmentsMeta: Array<{ filename: string; mime: string; size_bytes: number }>;
  /**
   * Attachment metadata WITH Gmail attachment ids — populated by
   * parseGmailMessage. D3 sync uses this to fan out
   * [MinimalSyncDeps.downloadAndStoreAttachment] calls. Stays separate from
   * `attachmentsMeta` (which is persisted on the message row as a stable
   * JSONB shape, no id leakage).
   */
  attachmentsWithIds?: Array<{
    filename: string;
    mime: string;
    size_bytes: number;
    gmail_attachment_id: string;
  }>;
  headersMeta: Record<string, string>;
}

export interface GmailThreadFull {
  threadId: string;
  historyId?: string | null;
  snippet?: string | null;
  subject?: string | null;
  participants: string[];
  labelIds: string[];
  lastMessageAt: string; // ISO
  messages: GmailMessage[]; // oldest first
}

export interface ThreadUpsertRow {
  user_id: string;
  case_id: string | null;
  gmail_thread_id: string;
  last_message_at: string;
  last_synced_at: string;
  snippet: string | null;
  subject: string | null;
  participants: string[];
  label_ids: string[];
  triage_status: "pending" | "triaged" | "skipped" | "handled-auto"
    | "archived" | "spam" | "error";
  last_history_id: string | null;
}

export interface MessageUpsertRow {
  thread_id: string; // FK uuid
  user_id: string;
  gmail_message_id: string;
  rfc_message_id: string | null;
  sender_email: string;
  sender_name: string | null;
  to_recipients: string[];
  cc_recipients: string[];
  subject: string | null;
  body_plaintext: string | null;
  snippet: string | null;
  sent_at: string;
  has_attachments: boolean;
  attachments_meta: Array<{ filename: string; mime: string; size_bytes: number }>;
  headers_meta: Record<string, string>;
}

export interface MinimalSyncDeps {
  /** Read the previously stored sync cursor (max last_synced_at) for a user. */
  getLastSyncedAt(userId: string): Promise<Date | null>;
  /** Gmail API: list threads since `since`. Returns thread ids. */
  listThreads(args: {
    accessToken: string;
    sinceMs: number;
    maxResults: number;
  }): Promise<Array<{ id: string; historyId?: string | null }>>;
  /** Gmail API: fetch one full thread with all messages. */
  getThread(args: {
    accessToken: string;
    threadId: string;
  }): Promise<GmailThreadFull | null>;
  /**
   * Upsert thread by (user_id, gmail_thread_id). Returns the thread row's
   * uuid PK so the caller can FK the message rows. Implementations bump
   * `triage_status` to 'pending' only when the row is new or
   * last_message_at advanced.
   */
  upsertThread(row: ThreadUpsertRow): Promise<{ id: string; isNewOrAdvanced: boolean }>;
  /**
   * Bulk upsert messages by gmail_message_id. Returns the count of rows
   * upserted AND a lookup map from gmail_message_id → uuid PK (needed by
   * the attachment-download fan-out in Fix #1). Existing tests that only
   * inspect `.count` keep working; new code reads `.idByGmailId`.
   */
  upsertMessages(rows: MessageUpsertRow[]): Promise<{
    count: number;
    idByGmailId: Record<string, string>;
  }>;
  /**
   * Best-effort: enqueue the thread for triage (D4). In tests this is a
   * no-op spy. In prod this calls the email-triage edge fn (or writes a
   * task row). Failures are swallowed — the next tick will retry.
   */
  enqueueTriage(args: { userId: string; threadId: string }): Promise<void>;
  /**
   * Optional sidecar: record an `email_in` event on the case timeline.
   * Called only when a thread is new or has advanced. The prod impl
   * reads the thread row's `case_id` and writes via the
   * `record_case_event` RPC; if the thread is not linked to a case it
   * no-ops. Test fakes can leave this undefined.
   */
  recordTimelineEvent?(args: {
    threadDbId: string;
    subject: string | null;
    snippet: string | null;
    lastMessageAt: string;
  }): Promise<void>;
  /**
   * Fix #1 (2026-05-26): download one attachment binary + persist to Storage
   * + insert email_attachments row. Implementations call
   * [downloadAttachment], upload to `case-documents/{userId}/email_attachments/`,
   * then insert. Test fakes can leave this undefined (sync skips the
   * download leg entirely). The impl SHOULD be idempotent on
   * (message_db_id, gmail_attachment_id) — the unique constraint enforces
   * it at the DB layer too.
   */
  downloadAndStoreAttachment?(args: {
    userId: string;
    threadDbId: string;
    messageDbId: string;
    gmailMessageId: string;
    attachment: {
      filename: string;
      mime: string;
      size_bytes: number;
      gmail_attachment_id: string;
    };
    accessToken: string;
  }): Promise<{ inserted: boolean; skipped_reason?: string }>;
}

// =============================================================================
// Pure helpers
// =============================================================================

/**
 * Truncate a UTF-8 body to at most `cap` bytes. Pure: never throws. Cuts at
 * the byte boundary; TextEncoder handles multi-byte chars cleanly because
 * we slice the encoded array, not the source string. A trailing
 * placeholder `[…truncated]` is appended only when truncation actually
 * happened, and never makes the result exceed `cap`.
 */
export function truncateBody(
  body: string | null | undefined,
  cap: number = BODY_CAP_BYTES,
): string | null {
  if (body == null) return null;
  const enc = new TextEncoder();
  const bytes = enc.encode(body);
  if (bytes.length <= cap) return body;
  const placeholder = "\n\n[…truncated]";
  const placeholderBytes = enc.encode(placeholder);
  // Reserve space for the placeholder. If `cap` is too small to hold the
  // placeholder itself (pathological), just hard-truncate.
  const usable = cap - placeholderBytes.length;
  if (usable <= 0) {
    return new TextDecoder("utf-8", { fatal: false })
      .decode(bytes.slice(0, cap));
  }
  // Find a safe UTF-8 boundary at or below `usable` bytes.
  let cut = usable;
  while (cut > 0 && (bytes[cut] & 0xc0) === 0x80) {
    cut--; // step back over continuation bytes
  }
  const head = new TextDecoder("utf-8", { fatal: false })
    .decode(bytes.slice(0, cut));
  return head + placeholder;
}

/**
 * Drop quoted reply chains older than `cutoffDays` from a plaintext body.
 * Heuristic: matches "On <date>… wrote:" and ">" prefix runs older than
 * the cutoff. Conservative — when in doubt, keep the quote (the model can
 * read it; the cap above bounds size).
 *
 * The detector is intentionally simple: we look for the most common reply
 * prelude formats produced by Gmail / Outlook / Apple Mail in EN/FI/ET/RU
 * and clip everything after it when the embedded date is older than the
 * cutoff. If no detectable prelude is found, returns the body unchanged.
 */
export function dropOldQuoteChains(
  body: string | null | undefined,
  now: Date = new Date(),
  cutoffDays: number = QUOTE_CHAIN_CUTOFF_DAYS,
): string | null {
  if (body == null) return null;
  const cutoffMs = now.getTime() - cutoffDays * 24 * 3600 * 1000;
  // Common reply preludes; capture group 1 is the date string.
  const preludes: RegExp[] = [
    // "On Mon, May 5, 2026 at 09:14 Foo Bar <foo@x.com> wrote:"
    /^On\s+([A-Za-z]{3},\s+[A-Za-z]+\s+\d{1,2},\s+\d{4})/m,
    // "On 2026-05-05 09:14, Foo Bar wrote:"
    /^On\s+(\d{4}-\d{2}-\d{2})/m,
    // "Le 2026-05-05 09:14, Foo Bar a écrit :"
    /^Le\s+(\d{4}-\d{2}-\d{2})/m,
    // "5.5.2026 9.14, Foo Bar kirjoitti:"  (FI)
    /^(\d{1,2}\.\d{1,2}\.\d{4})/m,
    // "5.05.2026, Foo Bar kirjutas:"  (ET)
    /^(\d{1,2}\.\d{1,2}\.\d{4})/m,
    // RFC 2822 ish: "5 May 2026 09:14:00"
    /^(\d{1,2}\s+[A-Za-z]+\s+\d{4})/m,
  ];
  for (const re of preludes) {
    const match = re.exec(body);
    if (!match) continue;
    const dateStr = match[1];
    const parsed = parseLooseDate(dateStr);
    if (parsed == null) continue;
    if (parsed.getTime() >= cutoffMs) {
      // Quote prelude is recent — keep entire body.
      return body;
    }
    // Cut at prelude position and append a marker.
    const head = body.slice(0, match.index).trimEnd();
    return `${head}\n\n[…older quote dropped: > ${cutoffDays}d]`;
  }
  return body;
}

/** Best-effort date parser used by [dropOldQuoteChains]. */
function parseLooseDate(s: string): Date | null {
  // ISO-like first
  const iso = /^(\d{4})-(\d{2})-(\d{2})$/.exec(s);
  if (iso) {
    const d = new Date(Date.UTC(+iso[1], +iso[2] - 1, +iso[3]));
    return isNaN(d.getTime()) ? null : d;
  }
  // "DD.MM.YYYY" — common in FI/ET/RU
  const dmy = /^(\d{1,2})\.(\d{1,2})\.(\d{4})$/.exec(s);
  if (dmy) {
    const d = new Date(Date.UTC(+dmy[3], +dmy[2] - 1, +dmy[1]));
    return isNaN(d.getTime()) ? null : d;
  }
  // Fallback to JS Date parser (handles "Mon, May 5, 2026", "5 May 2026", …).
  const ms = Date.parse(s);
  if (isFinite(ms)) return new Date(ms);
  return null;
}

/**
 * Convert a fetched Gmail thread to the DB upsert shape. Pure — no I/O. The
 * `userId`, `caseId`, and `now` are injected so the same function can be
 * unit-tested deterministically.
 */
export function toThreadRow(
  args: {
    userId: string;
    caseId: string | null;
    thread: GmailThreadFull;
    nowIso: string;
  },
): ThreadUpsertRow {
  const t = args.thread;
  return {
    user_id: args.userId,
    case_id: args.caseId,
    gmail_thread_id: t.threadId,
    last_message_at: t.lastMessageAt,
    last_synced_at: args.nowIso,
    snippet: t.snippet ?? null,
    subject: t.subject ?? null,
    participants: t.participants ?? [],
    label_ids: t.labelIds ?? [],
    triage_status: "pending",
    last_history_id: t.historyId ?? null,
  };
}

/**
 * Convert one Gmail message (post-truncation) to the DB row shape. Pure.
 */
export function toMessageRow(
  args: {
    threadDbId: string;
    userId: string;
    msg: GmailMessage;
    now?: Date;
  },
): MessageUpsertRow {
  const now = args.now ?? new Date();
  const cleanedQuotes = dropOldQuoteChains(args.msg.bodyPlaintext, now);
  const capped = truncateBody(cleanedQuotes, BODY_CAP_BYTES);
  return {
    thread_id: args.threadDbId,
    user_id: args.userId,
    gmail_message_id: args.msg.id,
    rfc_message_id: args.msg.rfcMessageId ?? null,
    sender_email: args.msg.senderEmail,
    sender_name: args.msg.senderName ?? null,
    to_recipients: args.msg.toRecipients ?? [],
    cc_recipients: args.msg.ccRecipients ?? [],
    subject: args.msg.subject ?? null,
    body_plaintext: capped,
    snippet: args.msg.snippet ?? null,
    sent_at: args.msg.sentAt,
    has_attachments: args.msg.hasAttachments,
    attachments_meta: args.msg.attachmentsMeta ?? [],
    headers_meta: args.msg.headersMeta ?? {},
  };
}

/** Keep at most the last N messages of a thread (oldest dropped). */
export function lastNMessages(msgs: GmailMessage[], n: number = 5): GmailMessage[] {
  if (msgs.length <= n) return msgs;
  // Stable sort by sentAt asc (defensive — Gmail returns asc but explicit is safer)
  const sorted = [...msgs].sort((a, b) => a.sentAt.localeCompare(b.sentAt));
  return sorted.slice(-n);
}

// =============================================================================
// Loop
// =============================================================================

export interface SyncResult {
  threads_synced: number;
  threads_skipped_unchanged: number;
  messages_upserted: number;
  triages_enqueued: number;
  errors: number;
  attachments_downloaded: number;
  attachments_skipped: number;
}

/**
 * Run one sync tick for a single user. Pure orchestration — all I/O is
 * delegated to `deps`. Failures on one thread do not abort the whole tick.
 *
 * `lookbackMs` is the floor for the Gmail query; the effective `since`
 * is `max(lastSyncedAt, now - lookbackMs)`. This bounds the tick when a
 * user has never been synced + bounds it again on a regular cadence so a
 * stale cursor cannot pull years of mail in one go.
 */
export async function runSyncTick(
  deps: MinimalSyncDeps,
  args: {
    userId: string;
    accessToken: string;
    now?: Date;
    lookbackMs?: number;
    maxThreads?: number;
  },
): Promise<SyncResult> {
  const now = args.now ?? new Date();
  const lookbackMs = args.lookbackMs ?? DEFAULT_LOOKBACK_MS;
  const maxThreads = Math.min(
    args.maxThreads ?? MAX_THREADS_PER_TICK,
    MAX_THREADS_PER_TICK,
  );

  const lastSyncedAt = await deps.getLastSyncedAt(args.userId);
  const sinceMs = Math.max(
    lastSyncedAt?.getTime() ?? 0,
    now.getTime() - lookbackMs,
  );

  const result: SyncResult = {
    threads_synced: 0,
    threads_skipped_unchanged: 0,
    messages_upserted: 0,
    triages_enqueued: 0,
    errors: 0,
    attachments_downloaded: 0,
    attachments_skipped: 0,
  };

  const threads = await deps.listThreads({
    accessToken: args.accessToken,
    sinceMs,
    maxResults: maxThreads,
  });

  for (const t of threads) {
    try {
      const full = await deps.getThread({
        accessToken: args.accessToken,
        threadId: t.id,
      });
      if (!full) {
        result.errors++;
        continue;
      }
      const threadRow = toThreadRow({
        userId: args.userId,
        caseId: null, // D3 does not infer case linkage; D4 may upgrade later
        thread: full,
        nowIso: now.toISOString(),
      });
      const upsert = await deps.upsertThread(threadRow);
      if (!upsert.isNewOrAdvanced) {
        result.threads_skipped_unchanged++;
        continue;
      }
      const lastFive = lastNMessages(full.messages, 5);
      const msgRows = lastFive.map((msg) =>
        toMessageRow({
          threadDbId: upsert.id,
          userId: args.userId,
          msg,
          now,
        })
      );
      const inserted = await deps.upsertMessages(msgRows);
      result.messages_upserted += inserted.count;
      result.threads_synced++;

      // Fix #1 (2026-05-26): fan out attachment downloads. Per-thread cap
      // [MAX_ATTACHMENTS_PER_THREAD] = 10 — overflow logged + skipped.
      // Per-attachment cap [MAX_ATTACHMENT_BYTES] = 50 MB enforced by
      // [downloadAttachment] itself. Only PDFs + images flow through (rest
      // would be dead Storage weight). Failures here NEVER abort the rest
      // of the tick — D4 triage will still run on bytes-less metadata.
      if (deps.downloadAndStoreAttachment) {
        let threadAttCount = 0;
        for (const msg of lastFive) {
          const messageDbId = inserted.idByGmailId[msg.id];
          if (!messageDbId) continue; // message wasn't upserted (rare)
          for (const att of (msg.attachmentsWithIds ?? [])) {
            if (threadAttCount >= MAX_ATTACHMENTS_PER_THREAD) {
              result.attachments_skipped++;
              continue;
            }
            if (!isDownloadableMime(att.mime)) {
              result.attachments_skipped++;
              continue;
            }
            try {
              const res = await deps.downloadAndStoreAttachment({
                userId: args.userId,
                threadDbId: upsert.id,
                messageDbId,
                gmailMessageId: msg.id,
                attachment: att,
                accessToken: args.accessToken,
              });
              if (res.inserted) {
                result.attachments_downloaded++;
                threadAttCount++;
              } else {
                result.attachments_skipped++;
              }
            } catch (e) {
              console.warn(
                `email-inbox-sync: attachment ${att.gmail_attachment_id} failed: ${String(e).slice(0, 200)}`,
              );
              result.attachments_skipped++;
            }
          }
        }
      }

      // Sidecar: timeline event when the thread is linked to a case.
      // toThreadRow above always sets case_id=null in D3 (we do not
      // infer case linkage here); a thread becomes case-linked when the
      // user attaches it or when email-triage assigns one. The prod
      // impl reads case_id from the row at write time and no-ops if
      // still null. Test fakes can leave this dep undefined.
      if (deps.recordTimelineEvent) {
        try {
          await deps.recordTimelineEvent({
            threadDbId: upsert.id,
            subject: full.subject ?? null,
            snippet: full.snippet ?? null,
            lastMessageAt: full.lastMessageAt,
          });
        } catch (_e) { /* swallow — sidecar */ }
      }

      // Best-effort triage enqueue.
      try {
        await deps.enqueueTriage({
          userId: args.userId,
          threadId: upsert.id,
        });
        result.triages_enqueued++;
      } catch (_e) {
        // Triage enqueue failure is recoverable; the next tick will retry.
        result.errors++;
      }
    } catch (e) {
      console.warn(
        `email-inbox-sync: thread ${t.id} failed: ${String(e).slice(0, 200)}`,
      );
      result.errors++;
    }
  }

  return result;
}
