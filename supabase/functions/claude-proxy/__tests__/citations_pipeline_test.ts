// Deno tests for Phase 2 Pkg 2 — citations pipeline wiring in claude-proxy.
// -----------------------------------------------------------------------------
// We pin two seams of the pipeline statically (no need to spin up a real edge
// runtime):
//   1. The verifier module is importable from `_shared/citation_grounder.ts`.
//   2. claude-proxy/index.ts imports the helpers, strips `rag_context` from
//      the body BEFORE forwarding, and augments the response with `citations`.
//
// We deliberately match against source text rather than running the function
// — the existing `active_case_injection_test.ts` uses the same pattern
// (CM-T50/T51/T52). It's load-bearing: it pins the wire contract without
// pulling in a live Supabase + Anthropic stack.
//
// Run with:
//   deno test --allow-read \
//     supabase/functions/claude-proxy/__tests__/citations_pipeline_test.ts
// -----------------------------------------------------------------------------

import {
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  concatAnthropicTextBlocks,
  extractRagContext,
  verifyCitations,
} from "../../_shared/citation_grounder.ts";

// ── Verifier wiring contract: source-text pin ────────────────────────────────

Deno.test("CIT-T01 — index.ts imports the verifier from _shared", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  assertStringIncludes(source, "../_shared/citation_grounder.ts");
  assertStringIncludes(source, "verifyCitations");
  assertStringIncludes(source, "extractRagContext");
});

Deno.test("CIT-T02 — rag_context is stripped BEFORE the Anthropic fetch", async () => {
  // The pipeline order is load-bearing: extractRagContext() must run before
  // the `fetch("https://api.anthropic.com/v1/messages", ...)` call so the
  // proxy-only field never reaches Anthropic. We pin the textual order in
  // the source to keep this guarantee under code review.
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  const stripped = source
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .replace(/^\s*\/\/.*$/gm, "");
  const extractIdx = stripped.indexOf("extractRagContext(");
  const fetchIdx = stripped.indexOf("api.anthropic.com/v1/messages");
  if (extractIdx === -1 || fetchIdx === -1) {
    throw new Error("Citations pipeline contract points missing in index.ts");
  }
  if (extractIdx >= fetchIdx) {
    throw new Error(
      "extractRagContext must run BEFORE the Anthropic fetch — otherwise " +
        "rag_context would leak into the upstream call.",
    );
  }
});

Deno.test("CIT-T03 — verifier runs AFTER the Anthropic response is parsed", async () => {
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  const stripped = source
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .replace(/^\s*\/\/.*$/gm, "");
  const fetchIdx = stripped.indexOf("api.anthropic.com/v1/messages");
  // Find the FIRST verifyCitations call AFTER the Anthropic fetch.
  const afterFetch = stripped.slice(fetchIdx);
  const verifyIdxRel = afterFetch.indexOf("verifyCitations(");
  if (verifyIdxRel < 0) {
    throw new Error("verifyCitations must be invoked after the Anthropic fetch");
  }
});

Deno.test("CIT-T04 — augmented response payload includes a citations field", async () => {
  // The proxy returns the Anthropic JSON augmented with `citations`. We pin
  // the textual marker in source so the response-shape contract holds.
  const source = await Deno.readTextFile(
    new URL("../index.ts", import.meta.url),
  );
  // Field name appears in the response-build call.
  assertStringIncludes(source, "citations");
});

// ── Verifier behaviour pin (sanity, in addition to grounder unit tests) ──────

Deno.test("CIT-T05 — concatAnthropicTextBlocks joins text blocks only", () => {
  const content = [
    { type: "text", text: "First [[ref:TLS:88]]" },
    { type: "tool_use", id: "tu_1", name: "search_estonian_law", input: {} },
    { type: "text", text: "Second segment." },
  ];
  const out = concatAnthropicTextBlocks(content);
  assertStringIncludes(out, "[[ref:TLS:88]]");
  assertStringIncludes(out, "Second segment.");
  // tool_use block contributed nothing.
  assertEquals(out.includes("search_estonian_law"), false);
});

Deno.test("CIT-T06 — extractRagContext mutates body and returns chunks", () => {
  const body: Record<string, unknown> = {
    model: "claude-haiku-4-5-20251001",
    system: "You are Advocat",
    rag_context: {
      chunks: [
        {
          id: "tls-§88-1",
          act_slug: "tls",
          paragraph: "88",
          act_name: "Töölepingu seadus",
          body: "Tööandja võib lepingu erakorraliselt üles öelda…",
          source_url: "https://www.riigiteataja.ee/akt/tls",
          jurisdiction: "EE",
          in_force: true,
        },
      ],
    },
  };
  const chunks = extractRagContext(body);
  assertEquals(chunks.length, 1);
  assertEquals(chunks[0].id, "tls-§88-1");
  // Field stripped from body so it never reaches Anthropic.
  assertEquals(Object.prototype.hasOwnProperty.call(body, "rag_context"), false);
});

Deno.test("CIT-T07 — extractRagContext is tolerant of missing/malformed input", () => {
  assertEquals(extractRagContext({}).length, 0);
  assertEquals(extractRagContext({ rag_context: null }).length, 0);
  assertEquals(extractRagContext({ rag_context: { chunks: "not-array" } }).length, 0);
  // Even a malformed rag_context still gets removed from the body.
  const body: Record<string, unknown> = { rag_context: 42 };
  extractRagContext(body);
  assertEquals(Object.prototype.hasOwnProperty.call(body, "rag_context"), false);
});

Deno.test("CIT-T08 — full pipeline round-trip: chunk → marker → verified citation", () => {
  const body: Record<string, unknown> = {
    rag_context: {
      chunks: [
        {
          id: "tls-§88-1",
          act_slug: "tls",
          paragraph: "88",
          act_name: "Töölepingu seadus",
          title: "Tööandja erakorraline ülesütlemine",
          body: "Tööandja võib töölepingu erakorraliselt üles öelda…",
          source_url: "https://www.riigiteataja.ee/akt/tls",
          jurisdiction: "EE",
          in_force: true,
        },
      ],
    },
  };
  const chunks = extractRagContext(body);
  const fakeAnthropicReply = [
    { type: "text", text: "Põhjendatud ülesütlemine [[ref:TLS:88]] on õiguspärane." },
  ];
  const replyText = concatAnthropicTextBlocks(fakeAnthropicReply);
  const citations = verifyCitations(replyText, chunks);
  assertEquals(citations.length, 1);
  assertEquals(citations[0].status, "verified");
  assertEquals(citations[0].chunk_id, "tls-§88-1");
});
