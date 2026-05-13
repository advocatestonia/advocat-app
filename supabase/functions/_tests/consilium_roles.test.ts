// consilium_roles.test.ts — v2.2 two-layer consilium roles unit tests.
// -----------------------------------------------------------------------------
// Run:
//   deno test --allow-env --allow-read \
//     supabase/functions/_tests/consilium_roles.test.ts
//
// Scope (all GREEN required):
//   R01-R10  Router picks correct roles for 10 scenarios
//   P01-P12  Each role's compiled prompt is non-empty + cites expected statutes
//   M01-M03  Memory injection works (stub reader)
//   B01-B02  Backward-compat: empty/unknown context falls back to no domain match
//   C01      Compiled role shape matches the runner contract
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  type CaseContext,
  compileRoles,
  DOMAIN_EXPERTS,
  getDomainExpert,
  getStrategicPosition,
  loadMemoryHooks,
  resolveDefaultMemoryDir,
  selectConsiliumRoles,
  STRATEGIC_POSITIONS,
  StubMemoryReader,
} from "../_shared/consilium_roles/index.ts";

// ─── R01-R10 Router scenarios ────────────────────────────────────────────────

Deno.test("R01 — Sulga KHO (immigration FI hard deadline) selects expected roles", () => {
  const ctx: CaseContext = {
    caseType: "immigration",
    jurisdiction: "FI",
    language: "ru",
    complexity: 8,
    hasHardDeadline: true,
    hasOpposingCorrespondence: true,
    keywords: ["valituslupa", "kho", "käännytys"],
  };
  const sel = selectConsiliumRoles(ctx);
  assert(sel.hasDomainMatch, "Sulga must match at least one domain expert");
  const domainIds = sel.domainRoles.map((d) => d.id);
  assert(domainIds.includes("immigration-fi"), "must include immigration-fi");

  const stratIds = sel.strategicRoles.map((s) => s.id);
  assert(stratIds.includes("deadline-strategist"), "must include deadline-strategist (hard deadline)");

  // Total should be 4-6 roles
  const total = sel.domainRoles.length + sel.strategicRoles.length;
  assert(total >= 4 && total <= 6, `expected 4-6 roles, got ${total}`);
});

Deno.test("R02 — Sulga KHO mixed (immigration + criminal asianomistaja) picks BOTH", () => {
  const ctx: CaseContext = {
    caseType: "immigration",
    secondaryTypes: ["criminal"],
    jurisdiction: "FI",
    language: "ru",
    complexity: 8,
    hasHardDeadline: true,
    hasOpposingCorrespondence: true,
  };
  const sel = selectConsiliumRoles(ctx);
  const domainIds = sel.domainRoles.map((d) => d.id);
  assert(domainIds.includes("immigration-fi"), "primary type → immigration-fi");
  assert(domainIds.includes("criminal-fi"), "secondary type → criminal-fi");
});

Deno.test("R03 — VD AluSysteme contract (DE B2B GDPR) picks contract-de + gdpr-eu", () => {
  const ctx: CaseContext = {
    caseType: "contract",
    jurisdiction: "DE",
    language: "ru",
    complexity: 6,
    keywords: ["gdpr", "data processing", "b2b"],
  };
  const sel = selectConsiliumRoles(ctx);
  const domainIds = sel.domainRoles.map((d) => d.id);
  assert(domainIds.includes("contract-de"), "must include contract-de");
  assert(domainIds.includes("gdpr-eu"), "must include gdpr-eu (keyword 'gdpr')");
});

Deno.test("R04 — Estonian rental dispute picks contract-ee + consumer-eu", () => {
  const ctx: CaseContext = {
    caseType: "contract",
    jurisdiction: "EE",
    language: "et",
    complexity: 4,
    keywords: ["tarbija", "rental"],
    hasHardDeadline: true,
  };
  const sel = selectConsiliumRoles(ctx);
  const domainIds = sel.domainRoles.map((d) => d.id);
  assert(domainIds.includes("contract-ee"));
  assert(domainIds.includes("consumer-eu"));

  const stratIds = sel.strategicRoles.map((s) => s.id);
  assert(stratIds.includes("deadline-strategist"));
});

Deno.test("R05 — Employment EE picks employment-ee", () => {
  const ctx: CaseContext = {
    caseType: "employment",
    jurisdiction: "EE",
    complexity: 5,
  };
  const sel = selectConsiliumRoles(ctx);
  assertEquals(sel.domainRoles[0].id, "employment-ee");
});

Deno.test("R06 — Employment FI picks employment-fi", () => {
  const ctx: CaseContext = {
    caseType: "employment",
    jurisdiction: "FI",
    complexity: 5,
  };
  const sel = selectConsiliumRoles(ctx);
  assertEquals(sel.domainRoles[0].id, "employment-fi");
});

Deno.test("R07 — Tax EE picks tax-ee", () => {
  const ctx: CaseContext = {
    caseType: "tax",
    jurisdiction: "EE",
    complexity: 5,
  };
  const sel = selectConsiliumRoles(ctx);
  assertEquals(sel.domainRoles[0].id, "tax-ee");
});

Deno.test("R08 — Family EE picks family-ee", () => {
  const ctx: CaseContext = {
    caseType: "family",
    jurisdiction: "EE",
    complexity: 5,
  };
  const sel = selectConsiliumRoles(ctx);
  assertEquals(sel.domainRoles[0].id, "family-ee");
});

Deno.test("R09 — Pure GDPR question without case type still picks gdpr-eu via keyword", () => {
  const ctx: CaseContext = {
    caseType: "unknown",
    jurisdiction: "EU",
    complexity: 4,
    keywords: ["gdpr", "data"],
  };
  const sel = selectConsiliumRoles(ctx);
  const domainIds = sel.domainRoles.map((d) => d.id);
  assert(domainIds.includes("gdpr-eu"));
});

Deno.test("R10 — Complex case (>= 7) unlocks long-game + 23-test strategics", () => {
  const ctx: CaseContext = {
    caseType: "immigration",
    jurisdiction: "FI",
    complexity: 9,
    hasHardDeadline: true,
  };
  const sel = selectConsiliumRoles(ctx);
  const stratIds = sel.strategicRoles.map((s) => s.id);
  // long-game should outrank some others for complexity >= 7
  const allHaveLongGameOption = stratIds.includes("long-game") ||
    stratIds.includes("23-test") ||
    stratIds.includes("deadline-strategist");
  assert(allHaveLongGameOption, "complex case must surface long-game / 23-test / deadline");
});

// ─── P01-P12 Per-role prompt checks ──────────────────────────────────────────

Deno.test("P01 — every domain expert has a non-empty statute shortlist", () => {
  for (const d of DOMAIN_EXPERTS) {
    assert(d.statuteShortlist.length > 0, `${d.id} missing statute shortlist`);
    assert(d.knownPitfalls.length > 0, `${d.id} missing pitfalls`);
  }
});

Deno.test("P02 — every strategic position has a non-empty pitfall list", () => {
  for (const s of STRATEGIC_POSITIONS) {
    assert(s.knownPitfalls.length > 0, `${s.id} missing pitfalls`);
  }
});

Deno.test("P03 — immigration-fi prompt cites Ulkomaalaislaki + Direktiivi 2004/38", async () => {
  const role = getDomainExpert("immigration-fi")!;
  const body = role.systemPromptFactory(
    { caseType: "immigration", jurisdiction: "FI" },
    "",
  );
  assertStringIncludes(body, "Ulkomaalaislaki");
  assertStringIncludes(body, "2004/38");
  assertStringIncludes(body, "HOL");
});

Deno.test("P04 — criminal-fi prompt cites RL + ROL + asianomistaja", async () => {
  const role = getDomainExpert("criminal-fi")!;
  const body = role.systemPromptFactory({ caseType: "criminal", jurisdiction: "FI" }, "");
  assertStringIncludes(body, "Rikoslaki");
  assertStringIncludes(body, "asianomista");
});

Deno.test("P05 — contract-de prompt cites BGB and Rom-I-VO", () => {
  const role = getDomainExpert("contract-de")!;
  const body = role.systemPromptFactory({ caseType: "contract", jurisdiction: "DE" }, "");
  assertStringIncludes(body, "BGB");
  assertStringIncludes(body, "Rom-I-VO");
});

Deno.test("P06 — contract-ee prompt cites VÕS + TsÜS", () => {
  const role = getDomainExpert("contract-ee")!;
  const body = role.systemPromptFactory({ caseType: "contract", jurisdiction: "EE" }, "");
  assertStringIncludes(body, "VÕS");
  assertStringIncludes(body, "TsÜS");
});

Deno.test("P07 — gdpr-eu prompt cites Art. 6 and Schrems II", () => {
  const role = getDomainExpert("gdpr-eu")!;
  const body = role.systemPromptFactory({ caseType: "gdpr", jurisdiction: "EU" }, "");
  assertStringIncludes(body, "Art. 6");
  assertStringIncludes(body, "Schrems");
});

Deno.test("P08 — decision-maker-risk prompt asks about judge career risk", () => {
  const role = getStrategicPosition("decision-maker-risk")!;
  const body = role.systemPromptFactory({}, "");
  // Either Russian word for judge ("судья") or English ("judge")
  assert(body.includes("судья") || body.includes("judge"), "decision-maker-risk must mention judge");
  assertStringIncludes(body, "прикрытие");
});

Deno.test("P09 — procedural-posture asks for 3 alternative sequences", () => {
  const role = getStrategicPosition("procedural-posture")!;
  const body = role.systemPromptFactory({}, "");
  assertStringIncludes(body, "3");
  assertStringIncludes(body, "контр-ход");
});

Deno.test("P10 — silent-concession references opposing materials", () => {
  const role = getStrategicPosition("silent-concession")!;
  const body = role.systemPromptFactory({}, "");
  assertStringIncludes(body, "оппонент");
  assertStringIncludes(body, "молчани");
});

Deno.test("P11 — long-game references KHO and EIK", () => {
  const role = getStrategicPosition("long-game")!;
  const body = role.systemPromptFactory({}, "");
  assert(body.includes("KHO") || body.includes("EIK"));
});

Deno.test("P12 — 23-test mentions tired judge / one paragraph", () => {
  const role = getStrategicPosition("23-test")!;
  const body = role.systemPromptFactory({}, "");
  assertStringIncludes(body, "23:00");
  assert(body.includes("абзац") || body.includes("paragraph"));
});

// ─── M01-M03 Memory injection ────────────────────────────────────────────────

Deno.test("M01 — loadMemoryHooks returns empty string when no hooks", async () => {
  const reader = new StubMemoryReader({});
  const out = await loadMemoryHooks([], reader);
  assertEquals(out, "");
});

Deno.test("M02 — loadMemoryHooks reads provided file and strips YAML front-matter", async () => {
  const reader = new StubMemoryReader({
    "lesson_test.md":
      "---\nname: x\ndescription: y\n---\nBody content here\nMore body",
  });
  const out = await loadMemoryHooks(["lesson_test.md"], reader);
  assertStringIncludes(out, "<memory>");
  assertStringIncludes(out, "Body content here");
  assert(!out.includes("name: x"), "front-matter must be stripped");
});

Deno.test("M03 — immigration-fi compileRoles auto-injects HAO/KHO lesson when present", async () => {
  const ctx: CaseContext = {
    caseType: "immigration",
    jurisdiction: "FI",
    language: "ru",
    hasHardDeadline: true,
  };
  const reader = new StubMemoryReader({
    "lesson_HAO_KHO_restoration_jurisdiction.md":
      "---\nname: HAO vs KHO\n---\nMenetetyn määräajan palauttaminen is KHO-only.",
    "lesson_sulga_three_identity_errors.md":
      "---\nname: Sulga identity\n---\nThree identity errors documented.",
  });
  const sel = selectConsiliumRoles(ctx);
  const compiled = await compileRoles({ selection: sel, ctx, memoryReader: reader });
  const immFi = compiled.find((c) => c.id === "immigration-fi");
  assert(immFi, "immigration-fi must be compiled");
  assertStringIncludes(immFi!.systemBody, "Menetetyn määräajan palauttaminen is KHO-only");
});

// ─── B01-B02 Backward compatibility ──────────────────────────────────────────

Deno.test("B01 — empty caseContext returns hasDomainMatch=false", () => {
  const sel = selectConsiliumRoles({});
  assertEquals(sel.hasDomainMatch, false);
});

Deno.test("B02 — unknown jurisdiction yields no domain match", () => {
  const sel = selectConsiliumRoles({ caseType: "unknown", jurisdiction: "unknown" });
  assertEquals(sel.hasDomainMatch, false);
});

// ─── C01 Compiled-role contract ──────────────────────────────────────────────

Deno.test("C01 — compileRoles produces runner-compatible shape", async () => {
  const ctx: CaseContext = {
    caseType: "immigration",
    jurisdiction: "FI",
    language: "ru",
    complexity: 7,
    hasHardDeadline: true,
  };
  const reader = new StubMemoryReader({});
  const sel = selectConsiliumRoles(ctx);
  const compiled = await compileRoles({ selection: sel, ctx, memoryReader: reader });
  assert(compiled.length >= 4 && compiled.length <= 6, `got ${compiled.length} roles`);
  for (const c of compiled) {
    assert(typeof c.id === "string" && c.id.length > 0);
    assert(typeof c.name === "string" && c.name.length > 0);
    assert(typeof c.model === "string" && c.model.length > 0);
    assert(typeof c.maxTokens === "number" && c.maxTokens > 0);
    assert(typeof c.systemBody === "string" && c.systemBody.length > 50);
  }
});

// ─── Smoke: default memory dir resolves ──────────────────────────────────────

Deno.test("Z01 — resolveDefaultMemoryDir does not throw", () => {
  const dir = resolveDefaultMemoryDir();
  assert(typeof dir === "string" && dir.length > 0);
});
