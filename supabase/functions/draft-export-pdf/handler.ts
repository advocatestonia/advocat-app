// draft-export-pdf/handler.ts — pure logic for Markdown → PDF export.
// -----------------------------------------------------------------------------
// Pkg 7 Drafting Studio MVP — Track 1A. Converts a draft's markdown into a
// PDF via the project's existing Typst worker (the same pattern as
// contract-review/index.ts: an HTTPS worker behind CONTRACT_PDF_WORKER_URL /
// CONTRACT_PDF_WORKER_SECRET). The edge function is a thin shim — it
// validates input, assembles a Typst source string, calls the worker, and
// base64-encodes the PDF bytes for the Flutter client.
//
// When the worker is not configured (local dev, smoke env), `runPdfExport`
// returns a 503 with `worker_not_configured` so the client can surface a
// clear "PDF export temporarily disabled" message instead of a silent
// failure. The DOCX export path remains the production fallback.
//
// What we deliberately DO NOT support in MVP:
//   - Images, tables, footnotes (Typst markdown rule handles a sane subset).
//   - Custom page setup (we hard-code A4 + 2.5 cm margins to match DOCX).
//   - Header/footer customisation per case (deferred to Pkg 7 v1.1).
// -----------------------------------------------------------------------------

// ─── Public contracts ───────────────────────────────────────────────────────

export interface PdfExportRequest {
  /** Markdown source of truth. */
  content_markdown: string;
  /** Optional title — becomes the suggested filename and document title. */
  title?: string;
}

export interface PdfExportSuccess {
  kind: "success";
  status: 200;
  body: {
    /** Base64-encoded PDF bytes. Client decodes and hands off to OS share sheet. */
    pdf_base64: string;
    /** Suggested filename (sanitised, .pdf suffix). */
    filename: string;
    /** Byte count of the un-encoded PDF (useful for assertions in tests). */
    byte_length: number;
    /** Static MIME for the client to set on the XFile envelope. */
    mime: "application/pdf";
  };
}

export interface PdfExportError {
  kind: "error";
  /** 400 = bad request; 502 = worker error; 503 = worker not configured. */
  status: 400 | 502 | 503;
  body: { error: string };
}

export type PdfExportResult = PdfExportSuccess | PdfExportError;

/** Payload posted to the Typst worker. The worker compiles `typst_source`
 *  with `typst compile` and returns the raw PDF bytes. */
export interface TypstWorkerRequest {
  typst_source: string;
  filename: string;
}

/** Dependency-injected Typst worker — production wires this to fetch();
 *  unit tests inject a stub returning fake PDF bytes. */
export type PdfWorkerCaller =
  | ((payload: TypstWorkerRequest) => Promise<Uint8Array>)
  | null;

// ─── Validation ─────────────────────────────────────────────────────────────

export interface ValidationFailure {
  kind: "error";
  status: 400;
  body: { error: string };
}

export function validatePdfRequest(
  body: unknown,
): { ok: true; req: PdfExportRequest } | ValidationFailure {
  if (!body || typeof body !== "object") {
    return {
      kind: "error",
      status: 400,
      body: { error: "Request body must be a JSON object" },
    };
  }
  const b = body as Record<string, unknown>;
  if (
    typeof b.content_markdown !== "string" || b.content_markdown.length === 0
  ) {
    return {
      kind: "error",
      status: 400,
      body: { error: "content_markdown is required" },
    };
  }
  if (b.content_markdown.length > 200_000) {
    return {
      kind: "error",
      status: 400,
      body: { error: "content_markdown exceeds 200000 chars" },
    };
  }
  const req: PdfExportRequest = { content_markdown: b.content_markdown };
  if (typeof b.title === "string") req.title = b.title;
  return { ok: true, req };
}

// ─── Typst source generation ────────────────────────────────────────────────

/** Triple-quote-style raw block delimiter used by Typst for embedded source
 *  strings. We standardise on a 4-backtick fence so the inner markdown can
 *  contain triple-backtick code blocks without escaping. */
const FENCE = "````";

/** Strips characters that would prematurely close the embedded raw block.
 *  Typst raw blocks are terminated by the same fence used to open them, so
 *  the only character sequence we need to scrub is the fence itself. */
function scrubFence(md: string): string {
  return md.replaceAll(FENCE, "‵‵‵‵"); // homoglyph fallback
}

/** Escape Typst-specific control characters inside the title argument. */
function escapeTypstString(s: string): string {
  return s
    .replaceAll("\\", "\\\\")
    .replaceAll('"', '\\"')
    .replaceAll("\n", " ");
}

/**
 * Assembles the Typst source that the worker compiles. The contract is
 * intentionally minimal: a document directive + the markdown body inside a
 * `cmarker.render(...)` call (the worker provides the `cmarker` import).
 *
 * Page setup mirrors the DOCX export (A4, 2.5 cm margins, 11 pt body) so
 * the same draft renders consistently across both formats.
 */
export function buildTypstSource(
  markdown: string,
  title: string | undefined,
): string {
  const safeTitle = title && title.trim().length > 0
    ? escapeTypstString(title.trim().slice(0, 200))
    : "Draft";
  const safeMarkdown = scrubFence(markdown);
  return `#import "@preview/cmarker:0.1.1": render as cmarker_render
#set document(title: "${safeTitle}", author: "Advocat.ee")
#set page(paper: "a4", margin: (x: 2.5cm, y: 2.5cm))
#set text(font: "Linux Libertine", size: 11pt, lang: "en")
#set par(justify: true, leading: 0.65em)
#show heading.where(level: 1): set text(size: 18pt, weight: "bold")
#show heading.where(level: 2): set text(size: 14pt, weight: "bold")
#show heading.where(level: 3): set text(size: 12pt, weight: "bold")

#cmarker_render(${FENCE}
${safeMarkdown}
${FENCE})

#align(right)[#text(size: 9pt, fill: rgb("#888888"))[Generated by Advocat.ee]]
`;
}

// ─── Filename sanitiser ─────────────────────────────────────────────────────

export function sanitisePdfFilename(title: string | undefined): string {
  const base = (title ?? "draft").trim();
  const cleaned = base
    .replace(/[^A-Za-zÀ-ÿ0-9 _-]+/g, "-")
    .replace(/\s+/g, "_")
    .replace(/-+/g, "-")
    .replace(/^[_-]+|[_-]+$/g, "");
  const safe = cleaned.length > 0 ? cleaned.slice(0, 80) : "draft";
  return `${safe}.pdf`;
}

// ─── Base64 helper (Deno-safe — no Node Buffer) ─────────────────────────────

function bytesToBase64(bytes: Uint8Array): string {
  // Process in 32KB chunks so we don't blow the JS string size limit on
  // larger PDFs (small drafts won't hit it; we set the guard anyway).
  let s = "";
  const chunkSize = 0x8000;
  for (let i = 0; i < bytes.length; i += chunkSize) {
    const chunk = bytes.subarray(i, Math.min(i + chunkSize, bytes.length));
    s += String.fromCharCode(...chunk);
  }
  return btoa(s);
}

/** %PDF-1.x file-magic check. The Typst worker should always return a real
 *  PDF — anything else likely means the worker returned an HTML error page
 *  with a 200 status code (Cloudflare 522 etc.), and we want to surface
 *  that as a 502 to the client instead of shipping a corrupt download. */
function looksLikePdf(bytes: Uint8Array): boolean {
  return (
    bytes.length >= 5 &&
    bytes[0] === 0x25 && // %
    bytes[1] === 0x50 && // P
    bytes[2] === 0x44 && // D
    bytes[3] === 0x46 && // F
    bytes[4] === 0x2d //   -
  );
}

// ─── Orchestrator ───────────────────────────────────────────────────────────

export interface RunPdfExportOptions {
  body: unknown;
  /** When null, the function returns 503 worker_not_configured. */
  pdfWorker: PdfWorkerCaller;
}

/** Top-level handler. Pure with respect to the global edge runtime — all IO
 *  is funnelled through the injected `pdfWorker`. */
export async function runPdfExport(
  opts: RunPdfExportOptions,
): Promise<PdfExportResult> {
  const v = validatePdfRequest(opts.body);
  if (!("ok" in v)) return v;
  const req = v.req;

  if (!opts.pdfWorker) {
    return {
      kind: "error",
      status: 503,
      body: { error: "worker_not_configured" },
    };
  }

  const filename = sanitisePdfFilename(req.title);
  const typst = buildTypstSource(req.content_markdown, req.title);

  let bytes: Uint8Array;
  try {
    bytes = await opts.pdfWorker({ typst_source: typst, filename });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    return {
      kind: "error",
      status: 502,
      body: { error: `pdf_worker_failed: ${msg.slice(0, 200)}` },
    };
  }

  if (!looksLikePdf(bytes)) {
    return {
      kind: "error",
      status: 502,
      body: { error: "pdf_worker_returned_non_pdf" },
    };
  }

  return {
    kind: "success",
    status: 200,
    body: {
      pdf_base64: bytesToBase64(bytes),
      filename,
      byte_length: bytes.length,
      mime: "application/pdf",
    },
  };
}
