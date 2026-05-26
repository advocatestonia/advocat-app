// Deno tests for email-triage/triage_logic.ts (D4 — orchestrator).
// -----------------------------------------------------------------------------
// We pin three flows end-to-end against a mocked Anthropic + Supabase:
//
//   1. Happy path — Sonnet returns Fixture B (auto_send_eligible). Phase 1
//      hard-caps to hold_for_user_review, gate runs, token issued, row
//      persists with severity=MEDIUM (no deadlines).
//   2. Phase-1 hard-cap — even when reviewer + parser + policy-gate all
//      pass, the row's send_recommendation is hold_for_user_review.
//   3. Regenerate-once — first model call returns garbage, second call
//      returns Fixture B; parse_attempts=2.
//
// Run:
//   deno test --allow-read --allow-env \
//     supabase/functions/email-triage/__tests__/triage_logic_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  type AnthropicCallArgs,
  type AnthropicResponse,
  buildContextSuffix,
  formatInboundAttachments,
  type MinimalTriageDeps,
  runTriage,
  type ThreadRecord,
  type TriageInsertRow,
} from "../triage_logic.ts";
import type { InboundAttachment } from "../wiring.ts";

const FIXTURE_B = `<privilege_check>passed</privilege_check>
<conflict_check>passed</conflict_check>
<triage>
TRACK: [korvausvaatimus_valtiokonttori]
INBOUND: receipt confirmation from kirjaamo@valtiokonttori.fi
KEY FACTS:
  - Valtiokonttori confirms receipt
  - Dnro 12345/2026 assigned
DEADLINES: none
CONTRADICTIONS: none
EVIDENCE GAPS: none
POSTURE: reply_now
REASONING: Routine acknowledgement.
</triage>
<draft language="fi" addressed_to="kirjaamo@valtiokonttori.fi">
Subject: Vastaus: Vastaanotettu — dnro 12345/2026

Arvoisa kirjaamo,

vahvistan vastaanottaneeni dnro 12345/2026.

Ystävällisin terveisin,
Dmitri Sulga
</draft>
<gdpr_basis>
recipient: kirjaamo@valtiokonttori.fi
art_6_basis: (c)
art_9_basis: n/a
art_10_basis: n/a
</gdpr_basis>
<actions_required>
- type: other
  target: monitor
  deadline: 2026-11-06
  why: track decision window
</actions_required>
<user_brief language="ru">Подтверждение получения, дело 12345/2026.</user_brief>
<send_recommendation>auto_send_eligible</send_recommendation>`;

function makeFakeThread(): ThreadRecord {
  return {
    id: "thread-1",
    user_id: "user-1",
    case_id: null,
    subject: "Vastaanotettu — dnro 12345/2026",
    participants: ["kirjaamo@valtiokonttori.fi", "user-1@example.com"],
    messages: [
      {
        id: "msg-1",
        gmail_message_id: "gm-1",
        sender_email: "kirjaamo@valtiokonttori.fi",
        sender_name: "Valtiokonttori",
        to_recipients: ["user-1@example.com"],
        cc_recipients: [],
        subject: "Vastaanotettu — dnro 12345/2026",
        body_plaintext: "Viestinne on vastaanotettu, kirjattu diaariin 12345/2026.",
        sent_at: "2026-05-06T09:13:00Z",
        has_attachments: false,
        attachments_meta: [],
        headers_meta: {},
      },
    ],
  };
}

function makeFakeDeps(opts: {
  responses: string[];
  capturedRow?: { row: TriageInsertRow | null };
  scheduledIntentions?: Array<unknown>;
}): MinimalTriageDeps {
  let callIndex = 0;
  return {
    async loadThread(_id) {
      return makeFakeThread();
    },
    async loadActiveCase(_caseId) {
      return null;
    },
    async loadMemoryBlock(_uid) {
      return {
        identity_markers: {},
        dead_addresses: [],
        own_counsel_emails: [],
        known_privileged_individuals: [],
      };
    },
    async loadUserPrefs(_uid) {
      return {
        preferred_language: "ru",
        signature: { fi: "Dmitri Sulga", ru: "", et: "", en: "" },
        timezone: "Europe/Helsinki",
        auto_send_opt_in: false,
        allowed_auto_send_categories: ["acknowledgement"],
      };
    },
    async loadLawSearch(_q) {
      return [];
    },
    async checkQuota(_uid) {
      return { allowed: true, remaining: 1200, plan: "premium" };
    },
    async callSonnet(_args: AnthropicCallArgs): Promise<AnthropicResponse> {
      const text = opts.responses[callIndex] ?? opts.responses[opts.responses.length - 1];
      callIndex++;
      return {
        content: text,
        input_tokens: 1000,
        output_tokens: 500,
      };
    },
    async persistTriageRow(row) {
      if (opts.capturedRow) opts.capturedRow.row = row;
      return { id: "triage-1" };
    },
    async markThreadTriageStatus(_threadId, _status) {
      // no-op for tests
    },
    async appendCaseEvent(_args) {
      // no-op
    },
    async scheduleAgentIntention(args) {
      opts.scheduledIntentions?.push(args);
    },
  };
}

// =============================================================================
// Tests
// =============================================================================

Deno.test("runTriage — happy path persists row, Phase 1 caps to hold_for_user_review", async () => {
  const captured: { row: TriageInsertRow | null } = { row: null };
  const intentions: unknown[] = [];
  const deps = makeFakeDeps({
    responses: [FIXTURE_B],
    capturedRow: captured,
    scheduledIntentions: intentions,
  });
  const out = await runTriage(deps, {
    thread_id: "thread-1",
    user_id: "user-1",
    auto_send_enabled: false,
    gate_secret: "test-secret",
  });
  assert(out.ok);
  if (!out.ok) return;
  assertEquals(out.severity, "MEDIUM"); // no deadlines + posture=reply_now
  // Phase 1 hard-cap: even when model emits auto_send_eligible, row stores
  // hold_for_user_review.
  assertEquals(out.send_recommendation, "hold_for_user_review");
  assertEquals(out.parse_attempts, 1);
  assertEquals(captured.row?.send_recommendation, "hold_for_user_review");
  assertEquals(captured.row?.privilege_check, "passed");
  assert(captured.row?.draft_body?.includes("dnro 12345/2026"));
  // Intention not scheduled because no hot deadline.
  assertEquals(intentions.length, 0);
});

Deno.test("runTriage — regenerate-once on parse failure", async () => {
  const captured: { row: TriageInsertRow | null } = { row: null };
  const deps = makeFakeDeps({
    responses: ["unparseable garbage", FIXTURE_B],
    capturedRow: captured,
  });
  const out = await runTriage(deps, {
    thread_id: "thread-1",
    user_id: "user-1",
    auto_send_enabled: false,
    gate_secret: "test-secret",
  });
  assert(out.ok);
  if (!out.ok) return;
  assertEquals(out.parse_attempts, 2);
  assertEquals(captured.row?.reviewer_status, "regenerated");
});

Deno.test("runTriage — quota exhausted blocks", async () => {
  const deps = makeFakeDeps({ responses: [FIXTURE_B] });
  // Override quota to deny.
  const denyingDeps: MinimalTriageDeps = {
    ...deps,
    async checkQuota(_uid) {
      return { allowed: false, remaining: 0, plan: "free" };
    },
  };
  const out = await runTriage(denyingDeps, {
    thread_id: "thread-1",
    user_id: "user-1",
    auto_send_enabled: false,
    gate_secret: "test-secret",
  });
  assert(!out.ok);
  if (out.ok) return;
  assertEquals(out.error_code, "quota_exhausted");
});

Deno.test("runTriage — hot deadline schedules an agent intention", async () => {
  const FIXTURE_HOT = FIXTURE_B.replace(
    "DEADLINES: none\n",
    "DEADLINES:\n  - 2026-05-09 (Δ 3 days, post-holiday-shift) — KHO appeal HOL 2019/808\n",
  );
  const intentions: unknown[] = [];
  const deps = makeFakeDeps({
    responses: [FIXTURE_HOT],
    scheduledIntentions: intentions,
  });
  const out = await runTriage(deps, {
    thread_id: "thread-1",
    user_id: "user-1",
    auto_send_enabled: false,
    gate_secret: "test-secret",
  });
  assert(out.ok);
  if (!out.ok) return;
  // 3-day deadline → HIGH per §737
  assertEquals(out.severity, "HIGH");
  assertEquals(intentions.length, 1);
});

Deno.test("runTriage — empty thread fails before model call", async () => {
  const deps = makeFakeDeps({ responses: [] });
  const denyingDeps: MinimalTriageDeps = {
    ...deps,
    async loadThread(_id) {
      const t = makeFakeThread();
      t.messages = [];
      return t;
    },
  };
  const out = await runTriage(denyingDeps, {
    thread_id: "thread-1",
    user_id: "user-1",
    auto_send_enabled: false,
    gate_secret: "test-secret",
  });
  assert(!out.ok);
  if (out.ok) return;
  assertEquals(out.error_code, "empty_thread");
});

Deno.test("runTriage — wrong-user thread rejected", async () => {
  const deps = makeFakeDeps({ responses: [FIXTURE_B] });
  const out = await runTriage(deps, {
    thread_id: "thread-1",
    user_id: "different-user",
    auto_send_enabled: false,
    gate_secret: "test-secret",
  });
  assert(!out.ok);
  if (out.ok) return;
  assertEquals(out.error_code, "thread_user_mismatch");
});

// =============================================================================
// Fix #2 (2026-05-26) — inbound_attachments block in system prompt
// =============================================================================
// When the deps wire `loadInboundAttachments` and it returns a non-empty
// list, the rendered `<context>` suffix must include an
// `<inbound_attachments>` block with the per-attachment text. The block
// is what lets Sonnet reason about the PDF an inbound email actually
// carried (käännytys decisions, court orders, Migri letters) instead of
// guessing from the subject line alone.

Deno.test(
  "formatInboundAttachments — empty list emits no block",
  () => {
    assertEquals(formatInboundAttachments([]), "");
  },
);

Deno.test(
  "formatInboundAttachments — renders attachment text inside XML tags",
  () => {
    const block = formatInboundAttachments([
      {
        filename: "kaennytys.pdf",
        mime: "application/pdf",
        parsed_text: "Neuvostoliitto — käännytyspäätös",
        parsed_meta: { page_count: 4 },
      },
    ]);
    assert(block.startsWith("<inbound_attachments>"));
    assert(block.endsWith("</inbound_attachments>"));
    assert(block.includes(`filename="kaennytys.pdf"`));
    assert(block.includes(`mime="application/pdf"`));
    assert(block.includes("Neuvostoliitto — käännytyspäätös"));
  },
);

Deno.test(
  "formatInboundAttachments — >3 attachments truncates with overflow sentinel",
  () => {
    const make = (i: number): InboundAttachment => ({
      filename: `doc-${i}.pdf`,
      mime: "application/pdf",
      parsed_text: `body-${i}`,
      parsed_meta: null,
    });
    const block = formatInboundAttachments([1, 2, 3, 4, 5].map(make));
    assert(block.includes("doc-1.pdf"));
    assert(block.includes("doc-2.pdf"));
    assert(block.includes("doc-3.pdf"));
    assert(!block.includes("doc-4.pdf"));
    assert(!block.includes("doc-5.pdf"));
    assert(block.includes("[…overflow truncated]"));
  },
);

Deno.test(
  "buildContextSuffix — inbound_attachments appears AFTER <thread> section",
  () => {
    const suffix = buildContextSuffix({
      currentDate: "2026-05-26",
      userEmail: "owner@example.com",
      userLang: "fi",
      userPrefs: {
        preferred_language: "fi",
        signature: { fi: "Dmitri Sulga", en: "", et: "", ru: "" },
      },
      userLastTz: "Europe/Helsinki",
      memoryBlock: {
        identity_markers: {},
        dead_addresses: [],
        own_counsel_emails: [],
        known_privileged_individuals: [],
      },
      activeCase: null,
      lawCtx: [],
      thread: {
        id: "thread-1",
        user_id: "user-1",
        case_id: null,
        subject: "Käännytyspäätös",
        participants: ["migri@migri.fi"],
        messages: [
          {
            id: "m-1",
            gmail_message_id: "g-1",
            sender_email: "migri@migri.fi",
            sender_name: "Migri",
            to_recipients: ["owner@example.com"],
            cc_recipients: [],
            subject: "Käännytys",
            body_plaintext: "Liitteenä päätös.",
            sent_at: "2026-05-26T08:00:00Z",
            has_attachments: true,
            attachments_meta: [{ filename: "kaennytys.pdf" }],
            headers_meta: {},
          },
        ],
      },
      ownCounselFlag: false,
      inboundAttachments: [
        {
          filename: "kaennytys.pdf",
          mime: "application/pdf",
          parsed_text: "MIGRI-DECISION-2026-05-26 Neuvostoliitto kansalaisuus",
          parsed_meta: { page_count: 4, doc_type: "decision" },
        },
      ],
    });

    // Block is present + carries the attachment text.
    assert(suffix.includes("<inbound_attachments>"));
    assert(suffix.includes("</inbound_attachments>"));
    assert(suffix.includes(`filename="kaennytys.pdf"`));
    assert(suffix.includes("MIGRI-DECISION-2026-05-26"));

    // Ordering — thread section appears BEFORE the inbound_attachments
    // block (the spec puts attachments AFTER the thread so the model
    // reads the message first, then the structured payload).
    const threadIdx = suffix.indexOf("Email thread (oldest → newest):");
    const attachIdx = suffix.indexOf("<inbound_attachments>");
    assert(threadIdx >= 0);
    assert(attachIdx >= 0);
    assert(threadIdx < attachIdx);
  },
);

Deno.test(
  "runTriage — inbound_attachments surface in the rendered system prompt",
  async () => {
    // Capture the systemBlocks that runTriage hands to callSonnet so we
    // can assert the attachment text actually made it into the prompt.
    const captured: { systemPrompt: string | null } = { systemPrompt: null };
    const baseDeps = makeFakeDeps({ responses: [FIXTURE_B] });
    const deps: MinimalTriageDeps = {
      ...baseDeps,
      async loadInboundAttachments(_threadId: string) {
        return [
          {
            filename: "kaennytys.pdf",
            mime: "application/pdf",
            parsed_text:
              "MIGRI-FIX2-MARKER kansalaisuusyksikkö 26.5.2026 päätös",
            parsed_meta: { page_count: 4 },
          },
        ];
      },
      async callSonnet(args: AnthropicCallArgs): Promise<AnthropicResponse> {
        // Stitch the system blocks the same way Anthropic would consume
        // them — a single concatenated prompt string for assertion.
        captured.systemPrompt = args.systemBlocks.map((b) => b.text).join("\n");
        return {
          content: FIXTURE_B,
          input_tokens: 1000,
          output_tokens: 500,
        };
      },
    };

    const out = await runTriage(deps, {
      thread_id: "thread-1",
      user_id: "user-1",
      auto_send_enabled: false,
      gate_secret: "test-secret",
    });
    assert(out.ok);
    if (!out.ok) return;
    assertExists(captured.systemPrompt);
    assert(
      captured.systemPrompt!.includes("<inbound_attachments>"),
      "system prompt must carry the <inbound_attachments> block",
    );
    assert(
      captured.systemPrompt!.includes("MIGRI-FIX2-MARKER"),
      "system prompt must carry the parsed attachment text",
    );
    assert(
      captured.systemPrompt!.includes(`filename="kaennytys.pdf"`),
      "system prompt must carry the attachment filename attribute",
    );
  },
);
