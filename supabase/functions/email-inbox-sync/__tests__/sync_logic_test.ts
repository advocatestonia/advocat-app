// Deno tests for email-inbox-sync/sync_logic.ts (D3, Email Agent integration).
// -----------------------------------------------------------------------------
// Pure logic tests only — the HTTP listener and Supabase wiring stay in
// index.ts and are exercised by post-deploy canary smokes. Here we lock:
//
//   * truncateBody    — UTF-8-safe byte cap, placeholder appended
//   * dropOldQuoteChains — quote prelude detection in EN/FI/ET formats
//   * lastNMessages   — keeps last 5
//   * runSyncTick     — idempotency: same thread no-ops the second tick
//   * runSyncTick     — body cap enforcement on persisted message
//   * runSyncTick     — failure on one thread does not abort the tick
//
// Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/email-inbox-sync/__tests__/sync_logic_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  BODY_CAP_BYTES,
  dropOldQuoteChains,
  type GmailMessage,
  type GmailThreadFull,
  lastNMessages,
  type MessageUpsertRow,
  type MinimalSyncDeps,
  QUOTE_CHAIN_CUTOFF_DAYS,
  runSyncTick,
  type ThreadUpsertRow,
  toMessageRow,
  toThreadRow,
  truncateBody,
} from "../sync_logic.ts";

// =============================================================================
// truncateBody
// =============================================================================

Deno.test("truncateBody — null in, null out", () => {
  assertEquals(truncateBody(null), null);
  assertEquals(truncateBody(undefined), null);
});

Deno.test("truncateBody — under cap unchanged", () => {
  const s = "hello world";
  assertEquals(truncateBody(s, 100), s);
});

Deno.test("truncateBody — over cap returns placeholder marker", () => {
  const s = "x".repeat(60_000);
  const out = truncateBody(s, BODY_CAP_BYTES);
  assert(out != null);
  assertStringIncludes(out, "[…truncated]");
  // result fits the cap
  assert(new TextEncoder().encode(out).length <= BODY_CAP_BYTES);
});

Deno.test("truncateBody — multibyte safe (Cyrillic body)", () => {
  // 'я' is 2 bytes in UTF-8; 30000 of them = 60_000 bytes — over the cap.
  const s = "я".repeat(30_000);
  const out = truncateBody(s, BODY_CAP_BYTES);
  assert(out != null);
  // The result must be a valid UTF-8 string (no '\uFFFD' replacement char
  // at the cut boundary).
  assertEquals(out.includes("\uFFFD"), false);
  assert(new TextEncoder().encode(out).length <= BODY_CAP_BYTES);
});

// =============================================================================
// dropOldQuoteChains
// =============================================================================

Deno.test("dropOldQuoteChains — no prelude, body unchanged", () => {
  const body = "Just a single message with no reply chain.";
  assertEquals(dropOldQuoteChains(body, new Date("2026-05-06")), body);
});

Deno.test("dropOldQuoteChains — recent quote kept", () => {
  // Prelude 5 days before "now" — well within the 30-day window.
  const body =
    "Latest reply text.\n\nOn 2026-05-01 09:14, Foo Bar wrote:\n> earlier message";
  const out = dropOldQuoteChains(body, new Date("2026-05-06"));
  assertEquals(out, body);
});

Deno.test("dropOldQuoteChains — old quote dropped (ISO date)", () => {
  // 60 days before "now" — outside 30-day cutoff.
  const body =
    "Latest reply text.\n\nOn 2026-03-07 09:14, Foo Bar wrote:\n> earlier message";
  const out = dropOldQuoteChains(body, new Date("2026-05-06"));
  assert(out != null);
  assertStringIncludes(out, "Latest reply text.");
  assertStringIncludes(out, "older quote dropped");
  assertEquals(out.includes("> earlier message"), false);
});

Deno.test("dropOldQuoteChains — old quote dropped (FI dotted date)", () => {
  const body =
    "Vastauksesi alkaa tästä.\n\n7.3.2026, Foo Bar kirjoitti:\n> aiempi viesti";
  const out = dropOldQuoteChains(body, new Date("2026-05-06"));
  assert(out != null);
  assertStringIncludes(out, "Vastauksesi alkaa tästä.");
  assertEquals(out.includes("aiempi viesti"), false);
});

// =============================================================================
// lastNMessages
// =============================================================================

Deno.test("lastNMessages — keeps last 5 sorted ascending", () => {
  const mk = (id: string, sentAt: string): GmailMessage => ({
    id,
    threadId: "t",
    senderEmail: "a@b",
    toRecipients: [],
    ccRecipients: [],
    sentAt,
    hasAttachments: false,
    attachmentsMeta: [],
    headersMeta: {},
  });
  const msgs = [
    mk("m1", "2026-01-01T00:00:00Z"),
    mk("m2", "2026-02-01T00:00:00Z"),
    mk("m3", "2026-03-01T00:00:00Z"),
    mk("m4", "2026-04-01T00:00:00Z"),
    mk("m5", "2026-05-01T00:00:00Z"),
    mk("m6", "2026-05-15T00:00:00Z"),
    mk("m7", "2026-05-16T00:00:00Z"),
  ];
  const last5 = lastNMessages(msgs, 5);
  assertEquals(last5.length, 5);
  assertEquals(last5[0].id, "m3");
  assertEquals(last5[4].id, "m7");
});

// =============================================================================
// runSyncTick — idempotency + body cap
// =============================================================================

interface FakeDepsState {
  storedThreads: Map<string, ThreadUpsertRow & { id: string }>;
  storedMsgIds: Set<string>;
  enqueued: Array<{ userId: string; threadId: string }>;
  fetchSequence: GmailThreadFull[];
}

function makeFakeDeps(state: FakeDepsState): MinimalSyncDeps {
  return {
    async getLastSyncedAt(_userId: string) {
      return null;
    },
    async listThreads(_args) {
      return state.fetchSequence.map((t) => ({ id: t.threadId, historyId: t.historyId ?? null }));
    },
    async getThread(args) {
      return state.fetchSequence.find((t) => t.threadId === args.threadId) ?? null;
    },
    async upsertThread(row) {
      const key = `${row.user_id}:${row.gmail_thread_id}`;
      const prior = state.storedThreads.get(key);
      if (!prior) {
        const id = `db-${state.storedThreads.size + 1}`;
        state.storedThreads.set(key, { ...row, id });
        return { id, isNewOrAdvanced: true };
      }
      const advanced = Date.parse(row.last_message_at) >
        Date.parse(prior.last_message_at);
      state.storedThreads.set(key, { ...prior, ...row });
      return { id: prior.id, isNewOrAdvanced: advanced };
    },
    async upsertMessages(rows: MessageUpsertRow[]) {
      let count = 0;
      const idByGmailId: Record<string, string> = {};
      for (const r of rows) {
        // Stable synthetic uuid by gmail id so tests can predict it.
        const dbId = `msg-uuid-${r.gmail_message_id}`;
        idByGmailId[r.gmail_message_id] = dbId;
        if (state.storedMsgIds.has(r.gmail_message_id)) continue;
        state.storedMsgIds.add(r.gmail_message_id);
        count++;
      }
      return { count, idByGmailId };
    },
    async enqueueTriage(args) {
      state.enqueued.push(args);
    },
  };
}

function mkThread(
  id: string,
  lastMsgAt: string,
  bodies: string[],
): GmailThreadFull {
  return {
    threadId: id,
    historyId: "h-1",
    snippet: "snip",
    subject: `Subject ${id}`,
    participants: ["a@b", "c@d"],
    labelIds: [],
    lastMessageAt: lastMsgAt,
    messages: bodies.map((b, i) => ({
      id: `${id}-m${i + 1}`,
      threadId: id,
      senderEmail: "sender@x",
      toRecipients: ["me@y"],
      ccRecipients: [],
      subject: `Subject ${id}`,
      bodyPlaintext: b,
      sentAt: new Date(Date.parse(lastMsgAt) - (bodies.length - i) * 60_000)
        .toISOString(),
      hasAttachments: false,
      attachmentsMeta: [],
      headersMeta: {},
    })),
  };
}

Deno.test("runSyncTick — first tick syncs thread, second tick skips unchanged", async () => {
  const thread = mkThread("t-1", "2026-05-06T10:00:00Z", ["hello"]);
  const state: FakeDepsState = {
    storedThreads: new Map(),
    storedMsgIds: new Set(),
    enqueued: [],
    fetchSequence: [thread],
  };
  const deps = makeFakeDeps(state);

  const r1 = await runSyncTick(deps, {
    userId: "u1",
    accessToken: "tok",
    now: new Date("2026-05-06T10:30:00Z"),
  });
  assertEquals(r1.threads_synced, 1);
  assertEquals(r1.threads_skipped_unchanged, 0);
  assertEquals(r1.messages_upserted, 1);
  assertEquals(r1.triages_enqueued, 1);

  // Second tick — same thread, same last_message_at, no new messages.
  const r2 = await runSyncTick(deps, {
    userId: "u1",
    accessToken: "tok",
    now: new Date("2026-05-06T10:35:00Z"),
  });
  assertEquals(r2.threads_synced, 0);
  assertEquals(r2.threads_skipped_unchanged, 1);
  // Existing gmail_message_id is now in the dedupe set; second tick adds 0.
  assertEquals(r2.messages_upserted, 0);
  // No re-enqueue when thread did not advance.
  assertEquals(r2.triages_enqueued, 0);
});

Deno.test("runSyncTick — body capped to 50 KB on insert", async () => {
  const huge = "x".repeat(120_000); // > 50 KB
  const thread = mkThread("t-big", "2026-05-06T10:00:00Z", [huge]);
  const state: FakeDepsState = {
    storedThreads: new Map(),
    storedMsgIds: new Set(),
    enqueued: [],
    fetchSequence: [thread],
  };
  // Capture rows passed to upsertMessages.
  const captured: MessageUpsertRow[] = [];
  const deps: MinimalSyncDeps = {
    ...makeFakeDeps(state),
    async upsertMessages(rows) {
      const idByGmailId: Record<string, string> = {};
      for (const r of rows) {
        captured.push(r);
        idByGmailId[r.gmail_message_id] = `msg-uuid-${r.gmail_message_id}`;
      }
      return { count: rows.length, idByGmailId };
    },
  };
  await runSyncTick(deps, {
    userId: "u1",
    accessToken: "tok",
    now: new Date("2026-05-06T10:30:00Z"),
  });
  assertEquals(captured.length, 1);
  const body = captured[0].body_plaintext!;
  assert(new TextEncoder().encode(body).length <= BODY_CAP_BYTES);
});

Deno.test("runSyncTick — one thread failure does not abort tick", async () => {
  const ok1 = mkThread("ok1", "2026-05-06T10:00:00Z", ["a"]);
  const fail = mkThread("fail", "2026-05-06T10:01:00Z", ["b"]);
  const ok2 = mkThread("ok2", "2026-05-06T10:02:00Z", ["c"]);
  const state: FakeDepsState = {
    storedThreads: new Map(),
    storedMsgIds: new Set(),
    enqueued: [],
    fetchSequence: [ok1, fail, ok2],
  };
  const deps: MinimalSyncDeps = {
    ...makeFakeDeps(state),
    async getThread(args) {
      if (args.threadId === "fail") {
        throw new Error("simulated Gmail 500");
      }
      return state.fetchSequence.find((t) => t.threadId === args.threadId) ?? null;
    },
  };
  const r = await runSyncTick(deps, {
    userId: "u1",
    accessToken: "tok",
    now: new Date("2026-05-06T10:30:00Z"),
  });
  assertEquals(r.threads_synced, 2);
  assertEquals(r.errors, 1);
});

// =============================================================================
// toThreadRow / toMessageRow
// =============================================================================

Deno.test("toThreadRow — copies fields and sets pending status", () => {
  const t = mkThread("t-1", "2026-05-06T10:00:00Z", ["x"]);
  const row = toThreadRow({
    userId: "u1",
    caseId: null,
    thread: t,
    nowIso: "2026-05-06T10:30:00Z",
  });
  assertEquals(row.gmail_thread_id, "t-1");
  assertEquals(row.triage_status, "pending");
  assertEquals(row.last_message_at, "2026-05-06T10:00:00Z");
  assertEquals(row.last_synced_at, "2026-05-06T10:30:00Z");
  assertEquals(row.case_id, null);
});

Deno.test("toMessageRow — drops old quote chain + caps body", () => {
  const huge = "x".repeat(120_000);
  const oldQuote =
    "fresh reply.\n\nOn 2026-01-01 00:00, Foo wrote:\n> ancient";
  const msg: GmailMessage = {
    id: "m-1",
    threadId: "t-1",
    senderEmail: "a@b",
    toRecipients: [],
    ccRecipients: [],
    sentAt: "2026-05-06T10:00:00Z",
    bodyPlaintext: huge + "\n" + oldQuote,
    hasAttachments: false,
    attachmentsMeta: [],
    headersMeta: {},
  };
  const row = toMessageRow({
    threadDbId: "db-1",
    userId: "u1",
    msg,
    now: new Date("2026-05-06"),
  });
  assert(row.body_plaintext != null);
  assert(new TextEncoder().encode(row.body_plaintext).length <= BODY_CAP_BYTES);
});

Deno.test("QUOTE_CHAIN_CUTOFF_DAYS constant locked at 30", () => {
  assertEquals(QUOTE_CHAIN_CUTOFF_DAYS, 30);
});

// =============================================================================
// Fix #1 (2026-05-26) — attachment fan-out
// =============================================================================

import {
  DOWNLOADABLE_MIME_PREFIXES,
  isDownloadableMime,
  MAX_ATTACHMENTS_PER_THREAD,
} from "../sync_logic.ts";

Deno.test("isDownloadableMime — accepts PDFs + images, rejects rest", () => {
  assert(isDownloadableMime("application/pdf"));
  assert(isDownloadableMime("image/png"));
  assert(isDownloadableMime("image/jpeg"));
  assert(isDownloadableMime("IMAGE/HEIC"));
  assert(!isDownloadableMime("application/zip"));
  assert(!isDownloadableMime("text/html"));
  assert(!isDownloadableMime(""));
});

Deno.test("MAX_ATTACHMENTS_PER_THREAD constant locked at 10", () => {
  assertEquals(MAX_ATTACHMENTS_PER_THREAD, 10);
});

Deno.test("DOWNLOADABLE_MIME_PREFIXES is the documented set", () => {
  assertEquals(DOWNLOADABLE_MIME_PREFIXES, ["application/pdf", "image/"]);
});

Deno.test("runSyncTick — fans out attachment downloads for PDF + skips non-PDF", async () => {
  const state: FakeDepsState = {
    storedThreads: new Map(),
    storedMsgIds: new Set(),
    enqueued: [],
    fetchSequence: [],
  };
  // Thread with 1 message containing 1 PDF + 1 zip (zip must be skipped).
  const thread: GmailThreadFull = {
    threadId: "t-poliisi",
    historyId: "h1",
    snippet: "Liitteenä asiakirjat",
    subject: "Asiakirjat",
    participants: ["ulkomaalaisasiat.helsinki@poliisi.fi", "me@advocat.ee"],
    labelIds: ["INBOX"],
    lastMessageAt: "2026-05-26T07:49:00Z",
    messages: [
      {
        id: "msg-1",
        threadId: "t-poliisi",
        rfcMessageId: "<m1@poliisi.fi>",
        senderEmail: "ulkomaalaisasiat.helsinki@poliisi.fi",
        senderName: null,
        toRecipients: ["me@advocat.ee"],
        ccRecipients: [],
        subject: "Asiakirjat",
        bodyPlaintext: "Liitteenä asiakirjat.",
        snippet: null,
        sentAt: "2026-05-26T07:49:00Z",
        hasAttachments: true,
        attachmentsMeta: [
          { filename: "SULGA päätös.pdf", mime: "application/pdf", size_bytes: 1489357 },
          { filename: "archive.zip", mime: "application/zip", size_bytes: 200 },
        ],
        attachmentsWithIds: [
          {
            filename: "SULGA päätös.pdf",
            mime: "application/pdf",
            size_bytes: 1489357,
            gmail_attachment_id: "att-pdf-1",
          },
          {
            filename: "archive.zip",
            mime: "application/zip",
            size_bytes: 200,
            gmail_attachment_id: "att-zip-1",
          },
        ],
        headersMeta: {},
      },
    ],
  };
  state.fetchSequence = [thread];
  const downloadCalls: Array<
    { gmail_attachment_id: string; filename: string }
  > = [];
  const deps: MinimalSyncDeps = {
    ...makeFakeDeps(state),
    async downloadAndStoreAttachment(args) {
      downloadCalls.push({
        gmail_attachment_id: args.attachment.gmail_attachment_id,
        filename: args.attachment.filename,
      });
      return { inserted: true };
    },
  };
  const res = await runSyncTick(deps, {
    userId: "u1",
    accessToken: "tok",
    now: new Date("2026-05-26T08:00:00Z"),
  });
  assertEquals(res.attachments_downloaded, 1, "only PDF should download");
  assertEquals(res.attachments_skipped, 1, "zip should be skipped");
  assertEquals(downloadCalls.length, 1, "downloadAndStoreAttachment called once");
  assertEquals(downloadCalls[0].gmail_attachment_id, "att-pdf-1");
  assertEquals(downloadCalls[0].filename, "SULGA päätös.pdf");
});

Deno.test("runSyncTick — enforces MAX_ATTACHMENTS_PER_THREAD cap", async () => {
  const state: FakeDepsState = {
    storedThreads: new Map(),
    storedMsgIds: new Set(),
    enqueued: [],
    fetchSequence: [],
  };
  // 15 PDFs — only 10 should download, 5 skipped.
  const pdfs = Array.from({ length: 15 }, (_, i) => ({
    filename: `f${i}.pdf`,
    mime: "application/pdf",
    size_bytes: 1000,
    gmail_attachment_id: `att-${i}`,
  }));
  const thread: GmailThreadFull = {
    threadId: "t-big",
    historyId: "h1",
    snippet: "many",
    subject: "Many",
    participants: ["a@x"],
    labelIds: [],
    lastMessageAt: "2026-05-26T08:00:00Z",
    messages: [
      {
        id: "msg-big",
        threadId: "t-big",
        senderEmail: "a@x",
        toRecipients: ["me@advocat.ee"],
        ccRecipients: [],
        bodyPlaintext: "",
        sentAt: "2026-05-26T08:00:00Z",
        hasAttachments: true,
        attachmentsMeta: pdfs.map((p) => ({
          filename: p.filename, mime: p.mime, size_bytes: p.size_bytes,
        })),
        attachmentsWithIds: pdfs,
        headersMeta: {},
      },
    ],
  };
  state.fetchSequence = [thread];
  let calls = 0;
  const deps: MinimalSyncDeps = {
    ...makeFakeDeps(state),
    async downloadAndStoreAttachment() {
      calls++;
      return { inserted: true };
    },
  };
  const res = await runSyncTick(deps, {
    userId: "u1",
    accessToken: "tok",
    now: new Date("2026-05-26T08:30:00Z"),
  });
  assertEquals(res.attachments_downloaded, 10);
  assertEquals(res.attachments_skipped, 5);
  assertEquals(calls, 10);
});

Deno.test("runSyncTick — attachment download failure is swallowed (sync continues)", async () => {
  const state: FakeDepsState = {
    storedThreads: new Map(),
    storedMsgIds: new Set(),
    enqueued: [],
    fetchSequence: [],
  };
  const thread: GmailThreadFull = {
    threadId: "t-fail",
    historyId: "h1",
    snippet: "x",
    subject: "X",
    participants: ["a@x"],
    labelIds: [],
    lastMessageAt: "2026-05-26T09:00:00Z",
    messages: [
      {
        id: "msg-fail",
        threadId: "t-fail",
        senderEmail: "a@x",
        toRecipients: ["me@advocat.ee"],
        ccRecipients: [],
        bodyPlaintext: "",
        sentAt: "2026-05-26T09:00:00Z",
        hasAttachments: true,
        attachmentsMeta: [{ filename: "x.pdf", mime: "application/pdf", size_bytes: 100 }],
        attachmentsWithIds: [{
          filename: "x.pdf", mime: "application/pdf", size_bytes: 100,
          gmail_attachment_id: "att-bad",
        }],
        headersMeta: {},
      },
    ],
  };
  state.fetchSequence = [thread];
  const deps: MinimalSyncDeps = {
    ...makeFakeDeps(state),
    async downloadAndStoreAttachment() {
      throw new Error("network blew up");
    },
  };
  const res = await runSyncTick(deps, {
    userId: "u1",
    accessToken: "tok",
    now: new Date("2026-05-26T09:30:00Z"),
  });
  // Thread sync still succeeds, attachment counted as skipped not errored.
  assertEquals(res.threads_synced, 1);
  assertEquals(res.attachments_downloaded, 0);
  assertEquals(res.attachments_skipped, 1);
  assertEquals(res.errors, 0);
});
