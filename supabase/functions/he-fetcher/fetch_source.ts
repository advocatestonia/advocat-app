// he-fetcher/fetch_source.ts — pull HE PDF or eelnõu HTML, return plain text.
// -----------------------------------------------------------------------------
// We deliberately don't share `pdf-parser`'s pdfjs-dist pipeline here because:
//   * pdfjs-dist via npm: specifier requires the canvas shim only for image
//     extraction; we only want text, so we use the same import minus the
//     vision-OCR branch.
//   * The HE/eelnõu corpus is born-digital — no scans — so the OCR fallback
//     is dead weight for this worker.
//
// HTML branch:
//   - strip <script>, <style>, comments
//   - replace block-level tags with newlines
//   - collapse remaining tags
//   - decode the common HTML entities
//   - normalise whitespace
//
// Fetch behaviour:
//   - 30s timeout per document (legal portals are slow)
//   - User-Agent: identifies as Advocat — eduskunta.fi 403s an empty UA
//   - Follow redirects (Finlex moves older HEs around)
//   - Hard cap at 25 MB to bound memory
// -----------------------------------------------------------------------------

const FETCH_TIMEOUT_MS = 30_000;
const MAX_BYTES = 25 * 1024 * 1024;
const USER_AGENT =
  "AdvocatTravauxFetcher/1.0 (+https://advocat.ee; legal-aid AI)";

export interface FetchResult {
  text: string;
  contentType: "pdf" | "html";
  bytes: number;
}

export async function fetchSource(url: string): Promise<FetchResult> {
  const ctl = new AbortController();
  const timer = setTimeout(() => ctl.abort("fetch_timeout"), FETCH_TIMEOUT_MS);
  try {
    const res = await fetch(url, {
      headers: {
        "User-Agent": USER_AGENT,
        "Accept": "application/pdf,text/html;q=0.9,*/*;q=0.8",
      },
      redirect: "follow",
      signal: ctl.signal,
    });
    if (!res.ok) {
      throw new Error(`http ${res.status} ${res.statusText}`);
    }
    const ct = (res.headers.get("content-type") ?? "").toLowerCase();
    const buf = new Uint8Array(await res.arrayBuffer());
    if (buf.byteLength > MAX_BYTES) {
      throw new Error(`oversize: ${buf.byteLength} > ${MAX_BYTES}`);
    }
    if (ct.includes("pdf") || url.toLowerCase().endsWith(".pdf")) {
      const text = await pdfToText(buf);
      return { text, contentType: "pdf", bytes: buf.byteLength };
    }
    // HTML / XHTML — decode then strip.
    const decoder = new TextDecoder("utf-8");
    const html = decoder.decode(buf);
    const text = htmlToText(html);
    return { text, contentType: "html", bytes: buf.byteLength };
  } finally {
    clearTimeout(timer);
  }
}

/**
 * Lightweight PDF → text using pdfjs-dist. Mirrors pdf-parser's text-only
 * branch. Returns concatenated page text separated by form feeds so the
 * downstream Sonnet pass can still see page boundaries if needed.
 */
async function pdfToText(bytes: Uint8Array): Promise<string> {
  // Lazy import — keeps the cold-start lean for invocations that only do
  // queue dispatch / seeding.
  const pdfjsLib = await import(
    // deno-lint-ignore no-explicit-any
    "https://esm.sh/pdfjs-dist@4.0.379/legacy/build/pdf.mjs"
  ) as unknown as {
    getDocument: (opts: unknown) => { promise: Promise<PdfDocument> };
    GlobalWorkerOptions: { workerSrc: string };
  };
  // No worker — run inline. Edge Functions don't have a Worker runtime that
  // matches pdfjs's expected shape.
  pdfjsLib.GlobalWorkerOptions.workerSrc = "";

  const doc = await pdfjsLib.getDocument({
    data: bytes,
    disableFontFace: true,
    isEvalSupported: false,
    useSystemFonts: false,
  }).promise;

  const pages: string[] = [];
  for (let i = 1; i <= doc.numPages; i++) {
    const page = await doc.getPage(i);
    const content = await page.getTextContent();
    const items = content.items as Array<{ str?: string }>;
    const txt = items.map((it) => it.str ?? "").join(" ");
    pages.push(txt);
  }
  return pages.join("\n\f\n");
}

interface PdfDocument {
  numPages: number;
  getPage: (n: number) => Promise<{
    getTextContent: () => Promise<{ items: Array<{ str?: string }> }>;
  }>;
}

/**
 * Minimal HTML → text. Good enough for Riigikogu eelnõu pages, which are
 * server-rendered HTML with clean semantic markup. We intentionally do NOT
 * pull in a full DOM parser — keeps the cold-start fast and avoids the
 * regex-vs-DOM tar-pit. Sonnet will tolerate light residual whitespace.
 */
export function htmlToText(html: string): string {
  if (!html) return "";
  let s = html;
  // Drop <script>, <style>, <!-- ... -->
  s = s.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, " ");
  s = s.replace(/<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>/gi, " ");
  s = s.replace(/<!--[\s\S]*?-->/g, " ");
  // Block-level tags → newline
  s = s.replace(
    /<\/?(p|div|section|article|li|tr|td|th|h[1-6]|br|hr|table|thead|tbody|ul|ol)\b[^>]*>/gi,
    "\n",
  );
  // All other tags away
  s = s.replace(/<[^>]+>/g, " ");
  // Decode common entities
  s = s
    .replace(/&nbsp;/gi, " ")
    .replace(/&amp;/gi, "&")
    .replace(/&lt;/gi, "<")
    .replace(/&gt;/gi, ">")
    .replace(/&quot;/gi, '"')
    .replace(/&#39;/gi, "'")
    .replace(/&#x([0-9a-f]+);/gi, (_, hex) => {
      const code = parseInt(hex, 16);
      return Number.isFinite(code) ? String.fromCodePoint(code) : " ";
    })
    .replace(/&#(\d+);/g, (_, dec) => {
      const code = parseInt(dec, 10);
      return Number.isFinite(code) ? String.fromCodePoint(code) : " ";
    });
  // Collapse whitespace runs but preserve paragraph breaks
  s = s.replace(/[\t ]+/g, " ").replace(/\n{3,}/g, "\n\n");
  return s.trim();
}
