// Deno tests for draft-export-docx (Pkg 7 Drafting Studio MVP).
// -----------------------------------------------------------------------------
// Run:
//   deno test --allow-read --allow-env \
//     supabase/functions/draft-export-docx/__tests__/draft_export_docx_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  parseMarkdownLines,
  renderDocumentXml,
  runDocxExport,
  sanitiseFilename,
  splitRuns,
  validateDocxRequest,
} from "../handler.ts";

// ─── Validation ─────────────────────────────────────────────────────────────

Deno.test("validateDocxRequest rejects missing markdown", () => {
  const v = validateDocxRequest({});
  assert(!("ok" in v));
});

Deno.test("validateDocxRequest rejects oversize markdown", () => {
  const v = validateDocxRequest({ content_markdown: "x".repeat(200_001) });
  assert(!("ok" in v));
});

Deno.test("validateDocxRequest accepts well-formed body", () => {
  const v = validateDocxRequest({ content_markdown: "# Hello\n\nBody.", title: "t" });
  assert("ok" in v && v.ok === true);
});

// ─── Markdown parsing ───────────────────────────────────────────────────────

Deno.test("parseMarkdownLines classifies headings, bullets, numbers, paragraphs", () => {
  const md = "# H1\n## H2\n### H3\n- bullet\n1. numbered\nparagraph";
  const lines = parseMarkdownLines(md);
  assertEquals(lines.length, 6);
  assertEquals(lines[0].kind, "h1");
  assertEquals(lines[1].kind, "h2");
  assertEquals(lines[2].kind, "h3");
  assertEquals(lines[3].kind, "bullet");
  assertEquals(lines[4].kind, "number");
  assertEquals(lines[5].kind, "p");
});

Deno.test("parseMarkdownLines folds h4-h6 into h3", () => {
  const lines = parseMarkdownLines("#### H4\n##### H5");
  assertEquals(lines[0].kind, "h3");
  assertEquals(lines[1].kind, "h3");
});

Deno.test("parseMarkdownLines preserves blank lines as empty paragraphs", () => {
  const lines = parseMarkdownLines("first\n\nsecond");
  assertEquals(lines.length, 3);
  assertEquals(lines[1].kind, "p");
  assertEquals(lines[1].text, "");
});

// ─── Inline run splitting ───────────────────────────────────────────────────

Deno.test("splitRuns marks bold inline", () => {
  const runs = splitRuns("This is **bold** text");
  assertEquals(runs.length, 3);
  assertEquals(runs[1].bold, true);
  assertEquals(runs[1].text, "bold");
});

Deno.test("splitRuns marks italic via *", () => {
  const runs = splitRuns("This is *italic* text");
  const italic = runs.find((r) => r.italic);
  assertExists(italic);
  assertEquals(italic!.text, "italic");
});

Deno.test("splitRuns marks italic via _", () => {
  const runs = splitRuns("This is _italic_ text");
  const italic = runs.find((r) => r.italic);
  assertExists(italic);
  assertEquals(italic!.text, "italic");
});

Deno.test("splitRuns returns single run for plain text", () => {
  const runs = splitRuns("just words");
  assertEquals(runs.length, 1);
  assertEquals(runs[0].bold ?? false, false);
  assertEquals(runs[0].italic ?? false, false);
});

// ─── XML rendering ──────────────────────────────────────────────────────────

Deno.test("renderDocumentXml emits w:document root", () => {
  const xml = renderDocumentXml(parseMarkdownLines("# Hi"));
  assert(xml.includes("<w:document"));
  assert(xml.includes("Heading1"));
});

Deno.test("renderDocumentXml escapes ampersands and angle brackets", () => {
  const xml = renderDocumentXml(parseMarkdownLines("A & B < C > D"));
  assert(xml.includes("A &amp; B &lt; C &gt; D"));
});

// ─── Filename sanitiser ─────────────────────────────────────────────────────

Deno.test("sanitiseFilename keeps safe chars and adds .docx", () => {
  assertEquals(sanitiseFilename("Reply to OP"), "Reply_to_OP.docx");
});

Deno.test("sanitiseFilename strips dangerous chars", () => {
  assertEquals(sanitiseFilename("../etc/passwd"), "etc-passwd.docx");
});

Deno.test("sanitiseFilename falls back to 'draft' when empty", () => {
  assertEquals(sanitiseFilename(undefined), "draft.docx");
  assertEquals(sanitiseFilename(""), "draft.docx");
});

Deno.test("sanitiseFilename truncates long titles", () => {
  const long = "a".repeat(200);
  const name = sanitiseFilename(long);
  assert(name.length <= "a".repeat(80).length + ".docx".length);
});

// ─── Full export pipeline ───────────────────────────────────────────────────

Deno.test("runDocxExport produces a non-empty base64 zip", () => {
  const r = runDocxExport({
    content_markdown: "# Hello\n\nThis is **bold** and *italic*.\n- one\n- two",
    title: "test",
  });
  assertEquals(r.kind, "success");
  if (r.kind !== "success") return;
  assert(r.body.byte_length > 100, "DOCX should be non-trivially sized");
  assert(r.body.docx_base64.length > 0);
  assertEquals(r.body.filename, "test.docx");
});

Deno.test("runDocxExport returns 400 on invalid input", () => {
  const r = runDocxExport({ title: "no body" });
  assertEquals(r.kind, "error");
  assertEquals(r.status, 400);
});

Deno.test("DOCX zip header starts with PK signature", () => {
  const r = runDocxExport({ content_markdown: "Hello", title: "t" });
  assertEquals(r.kind, "success");
  if (r.kind !== "success") return;
  // Base64 of "PK" is "UEs" — first 3 chars of every ZIP.
  assertEquals(r.body.docx_base64.slice(0, 3), "UEs");
});
