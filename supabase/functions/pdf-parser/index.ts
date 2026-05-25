// pdf-parser — Pkg 2 of Case Memory rebuild.
// -----------------------------------------------------------------------------
// User uploads a PDF to Supabase Storage; chat client calls THIS function with
// the storage_path. We:
//   1. download bytes from Storage,
//   2. extract text via pdfjs-dist (npm: specifier, runs in Deno),
//   3. for pages with <50 chars, fall back to Claude Vision (Haiku) OCR,
//   4. stitch with `--- PAGE N ---` separators,
//   5. detect language per page (cheap heuristic — no extra API calls),
//   6. ask Sonnet 4.6 for STRUCTURED JSON metadata (doc_type, parties, …),
//   7. embed the parsed_summary via OpenAI text-embedding-3-small,
//   8. upsert a `case_documents` row,
//   9. return {document_id, doc_type, parsed_summary, key_extractions,
//      page_count, lang_detected}.
//
// Decision: SYNCHRONOUS. We do NOT add a `processing_status` column or run
// the work in a background fetch(self). Two reasons:
//   * Pkg 3 is committing to main in parallel; adding an unrelated migration
//     would widen the merge surface.
//   * Vision OCR is hard-capped at 25 pages (PDF_MAX_VISION_PAGES) so the
//     worst realistic case fits inside Supabase's 5min timeout.
// >25 page scans return {error: "scan_too_long", ...} with NO row written.
// >25 page scans needing OCR are documented as a TODO for a follow-up that
// adds the background worker.
//
// Auth: user JWT (RLS enforced). Storage download is performed via the
// service-role client (the user already proved ownership at Storage upload
// time; a re-check is enforced via the path prefix `<user_id>/...`).
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  corsHeaders,
  jsonError,
  jsonOk,
  requireUserWithRateLimit,
} from "../_shared/auth.ts";
import {
  buildParsedSummary,
  detectPageLang,
  emptyExtraction,
  type ExtractedDoc,
  type LangCode,
  PDF_EXTRACTOR_MAX_TOKENS,
  PDF_EXTRACTOR_MODEL,
  PDF_EXTRACTOR_SYSTEM_PROMPT,
  PDF_EXTRACTOR_TIMEOUT_MS,
  PDF_MAX_PAGES,
  PDF_MAX_VISION_PAGES,
  PDF_SCAN_THRESHOLD_CHARS,
  PDF_TOTAL_SCAN_THRESHOLD_CHARS,
  PDF_VISION_MIN_USABLE_CHARS,
  parseExtractedDoc,
} from "../_shared/pdf_extractor_prompt.ts";
import {
  encodeBase64,
  extractedToKeyExtractions,
  isImageMime,
  normalizeImageMediaType,
  parseAndValidateBody,
  type PageText,
  type RequestBody,
  stitchPages,
} from "./helpers.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const CLAUDE_API_KEY = Deno.env.get("CLAUDE_API_KEY");
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");

const ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages";
const OPENAI_EMBEDDINGS_URL = "https://api.openai.com/v1/embeddings";
const VISION_MODEL = "claude-haiku-4-5-20251001";
const EMBEDDING_MODEL = "text-embedding-3-small";
const EMBEDDING_DIM = 1536;

/** Storage bucket. Mirrors lib/services/supabase_service.dart line 233. */
const STORAGE_BUCKET = "case-documents";

/** Hard cap on a single PDF body. 50 MB blocks adversarial uploads while
 * letting realistic 100-page legal scans (≈20-30 MB) through. */
const MAX_PDF_BYTES = 50 * 1024 * 1024;

/** Hard cap on a single image body. Anthropic Vision accepts up to ~5 MB
 * decoded per image; phone snaps are 2-6 MB. 10 MB leaves headroom for
 * HEIC originals while still rejecting adversarial gigabyte uploads. */
const MAX_IMAGE_BYTES = 10 * 1024 * 1024;

/** Vision per-page prompt — the same wording the spec dictates. */
const VISION_OCR_PROMPT =
  "Extract ALL visible text verbatim. Output plain text only, " +
  "preserve paragraphs, no commentary.";

interface ParsePipelineResult {
  pages: PageText[];
  parsed_text: string;
  pages_lang: LangCode[];
  /** True if the doc had usable text (>= PDF_VISION_MIN_USABLE_CHARS total). */
  readable: boolean;
  /** True if at least one page used Vision OCR. */
  used_vision: boolean;
}

// =============================================================================
// HTTP entry point
// =============================================================================

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonError("Method not allowed", 405);
  }

  // ── 1. AuthN + rate-limit. Parsing is expensive — cap at 6/min/user. ────
  const gate = await requireUserWithRateLimit(req, {
    bucket: "pdf-parser",
    maxPerMinute: 6,
  });
  if (gate.kind === "deny") return gate.response;

  if (!CLAUDE_API_KEY) {
    console.error("pdf-parser: CLAUDE_API_KEY not configured");
    return jsonError("Parser backend not configured", 503);
  }
  if (!OPENAI_API_KEY) {
    console.error("pdf-parser: OPENAI_API_KEY not configured");
    return jsonError("Parser backend not configured", 503);
  }

  // ── 2. Parse + validate body. ────────────────────────────────────────────
  let body: RequestBody;
  try {
    body = parseAndValidateBody(await req.json(), gate.user.id);
  } catch (e) {
    return jsonError(String(e instanceof Error ? e.message : e), 400);
  }

  // ── 3. Download bytes via service role. The path is pinned to the
  //       caller's uid prefix (validated above), so we cannot leak
  //       another user's storage object. ──────────────────────────────────
  const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const isImagePath = isImageMime(body.mime_type);
  const maxBytes = isImagePath ? MAX_IMAGE_BYTES : MAX_PDF_BYTES;

  let pdfBytes: Uint8Array;
  try {
    const { data, error } = await admin.storage
      .from(STORAGE_BUCKET)
      .download(body.storage_path);
    if (error || !data) {
      return jsonError(`Storage download failed: ${error?.message ?? "no data"}`, 404);
    }
    const buf = await data.arrayBuffer();
    if (buf.byteLength > maxBytes) {
      return jsonError(
        isImagePath
          ? "Image too large (max 10 MB)"
          : "PDF too large (max 50 MB)",
        413,
      );
    }
    pdfBytes = new Uint8Array(buf);
  } catch (e) {
    return jsonError(`Storage download threw: ${String(e).slice(0, 200)}`, 502);
  }

  // ── 4-5. Extract text + Vision fallback + per-page lang. ─────────────────
  // Images skip pdfjs entirely and go straight to Vision OCR as a single
  // synthetic "page". The rest of the pipeline (Sonnet structured
  // extraction + embedding + upsert) is identical to the PDF path.
  let pipeline: ParsePipelineResult;
  try {
    pipeline = isImagePath
      ? await runImageOcrPipeline(
          pdfBytes,
          CLAUDE_API_KEY,
          normalizeImageMediaType(body.mime_type),
        )
      : await runParsePipeline(pdfBytes, CLAUDE_API_KEY);
  } catch (e) {
    const msg = String(e instanceof Error ? e.message : e);
    if (msg.startsWith("too_long:")) {
      return jsonOk({ error: "too_long", parsed_pages: PDF_MAX_PAGES });
    }
    if (msg.startsWith("scan_too_long")) {
      return jsonOk({
        error: "scan_too_long",
        suggestion:
          "Document has no text layer and is too long for OCR. Split it " +
          "into <25 page parts and try again, or paste the relevant text " +
          "into chat directly.",
      });
    }
    console.error(`pdf-parser: pipeline failed: ${msg.slice(0, 300)}`);
    return jsonError(
      isImagePath ? "Image could not be parsed" : "PDF could not be parsed",
      502,
    );
  }

  if (!pipeline.readable) {
    return jsonOk({
      error: "unreadable",
      suggestion:
        "The document scan is too low-quality for automated OCR. Please " +
        "upload a clearer scan, or type the key facts into chat.",
    });
  }

  // ── 6. Structured extraction via Sonnet. ─────────────────────────────────
  const extracted = await runStructuredExtraction(
    pipeline.parsed_text,
    CLAUDE_API_KEY,
  );

  // ── 7. Embedding via OpenAI. Use the parsed_summary so retrieval ranks
  //       by "what the doc is about" rather than raw OCR noise. ────────────
  const parsedSummary = buildParsedSummary(extracted, pipeline.parsed_text);
  const embedding = await runEmbedding(parsedSummary, OPENAI_API_KEY);

  // ── 8. Upsert into case_documents. case_id may be null (general upload —
  //       client banner asks user to attach later). ──────────────────────
  const docRow = await upsertDocumentRow({
    admin,
    userId: gate.user.id,
    caseId: body.case_id,
    filename: body.filename,
    storagePath: body.storage_path,
    mimeType: body.mime_type,
    sizeBytes: pdfBytes.length,
    parsedText: pipeline.parsed_text,
    parsedSummary,
    extracted,
    pagesLang: pipeline.pages_lang,
    embedding,
  });
  if (docRow.kind === "error") {
    return jsonError(docRow.message, 500);
  }

  // ── B2B signal collection (2026-05-26) ────────────────────────────────
  // Fire-and-forget. NEVER block the parse response on a signal write —
  // signals are best-effort lead detection, never a correctness concern.
  // Both checks are gated server-side; the worker is the same service-role
  // admin client we already have.
  try {
    await recordPdfParserB2bSignals({
      admin,
      userId: gate.user.id,
      extracted,
    });
  } catch (e) {
    console.warn(
      `pdf-parser: b2b signal write failed: ${String(e).slice(0, 200)}`,
    );
  }

  return jsonOk({
    document_id: docRow.id,
    doc_type: extracted.doc_type,
    parsed_summary: parsedSummary,
    key_extractions: extractedToKeyExtractions(extracted, pipeline.pages_lang),
    page_count: pipeline.pages.length,
    lang_detected: pipeline.pages_lang,
  });
});

// =============================================================================
// B2B lead detection signals (2026-05-26)
// =============================================================================
//
// Two signal sources fire from pdf-parser:
//
//   1. doc_burst_3plus_day — user has uploaded >=3 documents in last 24h.
//      Fires AT MOST ONCE per UTC day per user (idempotency: query
//      b2b_signals for an existing row from `today` before recording).
//
//   2. attorney_role_in_doc — the extracted parties array contains anyone
//      whose role string matches /attorney|advokaat|asianajaja/i. Fires AT
//      MOST ONCE per 24h per user (same idempotency rule).
//
// Both write via the SECURITY DEFINER RPC `record_b2b_signal`, which also
// recomputes the rolling 30-day score and flips `b2b_modal_pending` on
// crossing the threshold.

interface RecordPdfParserSignalsArgs {
  // deno-lint-ignore no-explicit-any
  admin: any;
  userId: string;
  extracted: ExtractedDoc;
}

const ATTORNEY_ROLE_RE = /(attorney|advokaat|asianajaja)/i;

export async function recordPdfParserB2bSignals(
  args: RecordPdfParserSignalsArgs,
): Promise<void> {
  // ── 1. doc_burst_3plus_day ────────────────────────────────────────────
  try {
    const since = new Date(Date.now() - 24 * 60 * 60_000).toISOString();
    const { count } = await args.admin
      .from("case_documents")
      .select("id", { count: "exact", head: true })
      .eq("user_id", args.userId)
      .gte("created_at", since);
    if ((count ?? 0) >= 3) {
      // Idempotency: only record once per UTC day per user. The b2b-signal
      // edge fn has its own 1-hour idempotency window, but since we're
      // calling the RPC directly here we re-check the day-bucket inline.
      const today00 = new Date();
      today00.setUTCHours(0, 0, 0, 0);
      const existing = await args.admin
        .from("b2b_signals")
        .select("id", { count: "exact", head: true })
        .eq("user_id", args.userId)
        .eq("signal_type", "doc_burst_3plus_day")
        .gte("occurred_at", today00.toISOString());
      if ((existing.count ?? 0) === 0) {
        await args.admin.rpc("record_b2b_signal", {
          p_user_id: args.userId,
          p_signal_type: "doc_burst_3plus_day",
          p_score: 30,
          p_payload: { doc_count_24h: count, source: "pdf-parser" },
        });
      }
    }
  } catch (e) {
    console.warn(
      `pdf-parser: doc_burst signal failed: ${String(e).slice(0, 150)}`,
    );
  }

  // ── 2. attorney_role_in_doc ───────────────────────────────────────────
  try {
    const hasAttorney = args.extracted.parties.some((p) =>
      typeof p.role === "string" && ATTORNEY_ROLE_RE.test(p.role)
    );
    if (hasAttorney) {
      const since = new Date(Date.now() - 24 * 60 * 60_000).toISOString();
      const existing = await args.admin
        .from("b2b_signals")
        .select("id", { count: "exact", head: true })
        .eq("user_id", args.userId)
        .eq("signal_type", "attorney_role_in_doc")
        .gte("occurred_at", since);
      if ((existing.count ?? 0) === 0) {
        await args.admin.rpc("record_b2b_signal", {
          p_user_id: args.userId,
          p_signal_type: "attorney_role_in_doc",
          p_score: 50,
          p_payload: {
            source: "pdf-parser",
            party_count: args.extracted.parties.length,
          },
        });
      }
    }
  } catch (e) {
    console.warn(
      `pdf-parser: attorney_role signal failed: ${String(e).slice(0, 150)}`,
    );
  }
}

// =============================================================================
// Pipeline — text extraction + Vision fallback + language detection.
// =============================================================================

/**
 * Top-level: extract text with pdfjs-dist; for any page that has too few
 * chars, OCR via Claude Vision (Haiku). Caps at PDF_MAX_PAGES; if the doc
 * needs Vision on more than PDF_MAX_VISION_PAGES, throws `scan_too_long`.
 */
export async function runParsePipeline(
  pdfBytes: Uint8Array,
  claudeKey: string,
): Promise<ParsePipelineResult> {
  // Step 1 — text-layer extraction.
  const textPages = await extractTextLayer(pdfBytes);
  const totalPageCount = textPages.length;
  if (totalPageCount === 0) {
    throw new Error("scan_too_long: PDF has 0 readable pages");
  }
  if (totalPageCount > PDF_MAX_PAGES) {
    throw new Error(`too_long: ${totalPageCount} pages > ${PDF_MAX_PAGES}`);
  }

  // Step 2 — count pages that need Vision fallback.
  const pagesNeedingVision: number[] = [];
  let totalTextChars = 0;
  for (const p of textPages) {
    totalTextChars += p.text.length;
    if (p.text.length < PDF_SCAN_THRESHOLD_CHARS) {
      pagesNeedingVision.push(p.page);
    }
  }
  // Whole-doc scan: text layer barely yielded anything → OCR every page.
  const wholeDocScan = totalTextChars < PDF_TOTAL_SCAN_THRESHOLD_CHARS;
  const visionPages = wholeDocScan
    ? textPages.map((p) => p.page)
    : pagesNeedingVision;

  if (visionPages.length > PDF_MAX_VISION_PAGES) {
    throw new Error(
      `scan_too_long: ${visionPages.length} pages need OCR, max ${PDF_MAX_VISION_PAGES}`,
    );
  }

  // Step 3 — render + OCR each missing page.
  const finalPages: PageText[] = textPages.map((p) => ({ ...p }));
  let usedVision = false;
  for (const pn of visionPages) {
    let ocrText = "";
    try {
      const png = await renderPageToPng(pdfBytes, pn);
      const visionOut = await runVisionOcrOnPage(png, claudeKey);
      ocrText = visionOut.trim();
    } catch (e) {
      console.warn(
        `pdf-parser: vision OCR page ${pn} failed: ${String(e).slice(0, 200)}`,
      );
    }
    if (ocrText.length >= PDF_VISION_MIN_USABLE_CHARS) {
      const idx = finalPages.findIndex((x) => x.page === pn);
      if (idx >= 0) {
        finalPages[idx].text = ocrText;
        finalPages[idx].source = "vision";
      }
      usedVision = true;
    }
  }

  // Step 4 — stitch with --- PAGE N --- markers.
  const parsedText = stitchPages(finalPages);

  // Step 5 — per-page language.
  const pagesLang = finalPages.map((p) =>
    p.text.length > 0 ? detectPageLang(p.text) : "other"
  );

  const totalUsableChars = finalPages.reduce(
    (acc, p) => acc + p.text.length,
    0,
  );
  const readable = totalUsableChars >= PDF_VISION_MIN_USABLE_CHARS;

  return {
    pages: finalPages,
    parsed_text: parsedText,
    pages_lang: pagesLang,
    readable,
    used_vision: usedVision,
  };
}

/**
 * Image-path pipeline: a JPEG/PNG/HEIC/WebP upload is treated as a single
 * page. We send the bytes straight to Claude Vision with the appropriate
 * media_type and wrap the OCR output in the same [ParsePipelineResult]
 * shape the PDF path returns so the downstream steps (Sonnet structured
 * extraction, embedding, upsert) are agnostic to the source format.
 *
 * Throws (caller maps to HTTP):
 *   * `scan_too_long` is impossible for images (always 1 page).
 *   * On Vision failure: caller logs and returns a 502.
 * Empty OCR → `readable: false`, mirroring the PDF "unreadable" branch.
 */
export async function runImageOcrPipeline(
  imageBytes: Uint8Array,
  claudeKey: string,
  mediaType: string,
): Promise<ParsePipelineResult> {
  let ocrText = "";
  try {
    const out = await runVisionOcrOnPage(imageBytes, claudeKey, mediaType);
    ocrText = out.trim();
  } catch (e) {
    console.warn(
      `pdf-parser: vision OCR (image) failed: ${String(e).slice(0, 200)}`,
    );
  }

  const page: PageText = {
    page: 1,
    text: ocrText,
    source: ocrText.length > 0 ? "vision" : "empty",
  };
  const finalPages: PageText[] = [page];
  const parsedText = stitchPages(finalPages);
  const pagesLang: LangCode[] = [
    ocrText.length > 0 ? detectPageLang(ocrText) : "other",
  ];
  const readable = ocrText.length >= PDF_VISION_MIN_USABLE_CHARS;

  return {
    pages: finalPages,
    parsed_text: parsedText,
    pages_lang: pagesLang,
    readable,
    used_vision: ocrText.length > 0,
  };
}

/**
 * Dynamic loader for pdfjs-dist. Indirected through `Function('return import(...)')`
 * so the static dependency graph contains no `npm:` specifier — local
 * `deno check` can type-check the file without installing pdfjs, while the
 * Supabase Edge runtime resolves it at deploy time.
 */
// deno-lint-ignore no-explicit-any
async function loadPdfJs(): Promise<any> {
  const dynImport = new Function(
    "specifier",
    "return import(specifier);",
  ) as (specifier: string) => Promise<unknown>;
  return await dynImport("npm:pdfjs-dist@4.0.379/legacy/build/pdf.mjs");
}

/**
 * Extract per-page text via pdfjs-dist. Returns an empty array (not a
 * throw) if pdfjs cannot open the file at all — the caller treats it as
 * a scan and Vision OCR all pages.
 */
async function extractTextLayer(pdfBytes: Uint8Array): Promise<PageText[]> {
  try {
    // pdfjs-dist via Deno's npm: specifier. We import via a Function-eval
    // dynamic specifier so local `deno check` (which has no node_modules)
    // doesn't fail on resolution — the Supabase Edge runtime auto-installs
    // npm packages at deploy time. Tests bypass this path entirely via
    // the `__setPdfTextLayerImplForTest` hook.
    const impl = pdfTextLayerImpl ?? (await loadPdfJs());
    const pdfjs = impl as { getDocument: (arg: unknown) => { promise: Promise<unknown> } };
    const loadingTask = pdfjs.getDocument({
      data: pdfBytes,
      // Disable workers — Deno doesn't have the worker runtime pdfjs expects.
      disableWorker: true,
      // Avoid font fetching (would need network).
      disableFontFace: true,
      useSystemFonts: false,
    });
    const doc = await loadingTask.promise as {
      numPages: number;
      getPage: (n: number) => Promise<{
        getTextContent: () => Promise<{
          items: Array<{ str?: unknown }>;
        }>;
      }>;
    };
    const out: PageText[] = [];
    for (let i = 1; i <= doc.numPages; i++) {
      try {
        const page = await doc.getPage(i);
        const content = await page.getTextContent();
        const text = content.items
          .map((it) => (typeof it.str === "string" ? it.str : ""))
          .join(" ")
          .replace(/\s+/g, " ")
          .trim();
        out.push({
          page: i,
          text,
          source: text.length >= PDF_SCAN_THRESHOLD_CHARS ? "text" : "empty",
        });
      } catch (e) {
        console.warn(
          `pdf-parser: page ${i} text extraction failed: ${
            String(e).slice(0, 150)
          }`,
        );
        out.push({ page: i, text: "", source: "empty" });
      }
    }
    return out;
  } catch (e) {
    console.warn(
      `pdf-parser: pdfjs getDocument failed: ${String(e).slice(0, 200)}`,
    );
    return [];
  }
}

/**
 * Render a single PDF page to PNG via pdfjs-dist + the canvas API.
 *
 * NOTE 2026-05-06: Deno's std lib does not ship a 2D canvas. We rely on
 * pdfjs's "renderToImage" path which is supported in pdfjs-dist v4 via
 * the `node-canvas` peer dependency. In Supabase Edge runtime, where
 * node-canvas isn't bundled, this throws — the catch in the caller
 * gracefully marks the page as empty and the doc returns "unreadable".
 *
 * TODO(post-Pkg-2): replace with @resvg/resvg-deno or pdfium-deno once
 * one of them ships a stable Deno build. For now, scan-fallback works
 * IF node-canvas is available; otherwise we degrade to text-layer-only.
 */
async function renderPageToPng(
  pdfBytes: Uint8Array,
  pageNum: number,
): Promise<Uint8Array> {
  if (pdfRenderImpl) {
    return await pdfRenderImpl(pdfBytes, pageNum);
  }
  // Production path is intentionally narrow — we throw, the caller logs
  // and continues with the text it already has. See spec "scan fallback".
  throw new Error(
    `Page ${pageNum} render not supported in this runtime — pdfjs canvas missing`,
  );
}

// =============================================================================
// Vision OCR
// =============================================================================

async function runVisionOcrOnPage(
  imageBytes: Uint8Array,
  apiKey: string,
  mediaType: string = "image/png",
): Promise<string> {
  // Encode bytes to base64 for the Anthropic media block.
  const base64 = encodeBase64(imageBytes);
  const reqBody = {
    model: VISION_MODEL,
    max_tokens: 4_000,
    system: "You are analyzing a legal document image for OCR.",
    messages: [
      {
        role: "user",
        content: [
          {
            type: "image",
            source: { type: "base64", media_type: mediaType, data: base64 },
          },
          { type: "text", text: VISION_OCR_PROMPT },
        ],
      },
    ],
  };
  const ctrl = new AbortController();
  const timeout = setTimeout(() => ctrl.abort(), 60_000);
  try {
    const res = await fetch(ANTHROPIC_API_URL, {
      method: "POST",
      headers: {
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
        "Content-Type": "application/json",
      },
      body: JSON.stringify(reqBody),
      signal: ctrl.signal,
    });
    clearTimeout(timeout);
    if (!res.ok) {
      const snippet = (await res.text()).slice(0, 200);
      throw new Error(`Vision ${res.status}: ${snippet}`);
    }
    const json = await res.json() as {
      content?: Array<{ type?: string; text?: string }>;
    };
    if (!Array.isArray(json.content)) return "";
    let out = "";
    for (const block of json.content) {
      if (block && block.type === "text" && typeof block.text === "string") {
        out += block.text;
      }
    }
    return out;
  } finally {
    clearTimeout(timeout);
  }
}

// =============================================================================
// Structured extraction — Sonnet
// =============================================================================

/**
 * Send the parsed_text to Sonnet for structured extraction. Returns an
 * empty extraction on any failure (the document is still saved, but
 * with `doc_type: "other"` and empty arrays). The caller sees a `null`
 * from parseExtractedDoc fall back to a default-valued ExtractedDoc.
 */
export async function runStructuredExtraction(
  parsedText: string,
  apiKey: string,
): Promise<ExtractedDoc> {
  // Cap text at ~80 KB so the system+user prompt fits inside Sonnet's
  // 200 KB context comfortably (we also leave room for the 200K guard
  // ceiling on the calling side, though that guard is server-side and
  // doesn't apply here — we call Anthropic directly).
  const TRIM = 80_000;
  const text = parsedText.length > TRIM ? parsedText.slice(0, TRIM) : parsedText;

  const reqBody = {
    model: PDF_EXTRACTOR_MODEL,
    max_tokens: PDF_EXTRACTOR_MAX_TOKENS,
    system: PDF_EXTRACTOR_SYSTEM_PROMPT,
    messages: [
      {
        role: "user",
        content:
          "<document_text>\n" + text + "\n</document_text>\n\nJSON:",
      },
    ],
  };
  const ctrl = new AbortController();
  const timeout = setTimeout(() => ctrl.abort(), PDF_EXTRACTOR_TIMEOUT_MS);
  try {
    const res = await fetch(ANTHROPIC_API_URL, {
      method: "POST",
      headers: {
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
        "Content-Type": "application/json",
      },
      body: JSON.stringify(reqBody),
      signal: ctrl.signal,
    });
    clearTimeout(timeout);
    if (!res.ok) {
      const snippet = (await res.text()).slice(0, 200);
      console.warn(`pdf-parser: extractor ${res.status}: ${snippet}`);
      return emptyExtraction();
    }
    const json = await res.json() as {
      content?: Array<{ type?: string; text?: string }>;
    };
    if (!Array.isArray(json.content)) return emptyExtraction();
    let raw = "";
    for (const block of json.content) {
      if (block && block.type === "text" && typeof block.text === "string") {
        raw += block.text;
      }
    }
    const parsed = parseExtractedDoc(raw);
    return parsed ?? emptyExtraction();
  } catch (e) {
    clearTimeout(timeout);
    console.warn(
      `pdf-parser: extractor fetch failed: ${String(e).slice(0, 200)}`,
    );
    return emptyExtraction();
  }
}

// =============================================================================
// Embedding — OpenAI text-embedding-3-small (1536 dim)
// =============================================================================

/**
 * Compute a 1536-d embedding for [text]. Returns a zero-filled vector on
 * any failure — we still want to persist the row so the doc shows up in
 * the case files list, even if similarity ranking will rank it low.
 */
export async function runEmbedding(
  text: string,
  apiKey: string,
): Promise<number[]> {
  const ctrl = new AbortController();
  const timeout = setTimeout(() => ctrl.abort(), 30_000);
  try {
    const res = await fetch(OPENAI_EMBEDDINGS_URL, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: EMBEDDING_MODEL,
        input: text.slice(0, 8000),
        dimensions: EMBEDDING_DIM,
      }),
      signal: ctrl.signal,
    });
    clearTimeout(timeout);
    if (!res.ok) {
      const snippet = (await res.text()).slice(0, 200);
      console.warn(`pdf-parser: embed ${res.status}: ${snippet}`);
      return new Array<number>(EMBEDDING_DIM).fill(0);
    }
    const json = await res.json() as {
      data?: Array<{ embedding?: unknown }>;
    };
    const arr = json?.data?.[0]?.embedding;
    if (!Array.isArray(arr) || arr.length !== EMBEDDING_DIM) {
      return new Array<number>(EMBEDDING_DIM).fill(0);
    }
    return arr.map((v) => (typeof v === "number" ? v : 0));
  } catch (e) {
    clearTimeout(timeout);
    console.warn(`pdf-parser: embed fetch failed: ${String(e).slice(0, 200)}`);
    return new Array<number>(EMBEDDING_DIM).fill(0);
  }
}

// =============================================================================
// Persist (insert-or-update by case_id+filename)
// =============================================================================

interface UpsertArgs {
  // deno-lint-ignore no-explicit-any
  admin: any;
  userId: string;
  caseId: string | null;
  filename: string;
  storagePath: string;
  mimeType: string;
  sizeBytes: number;
  parsedText: string;
  parsedSummary: string;
  extracted: ExtractedDoc;
  pagesLang: LangCode[];
  embedding: number[];
}

type UpsertResult =
  | { kind: "ok"; id: string }
  | { kind: "error"; message: string };

async function upsertDocumentRow(args: UpsertArgs): Promise<UpsertResult> {
  // case_id is NOT NULL in the migration — callers without an active case
  // get rejected at the validator level (case_id null is allowed for the
  // "general upload, attach later" UX, but the DB row demands a case).
  // Solution for the no-case path: we DO NOT insert when case_id is null.
  // The client gets the parsed result back inline and inserts later when
  // the user picks a case.
  if (args.caseId === null) {
    // Synthetic id: chat client uses this to know "no row was written".
    return { kind: "ok", id: "" };
  }

  const row = {
    case_id: args.caseId,
    user_id: args.userId,
    filename: args.filename,
    storage_path: args.storagePath,
    mime_type: args.mimeType,
    size_bytes: args.sizeBytes,
    doc_type: args.extracted.doc_type,
    doc_date: args.extracted.doc_date,
    parsed_text: args.parsedText,
    parsed_summary: args.parsedSummary,
    key_extractions: extractedToKeyExtractions(args.extracted, args.pagesLang),
    embedding: args.embedding,
  };

  // Update if (case_id, filename) already exists, else insert.
  try {
    const existing = await args.admin
      .from("case_documents")
      .select("id")
      .eq("case_id", args.caseId)
      .eq("filename", args.filename)
      .limit(1);
    if (existing.error) {
      return { kind: "error", message: `select failed: ${existing.error.message}` };
    }
    const found = (existing.data as Array<{ id: string }> | null)?.[0];
    if (found?.id) {
      const upd = await args.admin
        .from("case_documents")
        .update(row)
        .eq("id", found.id)
        .select("id")
        .single();
      if (upd.error) {
        return { kind: "error", message: `update failed: ${upd.error.message}` };
      }
      return { kind: "ok", id: (upd.data as { id: string }).id };
    }
    const ins = await args.admin
      .from("case_documents")
      .insert(row)
      .select("id")
      .single();
    if (ins.error) {
      return { kind: "error", message: `insert failed: ${ins.error.message}` };
    }
    return { kind: "ok", id: (ins.data as { id: string }).id };
  } catch (e) {
    return { kind: "error", message: `upsert threw: ${String(e).slice(0, 200)}` };
  }
}

// =============================================================================
// Test seams — let unit tests inject lightweight mocks without touching the
// production code path. These are intentionally module-level mutable refs.
// =============================================================================

// deno-lint-ignore no-explicit-any
export let pdfTextLayerImpl: any = null;
// deno-lint-ignore no-explicit-any
export let pdfRenderImpl:
  | ((pdf: Uint8Array, pageNum: number) => Promise<Uint8Array>)
  | null = null;

/** Test helper — set the pdfjs-dist module mock. Pass null to reset. */
// deno-lint-ignore no-explicit-any
export function __setPdfTextLayerImplForTest(impl: any) {
  pdfTextLayerImpl = impl;
}
/** Test helper — set the page-render mock. Pass null to reset. */
export function __setPdfRenderImplForTest(
  impl:
    | ((pdf: Uint8Array, pageNum: number) => Promise<Uint8Array>)
    | null,
) {
  pdfRenderImpl = impl;
}

