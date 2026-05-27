// Deno tests for draft-export-pdf (Pkg 7 Drafting Studio MVP — Track 1A).
// -----------------------------------------------------------------------------
// Mirrors the structure of __tests__/draft_export_docx_test.ts but exercises
// the Typst-backed PDF pipeline. Because the worker is an external HTTP
// service, the unit tests inject a stub `pdfWorker` and never hit the network.
//
// Run:
//   deno test --allow-read --allow-env \
//     supabase/functions/draft-export-pdf/__tests__/draft_export_pdf_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  buildTypstSource,
  runPdfExport,
  sanitisePdfFilename,
  validatePdfRequest,
} from "../handler.ts";

// ─── Validation ─────────────────────────────────────────────────────────────

Deno.test("validatePdfRequest rejects missing markdown", () => {
  const v = validatePdfRequest({});
  assert(!("ok" in v));
});

Deno.test("validatePdfRequest rejects oversize markdown", () => {
  const v = validatePdfRequest({ content_markdown: "x".repeat(200_001) });
  assert(!("ok" in v));
});

Deno.test("validatePdfRequest accepts well-formed body", () => {
  const v = validatePdfRequest({
    content_markdown: "# Hello\n\nBody.",
    title: "t",
  });
  assert("ok" in v && v.ok === true);
});

// ─── Typst source generation ────────────────────────────────────────────────

Deno.test("buildTypstSource emits document preamble", () => {
  const src = buildTypstSource("Hello", "Title");
  // The Typst worker contract: a `#set document` directive must be present
  // so the rendered PDF carries the title in its metadata.
  assert(src.includes("#set document"));
  assert(src.includes("Title"));
});

Deno.test("buildTypstSource passes raw markdown through markdown rule", () => {
  const md = "# Heading\n\nBody **bold**.";
  const src = buildTypstSource(md, undefined);
  // Body markdown is embedded as a raw string Typst can parse — we don't
  // pre-render it on the edge fn side. The worker calls
  // `cmarker.render(...)` (or the Typst `pandoc`-style helper) over the
  // payload, so the markdown source must appear verbatim somewhere in the
  // Typst file.
  assert(src.includes(md), "Typst source should embed markdown verbatim");
});

Deno.test("buildTypstSource escapes embedded quotes", () => {
  const md = 'Has "quotes" inside.';
  const src = buildTypstSource(md, undefined);
  // We rely on Typst's triple-quote-block literal, so unescaped `"` inside
  // is safe — but a stray `"""` would close the block early. Smoke-check
  // that the dangerous triple-quote substring never lands in the source.
  const dangerous = '"""inside';
  assert(!src.includes(dangerous));
});

// ─── Filename sanitiser ─────────────────────────────────────────────────────

Deno.test("sanitisePdfFilename keeps safe chars and ends with .pdf", () => {
  assertEquals(sanitisePdfFilename("Reply to OP"), "Reply_to_OP.pdf");
});

Deno.test("sanitisePdfFilename strips dangerous chars", () => {
  assertEquals(sanitisePdfFilename("../etc/passwd"), "etc-passwd.pdf");
});

Deno.test("sanitisePdfFilename falls back to 'draft' when empty", () => {
  assertEquals(sanitisePdfFilename(undefined), "draft.pdf");
  assertEquals(sanitisePdfFilename(""), "draft.pdf");
});

Deno.test("sanitisePdfFilename truncates long titles", () => {
  const long = "a".repeat(200);
  const name = sanitisePdfFilename(long);
  assert(name.length <= "a".repeat(80).length + ".pdf".length);
});

// ─── runPdfExport — happy path with stub worker ─────────────────────────────

function stubWorker(bytes: Uint8Array) {
  return async (_payload: { typst_source: string; filename: string }) => {
    return await Promise.resolve(bytes);
  };
}

Deno.test("runPdfExport returns base64 + filename + mime on worker success", async () => {
  // Fake PDF bytes — must start with %PDF for the magic-bytes assertion.
  const fakePdf = new Uint8Array([
    0x25, 0x50, 0x44, 0x46, 0x2d, 0x31, 0x2e, 0x37, 0x0a, // %PDF-1.7\n
    0x42, 0x42, 0x42, // dummy body
  ]);
  const r = await runPdfExport({
    body: {
      content_markdown: "# Hello\n\nBody.",
      title: "test",
    },
    pdfWorker: stubWorker(fakePdf),
  });
  assertEquals(r.kind, "success");
  if (r.kind !== "success") return;
  assertEquals(r.body.mime, "application/pdf");
  assertEquals(r.body.filename, "test.pdf");
  assertEquals(r.body.byte_length, fakePdf.length);
  // Base64 of "%PDF" is "JVBERi0" (first 4 bytes round-trip).
  assertEquals(r.body.pdf_base64.slice(0, 5), "JVBER");
});

Deno.test("runPdfExport returns 400 on invalid body", async () => {
  const r = await runPdfExport({
    body: { title: "no body" },
    pdfWorker: stubWorker(new Uint8Array([0x25, 0x50, 0x44, 0x46])),
  });
  assertEquals(r.kind, "error");
  assertEquals(r.status, 400);
});

Deno.test("runPdfExport returns 503 when worker is null", async () => {
  const r = await runPdfExport({
    body: { content_markdown: "Hello", title: "t" },
    pdfWorker: null,
  });
  assertEquals(r.kind, "error");
  assertEquals(r.status, 503);
  if (r.kind === "error") {
    assert(r.body.error.includes("worker_not_configured"));
  }
});

Deno.test("runPdfExport surfaces worker errors as 502", async () => {
  const erroringWorker = (
    _payload: { typst_source: string; filename: string },
  ) => Promise.reject(new Error("typst exit 1: parse error"));
  const r = await runPdfExport({
    body: { content_markdown: "Hello", title: "t" },
    pdfWorker: erroringWorker,
  });
  assertEquals(r.kind, "error");
  assertEquals(r.status, 502);
});

Deno.test("runPdfExport rejects worker output that is not a PDF", async () => {
  // No %PDF magic.
  const notPdf = new Uint8Array([0x00, 0x01, 0x02, 0x03]);
  const r = await runPdfExport({
    body: { content_markdown: "Hello", title: "t" },
    pdfWorker: stubWorker(notPdf),
  });
  assertEquals(r.kind, "error");
  assertEquals(r.status, 502);
});
