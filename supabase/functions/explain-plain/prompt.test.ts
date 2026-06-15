// explain-plain/prompt.test.ts — unit tests for the pure prompt/parse logic.
// Run: deno test supabase/functions/explain-plain/prompt.test.ts
import {
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  buildExcerpt,
  buildSystemPrompt,
  buildUserPrompt,
  EXCERPT_CHARS,
  MAX_SOURCE_CHARS,
  MIN_SOURCE_CHARS,
  parseExplainResponse,
  validateRequest,
} from "./prompt.ts";

// ── validateRequest ──────────────────────────────────────────────────────────

Deno.test("validateRequest rejects non-object", () => {
  assertEquals(validateRequest(null).ok, false);
  assertEquals(validateRequest("string").ok, false);
  assertEquals(validateRequest(42).ok, false);
});

Deno.test("validateRequest requires source_text string", () => {
  assertEquals(validateRequest({}).ok, false);
  assertEquals(validateRequest({ source_text: 123 }).ok, false);
});

Deno.test("validateRequest rejects too-short source", () => {
  const r = validateRequest({ source_text: "short" });
  assertEquals(r.ok, false);
});

Deno.test("validateRequest trims and defaults level=friend", () => {
  const long = "  " + "a".repeat(MIN_SOURCE_CHARS + 5) + "  ";
  const r = validateRequest({ source_text: long });
  assertEquals(r.ok, true);
  if (r.ok) {
    assertEquals(r.value.level, "friend");
    // leading/trailing whitespace trimmed
    assertEquals(r.value.source_text.startsWith(" "), false);
    assertEquals(r.value.source_text.endsWith(" "), false);
  }
});

Deno.test("validateRequest accepts valid level + language + links", () => {
  const r = validateRequest({
    source_text: "x".repeat(MIN_SOURCE_CHARS + 1),
    level: "with_terms",
    language: "fi",
    case_id: "case-1",
    source_document_id: "doc-1",
  });
  assertEquals(r.ok, true);
  if (r.ok) {
    assertEquals(r.value.level, "with_terms");
    assertEquals(r.value.language, "fi");
    assertEquals(r.value.case_id, "case-1");
    assertEquals(r.value.source_document_id, "doc-1");
  }
});

Deno.test("validateRequest rejects bad level", () => {
  const r = validateRequest({
    source_text: "x".repeat(MIN_SOURCE_CHARS + 1),
    level: "casual",
  });
  assertEquals(r.ok, false);
});

Deno.test("validateRequest rejects unsupported language", () => {
  const r = validateRequest({
    source_text: "x".repeat(MIN_SOURCE_CHARS + 1),
    language: "zz",
  });
  assertEquals(r.ok, false);
});

Deno.test("validateRequest rejects absurdly long source", () => {
  const r = validateRequest({ source_text: "x".repeat(200_001) });
  assertEquals(r.ok, false);
});

Deno.test("validateRequest ignores empty optional links", () => {
  const r = validateRequest({
    source_text: "x".repeat(MIN_SOURCE_CHARS + 1),
    case_id: "",
    source_document_id: "",
  });
  assertEquals(r.ok, true);
  if (r.ok) {
    assertEquals(r.value.case_id, undefined);
    assertEquals(r.value.source_document_id, undefined);
  }
});

// ── buildSystemPrompt ────────────────────────────────────────────────────────

Deno.test(
  "buildSystemPrompt: friend mode demands A2-B1 + forbids advice",
  () => {
    const p = buildSystemPrompt("friend", "ru");
    assertStringIncludes(p, "A2");
    assertStringIncludes(p, "NOT giving legal advice");
    assertStringIncludes(p, "Russian");
  }
);

Deno.test("buildSystemPrompt: with_terms keeps glossary terms", () => {
  const p = buildSystemPrompt("with_terms", "fi");
  assertStringIncludes(p, "glossary");
  assertStringIncludes(p, "Finnish");
});

Deno.test("buildSystemPrompt: always asks for strict JSON shape", () => {
  const p = buildSystemPrompt("friend", "en");
  assertStringIncludes(p, '"tldr"');
  assertStringIncludes(p, '"paragraphs"');
  assertStringIncludes(p, '"glossary"');
  assertStringIncludes(p, '"next_steps"');
});

// ── buildUserPrompt ──────────────────────────────────────────────────────────

Deno.test("buildUserPrompt wraps the document in markers", () => {
  const p = buildUserPrompt("hello document");
  assertStringIncludes(p, "--- BEGIN DOCUMENT ---");
  assertStringIncludes(p, "hello document");
  assertStringIncludes(p, "--- END DOCUMENT ---");
});

Deno.test("buildUserPrompt truncates beyond MAX_SOURCE_CHARS", () => {
  const huge = "z".repeat(MAX_SOURCE_CHARS + 5000);
  const p = buildUserPrompt(huge);
  assertStringIncludes(p, "document truncated");
  // The body must not contain the full oversized text.
  assertEquals(p.length < huge.length + 500, true);
});

Deno.test("buildUserPrompt leaves short docs intact", () => {
  const small = "a short decision text";
  const p = buildUserPrompt(small);
  assertEquals(p.includes("document truncated"), false);
});

// ── buildExcerpt ─────────────────────────────────────────────────────────────

Deno.test("buildExcerpt collapses whitespace and caps length", () => {
  const noisy = "  Migri   decision\n\n\twith   spaces  ";
  assertEquals(buildExcerpt(noisy), "Migri decision with spaces");

  const long = "w ".repeat(EXCERPT_CHARS);
  const ex = buildExcerpt(long);
  assertEquals(ex.length <= EXCERPT_CHARS, true);
});

// ── parseExplainResponse ─────────────────────────────────────────────────────

Deno.test("parseExplainResponse parses a clean object", () => {
  const out = parseExplainResponse(
    JSON.stringify({
      tldr: ["You must reply within 30 days."],
      paragraphs: [{ heading: "Decision", plain: "Your permit was refused." }],
      glossary: [
        {
          term: "käännytys",
          plain: "removal from the country",
          ref: "fi-ulkomaalaislaki:148",
        },
      ],
      next_steps: [
        "The decision says you may appeal to the administrative court.",
      ],
    })
  );
  assertEquals(out.tldr.length, 1);
  assertEquals(out.paragraphs[0].heading, "Decision");
  assertEquals(out.glossary[0].ref, "fi-ulkomaalaislaki:148");
  assertEquals(out.next_steps.length, 1);
});

Deno.test("parseExplainResponse tolerates code fences", () => {
  const fenced =
    "```json\n" +
    JSON.stringify({
      tldr: ["x"],
      paragraphs: [],
      glossary: [],
      next_steps: [],
    }) +
    "\n```";
  const out = parseExplainResponse(fenced);
  assertEquals(out.tldr[0], "x");
});

Deno.test(
  "parseExplainResponse drops malformed glossary/paragraph rows",
  () => {
    const out = parseExplainResponse(
      JSON.stringify({
        tldr: ["ok", 42, "", "  keep  "],
        paragraphs: [
          { heading: "H", plain: "good" },
          { heading: "no-plain" }, // dropped: no plain
          "not-an-object", // dropped
          { plain: "" }, // dropped: empty plain
        ],
        glossary: [
          { term: "a", plain: "x" },
          { term: "", plain: "y" }, // dropped: empty term
          { term: "b" }, // dropped: no plain
          { term: "c", plain: "z", ref: "  " }, // ref blank → omitted
        ],
        next_steps: ["step"],
      })
    );
    assertEquals(out.tldr, ["ok", "keep"]);
    assertEquals(out.paragraphs.length, 1);
    assertEquals(out.glossary.length, 2);
    assertEquals(out.glossary[1].ref, undefined);
  }
);

Deno.test(
  "parseExplainResponse defaults missing sections to empty arrays",
  () => {
    const out = parseExplainResponse(JSON.stringify({ tldr: ["only tldr"] }));
    assertEquals(out.paragraphs, []);
    assertEquals(out.glossary, []);
    assertEquals(out.next_steps, []);
  }
);

Deno.test("parseExplainResponse throws on non-JSON", () => {
  let threw = false;
  try {
    parseExplainResponse("this is not json at all");
  } catch {
    threw = true;
  }
  assertEquals(threw, true);
});

Deno.test("parseExplainResponse throws on JSON non-object", () => {
  let threw = false;
  try {
    parseExplainResponse("[1,2,3]");
  } catch {
    threw = true;
  }
  assertEquals(threw, true);
});
