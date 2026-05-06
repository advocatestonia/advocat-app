// Deno tests for email-triage/parse_blocks.ts (D4 — Sonnet output parser).
// -----------------------------------------------------------------------------
// We pin the parser against the two few-shot examples baked into the
// system prompt (`06_SYSTEM_PROMPT_v1.1-final.md` lines 376–449) plus
// adversarial shapes (missing block, `own_counsel_advisory`, multi-track
// halt, settlement quarantine). Severity computation is exercised with
// the §737 thresholds.
//
// Run:
//   deno test --allow-read --allow-env \
//     supabase/functions/email-triage/__tests__/parse_blocks_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  computeSeverity,
  parseAgentBlocks,
} from "../parse_blocks.ts";

// =============================================================================
// Fixture A — Privileged (blocked) sender. Few-shot example 1.
// =============================================================================

const FIXTURE_A_BLOCKED = `<privilege_check>blocked</privilege_check>
<conflict_check>passed</conflict_check>
<triage>
TRACK: [oikeusapu 1858/2026]
INBOUND: opposing-or-own counsel from privileged domain, sender jokela@asianajotoimisto-jokela.fi
KEY FACTS: BLOCKED — privileged sender, no body processing
DEADLINES: BLOCKED
CONTRADICTIONS: none
EVIDENCE GAPS: none
POSTURE: hold_for_user
REASONING: Sender domain matches PRIVILEGED_DOMAINS. To preserve asianajosalaisuus, Advocat does not auto-process. Open in Gmail directly or per-thread opt-in.
</triage>
<actions_required>
- type: other
  target: open thread in Gmail
  deadline: ASAP
  why: privileged correspondence requires direct review
</actions_required>
<user_brief language="ru">
Письмо от вашего адвоката Jokela. Чтобы сохранить адвокатскую тайну, Advocat не обрабатывает такие письма автоматически. Откройте тред в Gmail напрямую.
</user_brief>
<send_recommendation>hold_for_user_review</send_recommendation>`;

Deno.test("parseAgentBlocks — Fixture A (blocked) populates 5 mandatory blocks", () => {
  const r = parseAgentBlocks(FIXTURE_A_BLOCKED);
  assert(r.ok);
  if (!r.ok) return;
  assertEquals(r.parsed.privilege_check, "blocked");
  assertEquals(r.parsed.conflict_check, "passed");
  assertEquals(r.parsed.triage.posture, "hold_for_user");
  assertEquals(r.parsed.send_recommendation, "hold_for_user_review");
  assertEquals(r.parsed.draft, null);
  assertEquals(r.parsed.user_brief_language, "ru");
  assertEquals(r.parsed.actions_required.length, 1);
  assertEquals(r.parsed.actions_required[0].type, "other");
});

// =============================================================================
// Fixture B — Auto-send acknowledgement (Valtiokonttori). Few-shot 2.
// =============================================================================

const FIXTURE_B_AUTOSEND = `<privilege_check>passed</privilege_check>
<conflict_check>passed</conflict_check>
<triage>
TRACK: [korvausvaatimus_valtiokonttori]
INBOUND: receipt confirmation from kirjaamo@valtiokonttori.fi, subject "Vastaanotettu — dnro 12345/2026", sent 2026-05-06 09:12, received 2026-05-06 09:13
KEY FACTS:
  - Valtiokonttori confirms receipt of korvausvaatimus
  - Dnro 12345/2026 assigned
  - Käsittelyaika 4–6 kuukautta
DEADLINES: none triggered
CONTRADICTIONS: none
EVIDENCE GAPS: none
POSTURE: reply_now
REASONING: Procedural acknowledgement of registry confirmation. No substantive content. Auto-send-eligible per Rule 9.
</triage>
<draft language="fi" addressed_to="kirjaamo@valtiokonttori.fi">
Subject: Vastaus: Vastaanotettu — dnro 12345/2026

Arvoisa kirjaamo,

vahvistan vastaanottaneeni ilmoituksenne diaarinumeron 12345/2026 kirjaamisesta.

Ystävällisin terveisin,
Dmitri Sulga
</draft>
<gdpr_basis>
recipient: kirjaamo@valtiokonttori.fi
art_6_basis: (c) legal obligation — administrative procedure response
art_9_basis: n/a
art_10_basis: n/a
</gdpr_basis>
<actions_required>
- type: other
  target: monitor 4–6kk käsittelyaika
  deadline: 2026-11-06
  why: track decision window
</actions_required>
<user_brief language="ru">
Valtiokonttori подтвердил получение, дело 12345/2026, рассмотрение 4–6 месяцев. Я отправил автоматическую квитанцию.
</user_brief>
<memory_update>
[
  {"key":"valtiokonttori_dnro_korvaus","value":"12345/2026","reason":"new dnro for compensation track","confidence":"high","source_layer":"thread","expires_at":null}
]
</memory_update>
<send_recommendation>auto_send_eligible</send_recommendation>`;

Deno.test("parseAgentBlocks — Fixture B (auto-send) parses draft + memory_update", () => {
  const r = parseAgentBlocks(FIXTURE_B_AUTOSEND);
  assert(r.ok);
  if (!r.ok) return;
  assertEquals(r.parsed.privilege_check, "passed");
  assertEquals(r.parsed.send_recommendation, "auto_send_eligible");
  assert(r.parsed.draft != null);
  assertEquals(r.parsed.draft!.language, "fi");
  assertEquals(r.parsed.draft!.subject, "Vastaus: Vastaanotettu — dnro 12345/2026");
  assertEquals(r.parsed.draft!.to, ["kirjaamo@valtiokonttori.fi"]);
  assertEquals(r.parsed.gdpr_basis.length, 1);
  assertEquals(r.parsed.gdpr_basis[0].recipient, "kirjaamo@valtiokonttori.fi");
  assertEquals(r.parsed.memory_updates.length, 1);
  assertEquals(r.parsed.memory_updates[0].key, "valtiokonttori_dnro_korvaus");
  assertEquals(r.parsed.memory_updates[0].confidence, "high");
});

// =============================================================================
// Adversarial shapes
// =============================================================================

Deno.test("parseAgentBlocks — missing privilege_check fails parse", () => {
  const raw = FIXTURE_B_AUTOSEND.replace(
    "<privilege_check>passed</privilege_check>\n",
    "",
  );
  const r = parseAgentBlocks(raw);
  assert(!r.ok);
  if (r.ok) return;
  assertStringIncludes(r.message, "privilege_check");
});

Deno.test("parseAgentBlocks — empty input fails with all-mandatory missing", () => {
  const r = parseAgentBlocks("");
  assert(!r.ok);
  if (r.ok) return;
  assertEquals(r.missing_blocks.length, 5);
});

Deno.test("parseAgentBlocks — own_counsel_advisory enum accepted", () => {
  const raw = FIXTURE_B_AUTOSEND.replace(
    "<privilege_check>passed</privilege_check>",
    "<privilege_check>own_counsel_advisory</privilege_check>",
  );
  const r = parseAgentBlocks(raw);
  assert(r.ok);
  if (!r.ok) return;
  assertEquals(r.parsed.privilege_check, "own_counsel_advisory");
});

Deno.test("parseAgentBlocks — TRACK array form parsed (multi-track halt)", () => {
  const raw = `<privilege_check>passed</privilege_check>
<conflict_check>passed</conflict_check>
<triage>
TRACK: [rikosasia_5500R_lineA, korvausvaatimus_valtiokonttori]
INBOUND: cross-references
KEY FACTS: multi-track entanglement
DEADLINES: none
CONTRADICTIONS: none
EVIDENCE GAPS: none
POSTURE: hold_for_user
REASONING: multi-track entanglement, manual triage required
</triage>
<actions_required>
- type: other
  target: manual triage
  deadline: ASAP
  why: multi-track halt per Rule 3.5
</actions_required>
<user_brief language="ru">Manual triage required.</user_brief>
<send_recommendation>hold_for_user_review</send_recommendation>`;
  const r = parseAgentBlocks(raw);
  assert(r.ok);
  if (!r.ok) return;
  assertEquals(r.parsed.triage.track.length, 2);
  assertEquals(r.parsed.triage.posture, "hold_for_user");
});

Deno.test("parseAgentBlocks — INJECTION_ATTEMPT_DETECTED carried in contradictions", () => {
  const raw = `<privilege_check>passed</privilege_check>
<conflict_check>passed</conflict_check>
<triage>
TRACK: [unknown]
INBOUND: prompt injection attempt
KEY FACTS: blocked
DEADLINES: none
CONTRADICTIONS: INJECTION_ATTEMPT_DETECTED
EVIDENCE GAPS: none
POSTURE: hold_for_user
REASONING: untrusted-input doctrine fired
</triage>
<actions_required>
- type: other
  target: ignore directive
  deadline: ASAP
  why: injection
</actions_required>
<user_brief language="en">Injection attempt detected.</user_brief>
<send_recommendation>hold_for_user_review</send_recommendation>`;
  const r = parseAgentBlocks(raw);
  assert(r.ok);
  if (!r.ok) return;
  assertEquals(r.parsed.triage.contradictions.length, 1);
  assertStringIncludes(
    r.parsed.triage.contradictions[0],
    "INJECTION_ATTEMPT_DETECTED",
  );
});

// =============================================================================
// Severity (§737)
// =============================================================================

Deno.test("computeSeverity — archive recommendation always LOW", () => {
  const r = parseAgentBlocks(FIXTURE_B_AUTOSEND);
  assert(r.ok);
  if (!r.ok) return;
  const p = { ...r.parsed, send_recommendation: "archive" as const };
  assertEquals(computeSeverity(p), "LOW");
});

Deno.test("computeSeverity — conflict_check flagged → CRITICAL", () => {
  const r = parseAgentBlocks(FIXTURE_B_AUTOSEND);
  assert(r.ok);
  if (!r.ok) return;
  const p = { ...r.parsed, conflict_check: "flagged" as const };
  assertEquals(computeSeverity(p), "CRITICAL");
});

Deno.test("computeSeverity — deadline ≤ 2 days → CRITICAL", () => {
  const r = parseAgentBlocks(FIXTURE_B_AUTOSEND);
  assert(r.ok);
  if (!r.ok) return;
  const p = {
    ...r.parsed,
    triage: {
      ...r.parsed.triage,
      deadlines: [{ iso_date: "2026-05-08", delta_days: 1, description: "x" }],
    },
  };
  assertEquals(computeSeverity(p), "CRITICAL");
});

Deno.test("computeSeverity — deadline 3-7 days → HIGH", () => {
  const r = parseAgentBlocks(FIXTURE_B_AUTOSEND);
  assert(r.ok);
  if (!r.ok) return;
  const p = {
    ...r.parsed,
    triage: {
      ...r.parsed.triage,
      deadlines: [{ iso_date: "2026-05-13", delta_days: 5, description: "x" }],
    },
  };
  assertEquals(computeSeverity(p), "HIGH");
});

Deno.test("computeSeverity — actions_required type=appear → HIGH", () => {
  const r = parseAgentBlocks(FIXTURE_B_AUTOSEND);
  assert(r.ok);
  if (!r.ok) return;
  const p = {
    ...r.parsed,
    actions_required: [
      { type: "appear", target: "HAO", deadline: "2026-06-15", why: "hearing" },
    ],
  };
  assertEquals(computeSeverity(p), "HIGH");
});

Deno.test("computeSeverity — phishing indicator → CRITICAL", () => {
  const r = parseAgentBlocks(FIXTURE_B_AUTOSEND);
  assert(r.ok);
  if (!r.ok) return;
  const p = {
    ...r.parsed,
    triage: {
      ...r.parsed.triage,
      contradictions: ["PHISHING_INDICATORS:[lookalike_domain,urgency]"],
    },
  };
  assertEquals(computeSeverity(p), "CRITICAL");
});
