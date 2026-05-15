// he-fetcher/pdf_splitter.ts — split large PDFs into ≤PAGES_PER_SEGMENT-page
// sub-PDFs that fit inside Anthropic's 100-page-per-document cap AND the
// 200K-token context-window cap.
// -----------------------------------------------------------------------------
// Problem we are solving (recorded in lesson 2026-05-15 — Fix #89 round 2-3):
//
//   Anthropic Messages API rejects a `document` content block on THREE axes:
//
//     (a) Page cap — hard server-side:
//         "messages.0.content.0.pdf.source.base64.data:
//          A maximum of 100 PDF pages may be provided."
//
//     (b) Token cap — context window:
//         "prompt is too long: 217922 tokens > 200000 maximum"
//
//     (c) Worker memory — Supabase Edge runtime (~256 MB cap per worker):
//         "WORKER_RESOURCE_LIMIT 546" — round 2 reproduced twice on HE 72/2002
//         (143-page PDF → 3 × 50-page segments). The previous implementation
//         held ALL segments (3 × ~10 MB PDF + 3 × ~13 MB base64 = ~70 MB
//         long-lived) AND the pdf-lib parse tree of the original (~30 MB)
//         simultaneously → killed the worker.
//
//   Round 1 (90-page cap) cleared (a) but not (b): dense Finnish parliamentary
//   text runs ~3000-3500 tokens/page. 90p × 3500 = 315K tokens → fails.
//
//   Round 2 (PAGES_PER_SEGMENT=50): cleared (a)+(b) but exposed (c).
//
//   Round 3 fix (this file):
//     - Streaming generator API: yieldSegments() copies + saves ONE sub-PDF
//       at a time and yields it. After the caller is done, the prior segment
//       falls out of scope and is GC'd before the next is allocated.
//     - segmentBytesToBase64() uses a Uint8Array growable scratch buffer
//       instead of O(n²) string += which doubles peak memory.
//     - Source PDFDocument is constructed once but the per-segment sub-PDFs
//       and their saved Uint8Arrays are short-lived.
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
//   3. If pages ≤ PAGES_PER_SEGMENT → yield ONE segment with the original bytes.
//   4. Otherwise lazily yield segments one at a time via an async generator,
//      so the caller can process+discard each before the next is built.
//
// Cost guard:
//   - HARD_MAX_PAGES (default 400) — refuses to split if input is absurdly
//     long. With 50p segments that's up to 8 Sonnet calls × ~$0.10/call
//     ≈ $0.80/doc worst case. Anything longer is almost certainly a
//     misclassified scan or appendix bundle.
//   - MAX_PDF_BYTES (50 MB) — same as fetch_source.ts to prevent OOM.
// -----------------------------------------------------------------------------

import { PDFDocument } from "https://esm.sh/pdf-lib@1.17.1";

/**
 * Anthropic caps: 100 pages/document AND 200K tokens/request.
 * Finnish parliamentary PDFs run ~3000-3500 tok/page (dense legal prose),
 * so 50 pages ≈ 175K tokens — well under the 200K token cap with headroom
 * for the system prompt + JSON output instructions.
 */
export const PAGES_PER_SEGMENT = 50;
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
 * Metadata-only result for the streaming path. The caller iterates
 * `yieldPdfSegments(...)` separately to obtain segment bytes.
 */
export interface SplitPlan {
  total_pages: number;
  segment_count: number;
}

/**
 * Download a PDF URL into memory and split into ≤PAGES_PER_SEGMENT segments.
 * Throws on oversize or pdf-lib parse errors. The caller handles failJob().
 *
 * NOTE: eager API kept for tests and backward compat. Hot-path callers that
 *       process big PDFs (HE 72/2002 = 143p) should use downloadAndStream()
 *       + yieldPdfSegments() to avoid holding all segments in memory.
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
 * Streaming counterpart to downloadAndSplit(): downloads the PDF once,
 * inspects total pages, and returns a {plan, iterator} pair. The caller
 * MUST iterate the async generator to receive segments one at a time. Each
 * yielded segment's bytes are freshly allocated on demand and can be GC'd
 * after the caller is done with that iteration.
 *
 * Memory profile per loop iteration (50-page FI HE segment):
 *   - Source PDFDocument held throughout: ~30 MB (input bytes + parse tree)
 *   - Current sub-PDF Uint8Array yielded: ~10 MB (transient — released after
 *     caller's iteration body returns)
 *   - Caller's base64 string: ~13 MB (transient — released after Sonnet call)
 *   = Peak ~53 MB during one segment, dropping back to ~30 MB between.
 *
 * Previous eager API held 3 × ~10 MB segments AND 3 × ~13 MB base64
 * simultaneously → ~100 MB on top of the ~30 MB source → killed the worker.
 */
export async function downloadAndStream(
  pdfUrl: string,
  userAgent: string,
  fetchTimeoutMs: number,
): Promise<{
  plan: SplitPlan;
  iterator: AsyncGenerator<PdfSegment, void, unknown>;
}> {
  const bytes = await downloadPdfBytes(pdfUrl, userAgent, fetchTimeoutMs);
  return await planAndStream(bytes);
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
 *
 * EAGER variant — builds all sub-PDFs up front. Use planAndStream() in the
 * hot path; this one stays for tests + small PDFs where the convenience is
 * worth more than the peak memory cost.
 */
export async function splitPdfBytes(bytes: Uint8Array): Promise<SplitOutcome> {
  const { plan, iterator } = await planAndStream(bytes);
  const segments: PdfSegment[] = [];
  for await (const seg of iterator) segments.push(seg);
  return { total_pages: plan.total_pages, segments };
}

/**
 * Streaming split: inspect total pages, return a plan + an async generator
 * that lazily yields each sub-PDF. The generator captures the source
 * PDFDocument in its closure so we don't reparse, but each sub-PDF
 * (PDFDocument.create + copy + save) is constructed on demand and falls out
 * of scope the moment the caller moves to the next iteration.
 *
 * Round 3 fix for WORKER_RESOURCE_LIMIT 546 on HE 72/2002 (143 pages).
 */
export async function planAndStream(
  bytes: Uint8Array,
): Promise<{
  plan: SplitPlan;
  iterator: AsyncGenerator<PdfSegment, void, unknown>;
}> {
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
  const segmentCount = totalPages <= PAGES_PER_SEGMENT
    ? 1
    : Math.ceil(totalPages / PAGES_PER_SEGMENT);
  const plan: SplitPlan = { total_pages: totalPages, segment_count: segmentCount };

  // Single-segment fast path: we yield the original bytes verbatim and never
  // touch the parse tree again.
  if (totalPages <= PAGES_PER_SEGMENT) {
    const singleBytes = bytes; // capture for the closure; we'll null it on exit.
    async function* one(): AsyncGenerator<PdfSegment, void, unknown> {
      yield { start_page: 1, end_page: totalPages, bytes: singleBytes };
      // After yield resumes the generator finishes and `src` falls out of scope.
    }
    return { plan, iterator: one() };
  }

  // Multi-segment streaming path. The generator does NOT pre-build sub-PDFs.
  async function* many(): AsyncGenerator<PdfSegment, void, unknown> {
    for (let start = 0; start < totalPages; start += PAGES_PER_SEGMENT) {
      const end = Math.min(start + PAGES_PER_SEGMENT, totalPages);
      // Build the sub-PDF for THIS segment only. `sub` and `subBytes`
      // are loop-local — once the caller's `for await` body completes and
      // the next iteration begins, they're eligible for GC.
      const sub = await PDFDocument.create();
      const indices: number[] = [];
      for (let i = start; i < end; i++) indices.push(i);
      const copied = await sub.copyPages(src, indices);
      for (const page of copied) sub.addPage(page);
      const subBytes = await sub.save({ useObjectStreams: true });
      yield { start_page: start + 1, end_page: end, bytes: subBytes };
      // (no explicit free needed — pdf-lib has no manual destructor; both
      // `sub` and `subBytes` become unreachable on the next iteration step
      // because there are no other references — the caller is responsible
      // for not retaining the yielded `bytes` past their iteration body.)
    }
  }
  return { plan, iterator: many() };
}

/**
 * Base64-encode raw bytes for an Anthropic `document.source.base64.data`.
 *
 * Memory shape (round 3 fix):
 *   - The old implementation built a binary string via `s += ...` 32 KB at
 *     a time. V8 reallocates `s` on each `+=` (O(n²) total memory churn,
 *     and a 2x peak when the final btoa() is called).
 *   - The new implementation pushes 32 KB binary-string slices into an
 *     array and joins() once — V8 builds the joined string with a single
 *     allocation. Peak intermediate memory ≈ 1.0× the binary length, then
 *     btoa() adds ~1.33× on top for the base64 result.
 *
 * For a 10 MB sub-PDF that's ~23 MB peak (down from ~33 MB) and avoids the
 * O(n²) churn that hits Supabase Edge's worker memory accounting.
 *
 * Kept here (separate from fetch_source.bytesToBase64) so the splitter is
 * self-contained for unit testing.
 */
export function segmentBytesToBase64(bytes: Uint8Array): string {
  const CHUNK = 32 * 1024;
  const parts: string[] = [];
  for (let i = 0; i < bytes.length; i += CHUNK) {
    const slice = bytes.subarray(i, Math.min(i + CHUNK, bytes.length));
    // String.fromCharCode.apply with 32K args is safe in V8/Deno (the arg
    // count limit is typically ~65K). Building the binary string this way
    // is the fastest path that doesn't run into the limit.
    parts.push(String.fromCharCode.apply(null, Array.from(slice)));
  }
  const binStr = parts.join("");
  // We don't need `parts` after join; let it go out of scope by ending the
  // function. btoa() returns a fresh ~1.33×-sized string.
  return btoa(binStr);
}
