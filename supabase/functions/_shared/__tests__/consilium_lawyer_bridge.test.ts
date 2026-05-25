// consilium_lawyer_bridge.test.ts — Deno TDD for the lawyer-router → consilium
// bridge introduced in Phase 1 (2026-05-25).
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-env \
//     supabase/functions/_shared/__tests__/consilium_lawyer_bridge.test.ts
//
// Coverage:
//   • 5 representative queries each produce a 3-5 ConsiliumRole roster
//   • Output is a valid ConsiliumRole[] (all required fields present, models
//     resolved to Anthropic ids, focus is non-empty)
//   • Bridge gracefully returns null for empty input
//   • selectRolesFromLawyerDeptSimple is a thin wrapper
//   • isLawyerRouterEnabled honours env (true / 1 / yes; everything else off)
//   • Round-1 opinion heuristic helpers behave deterministically
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  buildRoleOpinionPayload,
  classifyRolePosition,
  type ConsiliumRole,
  extractConfidenceHint,
  findKeyCitation,
  summariseOpinion,
} from "../consilium.ts";
import {
  isLawyerRouterEnabled,
  LAWYER_ROUTER_FLAG_ENV,
  selectRolesFromLawyerDept,
  selectRolesFromLawyerDeptSimple,
} from "../consilium_lawyer_bridge.ts";
import type { CaseContext } from "../consilium_roles/types.ts";

// ─── Roster size — 5 representative queries ──────────────────────────────────

interface Scenario {
  label: string;
  query: string;
  classification: CaseContext;
  /** Stable ids we expect to see somewhere in the selected roster. */
  expectedIds: string[];
}

const SCENARIOS: Scenario[] = [
  {
    label: "FI immigration — Sulga-like deport challenge",
    query:
      "Minulta on käännyttämispäätös Suomesta. KHO 5.6.2026 valituslupahakemus, hain menetetyn määräajan palauttamista. Mitä teen?",
    classification: {
      caseType: "immigration",
      jurisdiction: "FI",
      language: "fi",
      complexity: 8,
      hasHardDeadline: true,
    },
    expectedIds: ["senior-asianajaja", "immigration-lawyer", "strategist"],
  },
  {
    label: "EE corporate — contract dispute",
    query:
      "Meil on Eesti OÜ-l vaidlus tarnijaga töövõtulepingu rikkumise üle. Ähvardab kohtuhagi. Mida soovitate?",
    classification: {
      caseType: "contract",
      jurisdiction: "EE",
      language: "et",
      complexity: 5,
    },
    expectedIds: ["senior-vandeadvokaat", "corporate-lawyer", "strategist"],
  },
  {
    label: "Mixed FI+EE — cross-border employment",
    query:
      "Я работаю в финской компании из Эстонии remote, договор по финскому праву, but болезнь, неплачу налоги. Что делать?",
    classification: {
      caseType: "employment",
      jurisdiction: "mixed",
      language: "ru",
      complexity: 7,
      hasHardDeadline: false,
    },
    expectedIds: ["labor-lawyer", "strategist"],
  },
  {
    label: "ECHR — exhausted-remedies application",
    query:
      "I exhausted KHO appeal route in Finland; planning an ECHR application under Art 3 + 8. What is the deadline and what evidence matters?",
    classification: {
      caseType: "immigration",
      jurisdiction: "FI",
      language: "en",
      complexity: 9,
      hasHardDeadline: true,
    },
    expectedIds: ["immigration-lawyer", "strategist", "researcher", "litigator"],
  },
  {
    label: "Simple Q&A — what does asianomistaja mean",
    query: "Mida tähendab asianomistaja Soome kriminaalmenetluses?",
    classification: {
      caseType: "criminal",
      jurisdiction: "FI",
      language: "et",
      complexity: 2,
    },
    expectedIds: ["senior-asianajaja", "strategist"],
  },
];

Deno.test("selectRolesFromLawyerDept — every scenario returns 3-5 roles", () => {
  for (const s of SCENARIOS) {
    const result = selectRolesFromLawyerDept(s.query, s.classification);
    assertExists(result, `${s.label}: expected a non-null bridge result`);
    assert(
      result.roles.length >= 3 && result.roles.length <= 5,
      `${s.label}: roster size ${result.roles.length} out of bounds`,
    );
    // Spot-check expected ids are present in the agent list (not necessarily
    // in the role list — role.name is the display, agent.id is the stable id).
    // We only require ≥1 of the expected ids fires; routing is heuristic
    // so we don't want brittle exact matches.
    const agentIds = new Set(result.agents.map((a) => a.id));
    // Soft assertion: at least one expected id must appear.
    const anyHit = s.expectedIds.some((id) => agentIds.has(id));
    assert(
      anyHit,
      `${s.label}: none of ${s.expectedIds.join(",")} in selected ${
        [...agentIds].join(",")
      }`,
    );
  }
});

Deno.test("selectRolesFromLawyerDept — output is valid ConsiliumRole[]", () => {
  for (const s of SCENARIOS) {
    const result = selectRolesFromLawyerDept(s.query, s.classification);
    assertExists(result);
    for (const role of result.roles) {
      assertConsiliumRole(role, s.label);
    }
    // overrideRoleIds parity check — count matches roles count.
    assertEquals(
      result.agents.length,
      result.roles.length,
      `${s.label}: agents and roles must be 1:1`,
    );
  }
});

function assertConsiliumRole(role: ConsiliumRole, ctx: string): void {
  assert(typeof role.name === "string" && role.name.length > 0, `${ctx}: name`);
  assert(typeof role.model === "string" && role.model.length > 0, `${ctx}: model`);
  // model id must be one of the three Anthropic-resolved ids
  const validModels = [
    "claude-sonnet-4-6",
    "claude-haiku-4-5-20251001",
    "claude-opus-4-1-20250805",
  ];
  assert(
    validModels.includes(role.model),
    `${ctx}: model "${role.model}" not in allowed list`,
  );
  assert(
    typeof role.maxTokens === "number" && role.maxTokens > 0,
    `${ctx}: maxTokens`,
  );
  assert(typeof role.focus === "string" && role.focus.length > 200, `${ctx}: focus body too short`);
  assertEquals(role.isCompiled, true, `${ctx}: isCompiled must be true`);
}

// ─── Bridge safety ───────────────────────────────────────────────────────────

Deno.test("selectRolesFromLawyerDept — returns null for empty query", () => {
  assertEquals(selectRolesFromLawyerDept(""), null);
  assertEquals(selectRolesFromLawyerDept("   "), null);
});

Deno.test("selectRolesFromLawyerDept — handles missing classification", () => {
  // Pure keyword-only routing should still work.
  const result = selectRolesFromLawyerDept(
    "ulkomaalaislaki ja käännyttäminen",
  );
  assertExists(result);
  assert(result.roles.length >= 3);
});

Deno.test("selectRolesFromLawyerDeptSimple — returns only ConsiliumRole[]", () => {
  const roles = selectRolesFromLawyerDeptSimple("KHO valituslupa", {
    jurisdiction: "FI",
    language: "fi",
  });
  assertExists(roles);
  assert(Array.isArray(roles));
  assert(roles.length >= 3 && roles.length <= 5);
  for (const r of roles) assertConsiliumRole(r, "simple");
});

// ─── Env flag ────────────────────────────────────────────────────────────────

Deno.test("isLawyerRouterEnabled — default OFF", () => {
  Deno.env.delete(LAWYER_ROUTER_FLAG_ENV);
  assertEquals(isLawyerRouterEnabled(), false);
});

Deno.test("isLawyerRouterEnabled — accepts true / 1 / yes", () => {
  for (const v of ["true", "TRUE", "1", "yes", " True "]) {
    Deno.env.set(LAWYER_ROUTER_FLAG_ENV, v);
    assertEquals(isLawyerRouterEnabled(), true, `value=${JSON.stringify(v)}`);
  }
  // Anything else is OFF.
  for (const v of ["false", "0", "no", "off", "maybe"]) {
    Deno.env.set(LAWYER_ROUTER_FLAG_ENV, v);
    assertEquals(isLawyerRouterEnabled(), false, `value=${JSON.stringify(v)}`);
  }
  Deno.env.delete(LAWYER_ROUTER_FLAG_ENV);
});

// ─── Round-1 opinion heuristic helpers ───────────────────────────────────────

Deno.test("summariseOpinion — cuts to 1-2 sentences", () => {
  const txt =
    "Это первое предложение. Это второе предложение. И ещё третье, которое не должно попасть.";
  const out = summariseOpinion(txt);
  assert(out.length < txt.length);
  assert(out.includes("первое"));
});

Deno.test("summariseOpinion — hard-truncates with ellipsis", () => {
  const huge = "А".repeat(2000);
  const out = summariseOpinion(huge, 200);
  assert(out.endsWith("…") || out.length <= 200);
});

Deno.test("classifyRolePosition — settle / push / investigate / out_of_scope", () => {
  assertEquals(
    classifyRolePosition("Нужно сдаться и пойти на мировое соглашение."),
    "settle",
  );
  assertEquals(
    classifyRolePosition("Подать valitus в KHO в течение 30 дней."),
    "push",
  );
  assertEquals(
    classifyRolePosition("Недостаточно фактов — нужно запросить больше доказательств."),
    "investigate",
  );
  assertEquals(
    classifyRolePosition("[роль недоступна]"),
    "out_of_scope",
  );
});

Deno.test("extractConfidenceHint — parses ranges and singles", () => {
  assertEquals(extractConfidenceHint("Реалистичный шанс: 20-30%"), 0.25);
  assertEquals(extractConfidenceHint("Около 15 %"), 0.15);
  assertEquals(extractConfidenceHint("Без процентов вообще"), null);
});

Deno.test("findKeyCitation — extracts first [[ref:slug:para]] marker", () => {
  assertEquals(
    findKeyCitation("По норме [[ref:fi-ulkomaalaislaki:147]] процедура такая."),
    "[[ref:fi-ulkomaalaislaki:147]]",
  );
  assertEquals(findKeyCitation("Без цитат"), null);
});

Deno.test("buildRoleOpinionPayload — populates all fields", () => {
  const payload = buildRoleOpinionPayload(
    { id: "immigration-lawyer", name: "Иммиграционный адвокат" },
    "Подать valitus. Шанс 25-35%. См. [[ref:fi-hol:114]].",
  );
  assertEquals(payload.role_id, "immigration-lawyer");
  assertEquals(payload.role, "Иммиграционный адвокат");
  assertEquals(payload.position, "push");
  assertEquals(payload.confidence, 0.3);
  assertEquals(payload.key_citation, "[[ref:fi-hol:114]]");
  assert(payload.opinion.length > 0);
});

Deno.test("buildRoleOpinionPayload — handles unavailable role sentinel", () => {
  const payload = buildRoleOpinionPayload(
    { name: "Some Role" },
    "[роль недоступна]",
  );
  assertEquals(payload.role_id, "Some Role");
  assertEquals(payload.position, "out_of_scope");
  assertEquals(payload.confidence, null);
  assertEquals(payload.key_citation, null);
});
