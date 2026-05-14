// Deno tests for credit_fallback (Anthropic $0 graceful degradation).
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/claude-proxy/__tests__/credit_fallback_test.ts
//
// Contract:
//   • isCreditBalanceError(400, "...credit balance...") → true
//   • isCreditBalanceError(400, "rate limit") → false
//   • isCreditBalanceError(500, "credit balance") → false  (only 400)
//   • buildRagOnlyResponse with embed+rpc fakes returns a banner + chunks
//   • buildRagOnlyResponse with zero hits returns banner + NO_CORPUS footer
//   • Streaming wrapper emits message_start..message_stop sequence
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertFalse,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  buildRagOnlyJsonResponse,
  buildRagOnlyResponse,
  buildRagOnlySseResponse,
  isCreditBalanceError,
  type RagChunk,
} from "../credit_fallback.ts";

// =============================================================================
// 1. isCreditBalanceError
// =============================================================================

Deno.test("CF-T01 — 400 with 'credit balance' in body returns true", () => {
  const body = JSON.stringify({
    error: {
      type: "invalid_request_error",
      message: "Your credit balance is too low to access the Anthropic API",
    },
  });
  assert(isCreditBalanceError(400, body));
});

Deno.test("CF-T02 — 400 with 'Credit Balance' (mixed case) returns true", () => {
  assert(isCreditBalanceError(400, "Your Credit Balance is empty."));
});

Deno.test("CF-T03 — 400 with unrelated error returns false", () => {
  assert(!isCreditBalanceError(400, '{"error":"invalid_api_key"}'));
});

Deno.test("CF-T04 — 500 with 'credit balance' returns false (status gate)", () => {
  assertFalse(isCreditBalanceError(500, "credit balance too low"));
});

Deno.test("CF-T05 — empty body returns false", () => {
  assertFalse(isCreditBalanceError(400, ""));
});

// =============================================================================
// 2. buildRagOnlyResponse with happy-path fakes
// =============================================================================

const HAPPY_ROWS: RagChunk[] = [
  {
    act_slug: "perustuslaki",
    act_name: "Suomen perustuslaki",
    paragraph: "10",
    title: "Yksityiselämän suoja",
    body:
      "Jokaisen yksityiselämä, kunnia ja kotirauha on turvattu. Henkilötietojen suojasta säädetään tarkemmin lailla.",
    source_url: "https://www.finlex.fi/fi/laki/ajantasa/1999/19990731",
    similarity: 0.82,
  },
  {
    act_slug: "perustuslaki",
    act_name: "Suomen perustuslaki",
    paragraph: "21",
    title: "Oikeusturva",
    body: "Jokaisella on oikeus saada asiansa käsitellyksi asianmukaisesti.",
    source_url: "https://www.finlex.fi/fi/laki/ajantasa/1999/19990731",
    similarity: 0.71,
  },
];

function fakeEmbed() {
  return async (_q: string) => ({
    embedding: new Array(1536).fill(0.001),
    tokens: 7,
  });
}

function fakeLawSearch(rows: RagChunk[]) {
  return async (_params: unknown) => rows;
}

Deno.test("CF-T06 — happy path renders banner + 2 chunks + restore footer", async () => {
  const result = await buildRagOnlyResponse(
    "Mitä sanoo perustuslaki §10?",
    {
      embed: fakeEmbed(),
      lawSearch: fakeLawSearch(HAPPY_ROWS),
    },
    { jurisdiction: "FI" },
  );

  assertEquals(result.chunkCount, 2);
  assertEquals(result.caseCount, 0);
  assertFalse(result.emptyCorpus);

  // Banner present
  assertStringIncludes(result.text, "AI generation temporarily unavailable");
  // Chunk 1 rendered
  assertStringIncludes(result.text, "PERUSTUSLAKI §10");
  assertStringIncludes(result.text, "Yksityiselämän suoja");
  assertStringIncludes(result.text, "Jokaisen yksityiselämä");
  // Source URL surfaced
  assertStringIncludes(result.text, "finlex.fi");
  // Chunk 2 rendered
  assertStringIncludes(result.text, "PERUSTUSLAKI §21");
  // Restore footer
  assertStringIncludes(result.text, "AI generation is restored");
});

Deno.test("CF-T07 — empty corpus returns NO_CORPUS footer", async () => {
  const result = await buildRagOnlyResponse(
    "Some arbitrary legal question",
    {
      embed: fakeEmbed(),
      lawSearch: fakeLawSearch([]),
    },
    { jurisdiction: "FI" },
  );

  assertEquals(result.chunkCount, 0);
  assert(result.emptyCorpus);
  assertStringIncludes(result.text, "AI generation temporarily unavailable");
  // Should NOT include any "PERUSTUSLAKI" or "📖" since no chunks
  assertFalse(result.text.includes("📖"));
});

Deno.test("CF-T08 — empty query short-circuits before embed", async () => {
  let embedCalls = 0;
  const result = await buildRagOnlyResponse(
    "   ",
    {
      embed: async () => {
        embedCalls++;
        return { embedding: [], tokens: 0 };
      },
      lawSearch: fakeLawSearch([]),
    },
  );
  assertEquals(embedCalls, 0, "embed must not be called for empty query");
  assertEquals(result.chunkCount, 0);
  assert(result.emptyCorpus);
});

Deno.test("CF-T09 — embed failure returns NO_EMBED footer", async () => {
  const result = await buildRagOnlyResponse(
    "test",
    {
      embed: async () => null,
      lawSearch: fakeLawSearch(HAPPY_ROWS),
    },
  );
  assertEquals(result.chunkCount, 0);
  assert(result.emptyCorpus);
  // Should hint at retry
  assertStringIncludes(result.text, "muutaman");
});

Deno.test("CF-T10 — cases_citing rows decorate top hit", async () => {
  const result = await buildRagOnlyResponse(
    "perustuslaki 10",
    {
      embed: fakeEmbed(),
      lawSearch: fakeLawSearch(HAPPY_ROWS),
      casesCiting: async () => [
        {
          case_number: "2024:30",
          court: "KHO",
          decided_at: "2024-03-15",
          key_holding: "valituslupahakemus mechanics clarified",
        },
      ],
    },
  );
  assertEquals(result.caseCount, 1);
  assertStringIncludes(result.text, "Related court cases");
  assertStringIncludes(result.text, "KHO 2024:30");
  assertStringIncludes(result.text, "valituslupahakemus");
});

Deno.test("CF-T11 — unsupported jurisdiction defaults to FI", async () => {
  let capturedJur: string | null = null;
  const result = await buildRagOnlyResponse(
    "test",
    {
      embed: fakeEmbed(),
      lawSearch: async (params) => {
        capturedJur = (params as { query_jurisdiction: string }).query_jurisdiction;
        return HAPPY_ROWS;
      },
    },
    { jurisdiction: "JP" }, // not in whitelist
  );
  assertEquals(capturedJur, "FI");
  assertEquals(result.chunkCount, 2);
});

// =============================================================================
// 3. Response builders
// =============================================================================

Deno.test("CF-T12 — buildRagOnlyJsonResponse returns 200 + assistant content", async () => {
  const resp = buildRagOnlyJsonResponse(
    {
      text: "Test reply",
      chunkCount: 1,
      caseCount: 0,
      emptyCorpus: false,
    },
    { messageId: "11111111-1111-1111-1111-111111111111" },
  );
  assertEquals(resp.status, 200);
  assertEquals(
    resp.headers.get("X-Advocat-Model-Used"),
    "rag-only-fallback",
  );
  const body = await resp.json();
  assertEquals(body.role, "assistant");
  assertEquals(body.model_used, "rag-only-fallback");
  assertEquals(body.fallback_reason, "anthropic_credit_exhausted");
  assertEquals(body.content[0].text, "Test reply");
  assertEquals(body.message_id, "11111111-1111-1111-1111-111111111111");
});

Deno.test("CF-T13 — buildRagOnlySseResponse emits message_start..message_stop", async () => {
  const resp = buildRagOnlySseResponse(
    {
      text: "Hello world",
      chunkCount: 1,
      caseCount: 0,
      emptyCorpus: false,
    },
  );
  assertEquals(resp.status, 200);
  assertEquals(resp.headers.get("Content-Type"), "text/event-stream");
  const text = await resp.text();
  assertStringIncludes(text, "event: message_start");
  assertStringIncludes(text, "event: content_block_start");
  assertStringIncludes(text, "event: content_block_delta");
  assertStringIncludes(text, "Hello world");
  assertStringIncludes(text, "event: content_block_stop");
  assertStringIncludes(text, "event: message_delta");
  assertStringIncludes(text, "event: message_stop");
  assertStringIncludes(text, "event: citations");
});

// =============================================================================
// 4. Source-code contract: index.ts wires the fallback
// =============================================================================

Deno.test("CF-T14 — claude-proxy/index.ts imports credit_fallback hooks", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  assertStringIncludes(source, "isCreditBalanceError");
  assertStringIncludes(source, "buildRagOnlyResponse");
  assertStringIncludes(source, "buildEmbedFn");
  assertStringIncludes(source, "runCreditExhaustedFallback");
});

Deno.test("CF-T15 — claude-proxy/index.ts tightens free-tier limits", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  // Constants must match the 2026-05-13 tighten.
  assertStringIncludes(source, "const RATE_LIMIT_MAX = 5;");
  assertStringIncludes(source, "const ANON_RATE_LIMIT_PER_MINUTE = 1;");
  assertStringIncludes(source, "const ANON_MAX_TOKENS = 200;");
});
