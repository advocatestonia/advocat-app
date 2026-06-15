// Deno tests for Document-Collection Checklist (Feature #4) — AI top-up parser.
// -----------------------------------------------------------------------------
// Run with:
//   deno test --allow-read --allow-env \
//     supabase/functions/doc-requirements/__tests__/suggest_prompt_test.ts
//
// Pure-function tests for `suggest_prompt.ts` (build block + parse + clamp +
// de-dup vs base list) and a few source-contract assertions on
// `doc-requirements/index.ts` (JWT gate, RPC names, no progress writes).
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  buildDocSuggestUserBlock,
  DOC_SUGGEST_HAIKU_MODEL,
  DOC_SUGGEST_SYSTEM_PROMPT,
  MAX_SUGGEST_TITLE_CHARS,
  MAX_SUGGESTIONS,
  parseDocSuggestions,
} from "../suggest_prompt.ts";

// ── parseDocSuggestions ──────────────────────────────────────────────────

Deno.test("parses a clean JSON array of suggestions", () => {
  const raw = JSON.stringify([
    {
      title: "Tax residency certificate",
      where_to_get: "Tax authority",
      why_needed: "Proves where you are taxed",
    },
    {
      title: "Power of attorney",
      where_to_get: "A notary",
      why_needed: "Lets a representative act for you",
    },
  ]);
  const out = parseDocSuggestions(raw);
  assertEquals(out.length, 2);
  assertEquals(out[0].title, "Tax residency certificate");
  assertEquals(out[1].where_to_get, "A notary");
});

Deno.test("extracts the array from a code-fenced reply with prose", () => {
  const raw =
    'Sure, here you go:\n```json\n[{"title":"Bank statement","where_to_get":"Your bank","why_needed":"Shows funds"}]\n```\nHope that helps!';
  const out = parseDocSuggestions(raw);
  assertEquals(out.length, 1);
  assertEquals(out[0].title, "Bank statement");
});

Deno.test("returns [] for malformed / non-array replies", () => {
  assertEquals(parseDocSuggestions(""), []);
  assertEquals(parseDocSuggestions("not json at all"), []);
  assertEquals(parseDocSuggestions("{not: closed"), []);
  assertEquals(parseDocSuggestions('{"title":"x"}'), []); // object, not array
});

Deno.test("drops entries without a usable title", () => {
  const raw = JSON.stringify([
    { where_to_get: "x", why_needed: "y" }, // no title
    { title: "   ", where_to_get: "x" }, // blank title
    { title: "Valid one" },
  ]);
  const out = parseDocSuggestions(raw);
  assertEquals(out.length, 1);
  assertEquals(out[0].title, "Valid one");
  assertEquals(out[0].where_to_get, ""); // missing field -> empty string
});

Deno.test("de-duplicates against the base list (case-insensitive)", () => {
  const raw = JSON.stringify([
    { title: "Valid passport" }, // already in base
    { title: "PASSPORT COPY" }, // distinct title -> kept
    { title: "Marriage certificate" }, // distinct -> kept
  ]);
  const out = parseDocSuggestions(raw, ["Valid passport"]);
  assertEquals(
    out.map((s) => s.title),
    ["PASSPORT COPY", "Marriage certificate"]
  );
});

Deno.test("de-duplicates repeated suggestions within one reply", () => {
  const raw = JSON.stringify([
    { title: "Bank statement" },
    { title: "bank statement" }, // dup -> dropped
    { title: "Bank Statement " }, // trimmed dup -> dropped
  ]);
  const out = parseDocSuggestions(raw);
  assertEquals(out.length, 1);
});

Deno.test("clamps the number of suggestions to MAX_SUGGESTIONS", () => {
  const many = Array.from({ length: MAX_SUGGESTIONS + 5 }, (_, i) => ({
    title: `Doc ${i}`,
  }));
  const out = parseDocSuggestions(JSON.stringify(many));
  assertEquals(out.length, MAX_SUGGESTIONS);
});

Deno.test("clamps an over-long title", () => {
  const longTitle = "A".repeat(MAX_SUGGEST_TITLE_CHARS + 50);
  const out = parseDocSuggestions(JSON.stringify([{ title: longTitle }]));
  assertEquals(out.length, 1);
  assertEquals(out[0].title.length, MAX_SUGGEST_TITLE_CHARS);
});

// ── buildDocSuggestUserBlock ─────────────────────────────────────────────

Deno.test("user block embeds problem type, base list and situation", () => {
  const block = buildDocSuggestUserBlock({
    problemType: "residence_permit",
    baseTitles: ["Valid passport", "Proof of income"],
    situation: "I am a startup founder applying on entrepreneur grounds.",
  });
  assertStringIncludes(block, "residence_permit");
  assertStringIncludes(block, "Valid passport");
  assertStringIncludes(block, "startup founder");
  assertStringIncludes(block, "ADDITIONAL");
});

Deno.test("user block caps the base list at 40 titles", () => {
  const titles = Array.from({ length: 100 }, (_, i) => `Title ${i}`);
  const block = buildDocSuggestUserBlock({
    problemType: "divorce",
    baseTitles: titles,
    situation: "x",
  });
  assertStringIncludes(block, "Title 0");
  assertStringIncludes(block, "Title 39");
  assert(!block.includes("Title 40"));
});

// ── system prompt guardrails ─────────────────────────────────────────────

Deno.test("system prompt forbids legal advice and demands JSON-only", () => {
  assertStringIncludes(DOC_SUGGEST_SYSTEM_PROMPT, "ADDITIONAL");
  assertStringIncludes(DOC_SUGGEST_SYSTEM_PROMPT, "legal advice");
  assertStringIncludes(DOC_SUGGEST_SYSTEM_PROMPT, "STRICT JSON");
});

// ── source-contract assertions on the edge function ──────────────────────

Deno.test("index.ts gates on JWT and never writes progress", async () => {
  const src = await Deno.readTextFile(new URL("../index.ts", import.meta.url));
  // JWT gate present.
  assertStringIncludes(src, "requireUserWithRateLimit");
  // Reads via the RLS/DEFINER RPC.
  assertStringIncludes(src, "get_doc_requirements");
  // Suggest never persists: the write RPC and any insert/update into the
  // progress table must not appear (comments may reference the names).
  assert(!src.includes('rpc("toggle_doc_requirement"'));
  assert(!/\.from\(["']doc_collection_progress["']\)/.test(src));
  assert(!src.includes(".insert("));
  assert(!src.includes(".update("));
  // Uses the right (cheap) model for the top-up.
  assertEquals(DOC_SUGGEST_HAIKU_MODEL, "claude-3-5-haiku-20241022");
});

Deno.test("index.ts restricts problem types to the seeded set", async () => {
  const src = await Deno.readTextFile(new URL("../index.ts", import.meta.url));
  for (const t of [
    "residence_permit",
    "tenant_rights",
    "dismissal",
    "inheritance",
    "divorce",
  ]) {
    assertStringIncludes(src, t);
  }
});
