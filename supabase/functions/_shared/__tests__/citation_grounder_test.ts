// Deno TDD — Phase 2 Pkg 2 grounding verifier (_shared/citation_grounder.ts).
// -----------------------------------------------------------------------------
// Pure-module contract tests. Mirrors §4 of
// docs/architecture/phase2-pkg2-citations.md and §8 of the same brief. The
// verifier is intentionally pure (regex + in-memory map) so it can be exercised
// here without a Supabase / Anthropic mock.
//
// Run with:
//   deno test --allow-read \
//     supabase/functions/_shared/__tests__/citation_grounder_test.ts
// -----------------------------------------------------------------------------

import {
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  CITATION_MARKER_PATTERN,
  type Citation,
  type GroundingChunk,
  verifyCitations,
} from "../citation_grounder.ts";

// ─── Fixtures ───────────────────────────────────────────────────────────────

function tlsChunk(): GroundingChunk {
  return {
    id: "tls-§88-1",
    act_slug: "tls",
    act_name: "Töölepingu seadus",
    paragraph: "88",
    title: "Tööandja erakorraline ülesütlemine",
    body:
      "Tööandja võib töölepingu erakorraliselt üles öelda mõjuval põhjusel. " +
      "Seadusest tuleneva piirangu rikkumine on tühine.",
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
    body: "Teise inimese tervise kahjustamise eest karistatakse...",
    source_url: "https://www.riigiteataja.ee/akt/kars",
    jurisdiction: "EE",
    in_force: true,
  };
}

function historicalTlsChunk(): GroundingChunk {
  // Same act/paragraph as in-force version but flagged historical (in_force = false).
  return {
    ...tlsChunk(),
    id: "tls-§88-1-v2019",
    in_force: false,
  };
}

function euDirectiveChunk(): GroundingChunk {
  return {
    id: "32019l1152-art-5-0",
    act_slug: "32019L1152",
    act_name: "Directive (EU) 2019/1152",
    paragraph: "5",
    title: "Information on essential aspects of the employment relationship",
    body: "Member States shall ensure ...",
    source_url:
      "https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32019L1152",
    jurisdiction: "EU",
    in_force: true,
  };
}

// ─── CGRD-T01 — verbatim verified marker ────────────────────────────────────

Deno.test("CGRD-T01 — verbatim marker matches retrieved chunk → verified", () => {
  const reply =
    "Tööandja võib lepingu erakorraliselt üles öelda [[ref:TLS:88]] " +
    "kui esineb mõjuv põhjus.";
  const out = verifyCitations(reply, [tlsChunk()]);
  assertEquals(out.length, 1);
  const [c] = out;
  assertEquals(c.status, "verified");
  assertEquals(c.chunk_id, "tls-§88-1");
  assertEquals(c.act_slug, "tls");
  assertEquals(c.paragraph, "88");
  assertEquals(c.act_name, "Töölepingu seadus");
  assertEquals(c.in_force, true);
  assertEquals(c.occurrences, 1);
  // Snippet ≤ 400 chars (taken from chunk.body verbatim head).
  assertStringIncludes(c.snippet ?? "", "Tööandja võib töölepingu");
  if ((c.snippet?.length ?? 0) > 400) {
    throw new Error(`snippet must be ≤400 chars, got ${c.snippet?.length}`);
  }
  assertEquals(c.source_url, "https://www.riigiteataja.ee/akt/tls");
});

// ─── CGRD-T02 — paraphrase still verified (reference-level, not text-level) ──

Deno.test("CGRD-T02 — paraphrased reply with correct marker → verified", () => {
  // Model paraphrases TLS §88 but emits the marker → still verified.
  const reply =
    "Под §88 закона о труде работодатель может уволить работника по уважительной причине [[ref:TLS:88]].";
  const out = verifyCitations(reply, [tlsChunk()]);
  assertEquals(out.length, 1);
  assertEquals(out[0].status, "verified");
  assertEquals(out[0].chunk_id, "tls-§88-1");
});

// ─── CGRD-T03 — marker without retrieved chunk → unverified ─────────────────

Deno.test("CGRD-T03 — marker for an act NOT in rag_context → unverified", () => {
  const reply =
    "По KarS §217 [[ref:KarS:217]] это уголовное правонарушение.";
  const out = verifyCitations(reply, [tlsChunk()]); // only TLS is retrieved
  assertEquals(out.length, 1);
  assertEquals(out[0].status, "unverified");
  assertEquals(out[0].chunk_id, null);
  assertEquals(out[0].act_slug, "kars");
  assertEquals(out[0].paragraph, "217");
  // No verified snippet for unverified citations (we don't have it locally).
  assertEquals(out[0].snippet, null);
});

// ─── CGRD-T04 — historical chunk (in_force=false) → historical ──────────────

Deno.test("CGRD-T04 — chunk flagged in_force=false → status historical", () => {
  const reply = "Старая редакция §88 [[ref:TLS:88]].";
  const out = verifyCitations(reply, [historicalTlsChunk()]);
  assertEquals(out.length, 1);
  assertEquals(out[0].status, "historical");
  assertEquals(out[0].chunk_id, "tls-§88-1-v2019");
  assertEquals(out[0].in_force, false);
});

// ─── CGRD-T05 — duplicate marker dedup with occurrences ────────────────────

Deno.test("CGRD-T05 — same marker × 3 → one citation, occurrences=3", () => {
  const reply =
    "См [[ref:TLS:88]] — также [[ref:TLS:88]] — и снова [[ref:TLS:88]].";
  const out = verifyCitations(reply, [tlsChunk()]);
  assertEquals(out.length, 1);
  assertEquals(out[0].occurrences, 3);
  assertEquals(out[0].status, "verified");
});

// ─── CGRD-T06 — multiple distinct markers, mixed status ────────────────────

Deno.test("CGRD-T06 — mixed verified + unverified citations preserved", () => {
  const reply =
    "TLS §88 [[ref:TLS:88]] и KarS §121 [[ref:KarS:121]] и hallucination [[ref:KarS:999]].";
  const out = verifyCitations(reply, [tlsChunk(), karsChunk()]);
  // Three distinct markers → three citation entries.
  assertEquals(out.length, 3);
  const byKey = (c: Citation) => `${c.act_slug}:${c.paragraph}`;
  const verified = out.find((c) => byKey(c) === "tls:88");
  const verified2 = out.find((c) => byKey(c) === "kars:121");
  const unverified = out.find((c) => byKey(c) === "kars:999");
  if (!verified || !verified2 || !unverified) {
    throw new Error("All three markers must be returned");
  }
  assertEquals(verified.status, "verified");
  assertEquals(verified2.status, "verified");
  assertEquals(unverified.status, "unverified");
});

// ─── CGRD-T07 — malformed markers are skipped ──────────────────────────────

Deno.test("CGRD-T07 — malformed marker (no paragraph) skipped silently", () => {
  // Missing paragraph component should NOT match the regex at all (the
  // regex requires :paragraph). Verifier returns empty citations.
  const reply = "Bad marker [[ref:TLS]] should not crash.";
  const out = verifyCitations(reply, [tlsChunk()]);
  assertEquals(out.length, 0);
});

Deno.test("CGRD-T07b — empty markers field is fine, no false positive", () => {
  const reply = "No markers at all here. Just prose with §88 reference.";
  const out = verifyCitations(reply, [tlsChunk()]);
  assertEquals(out.length, 0);
});

// ─── CGRD-T08 — EU directive marker with optional lang suffix ───────────────

Deno.test("CGRD-T08 — EU directive marker [[ref:32019L1152:5:en]] verified", () => {
  const reply =
    "Per Directive 2019/1152 art. 5 [[ref:32019L1152:5:en]] employers must inform...";
  const out = verifyCitations(reply, [euDirectiveChunk()]);
  assertEquals(out.length, 1);
  assertEquals(out[0].status, "verified");
  assertEquals(out[0].chunk_id, "32019l1152-art-5-0");
  assertEquals(out[0].act_slug, "32019l1152");
  assertEquals(out[0].paragraph, "5");
});

// ─── CGRD-T09 — case-insensitive act_slug match ─────────────────────────────

Deno.test("CGRD-T09 — uppercase marker maps to lowercase chunk slug", () => {
  // Model emits TLS uppercase; chunk stored with lowercase slug.
  const reply = "[[ref:TLS:88]]";
  const out = verifyCitations(reply, [tlsChunk()]);
  assertEquals(out.length, 1);
  assertEquals(out[0].status, "verified");
});

// ─── CGRD-T10 — snippet truncation cap ──────────────────────────────────────

Deno.test("CGRD-T10 — long body truncated to ≤400 char snippet", () => {
  const long = {
    ...tlsChunk(),
    body: "ä".repeat(800), // 800-char body, every char a 2-byte utf-8
  };
  const reply = "[[ref:TLS:88]]";
  const out = verifyCitations(reply, [long]);
  assertEquals(out.length, 1);
  // ≤400 *characters* (not bytes) — JS string length counts code units.
  if ((out[0].snippet?.length ?? 0) > 400) {
    throw new Error(`snippet must be ≤400 chars, got ${out[0].snippet!.length}`);
  }
});

// ─── CGRD-T11 — empty rag_context: every marker is unverified ───────────────

Deno.test("CGRD-T11 — empty rag_context still returns unverified entries", () => {
  const reply = "Some legal claim [[ref:TLS:88]].";
  const out = verifyCitations(reply, []);
  assertEquals(out.length, 1);
  assertEquals(out[0].status, "unverified");
  assertEquals(out[0].chunk_id, null);
});

// ─── CGRD-T12 — regex shape (single canonical pattern) ──────────────────────

Deno.test("CGRD-T12 — CITATION_MARKER_PATTERN matches the documented forms", () => {
  const re = new RegExp(CITATION_MARKER_PATTERN, "g");
  const cases: { text: string; expected: number }[] = [
    { text: "[[ref:TLS:88]]", expected: 1 },
    { text: "[[ref:tls:88]]", expected: 1 },
    { text: "[[ref:32019L1152:5:en]]", expected: 1 },
    { text: "two: [[ref:TLS:88]] and [[ref:KarS:121]]", expected: 2 },
    // Non-matches:
    { text: "[TLS §88]", expected: 0 },
    { text: "[[ref:TLS]]", expected: 0 },
    { text: "[[ref:]]", expected: 0 },
    { text: "regular prose with §88 reference", expected: 0 },
    { text: "[[notref:TLS:88]]", expected: 0 },
  ];
  for (const c of cases) {
    re.lastIndex = 0;
    const matches = c.text.match(re) ?? [];
    if (matches.length !== c.expected) {
      throw new Error(
        `Pattern mismatch on "${c.text}": expected ${c.expected}, got ${matches.length} → ${
          JSON.stringify(matches)
        }`,
      );
    }
  }
});

// ─── CGRD-T13 — verifier never throws on null/undefined inputs ──────────────

Deno.test("CGRD-T13 — verifier handles empty/whitespace reply gracefully", () => {
  assertEquals(verifyCitations("", [tlsChunk()]).length, 0);
  assertEquals(verifyCitations("   \n\n  ", [tlsChunk()]).length, 0);
});

// ─── CGRD-T14 — passes through act_name + title from chunk ──────────────────

Deno.test("CGRD-T14 — citation enriched with act_name, title, source_url", () => {
  const reply = "[[ref:TLS:88]]";
  const [c] = verifyCitations(reply, [tlsChunk()]);
  assertEquals(c.act_name, "Töölepingu seadus");
  assertEquals(c.title, "Tööandja erakorraline ülesütlemine");
  assertEquals(c.source_url, "https://www.riigiteataja.ee/akt/tls");
  assertEquals(c.jurisdiction, "EE");
});
