// Deno tests for the email-triage ↔ 15-lawyer-consilium wiring.
// -----------------------------------------------------------------------------
// Covers the EMAIL_TRIAGE_USE_CONSILIUM feature flag introduced 2026-05-25:
//
//   (a) flag OFF → orchestrator never calls deps.callConsilium, the legacy
//       single-Sonnet path runs unchanged, and `lawyer_opinions` is null on
//       the persisted row.
//   (b) flag ON  → orchestrator calls deps.callConsilium exactly once per
//       parse attempt, and `lawyer_opinions` from the consilium response are
//       forwarded to the persisted row.
//   (c) flag ON + lawyer_opinions populated → audit-trail end-to-end: the
//       persisted row carries the SAME opinion payloads the consilium
//       emitted, in the SAME order, with all six wire fields intact.
//
// Run (from app/advocat_project):
//   deno test --allow-read --allow-env \
//     supabase/functions/email-triage/__tests__/triage_consilium_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  type AnthropicCallArgs,
  type AnthropicResponse,
  type ConsiliumCallArgs,
  CONSILIUM_FLAG_ENV,
  type LawyerOpinion,
  type MinimalTriageDeps,
  runTriage,
  type ThreadRecord,
  type TriageInsertRow,
} from "../triage_logic.ts";

// Same fixture shape as triage_logic_test.ts so both test files agree on
// what a "happy path" Sonnet response looks like. Kept in sync intentionally
// — if the v1.1-final block schema changes, BOTH test files need updates.
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

// Three sample lawyer opinions — one per stance the timeline UI renders.
// The shape matches ConsiliumRoleOpinionPayload from consilium.ts (FLAT,
// post-2026-05-25 bug fix). If consilium.ts changes the shape, this fixture
// must be updated in lockstep.
const SAMPLE_OPINIONS: LawyerOpinion[] = [
  {
    role_id: "senior-asianajaja",
    role_name: "Senior Asianajaja",
    opinion:
      "Asia on rutiininomainen vastaanottokuittaus. Suosittelen lähettämään " +
      "vahvistuksen sisäisellä määräajalla.",
    position: "push",
    confidence: 0.85,
    key_citation: "[[ref:hol:122]]",
  },
  {
    role_id: "strategist",
    role_name: "Strategist",
    opinion:
      "Без действий по существу — это лишь подтверждение регистрации, " +
      "следующий ход за Valtiokonttori.",
    position: "investigate",
    confidence: null,
    key_citation: null,
  },
  {
    role_id: "criminal-defender",
    role_name: "Criminal Defender",
    opinion: "[роль недоступна]",
    position: "out_of_scope",
    confidence: null,
    key_citation: null,
  },
];

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
        body_plaintext:
          "Viestinne on vastaanotettu, kirjattu diaariin 12345/2026.",
        sent_at: "2026-05-06T09:13:00Z",
        has_attachments: false,
        attachments_meta: [],
        headers_meta: {},
      },
    ],
  };
}

interface CallTrace {
  sonnetCalls: number;
  consiliumCalls: number;
  lastSonnetArgs: AnthropicCallArgs | null;
  lastConsiliumArgs: ConsiliumCallArgs | null;
}

function makeFakeDeps(opts: {
  capturedRow: { row: TriageInsertRow | null };
  trace: CallTrace;
  /** Provide to enable the consilium dep wiring. */
  consiliumOpinions?: LawyerOpinion[];
  consiliumSynthesis?: string;
}): MinimalTriageDeps {
  const base: MinimalTriageDeps = {
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
    async callSonnet(args: AnthropicCallArgs): Promise<AnthropicResponse> {
      opts.trace.sonnetCalls += 1;
      opts.trace.lastSonnetArgs = args;
      return {
        content: FIXTURE_B,
        input_tokens: 1000,
        output_tokens: 500,
      };
    },
    async persistTriageRow(row) {
      opts.capturedRow.row = row;
      return { id: "triage-1" };
    },
    async markThreadTriageStatus(_threadId, _status) {
      // no-op
    },
    async appendCaseEvent(_args) {
      // no-op
    },
    async scheduleAgentIntention(_args) {
      // no-op
    },
  };

  if (opts.consiliumOpinions !== undefined) {
    base.callConsilium = async (args: ConsiliumCallArgs) => {
      opts.trace.consiliumCalls += 1;
      opts.trace.lastConsiliumArgs = args;
      return {
        content: FIXTURE_B,
        input_tokens: 1500,
        output_tokens: 600,
        lawyer_opinions: opts.consiliumOpinions,
        consilium_synthesis: opts.consiliumSynthesis,
      };
    };
  }

  return base;
}

// ─── Env flag helpers ────────────────────────────────────────────────────────
// Deno.test runs in-process, so we mutate the env var around each test and
// reset it on exit to avoid leaking state across tests.

function setFlag(value: string | null) {
  if (value === null) {
    Deno.env.delete(CONSILIUM_FLAG_ENV);
  } else {
    Deno.env.set(CONSILIUM_FLAG_ENV, value);
  }
}

// =============================================================================
// Tests
// =============================================================================

Deno.test("triage-consilium (a) — flag OFF skips consilium dep, legacy path runs", async () => {
  setFlag(null);
  const trace: CallTrace = {
    sonnetCalls: 0,
    consiliumCalls: 0,
    lastSonnetArgs: null,
    lastConsiliumArgs: null,
  };
  const captured: { row: TriageInsertRow | null } = { row: null };
  // Wire BOTH deps — but the flag is off, so callConsilium MUST NOT fire.
  const deps = makeFakeDeps({
    capturedRow: captured,
    trace,
    consiliumOpinions: SAMPLE_OPINIONS,
    consiliumSynthesis: "synthesis text",
  });

  const out = await runTriage(deps, {
    thread_id: "thread-1",
    user_id: "user-1",
    auto_send_enabled: false,
    gate_secret: "test-secret",
  });

  assert(out.ok);
  if (!out.ok) return;
  assertEquals(trace.sonnetCalls, 1, "legacy path uses Sonnet exactly once");
  assertEquals(trace.consiliumCalls, 0, "consilium dep MUST NOT fire when flag off");
  assertEquals(
    captured.row?.lawyer_opinions,
    null,
    "lawyer_opinions is null on the legacy path",
  );
});

Deno.test("triage-consilium (b) — flag ON routes through callConsilium", async () => {
  setFlag("true");
  try {
    const trace: CallTrace = {
      sonnetCalls: 0,
      consiliumCalls: 0,
      lastSonnetArgs: null,
      lastConsiliumArgs: null,
    };
    const captured: { row: TriageInsertRow | null } = { row: null };
    const deps = makeFakeDeps({
      capturedRow: captured,
      trace,
      consiliumOpinions: SAMPLE_OPINIONS,
      consiliumSynthesis: "Chairman synthesis: routine receipt confirmation.",
    });

    const out = await runTriage(deps, {
      thread_id: "thread-1",
      user_id: "user-1",
      auto_send_enabled: false,
      gate_secret: "test-secret",
    });

    assert(out.ok);
    if (!out.ok) return;
    assertEquals(
      trace.consiliumCalls,
      1,
      "consilium dep fires exactly once when flag is on",
    );
    assertEquals(
      trace.sonnetCalls,
      0,
      "legacy Sonnet path MUST be bypassed when consilium routes the call",
    );
    // The consilium got a natural-language query, NOT a structured <context>.
    assert(
      typeof trace.lastConsiliumArgs?.consiliumQuery === "string" &&
        trace.lastConsiliumArgs!.consiliumQuery.length > 0,
      "consiliumQuery is built from the inbound subject + body",
    );
    assert(
      trace.lastConsiliumArgs!.consiliumQuery.includes("12345/2026"),
      "consiliumQuery surfaces the inbound subject keywords",
    );
  } finally {
    setFlag(null);
  }
});

Deno.test("triage-consilium (c) — lawyer_opinions persisted to row", async () => {
  setFlag("1"); // alternate truthy form
  try {
    const trace: CallTrace = {
      sonnetCalls: 0,
      consiliumCalls: 0,
      lastSonnetArgs: null,
      lastConsiliumArgs: null,
    };
    const captured: { row: TriageInsertRow | null } = { row: null };
    const deps = makeFakeDeps({
      capturedRow: captured,
      trace,
      consiliumOpinions: SAMPLE_OPINIONS,
      consiliumSynthesis: "Synth body",
    });

    const out = await runTriage(deps, {
      thread_id: "thread-1",
      user_id: "user-1",
      auto_send_enabled: false,
      gate_secret: "test-secret",
    });

    assert(out.ok);
    if (!out.ok) return;
    const persistedOpinions = captured.row?.lawyer_opinions;
    assert(
      Array.isArray(persistedOpinions),
      "lawyer_opinions is an array on the persisted row",
    );
    assertEquals(persistedOpinions!.length, SAMPLE_OPINIONS.length);
    for (let i = 0; i < SAMPLE_OPINIONS.length; i++) {
      const expected = SAMPLE_OPINIONS[i];
      const actual = persistedOpinions![i];
      assertEquals(actual.role_id, expected.role_id);
      assertEquals(actual.role_name, expected.role_name);
      assertEquals(actual.opinion, expected.opinion);
      assertEquals(actual.position, expected.position);
      assertEquals(actual.confidence, expected.confidence);
      assertEquals(actual.key_citation, expected.key_citation);
    }
    // Audit trail: raw_model_output should include the synthesis under the
    // documented sentinel so reviewers can split structured vs synthesis.
    assert(
      typeof captured.row?.raw_model_output === "string" &&
        captured.row!.raw_model_output!.includes("consilium_synthesis"),
      "raw_model_output retains the consilium synthesis under sentinel",
    );
  } finally {
    setFlag(null);
  }
});

Deno.test("triage-consilium — flag ON without callConsilium dep falls back to legacy", async () => {
  // Defense-in-depth: even with the env flag set, if the caller hasn't
  // wired callConsilium (e.g. a test harness, an old prod deploy) the
  // orchestrator MUST silently fall back to the legacy single-Sonnet path.
  setFlag("true");
  try {
    const trace: CallTrace = {
      sonnetCalls: 0,
      consiliumCalls: 0,
      lastSonnetArgs: null,
      lastConsiliumArgs: null,
    };
    const captured: { row: TriageInsertRow | null } = { row: null };
    // No consiliumOpinions → makeFakeDeps does NOT wire callConsilium.
    const deps = makeFakeDeps({ capturedRow: captured, trace });

    const out = await runTriage(deps, {
      thread_id: "thread-1",
      user_id: "user-1",
      auto_send_enabled: false,
      gate_secret: "test-secret",
    });

    assert(out.ok);
    if (!out.ok) return;
    assertEquals(trace.sonnetCalls, 1, "legacy Sonnet runs when dep not wired");
    assertEquals(trace.consiliumCalls, 0);
    assertEquals(captured.row?.lawyer_opinions, null);
  } finally {
    setFlag(null);
  }
});
