// Deno TDD — Phase 2 strategic upgrade #2 (_shared/legal_lookup.ts).
// -----------------------------------------------------------------------------
// Pure-module contract tests. The OpenAI embed and Supabase RPC are injected
// via dependency seams so every test is deterministic + offline.
//
// Run with:
//   deno test --allow-env=LEGAL_LOOKUP_LIVE_API_ENABLED \
//     supabase/functions/_shared/__tests__/legal_lookup_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertRejects,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  type CasesCitingFn,
  type EmbedQueryFn,
  extractSectionFromQuery,
  type FetchFreshnessFn,
  formatLookupResultForModel,
  formatStatute,
  type LawSearchRpcFn,
  type LawSearchRpcRow,
  type LegalLookupCaseCitation,
  type LegalLookupTravaux,
  LEGAL_LOOKUP_MATCH_COUNT,
  LEGAL_LOOKUP_MAX_RESPONSE_BYTES,
  LEGAL_LOOKUP_SECTION_BOOST_EXACT,
  LEGAL_LOOKUP_SECTION_BOOST_PARTIAL,
  LEGAL_LOOKUP_SIMILARITY_THRESHOLD,
  LEGAL_LOOKUP_SNIPPET_MAX_CHARS,
  LEGAL_LOOKUP_SNIPPET_ONLY_MAX_CHARS,
  LEGAL_LOOKUP_STALE_THRESHOLD_DAYS,
  LEGAL_LOOKUP_TOOL_USE_INSTRUCTION,
  legalLookup,
  LegalLookupConfigError,
  type LiveFallbackFn,
  rerankRowsBySection,
  type TravauxForFn,
  computeFreshnessDays,
  stubLiveFallback,
} from "../legal_lookup.ts";

// ─── Fixtures ───────────────────────────────────────────────────────────────

const FROZEN_NOW = new Date("2026-05-13T12:00:00Z");
const FRESH_REFRESHED = "2026-05-01T00:00:00Z"; // 12 days old, fresh.
const STALE_REFRESHED = "2026-01-01T00:00:00Z"; // 132 days old, stale.

function dummyEmbedding(): number[] {
  // 1536-d zero vector. Real embeddings have float magnitudes, but the
  // tests do not exercise downstream similarity logic — we control
  // `similarity` directly on RPC rows.
  return Array(1536).fill(0);
}

const okEmbed: EmbedQueryFn = async (q: string) => ({
  embedding: dummyEmbedding(),
  tokens: q.length,
});

function makeRow(
  overrides: Partial<LawSearchRpcRow> = {},
): LawSearchRpcRow {
  return {
    id: "hol-§114-0",
    act_slug: "hol",
    act_name: "Hallintolaki",
    paragraph: "114",
    title: "Menetetyn määräajan palauttaminen",
    body:
      "Jos joku laillisen esteen tai muun erittäin painavan syyn vuoksi " +
      "ei ole voinut määräajassa hakea muutosta päätökseen tai ryhtyä " +
      "muuhun toimenpiteeseen oikeudenkäynnissä, korkein hallinto-oikeus " +
      "voi hakemuksesta palauttaa määräajan. Hakemus on tehtävä 30 päivän " +
      "kuluessa esteen lakkaamisesta ja viimeistään vuoden kuluttua " +
      "siitä, kun määräaika päättyi.",
    source_url: "https://www.finlex.fi/fi/laki/ajantasa/2003/20030434",
    jurisdiction: "FI",
    similarity: 0.87,
    ...overrides,
  };
}

function rpcReturning(
  rows: LawSearchRpcRow[],
): LawSearchRpcFn {
  return async () => rows;
}

function freshnessReturning(
  map: Record<string, string | null>,
): FetchFreshnessFn {
  return async (ids: string[]) => {
    const out = new Map<string, string | null>();
    for (const id of ids) out.set(id, map[id] ?? null);
    return out;
  };
}

// ─── LLK-T01 — happy path: corpus hit, fresh ────────────────────────────────

Deno.test("LLK-T01 — corpus hit with fresh chunk → no stale_warning", async () => {
  const result = await legalLookup(
    "HOL §114 restoration deadlines",
    "fi",
    {
      embed: okEmbed,
      lawSearch: rpcReturning([makeRow()]),
      fetchFreshness: freshnessReturning({ "hol-§114-0": FRESH_REFRESHED }),
    },
    { now: () => FROZEN_NOW },
  );

  assertEquals(result.source, "corpus");
  assertEquals(result.chunks.length, 1);
  assertEquals(result.chunks[0].statute, "HOL §114");
  assertEquals(result.chunks[0].similarity, 0.87);
  assertEquals(result.chunks[0].freshness_days, 12);
  assertEquals(result.stale_warning, undefined);
});

// ─── LLK-T02 — cosine threshold filter (model contract, not RPC) ────────────

Deno.test("LLK-T02 — threshold passed through to RPC", async () => {
  let capturedThreshold: number | undefined;
  const rpc: LawSearchRpcFn = async (params) => {
    capturedThreshold = params.similarity_threshold;
    return [];
  };

  await legalLookup(
    "some query",
    "ee",
    { embed: okEmbed, lawSearch: rpc },
    { similarityThreshold: 0.82, now: () => FROZEN_NOW },
  );
  assertEquals(capturedThreshold, 0.82);

  // Default threshold
  await legalLookup(
    "some query",
    "ee",
    { embed: okEmbed, lawSearch: rpc },
    { now: () => FROZEN_NOW },
  );
  assertEquals(capturedThreshold, LEGAL_LOOKUP_SIMILARITY_THRESHOLD);
});

// ─── LLK-T03 — stale warning when corpus old ────────────────────────────────

Deno.test("LLK-T03 — stale chunk → stale_warning present", async () => {
  const result = await legalLookup(
    "HOL §114",
    "fi",
    {
      embed: okEmbed,
      lawSearch: rpcReturning([makeRow()]),
      fetchFreshness: freshnessReturning({ "hol-§114-0": STALE_REFRESHED }),
    },
    { now: () => FROZEN_NOW },
  );

  assert(result.stale_warning !== undefined, "expected stale_warning");
  assertStringIncludes(result.stale_warning!, "132 days");
  assertStringIncludes(result.stale_warning!, "Cross-check with primary source");
  // Still corpus-sourced (no live fallback wired).
  assertEquals(result.source, "corpus");
  assertEquals(result.chunks[0].freshness_days, 132);
});

// ─── LLK-T04 — missing corpus_refreshed_at → treated stale ──────────────────

Deno.test("LLK-T04 — null refreshed_at → freshness_days=null + warning", async () => {
  const result = await legalLookup(
    "HOL §114",
    "fi",
    {
      embed: okEmbed,
      lawSearch: rpcReturning([makeRow()]),
      fetchFreshness: freshnessReturning({ "hol-§114-0": null }),
    },
    { now: () => FROZEN_NOW },
  );

  assertEquals(result.chunks[0].freshness_days, null);
  assert(result.stale_warning !== undefined);
  assertStringIncludes(result.stale_warning!, "unknown refresh date");
});

// ─── LLK-T05 — live fallback dispatch (enabled + stale) ─────────────────────

Deno.test("LLK-T05 — live fallback fires when enabled + stale", async () => {
  let liveCalled = false;
  let liveJurisdiction: string | null = null;
  const live: LiveFallbackFn = async (req) => {
    liveCalled = true;
    liveJurisdiction = req.jurisdiction;
    return {
      chunks: [
        {
          statute: "HOL §114",
          act_slug: "hol",
          paragraph: "114",
          text: "(live Finlex text)",
          similarity: 1.0,
          freshness_days: 0,
          source_url: "https://finlex.fi/...",
        },
      ],
      source: "finlex",
    };
  };

  const result = await legalLookup(
    "HOL §114",
    "fi",
    {
      embed: okEmbed,
      lawSearch: rpcReturning([makeRow()]),
      fetchFreshness: freshnessReturning({ "hol-§114-0": STALE_REFRESHED }),
      liveFallback: live,
    },
    { now: () => FROZEN_NOW, liveApiEnabled: true },
  );

  assert(liveCalled, "live fallback should have been invoked");
  assertEquals(liveJurisdiction, "fi");
  assertEquals(result.source, "finlex");
  assertEquals(result.chunks[0].text, "(live Finlex text)");
});

// ─── LLK-T06 — live fallback NOT fired when disabled ────────────────────────

Deno.test("LLK-T06 — stale + liveApiEnabled=false → corpus only", async () => {
  let liveCalled = false;
  const live: LiveFallbackFn = async () => {
    liveCalled = true;
    return null;
  };

  const result = await legalLookup(
    "HOL §114",
    "fi",
    {
      embed: okEmbed,
      lawSearch: rpcReturning([makeRow()]),
      fetchFreshness: freshnessReturning({ "hol-§114-0": STALE_REFRESHED }),
      liveFallback: live,
    },
    { now: () => FROZEN_NOW, liveApiEnabled: false },
  );

  assertEquals(liveCalled, false);
  assertEquals(result.source, "corpus");
  assert(result.stale_warning !== undefined);
});

// ─── LLK-T07 — stub live fallback always returns null (v1) ──────────────────

Deno.test("LLK-T07 — stubLiveFallback returns null for every jurisdiction", async () => {
  for (const jur of ["fi", "ee", "eu", "de", "ru"] as const) {
    const out = await stubLiveFallback({
      query: "test",
      jurisdiction: jur,
      specificStatute: null,
    });
    assertEquals(out, null, `expected null for ${jur} in v1`);
  }
});

// ─── LLK-T08 — unknown jurisdiction throws config error ─────────────────────

Deno.test("LLK-T08 — unknown jurisdiction throws LegalLookupConfigError", async () => {
  await assertRejects(
    () =>
      legalLookup(
        "test",
        "us", // not in whitelist
        { embed: okEmbed, lawSearch: rpcReturning([]) },
      ),
    LegalLookupConfigError,
    "Unsupported jurisdiction",
  );
});

// ─── LLK-T09 — empty query → graceful no-op ─────────────────────────────────

Deno.test("LLK-T09 — empty query → empty chunks, source=stub", async () => {
  const result = await legalLookup(
    "   ",
    "fi",
    { embed: okEmbed, lawSearch: rpcReturning([makeRow()]) },
  );
  assertEquals(result.chunks.length, 0);
  assertEquals(result.source, "stub");
  assertEquals(result.embed_tokens, 0);
});

// ─── LLK-T10 — embed failure → graceful empty ───────────────────────────────

Deno.test("LLK-T10 — embed returns null → empty result, no RPC call", async () => {
  let rpcCalled = false;
  const failingEmbed: EmbedQueryFn = async () => null;
  const rpc: LawSearchRpcFn = async () => {
    rpcCalled = true;
    return [];
  };
  const result = await legalLookup(
    "test",
    "fi",
    { embed: failingEmbed, lawSearch: rpc },
  );
  assertEquals(result.chunks.length, 0);
  assertEquals(rpcCalled, false);
});

// ─── LLK-T11 — RPC throws → degrades to empty ───────────────────────────────

Deno.test("LLK-T11 — RPC throws → empty chunks, no exception", async () => {
  const rpc: LawSearchRpcFn = async () => {
    throw new Error("boom");
  };
  const result = await legalLookup(
    "test",
    "fi",
    { embed: okEmbed, lawSearch: rpc },
  );
  assertEquals(result.chunks.length, 0);
  assertEquals(result.source, "stub");
});

// ─── LLK-T12 — 4 KB cap on response body ────────────────────────────────────

Deno.test("LLK-T12 — response capped at 4KB by dropping low-similarity chunks", async () => {
  // Build five rows with full-length bodies (~700 chars each post-truncate)
  // plus metadata → must exceed 4096 bytes if all kept; lowest-similarity
  // chunks should be dropped first.
  const longBody = "A".repeat(2000); // exceeds 700 cap → truncated to 700
  const rows: LawSearchRpcRow[] = [];
  for (let i = 0; i < 5; i++) {
    rows.push(
      makeRow({
        id: `hol-§${i}-0`,
        paragraph: String(i),
        body: longBody,
        similarity: 0.75 + i * 0.05, // 0.75 .. 0.95
      }),
    );
  }

  const result = await legalLookup(
    "HOL paragraphs",
    "fi",
    {
      embed: okEmbed,
      lawSearch: rpcReturning(rows),
      fetchFreshness: freshnessReturning({}),
    },
    { now: () => FROZEN_NOW },
  );

  const serialised = JSON.stringify(result);
  assert(
    serialised.length <= LEGAL_LOOKUP_MAX_RESPONSE_BYTES,
    `expected ≤ ${LEGAL_LOOKUP_MAX_RESPONSE_BYTES} bytes, got ${serialised.length}`,
  );
  // Highest-similarity chunk MUST survive even after capping.
  const survivingParagraphs = result.chunks.map((c) => c.paragraph);
  if (result.chunks.length > 0) {
    assert(
      survivingParagraphs.includes("4"),
      "expected highest-similarity chunk (paragraph=4) to survive cap",
    );
  }
});

// ─── LLK-T13 — snippet truncation cap ───────────────────────────────────────

Deno.test("LLK-T13 — snippet bodies truncated to ≤700 chars", async () => {
  const longBody = "B".repeat(2000);
  const result = await legalLookup(
    "test",
    "fi",
    {
      embed: okEmbed,
      lawSearch: rpcReturning([makeRow({ body: longBody })]),
      fetchFreshness: freshnessReturning({ "hol-§114-0": FRESH_REFRESHED }),
    },
    { now: () => FROZEN_NOW },
  );
  assertEquals(
    result.chunks[0].text.length,
    LEGAL_LOOKUP_SNIPPET_MAX_CHARS,
  );
});

// ─── LLK-T14 — specific_statute prepended to embed query ────────────────────

Deno.test("LLK-T14 — specific_statute is prepended to embed input", async () => {
  let captured: string | null = null;
  const spyEmbed: EmbedQueryFn = async (q: string) => {
    captured = q;
    return { embedding: dummyEmbedding(), tokens: 0 };
  };

  await legalLookup(
    "restoration deadlines",
    "fi",
    { embed: spyEmbed, lawSearch: rpcReturning([]) },
    { specificStatute: "HOL §114", now: () => FROZEN_NOW },
  );

  assert(captured !== null);
  assertStringIncludes(captured!, "HOL §114");
  assertStringIncludes(captured!, "restoration deadlines");
});

// ─── LLK-T15 — match_count passed through ───────────────────────────────────

Deno.test("LLK-T15 — match_count default + override flow to RPC", async () => {
  let captured: number | undefined;
  const rpc: LawSearchRpcFn = async (params) => {
    captured = params.match_count;
    return [];
  };

  await legalLookup(
    "test",
    "fi",
    { embed: okEmbed, lawSearch: rpc },
    { now: () => FROZEN_NOW },
  );
  assertEquals(captured, LEGAL_LOOKUP_MATCH_COUNT);

  await legalLookup(
    "test",
    "fi",
    { embed: okEmbed, lawSearch: rpc },
    { matchCount: 12, now: () => FROZEN_NOW },
  );
  assertEquals(captured, 12);
});

// ─── LLK-T16 — formatStatute helpers ────────────────────────────────────────

Deno.test("LLK-T16 — formatStatute renders EE/FI and EU correctly", () => {
  assertEquals(formatStatute("tls", "88"), "TLS §88");
  assertEquals(formatStatute("HOL", "114"), "HOL §114");
  assertEquals(
    formatStatute("32019L1152", "art-5"),
    "Directive 32019L1152 art-5",
  );
});

// ─── LLK-T17 — computeFreshnessDays edge cases ──────────────────────────────

Deno.test("LLK-T17 — computeFreshnessDays handles null, bad ISO, clock skew", () => {
  const nowMs = FROZEN_NOW.getTime();
  assertEquals(computeFreshnessDays(null, nowMs), null);
  assertEquals(computeFreshnessDays("not-a-date", nowMs), null);
  assertEquals(computeFreshnessDays(FRESH_REFRESHED, nowMs), 12);
  // Clock-skew (future date) clamps to 0, not negative.
  assertEquals(
    computeFreshnessDays("2030-01-01T00:00:00Z", nowMs),
    0,
  );
});

// ─── LLK-T18 — formatLookupResultForModel: not-found message ────────────────

Deno.test("LLK-T18 — formatLookupResultForModel on empty result says 'do NOT fabricate'", () => {
  const out = formatLookupResultForModel({
    chunks: [],
    source: "stub",
    embed_tokens: 0,
  });
  assertStringIncludes(out, "No matching statute");
  assertStringIncludes(out, "Do NOT fabricate");
});

// ─── LLK-T19 — formatLookupResultForModel: chunk rendering ──────────────────

Deno.test("LLK-T19 — formatLookupResultForModel includes stale warning + sources", () => {
  const out = formatLookupResultForModel({
    chunks: [
      {
        statute: "HOL §114",
        act_slug: "hol",
        paragraph: "114",
        text: "Jos joku laillisen esteen vuoksi...",
        similarity: 0.91,
        freshness_days: 132,
        source_url: "https://finlex.fi/...",
      },
    ],
    source: "corpus",
    stale_warning: "Corpus may be stale (132 days, threshold 60 days).",
    embed_tokens: 50,
  });
  assertStringIncludes(out, "[HOL §114]");
  assertStringIncludes(out, "sim 0.91");
  assertStringIncludes(out, "132d old");
  assertStringIncludes(out, "Source: https://finlex.fi/");
  assertStringIncludes(out, "Corpus may be stale");
});

// ─── LLK-T20 — stale threshold default value sanity check ───────────────────

Deno.test("LLK-T20 — STALE threshold constants match spec (60 days, 0.75 cos)", () => {
  assertEquals(LEGAL_LOOKUP_STALE_THRESHOLD_DAYS, 60);
  assertEquals(LEGAL_LOOKUP_SIMILARITY_THRESHOLD, 0.75);
  assertEquals(LEGAL_LOOKUP_MAX_RESPONSE_BYTES, 4096);
  assertEquals(LEGAL_LOOKUP_MATCH_COUNT, 5);
});

// =============================================================================
// Corpus v3 additions — cases_citing + travaux + validAt + stronger TOOL USE
// =============================================================================

const SAMPLE_CASE_HOL114: LegalLookupCaseCitation = {
  case_number: "KHO 2018:42",
  court: "KHO",
  decided_at: "2018-03-15",
  key_holding: "Sotaperäisen tilan vuoksi annettu lupa ei poistanut " +
    "kantajan oikeutta hakea palauttamista.",
};

const SAMPLE_TRAVAUX_HOL114: LegalLookupTravaux = {
  doc_number: "HE 72/2002 vp",
  title: "Hallintolaki — perustelut",
  text: "Pykälä vastaa pääosin hallintolainkäyttölain 61 §:n nykyistä " +
    "sääntelyä. Erityisen painavalla syyllä tarkoitetaan...",
  source_url: "https://www.eduskunta.fi/...HE_72+2002",
};

function casesReturning(rows: LegalLookupCaseCitation[]): CasesCitingFn {
  return async () => rows;
}

function travauxReturning(rows: LegalLookupTravaux[]): TravauxForFn {
  return async () => rows;
}

// ─── LLK-T21 — cases_citing enrichment populates result ─────────────────────

Deno.test("LLK-T21 — cases_citing populates result.cases_citing for top hit", async () => {
  let casesArgs: { act_slug: string; section: string } | null = null;
  const cases: CasesCitingFn = async (params) => {
    casesArgs = params;
    return [SAMPLE_CASE_HOL114];
  };

  const result = await legalLookup(
    "HOL §114",
    "fi",
    {
      embed: okEmbed,
      lawSearch: rpcReturning([makeRow()]),
      fetchFreshness: freshnessReturning({ "hol-§114-0": FRESH_REFRESHED }),
      casesCiting: cases,
    },
    { now: () => FROZEN_NOW },
  );

  // Cast: TS control-flow narrows casesArgs to `never` after the async
  // closure assignment because it cannot prove the callback ran.
  const seenArgs = casesArgs as { act_slug: string; section: string } | null;
  assertEquals(seenArgs?.act_slug, "hol");
  assertEquals(seenArgs?.section, "114");
  assertEquals(result.cases_citing?.length, 1);
  assertEquals(result.cases_citing?.[0].case_number, "KHO 2018:42");
});

// ─── LLK-T22 — travaux enrichment populates result.travaux ──────────────────

Deno.test("LLK-T22 — travauxFor populates result.travaux for top hit", async () => {
  const travaux: TravauxForFn = travauxReturning([SAMPLE_TRAVAUX_HOL114]);

  const result = await legalLookup(
    "HOL §114",
    "fi",
    {
      embed: okEmbed,
      lawSearch: rpcReturning([makeRow()]),
      fetchFreshness: freshnessReturning({ "hol-§114-0": FRESH_REFRESHED }),
      travauxFor: travaux,
    },
    { now: () => FROZEN_NOW },
  );

  assertEquals(result.travaux?.length, 1);
  assertEquals(result.travaux?.[0].doc_number, "HE 72/2002 vp");
  // Body truncated by the same SNIPPET cap.
  assert(
    (result.travaux?.[0].text?.length ?? 0) <= LEGAL_LOOKUP_SNIPPET_MAX_CHARS,
  );
});

// ─── LLK-T23 — enrichment is best-effort: throwing RPC swallowed ────────────

Deno.test("LLK-T23 — cases_citing throws → chunks still returned, cases_citing absent", async () => {
  const throwingCases: CasesCitingFn = async () => {
    throw new Error("cases_citing boom");
  };
  const throwingTrav: TravauxForFn = async () => {
    throw new Error("travaux boom");
  };

  const result = await legalLookup(
    "HOL §114",
    "fi",
    {
      embed: okEmbed,
      lawSearch: rpcReturning([makeRow()]),
      fetchFreshness: freshnessReturning({ "hol-§114-0": FRESH_REFRESHED }),
      casesCiting: throwingCases,
      travauxFor: throwingTrav,
    },
    { now: () => FROZEN_NOW },
  );

  assertEquals(result.chunks.length, 1);
  assertEquals(result.cases_citing, undefined);
  assertEquals(result.travaux, undefined);
});

// ─── LLK-T24 — enrichment skipped when no chunks ─────────────────────────────

Deno.test("LLK-T24 — empty chunks → enrichment RPCs are NOT invoked", async () => {
  let casesCalled = false;
  let travauxCalled = false;
  const cases: CasesCitingFn = async () => {
    casesCalled = true;
    return [SAMPLE_CASE_HOL114];
  };
  const travaux: TravauxForFn = async () => {
    travauxCalled = true;
    return [SAMPLE_TRAVAUX_HOL114];
  };

  const result = await legalLookup(
    "HOL §114",
    "fi",
    {
      embed: okEmbed,
      lawSearch: rpcReturning([]), // empty RPC result
      casesCiting: cases,
      travauxFor: travaux,
    },
    { now: () => FROZEN_NOW },
  );

  assertEquals(result.chunks.length, 0);
  assertEquals(casesCalled, false);
  assertEquals(travauxCalled, false);
});

// ─── LLK-T25 — enrichmentLimit caps cases and travaux lists ─────────────────

Deno.test("LLK-T25 — enrichmentLimit caps cases_citing/travaux arrays", async () => {
  const many = Array.from({ length: 10 }, (_, i): LegalLookupCaseCitation => ({
    case_number: `KHO 2020:${i}`,
    court: "KHO",
    decided_at: `2020-01-0${(i % 9) + 1}`,
    key_holding: `holding ${i}`,
  }));
  const cases: CasesCitingFn = casesReturning(many);

  const result = await legalLookup(
    "HOL §114",
    "fi",
    {
      embed: okEmbed,
      lawSearch: rpcReturning([makeRow()]),
      fetchFreshness: freshnessReturning({ "hol-§114-0": FRESH_REFRESHED }),
      casesCiting: cases,
    },
    { now: () => FROZEN_NOW, enrichmentLimit: 2 },
  );

  assertEquals(result.cases_citing?.length, 2);
});

// ─── LLK-T26 — validAt option passes through to RPC params ──────────────────

Deno.test("LLK-T26 — validAt option is accepted without breaking RPC contract", async () => {
  // The v1 RPC signature does NOT have valid_at, so legalLookup just stores
  // the option for downstream use (the handler injects it into the v2 RPC
  // call). This test verifies the option is accepted, doesn't throw, and
  // leaves the existing RPC contract intact.
  let capturedParams: unknown = null;
  const rpc: LawSearchRpcFn = async (params) => {
    capturedParams = params;
    return [];
  };

  const result = await legalLookup(
    "HOL §114",
    "fi",
    { embed: okEmbed, lawSearch: rpc },
    {
      now: () => FROZEN_NOW,
      validAt: "2026-05-14T00:00:00Z",
    },
  );

  // Existing contract unchanged: 5 fields go to the RPC.
  assert(capturedParams !== null);
  assertEquals(typeof (capturedParams as Record<string, unknown>).match_count, "number");
  assertEquals(result.chunks.length, 0);
});

// ─── LLK-T27 — formatLookupResultForModel renders cases + travaux ───────────

Deno.test("LLK-T27 — formatter renders cases_citing + travaux sections", () => {
  const out = formatLookupResultForModel({
    chunks: [
      {
        statute: "HOL §114",
        act_slug: "hol",
        paragraph: "114",
        text: "Pykälän nykyinen teksti...",
        similarity: 0.93,
        freshness_days: 5,
        source_url: "https://finlex.fi/...",
      },
    ],
    cases_citing: [SAMPLE_CASE_HOL114],
    travaux: [SAMPLE_TRAVAUX_HOL114],
    source: "corpus",
    embed_tokens: 12,
  });

  assertStringIncludes(out, "Cases citing this §");
  assertStringIncludes(out, "KHO 2018:42");
  assertStringIncludes(out, "MENTION these decisions");
  assertStringIncludes(out, "Travaux / legislative intent");
  assertStringIncludes(out, "HE 72/2002 vp");
  assertStringIncludes(out, "CITE the HE / eelnõu");
});

// ─── LLK-T28 — TOOL_USE_INSTRUCTION mentions cases_citing + travaux ─────────

Deno.test("LLK-T28 — TOOL_USE_INSTRUCTION mentions cases_citing + travaux", () => {
  assertStringIncludes(LEGAL_LOOKUP_TOOL_USE_INSTRUCTION, "cases_citing");
  assertStringIncludes(LEGAL_LOOKUP_TOOL_USE_INSTRUCTION, "travaux");
  assertStringIncludes(LEGAL_LOOKUP_TOOL_USE_INSTRUCTION, "MANDATORY");
  // Hard ceiling 2560 bytes — the LLK-T43 clause for Option B snippet
  // handling pushed the canonical text to ~2.1 KB. Headroom kept tight so
  // accidental Option-C expansions trip the test rather than bloating the
  // executor system prompt budget.
  assert(LEGAL_LOOKUP_TOOL_USE_INSTRUCTION.length < 2560);
});

// ─── LLK-T29 — backward-compat: legalLookup without v3 deps still works ─────

Deno.test("LLK-T29 — legalLookup without casesCiting/travauxFor deps works unchanged", async () => {
  const result = await legalLookup(
    "HOL §114",
    "fi",
    {
      embed: okEmbed,
      lawSearch: rpcReturning([makeRow()]),
      fetchFreshness: freshnessReturning({ "hol-§114-0": FRESH_REFRESHED }),
      // No casesCiting, no travauxFor → result must omit those fields.
    },
    { now: () => FROZEN_NOW },
  );

  assertEquals(result.chunks.length, 1);
  assertEquals(result.cases_citing, undefined);
  assertEquals(result.travaux, undefined);
  assertEquals(result.source, "corpus");
});

// =============================================================================
// Section-aware re-ranking (2026-05-13) — fixes 5 golden QA queries where the
// right act was retrieved but a sibling § ranked above the target.
// =============================================================================

// ─── LLK-T30 — extractSectionFromQuery: FI patterns ─────────────────────────

Deno.test("LLK-T30 — extractSectionFromQuery handles FI § patterns", () => {
  // §-symbol BEFORE number
  assertEquals(extractSectionFromQuery("perustuslaki §10"), "10");
  assertEquals(extractSectionFromQuery("perustuslaki § 10"), "10");
  assertEquals(extractSectionFromQuery("HOL §114"), "114");
  assertEquals(extractSectionFromQuery("HOL § 114a"), "114a");
  // §-symbol AFTER number (FI usage)
  assertEquals(extractSectionFromQuery("hallintolain 26 § kielelliset oikeudet"), "26");
  assertEquals(extractSectionFromQuery("114§"), "114");
  // Sub-paragraph "6:2"
  assertEquals(extractSectionFromQuery("§ 6:2 erityissäännös"), "6:2");
});

// ─── LLK-T31 — extractSectionFromQuery: EE + EU + null cases ────────────────

Deno.test("LLK-T31 — extractSectionFromQuery handles EE, EU, and null cases", () => {
  // EE — same §-symbol notation as FI
  assertEquals(extractSectionFromQuery("TsÜS § 86"), "86");
  assertEquals(extractSectionFromQuery("TsÜS §86 hea usk"), "86");
  // EU article notation
  assertEquals(extractSectionFromQuery("GDPR art. 17 right to be forgotten"), "17");
  assertEquals(extractSectionFromQuery("Article 5 GDPR"), "5");
  assertEquals(extractSectionFromQuery("art 17.1"), "17.1");
  // No § reference → null (preserves semantic-search order)
  assertEquals(extractSectionFromQuery("what is the deadline for restoration"), null);
  assertEquals(extractSectionFromQuery("hallintolaki kielelliset oikeudet"), null);
  assertEquals(extractSectionFromQuery(""), null);
  // "5 years" without § symbol must NOT match (would have been a false-positive
  // in a naive \d+ regex).
  assertEquals(extractSectionFromQuery("5 years to file"), null);
});

// ─── LLK-T32 — rerankRowsBySection: exact match floats to top ───────────────

Deno.test("LLK-T32 — rerankRowsBySection: §26 exact match overcomes sibling cosine lead", () => {
  // Simulates the production failure: HOL is the right act, but §6 (general
  // hyvän hallinnon perusteet) ranks above §26 (kielelliset oikeudet) by
  // cosine alone.
  const rows: LawSearchRpcRow[] = [
    makeRow({ id: "hol-§6-0", paragraph: "6", similarity: 0.88 }),
    makeRow({ id: "hol-§9-0", paragraph: "9", similarity: 0.84 }),
    makeRow({ id: "hol-§26-0", paragraph: "26", similarity: 0.79 }),
  ];

  const reranked = rerankRowsBySection(rows, "26");
  assertEquals(reranked[0].paragraph, "26", "§26 must float to top after rerank");
  // Original cosine order preserved among non-matches.
  assertEquals(reranked[1].paragraph, "6");
  assertEquals(reranked[2].paragraph, "9");
  // Similarity field itself is NOT mutated (boost is order-only).
  assertEquals(reranked[0].similarity, 0.79);
});

// ─── LLK-T33 — rerankRowsBySection: no target → preserves cosine order ──────

Deno.test("LLK-T33 — rerankRowsBySection: empty target preserves original order", () => {
  const rows: LawSearchRpcRow[] = [
    makeRow({ id: "a", paragraph: "6", similarity: 0.88 }),
    makeRow({ id: "b", paragraph: "26", similarity: 0.79 }),
  ];
  // Empty target → identity (semantic search undisturbed).
  const out = rerankRowsBySection(rows, "");
  assertEquals(out, rows);
  // Single-row arrays are trivially identity too.
  assertEquals(rerankRowsBySection([rows[0]], "26"), [rows[0]]);
});

// ─── LLK-T34 — rerankRowsBySection: partial match ranks below exact ─────────

Deno.test("LLK-T34 — rerankRowsBySection: partial match boosts less than exact", () => {
  // Query "§6" → exact match "6" must beat partial match "6a" (substring),
  // and partial must beat unrelated "9".
  const rows: LawSearchRpcRow[] = [
    makeRow({ id: "a", paragraph: "9", similarity: 0.90 }),
    makeRow({ id: "b", paragraph: "6a", similarity: 0.85 }),
    makeRow({ id: "c", paragraph: "6", similarity: 0.80 }),
  ];
  const out = rerankRowsBySection(rows, "6");
  assertEquals(out[0].paragraph, "6");   // exact: 0.80 + 1.0 = 1.80
  assertEquals(out[1].paragraph, "6a");  // partial: 0.85 + 0.5 = 1.35
  assertEquals(out[2].paragraph, "9");   // none: 0.90
  // Sanity: the boost constants we exposed actually drive this ordering.
  assertEquals(LEGAL_LOOKUP_SECTION_BOOST_EXACT > LEGAL_LOOKUP_SECTION_BOOST_PARTIAL, true);
});

// ─── LLK-T35 — legalLookup end-to-end: §-aware boost flips the top hit ──────

Deno.test("LLK-T35 — legalLookup: query with §26 ref promotes §26 to top hit", async () => {
  // The bug under test: cosine returns §6 first; we want §26 first when
  // the user explicitly asked about §26.
  const rows: LawSearchRpcRow[] = [
    makeRow({ id: "hol-§6-0",  paragraph: "6",  similarity: 0.88,
              body: "Hyvän hallinnon perusteet" }),
    makeRow({ id: "hol-§26-0", paragraph: "26", similarity: 0.79,
              body: "Kielelliset oikeudet" }),
  ];

  const result = await legalLookup(
    "hallintolain 26 § kielelliset oikeudet",
    "fi",
    {
      embed: okEmbed,
      lawSearch: rpcReturning(rows),
      fetchFreshness: freshnessReturning({
        "hol-§6-0": FRESH_REFRESHED,
        "hol-§26-0": FRESH_REFRESHED,
      }),
    },
    { now: () => FROZEN_NOW },
  );

  assertEquals(result.chunks.length, 2);
  assertEquals(result.chunks[0].paragraph, "26",
    "§26 should now lead the result for a §26-targeted query");
  // Similarity numbers we surface are still the underlying cosines, not the
  // boosted score. Important for the model's confidence display.
  assertEquals(result.chunks[0].similarity, 0.79);
});

// ─── LLK-T36 — legalLookup: query WITHOUT §ref → original cosine order ──────

Deno.test("LLK-T36 — legalLookup: query without § reference preserves cosine order", async () => {
  // Mirror of LLK-T35 but with a semantic query (no §). Must NOT rerank.
  // This guards against the rerank disrupting normal semantic search.
  const rows: LawSearchRpcRow[] = [
    makeRow({ id: "hol-§6-0",  paragraph: "6",  similarity: 0.88 }),
    makeRow({ id: "hol-§26-0", paragraph: "26", similarity: 0.79 }),
  ];

  const result = await legalLookup(
    "hallintolaki kielelliset oikeudet", // no § symbol → no rerank
    "fi",
    {
      embed: okEmbed,
      lawSearch: rpcReturning(rows),
      fetchFreshness: freshnessReturning({
        "hol-§6-0": FRESH_REFRESHED,
        "hol-§26-0": FRESH_REFRESHED,
      }),
    },
    { now: () => FROZEN_NOW },
  );

  assertEquals(result.chunks[0].paragraph, "6",
    "without explicit § ref the original cosine order must be preserved");
  assertEquals(result.chunks[1].paragraph, "26");
});

// ─── LLK-T37 — legalLookup: §-ref via specificStatute option also triggers rerank ─

Deno.test("LLK-T37 — legalLookup: specificStatute 'TsÜS §86' triggers rerank", async () => {
  // Query alone has no §-symbol, but specificStatute does. The implementation
  // must consider both inputs for section extraction.
  const rows: LawSearchRpcRow[] = [
    makeRow({ id: "ts-§5-0",  act_slug: "tsus", paragraph: "5",  similarity: 0.90 }),
    makeRow({ id: "ts-§86-0", act_slug: "tsus", paragraph: "86", similarity: 0.81 }),
  ];

  const result = await legalLookup(
    "hea usk",
    "ee",
    {
      embed: okEmbed,
      lawSearch: rpcReturning(rows),
      fetchFreshness: freshnessReturning({
        "ts-§5-0": FRESH_REFRESHED,
        "ts-§86-0": FRESH_REFRESHED,
      }),
    },
    { specificStatute: "TsÜS § 86", now: () => FROZEN_NOW },
  );

  assertEquals(result.chunks[0].paragraph, "86",
    "specificStatute hint must seed the section rerank");
  assertEquals(result.chunks[0].statute, "TSUS §86");
});

// =============================================================================
// Option B (2026-05-15) — Ajantasa license / display_policy snippet handling.
// Per business/legal/finlex_licensing_decision_2026-05-14.md: chunks marked
// display_policy='snippet_only' (Finlex CC-BY-NC ajantasa rows) must be
// truncated to 200 chars and surfaced with a Finlex link so the model
// (and any future UI) never reprints > 200 chars of consolidated text.
// =============================================================================

// ─── LLK-T38 — snippet_only chunk: 200-char truncate + link_required flag ────

Deno.test("LLK-T38 — display_policy='snippet_only' truncates to 200 chars + flag", async () => {
  const longBody = "A".repeat(800); // 4× the snippet cap; must be cut to 200
  const result = await legalLookup(
    "menetetyn määräajan palauttaminen",
    "fi",
    {
      embed: okEmbed,
      lawSearch: rpcReturning([
        makeRow({
          id: "oho-§114-0",
          act_slug: "fi-oho",
          paragraph: "114",
          body: longBody,
          source_url:
            "https://opendata.finlex.fi/finlex/avoindata/v1/akn/fi/" +
            "act/statute-consolidated/2019/808/fin@",
          // Cast — these fields will be added to LawSearchRpcRow below.
          license: "CC-BY-NC-4.0",
          display_policy: "snippet_only",
        } as Partial<LawSearchRpcRow>),
      ]),
      fetchFreshness: freshnessReturning({ "oho-§114-0": FRESH_REFRESHED }),
    },
    { now: () => FROZEN_NOW },
  );

  assertEquals(result.chunks.length, 1);
  const c = result.chunks[0];
  assertEquals(
    c.text.length,
    LEGAL_LOOKUP_SNIPPET_ONLY_MAX_CHARS,
    `snippet_only rows must truncate to ${LEGAL_LOOKUP_SNIPPET_ONLY_MAX_CHARS} chars`,
  );
  assertEquals(c.link_required, true);
  assertEquals(c.display_policy, "snippet_only");
  assertEquals(c.license, "CC-BY-NC-4.0");
});

// ─── LLK-T39 — public-domain chunk: full 700-char snippet, no link_required ──

Deno.test("LLK-T39 — display_policy='full' uses regular 700-char snippet cap", async () => {
  const longBody = "B".repeat(2000);
  const result = await legalLookup(
    "soveltamisala",
    "fi",
    {
      embed: okEmbed,
      lawSearch: rpcReturning([
        makeRow({
          id: "hol-§1-0",
          body: longBody,
          license: "public-domain",
          display_policy: "full",
        } as Partial<LawSearchRpcRow>),
      ]),
      fetchFreshness: freshnessReturning({ "hol-§1-0": FRESH_REFRESHED }),
    },
    { now: () => FROZEN_NOW },
  );

  assertEquals(result.chunks.length, 1);
  const c = result.chunks[0];
  assertEquals(c.text.length, LEGAL_LOOKUP_SNIPPET_MAX_CHARS);
  // link_required is opt-in; full-display rows are undefined OR false.
  assert(!c.link_required, "full-display chunks must NOT set link_required");
  assertEquals(c.display_policy, "full");
});

// ─── LLK-T40 — snippet_only constants are conservative (≤200) ───────────────

Deno.test("LLK-T40 — SNIPPET_ONLY_MAX_CHARS ≤ 200 (license-safe limit)", () => {
  // Hard ceiling per finlex_licensing_decision_2026-05-14.md §7. The 200-char
  // cap is the market-norm threshold for fair-dealing under Tekijänoikeuslaki
  // §22; raising it without owner sign-off is a licence-risk regression.
  assert(
    LEGAL_LOOKUP_SNIPPET_ONLY_MAX_CHARS <= 200,
    `SNIPPET_ONLY_MAX_CHARS must be ≤ 200, got ${LEGAL_LOOKUP_SNIPPET_ONLY_MAX_CHARS}`,
  );
  // And meaningfully shorter than the public-domain 700-char snippet — that
  // gap is what makes the policy enforceable: 200 ≠ 700 visibly.
  assert(LEGAL_LOOKUP_SNIPPET_ONLY_MAX_CHARS < LEGAL_LOOKUP_SNIPPET_MAX_CHARS);
});

// ─── LLK-T41 — missing license/display_policy → safe defaults ───────────────

Deno.test("LLK-T41 — RPC row without license/display_policy → public-domain/full defaults", async () => {
  // Tolerate older RPC signatures that pre-date the Option B columns. The
  // chunk surfaces conservative defaults (full + public-domain) so legacy
  // alkup rows continue to display unchanged.
  const longBody = "C".repeat(2000);
  const result = await legalLookup(
    "test",
    "fi",
    {
      embed: okEmbed,
      // makeRow's default has no license/display_policy → simulates v1 RPC.
      lawSearch: rpcReturning([makeRow({ body: longBody })]),
      fetchFreshness: freshnessReturning({ "hol-§114-0": FRESH_REFRESHED }),
    },
    { now: () => FROZEN_NOW },
  );

  const c = result.chunks[0];
  assertEquals(c.display_policy, "full");
  assertEquals(c.license, "public-domain");
  assertEquals(c.text.length, LEGAL_LOOKUP_SNIPPET_MAX_CHARS);
  assert(!c.link_required);
});

// ─── LLK-T42 — formatLookupResultForModel renders snippet-only link warning ─

Deno.test("LLK-T42 — formatter surfaces Finlex link + license warning for snippet_only", () => {
  const out = formatLookupResultForModel({
    chunks: [
      {
        statute: "OHO §114",
        act_slug: "fi-oho",
        paragraph: "114",
        text:
          "Korkein hallinto-oikeus voi palauttaa menetetyn määräajan sille, " +
          "joka laillisen esteen tai muun erittäin painavan syyn vuoksi...",
        similarity: 0.91,
        freshness_days: 5,
        source_url:
          "https://opendata.finlex.fi/finlex/avoindata/v1/akn/fi/" +
          "act/statute-consolidated/2019/808/fin@",
        license: "CC-BY-NC-4.0",
        display_policy: "snippet_only",
        link_required: true,
      },
    ],
    source: "corpus",
    embed_tokens: 14,
  });

  // Must include the Finlex URL.
  assertStringIncludes(out, "https://opendata.finlex.fi");
  // Must tell the model NOT to quote more than the returned snippet.
  assertStringIncludes(out, "snippet_only");
  // Must mention the link-required directive in human-readable form.
  assertStringIncludes(out, "Read full text on Finlex");
});

// ─── LLK-T43 — TOOL_USE_INSTRUCTION mentions snippet-only quotation rule ─────

Deno.test("LLK-T43 — TOOL_USE_INSTRUCTION mentions snippet_only + 200-char cap", () => {
  // The model needs to see explicit guidance not to quote > 200 chars from
  // snippet_only chunks. If this assertion fails, the runtime header drifted
  // from the licensing decision.
  assertStringIncludes(LEGAL_LOOKUP_TOOL_USE_INSTRUCTION, "snippet_only");
  assertStringIncludes(LEGAL_LOOKUP_TOOL_USE_INSTRUCTION, "200");
  assertStringIncludes(LEGAL_LOOKUP_TOOL_USE_INSTRUCTION, "Finlex");
  // Must remain under 2.5KB — the new clause adds ~400 chars; keep headroom.
  assert(
    LEGAL_LOOKUP_TOOL_USE_INSTRUCTION.length < 2560,
    `TOOL_USE_INSTRUCTION ${LEGAL_LOOKUP_TOOL_USE_INSTRUCTION.length} bytes ≥ 2560`,
  );
});

// ─── LLK-T44 — mixed batch: full + snippet_only chunks coexist correctly ────

Deno.test("LLK-T44 — mixed batch returns each chunk under its own policy", async () => {
  const longBody = "X".repeat(800);
  const result = await legalLookup(
    "deadlines",
    "fi",
    {
      embed: okEmbed,
      lawSearch: rpcReturning([
        // alkup row — full display, public-domain
        makeRow({
          id: "hol-§22-0",
          paragraph: "22",
          body: longBody,
          license: "public-domain",
          display_policy: "full",
        } as Partial<LawSearchRpcRow>),
        // ajantasa row — snippet only, CC-BY-NC
        makeRow({
          id: "oho-§114-0",
          act_slug: "fi-oho",
          paragraph: "114",
          body: longBody,
          license: "CC-BY-NC-4.0",
          display_policy: "snippet_only",
        } as Partial<LawSearchRpcRow>),
      ]),
      fetchFreshness: freshnessReturning({
        "hol-§22-0": FRESH_REFRESHED,
        "oho-§114-0": FRESH_REFRESHED,
      }),
    },
    { now: () => FROZEN_NOW },
  );

  assertEquals(result.chunks.length, 2);

  const full = result.chunks.find((c) => c.act_slug === "hol")!;
  const snippet = result.chunks.find((c) => c.act_slug === "fi-oho")!;

  assertEquals(full.display_policy, "full");
  assertEquals(full.text.length, LEGAL_LOOKUP_SNIPPET_MAX_CHARS);
  assert(!full.link_required);

  assertEquals(snippet.display_policy, "snippet_only");
  assertEquals(snippet.text.length, LEGAL_LOOKUP_SNIPPET_ONLY_MAX_CHARS);
  assertEquals(snippet.link_required, true);
});
