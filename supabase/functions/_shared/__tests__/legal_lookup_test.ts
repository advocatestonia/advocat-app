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
  type EmbedQueryFn,
  type FetchFreshnessFn,
  formatLookupResultForModel,
  formatStatute,
  type LawSearchRpcFn,
  type LawSearchRpcRow,
  LEGAL_LOOKUP_MATCH_COUNT,
  LEGAL_LOOKUP_MAX_RESPONSE_BYTES,
  LEGAL_LOOKUP_SIMILARITY_THRESHOLD,
  LEGAL_LOOKUP_SNIPPET_MAX_CHARS,
  LEGAL_LOOKUP_STALE_THRESHOLD_DAYS,
  legalLookup,
  LegalLookupConfigError,
  type LiveFallbackFn,
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
