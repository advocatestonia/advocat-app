// claude-proxy/tool_handlers.ts
// -----------------------------------------------------------------------------
// Tool-use capability for the Advocat AI assistant.
//
// Three tools are defined:
//
//   send_email      — Send an email on the user's behalf via the existing
//                     `send-email` edge function. The tool schema hard-requires
//                     `confirmed: true` so the Anthropic model MUST always ask
//                     the user before calling it. If confirmed is missing or
//                     false, the handler returns an error message instead of
//                     dispatching (defence-in-depth: the model should never
//                     pass confirmed=false, but the server checks anyway).
//
//   generate_pdf    — Convert markdown content to a formatted HTML file stored
//                     in Supabase Storage (case-documents bucket) and return a
//                     signed 1-hour download URL. We deliberately store .html
//                     rather than attempting PDF conversion — Deno on Edge has
//                     no headless browser and no stable PDF library. The output
//                     is a well-formatted page that browsers render identically
//                     and users can print-to-PDF themselves. A TODO is left for
//                     a Puppeteer/Chrome worker upgrade path.
//
//   legal_lookup    — Phase 2 strategic upgrade #2 (tool-augmented mid-reasoning).
//                     Look up current statute text from Finlex / Riigi Teataja /
//                     EUR-Lex via our pgvector RAG corpus (and optionally a
//                     live API fallback when corpus is stale). The executor
//                     pass is instructed to call this BEFORE citing any
//                     specific paragraph — kills the #1 hallucination class
//                     (invented statute content, e.g. HOL §114 "30-day
//                     window" when reality is "5 years"). Implemented in
//                     `_shared/legal_lookup.ts`; this file owns the schema +
//                     dispatch, plus the embed/RPC wiring against the
//                     existing law_chunks table.
//
// Integration pattern
// -------------------
// After the first Anthropic response, claude-proxy/index.ts checks whether the
// stop_reason is "tool_use". If so, it calls `executeToolCalls` with the
// tool_use content blocks and the user's auth header (for `send-email` to
// use). The returned tool_result blocks are appended as a new "user" turn and
// claude-proxy sends ONE follow-up non-streaming call to Anthropic to get the
// final assistant text. That final response is what the Flutter client receives
// — it never sees the intermediate tool_use/tool_result exchange.
//
// Streaming limitation: tool execution is only done in the NON-STREAMING path
// for now. Streaming requests with tool_use fall through to the existing SSE
// pipe unchanged (the model is unlikely to use tools in streaming mode because
// the client doesn't pass a `tools` array in streaming calls — the client
// controls this).
// -----------------------------------------------------------------------------

import { embedQuery } from "../law-search/embed.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  formatLookupResultForModel,
  type LawSearchRpcRow,
  legalLookup,
  type LegalLookupResult,
} from "../_shared/legal_lookup.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";

// =============================================================================
// Tool schema definitions — passed to Anthropic in the `tools` array.
// =============================================================================

export const ASSISTANT_TOOLS = [
  {
    name: "send_email",
    description:
      "Send an email on behalf of the user. " +
      "ALWAYS show the user the exact to/subject/body and ask for explicit " +
      "confirmation ('yes, send it') BEFORE calling this tool. " +
      "Set confirmed=true only after the user has explicitly agreed.",
    input_schema: {
      type: "object",
      properties: {
        to: {
          type: "string",
          description: "Recipient email address",
        },
        subject: {
          type: "string",
          description: "Email subject line",
        },
        body: {
          type: "string",
          description: "Email body text (plain text)",
        },
        cc: {
          type: "string",
          description: "CC email address (optional)",
        },
        confirmed: {
          type: "boolean",
          description:
            "Must be true — indicates user explicitly confirmed sending. " +
            "Never pass true without showing the email to the user first.",
        },
      },
      required: ["to", "subject", "body", "confirmed"],
    },
  },
  {
    name: "generate_pdf",
    description:
      "Generate a formatted document (letter, legal brief, complaint, summary) " +
      "from the conversation content and return a download URL. " +
      "The document is stored securely in the user's account and accessible " +
      "for 1 hour via the returned URL. Use this when the user asks to " +
      "'save as PDF', 'generate a letter', 'create a document', etc.",
    input_schema: {
      type: "object",
      properties: {
        title: {
          type: "string",
          description: "Document title (used as the page heading)",
        },
        content: {
          type: "string",
          description:
            "Full document content in markdown. Use ## for sections, " +
            "**bold** for key terms, bullet lists for facts.",
        },
        document_type: {
          type: "string",
          enum: ["letter", "complaint", "brief", "summary"],
          description: "Type of document being generated",
        },
      },
      required: ["title", "content", "document_type"],
    },
  },
  {
    name: "legal_lookup",
    description:
      "Look up current statute text from Finnish Finlex, Estonian Riigi " +
      "Teataja, or EU EUR-Lex (via our bundled corpus, with live API " +
      "fallback on stale results). Use this BEFORE asserting any statute " +
      "paragraph content. Returns exact current text + freshness metadata " +
      "+ source URL.\n\n" +
      "Pattern: (1) identify which statute you need to cite, " +
      "(2) call legal_lookup({ query, jurisdiction }), " +
      "(3) read the returned text, " +
      "(4) quote/paraphrase based on that text — never from memory.\n\n" +
      "NEVER cite a paragraph from memory if this tool is available. " +
      "An empty result means the statute is not in our corpus — say so " +
      "honestly and recommend a primary source check rather than fabricating.",
    input_schema: {
      type: "object",
      properties: {
        query: {
          type: "string",
          description:
            "Semantic search query. Examples: " +
            "'HOL §114 restoration deadlines', " +
            "'TLS extraordinary dismissal grounds', " +
            "'GDPR right of erasure exceptions'. " +
            "Keep it specific — 10-20 words works best.",
        },
        jurisdiction: {
          type: "string",
          enum: ["fi", "ee", "eu", "de"],
          description:
            "Which jurisdiction's statutes to search. " +
            "fi = Finnish (Finlex), " +
            "ee = Estonian (Riigi Teataja), " +
            "eu = EU directives (EUR-Lex), " +
            "de = German (corpus-stub only).",
        },
        specific_statute: {
          type: "string",
          description:
            "Optional exact statute reference like 'HOL §114', " +
            "'TLS §88', 'Directive 32019L1152 art-5'. When supplied, " +
            "the tool boosts retrieval precision for that paragraph.",
        },
      },
      required: ["query", "jurisdiction"],
    },
  },
] as const;

// =============================================================================
// Tool input types
// =============================================================================

interface SendEmailInput {
  to: string;
  subject: string;
  body: string;
  cc?: string;
  confirmed: boolean;
}

interface GeneratePdfInput {
  title: string;
  content: string;
  document_type: "letter" | "complaint" | "brief" | "summary";
}

interface LegalLookupInput {
  query: string;
  jurisdiction: string;
  specific_statute?: string;
}

type ToolInput = SendEmailInput | GeneratePdfInput | LegalLookupInput;

// Anthropic tool_use block shape
interface ToolUseBlock {
  type: "tool_use";
  id: string;
  name: string;
  input: Record<string, unknown>;
}

// Anthropic tool_result block shape (for the follow-up user turn)
interface ToolResultBlock {
  type: "tool_result";
  tool_use_id: string;
  content: string;
  is_error?: boolean;
}

// =============================================================================
// Public entry point
// =============================================================================

/**
 * Execute all tool_use blocks from an Anthropic response and return the
 * tool_result blocks to pass back as a "user" turn.
 *
 * @param blocks   - Array of tool_use content blocks from the Anthropic response.
 * @param authHeader - The caller's Authorization header (forwarded to send-email).
 * @param userId   - Authenticated user id (for storage path isolation in generate_pdf).
 * @returns Array of tool_result blocks ready to inject into the messages array.
 */
export async function executeToolCalls(
  blocks: ToolUseBlock[],
  authHeader: string,
  userId: string,
): Promise<ToolResultBlock[]> {
  const results = await Promise.all(
    blocks.map((block) => executeSingleTool(block, authHeader, userId)),
  );
  return results;
}

// =============================================================================
// Per-tool dispatch
// =============================================================================

async function executeSingleTool(
  block: ToolUseBlock,
  authHeader: string,
  userId: string,
): Promise<ToolResultBlock> {
  try {
    switch (block.name) {
      case "send_email":
        return await handleSendEmail(
          block.id,
          block.input as unknown as SendEmailInput,
          authHeader,
        );
      case "generate_pdf":
        return await handleGeneratePdf(
          block.id,
          block.input as unknown as GeneratePdfInput,
          userId,
        );
      case "legal_lookup":
        return await handleLegalLookup(
          block.id,
          block.input as unknown as LegalLookupInput,
        );
      default:
        return {
          type: "tool_result",
          tool_use_id: block.id,
          content: `Unknown tool: ${block.name}`,
          is_error: true,
        };
    }
  } catch (e) {
    return {
      type: "tool_result",
      tool_use_id: block.id,
      content: `Tool execution failed: ${String(e).slice(0, 300)}`,
      is_error: true,
    };
  }
}

// =============================================================================
// send_email handler
// =============================================================================

async function handleSendEmail(
  toolUseId: string,
  input: SendEmailInput,
  authHeader: string,
): Promise<ToolResultBlock> {
  // Defence-in-depth: reject if the model somehow omits confirmation.
  if (input.confirmed !== true) {
    return {
      type: "tool_result",
      tool_use_id: toolUseId,
      content:
        "Error: User confirmation required before sending email. " +
        "Please show the user the exact email details and wait for " +
        "their explicit 'yes, send it' before calling this tool again " +
        "with confirmed=true.",
      is_error: true,
    };
  }

  // Basic input validation (mirrors send-email/index.ts guards).
  const to = (input.to ?? "").trim();
  const subject = (input.subject ?? "").trim();
  const body = (input.body ?? "").trim();
  const cc = input.cc?.trim();

  if (!to || !subject || !body) {
    return {
      type: "tool_result",
      tool_use_id: toolUseId,
      content: "Error: to, subject, and body are all required.",
      is_error: true,
    };
  }

  // Forward to the existing send-email edge function. We call it internally
  // (same Supabase project) using the caller's JWT so the function's own
  // auth + rate-limit + correspondence logging all apply unchanged.
  const resp = await fetch(
    `${SUPABASE_URL}/functions/v1/send-email`,
    {
      method: "POST",
      headers: {
        "Authorization": authHeader,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ to, subject, body, cc }),
    },
  );

  if (!resp.ok) {
    let detail = "";
    try {
      const err = await resp.json() as { error?: string; details?: string };
      detail = err.error ?? err.details ?? "";
    } catch (_) {
      detail = await resp.text().catch(() => "");
    }
    return {
      type: "tool_result",
      tool_use_id: toolUseId,
      content: `Error sending email (HTTP ${resp.status}): ${detail}`.slice(
        0,
        500,
      ),
      is_error: true,
    };
  }

  const result = await resp.json() as {
    ok?: boolean;
    provider?: string;
    provider_message_id?: string;
  };
  return {
    type: "tool_result",
    tool_use_id: toolUseId,
    content:
      `Email sent successfully via ${result.provider ?? "unknown"} ` +
      `(id: ${result.provider_message_id ?? "n/a"}). ` +
      `To: ${to} | Subject: ${subject}`,
  };
}

// =============================================================================
// generate_pdf handler
// =============================================================================

/**
 * Convert markdown to a print-ready HTML document and store it in
 * Supabase Storage (case-documents bucket). Return a signed 1-hour URL.
 *
 * Why HTML and not PDF:
 *   Deno on Supabase Edge has no headless browser, no canvas API (see
 *   pdf-parser TODO), and no stable PDF-generation library. HTML stored in
 *   Storage with proper print CSS is equivalent for all practical purposes:
 *   users open the URL, browser renders a clean page, File → Print → Save as
 *   PDF takes two clicks. The format is disclosed in the returned content.
 *
 * TODO: When a Puppeteer-backed worker or pdfium-deno ships a stable Deno
 * build, replace the Storage HTML write + signed URL with a puppeteer.pdf()
 * call and return a Content-Disposition: attachment; filename=<title>.pdf
 * URL instead.
 */
async function handleGeneratePdf(
  toolUseId: string,
  input: GeneratePdfInput,
  userId: string,
): Promise<ToolResultBlock> {
  const title = (input.title ?? "Document").trim().slice(0, 200);
  const content = (input.content ?? "").trim();
  const docType = input.document_type ?? "letter";

  if (!content) {
    return {
      type: "tool_result",
      tool_use_id: toolUseId,
      content: "Error: content is required.",
      is_error: true,
    };
  }

  // Convert markdown to HTML (lightweight, no external deps).
  const htmlBody = markdownToHtml(content);

  // Full document with print CSS.
  const now = new Date();
  const dateStr = now.toLocaleDateString("en-GB", {
    day: "2-digit",
    month: "long",
    year: "numeric",
  });
  const html = buildHtmlDocument({ title, htmlBody, docType, dateStr });

  // Storage path: user-scoped, timestamped.
  const ts = now.toISOString().replace(/[:.]/g, "-").slice(0, 19);
  const safeName = title.replace(/[^a-zA-Z0-9_\-]/g, "_").slice(0, 60);
  const storagePath = `${userId}/generated/${ts}_${safeName}.html`;

  // Upload via Supabase Storage REST API (service role).
  const uploadUrl =
    `${SUPABASE_URL}/storage/v1/object/case-documents/${storagePath}`;

  const htmlBytes = new TextEncoder().encode(html);
  const uploadResp = await fetch(uploadUrl, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
      "Content-Type": "text/html; charset=utf-8",
      "x-upsert": "true",
    },
    body: htmlBytes,
  });

  if (!uploadResp.ok) {
    const err = await uploadResp.text().catch(() => "");
    return {
      type: "tool_result",
      tool_use_id: toolUseId,
      content: `Error uploading document (HTTP ${uploadResp.status}): ${err}`.slice(
        0,
        500,
      ),
      is_error: true,
    };
  }

  // Create a signed URL valid for 3600 seconds (1 hour).
  const signedUrlEndpoint =
    `${SUPABASE_URL}/storage/v1/object/sign/case-documents/${storagePath}`;
  const signResp = await fetch(signedUrlEndpoint, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ expiresIn: 3600 }),
  });

  if (!signResp.ok) {
    // File was uploaded — return a public path even without a signed URL.
    return {
      type: "tool_result",
      tool_use_id: toolUseId,
      content:
        `Document generated and stored. Storage path: case-documents/${storagePath}. ` +
        `Note: Could not create a signed URL (HTTP ${signResp.status}). ` +
        `The owner can download via the Supabase dashboard.`,
    };
  }

  const signData = await signResp.json() as { signedURL?: string; signedUrl?: string };
  // Supabase returns either `signedURL` (older) or `signedUrl` (newer).
  const relativeUrl = signData.signedURL ?? signData.signedUrl ?? "";
  // Build the full URL: if it's already absolute, use it; otherwise prepend base.
  const downloadUrl = relativeUrl.startsWith("http")
    ? relativeUrl
    : `${SUPABASE_URL}${relativeUrl}`;

  return {
    type: "tool_result",
    tool_use_id: toolUseId,
    content:
      `Document "${title}" generated successfully.\n` +
      `Type: ${docType} | Date: ${dateStr}\n` +
      `Download URL (valid 1 hour): ${downloadUrl}\n\n` +
      `Note: The document is formatted HTML — open the link in a browser ` +
      `and use File → Print → Save as PDF to export a PDF copy.`,
  };
}

// =============================================================================
// Markdown → HTML (lightweight, no external deps)
// =============================================================================

/**
 * Minimal markdown-to-HTML converter covering the subset used in legal docs:
 * headings (## / ###), bold (**), italic (*), bullet lists (- / *), and
 * paragraphs. Not a full CommonMark parser — just enough for the tool output.
 */
function markdownToHtml(md: string): string {
  const lines = md.split("\n");
  const out: string[] = [];
  let inList = false;

  for (const rawLine of lines) {
    const line = rawLine.trimEnd();

    // Blank line — close list if open, add paragraph break
    if (line.trim() === "") {
      if (inList) {
        out.push("</ul>");
        inList = false;
      }
      out.push("<p></p>");
      continue;
    }

    // Headings
    if (line.startsWith("#### ")) {
      if (inList) { out.push("</ul>"); inList = false; }
      out.push(`<h4>${escHtml(line.slice(5))}</h4>`);
      continue;
    }
    if (line.startsWith("### ")) {
      if (inList) { out.push("</ul>"); inList = false; }
      out.push(`<h3>${escHtml(line.slice(4))}</h3>`);
      continue;
    }
    if (line.startsWith("## ")) {
      if (inList) { out.push("</ul>"); inList = false; }
      out.push(`<h2>${escHtml(line.slice(3))}</h2>`);
      continue;
    }
    if (line.startsWith("# ")) {
      if (inList) { out.push("</ul>"); inList = false; }
      out.push(`<h1>${escHtml(line.slice(2))}</h1>`);
      continue;
    }

    // Horizontal rule
    if (/^[-*_]{3,}$/.test(line.trim())) {
      if (inList) { out.push("</ul>"); inList = false; }
      out.push("<hr>");
      continue;
    }

    // Bullet list item (- or * at start of line)
    const listMatch = /^[-*]\s+(.+)/.exec(line);
    if (listMatch) {
      if (!inList) {
        out.push("<ul>");
        inList = true;
      }
      out.push(`<li>${inlineMarkdown(listMatch[1])}</li>`);
      continue;
    }

    // Close list before normal paragraph
    if (inList) {
      out.push("</ul>");
      inList = false;
    }

    // Normal paragraph line
    out.push(`<p>${inlineMarkdown(line)}</p>`);
  }

  if (inList) out.push("</ul>");
  return out.join("\n");
}

/** Apply inline markdown: **bold**, *italic*, `code`. */
function inlineMarkdown(s: string): string {
  // Escape HTML first, then restore our own tags.
  let r = escHtml(s);
  // Bold: **text** or __text__
  r = r.replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>");
  r = r.replace(/__(.+?)__/g, "<strong>$1</strong>");
  // Italic: *text* or _text_
  r = r.replace(/\*(.+?)\*/g, "<em>$1</em>");
  r = r.replace(/_(.+?)_/g, "<em>$1</em>");
  // Inline code: `code`
  r = r.replace(/`([^`]+)`/g, "<code>$1</code>");
  return r;
}

function escHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

// =============================================================================
// HTML document template
// =============================================================================

function buildHtmlDocument(args: {
  title: string;
  htmlBody: string;
  docType: string;
  dateStr: string;
}): string {
  const typeLabel: Record<string, string> = {
    letter: "Letter",
    complaint: "Formal Complaint",
    brief: "Legal Brief",
    summary: "Case Summary",
  };
  const label = typeLabel[args.docType] ?? "Document";

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${escHtml(args.title)}</title>
  <style>
    /* Screen */
    body {
      font-family: "Georgia", "Times New Roman", serif;
      font-size: 12pt;
      line-height: 1.6;
      color: #1a1a1a;
      max-width: 760px;
      margin: 0 auto;
      padding: 40px 48px;
      background: #fff;
    }
    header {
      border-bottom: 2px solid #2c4a8f;
      padding-bottom: 16px;
      margin-bottom: 32px;
    }
    header .doc-type {
      font-size: 10pt;
      text-transform: uppercase;
      letter-spacing: 0.12em;
      color: #2c4a8f;
      margin: 0 0 6px;
    }
    header h1 {
      font-size: 18pt;
      margin: 0 0 6px;
      font-weight: 700;
    }
    header .meta {
      font-size: 10pt;
      color: #666;
    }
    footer {
      border-top: 1px solid #ddd;
      margin-top: 48px;
      padding-top: 12px;
      font-size: 9pt;
      color: #888;
      text-align: center;
    }
    h1 { font-size: 16pt; margin: 24px 0 8px; }
    h2 { font-size: 14pt; margin: 20px 0 6px; border-bottom: 1px solid #eee; padding-bottom: 4px; }
    h3 { font-size: 12pt; margin: 16px 0 4px; }
    h4 { font-size: 11pt; margin: 12px 0 4px; font-style: italic; }
    p  { margin: 8px 0; }
    ul { margin: 8px 0 8px 24px; padding: 0; }
    li { margin: 4px 0; }
    strong { font-weight: 700; }
    em { font-style: italic; }
    code { font-family: monospace; background: #f5f5f5; padding: 1px 4px; border-radius: 2px; }
    hr { border: none; border-top: 1px solid #ddd; margin: 20px 0; }

    /* Print */
    @media print {
      body { padding: 0; max-width: 100%; }
      header { page-break-after: avoid; }
      h1, h2, h3 { page-break-after: avoid; }
      footer { position: fixed; bottom: 0; left: 0; right: 0; }
    }
  </style>
</head>
<body>
  <header>
    <div class="doc-type">${escHtml(label)}</div>
    <h1>${escHtml(args.title)}</h1>
    <div class="meta">Generated by Advocat AI &bull; ${escHtml(args.dateStr)}</div>
  </header>

  <main>
    ${args.htmlBody}
  </main>

  <footer>
    Generated by Advocat &bull; advocat.ee &bull;
    This document is for informational purposes only and does not constitute legal advice.
    Consult a licensed attorney for legal representation.
  </footer>
</body>
</html>`;
}

// =============================================================================
// legal_lookup handler
// =============================================================================

/**
 * Look up current statute text from the law_chunks corpus (Phase 2 Pkg 1).
 * Returns formatted text the model can quote/paraphrase.
 *
 * The handler is the dependency-injection seam for `legalLookup()`:
 *   - embed → law-search/embed.ts (OpenAI text-embedding-3-small)
 *   - lawSearch → supabase.rpc('law_search', ...) with jurisdiction filter
 *   - fetchFreshness → batched select on law_chunks(corpus_refreshed_at)
 *   - liveFallback → stubLiveFallback (v2 — currently always null)
 *
 * All failure modes degrade to `{ chunks: [] }` returning a "not found"
 * message via `formatLookupResultForModel`. The handler NEVER returns
 * is_error=true unless the input itself was malformed — a corpus miss
 * is a normal response the model is told how to handle.
 */
async function handleLegalLookup(
  toolUseId: string,
  input: LegalLookupInput,
): Promise<ToolResultBlock> {
  const query = (input.query ?? "").trim();
  const jurisdiction = (input.jurisdiction ?? "").trim().toLowerCase();
  const specificStatute = input.specific_statute?.trim() || null;

  if (!query) {
    return {
      type: "tool_result",
      tool_use_id: toolUseId,
      content: "Error: 'query' is required (non-empty string).",
      is_error: true,
    };
  }
  if (!jurisdiction) {
    return {
      type: "tool_result",
      tool_use_id: toolUseId,
      content: "Error: 'jurisdiction' is required (one of fi/ee/eu/de).",
      is_error: true,
    };
  }

  // Build dependency closure. Service-role client is fine — the corpus is
  // public-read anyway via RLS policy "law_chunks readable by anon".
  if (!OPENAI_API_KEY || !SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    // Server misconfig — degrade to "not found" message rather than 5xx.
    return {
      type: "tool_result",
      tool_use_id: toolUseId,
      content: formatLookupResultForModel({
        chunks: [],
        source: "stub",
        embed_tokens: 0,
      }),
    };
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  try {
    const result: LegalLookupResult = await legalLookup(
      query,
      jurisdiction,
      {
        embed: async (q: string) =>
          await embedQuery(q, {
            apiKey: OPENAI_API_KEY,
            timeoutMs: 5000,
          }),
        lawSearch: async (params): Promise<LawSearchRpcRow[] | null> => {
          const { data, error } = await supabase.rpc("law_search", params);
          if (error) {
            console.warn(`legal_lookup tool: RPC error — ${error.message}`);
            return null;
          }
          return Array.isArray(data) ? data as LawSearchRpcRow[] : null;
        },
        fetchFreshness: async (ids: string[]) => {
          const out = new Map<string, string | null>();
          if (ids.length === 0) return out;
          const { data, error } = await supabase
            .from("law_chunks")
            .select("id, corpus_refreshed_at")
            .in("id", ids);
          if (error) {
            console.warn(
              `legal_lookup tool: freshness query error — ${error.message}`,
            );
            return out;
          }
          for (const row of (data ?? []) as Array<{
            id: string;
            corpus_refreshed_at: string | null;
          }>) {
            out.set(row.id, row.corpus_refreshed_at ?? null);
          }
          return out;
        },
        // v2 stub — wired but always returns null today. Set
        // LEGAL_LOOKUP_LIVE_API_ENABLED=true to attempt the (currently
        // no-op) dispatch when corpus is stale.
        liveFallback: async () => null,
      },
      {
        specificStatute,
        // Live API resolved from env inside legalLookup. No-op in v1.
      },
    );

    return {
      type: "tool_result",
      tool_use_id: toolUseId,
      content: formatLookupResultForModel(result),
    };
  } catch (e) {
    // LegalLookupConfigError (unknown jurisdiction) ends up here. Surface
    // as is_error so the model retries with a valid value.
    return {
      type: "tool_result",
      tool_use_id: toolUseId,
      content: `legal_lookup failed: ${String(e).slice(0, 300)}`,
      is_error: true,
    };
  }
}

// =============================================================================
// Type guard helpers (used by claude-proxy/index.ts)
// =============================================================================

/** Return true when an Anthropic response content block is a tool_use block. */
export function isToolUseBlock(
  block: unknown,
): block is ToolUseBlock {
  return (
    typeof block === "object" &&
    block !== null &&
    (block as Record<string, unknown>).type === "tool_use" &&
    typeof (block as Record<string, unknown>).name === "string" &&
    typeof (block as Record<string, unknown>).id === "string"
  );
}

/** Extract all tool_use blocks from an Anthropic response content array. */
export function extractToolUseBlocks(
  content: unknown,
): ToolUseBlock[] {
  if (!Array.isArray(content)) return [];
  return content.filter(isToolUseBlock);
}
