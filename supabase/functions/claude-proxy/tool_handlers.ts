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
  type LegalLookupCaseCitation,
  legalLookup,
  type LegalLookupResult,
  type LegalLookupTravaux,
} from "../_shared/legal_lookup.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY") ?? "";

// =============================================================================
// Tool schema definitions — passed to Anthropic in the `tools` array.
// =============================================================================

export const ASSISTANT_TOOLS = [
  // ── READ TOOLS for agent loop (Day 1-2, 2026-05-27) ──────────────────────
  // These are server-side wrappers around existing infra (email-inbox-sync,
  // pdf-parser, consilium pipeline, email_attachments table). They let the
  // agent loop chain calls inside ONE claude-proxy invocation: list_inbox →
  // get_thread → run_pdf_parser × N → run_consilium → draft.
  //
  // All four are READ tools — no side effects, no approval required.
  // Approval gate kicks in only on the WRITE tools (send_email,
  // generate_pdf, approve_send_draft) per Day 4.
  {
    name: "list_inbox",
    description:
      "List the user's recent email threads with triage status. " +
      "Returns up to 20 threads sorted by last_message_at desc, " +
      "with severity, subject, sender, unread flag, and triage summary " +
      "when available. Use this to discover what new mail the user has " +
      "before drilling into a specific thread.",
    input_schema: {
      type: "object",
      properties: {
        limit: {
          type: "integer",
          minimum: 1,
          maximum: 20,
          description: "Max threads to return. Default 10.",
        },
        only_unread: {
          type: "boolean",
          description: "When true, only threads with unread messages.",
        },
        severity_min: {
          type: "string",
          enum: ["LOW", "MEDIUM", "HIGH", "CRITICAL"],
          description: "Only return threads at or above this severity.",
        },
      },
      required: [],
    },
  },
  {
    name: "read_thread_full",
    description:
      "Read full content of one email thread: subject, all messages " +
      "(sender, sent_at, plaintext body), participants, attachment " +
      "metadata, and the triage row if one exists (severity, user_brief, " +
      "draft_body, proposed_actions). Use this AFTER list_inbox to drill " +
      "into a specific thread the user asked about.",
    input_schema: {
      type: "object",
      properties: {
        thread_id: {
          type: "string",
          description:
            "Thread id (the email_threads.id uuid OR the gmail_thread_id " +
            "string returned by list_inbox).",
        },
      },
      required: ["thread_id"],
    },
  },
  {
    name: "run_pdf_parser",
    description:
      "Parse a PDF attachment via Vision OCR + Sonnet structured " +
      "extraction. Use this AFTER read_thread_full when the thread has " +
      "PDF attachments the user wants you to read. Returns parsed_text, " +
      "parsed_summary, key_extractions (dates, parties, paragraphs cited). " +
      "Pass the email_attachments.id (returned in read_thread_full's " +
      "attachments array).",
    input_schema: {
      type: "object",
      properties: {
        attachment_id: {
          type: "string",
          description: "email_attachments.id uuid",
        },
      },
      required: ["attachment_id"],
    },
  },
  {
    name: "run_consilium",
    description:
      "Run the 15-lawyer consilium on a question. Returns each lawyer's " +
      "opinion + a final synthesised verdict. Use this for high-stakes " +
      "legal questions where multiple jurisdictions / specialisations " +
      "matter (immigration + EU rights + ECHR + procedure). Takes " +
      "~15-25s — only call when the user's question warrants it.",
    input_schema: {
      type: "object",
      properties: {
        question: {
          type: "string",
          description:
            "The question to consult the consilium on. " +
            "Be specific — include the case facts and the legal issue.",
        },
        case_context: {
          type: "string",
          description:
            "Optional 1-2 paragraph case context (parties, deadlines, " +
            "what's at stake). The lawyers cite this in their opinions.",
        },
      },
      required: ["question"],
    },
  },
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
        valid_at: {
          type: "string",
          description:
            "Optional ISO-8601 timestamp for version-aware retrieval " +
            "(corpus v3). When set, returns only redaktsioon versions " +
            "valid at that instant. Use when the user asks 'what did " +
            "the law say on 2024-01-01' or analysing a case decided " +
            "under earlier text. Omit for current text.",
        },
      },
      required: ["query", "jurisdiction"],
    },
  },
] as const;

// =============================================================================
// Tool input types
// =============================================================================

interface ListInboxInput {
  limit?: number;
  only_unread?: boolean;
  severity_min?: "LOW" | "MEDIUM" | "HIGH" | "CRITICAL";
}

interface ReadThreadFullInput {
  thread_id: string;
}

interface RunPdfParserInput {
  attachment_id: string;
}

interface RunConsiliumInput {
  question: string;
  case_context?: string;
}

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
  /** Corpus v3 — version-aware retrieval. ISO timestamp; when set, only
   *  redaktsioon versions valid at that instant are returned. Used when the
   *  user asks "what did the statute say on 2024-01-01" or for legacy-case
   *  analysis. Optional; omit for "current text". */
  valid_at?: string;
}

type ToolInput =
  | SendEmailInput
  | GeneratePdfInput
  | LegalLookupInput
  | ListInboxInput
  | ReadThreadFullInput
  | RunPdfParserInput
  | RunConsiliumInput;

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
// Verifier sidecar (citation_verifier integration — 2026-05-19)
// =============================================================================
//
// The citation verifier (../_shared/citation_verifier.ts) needs structured
// access to every legal_lookup result that fired in a single turn (act_slug,
// paragraph, section_label, plus the original tool_use input). The
// tool_result.content string returned to Anthropic is human-prose and would
// require parsing; instead we publish the structured records to a
// module-scoped map keyed by tool_use_id. `consumeLegalLookupLog` drains
// records by id so claude-proxy can hand them straight to the verifier.
// Drained entries are dropped to prevent stale-turn cross-contamination.

/** Verifier-friendly view of one legal_lookup invocation. */
export interface LegalLookupVerifierRecord {
  tool_use_id: string;
  input: {
    query?: string;
    jurisdiction?: string;
    specific_statute?: string;
  };
  returned_chunks: Array<{
    act_slug: string | null;
    paragraph: string | null;
    section_label: string | null;
    similarity: number | null;
  }>;
}

const _legalLookupLog = new Map<string, LegalLookupVerifierRecord>();

/** Drain all records whose tool_use_id is in `ids`. Returns the records and
 *  deletes them from the internal store so a later turn cannot inherit them.
 *  When `ids` is undefined, drains everything currently held. */
export function consumeLegalLookupLog(
  ids?: ReadonlyArray<string>,
): LegalLookupVerifierRecord[] {
  const out: LegalLookupVerifierRecord[] = [];
  if (ids === undefined) {
    for (const v of _legalLookupLog.values()) out.push(v);
    _legalLookupLog.clear();
    return out;
  }
  for (const id of ids) {
    const rec = _legalLookupLog.get(id);
    if (rec) {
      out.push(rec);
      _legalLookupLog.delete(id);
    }
  }
  return out;
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
      case "list_inbox":
        return await handleListInbox(
          block.id,
          block.input as unknown as ListInboxInput,
          userId,
        );
      case "read_thread_full":
        return await handleReadThreadFull(
          block.id,
          block.input as unknown as ReadThreadFullInput,
          userId,
        );
      case "run_pdf_parser":
        return await handleRunPdfParser(
          block.id,
          block.input as unknown as RunPdfParserInput,
          userId,
        );
      case "run_consilium":
        return await handleRunConsilium(
          block.id,
          block.input as unknown as RunConsiliumInput,
          userId,
        );
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
// legal_lookup handler — law_search_v2 row adapter
// =============================================================================

/** Shape of one row returned by `law_search_v2`. Differs from the legacy
 *  `LawSearchRpcRow` in two material ways:
 *    - `section_label` instead of `paragraph`/`title` (combined human label)
 *    - `text` instead of `body`
 *  Plus: `id` is uuid (string at JSON layer), no `jurisdiction` / `act_name`
 *  columns (we have `act_slug` only). */
interface LawSearchV2Row {
  id: string;
  act_slug: string;
  section_label: string;
  text: string;
  similarity: number;
  source_url: string | null;
  license: string | null;
  display_policy: string | null;
}

/**
 * Extract the bare paragraph/article identifier from a v2 `section_label`.
 *
 * Examples (covering FI / EE / EU / multi-lang):
 *   "HOL 1:114 §"     → "114"      (FI: ACT CHAPTER:SECTION §)
 *   "KarS § 114"      → "114"      (EE: ACT § SECTION)
 *   "KarS § 114¹"     → "114¹"     (EE: with superscript suffix)
 *   "Article 39"      → "39"       (EU EN)
 *   "Artikkel 28"     → "28"       (EU ET)
 *   "39 artikla"      → "39"       (EU FI)
 *   "TLS § 88"        → "88"
 *
 * Returns the original string lowercased if nothing matches — downstream
 * formatStatute / extractSectionFromQuery already tolerate odd inputs.
 */
export function paragraphFromSectionLabel(label: string): string {
  if (!label) return "";
  const trimmed = label.trim();

  // FI pattern: "ACT CHAPTER:SECTION §" or "ACT CHAPTER:SECTION§"
  const fi = trimmed.match(/\d+:(\d+[a-zA-Z¹²³⁰⁴⁵⁶⁷⁸⁹]?)\s*§?\s*$/);
  if (fi) return fi[1];

  // EE pattern: "ACT § SECTION" — section may carry sup/sub like 114¹
  const ee = trimmed.match(/§\s*(\d+[a-zA-Z¹²³⁰⁴⁵⁶⁷⁸⁹]?)\s*$/);
  if (ee) return ee[1];

  // EU EN: "Article 39" / "Article 39.1"
  const enArt = trimmed.match(/^Article\s+(\d+(?:[.\-]\d+)?)/i);
  if (enArt) return enArt[1];

  // EU ET: "Artikkel 28"
  const etArt = trimmed.match(/^Artikkel\s+(\d+(?:[.\-]\d+)?)/i);
  if (etArt) return etArt[1];

  // EU FI: "39 artikla"
  const fiArt = trimmed.match(/^(\d+(?:[.\-]\d+)?)\s+artikla/i);
  if (fiArt) return fiArt[1];

  // Last-resort: first digit run after a § / colon / space, else the label.
  const digits = trimmed.match(/(\d+[a-zA-Z¹²³⁰⁴⁵⁶⁷⁸⁹]?)/);
  return digits ? digits[1] : trimmed;
}

/** Adapt a `law_search_v2` row to the legacy `LawSearchRpcRow` shape so the
 *  `legalLookup()` pipeline stays untouched. */
export function adaptV2RowToLegacy(row: LawSearchV2Row): LawSearchRpcRow {
  return {
    id: row.id,
    act_slug: row.act_slug ?? "",
    act_name: null,
    paragraph: paragraphFromSectionLabel(row.section_label ?? ""),
    title: row.section_label ?? null,
    body: row.text ?? "",
    source_url: row.source_url ?? null,
    jurisdiction: null,
    similarity: typeof row.similarity === "number" ? row.similarity : 0,
    license: row.license ?? null,
    display_policy: row.display_policy ?? null,
  };
}

// =============================================================================
// legal_lookup handler
// =============================================================================

/**
 * Look up current statute text from the law_chunks_v2 corpus (2026-05-13 P0
 * fix — v1 `law_chunks`/`law_search` returned an EE-only stale 6584-row set;
 * v2 covers 15 295 rows: 3355 FI + 7288 EE + 2692 EU).
 *
 * The handler is the dependency-injection seam for `legalLookup()`:
 *   - embed → law-search/embed.ts (OpenAI text-embedding-3-small)
 *   - lawSearch → supabase.rpc('law_search_v2', ...) + row adapter (v2 returns
 *                 (id, act_slug, section_label, text, similarity, source_url,
 *                  license, display_policy); we map this back to the
 *                 LawSearchRpcRow shape the rest of the pipeline expects)
 *   - fetchFreshness → batched select on law_chunks_v2(last_verified_at)
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
          // 2026-05-13 P0 fix: swap to law_search_v2 (15,295 rows: FI/EE/EU)
          // away from the legacy law_search (EE-only, 6584 rows, stale).
          // v2 takes a different positional shape AND returns a different
          // column set — adapt both directions here so the legal_lookup
          // pipeline upstream stays unchanged.
          //
          // v2 RPC contract:
          //   IN:  query_embedding, jurisdiction_filter, act_slug_filter,
          //        lang_filter, valid_at, match_threshold, match_count
          //   OUT: id, act_slug, section_label, text, similarity,
          //        source_url, license, display_policy
          //
          // v1 (legacy) row shape we adapt back to:
          //   id, act_slug, act_name, paragraph, title, body, source_url,
          //   jurisdiction, similarity
          //
          // jurisdiction_filter: legacy callers pass "FI"/"EE"/"EU"
          // (uppercase, see JURISDICTION_TO_RPC in legal_lookup.ts). v2's
          // `law_chunks_v2.jurisdiction` stores lowercase ("fi"/"ee"/"eu"),
          // so we lowercase here. Same for `lang_filter`.
          const v2Params = {
            query_embedding: params.query_embedding,
            jurisdiction_filter: params.query_jurisdiction
              ? params.query_jurisdiction.toLowerCase()
              : null,
            act_slug_filter: null as string | null,
            lang_filter: params.query_lang
              ? params.query_lang.toLowerCase()
              : null,
            valid_at: null as string | null,
            match_threshold: params.similarity_threshold,
            match_count: params.match_count,
          };
          const { data, error } = await supabase.rpc(
            "law_search_v2",
            v2Params,
          );
          if (error) {
            console.warn(
              `legal_lookup tool: law_search_v2 RPC error — ${error.message}`,
            );
            return null;
          }
          if (!Array.isArray(data)) return null;
          return (data as LawSearchV2Row[]).map(adaptV2RowToLegacy);
        },
        // Vabank A1 (2026-05-15) — hybrid BM25+dense RRF retriever.
        //   `legalLookup` calls this first when query has >=2 tokens and
        //   transparently falls back to the dense `lawSearch` above on
        //   null/empty/error. So wiring it in is strictly additive — worst
        //   case is the dense baseline.
        //
        //   law_search_hybrid contract:
        //     IN:  p_query_embedding, p_query_text, p_jurisdiction, p_lang,
        //          p_act_slug, p_valid_at, p_match_threshold, p_limit
        //     OUT: id, act_slug, section_label, text, similarity, source_url,
        //          bm25_rank, rrf_score, source_type
        //
        //   The hybrid row has the same columns the v2 adapter cares about;
        //   bm25_rank / rrf_score / source_type are debug-only and dropped
        //   by `adaptV2RowToLegacy`. Rows arrive pre-ordered by rrf_score
        //   DESC, so the downstream section-rerank still does its
        //   tie-break on top.
        lawSearchHybrid: async (params): Promise<LawSearchRpcRow[] | null> => {
          const hybridParams = {
            p_query_embedding: params.query_embedding,
            p_query_text: params.query_text,
            p_jurisdiction: params.query_jurisdiction
              ? params.query_jurisdiction.toLowerCase()
              : null,
            p_lang: params.query_lang ? params.query_lang.toLowerCase() : null,
            p_act_slug: null as string | null,
            p_valid_at: null as string | null,
            p_match_threshold: params.similarity_threshold,
            p_limit: params.match_count,
          };
          const { data, error } = await supabase.rpc(
            "law_search_hybrid",
            hybridParams,
          );
          if (error) {
            // Surface the RPC error but degrade silently — `legalLookup`
            // will retry on the dense path.
            console.warn(
              `legal_lookup tool: law_search_hybrid RPC error — ${error.message}`,
            );
            return null;
          }
          if (!Array.isArray(data)) return null;
          return (data as LawSearchV2Row[]).map(adaptV2RowToLegacy);
        },
        fetchFreshness: async (ids: string[]) => {
          const out = new Map<string, string | null>();
          if (ids.length === 0) return out;
          // law_chunks_v2 has no `corpus_refreshed_at`; we use
          // `last_verified_at` (preferred) and fall back to `ingested_at`.
          // The legalLookup pipeline only cares about a "when was this
          // chunk last known-current" timestamp for the stale_warning.
          const { data, error } = await supabase
            .from("law_chunks_v2")
            .select("id, last_verified_at, ingested_at")
            .in("id", ids);
          if (error) {
            console.warn(
              `legal_lookup tool: freshness query error — ${error.message}`,
            );
            return out;
          }
          for (const row of (data ?? []) as Array<{
            id: string;
            last_verified_at: string | null;
            ingested_at: string | null;
          }>) {
            out.set(row.id, row.last_verified_at ?? row.ingested_at ?? null);
          }
          return out;
        },
        // v2 stub — wired but always returns null today. Set
        // LEGAL_LOOKUP_LIVE_API_ENABLED=true to attempt the (currently
        // no-op) dispatch when corpus is stale.
        liveFallback: async () => null,
        // Corpus v3 — reverse-citation graph. Returns court decisions
        // that have applied the top-hit §. When law_chunks_v2 is empty
        // (pre-ingestion), the RPC simply returns 0 rows and the
        // enrichment is omitted silently. No fallback to a different
        // table — the RPC only knows law_chunks_v2.
        casesCiting: async ({ act_slug, section }): Promise<LegalLookupCaseCitation[] | null> => {
          const { data, error } = await supabase.rpc("cases_citing", {
            p_act_slug: act_slug,
            p_section: section,
          });
          if (error) {
            console.warn(
              `legal_lookup tool: cases_citing RPC error — ${error.message}`,
            );
            return null;
          }
          return Array.isArray(data) ? data as LegalLookupCaseCitation[] : null;
        },
        // Corpus v3 — HE / eelnõu / seletuskiri (legislative intent).
        // Same emptiness behaviour as cases_citing.
        travauxFor: async ({ act_slug, section }): Promise<LegalLookupTravaux[] | null> => {
          const { data, error } = await supabase.rpc("travaux_for", {
            p_act_slug: act_slug,
            p_section: section,
          });
          if (error) {
            console.warn(
              `legal_lookup tool: travaux_for RPC error — ${error.message}`,
            );
            return null;
          }
          return Array.isArray(data) ? data as LegalLookupTravaux[] : null;
        },
      },
      {
        specificStatute,
        // Forward an optional valid_at timestamp from the tool input
        // (corpus v3 — version-aware retrieval). Today's v1 law_search
        // RPC ignores it; once a caller switches the lookup over to the
        // law_search_v2 RPC, this becomes the redaktsioon anchor.
        validAt: input.valid_at ?? null,
        // Live API resolved from env inside legalLookup. No-op in v1.
      },
    );

    // Publish a verifier-friendly view of this lookup so the post-pass
    // citation verifier can cross-check prose §-citations against what the
    // tool ACTUALLY returned (P0 hallucination guard, 2026-05-19).
    _legalLookupLog.set(toolUseId, {
      tool_use_id: toolUseId,
      input: {
        query,
        jurisdiction,
        specific_statute: specificStatute ?? undefined,
      },
      returned_chunks: result.chunks.map((c) => ({
        act_slug: c.act_slug ?? null,
        paragraph: c.paragraph ?? null,
        section_label: c.statute ?? null,
        similarity: c.similarity ?? null,
      })),
    });

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
// Day 1-2 (2026-05-27) — READ tools for agent loop
// =============================================================================
//
// Pattern: each handler instantiates a service-role Supabase client, queries
// public tables (RLS bypassed — caller's user_id pinned via the userId arg),
// formats a model-friendly content string. Same try/catch surface as the
// other tools.
//
// These tools NEVER trigger side-effects: list_inbox is a SELECT, read_thread
// is a SELECT, run_pdf_parser delegates to an existing edge fn (which does
// write but inside its own RLS-pinned scope — we're not creating new data
// here, only fetching), run_consilium reads memory blocks + calls Anthropic.

function adminClient() {
  return createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

async function handleListInbox(
  toolUseId: string,
  input: ListInboxInput,
  userId: string,
): Promise<ToolResultBlock> {
  const limit = Math.min(Math.max(input.limit ?? 10, 1), 20);
  const onlyUnread = input.only_unread === true;
  const sevMin = input.severity_min;
  const SEV_RANK: Record<string, number> = {
    LOW: 1,
    MEDIUM: 2,
    HIGH: 3,
    CRITICAL: 4,
  };
  const minRank = sevMin ? (SEV_RANK[sevMin] ?? 0) : 0;
  const sb = adminClient();
  let q = sb
    .from("email_threads")
    .select(
      "id, gmail_thread_id, subject, snippet, participants, last_message_at, " +
        "label_ids, triage_status",
    )
    .eq("user_id", userId)
    .order("last_message_at", { ascending: false })
    .limit(limit);
  if (onlyUnread) q = q.contains("label_ids", ["UNREAD"]);
  const { data: threads, error } = await q;
  if (error) {
    return {
      type: "tool_result",
      tool_use_id: toolUseId,
      content: `list_inbox failed: ${error.message}`,
      is_error: true,
    };
  }
  if (!threads || threads.length === 0) {
    return {
      type: "tool_result",
      tool_use_id: toolUseId,
      content: "Inbox is empty (no synced threads for this user yet).",
    };
  }
  // Join with latest triage_results for severity+brief.
  const threadRows = threads as unknown as Array<Record<string, unknown>>;
  const threadIds = threadRows.map((t) => t.id as string);
  const { data: triage } = await sb
    .from("email_triage_results")
    .select(
      "thread_id, severity, user_brief, draft_body, draft_subject, " +
        "send_recommendation, sent_at",
    )
    .in("thread_id", threadIds);
  const triageByThread: Record<string, Record<string, unknown>> = {};
  for (
    const r of ((triage ?? []) as unknown as Array<Record<string, unknown>>)
  ) {
    triageByThread[r.thread_id as string] = r;
  }
  const rows: Array<Record<string, unknown>> = [];
  for (const t of threadRows) {
    const tr = triageByThread[t.id as string];
    const sev = (tr?.severity as string) ?? "LOW";
    if (minRank > 0 && (SEV_RANK[sev] ?? 0) < minRank) continue;
    rows.push({
      thread_id: t.id,
      gmail_thread_id: t.gmail_thread_id,
      subject: t.subject,
      snippet: t.snippet,
      participants: t.participants,
      last_message_at: t.last_message_at,
      unread: Array.isArray(t.label_ids) &&
        (t.label_ids as string[]).includes("UNREAD"),
      severity: sev,
      user_brief: tr?.user_brief ?? null,
      has_draft: !!tr?.draft_body,
      already_sent: !!tr?.sent_at,
    });
  }
  return {
    type: "tool_result",
    tool_use_id: toolUseId,
    content: JSON.stringify({ threads: rows, count: rows.length }, null, 2),
  };
}

async function handleReadThreadFull(
  toolUseId: string,
  input: ReadThreadFullInput,
  userId: string,
): Promise<ToolResultBlock> {
  const tid = (input.thread_id ?? "").trim();
  if (!tid) {
    return {
      type: "tool_result",
      tool_use_id: toolUseId,
      content: "read_thread_full requires thread_id",
      is_error: true,
    };
  }
  const sb = adminClient();
  // Accept either uuid PK or gmail_thread_id string.
  const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    .test(tid);
  const threadQ = sb
    .from("email_threads")
    .select(
      "id, gmail_thread_id, subject, participants, last_message_at, label_ids",
    )
    .eq("user_id", userId);
  const { data: thread, error: tErr } = await (isUuid
    ? threadQ.eq("id", tid)
    : threadQ.eq("gmail_thread_id", tid)).maybeSingle();
  if (tErr || !thread) {
    return {
      type: "tool_result",
      tool_use_id: toolUseId,
      content: `read_thread_full: thread not found (${tid})`,
      is_error: true,
    };
  }
  const threadDbId = (thread as Record<string, unknown>).id as string;
  const [msgRes, attRes, triageRes] = await Promise.all([
    sb
      .from("email_messages")
      .select(
        "id, gmail_message_id, sender_email, sender_name, to_recipients, " +
          "cc_recipients, subject, body_plaintext, sent_at, has_attachments, " +
          "attachments_meta",
      )
      .eq("thread_id", threadDbId)
      .order("sent_at", { ascending: true }),
    sb
      .from("email_attachments")
      .select("id, filename, mime, size_bytes, parsed_text, parsed_at")
      .eq("thread_id", threadDbId)
      .order("downloaded_at", { ascending: true }),
    sb
      .from("email_triage_results")
      .select(
        "id, severity, user_brief, draft_body, draft_subject, draft_to, " +
          "draft_cc, draft_language, send_recommendation, proposed_actions, " +
          "lawyer_opinions, sent_at",
      )
      .eq("thread_id", threadDbId)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle(),
  ]);
  const msgRows = (msgRes.data ?? []) as unknown as Array<
    Record<string, unknown>
  >;
  const messages = msgRows.map((m) => ({
    sender: m.sender_name
      ? `${m.sender_name} <${m.sender_email}>`
      : m.sender_email,
    to: m.to_recipients,
    cc: m.cc_recipients,
    subject: m.subject,
    sent_at: m.sent_at,
    body: (m.body_plaintext as string | null)?.slice(0, 8000) ?? null,
    body_truncated:
      typeof m.body_plaintext === "string" && m.body_plaintext.length > 8000,
    has_attachments: m.has_attachments,
  }));
  const attRows = (attRes.data ?? []) as unknown as Array<
    Record<string, unknown>
  >;
  const attachments = attRows.map(
    (a) => ({
      attachment_id: a.id,
      filename: a.filename,
      mime: a.mime,
      size_bytes: a.size_bytes,
      already_parsed: !!a.parsed_text,
    }),
  );
  const triage = triageRes.data ?? null;
  return {
    type: "tool_result",
    tool_use_id: toolUseId,
    content: JSON.stringify(
      {
        thread: {
          id: threadDbId,
          gmail_thread_id: (thread as Record<string, unknown>).gmail_thread_id,
          subject: (thread as Record<string, unknown>).subject,
          participants: (thread as Record<string, unknown>).participants,
          last_message_at: (thread as Record<string, unknown>).last_message_at,
        },
        messages,
        attachments,
        triage,
      },
      null,
      2,
    ),
  };
}

async function handleRunPdfParser(
  toolUseId: string,
  input: RunPdfParserInput,
  userId: string,
): Promise<ToolResultBlock> {
  const attId = (input.attachment_id ?? "").trim();
  if (!attId) {
    return {
      type: "tool_result",
      tool_use_id: toolUseId,
      content: "run_pdf_parser requires attachment_id",
      is_error: true,
    };
  }
  const sb = adminClient();
  const { data: att, error: attErr } = await sb
    .from("email_attachments")
    .select(
      "id, user_id, thread_id, message_id, filename, mime, storage_path, " +
        "parsed_text, parsed_meta, parsed_at",
    )
    .eq("id", attId)
    .maybeSingle();
  if (attErr || !att) {
    return {
      type: "tool_result",
      tool_use_id: toolUseId,
      content: `run_pdf_parser: attachment not found (${attId})`,
      is_error: true,
    };
  }
  const a = att as unknown as Record<string, unknown>;
  if (a.user_id !== userId) {
    return {
      type: "tool_result",
      tool_use_id: toolUseId,
      content: "run_pdf_parser: attachment does not belong to caller",
      is_error: true,
    };
  }
  // If already parsed, return cached result (we don't re-bill OCR).
  if (a.parsed_text) {
    return {
      type: "tool_result",
      tool_use_id: toolUseId,
      content: JSON.stringify(
        {
          attachment_id: attId,
          filename: a.filename,
          cached: true,
          parsed_text: (a.parsed_text as string).slice(0, 5000),
          parsed_meta: a.parsed_meta,
          parsed_at: a.parsed_at,
        },
        null,
        2,
      ),
    };
  }
  // Otherwise, delegate to pdf-parser edge fn via internal-call bypass.
  try {
    const resp = await fetch(`${SUPABASE_URL}/functions/v1/pdf-parser`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        "Content-Type": "application/json",
        "x-internal-call": "claude-proxy",
      },
      body: JSON.stringify({
        user_id: userId,
        storage_path: a.storage_path,
        filename: a.filename,
        mime_type: a.mime,
      }),
    });
    if (!resp.ok) {
      const errText = await resp.text();
      return {
        type: "tool_result",
        tool_use_id: toolUseId,
        content:
          `run_pdf_parser: pdf-parser HTTP ${resp.status}: ${
            errText.slice(0, 200)
          }`,
        is_error: true,
      };
    }
    const data = await resp.json() as {
      document_id?: string;
      doc_type?: string;
      parsed_summary?: string;
      key_extractions?: unknown;
      page_count?: number;
      lang_detected?: string;
    };
    // Cache the parsed text back into email_attachments so subsequent
    // tool calls on the same attachment hit the fast path.
    await sb
      .from("email_attachments")
      .update({
        parsed_text: (data.parsed_summary ?? "").slice(0, 50000),
        parsed_meta: {
          document_id: data.document_id,
          doc_type: data.doc_type,
          key_extractions: data.key_extractions,
          page_count: data.page_count,
          lang_detected: data.lang_detected,
        },
        parsed_at: new Date().toISOString(),
      })
      .eq("id", attId);
    return {
      type: "tool_result",
      tool_use_id: toolUseId,
      content: JSON.stringify(
        {
          attachment_id: attId,
          filename: a.filename,
          cached: false,
          doc_type: data.doc_type,
          parsed_summary: (data.parsed_summary ?? "").slice(0, 5000),
          key_extractions: data.key_extractions,
          page_count: data.page_count,
          lang_detected: data.lang_detected,
        },
        null,
        2,
      ),
    };
  } catch (e) {
    return {
      type: "tool_result",
      tool_use_id: toolUseId,
      content: `run_pdf_parser failed: ${String(e).slice(0, 300)}`,
      is_error: true,
    };
  }
}

async function handleRunConsilium(
  toolUseId: string,
  input: RunConsiliumInput,
  _userId: string,
): Promise<ToolResultBlock> {
  const question = (input.question ?? "").trim();
  if (!question) {
    return {
      type: "tool_result",
      tool_use_id: toolUseId,
      content: "run_consilium requires question",
      is_error: true,
    };
  }
  const apiKey = Deno.env.get("ANTHROPIC_API_KEY") ?? "";
  if (!apiKey) {
    return {
      type: "tool_result",
      tool_use_id: toolUseId,
      content: "run_consilium: ANTHROPIC_API_KEY not configured",
      is_error: true,
    };
  }
  // The existing runConsilium streams events via onEvent. We capture them
  // into a structured array so the tool result returns each lawyer's
  // opinion + the final synthesis text. The function itself returns the
  // synthesis string when successful.
  try {
    const { runConsilium } = await import("../_shared/consilium.ts");
    const opinions: Array<{ name: string; opinion: string }> = [];
    let synthesisText = "";
    const synthesis = await runConsilium({
      userMessage: question,
      systemPrompt:
        "You are a senior legal consilium of specialised lawyers (FI immigration, " +
        "EU citizenship, ECHR, KHO procedure, criminal defence, EE admin, " +
        "cross-border, evidence, procedural strategy, identity errors, CJEU, " +
        "risk, communication, devil's advocate). Each role gives a structured " +
        "opinion. Reply in the user's language.",
      ragContext: "",
      caseContext: input.case_context ?? "",
      anthropicApiKey: apiKey,
      onEvent: (ev) => {
        // Capture per-role opinion events. The consilium SSE contract is
        // documented in consilium.ts:ConsiliumSSEEvent. We only care about
        // role_complete (one per lawyer) and synthesis_text (final).
        // deno-lint-ignore no-explicit-any
        const e = ev as any;
        if (e?.type === "role_complete" && typeof e?.opinion === "string") {
          opinions.push({
            name: typeof e?.role === "string"
              ? e.role
              : (typeof e?.name === "string" ? e.name : "lawyer"),
            opinion: e.opinion.slice(0, 2000),
          });
        } else if (
          e?.type === "synthesis_delta" && typeof e?.text === "string"
        ) {
          synthesisText += e.text;
        }
      },
    });
    // runConsilium returns the final synthesis text — prefer the explicit
    // captured text, fall back to the return value.
    const finalText = synthesisText.length > 0 ? synthesisText : synthesis;
    return {
      type: "tool_result",
      tool_use_id: toolUseId,
      content: JSON.stringify(
        {
          synthesis: finalText.slice(0, 8000),
          lawyer_count: opinions.length,
          opinions: opinions.slice(0, 15),
        },
        null,
        2,
      ),
    };
  } catch (e) {
    return {
      type: "tool_result",
      tool_use_id: toolUseId,
      content: `run_consilium failed: ${String(e).slice(0, 300)}`,
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
