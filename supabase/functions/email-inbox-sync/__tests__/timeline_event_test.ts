// Deno tests for the optional recordTimelineEvent sidecar on
// email-inbox-sync/sync_logic.ts.
// -----------------------------------------------------------------------------
// Covers the contract added by migration 20260525154500_case_timeline_events:
//
//   * runSyncTick invokes deps.recordTimelineEvent for each new-or-advanced
//     thread exactly once, with the thread db id + subject + snippet.
//   * It is NOT called when the thread is unchanged (idempotency).
//   * recordTimelineEvent failures do NOT collapse the sync (best-effort).
//
// Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/email-inbox-sync/__tests__/timeline_event_test.ts
// -----------------------------------------------------------------------------

import { assert, assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  type GmailThreadFull,
  type MessageUpsertRow,
  type MinimalSyncDeps,
  runSyncTick,
  type ThreadUpsertRow,
} from "../sync_logic.ts";

function mkThread(
  id: string,
  lastMsgAt: string,
  subject: string,
  snippet: string,
): GmailThreadFull {
  return {
    threadId: id,
    historyId: "h-1",
    snippet,
    subject,
    participants: ["a@b"],
    labelIds: [],
    lastMessageAt: lastMsgAt,
    messages: [{
      id: `${id}-m1`,
      threadId: id,
      senderEmail: "sender@x",
      toRecipients: ["me@y"],
      ccRecipients: [],
      subject,
      bodyPlaintext: "body",
      sentAt: lastMsgAt,
      hasAttachments: false,
      attachmentsMeta: [],
      headersMeta: {},
    }],
  };
}

interface FakeState {
  storedThreads: Map<string, ThreadUpsertRow & { id: string }>;
  storedMsgIds: Set<string>;
  enqueued: { userId: string; threadId: string }[];
  fetchSequence: GmailThreadFull[];
  timelineCalls: Array<{
    threadDbId: string;
    subject: string | null;
    snippet: string | null;
    lastMessageAt: string;
  }>;
  timelineThrows?: boolean;
}

function makeFakeDeps(state: FakeState): MinimalSyncDeps {
  return {
    async getLastSyncedAt() {
      return null;
    },
    async listThreads({ maxResults }) {
      return state.fetchSequence.slice(0, maxResults).map((t) => ({
        id: t.threadId,
        historyId: t.historyId,
      }));
    },
    async getThread({ threadId }) {
      return state.fetchSequence.find((t) => t.threadId === threadId) ?? null;
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
        idByGmailId[r.gmail_message_id] = `msg-uuid-${r.gmail_message_id}`;
        if (state.storedMsgIds.has(r.gmail_message_id)) continue;
        state.storedMsgIds.add(r.gmail_message_id);
        count++;
      }
      return { count, idByGmailId };
    },
    async enqueueTriage(args) {
      state.enqueued.push(args);
    },
    async recordTimelineEvent(args) {
      if (state.timelineThrows) throw new Error("simulated record failure");
      state.timelineCalls.push(args);
    },
  };
}

Deno.test(
  "runSyncTick — recordTimelineEvent called once per new thread, with subject+snippet+ts",
  async () => {
    const thread = mkThread(
      "t-1",
      "2026-05-25T10:00:00Z",
      "Migri: hakemus vastaanotettu",
      "Olemme vastaanottaneet hakemuksenne…",
    );
    const state: FakeState = {
      storedThreads: new Map(),
      storedMsgIds: new Set(),
      enqueued: [],
      fetchSequence: [thread],
      timelineCalls: [],
    };
    const deps = makeFakeDeps(state);

    const r = await runSyncTick(deps, {
      userId: "u1",
      accessToken: "tok",
      now: new Date("2026-05-25T10:30:00Z"),
    });

    assertEquals(r.threads_synced, 1);
    assertEquals(state.timelineCalls.length, 1);
    assertEquals(state.timelineCalls[0].subject, "Migri: hakemus vastaanotettu");
    assertEquals(
      state.timelineCalls[0].snippet,
      "Olemme vastaanottaneet hakemuksenne…",
    );
    assertEquals(state.timelineCalls[0].lastMessageAt, "2026-05-25T10:00:00Z");
    // Threads share the same upsert key on first insert.
    assert(state.timelineCalls[0].threadDbId.startsWith("db-"));
  },
);

Deno.test(
  "runSyncTick — recordTimelineEvent NOT called when thread is unchanged",
  async () => {
    const thread = mkThread(
      "t-2",
      "2026-05-25T10:00:00Z",
      "Subject",
      "Snippet",
    );
    const state: FakeState = {
      storedThreads: new Map(),
      storedMsgIds: new Set(),
      enqueued: [],
      fetchSequence: [thread],
      timelineCalls: [],
    };
    const deps = makeFakeDeps(state);

    await runSyncTick(deps, {
      userId: "u1",
      accessToken: "tok",
      now: new Date("2026-05-25T10:30:00Z"),
    });
    assertEquals(state.timelineCalls.length, 1);

    // Second tick — same thread, same last_message_at → no advance.
    await runSyncTick(deps, {
      userId: "u1",
      accessToken: "tok",
      now: new Date("2026-05-25T10:35:00Z"),
    });
    assertEquals(state.timelineCalls.length, 1,
      "no second timeline event when thread unchanged");
  },
);

Deno.test(
  "runSyncTick — recordTimelineEvent failure is best-effort (sync still completes)",
  async () => {
    const thread = mkThread("t-3", "2026-05-25T10:00:00Z", "S", "s");
    const state: FakeState = {
      storedThreads: new Map(),
      storedMsgIds: new Set(),
      enqueued: [],
      fetchSequence: [thread],
      timelineCalls: [],
      timelineThrows: true,
    };
    const deps = makeFakeDeps(state);

    const r = await runSyncTick(deps, {
      userId: "u1",
      accessToken: "tok",
      now: new Date("2026-05-25T10:30:00Z"),
    });
    // Sidecar threw; sync still completed and counted the thread.
    assertEquals(r.threads_synced, 1);
    assertEquals(r.errors, 0,
      "recordTimelineEvent failure must NOT increment errors counter");
  },
);

Deno.test(
  "runSyncTick — works without recordTimelineEvent dep (back-compat)",
  async () => {
    const thread = mkThread("t-4", "2026-05-25T10:00:00Z", "S", "s");
    const state: FakeState = {
      storedThreads: new Map(),
      storedMsgIds: new Set(),
      enqueued: [],
      fetchSequence: [thread],
      timelineCalls: [],
    };
    const deps = makeFakeDeps(state);
    // Strip the optional dep — pre-migration deployments do not have it.
    const baseDeps: MinimalSyncDeps = { ...deps };
    delete (baseDeps as { recordTimelineEvent?: unknown }).recordTimelineEvent;

    const r = await runSyncTick(baseDeps, {
      userId: "u1",
      accessToken: "tok",
      now: new Date("2026-05-25T10:30:00Z"),
    });
    assertEquals(r.threads_synced, 1);
    assertEquals(state.timelineCalls.length, 0);
  },
);
