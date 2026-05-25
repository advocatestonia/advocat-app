// email_send_action_idx_test.ts
// -----------------------------------------------------------------------------
// Coordination test (2026-05-25) — locks the contract between the Parallel
// Actions Panel (Flutter) and the `email-send` edge function (owned by the
// sibling "Approve&Send UI" agent).
//
// Wire shape from Flutter:
//   POST email-send
//     Authorization: Bearer <user JWT>
//     body: { triage_id: uuid, action_idx?: number, edited_body?: string }
//
// Required edge-function behaviour:
//   • action_idx omitted OR action_idx === 0 → use the legacy draft_*
//     columns on email_triage_results (backwards compat for the existing
//     single-draft approveAndSend flow).
//   • action_idx > 0 AND email_triage_results.proposed_actions[action_idx]
//     exists → use THAT action's to_addr / subject / body / cc / language.
//   • action_idx out of bounds → 400 with error_code='action_idx_oob'.
//
// Until the sibling agent lands their edge fn, this file is a contract
// fixture only: a pure-helper test that exercises the lookup logic
// (`pickActionFromRow`) which the edge fn imports from
// _shared/parallel_actions.ts. The helper itself lives next to the
// deserialiser so both can share types.
//
// Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/_shared/__tests__/email_send_action_idx_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { deserialiseProposedActions } from "../parallel_actions.ts";

// =============================================================================
// Helper under test
//
// The sibling agent's email-send edge fn will call this helper to resolve the
// (triage_row, action_idx) → outgoing-email tuple. Defined inline here so the
// test runs without depending on the not-yet-created edge fn.
// =============================================================================

interface TriageRowSlice {
  draft_to: string[] | null;
  draft_cc: string[] | null;
  draft_subject: string | null;
  draft_body: string | null;
  draft_language: string | null;
  proposed_actions: unknown;
}

interface ResolvedSend {
  to_addr: string;
  cc: string[];
  subject: string;
  body: string;
  language: string;
}

/** Pure lookup — pick the (to, cc, subject, body, language) tuple the edge
 *  function should pass to Gmail / Resend based on action_idx. Mirrors the
 *  fallback rules documented at the top of this file. */
export function pickActionFromRow(
  row: TriageRowSlice,
  actionIdx: number,
): { ok: true; send: ResolvedSend } | { ok: false; error_code: string } {
  const legacy: ResolvedSend = {
    to_addr: (row.draft_to && row.draft_to[0]) ?? "",
    cc: row.draft_cc ?? [],
    subject: row.draft_subject ?? "",
    body: row.draft_body ?? "",
    language: row.draft_language ?? "en",
  };

  // action_idx 0 ⇒ legacy draft_* columns by spec (backwards compat).
  if (!Number.isFinite(actionIdx) || actionIdx === 0) {
    if (legacy.to_addr.length === 0 && legacy.body.length === 0) {
      return { ok: false, error_code: "no_legacy_draft" };
    }
    return { ok: true, send: legacy };
  }

  const actions = deserialiseProposedActions(row.proposed_actions);
  const match = actions.find((a) => a.idx === actionIdx);
  if (!match) return { ok: false, error_code: "action_idx_oob" };
  return {
    ok: true,
    send: {
      to_addr: match.to_addr,
      cc: match.cc,
      subject: match.subject,
      body: match.body,
      language: match.language,
    },
  };
}

// =============================================================================
// Fixtures
// =============================================================================

const SULGA_ROW: TriageRowSlice = {
  // Legacy draft columns mirror the consilium's primary recommendation
  // (action idx=0) for backwards compat.
  draft_to: ["jokela@migri.fi"],
  draft_cc: [],
  draft_subject: "Vastaus 12.5.2026 viestiin",
  draft_body: "Hyvä Jokela, ...",
  draft_language: "fi",
  // proposed_actions has BOTH parallel actions; idx=0 mirrors the legacy
  // columns and idx=1 is the new asiakirjapyyntö to poliisi.
  proposed_actions: [
    {
      idx: 0,
      kind: "email_reply",
      to_addr: "jokela@migri.fi",
      cc: [],
      subject: "Vastaus 12.5.2026 viestiin",
      body: "Hyvä Jokela, ...",
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
      body: "Pyydän julkisuuslain 14§:n nojalla ...",
      language: "fi",
      citations: ["[[ref:fi-julkl:14]]"],
      rationale: "2vk deadline.",
      gate_token: null,
    },
  ],
};

// =============================================================================
// Tests
// =============================================================================

Deno.test("action_idx omitted / 0 — uses legacy draft_* columns", () => {
  const r = pickActionFromRow(SULGA_ROW, 0);
  assert(r.ok);
  assertEquals(r.send.to_addr, "jokela@migri.fi");
  assertEquals(r.send.subject, "Vastaus 12.5.2026 viestiin");
  assertEquals(r.send.language, "fi");
});

Deno.test("action_idx=1 — uses proposed_actions[1] from the JSONB column", () => {
  const r = pickActionFromRow(SULGA_ROW, 1);
  assert(r.ok);
  assertEquals(r.send.to_addr, "kirjaamo.helsinki@poliisi.fi");
  assertEquals(r.send.subject, "Asiakirjapyyntö (JulkL 14§)");
  assertEquals(r.send.body.startsWith("Pyydän julkisuuslain"), true);
  assertEquals(r.send.language, "fi");
});

Deno.test("action_idx out of bounds — returns action_idx_oob", () => {
  const r = pickActionFromRow(SULGA_ROW, 99);
  assertEquals(r.ok, false);
  if (!r.ok) assertEquals(r.error_code, "action_idx_oob");
});

Deno.test(
  "legacy row with no draft + no actions — returns no_legacy_draft for idx=0",
  () => {
    const empty: TriageRowSlice = {
      draft_to: null,
      draft_cc: null,
      draft_subject: null,
      draft_body: null,
      draft_language: null,
      proposed_actions: null,
    };
    const r = pickActionFromRow(empty, 0);
    assertEquals(r.ok, false);
    if (!r.ok) assertEquals(r.error_code, "no_legacy_draft");
  },
);

Deno.test(
  "action_idx=0 on a multi-action row still uses legacy columns (back-compat)",
  () => {
    // Even when proposed_actions[0] would diverge from draft_*, the spec
    // says action_idx=0 wins the legacy path. This locks the contract so
    // the existing single-draft approveAndSend flow can never break.
    const r = pickActionFromRow(SULGA_ROW, 0);
    assert(r.ok);
    assertEquals(r.send.to_addr, "jokela@migri.fi");
  },
);
