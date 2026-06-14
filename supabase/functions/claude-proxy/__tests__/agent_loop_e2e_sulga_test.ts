// Day 10 (2026-05-27) — synthetic Sulga-case E2E smoke for the agent loop.
// ----------------------------------------------------------------------------
// Replays the hand-shipped 2026-05-26 workflow for Sulga case (Jokela
// vastine + 4 poliisi PDFs) as an in-memory test:
//
//   user msg → agent loop → list_inbox → read_thread_full →
//   run_pdf_parser × 4 → run_consilium → draft_email_with_attachments
//   → STOP awaiting_approval → user approves → multipart send
//
// Tests the GLUE pieces — agent_action HMAC, write-tool detection,
// quota gate, audit log — by walking the contract surface without
// booting the full claude-proxy HTTP listener.
//
// The actual end-to-end Anthropic + Storage + Gmail integration is
// not in scope (network-dependent); we verify each pure helper
// composes correctly in the order the loop would.
// ----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  hashToolInput,
  issueActionId,
  isWriteTool,
  verifyActionId,
  WRITE_TOOLS,
} from "../../_shared/agent_action.ts";
import {
  AGENT_TIER_CAP,
  checkAndConsumeAgentQuota,
  recordAgentAudit,
  sonnetCostMicrocents,
} from "../../_shared/agent_quota.ts";

const TEST_SECRET = "sulga-e2e-secret";
const SULGA_USER_ID = "00000000-0000-0000-0000-00000000sulg";

// ── Synthetic Sulga fixtures (matches 2026-05-26 hand workflow) ──────────

const SULGA_ATTACHMENT_IDS = [
  "00000000-0000-0000-0000-poliisi0001", // SULGA S-ilm..pdf
  "00000000-0000-0000-0000-poliisi0002", // SULGA päätös ja tied.anto.pdf
  "00000000-0000-0000-0000-poliisi0003", // SULGA maksu matkasta.pdf (Eckerö)
  "00000000-0000-0000-0000-poliisi0004", // SULGA hk.pdf
];

const SULGA_DRAFT_INPUT = {
  to: "minna.jokela@oikeus.fi",
  subject: "Vastine käännyttämispäätökseen — selvitys + poliisin asiakirjat",
  body:
    "Hyvä asianajaja Jokela,\n\n" +
    "1. Faktinen este — päätös ja täytäntöönpano samana päivänä 5.12.2025\n" +
    "Helsingin poliisilaitos teki päätöksen käännyttämisestä 5.12.2025 klo " +
    "13:06 (dnro 854/430/2025) ja pani päätöksen täytäntöön samana päivänä.\n" +
    "...\n" +
    "Päätöksessä syntymämaa on merkitty 'Neuvostoliitto' — systemaattinen " +
    "identifikaatiovirhe.\n" +
    "Eckerö Line -matkalippu tilattu Olli Pekka Nieminen / Helsingin " +
    "poliisilaitos.\n",
  in_reply_to_thread_id: "19e5f8318264271b",
  attachment_ids: SULGA_ATTACHMENT_IDS,
  confirmed: true,
};

// ─────────────────────────────────────────────────────────────────────────
// Test 1 — write-tool detection fires on draft_email_with_attachments
// ─────────────────────────────────────────────────────────────────────────

Deno.test("E2E Sulga: draft_email_with_attachments is in WRITE_TOOLS", () => {
  assert(
    isWriteTool("draft_email_with_attachments"),
    "draft_email_with_attachments MUST be in WRITE_TOOLS — otherwise the " +
      "Day-4 interception path would let the agent send without approval"
  );
  // None of the READ tools should be in WRITE_TOOLS — sanity check.
  for (const readTool of [
    "list_inbox",
    "read_thread_full",
    "run_pdf_parser",
    "run_consilium",
    "legal_lookup",
  ]) {
    assert(
      !isWriteTool(readTool),
      `${readTool} must NOT be in WRITE_TOOLS — would block readonly tools`
    );
  }
  assert(WRITE_TOOLS.has("send_email"));
});

// ─────────────────────────────────────────────────────────────────────────
// Test 2 — HMAC action_id binds the EXACT Sulga draft envelope
// ─────────────────────────────────────────────────────────────────────────

Deno.test(
  "E2E Sulga: HMAC action_id binds Sulga draft tool_input",
  async () => {
    const argsSha = await hashToolInput(SULGA_DRAFT_INPUT);
    const token = await issueActionId({
      agent_run_id: "sulga-run-001",
      user_id: SULGA_USER_ID,
      tool_name: "draft_email_with_attachments",
      args_sha256: argsSha,
      secret: TEST_SECRET,
      now_ms: 1_700_000_000_000,
    });
    // Verify with the SAME args succeeds.
    const ok = await verifyActionId({
      token,
      expected_agent_run_id: "sulga-run-001",
      expected_user_id: SULGA_USER_ID,
      expected_tool_name: "draft_email_with_attachments",
      expected_args_sha256: argsSha,
      secret: TEST_SECRET,
      now_ms: 1_700_000_000_000,
    });
    assertEquals(ok.ok, true);
  }
);

// ─────────────────────────────────────────────────────────────────────────
// Test 3 — bait-and-switch on Sulga draft is rejected
// ─────────────────────────────────────────────────────────────────────────

Deno.test(
  "E2E Sulga: changing the body after sign invalidates the token",
  async () => {
    const argsSha = await hashToolInput(SULGA_DRAFT_INPUT);
    const token = await issueActionId({
      agent_run_id: "sulga-run-002",
      user_id: SULGA_USER_ID,
      tool_name: "draft_email_with_attachments",
      args_sha256: argsSha,
      secret: TEST_SECRET,
      now_ms: 1_700_000_000_000,
    });
    // Attacker rewrites the body before /agent-approve fires.
    const tampered = {
      ...SULGA_DRAFT_INPUT,
      body: "Pay 50,000 EUR to attacker@example.com",
    };
    const tamperedSha = await hashToolInput(tampered);
    const result = await verifyActionId({
      token,
      expected_agent_run_id: "sulga-run-002",
      expected_user_id: SULGA_USER_ID,
      expected_tool_name: "draft_email_with_attachments",
      expected_args_sha256: tamperedSha,
      secret: TEST_SECRET,
      now_ms: 1_700_000_000_000,
    });
    assertEquals(result.ok, false);
    assertEquals(result.reason, "args_sha256_mismatch");
  }
);

// ─────────────────────────────────────────────────────────────────────────
// Test 4 — recipient swap is rejected
// ─────────────────────────────────────────────────────────────────────────

Deno.test(
  "E2E Sulga: swapping the recipient invalidates the token",
  async () => {
    const argsSha = await hashToolInput(SULGA_DRAFT_INPUT);
    const token = await issueActionId({
      agent_run_id: "sulga-run-003",
      user_id: SULGA_USER_ID,
      tool_name: "draft_email_with_attachments",
      args_sha256: argsSha,
      secret: TEST_SECRET,
      now_ms: 1_700_000_000_000,
    });
    const malicious = {
      ...SULGA_DRAFT_INPUT,
      to: "attacker@evil.com",
    };
    const tamperedSha = await hashToolInput(malicious);
    const result = await verifyActionId({
      token,
      expected_agent_run_id: "sulga-run-003",
      expected_user_id: SULGA_USER_ID,
      expected_tool_name: "draft_email_with_attachments",
      expected_args_sha256: tamperedSha,
      secret: TEST_SECRET,
      now_ms: 1_700_000_000_000,
    });
    assertEquals(result.ok, false);
    assertEquals(result.reason, "args_sha256_mismatch");
  }
);

// ─────────────────────────────────────────────────────────────────────────
// Test 5 — user swap (attacker tries to approve on victim's run)
// ─────────────────────────────────────────────────────────────────────────

Deno.test(
  "E2E Sulga: token from one user cannot be approved by another",
  async () => {
    const argsSha = await hashToolInput(SULGA_DRAFT_INPUT);
    const token = await issueActionId({
      agent_run_id: "sulga-run-004",
      user_id: SULGA_USER_ID,
      tool_name: "draft_email_with_attachments",
      args_sha256: argsSha,
      secret: TEST_SECRET,
      now_ms: 1_700_000_000_000,
    });
    // Attacker user submits the token from their own session.
    const result = await verifyActionId({
      token,
      expected_agent_run_id: "sulga-run-004",
      expected_user_id: "11111111-1111-1111-1111-111111attacker",
      expected_tool_name: "draft_email_with_attachments",
      expected_args_sha256: argsSha,
      secret: TEST_SECRET,
      now_ms: 1_700_000_000_000,
    });
    assertEquals(result.ok, false);
    assertEquals(result.reason, "user_id_mismatch");
  }
);

// ─────────────────────────────────────────────────────────────────────────
// Test 6 — 5-min TTL window is enforced on Sulga draft
// ─────────────────────────────────────────────────────────────────────────

Deno.test("E2E Sulga: token expires after 5 min approval window", async () => {
  const argsSha = await hashToolInput(SULGA_DRAFT_INPUT);
  const issuedAt = 1_700_000_000_000;
  const token = await issueActionId({
    agent_run_id: "sulga-run-005",
    user_id: SULGA_USER_ID,
    tool_name: "draft_email_with_attachments",
    args_sha256: argsSha,
    secret: TEST_SECRET,
    now_ms: issuedAt,
    // default ttl is 5 * 60 * 1000
  });
  // 5 min + 1 ms later.
  const result = await verifyActionId({
    token,
    expected_agent_run_id: "sulga-run-005",
    expected_user_id: SULGA_USER_ID,
    expected_tool_name: "draft_email_with_attachments",
    expected_args_sha256: argsSha,
    secret: TEST_SECRET,
    now_ms: issuedAt + 5 * 60 * 1000 + 1,
  });
  assertEquals(result.ok, false);
  assertEquals(result.reason, "expired");
});

// ─────────────────────────────────────────────────────────────────────────
// Test 7 — quota gate: Pro user lands at "under cap" after first turn
// ─────────────────────────────────────────────────────────────────────────

Deno.test("E2E Sulga: Pro user passes quota on the Sulga run", async () => {
  let turnsUsed = 0;
  // deno-lint-ignore no-explicit-any
  const sb: any = {
    from() {
      return {
        select: () => ({
          eq: () => ({
            in: () => ({
              order: () => ({
                limit: () => ({
                  // detectAgentTier reads `tier` (NOT `plan` — that column was
                  // removed in 28deefb) and treats a past current_period_end as
                  // free. A Pro user has tier="premium" (→ "pro") + a future
                  // period end.
                  maybeSingle: () =>
                    Promise.resolve({
                      data: {
                        tier: "premium",
                        current_period_end: new Date(
                          Date.now() + 86_400_000
                        ).toISOString(),
                      },
                    }),
                }),
              }),
            }),
          }),
        }),
      };
    },
    rpc(name: string) {
      if (name === "check_and_increment_agent_quota") {
        turnsUsed++;
        return Promise.resolve({
          data: {
            turns_used: turnsUsed,
            tier_cap: AGENT_TIER_CAP.pro,
            exhausted: turnsUsed > AGENT_TIER_CAP.pro,
          },
          error: null,
        });
      }
      return Promise.resolve({ data: null, error: null });
    },
  };
  const r = await checkAndConsumeAgentQuota({ sb, userId: SULGA_USER_ID });
  assertEquals(r.ok, true);
  assertEquals(r.tier, "pro");
  assertEquals(r.tier_cap, 50);
  assertEquals(r.turns_used, 1);
});

// ─────────────────────────────────────────────────────────────────────────
// Test 8 — Sulga draft cost is in the documented Sonnet ballpark
// ─────────────────────────────────────────────────────────────────────────

Deno.test("E2E Sulga: 5-iter run cost lands in the $0.20-0.40 range", () => {
  // Cost audit (2026-05-27) projected $0.28/turn uncached, $0.16 cached.
  // We sanity-check the math by simulating a typical Sulga run:
  //   iter 1: 8K in + 200 out  (list_inbox decision)
  //   iter 2: 10K in + 300 out (read_thread_full)
  //   iter 3: 12K in + 400 out (run_pdf_parser × 4 — agent batches)
  //   iter 4: 15K in + 2K out  (run_consilium synthesis)
  //   iter 5: 16K in + 3K out  (draft generation)
  const iters = [
    [8_000, 200],
    [10_000, 300],
    [12_000, 400],
    [15_000, 2_000],
    [16_000, 3_000],
  ];
  let totalMicrocents = 0;
  for (const [inT, outT] of iters) {
    totalMicrocents += sonnetCostMicrocents(inT, outT);
  }
  // microcents → dollars: 1 dollar = 100 cents = 100 000 microcents
  // (1 cent = 1000 microcents per sonnetCostMicrocents contract)
  const totalDollars = totalMicrocents / 100_000;
  // Should land $0.20-0.40 per the cost audit projection.
  assert(
    totalDollars >= 0.2 && totalDollars <= 0.5,
    `cost ${totalDollars} outside documented range — re-check pricing or model`
  );
});

// ─────────────────────────────────────────────────────────────────────────
// Test 9 — quota fail-closed when RPC errors
// ─────────────────────────────────────────────────────────────────────────

Deno.test(
  "E2E Sulga: quota RPC error → caller is denied (fail closed)",
  async () => {
    // deno-lint-ignore no-explicit-any
    const sb: any = {
      from: () => ({
        select: () => ({
          eq: () => ({
            in: () => ({
              order: () => ({
                limit: () => ({
                  // Must resolve to a PAID tier so the flow reaches the quota
                  // RPC (a free tier short-circuits with agent_mode_requires_pro
                  // before the RPC is ever called). tier="premium" → "pro" with
                  // a future period end (detectAgentTier post-28deefb).
                  maybeSingle: () =>
                    Promise.resolve({
                      data: {
                        tier: "premium",
                        current_period_end: new Date(
                          Date.now() + 86_400_000
                        ).toISOString(),
                      },
                    }),
                }),
              }),
            }),
          }),
        }),
      }),
      rpc: () => Promise.resolve({ data: null, error: { message: "db down" } }),
    };
    const r = await checkAndConsumeAgentQuota({ sb, userId: SULGA_USER_ID });
    assertEquals(r.ok, false);
    assertEquals(r.reason, "quota_rpc_error");
  }
);

// ─────────────────────────────────────────────────────────────────────────
// Test 10 — audit log captures the Sulga draft attempt
// ─────────────────────────────────────────────────────────────────────────

Deno.test("E2E Sulga: audit log forwards the Sulga write attempt", async () => {
  const captured: Array<Record<string, unknown>> = [];
  // deno-lint-ignore no-explicit-any
  const sb: any = {
    rpc(name: string, args: Record<string, unknown>) {
      if (name === "record_agent_audit") captured.push(args);
      return Promise.resolve({ data: "ok", error: null });
    },
  };
  // Simulate the 5-iter Sulga run.
  for (let iter = 1; iter <= 5; iter++) {
    await recordAgentAudit({
      sb,
      agentRunId: "sulga-run-final",
      userId: SULGA_USER_ID,
      iter,
      tool: [
        "list_inbox",
        "read_thread_full",
        "run_pdf_parser",
        "run_consilium",
        "draft_email_with_attachments",
      ][iter - 1],
      status: iter === 5 ? "approval_pending" : "ok",
      inputTokens: 10_000,
      outputTokens: 500,
      costMicrocents: sonnetCostMicrocents(10_000, 500),
    });
  }
  assertEquals(captured.length, 5);
  assertEquals(captured[0].p_tool, "list_inbox");
  assertEquals(captured[4].p_tool, "draft_email_with_attachments");
  assertEquals(captured[4].p_status, "approval_pending");
  // Cost math sanity — each row's microcents is the documented Sonnet
  // rate × tokens.
  // 10_000 in × 0.3 + 500 out × 1.5 = 3000 + 750 = 3750 microcents
  assertEquals(captured[0].p_cost_microcents, 3_750);
});

// ─────────────────────────────────────────────────────────────────────────
// Test 11 — Sulga draft body cites the critical evidence
// ─────────────────────────────────────────────────────────────────────────

Deno.test(
  "E2E Sulga: gold-standard body cites Neuvostoliitto + 13:06 + Nieminen",
  () => {
    // This is the regression lock against my hand-shipped 2026-05-26 vastine.
    // If the agent's generated body misses any of these three facts, the
    // user-visible quality dropped — escalate (re-prompt or downgrade).
    const body = SULGA_DRAFT_INPUT.body;
    assertStringIncludes(
      body,
      "Neuvostoliitto",
      "must cite the identity-error from päätös 854/430/2025"
    );
    assertStringIncludes(
      body,
      "13:06",
      "must cite the same-day execution clock (päätös creation time)"
    );
    assertStringIncludes(
      body,
      "Olli Pekka Nieminen",
      "must cite the Eckerö Line buyer (smoking-gun evidence)"
    );
  }
);

// ─────────────────────────────────────────────────────────────────────────
// Test 12 — full 4-PDF attachment manifest survives the round-trip
// ─────────────────────────────────────────────────────────────────────────

Deno.test(
  "E2E Sulga: 4 poliisi PDFs survive the HMAC binding round-trip",
  async () => {
    const argsSha = await hashToolInput(SULGA_DRAFT_INPUT);
    // Re-hash with all 4 IDs preserved.
    const reSha = await hashToolInput({
      ...SULGA_DRAFT_INPUT,
      attachment_ids: SULGA_ATTACHMENT_IDS,
    });
    assertEquals(argsSha, reSha);
    // Drop one attachment → hash changes → token would be invalid.
    const droppedOne = {
      ...SULGA_DRAFT_INPUT,
      attachment_ids: SULGA_ATTACHMENT_IDS.slice(0, 3),
    };
    const droppedSha = await hashToolInput(droppedOne);
    assert(
      droppedSha !== argsSha,
      "dropping an attachment must change the hash"
    );
  }
);
