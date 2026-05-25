// email_send_test.ts — D6 "Approve & Send" edge function tests.
// -----------------------------------------------------------------------------
// Covers the four contract guarantees that gate this function:
//
//   (a) Happy path — a valid triage row with a fresh HMAC gate_token
//       results in a Gmail API call + a stamped triage row.
//   (b) HMAC mismatch — a forged / replayed token returns 409 and the
//       Gmail call is NEVER made.
//   (c) Edited-body quality re-check — when the user edits the body
//       into something that fails email_quality_check (loaded language,
//       too short, too few questions), the function returns 400 and
//       the Gmail call is NEVER made.
//   (d) Idempotent re-send — when the row already has sent_at /
//       sent_message_id, the function returns 200 with the original
//       ids and the Gmail call is NEVER made (no duplicate dispatch).
//
// Bonus tests:
//   - 404 when triage_id is unknown.
//   - 422 when draft body is empty (no work to do).
//   - 503 when Gmail OAuth is not connected.
//   - Older row with null gate_token → gate_outcome=skipped (audit
//     trail breadcrumb, send still proceeds).
//   - Idempotent skip when wasEdited but body matches whitespace-trimmed.
//
// Run with:
//   deno test --allow-all supabase/functions/email-send/__tests__/email_send_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { handleSend } from "../index.ts";
import {
  type EmailSendDeps,
  type LastInboundMessage,
  type SendArgs,
  type TriageRow,
} from "../send_logic.ts";
import { issueGateToken, sha256Hex } from "../../email-triage/policy_gate.ts";

// =============================================================================
// Fixtures
// =============================================================================

const TEST_SECRET = "test-gate-secret-do-not-use-in-prod";
const USER_ID = "user-1111-1111-1111-1111-111111111111";
const TRIAGE_ID = "triag-1111-1111-1111-1111-111111111111";
const THREAD_ID = "threa-1111-1111-1111-1111-111111111111";
const GMAIL_THREAD_ID = "1810abcd";

const VALID_DRAFT_BODY = [
  "Lugupeetud advokaat,",
  "",
  "Täname kirja eest. Soovime selguse järgmistes küsimustes:",
  "",
  "1. Mis on tähtaeg lisamaterjalide esitamiseks?",
  "2. Kas on võimalik pikendada vastuse aega kahe nädala võrra?",
  "3. Millised on järgmised menetlustoimingud meie poolelt?",
  "4. Kas notariaalne kinnitus on vajalik?",
  "",
  "Ootame teie vastust.",
  "",
  "Lugupidamisega,",
  "[Allkiri]",
].join("\n");

function makeTriageRow(overrides: Partial<TriageRow> = {}): TriageRow {
  return {
    id: TRIAGE_ID,
    user_id: USER_ID,
    thread_id: THREAD_ID,
    gmail_thread_id: GMAIL_THREAD_ID,
    draft_language: "et",
    draft_subject: "Re: Tähtaeg",
    draft_body: VALID_DRAFT_BODY,
    draft_to: ["counterparty@example.com"],
    draft_cc: [],
    send_recommendation: "hold_for_user_review",
    gate_token: null,
    sent_at: null,
    sent_message_id: null,
    user_action: null,
    // Parallel Actions Panel — NULL on legacy single-draft rows. Tests
    // exercising the multi-action path override this with an explicit
    // jsonb array.
    proposed_actions: null,
    ...overrides,
  };
}

const LAST_INBOUND: LastInboundMessage = {
  gmail_message_id: "gmail-msg-1",
  rfc_message_id: "<abc.def@example.com>",
  subject: "Tähtaeg",
};

/** Build a recording deps object. Captures every call so the assertion
 *  layer can verify what the function did (and didn't) attempt. */
function makeRecordingDeps(row: TriageRow): {
  deps: EmailSendDeps;
  calls: {
    sendArgs: SendArgs[];
    markSent: { triageId: string; gmailMessageId: string }[];
    markThread: { threadId: string; status: string }[];
    correspondence: number;
  };
  lastInbound: LastInboundMessage | null;
} {
  const calls = {
    sendArgs: [] as SendArgs[],
    markSent: [] as { triageId: string; gmailMessageId: string }[],
    markThread: [] as { threadId: string; status: string }[],
    correspondence: 0,
  };
  let lastInbound: LastInboundMessage | null = LAST_INBOUND;
  const deps: EmailSendDeps = {
    async loadTriageForUser(triageId, userId) {
      if (triageId !== row.id) return null;
      if (userId !== row.user_id) return null;
      return row;
    },
    async loadLastInbound(_threadId) {
      return lastInbound;
    },
    async sendViaGmail(args) {
      calls.sendArgs.push(args);
      return { id: "gmail-sent-msg-" + Math.floor(Math.random() * 1e6) };
    },
    async markSent(args) {
      calls.markSent.push({
        triageId: args.triageId,
        gmailMessageId: args.gmailMessageId,
      });
    },
    async markThreadStatus(threadId, status) {
      calls.markThread.push({ threadId, status });
    },
    async appendCorrespondence(_args) {
      calls.correspondence += 1;
    },
  };
  return {
    deps,
    calls,
    get lastInbound() {
      return lastInbound;
    },
    set lastInbound(v: LastInboundMessage | null) {
      lastInbound = v;
    },
  } as unknown as {
    deps: EmailSendDeps;
    calls: typeof calls;
    lastInbound: LastInboundMessage | null;
  };
}

async function tokenFor(args: {
  body: string;
  recipients: string[];
  draftId?: string;
  ttlMs?: number;
}) {
  const sha = await sha256Hex(args.body);
  return await issueGateToken({
    draft_id: args.draftId ?? TRIAGE_ID,
    body_sha256: sha,
    recipients: args.recipients,
    secret: TEST_SECRET,
    ttl_ms: args.ttlMs ?? 10 * 60_000, // 10 min — plenty for the test
  });
}

function fakeTokenLoader(
  token = "ya29.fake-fresh",
  fromAddress = "owner@example.com",
) {
  return async (_uid: string) => ({ token, fromAddress });
}

async function readJson(resp: Response): Promise<Record<string, unknown>> {
  const text = await resp.text();
  return text ? JSON.parse(text) : {};
}

// =============================================================================
// (a) Happy path — sends draft
// =============================================================================

Deno.test("email-send (a): sends the draft and stamps the row", async () => {
  const gateToken = await tokenFor({
    body: VALID_DRAFT_BODY,
    recipients: ["counterparty@example.com"],
  });
  const row = makeTriageRow({ gate_token: gateToken });
  const ctx = makeRecordingDeps(row);

  const resp = await handleSend({
    deps: ctx.deps,
    userId: USER_ID,
    triageId: TRIAGE_ID,
    editedBody: null,
    gateSecret: TEST_SECRET,
    loadAccessToken: fakeTokenLoader(),
  });

  assertEquals(resp.status, 200);
  const body = await readJson(resp);
  assertEquals(body.ok, true);
  assert(typeof body.gmail_message_id === "string");
  assertEquals(body.gate_outcome, "ok");

  // Gmail API was called exactly once with the draft body and threading.
  assertEquals(ctx.calls.sendArgs.length, 1);
  const call = ctx.calls.sendArgs[0];
  assertEquals(call.to, "counterparty@example.com");
  assertEquals(call.threadId, GMAIL_THREAD_ID);
  assertEquals(call.body, VALID_DRAFT_BODY);
  assertEquals(call.inReplyTo, "<abc.def@example.com>");

  // Row was stamped exactly once.
  assertEquals(ctx.calls.markSent.length, 1);
  assertEquals(ctx.calls.markSent[0].triageId, TRIAGE_ID);

  // Thread was marked triaged.
  assertEquals(ctx.calls.markThread.length, 1);
  assertEquals(ctx.calls.markThread[0].status, "triaged");

  // Correspondence was logged.
  assertEquals(ctx.calls.correspondence, 1);
});

// =============================================================================
// (b) Gate token mismatch — blocks the send
// =============================================================================

Deno.test("email-send (b): blocks when gate_token HMAC does not match", async () => {
  const goodToken = await tokenFor({
    body: VALID_DRAFT_BODY,
    recipients: ["counterparty@example.com"],
  });
  // Forge by mutating the hmac.
  const forged = { ...goodToken, hmac: goodToken.hmac.replace(/./g, "0") };
  const row = makeTriageRow({ gate_token: forged });
  const ctx = makeRecordingDeps(row);

  const resp = await handleSend({
    deps: ctx.deps,
    userId: USER_ID,
    triageId: TRIAGE_ID,
    editedBody: null,
    gateSecret: TEST_SECRET,
    loadAccessToken: fakeTokenLoader(),
  });

  assertEquals(resp.status, 409);
  const body = await readJson(resp);
  assertEquals(body.error, "Gate token verification failed");
  assertEquals(body.reason, "hmac_mismatch");

  // No Gmail call. No row stamp.
  assertEquals(ctx.calls.sendArgs.length, 0);
  assertEquals(ctx.calls.markSent.length, 0);
});

Deno.test("email-send (b'): blocks on token bound to a different body", async () => {
  // Token bound to a *different* body — the live body now mismatches.
  const goodTokenForOldBody = await tokenFor({
    body: "old body version",
    recipients: ["counterparty@example.com"],
  });
  const row = makeTriageRow({ gate_token: goodTokenForOldBody });
  const ctx = makeRecordingDeps(row);

  const resp = await handleSend({
    deps: ctx.deps,
    userId: USER_ID,
    triageId: TRIAGE_ID,
    editedBody: null,
    gateSecret: TEST_SECRET,
    loadAccessToken: fakeTokenLoader(),
  });

  assertEquals(resp.status, 409);
  const body = await readJson(resp);
  assertEquals(body.reason, "body_sha256_mismatch");
  assertEquals(ctx.calls.sendArgs.length, 0);
});

// =============================================================================
// (c) Quality check on edited body
// =============================================================================

Deno.test(
  "email-send (c): blocks edited body that fails quality gate",
  async () => {
    const gateToken = await tokenFor({
      body: VALID_DRAFT_BODY,
      recipients: ["counterparty@example.com"],
    });
    const row = makeTriageRow({ gate_token: gateToken });
    const ctx = makeRecordingDeps(row);

    // Edited body — too short, no numbered questions, loaded language.
    const badEdit = "See on ebaõiglane ja vastuvõetamatu olukord.";

    const resp = await handleSend({
      deps: ctx.deps,
      userId: USER_ID,
      triageId: TRIAGE_ID,
      editedBody: badEdit,
      gateSecret: TEST_SECRET,
      loadAccessToken: fakeTokenLoader(),
    });

    assertEquals(resp.status, 400);
    const body = await readJson(resp);
    assertEquals(body.error, "Edited body failed quality gate");
    const report = body.report as Record<string, unknown> | undefined;
    assert(report, "quality report should be returned in the error body");
    const issues = report.issues as Array<{ code: string }>;
    const codes = issues.map((i) => i.code);
    // At least one of the canonical issues must surface.
    assert(
      codes.includes("loaded_language") ||
        codes.includes("too_short") ||
        codes.includes("too_few_questions"),
      `expected quality issues; got ${JSON.stringify(codes)}`,
    );
    // Gmail NEVER called.
    assertEquals(ctx.calls.sendArgs.length, 0);
    assertEquals(ctx.calls.markSent.length, 0);
  },
);

// =============================================================================
// (d) Idempotent re-send
// =============================================================================

Deno.test(
  "email-send (d): idempotent — returns prior result when row already sent",
  async () => {
    const gateToken = await tokenFor({
      body: VALID_DRAFT_BODY,
      recipients: ["counterparty@example.com"],
    });
    const row = makeTriageRow({
      gate_token: gateToken,
      sent_at: "2026-05-25T18:55:00.000Z",
      sent_message_id: "gmail-prior-msg-42",
      user_action: "sent",
    });
    const ctx = makeRecordingDeps(row);

    const resp = await handleSend({
      deps: ctx.deps,
      userId: USER_ID,
      triageId: TRIAGE_ID,
      editedBody: null,
      gateSecret: TEST_SECRET,
      loadAccessToken: fakeTokenLoader(),
    });

    assertEquals(resp.status, 200);
    const body = await readJson(resp);
    assertEquals(body.ok, true);
    assertEquals(body.idempotent, true);
    assertEquals(body.gmail_message_id, "gmail-prior-msg-42");
    assertEquals(body.sent_at, "2026-05-25T18:55:00.000Z");

    // Importantly: NO new Gmail call, NO duplicate stamp.
    assertEquals(ctx.calls.sendArgs.length, 0);
    assertEquals(ctx.calls.markSent.length, 0);
  },
);

// =============================================================================
// Bonus coverage
// =============================================================================

Deno.test("email-send: 404 when triage_id is unknown", async () => {
  const row = makeTriageRow();
  const ctx = makeRecordingDeps(row);

  const resp = await handleSend({
    deps: ctx.deps,
    userId: USER_ID,
    triageId: "no-such-1111-1111-1111-1111-111111111111",
    editedBody: null,
    gateSecret: TEST_SECRET,
    loadAccessToken: fakeTokenLoader(),
  });
  assertEquals(resp.status, 404);
  assertEquals(ctx.calls.sendArgs.length, 0);
});

Deno.test(
  "email-send: 403-equivalent (404 from RLS-like check) when row belongs to another user",
  async () => {
    const row = makeTriageRow({ user_id: "someone-else-uuid-uuid-uuid-uuid" });
    const ctx = makeRecordingDeps(row);
    const resp = await handleSend({
      deps: ctx.deps,
      userId: USER_ID,
      triageId: TRIAGE_ID,
      editedBody: null,
      gateSecret: TEST_SECRET,
      loadAccessToken: fakeTokenLoader(),
    });
    // Implementation collapses ownership mismatch into 404 — the inbox
    // UI never sees other users' triage_ids anyway. Either is safe.
    assertEquals(resp.status, 404);
    assertEquals(ctx.calls.sendArgs.length, 0);
  },
);

Deno.test("email-send: 422 when draft body is empty", async () => {
  const row = makeTriageRow({ draft_body: "" });
  const ctx = makeRecordingDeps(row);
  const resp = await handleSend({
    deps: ctx.deps,
    userId: USER_ID,
    triageId: TRIAGE_ID,
    editedBody: null,
    gateSecret: TEST_SECRET,
    loadAccessToken: fakeTokenLoader(),
  });
  assertEquals(resp.status, 422);
  assertEquals(ctx.calls.sendArgs.length, 0);
});

Deno.test("email-send: 503 when Gmail OAuth is not connected", async () => {
  const gateToken = await tokenFor({
    body: VALID_DRAFT_BODY,
    recipients: ["counterparty@example.com"],
  });
  const row = makeTriageRow({ gate_token: gateToken });
  const ctx = makeRecordingDeps(row);
  const resp = await handleSend({
    deps: ctx.deps,
    userId: USER_ID,
    triageId: TRIAGE_ID,
    editedBody: null,
    gateSecret: TEST_SECRET,
    loadAccessToken: async (_uid) => ({
      token: null,
      fromAddress: "support@advocat.ee",
    }),
  });
  assertEquals(resp.status, 503);
  const body = await readJson(resp);
  assertEquals(body.error_code, "gmail_reauth_required");
  assertEquals(ctx.calls.sendArgs.length, 0);
});

Deno.test(
  "email-send: older row with null gate_token — gate_outcome=skipped, send proceeds",
  async () => {
    const row = makeTriageRow({ gate_token: null });
    const ctx = makeRecordingDeps(row);
    const resp = await handleSend({
      deps: ctx.deps,
      userId: USER_ID,
      triageId: TRIAGE_ID,
      editedBody: null,
      gateSecret: TEST_SECRET,
      loadAccessToken: fakeTokenLoader(),
    });
    assertEquals(resp.status, 200);
    const body = await readJson(resp);
    assertEquals(body.gate_outcome, "skipped");
    assertEquals(ctx.calls.sendArgs.length, 1);
  },
);

Deno.test(
  "email-send: whitespace-only edit is treated as no edit (skip quality recheck)",
  async () => {
    const gateToken = await tokenFor({
      body: VALID_DRAFT_BODY,
      recipients: ["counterparty@example.com"],
    });
    const row = makeTriageRow({ gate_token: gateToken });
    const ctx = makeRecordingDeps(row);
    const resp = await handleSend({
      deps: ctx.deps,
      userId: USER_ID,
      triageId: TRIAGE_ID,
      // Same body, just extra trailing newlines — should NOT trigger the
      // gate body-mismatch.
      editedBody: VALID_DRAFT_BODY + "\n\n\n",
      gateSecret: TEST_SECRET,
      loadAccessToken: fakeTokenLoader(),
    });
    assertEquals(resp.status, 200);
    assertEquals(ctx.calls.sendArgs.length, 1);
    // The body actually written to Gmail is the original draft (since
    // pickOutgoingBody collapses the whitespace-equal edit to "no edit").
    assertEquals(ctx.calls.sendArgs[0].body, VALID_DRAFT_BODY);
  },
);

Deno.test("email-send: builds Re: subject from inbound when draft has none", async () => {
  const gateToken = await tokenFor({
    body: VALID_DRAFT_BODY,
    recipients: ["counterparty@example.com"],
  });
  const row = makeTriageRow({
    gate_token: gateToken,
    draft_subject: null,
  });
  const ctx = makeRecordingDeps(row);
  const resp = await handleSend({
    deps: ctx.deps,
    userId: USER_ID,
    triageId: TRIAGE_ID,
    editedBody: null,
    gateSecret: TEST_SECRET,
    loadAccessToken: fakeTokenLoader(),
  });
  assertEquals(resp.status, 200);
  assertEquals(ctx.calls.sendArgs[0].subject, "Re: Tähtaeg");
});

// =============================================================================
// Payload validation
// =============================================================================

Deno.test(
  "email-send: 400 on missing triage_id (validatePayload)",
  async () => {
    const row = makeTriageRow();
    const ctx = makeRecordingDeps(row);
    const resp = await handleSend({
      deps: ctx.deps,
      userId: USER_ID,
      triageId: "", // malformed at the entry point — handleSend itself returns 404
      editedBody: null,
      gateSecret: TEST_SECRET,
      loadAccessToken: fakeTokenLoader(),
    });
    // handleSend treats "" as "row not found" — the serve() layer is
    // the one that returns 400 via validatePayload. We assert the
    // handler's defensive behaviour here.
    assertEquals(resp.status, 404);
    assertEquals(ctx.calls.sendArgs.length, 0);
  },
);

Deno.test(
  "email-send: 502 when Gmail API throws a non-auth error",
  async () => {
    const gateToken = await tokenFor({
      body: VALID_DRAFT_BODY,
      recipients: ["counterparty@example.com"],
    });
    const row = makeTriageRow({ gate_token: gateToken });
    const baseDeps = makeRecordingDeps(row).deps;
    const erroringDeps: EmailSendDeps = {
      ...baseDeps,
      async sendViaGmail(_args) {
        throw new Error("Gmail API 500: backend hiccup");
      },
    };
    const resp = await handleSend({
      deps: erroringDeps,
      userId: USER_ID,
      triageId: TRIAGE_ID,
      editedBody: null,
      gateSecret: TEST_SECRET,
      loadAccessToken: fakeTokenLoader(),
    });
    assertEquals(resp.status, 502);
    const body = await readJson(resp);
    assertStringIncludes(String(body.details ?? ""), "backend hiccup");
  },
);

// =============================================================================
// Parallel Actions Panel (2026-05-25)
//
// When the consilium proposes N parallel actions, the Flutter card fans
// out N invocations of email-send, each with a unique `action_idx`. The
// edge fn looks up that action in `email_triage_results.proposed_actions`
// and dispatches it. action_idx=0 stays on the legacy draft_* path for
// backwards compat.
// =============================================================================

const SULGA_BODY_REPLY =
  "Hyvä Jokela,\n\n" +
  "vastauksena viestiinne 12.5.2026 totean seuraavaa. Hallintolain " +
  "§122 nojalla en hyväksy käännytyspäätöstä, koska tunnistustiedot " +
  "ovat virheelliset.\n\n" +
  "1. Pyydän, että viranomainen korjaa nimen kirjoitusasun.\n" +
  "2. Pyydän, että käännytyspäätös perutaan.\n\n" +
  "Yhteistyöterveisin,\nDmitri Sulga";

const SULGA_BODY_NEW =
  "Pyydän julkisuuslain 14§:n nojalla seuraavat asiakirjat:\n\n" +
  "1. Eckerö Linen matkalipputiedot 5.12.2025.\n" +
  "2. Poliisin laatima käännytysasiakirja 5.12.2025.\n" +
  "3. Saateasiakirjat, jotka osoittavat lähettäjän.\n\n" +
  "Pyyntö perustuu siihen, että nämä todistavat tapahtuman.";

function makeRowWithTwoActions(): TriageRow {
  return makeTriageRow({
    // Legacy columns mirror action idx=0 for back-compat.
    draft_to: ["jokela@migri.fi"],
    draft_subject: "Vastaus 12.5.2026 viestiin",
    draft_body: SULGA_BODY_REPLY,
    draft_language: "fi",
    proposed_actions: [
      {
        idx: 0,
        kind: "email_reply",
        to_addr: "jokela@migri.fi",
        cc: [],
        subject: "Vastaus 12.5.2026 viestiin",
        body: SULGA_BODY_REPLY,
        language: "fi",
        citations: ["[[ref:fi-hol:122]]"],
        rationale: "Soft-return per HOL §122.",
        gate_token: null,
      },
      {
        idx: 1,
        kind: "email_new",
        to_addr: "kirjaamo.helsinki@poliisi.fi",
        cc: [],
        subject: "Asiakirjapyyntö (JulkL 14§)",
        body: SULGA_BODY_NEW,
        language: "fi",
        citations: ["[[ref:fi-julkl:14]]"],
        rationale: "2vk deadline.",
        gate_token: null,
      },
    ],
  });
}

Deno.test(
  "email-send: action_idx omitted → legacy draft_* (back-compat)",
  async () => {
    const row = makeRowWithTwoActions();
    const harness = makeRecordingDeps(row);
    const resp = await handleSend({
      deps: harness.deps,
      userId: USER_ID,
      triageId: TRIAGE_ID,
      editedBody: null,
      gateSecret: TEST_SECRET,
      loadAccessToken: fakeTokenLoader(),
      // actionIdx intentionally omitted — must default to 0.
    });
    assertEquals(resp.status, 200);
    const body = await readJson(resp);
    assertEquals(body.ok, true);
    assertEquals(body.action_idx, 0);
    // Gmail was called with the legacy/idx-0 recipient + body.
    assertEquals(harness.calls.sendArgs.length, 1);
    assertEquals(harness.calls.sendArgs[0].to, "jokela@migri.fi");
    assertStringIncludes(harness.calls.sendArgs[0].body, "HOL §122");
  },
);

Deno.test(
  "email-send: action_idx=1 → dispatches the asiakirjapyyntö to poliisi",
  async () => {
    const row = makeRowWithTwoActions();
    const harness = makeRecordingDeps(row);
    const resp = await handleSend({
      deps: harness.deps,
      userId: USER_ID,
      triageId: TRIAGE_ID,
      editedBody: null,
      actionIdx: 1,
      gateSecret: TEST_SECRET,
      loadAccessToken: fakeTokenLoader(),
    });
    assertEquals(resp.status, 200);
    const body = await readJson(resp);
    assertEquals(body.ok, true);
    assertEquals(body.action_idx, 1);
    // Gmail was called with the idx=1 recipient + body.
    assertEquals(harness.calls.sendArgs.length, 1);
    assertEquals(
      harness.calls.sendArgs[0].to,
      "kirjaamo.helsinki@poliisi.fi",
    );
    assertStringIncludes(harness.calls.sendArgs[0].body, "JulkL 14§");
    // markSent must NOT fire for action_idx > 0 — the per-row sent_at
    // marker is reserved for the legacy single-draft path.
    assertEquals(harness.calls.markSent.length, 0);
  },
);

Deno.test(
  "email-send: action_idx out-of-bounds → 400 action_idx_oob",
  async () => {
    const row = makeRowWithTwoActions();
    const harness = makeRecordingDeps(row);
    const resp = await handleSend({
      deps: harness.deps,
      userId: USER_ID,
      triageId: TRIAGE_ID,
      editedBody: null,
      actionIdx: 99,
      gateSecret: TEST_SECRET,
      loadAccessToken: fakeTokenLoader(),
    });
    assertEquals(resp.status, 400);
    const body = await readJson(resp);
    assertEquals(body.error_code, "action_idx_oob");
    // No Gmail call.
    assertEquals(harness.calls.sendArgs.length, 0);
  },
);

Deno.test(
  "email-send: parallel idx=0 + idx=1 fan-out both succeed independently",
  async () => {
    // Pattern source: Sulga case. The Flutter ParallelActionsCard
    // dispatches BOTH actions in a single user click. The handler must
    // tolerate being called twice for the same triage row with
    // different action_idx values; idx=0 stamps sent_at and idx>0 does
    // not, so the partial-failure retry story stays clean.
    const row = makeRowWithTwoActions();
    const harness = makeRecordingDeps(row);
    const [r0, r1] = await Promise.all([
      handleSend({
        deps: harness.deps,
        userId: USER_ID,
        triageId: TRIAGE_ID,
        editedBody: null,
        actionIdx: 0,
        gateSecret: TEST_SECRET,
        loadAccessToken: fakeTokenLoader(),
      }),
      handleSend({
        deps: harness.deps,
        userId: USER_ID,
        triageId: TRIAGE_ID,
        editedBody: null,
        actionIdx: 1,
        gateSecret: TEST_SECRET,
        loadAccessToken: fakeTokenLoader(),
      }),
    ]);
    assertEquals(r0.status, 200);
    assertEquals(r1.status, 200);
    assertEquals(harness.calls.sendArgs.length, 2);
    // Each action hit its own recipient.
    const recipients = harness.calls.sendArgs.map((a) => a.to).sort();
    assertEquals(recipients, [
      "jokela@migri.fi",
      "kirjaamo.helsinki@poliisi.fi",
    ]);
    // Exactly one markSent (the legacy idx=0 path).
    assertEquals(harness.calls.markSent.length, 1);
  },
);
