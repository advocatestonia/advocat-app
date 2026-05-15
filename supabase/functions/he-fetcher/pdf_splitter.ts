// he-fetcher/pdf_splitter.ts — split large PDFs into ≤PAGES_PER_SEGMENT-page
// sub-PDFs that fit inside Anthropic's 100-page-per-document cap.
// -----------------------------------------------------------------------------
// Problem we are solving (recorded in lesson 2026-05-15):
//
//   Anthropic Messages API rejects a `document` content block whose source
//   PDF has > 100 pages with:
//       "messages.0.content.0.pdf.source.base64.data:
//        A maximum of 100 PDF pages may be provided."
//
//   This held for both `source.type: "url"` (Anthropic fetches it) and
//   `source.type: "base64"` paths — the cap is server-side per document.
//
//   The earlier he-fetcher tried `npm:pdfjs-dist@4.0.379/legacy/build/pdf.mjs`
//   for text extraction but Supabase Edge started rejecting that specifier
//   ("Could not find constraint"). pdf-lib (esm.sh build) is a different
//   library, has zero native deps, and works in Deno Edge — we already
//   import other esm.sh packages elsewhere (@supabase/supabase-js etc).
//
// Strategy:
//   1. Download the PDF bytes once into memory (≤MAX_PDF_BYTES guard).
//   2. Load via pdf-lib, count pages.
//   3. If pages ≤ PAGES_PER_SEGMENT → return ONE segment with the original bytes.
//   4. Otherwise iterate, copy pages into fresh PDFDocuments, return each as
//      Uint8Array + page_range metadata.
//
// Cost guard:
//   - HARD_MAX_PAGES (default 400) — refuses to split if input is absurdly
//     long. Sonnet pricing × 4 segments × ~30K tok/segment ≈ $0.45/doc.
//     A 400-page HE is the long tail; we accept that cost. Anything longer
//     is almost certainly a misclassified scan or appendix bundle.
//   - MAX_PDF_BYTES (50 MB) — same as fetch_source.ts to prevent OOM.
// -----------------------------------------------------------------------------

import { PDFDocument } from "https://esm.sh/pdf-lib@1.17.1";

/** Anthropic accepts ≤100 pages/document; we leave 10p headroom. */
export const PAGES_PER_SEGMENT = 90;
/** Refuse to process anything longer than this — cost guard. */
export const HARD_MAX_PAGES = 400;
/** Same byte ceiling as fetch_source.ts. */
export const MAX_PDF_BYTES = 50 * 1024 * 1024;

export interface PdfSegment {
  /** 1-indexed page range, inclusive. e.g. {start:1, end:90}. */
  start_page: number;
  end_page: number;
  /** Sub-PDF bytes (NOT base64-encoded — caller decides). */
  bytes: Uint8Array;
}

export interface SplitOutcome {
  total_pages: number;
  segments: PdfSegment[];
}

/**
 * Download a PDF URL into memory and split into ≤PAGES_PER_SEGMENT segments.
 * Throws on oversize or pdf-lib parse errors. The caller handles failJob().
 */
export async function downloadAndSplit(
  pdfUrl: string,
  userAgent: string,
  fetchTimeoutMs: number,
): Promise<SplitOutcome> {
  const bytes = await downloadPdfBytes(pdfUrl, userAgent, fetchTimeoutMs);
  return await splitPdfBytes(bytes);
}

/**
 * GET the PDF bytes, with the same timeout + UA we use elsewhere.
 * Throws on http error or oversize.
 */
export async function downloadPdfBytes(
  pdfUrl: string,
  userAgent: string,
  timeoutMs: number,
): Promise<Uint8Array> {
  const ctl = new AbortController();
  const timer = setTimeout(() => ctl.abort("pdf_download_timeout"), timeoutMs);
  try {
    const res = await fetch(pdfUrl, {
      method: "GET",
      headers: { "User-Agent": userAgent, "Accept": "application/pdf,*/*" },
      redirect: "follow",
      signal: ctl.signal,
    });
    if (!res.ok) {
      throw new Error(`pdf download http ${res.status} ${res.statusText}`);
    }
    const buf = new Uint8Array(await res.arrayBuffer());
    if (buf.byteLength > MAX_PDF_BYTES) {
      throw new Error(
        `pdf oversize: ${buf.byteLength} > ${MAX_PDF_BYTES} bytes`,
      );
    }
    if (buf.byteLength < 1024) {
      // Sanity: any real HE PDF is at least a few KB; <1KB means the upstream
      // returned an HTML error page that slipped past the content-type check.
      throw new Error(`pdf too small: ${buf.byteLength} bytes`);
    }
    return buf;
  } finally {
    clearTimeout(timer);
  }
}

/**
 * Split raw PDF bytes into ≤PAGES_PER_SEGMENT-page segments.
 *
 * For a PDF that already fits in one segment we still wrap it as a single
 * SplitOutcome — keeps the caller's loop uniform.
 */
export async function splitPdfBytes(bytes: Uint8Array): Promise<SplitOutcome> {
  let src: PDFDocument;
  try {
    // ignoreEncryption: some Finlex PDFs have an "owner password" set with no
    // restrictions — pdf-lib refuses to copy from them unless we say so.
    src = await PDFDocument.load(bytes, { ignoreEncryption: true });
  } catch (e) {
    throw new Error(`pdf-lib load failed: ${String(e).slice(0, 200)}`);
  }
  const totalPages = src.getPageCount();
  if (totalPages <= 0) {
    throw new Error("pdf has 0 pages");
  }
  if (totalPages > HARD_MAX_PAGES) {
    throw new Error(
      `pdf too long: ${totalPages} > ${HARD_MAX_PAGES} (HARD_MAX_PAGES)`,
    );
  }
  // Single segment — no copy needed.
  if (totalPages <= PAGES_PER_SEGMENT) {
    return {
      total_pages: totalPages,
      segments: [{ start_page: 1, end_page: totalPages, bytes }],
    };
  }
  // Multi-segment path: build sub-PDFs.
  const segments: PdfSegment[] = [];
  for (let start = 0; start < totalPages; start += PAGES_PER_SEGMENT) {
    const end = Math.min(start + PAGES_PER_SEGMENT, totalPages);
    const sub = await PDFDocument.create();
    const indices: number[] = [];
    for (let i = start; i < end; i++) indices.push(i);
    const copied = await sub.copyPages(src, indices);
    for (const page of copied) sub.addPage(page);
    const subBytes = await sub.save({ useObjectStreams: true });
    segments.push({
      start_page: start + 1,
      end_page: end,
      bytes: subBytes,
    });
  }
  return { total_pages: totalPages, segments };
}

/**
 * Base64-encode raw bytes for an Anthropic `document.source.base64.data`.
 * 32 KB chunking avoids the 2x-memory peak btoa() shows on multi-MB strings.
 *
 * Kept here (separate from fetch_source.bytesToBase64) so the splitter is
 * self-contained for unit testing — the two implementations are identical
 * but live in their own module concerns.
 */
export function segmentBytesToBase64(bytes: Uint8Array): string {
  const CHUNK = 32 * 1024;
  let s = "";
  for (let i = 0; i < bytes.length; i += CHUNK) {
    const slice = bytes.subarray(i, Math.min(i + CHUNK, bytes.length));
    s += String.fromCharCode.apply(null, Array.from(slice));
  }
  return btoa(s);
}
