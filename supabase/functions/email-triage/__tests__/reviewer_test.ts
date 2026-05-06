// Deno tests for email-triage/reviewer.ts (D4 — Haiku-grade reviewer).
// -----------------------------------------------------------------------------
// Anchors per OPERATOR_PROMPT §697:
//   1. case-number anchor on draft
//   2. conflict_check well-formed
//   3. appeal_route on decision-shaped subject + reply_now
//   4. gdpr_basis whenever draft emitted
//   5. actions_required whenever posture != no_reply
//   6. own_counsel_advisory hard cap on send_recommendation
// -----------------------------------------------------------------------------

import { assert, assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";

import type { ParsedTriage } from "../parse_blocks.ts";
import { runReviewerLocal } from "../reviewer.ts";

function basePassed(): ParsedTriage {
  return {
    privilege_check: "passed",
    conflict_check: "passed",
    triage: {
      track: ["t"],
      inbound: "x",
      key_facts: [],
      deadlines: [],
      contradictions: [],
      evidence_gaps: [],
      posture: "reply_now",
      reasoning: "reasoning",
    },
    appeal_route: null,
    attachments: [],
    draft: {
      language: "fi",
      addressed_to: "kirjaamo@valtiokonttori.fi",
      subject: "Vastaus: Vastaanotettu — dnro 12345/2026",
      body: "vahvistan vastaanottaneeni dnro 12345/2026.",
      to: ["kirjaamo@valtiokonttori.fi"],
      cc: [],
    },
    gdpr_basis: [
      {
        recipient: "kirjaamo@valtiokonttori.fi",
        art_6_basis: "(c)",
        art_9_basis: "n/a",
        art_10_basis: "n/a",
      },
    ],
    actions_required: [
      { type: "other", target: "monitor", deadline: "2026-11-06", why: "track" },
    ],
    user_brief: "ok",
    user_brief_language: "ru",
    memory_updates: [],
    send_recommendation: "auto_send_eligible",
    prompt_version: "v1.1-final",
  };
}

Deno.test("reviewer — happy path passes", () => {
  const r = runReviewerLocal(basePassed(), "Vastaanotettu — dnro 12345/2026");
  assertEquals(r.ok, true);
  assertEquals(r.failures.length, 0);
});

Deno.test("reviewer — missing case-number anchor fails", () => {
  const p = basePassed();
  p.draft!.subject = "Vastaus";
  p.draft!.body = "vahvistan vastaanottaneeni.";
  const r = runReviewerLocal(p, "Vastaanotettu");
  assertEquals(r.ok, false);
  assert(r.failures.includes("missing_case_number_anchor"));
});

Deno.test("reviewer — decision subject + reply_now without appeal_route fails", () => {
  const p = basePassed();
  p.appeal_route = null;
  const r = runReviewerLocal(p, "Päätös 22.04.2026 dnro 12345/2026");
  assertEquals(r.ok, false);
  assert(r.failures.includes("missing_appeal_route_on_decision"));
});

Deno.test("reviewer — gdpr_basis missing recipient fails", () => {
  const p = basePassed();
  p.gdpr_basis = [];
  const r = runReviewerLocal(p, "Vastaanotettu — dnro 12345/2026");
  assertEquals(r.ok, false);
  assert(r.failures.includes("missing_gdpr_basis_on_draft"));
});

Deno.test("reviewer — actions_required required when posture != no_reply", () => {
  const p = basePassed();
  p.actions_required = [];
  const r = runReviewerLocal(p, "Vastaanotettu — dnro 12345/2026");
  assertEquals(r.ok, false);
  assert(r.failures.includes("missing_actions_required"));
});

Deno.test("reviewer — own_counsel_advisory must hard-cap to hold_for_user_review", () => {
  const p = basePassed();
  p.privilege_check = "own_counsel_advisory";
  // model violates Rule 16.bis by emitting auto_send_eligible
  p.send_recommendation = "auto_send_eligible";
  const r = runReviewerLocal(p, "Asiassasi on se ongelma");
  assertEquals(r.ok, false);
  assert(
    r.failures.includes("own_counsel_advisory_must_be_hold_for_user_review"),
  );
});

Deno.test("reviewer — own_counsel_advisory passes when send_recommendation respects cap", () => {
  const p = basePassed();
  p.privilege_check = "own_counsel_advisory";
  p.send_recommendation = "hold_for_user_review";
  const r = runReviewerLocal(p, "dnro 1858/2026");
  assertEquals(r.ok, true);
});
