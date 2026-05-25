// Deno TDD — lawyer_router + lawyer_agents department.
// -----------------------------------------------------------------------------
// Pure-module contract tests. No network — the keyword router is fully
// deterministic, and the Haiku refinement seam is exercised with an injected
// stub caller.
//
// Run with:
//   deno test --allow-net=api.anthropic.com --allow-env \
//     supabase/functions/_shared/__tests__/lawyer_router_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  ALL_LAWYERS,
  buildLawyerCtx,
  extractKeywords,
  getLawyerById,
  type LawyerAgent,
  resolveModelId,
} from "../lawyer_agents/index.ts";
import {
  COMPLEXITY_THRESHOLD,
  type HaikuCaller,
  MAX_LAWYERS,
  MIN_LAWYERS,
  refineWithHaiku,
  routeToLawyers,
} from "../lawyer_router.ts";

// ─── ALL_LAWYERS sanity ──────────────────────────────────────────────────────

Deno.test("ALL_LAWYERS contains exactly 15 distinct agents (Wave F)", () => {
  assertEquals(ALL_LAWYERS.length, 15);
  const ids = new Set(ALL_LAWYERS.map((a) => a.id));
  assertEquals(ids.size, 15, "all agent ids must be unique");
  // Wave F specialists must be present.
  for (
    const id of [
      "ecthr-specialist",
      "client-psychology",
      "forensic-evidence",
      "native-writer",
    ]
  ) {
    assert(ids.has(id), `missing Wave F specialist: ${id}`);
  }
});

Deno.test("every agent prompt is non-empty and >= 400 chars", () => {
  for (const a of ALL_LAWYERS) {
    const prompt = a.systemPrompt("Test query in EE", {
      jurisdiction: "EE",
      language: "ru",
    });
    assert(prompt.length > 400, `${a.id} prompt is too short: ${prompt.length} chars`);
    assertStringIncludes(prompt, "##", `${a.id} prompt missing structure headers`);
  }
});

Deno.test("every agent has at least 4 trigger keywords + 1 expertise tag", () => {
  for (const a of ALL_LAWYERS) {
    assert(
      a.triggerKeywords.length >= 4,
      `${a.id} has only ${a.triggerKeywords.length} keywords`,
    );
    assert(
      a.expertise.length >= 1,
      `${a.id} has no expertise tags`,
    );
  }
});

Deno.test("resolveModelId maps each LawyerModel correctly", () => {
  assertEquals(resolveModelId("sonnet"), "claude-sonnet-4-6");
  assertEquals(resolveModelId("haiku"), "claude-haiku-4-5-20251001");
  assertEquals(resolveModelId("opus"), "claude-opus-4-1-20250805");
});

Deno.test("getLawyerById finds and returns null on miss", () => {
  assert(getLawyerById("immigration-lawyer") !== null);
  assertEquals(getLawyerById("not-a-real-id"), null);
});

// ─── extractKeywords / buildLawyerCtx ────────────────────────────────────────

Deno.test("extractKeywords keeps ≥3-char tokens and dedupes", () => {
  const kws = extractKeywords("Меня хотят депортировать из Финляндии. KHO 5.6.");
  assert(kws.includes("депортировать"));
  assert(kws.includes("финляндии") || kws.includes("kho"));
  // dedupe
  const seen = new Set(kws);
  assertEquals(seen.size, kws.length);
});

Deno.test("buildLawyerCtx fills keywords when missing", () => {
  const ctx = buildLawyerCtx("oleskelulupa hakemus KHO valituslupa", "fi");
  assert((ctx.keywords?.length ?? 0) > 0);
  assertEquals(ctx.language, "fi");
});

// ─── routeToLawyers — 10 sample queries ──────────────────────────────────────

interface RouterCase {
  name: string;
  query: string;
  lang: "ru" | "et" | "fi" | "en";
  ctx?: { jurisdiction?: "FI" | "EE" | "EU" | "mixed"; complexity?: number; hasHardDeadline?: boolean; caseType?: "immigration" | "tax" | "family" | "employment" | "contract" | "criminal" | "gdpr" };
  mustIncludeId: string[];
  mustExcludeId?: string[];
  expectHighStakes?: boolean;
}

const CASES: RouterCase[] = [
  {
    name: "FI immigration / deportation (Sulga-shape)",
    query: "Меня хотят депортировать из Финляндии, могу ли я остаться по работе?",
    lang: "ru",
    ctx: { jurisdiction: "FI", complexity: 8, hasHardDeadline: true },
    mustIncludeId: [
      "senior-asianajaja",
      "immigration-lawyer",
      "strategist",
    ],
    expectHighStakes: true,
  },
  {
    name: "EE tax dispute with EMTA",
    query: "EMTA otsus dividendi tulumaksu kohta, vaie esitamise tähtaeg.",
    lang: "et",
    ctx: { jurisdiction: "EE", caseType: "tax" },
    mustIncludeId: ["senior-vandeadvokaat", "tax-advisor", "strategist"],
  },
  {
    name: "FI divorce + child custody, cross-border",
    query: "Avioero ja lapsen huoltajuus — perheel toinen vanhempi muutti Viroon. Brussels IIb?",
    lang: "fi",
    ctx: { jurisdiction: "mixed", caseType: "family", complexity: 7 },
    mustIncludeId: ["family-lawyer", "strategist"],
    expectHighStakes: true,
  },
  {
    name: "EE corporate / shareholder dispute",
    query: "OÜ osanike vahel vaidlus, põhikiri ütleb …",
    lang: "et",
    ctx: { jurisdiction: "EE", caseType: "contract" },
    mustIncludeId: ["senior-vandeadvokaat", "corporate-lawyer", "strategist"],
  },
  {
    name: "FI termination of employment + YTL neuvottelut",
    query: "Sain irtisanomisilmoituksen, työnantajalla 80 työntekijää, oliko yhteistoiminta tehty?",
    lang: "fi",
    ctx: { jurisdiction: "FI", caseType: "employment" },
    mustIncludeId: ["senior-asianajaja", "labor-lawyer", "strategist"],
  },
  {
    name: "EE criminal — asianomistaja in assault case",
    query: "Olen kannataja kallaletungi juhtumis politseis. KrMS § 38?",
    lang: "et",
    ctx: { jurisdiction: "EE", caseType: "criminal", complexity: 6 },
    mustIncludeId: ["senior-vandeadvokaat", "criminal-defender", "strategist"],
  },
  {
    name: "FI KHO valituslupa drafting",
    query: "Pitää laatia valituslupahakemus KHO:lle, HOL § 111 menettelyvirhe.",
    lang: "fi",
    ctx: { jurisdiction: "FI", complexity: 9, hasHardDeadline: true },
    mustIncludeId: ["senior-asianajaja", "litigator", "researcher", "strategist"],
    expectHighStakes: true,
  },
  {
    name: "EU GDPR breach incident — corporate",
    query: "GDPR breach в нашей компании, 1000+ субъектов затронуто, нужно ли уведомлять supervisorку через 72ч?",
    lang: "ru",
    ctx: { jurisdiction: "EU", caseType: "gdpr", complexity: 7 },
    mustIncludeId: ["corporate-lawyer", "strategist"],
    expectHighStakes: true,
  },
  {
    name: "ECHR application after exhausted KHO route",
    query: "KHO отказал в valituslupa. Хочу подать в ECHR. Срок 4 месяца?",
    lang: "ru",
    ctx: { jurisdiction: "FI", complexity: 9 },
    mustIncludeId: ["litigator", "strategist"],
    expectHighStakes: true,
  },
  {
    name: "Plain question, no obvious domain — fallback path",
    query: "У меня вопрос по закону, не знаю с чего начать.",
    lang: "ru",
    ctx: { jurisdiction: "EE" },
    mustIncludeId: ["senior-vandeadvokaat", "strategist"],
  },
  // ─── Wave F (2026-05-25) specialist routing cases ───────────────────────
  {
    name: "Wave F: ECtHR application after KHO refusal",
    query:
      "KHO отказал в valituslupa. Хочу подать в ECHR — какой срок? Art 8 ECHR + Art 13?",
    lang: "ru",
    ctx: { jurisdiction: "FI", complexity: 9, hasHardDeadline: true },
    mustIncludeId: ["ecthr-specialist", "strategist"],
    expectHighStakes: true,
  },
  {
    name: "Wave F: Client psychology — exhausted, considering settlement",
    query:
      "Я устал воевать три года. Стоит ли всё это? Не могу больше — может сдаться?",
    lang: "ru",
    ctx: { jurisdiction: "FI", complexity: 7 },
    mustIncludeId: ["client-psychology", "strategist"],
  },
  {
    name: "Wave F: Forensic evidence — F43.1 epikriis + signature anomaly",
    query:
      "У меня epikriis с F43.1 PTSD, но подпись врача на одном документе странная. Какое доказательство?",
    lang: "ru",
    ctx: { jurisdiction: "EE", complexity: 6 },
    mustIncludeId: ["forensic-evidence", "strategist"],
  },
  {
    name: "Wave F: Native writer — draft KHO valituslupahakemus",
    query:
      "Pitää laatia valituslupahakemus KHO:lle suomeksi, vaatimukset ja perustelut on jo päätetty.",
    lang: "fi",
    ctx: { jurisdiction: "FI", complexity: 8, hasHardDeadline: true },
    mustIncludeId: ["native-writer", "senior-asianajaja", "strategist"],
    expectHighStakes: true,
  },
];

for (const c of CASES) {
  Deno.test(`routeToLawyers: ${c.name}`, () => {
    const decision = routeToLawyers(c.query, c.lang, c.ctx);
    // floor / cap
    assert(decision.agents.length >= MIN_LAWYERS, `< MIN_LAWYERS for ${c.name}`);
    assert(decision.agents.length <= MAX_LAWYERS, `> MAX_LAWYERS for ${c.name}`);
    // must-include
    const ids = new Set(decision.agents.map((a) => a.id));
    for (const need of c.mustIncludeId) {
      assert(
        ids.has(need),
        `${c.name}: expected ${need} in roster but got [${
          [...ids].join(",")
        }]`,
      );
    }
    // must-exclude
    for (const banned of c.mustExcludeId ?? []) {
      assert(
        !ids.has(banned),
        `${c.name}: ${banned} should NOT appear`,
      );
    }
    // high-stakes
    if (c.expectHighStakes !== undefined) {
      assertEquals(
        decision.highStakes,
        c.expectHighStakes,
        `${c.name}: highStakes mismatch (trace: ${decision.trace.join(",")})`,
      );
    }
    // exactly ONE general counsel
    const generals = decision.agents.filter((a) =>
      a.id === "senior-asianajaja" || a.id === "senior-vandeadvokaat"
    );
    assertEquals(
      generals.length,
      1,
      `${c.name}: expected exactly 1 general counsel, got ${generals.length}`,
    );
    // strategist always present
    assert(
      decision.agents.some((a) => a.id === "strategist"),
      `${c.name}: strategist must be present`,
    );
  });
}

// ─── High-stakes branch logic ────────────────────────────────────────────────

Deno.test("complexity ≥ threshold triggers high-stakes", () => {
  const d = routeToLawyers("any query", "ru", {
    jurisdiction: "EE",
    complexity: COMPLEXITY_THRESHOLD,
  });
  assert(d.highStakes, "complexity at threshold must trigger high-stakes");
});

Deno.test("hasHardDeadline triggers high-stakes", () => {
  const d = routeToLawyers("urgent question", "ru", {
    jurisdiction: "EE",
    hasHardDeadline: true,
  });
  assert(d.highStakes, "hasHardDeadline must trigger high-stakes");
});

Deno.test("mixed jurisdiction triggers high-stakes", () => {
  const d = routeToLawyers("cross-border query", "ru", {
    jurisdiction: "mixed",
  });
  assert(d.highStakes, "mixed jurisdiction must trigger high-stakes");
});

// ─── Haiku refinement seam ───────────────────────────────────────────────────

Deno.test("refineWithHaiku adds suggested agents without exceeding MAX_LAWYERS", async () => {
  const stub: HaikuCaller = {
    blocking: () =>
      Promise.resolve(
        `{"agent_ids":["researcher","litigator","tax-advisor"]}`,
      ),
  };
  const initial = routeToLawyers("plain", "ru", { jurisdiction: "EE" });
  const refined = await refineWithHaiku("plain", initial, stub, "haiku-test");
  assert(refined.agents.length <= MAX_LAWYERS);
  assert(refined.trace.some((t) => t.startsWith("haiku_added=")));
});

Deno.test("refineWithHaiku gracefully ignores unparseable output", async () => {
  const stub: HaikuCaller = {
    blocking: () => Promise.resolve(`not-json garbage`),
  };
  const initial = routeToLawyers("plain", "ru", { jurisdiction: "EE" });
  const refined = await refineWithHaiku("plain", initial, stub, "haiku-test");
  // Same as initial — no crash, no added agents.
  assertEquals(refined.agents.length, initial.agents.length);
});

Deno.test("refineWithHaiku ignores unknown agent_ids", async () => {
  const stub: HaikuCaller = {
    blocking: () => Promise.resolve(`{"agent_ids":["totally-fake-agent"]}`),
  };
  const initial = routeToLawyers("plain", "ru", { jurisdiction: "EE" });
  const refined = await refineWithHaiku("plain", initial, stub, "haiku-test");
  assertEquals(
    refined.agents.length,
    initial.agents.length,
    "unknown ids should be silently dropped",
  );
});

// ─── Agent snapshot tests — each prompt non-trivial in each lang ─────────────

const SAMPLE_QUERY = "Sample legal question — has §, multi-jur, complex case.";

Deno.test("agent prompts produce non-empty output in all 4 languages", () => {
  const langs: ReadonlyArray<"ru" | "et" | "fi" | "en"> = ["ru", "et", "fi", "en"];
  for (const a of ALL_LAWYERS) {
    for (const lang of langs) {
      const prompt = a.systemPrompt(SAMPLE_QUERY, { language: lang });
      assert(
        prompt.length > 400,
        `${a.id} (${lang}) prompt too short: ${prompt.length}`,
      );
    }
  }
});

Deno.test("agent prompts are distinguishable (no two identical)", () => {
  const firstChunks = ALL_LAWYERS.map((a) =>
    a.systemPrompt(SAMPLE_QUERY, { language: "ru" }).slice(0, 250)
  );
  const seen = new Set(firstChunks);
  assertEquals(
    seen.size,
    firstChunks.length,
    "every agent must have a distinct opening prompt",
  );
});

Deno.test("immigration_lawyer prompt mentions Sulga-relevant statutes", () => {
  const a: LawyerAgent = getLawyerById("immigration-lawyer")!;
  const prompt = a.systemPrompt(
    "depri меня хотят, KHO 5.6",
    { jurisdiction: "FI", language: "ru" },
  );
  assertStringIncludes(prompt, "UlkomaalaisL");
  assertStringIncludes(prompt, "Dublin III");
  assertStringIncludes(prompt, "ECHR Art 3");
});

Deno.test("strategist prompt includes 4-plan structure A/B/C/D", () => {
  const a = getLawyerById("strategist")!;
  const prompt = a.systemPrompt("какие альтернативы?", { language: "ru" });
  assertStringIncludes(prompt, "План A");
  assertStringIncludes(prompt, "План B");
  assertStringIncludes(prompt, "План C");
  assertStringIncludes(prompt, "План D");
});

Deno.test("litigator prompt insists on norm → finding → contradiction structure", () => {
  const a = getLawyerById("litigator")!;
  const prompt = a.systemPrompt(
    "valituslupahakemus",
    { jurisdiction: "FI", language: "ru" },
  );
  assertStringIncludes(prompt, "norm");
  assertStringIncludes(prompt, "contradiction");
  assertStringIncludes(prompt, "HOL § 111");
});

Deno.test("senior_vandeadvokaat prompt is EE-only formalism", () => {
  const a = getLawyerById("senior-vandeadvokaat")!;
  const prompt = a.systemPrompt("kassatsioon TsMS", { language: "et" });
  assertStringIncludes(prompt, "Vanemvandeadvokaat");
  assertStringIncludes(prompt, "Riigikoh");
});

Deno.test("senior_asianajaja prompt is FI-only formalism", () => {
  const a = getLawyerById("senior-asianajaja")!;
  const prompt = a.systemPrompt("KHO valitus", { language: "fi" });
  assertStringIncludes(prompt, "Senior Asianajaja");
  assertStringIncludes(prompt, "KKO");
});
