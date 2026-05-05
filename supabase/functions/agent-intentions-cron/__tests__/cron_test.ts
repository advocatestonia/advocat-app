// Deno tests for agent-intentions-cron auth gate + processor.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-env --allow-read --allow-net=esm.sh,deno.land \
//     supabase/functions/agent-intentions-cron/__tests__/cron_test.ts
//
// Scope:
//   - checkCronSecret() — same shape as deadline-reminder's tests
//   - renderNotification() — locale dispatch, target_id interpolation
//   - processDueIntentions() — fake Supabase, asserts mark-complete behaviour,
//     skip when no email, error counter on insert failure
//   - source-code contracts: index.ts gates with checkCronSecret BEFORE
//     createClient, response is PII-scrubbed
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { checkCronSecret } from "../auth_gate.ts";
import {
  type IntentionRow,
  type MinimalSupabase,
  processDueIntentions,
  renderNotification,
} from "../processor.ts";

// ── Auth gate ──────────────────────────────────────────────────────────────

Deno.test("AI-T01 — no env var -> 500 fail-closed", () => {
  const r = checkCronSecret("anything", undefined);
  assertEquals(r.kind, "deny");
  if (r.kind === "deny") {
    assertEquals(r.status, 500);
    assertStringIncludes(r.body.error, "not configured");
  }
});

Deno.test("AI-T02 — missing header -> 401", () => {
  const r = checkCronSecret(null, "the-secret");
  assertEquals(r.kind, "deny");
  if (r.kind === "deny") assertEquals(r.status, 401);
});

Deno.test("AI-T03 — wrong header -> 401", () => {
  const r = checkCronSecret("guess", "the-secret");
  assertEquals(r.kind, "deny");
  if (r.kind === "deny") assertEquals(r.status, 401);
});

Deno.test("AI-T04 — correct header -> allow", () => {
  const r = checkCronSecret("the-secret", "the-secret");
  assertEquals(r.kind, "allow");
});

// ── Notification rendering ────────────────────────────────────────────────

function row(p: Partial<IntentionRow>): IntentionRow {
  return {
    id: "00000000-0000-0000-0000-000000000001",
    user_id: "u1",
    case_id: null,
    intent_type: "remind_deadline",
    target_id: null,
    next_check_at: "2026-06-05T10:00:00Z",
    conversation_context: { summary: "default", locale: "en" },
    completed: false,
    ...p,
  };
}

Deno.test("AI-T05 — renderNotification dispatches by locale (RU)", () => {
  const r = renderNotification(row({
    intent_type: "remind_deadline",
    conversation_context: { summary: "appeal deadline", locale: "ru" },
  }));
  assertStringIncludes(r.title, "Напоминание");
  assertStringIncludes(r.body, "appeal deadline");
});

Deno.test("AI-T06 — renderNotification dispatches by locale (ET)", () => {
  const r = renderNotification(row({
    intent_type: "remind_deadline",
    conversation_context: { summary: "kaebuse tähtaeg", locale: "et" },
  }));
  assertStringIncludes(r.title, "Meeldetuletus");
});

Deno.test("AI-T07 — check_court_status interpolates target_id", () => {
  const r = renderNotification(row({
    intent_type: "check_court_status",
    target_id: "R-2025/123",
    conversation_context: { summary: "Sulga case", locale: "en" },
  }));
  assertStringIncludes(r.body, "R-2025/123");
});

Deno.test("AI-T08 — follow_up_question references summary", () => {
  const r = renderNotification(row({
    intent_type: "follow_up_question",
    conversation_context: { summary: "appeal preparation", locale: "en" },
  }));
  assertStringIncludes(r.body, "appeal preparation");
});

Deno.test("AI-T09 — check_company_status references target", () => {
  const r = renderNotification(row({
    intent_type: "check_company_status",
    target_id: "12345678",
    conversation_context: { summary: "supplier check", locale: "en" },
  }));
  assertStringIncludes(r.body, "12345678");
});

// ── Processor: fake-supabase smoke ────────────────────────────────────────

function makeFakeSupabase(opts: {
  rows?: IntentionRow[];
  emails?: Record<string, string | null>;
  insertThrows?: boolean;
}) {
  const calls = {
    fetched: 0,
    notifications: [] as Array<Record<string, unknown>>,
    completed: [] as string[],
  };
  const fake: MinimalSupabase = {
    async fetchDueIntentions(_now, _limit) {
      calls.fetched++;
      return opts.rows ?? [];
    },
    async fetchUserEmail(uid) {
      // Honour explicit null in the override map (vs falling back to default).
      if (opts.emails && uid in opts.emails) return opts.emails[uid];
      return `${uid}@example.com`;
    },
    async insertNotification(n) {
      if (opts.insertThrows) throw new Error("forced failure");
      calls.notifications.push(n);
    },
    async markIntentionComplete(id) {
      calls.completed.push(id);
    },
  };
  return { fake, calls };
}

Deno.test("AI-T10 — processDueIntentions on empty list -> 0/0", async () => {
  const { fake } = makeFakeSupabase({ rows: [] });
  const r = await processDueIntentions(fake, new Date(), 50);
  assertEquals(r.processed, 0);
  assertEquals(r.errors, 0);
});

Deno.test("AI-T11 — processes a due row, inserts notification, marks complete", async () => {
  const { fake, calls } = makeFakeSupabase({
    rows: [row({ id: "i1", user_id: "u1" })],
  });
  const r = await processDueIntentions(fake, new Date(), 50);
  assertEquals(r.processed, 1);
  assertEquals(r.errors, 0);
  assertEquals(calls.notifications.length, 1);
  assertEquals(calls.completed, ["i1"]);
  assertEquals(calls.notifications[0].user_id, "u1");
  assertStringIncludes(
    calls.notifications[0].type as string,
    "agent_intention:remind_deadline",
  );
});

Deno.test("AI-T12 — user with no email is marked complete (no infinite loop)", async () => {
  const { fake, calls } = makeFakeSupabase({
    rows: [row({ id: "i2", user_id: "ghost" })],
    emails: { ghost: null },
  });
  const r = await processDueIntentions(fake, new Date(), 50);
  assertEquals(r.processed, 0);
  assertEquals(calls.notifications.length, 0);
  assertEquals(calls.completed, ["i2"]);
});

Deno.test("AI-T13 — insert failure increments error counter, leaves row uncompleted", async () => {
  const { fake, calls } = makeFakeSupabase({
    rows: [row({ id: "i3", user_id: "u3" })],
    insertThrows: true,
  });
  const r = await processDueIntentions(fake, new Date(), 50);
  assertEquals(r.processed, 0);
  assertEquals(r.errors, 1);
  assertEquals(calls.completed.length, 0);
});

// ── Source-code contracts (static analysis of index.ts) ───────────────────

Deno.test("AI-T14 — index.ts gates checkCronSecret BEFORE createClient", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  const gateIdx = source.indexOf("checkCronSecret(");
  const createClientIdx = source.indexOf("createClient(");
  assert(gateIdx !== -1, "must gate with checkCronSecret");
  assert(createClientIdx !== -1, "must instantiate Supabase client");
  assert(
    gateIdx < createClientIdx,
    "checkCronSecret MUST precede createClient — fail-closed contract",
  );
});

Deno.test("AI-T15 — index.ts uses x-cron-secret header (not Authorization)", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  assertStringIncludes(source, "x-cron-secret");
});

Deno.test("AI-T16 — response body is PII-scrubbed (no rows/emails leaked)", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  const stripped = source
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .replace(/^\s*\/\/.*$/gm, "");
  // The success response must use the terse counts shape from
  // processDueIntentions, never echo summaries / emails / user_ids.
  assertFalse(
    /details\s*:\s*notifications/.test(stripped),
    "must not echo notifications array — PII leak",
  );
  assertFalse(
    /String\(error\)|String\(_e\)/.test(stripped),
    "catch must not echo raw error string — Supabase errors may carry PII",
  );
});

Deno.test("AI-T17 — index.ts reads CRON_SECRET from env (not body, not query)", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  assertStringIncludes(source, "Deno.env.get(\"CRON_SECRET\")");
});
