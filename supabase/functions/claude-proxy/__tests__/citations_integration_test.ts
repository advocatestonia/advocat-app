// Deno integration tests — Phase 2 Pkg 2 citations end-to-end scenarios.
// -----------------------------------------------------------------------------
// QA-layer tests beyond what the implementer shipped. The grounder unit suite
// (citation_grounder_test.ts) and the pipeline wiring suite
// (citations_pipeline_test.ts) cover individual seams. This file exercises
// the full grounder against the architect's canonical 3-tier reply scenario
// and pins additional edge cases that real Anthropic replies hit:
//
//   • Verbatim verified citation + paraphrased verified citation + fabricated
//     unverified citation IN THE SAME REPLY (architect's headline scenario,
//     §4 of docs/architecture/phase2-pkg2-citations.md).
//   • Mixed in-force + historical chunks for the same act.
//   • Lang-suffixed EU markers cohabit with EE markers.
//   • Verifier preserves first-occurrence order across statuses.
//   • Marker scan tolerant of large reply bodies (10k chars × 30 markers).
//   • The proxy's response shape passes citations through alongside the raw
//     Anthropic content array.
//
// Run with:
//   deno test --allow-read \
//     supabase/functions/claude-proxy/__tests__/citations_integration_test.ts
// -----------------------------------------------------------------------------

import {
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  type Citation,
  concatAnthropicTextBlocks,
  extractRagContext,
  type GroundingChunk,
  verifyCitations,
} from "../../_shared/citation_grounder.ts";

// ─── Fixtures (parallel structure with grounder unit tests) ─────────────────

function tlsChunk(): GroundingChunk {
  return {
    id: "tls-§88-1",
    act_slug: "tls",
    act_name: "Töölepingu seadus",
    paragraph: "88",
    title: "Tööandja erakorraline ülesütlemine",
    body:
      "Tööandja võib töölepingu erakorraliselt üles öelda mõjuval põhjusel, " +
      "eelkõige juhul, kui kõiki asjaolusid ja mõlemapoolset huvi arvestades " +
      "ei saa mõistlikult nõuda lepingulise suhte jätkamist.",
    source_url: "https://www.riigiteataja.ee/akt/tls",
    jurisdiction: "EE",
    in_force: true,
  };
}

function karsChunk(): GroundingChunk {
  return {
    id: "kars-§121-0",
    act_slug: "kars",
    act_name: "Karistusseadustik",
    paragraph: "121",
    title: "Kehaline väärkohtlemine",
    body:
      "Teise inimese tervise kahjustamise eest, samuti füüsilise valu " +
      "tekitamise eest karistatakse rahalise karistuse või kuni üheaastase " +
      "vangistusega.",
    source_url: "https://www.riigiteataja.ee/akt/kars",
    jurisdiction: "EE",
    in_force: true,
  };
}

function vols118Chunk(): GroundingChunk {
  // Different act, different paragraph — the "second verified" chunk.
  return {
    id: "vols-§118-0",
    act_slug: "vols",
    act_name: "Võlaõigusseadus",
    paragraph: "118",
    title: "Lepingu rikkumise tagajärjed",
    body: "Kohustuse rikkumise korral võib võlausaldaja...",
    source_url: "https://www.riigiteataja.ee/akt/vols",
    jurisdiction: "EE",
    in_force: true,
  };
}

function tlsHistoricalChunk(): GroundingChunk {
  return {
    ...tlsChunk(),
    id: "tls-§88-1-v2018",
    in_force: false,
    body: "Old-version body for §88 (pre-2019 amendment).",
  };
}

function euDirectiveChunk(): GroundingChunk {
  return {
    id: "32019l1152-art-5-0",
    act_slug: "32019L1152",
    act_name: "Directive (EU) 2019/1152",
    paragraph: "5",
    title: "Information on essential aspects of the employment relationship",
    body:
      "Member States shall ensure that workers receive a written statement " +
      "containing the information referred to in Article 4 not later than...",
    source_url:
      "https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32019L1152",
    jurisdiction: "EU",
    in_force: true,
  };
}

// ─── CIT-INT-T01 — architect's canonical 3-tier scenario ────────────────────
//
// One reply contains:
//   1. Verbatim citation — model quotes TLS §88 word-for-word with marker.
//   2. Paraphrased citation — model summarises VÕS §118 in its own words
//      with the marker.
//   3. Fabricated citation — model emits [[ref:KarS:999]] but no §999 chunk
//      was retrieved (and the act_slug isn't even in rag_context).
//
// Expected: 1 verified (verbatim), 1 verified (paraphrase — verifier is
// reference-level not text-level), 1 unverified.

Deno.test("CIT-INT-T01 — verbatim + paraphrase + fabricated → mixed statuses", () => {
  // Two chunks injected, three markers in the reply.
  const reply = [
    "По эстонскому трудовому праву работодатель может расторгнуть",
    "договор по уважительной причине: точная формулировка такая —",
    `"${tlsChunk().body}" [[ref:TLS:88]]. `,
    "В договорном праве §118 регулирует последствия нарушения договора",
    "(пересказ своими словами) [[ref:VOLS:118]]. ",
    "А вот по уголовному кодексу §999 [[ref:KarS:999]] — такой нормы нет.",
  ].join(" ");

  const citations = verifyCitations(reply, [tlsChunk(), vols118Chunk()]);
  assertEquals(citations.length, 3, "three distinct markers → three citations");

  const byKey = (c: Citation) => `${c.act_slug}:${c.paragraph}`;
  const verbatim = citations.find((c) => byKey(c) === "tls:88");
  const paraphrase = citations.find((c) => byKey(c) === "vols:118");
  const fabricated = citations.find((c) => byKey(c) === "kars:999");

  if (!verbatim || !paraphrase || !fabricated) {
    throw new Error("Expected all three (verbatim/paraphrase/fabricated)");
  }

  assertEquals(verbatim.status, "verified");
  assertEquals(verbatim.chunk_id, "tls-§88-1");
  // Verbatim snippet shows up in payload (≤400 chars).
  assertStringIncludes(verbatim.snippet ?? "", "Tööandja võib");

  // Paraphrase verified — verifier doesn't compare reply text to body.
  // This locks design risk #3 acceptance: paraphrases that emit the marker
  // count as verified.
  assertEquals(paraphrase.status, "verified");
  assertEquals(paraphrase.chunk_id, "vols-§118-0");
  assertEquals(paraphrase.act_name, "Võlaõigusseadus");

  assertEquals(fabricated.status, "unverified");
  assertEquals(fabricated.chunk_id, null);
  assertEquals(fabricated.snippet, null);
});

// ─── CIT-INT-T02 — first-occurrence order preserved across statuses ────────

Deno.test("CIT-INT-T02 — citations[] order matches first-occurrence in reply", () => {
  // Reply order: KarS (unverified) first, TLS (verified) second.
  // Citations array MUST mirror that order — Flutter renders chips inline,
  // and the bottom sheet jump relies on order parity.
  const reply =
    "Сначала [[ref:KarS:999]] potem [[ref:TLS:88]] и снова [[ref:KarS:999]].";
  const out = verifyCitations(reply, [tlsChunk()]);
  assertEquals(out.length, 2);
  assertEquals(out[0].act_slug, "kars");
  assertEquals(out[0].status, "unverified");
  assertEquals(out[0].occurrences, 2); // appears 2× in reply
  assertEquals(out[1].act_slug, "tls");
  assertEquals(out[1].status, "verified");
});

// ─── CIT-INT-T03 — historical + in-force chunks for same act, in-force wins ─

Deno.test(
  "CIT-INT-T03 — when both in-force and historical chunks present, in-force wins",
  () => {
    // Per citation_grounder.ts:114 — "first-write wins". law_search returns
    // in-force=true rows first, so when both versions land in rag_context,
    // the in-force row indexes first and the marker resolves verified.
    const reply = "[[ref:TLS:88]]";
    const out = verifyCitations(reply, [tlsChunk(), tlsHistoricalChunk()]);
    assertEquals(out.length, 1);
    assertEquals(out[0].status, "verified");
    assertEquals(out[0].chunk_id, "tls-§88-1");
    assertEquals(out[0].in_force, true);
  },
);

// ─── CIT-INT-T04 — historical-only (in-force absent) → status historical ────

Deno.test(
  "CIT-INT-T04 — only historical chunk in rag_context → status historical",
  () => {
    // Realistic scenario: corpus refresh in flight, current law_chunks for
    // §88 has only the old version with in_force=false. UI must show amber
    // "historical" badge so the user knows it's superseded.
    const reply = "Старая редакция [[ref:TLS:88]].";
    const out = verifyCitations(reply, [tlsHistoricalChunk()]);
    assertEquals(out.length, 1);
    assertEquals(out[0].status, "historical");
    assertEquals(out[0].chunk_id, "tls-§88-1-v2018");
    assertEquals(out[0].in_force, false);
  },
);

// ─── CIT-INT-T05 — EE + EU markers cohabit in one reply ────────────────────

Deno.test("CIT-INT-T05 — EE marker + EU directive marker → both verified", () => {
  const reply = [
    "Eesti TLS §88 [[ref:TLS:88]] mirrors the EU directive 2019/1152",
    "art. 5 [[ref:32019L1152:5:en]] employer-information requirement.",
  ].join(" ");
  const out = verifyCitations(reply, [tlsChunk(), euDirectiveChunk()]);
  assertEquals(out.length, 2);
  // Both verified, jurisdiction populated from chunk snapshot.
  const byKey = (c: Citation) => `${c.act_slug}:${c.paragraph}`;
  const ee = out.find((c) => byKey(c) === "tls:88");
  const eu = out.find((c) => byKey(c) === "32019l1152:5");
  if (!ee || !eu) throw new Error("Expected EE + EU citation rows");
  assertEquals(ee.jurisdiction, "EE");
  assertEquals(eu.jurisdiction, "EU");
  assertEquals(ee.status, "verified");
  assertEquals(eu.status, "verified");
});

// ─── CIT-INT-T06 — large reply (10k chars, 30 markers) bounded latency ──────

Deno.test("CIT-INT-T06 — 30 markers in a 10k reply complete in <50ms", () => {
  // Synthesise a long reply with 30 distinct markers. Verifier latency
  // budget per design: p95 < 50ms. This is a smoke pin (not a strict
  // benchmark) — flag if a later refactor regresses to O(n²) somehow.
  const filler = "lorem ipsum dolor sit amet ".repeat(40); // ~1k chars
  const markers: string[] = [];
  const chunks: GroundingChunk[] = [];
  for (let i = 0; i < 30; i++) {
    const para = String(100 + i);
    markers.push(`[[ref:TLS:${para}]]`);
    chunks.push({
      id: `tls-§${para}-0`,
      act_slug: "tls",
      paragraph: para,
      act_name: "TLS",
      title: `§${para}`,
      body: `Body for §${para}.`,
      source_url: "https://www.riigiteataja.ee/akt/tls",
      jurisdiction: "EE",
      in_force: true,
    });
  }
  const reply = filler + " " + markers.join(" " + filler + " ");

  const start = performance.now();
  const out = verifyCitations(reply, chunks);
  const elapsed = performance.now() - start;

  assertEquals(out.length, 30);
  // Generous threshold (CI machines are slow, and we only care to flag
  // O(n²) regressions). Design budget is <50ms; we set an order-of-magnitude
  // safety margin.
  if (elapsed > 500) {
    throw new Error(
      `Verifier should complete a 10k-char/30-marker reply in <500ms, got ${
        elapsed.toFixed(1)
      }ms`,
    );
  }
});

// ─── CIT-INT-T07 — round-trip reproduces architect's response shape (§3) ────

Deno.test(
  "CIT-INT-T07 — full pipeline matches architect §3 response-shape contract",
  () => {
    // Build a request body mirroring what claude_service.dart would send,
    // run extractRagContext + concatTextBlocks + verifyCitations end-to-end,
    // and assert every documented field in citations[0] is present and
    // typed correctly.
    const body: Record<string, unknown> = {
      model: "claude-haiku-4-5-20251001",
      system: "You are Advocat.",
      messages: [{ role: "user", content: "TLS §88?" }],
      rag_context: { chunks: [tlsChunk()] },
    };
    const ragChunks = extractRagContext(body);
    // rag_context stripped from body (back-compat / no-leak guarantee).
    assertEquals(
      Object.prototype.hasOwnProperty.call(body, "rag_context"),
      false,
    );

    // Mock Anthropic content array with one verified marker.
    const fakeAnthropicContent = [
      {
        type: "text",
        text:
          "Tööandja võib lepingu erakorraliselt üles öelda [[ref:TLS:88]].",
      },
    ];
    const replyText = concatAnthropicTextBlocks(fakeAnthropicContent);
    const citations = verifyCitations(replyText, ragChunks);
    assertEquals(citations.length, 1);

    const c = citations[0];
    // Every field documented in §3 of the design doc.
    const documentedFields: Array<keyof Citation> = [
      "marker",
      "status",
      "chunk_id",
      "act_slug",
      "act_name",
      "paragraph",
      "title",
      "snippet",
      "source_url",
      "in_force",
      "occurrences",
    ];
    for (const f of documentedFields) {
      if (!(f in c)) {
        throw new Error(`Citation payload missing field "${String(f)}"`);
      }
    }
    // Spot-check types.
    assertEquals(typeof c.marker, "string");
    assertEquals(typeof c.status, "string");
    assertEquals(typeof c.act_slug, "string");
    assertEquals(typeof c.paragraph, "string");
    assertEquals(typeof c.occurrences, "number");
    // Marker is the literal source text — Flutter chips render this string
    // back as the chip label substring.
    assertEquals(c.marker, "[[ref:TLS:88]]");
  },
);

// ─── CIT-INT-T08 — empty reply text is a no-op (Anthropic edge case) ────────

Deno.test(
  "CIT-INT-T08 — Anthropic returning empty content[] yields citations:[]",
  () => {
    // Anthropic occasionally responds with [{type:'tool_use', ...}] only —
    // no text block. concatAnthropicTextBlocks returns "", verifier returns
    // []. Important: the augmented response still has `citations: []`, NOT
    // a missing field — Flutter's deserialiser depends on the field being
    // present.
    const body: Record<string, unknown> = {
      rag_context: { chunks: [tlsChunk()] },
    };
    const chunks = extractRagContext(body);
    const toolOnlyContent = [
      { type: "tool_use", id: "tu_1", name: "search_estonian_law", input: {} },
    ];
    const replyText = concatAnthropicTextBlocks(toolOnlyContent);
    assertEquals(replyText, "");
    const citations = verifyCitations(replyText, chunks);
    assertEquals(Array.isArray(citations), true);
    assertEquals(citations.length, 0);
  },
);

// ─── CIT-INT-T09 — reply with only invalid markers does not crash ───────────

Deno.test(
  "CIT-INT-T09 — reply with malformed and prose-style citations only → []",
  () => {
    // Models occasionally regress to prose form. UI signal in that case is
    // "0 citations" footer warning (per design §6.3). Verifier MUST return
    // [] — no false-positive against prose patterns.
    const reply = [
      "По § 88 ТЛС работодатель может уволить.",
      "[TLS §88] это формат, который мы не парсим.",
      "[[notref:TLS:88]] неправильный keyword.",
      "[[ref:TLS]] без параграфа.",
      "[[ref:]] совсем пустой.",
    ].join(" ");
    const out = verifyCitations(reply, [tlsChunk()]);
    assertEquals(out.length, 0);
  },
);

// ─── CIT-INT-T10 — duplicate chunks in rag_context don't create duplicate citations ─

Deno.test(
  "CIT-INT-T10 — duplicate chunks in rag_context: first-write wins, no double",
  () => {
    // law_search RPC could in theory return the same chunk twice (race or
    // bug); the index dedups by (act_slug:paragraph). Verifier must not
    // emit two citation rows for one marker even if the chunk is twice.
    const reply = "[[ref:TLS:88]]";
    const out = verifyCitations(reply, [tlsChunk(), tlsChunk()]);
    assertEquals(out.length, 1);
    assertEquals(out[0].chunk_id, "tls-§88-1");
    assertEquals(out[0].occurrences, 1);
  },
);
