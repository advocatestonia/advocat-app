// he-fetcher/fetch_source.ts — pull HE / eelnõu content.
// -----------------------------------------------------------------------------
// We return EITHER plain text (HTML pages) OR raw PDF bytes (for documents
// where Claude's native PDF support is the more reliable path). The previous
// implementation tried pdfjs-dist in Deno, but Supabase Edge Runtime started
// rejecting the `npm:pdfjs-dist@4.0.379/legacy/build/pdf.mjs` specifier with
// "Could not find constraint" on freshly-deployed functions (the pdf-parser
// function only works because it was deployed before the regression).
//
// Two source families:
//
//   1. Finlex HE pages (finlex.fi/fi/hallituksen-esitykset/{year}/{n}):
//      Server-rendered HTML containing a
//      "/api/media/government-proposal/{id}/mainPdf/main.pdf" URL we extract.
//      We always prefer the PDF — Finlex HTML is a Next.js SPA that does NOT
//      render the HE text server-side.
//
//   2. Riigikogu eelnõu pages (riigikogu.ee/tegevus/eelnoud/eelnou/{uuid}):
//      WordPress-rendered HTML where the actual bill text + seletuskiri
//      live behind /download/{guid} links. We scrape the landing page
//      for the first link whose anchor text matches Seletuskiri /
//      Eelnõu pdf / Algtekst, then re-fetch that PDF.
//
// HTML fallback branch:
//   - strip <script>, <style>, comments
//   - replace block-level tags with newlines
//   - collapse remaining tags
//   - decode the common HTML entities
//   - normalise whitespace
//
// Fetch behaviour:
//   - 30s timeout per HTTP step (legal portals are slow)
//   - User-Agent: identifies as Advocat
//   - Follow redirects (Finlex moves older HEs around)
//   - Hard cap at 50 MB to bound memory
//   - Max 2 hops for landing-page → PDF discovery
// -----------------------------------------------------------------------------

const FETCH_TIMEOUT_MS = 30_000;
// 50 MB — older HE PDFs (e.g. HE 94/1993 rikoslaki-uudistus) are 30+ MB.
const MAX_BYTES = 50 * 1024 * 1024;
const USER_AGENT =
  "AdvocatTravauxFetcher/1.0 (+https://advocat.ee; legal-aid AI)";

export interface FetchResult {
  /** Plain text. Empty string when contentType === "pdf" — Anthropic fetches the URL. */
  text: string;
  contentType: "pdf" | "html";
  /** Bytes inspected (0 for PDFs since we only HEAD-check). */
  bytes: number;
  /** Resolved URL — for PDFs, this is what we pass to Anthropic as document.source.url. */
  resolvedUrl: string;
}

export async function fetchSource(url: string): Promise<FetchResult> {
  const u = new URL(url);
  // Strategy 1: Finlex HE page → extract embedded PDF URL.
  if (
    u.hostname.includes("finlex.fi") &&
    u.pathname.includes("/hallituksen-esitykset/")
  ) {
    const pdfUrl = await discoverFinlexPdf(url);
    if (pdfUrl) {
      await assertPdfReachable(pdfUrl);
      return { text: "", contentType: "pdf", bytes: 0, resolvedUrl: pdfUrl };
    }
    // Fall back to HTML (unlikely to be useful — Finlex is a Next.js SPA).
    return await fetchHtml(url);
  }
  // Strategy 2: Riigikogu eelnõu page → discover the seletuskiri/algtekst PDF.
  if (
    u.hostname.includes("riigikogu.ee") &&
    u.pathname.includes("/tegevus/eelnoud/")
  ) {
    const pdfUrl = await discoverRiigikoguPdf(url);
    if (pdfUrl) {
      await assertPdfReachable(pdfUrl);
      return { text: "", contentType: "pdf", bytes: 0, resolvedUrl: pdfUrl };
    }
    return await fetchHtml(url);
  }
  // Default: probe content-type. If it's a PDF, return URL; otherwise HTML.
  return await fetchAny(url);
}

/**
 * HEAD-check (with GET fallback) that the PDF URL is fetchable and the
 * server returns a content-type containing "pdf". Throws on 4xx/5xx.
 */
async function assertPdfReachable(pdfUrl: string): Promise<void> {
  const ctl = new AbortController();
  const timer = setTimeout(() => ctl.abort("head_timeout"), FETCH_TIMEOUT_MS);
  try {
    // Try HEAD first.
    let res = await fetch(pdfUrl, {
      method: "HEAD",
      headers: { "User-Agent": USER_AGENT },
      redirect: "follow",
      signal: ctl.signal,
    });
    if (!res.ok) {
      // Some CDNs (e.g. eduskunta) don't support HEAD; fall back to GET-range.
      res = await fetch(pdfUrl, {
        method: "GET",
        headers: {
          "User-Agent": USER_AGENT,
          "Range": "bytes=0-1023",
        },
        redirect: "follow",
        signal: ctl.signal,
      });
      if (!res.ok && res.status !== 206) {
        throw new Error(`http ${res.status} ${res.statusText}`);
      }
      // Drain body so the connection closes cleanly.
      await res.arrayBuffer();
    }
    const ct = (res.headers.get("content-type") ?? "").toLowerCase();
    if (!ct.includes("pdf") && !pdfUrl.toLowerCase().endsWith(".pdf")) {
      throw new Error(`expected PDF, got content-type=${ct}`);
    }
  } finally {
    clearTimeout(timer);
  }
}

/**
 * Fetch a URL, decode as HTML, strip tags.
 */
async function fetchHtml(url: string): Promise<FetchResult> {
  const ctl = new AbortController();
  const timer = setTimeout(() => ctl.abort("fetch_timeout"), FETCH_TIMEOUT_MS);
  try {
    const res = await fetch(url, {
      headers: {
        "User-Agent": USER_AGENT,
        "Accept": "text/html,*/*;q=0.8",
      },
      redirect: "follow",
      signal: ctl.signal,
    });
    if (!res.ok) {
      throw new Error(`http ${res.status} ${res.statusText}`);
    }
    const buf = new Uint8Array(await res.arrayBuffer());
    if (buf.byteLength > MAX_BYTES) {
      throw new Error(`oversize: ${buf.byteLength} > ${MAX_BYTES}`);
    }
    const decoder = new TextDecoder("utf-8");
    const html = decoder.decode(buf);
    const text = htmlToText(html);
    return { text, contentType: "html", bytes: buf.byteLength, resolvedUrl: url };
  } finally {
    clearTimeout(timer);
  }
}

/**
 * Generic fetch — sniffs content-type to decide PDF-pass-through vs HTML-decode.
 */
async function fetchAny(url: string): Promise<FetchResult> {
  // First, HEAD to sniff content-type.
  const ctl = new AbortController();
  const timer = setTimeout(() => ctl.abort("head_timeout"), FETCH_TIMEOUT_MS);
  try {
    const head = await fetch(url, {
      method: "HEAD",
      headers: { "User-Agent": USER_AGENT },
      redirect: "follow",
      signal: ctl.signal,
    });
    const ct = (head.headers.get("content-type") ?? "").toLowerCase();
    if (head.ok && (ct.includes("pdf") || url.toLowerCase().endsWith(".pdf"))) {
      return { text: "", contentType: "pdf", bytes: 0, resolvedUrl: url };
    }
  } catch {
    // Fall through to HTML path.
  } finally {
    clearTimeout(timer);
  }
  return await fetchHtml(url);
}

/**
 * Discover the embedded PDF URL on a Finlex HE page.
 * The page HTML contains one or more
 * `/api/media/government-proposal/{id}/mainPdf/main.pdf` strings.
 * Returns null if none found.
 */
export async function discoverFinlexPdf(pageUrl: string): Promise<string | null> {
  const ctl = new AbortController();
  const timer = setTimeout(() => ctl.abort("discover_timeout"), FETCH_TIMEOUT_MS);
  try {
    const res = await fetch(pageUrl, {
      headers: { "User-Agent": USER_AGENT, "Accept": "text/html" },
      redirect: "follow",
      signal: ctl.signal,
    });
    if (!res.ok) return null;
    const html = await res.text();
    const m =
      /\/api\/media\/government-proposal\/(\d+)\/mainPdf\/main\.pdf[^"\\]*/g.exec(
        html,
      );
    if (!m) return null;
    const path = m[0].replace(/\\/g, "");
    return new URL(path, "https://www.finlex.fi").toString();
  } catch {
    return null;
  } finally {
    clearTimeout(timer);
  }
}

/**
 * Discover the Seletuskiri / Algtekst / Eelnõu PDF on a Riigikogu eelnõu page.
 * Priority (descending) — pick the first match in HTML order:
 *   1. anchor text contains "seletuskiri" AND "pdf"
 *   2. anchor text contains "eelnõu" AND "pdf"
 *   3. anchor text contains just "seletuskiri" (some labels omit "pdf")
 *   4. anchor text contains "algtekst" (the old IX-coosseis bills have no
 *      seletuskiri but the algtekst PDF is the bill text itself)
 *   5. anchor text contains "lõpptekst"
 *
 * Returns the absolute URL or null.
 */
export async function discoverRiigikoguPdf(pageUrl: string): Promise<string | null> {
  const ctl = new AbortController();
  const timer = setTimeout(() => ctl.abort("discover_timeout"), FETCH_TIMEOUT_MS);
  try {
    const res = await fetch(pageUrl, {
      headers: { "User-Agent": USER_AGENT, "Accept": "text/html" },
      redirect: "follow",
      signal: ctl.signal,
    });
    if (!res.ok) return null;
    const html = await res.text();
    // Extract all `<a href="/download/{guid}" ...>label</a>` pairs in HTML order.
    const anchors: Array<{ href: string; label: string }> = [];
    const reAnchor =
      /<a\s+[^>]*href="(\/download\/[a-f0-9-]+)"[^>]*>([^<]+)<\/a>/gi;
    for (let m = reAnchor.exec(html); m; m = reAnchor.exec(html)) {
      anchors.push({ href: m[1], label: m[2].trim().toLowerCase() });
    }
    if (anchors.length === 0) return null;
    const find = (pred: (l: string) => boolean): string | null => {
      const hit = anchors.find((a) => pred(a.label));
      return hit ? new URL(hit.href, "https://www.riigikogu.ee").toString() : null;
    };
    return (
      find((l) => l.includes("seletuskiri") && l.includes("pdf")) ??
      find((l) => l.includes("eelnõu") && l.includes("pdf")) ??
      find((l) => l.includes("seletuskiri")) ??
      find((l) => l.includes("algtekst") && !l.includes("ddoc")) ??
      find((l) => l.includes("algtekst")) ??
      find((l) => l.includes("lõpptekst"))
    );
  } catch {
    return null;
  } finally {
    clearTimeout(timer);
  }
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

/**
 * Base64-encode raw bytes for Claude's PDF document content block.
 * Uses chunked encoding to avoid a 2x-memory peak on large PDFs.
 */
export function bytesToBase64(bytes: Uint8Array): string {
  // btoa() can't handle large strings; chunk into 32 KB pieces.
  const CHUNK = 32 * 1024;
  let s = "";
  for (let i = 0; i < bytes.length; i += CHUNK) {
    const slice = bytes.subarray(i, Math.min(i + CHUNK, bytes.length));
    s += String.fromCharCode.apply(null, Array.from(slice));
  }
  return btoa(s);
}
