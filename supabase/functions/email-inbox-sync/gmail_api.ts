// email-inbox-sync/gmail_api.ts
// -----------------------------------------------------------------------------
// Thin Gmail API v1 client. Two endpoints only:
//
//   1. users.threads.list   — paginated thread index, server-side query.
//   2. users.threads.get    — full thread incl. messages + payload.
//
// We intentionally do not depend on googleapis SDK — Deno on Supabase Edge
// has a 1 MB function bundle ceiling and the SDK is heavy. The REST shape
// is stable and the parsing is small.
// -----------------------------------------------------------------------------

import type { GmailMessage, GmailThreadFull } from "./sync_logic.ts";

const GMAIL_API_BASE = "https://gmail.googleapis.com/gmail/v1";

interface GmailListThreadsResponse {
  threads?: Array<{ id: string; historyId?: string; snippet?: string }>;
  nextPageToken?: string;
}

interface GmailHeader {
  name: string;
  value: string;
}

interface GmailPayload {
  partId?: string;
  mimeType?: string;
  filename?: string;
  headers?: GmailHeader[];
  body?: { size?: number; data?: string; attachmentId?: string };
  parts?: GmailPayload[];
}

interface GmailRawMessage {
  id: string;
  threadId: string;
  labelIds?: string[];
  snippet?: string;
  payload?: GmailPayload;
  internalDate?: string; // ms since epoch as string
}

interface GmailRawThread {
  id: string;
  historyId?: string;
  messages?: GmailRawMessage[];
}

/**
 * List threads matching `q`, capped at `maxResults`. Returns thread ids
 * only — caller fetches full content via [getThreadFull]. Errors raise.
 */
export async function listThreads(args: {
  accessToken: string;
  sinceMs: number;
  maxResults: number;
}): Promise<Array<{ id: string; historyId?: string | null }>> {
  const sinceSec = Math.floor(args.sinceMs / 1000);
  const q = `after:${sinceSec} -category:promotions -category:social ` +
    `-in:trash -in:spam`;
  const url = new URL(`${GMAIL_API_BASE}/users/me/threads`);
  url.searchParams.set("q", q);
  url.searchParams.set("maxResults", String(args.maxResults));
  const resp = await fetch(url.toString(), {
    headers: {
      "Authorization": `Bearer ${args.accessToken}`,
    },
  });
  if (!resp.ok) {
    throw new Error(`Gmail list threads ${resp.status}: ${await resp.text()}`);
  }
  const body = (await resp.json()) as GmailListThreadsResponse;
  return (body.threads ?? []).map((t) => ({
    id: t.id,
    historyId: t.historyId ?? null,
  }));
}

/**
 * Fetch one full thread (all messages, all headers, full body). Returns
 * null on 404 (thread deleted between list and get).
 */
export async function getThreadFull(args: {
  accessToken: string;
  threadId: string;
}): Promise<GmailThreadFull | null> {
  const url = new URL(
    `${GMAIL_API_BASE}/users/me/threads/${encodeURIComponent(args.threadId)}`,
  );
  url.searchParams.set("format", "full");
  const resp = await fetch(url.toString(), {
    headers: {
      "Authorization": `Bearer ${args.accessToken}`,
    },
  });
  if (resp.status === 404) return null;
  if (!resp.ok) {
    throw new Error(`Gmail get thread ${resp.status}: ${await resp.text()}`);
  }
  const raw = (await resp.json()) as GmailRawThread;
  return parseGmailThread(raw);
}

// =============================================================================
// Parser — exported for tests
// =============================================================================

/** Translate a raw Gmail thread into our normalised shape. */
export function parseGmailThread(raw: GmailRawThread): GmailThreadFull {
  const messages: GmailMessage[] = [];
  for (const m of raw.messages ?? []) {
    messages.push(parseGmailMessage(m));
  }
  // sort oldest -> newest
  messages.sort((a, b) => a.sentAt.localeCompare(b.sentAt));
  const lastMessageAt = messages.length > 0
    ? messages[messages.length - 1].sentAt
    : new Date(0).toISOString();
  // Participants: union of From/To/Cc across messages, plain emails.
  const participants = new Set<string>();
  let firstSubject: string | null = null;
  for (const m of messages) {
    if (m.senderEmail) participants.add(m.senderEmail);
    for (const r of m.toRecipients) participants.add(r);
    for (const r of m.ccRecipients) participants.add(r);
    if (firstSubject == null && m.subject) {
      firstSubject = stripSubjectPrefix(m.subject);
    }
  }
  // Label ids: union of label ids across messages (not in our shape per
  // message — keep the raw thread snippet for display).
  const labelIds: string[] = [];
  return {
    threadId: raw.id,
    historyId: raw.historyId ?? null,
    snippet: messages[messages.length - 1]?.snippet ?? null,
    subject: firstSubject,
    participants: [...participants],
    labelIds,
    lastMessageAt,
    messages,
  };
}

/** Translate a raw Gmail message. Exported for tests. */
export function parseGmailMessage(raw: GmailRawMessage): GmailMessage {
  const headers = raw.payload?.headers ?? [];
  const h = (name: string) => headerValue(headers, name);
  const sentAtMs = Number(raw.internalDate ?? "0");
  const sentAt = isFinite(sentAtMs) && sentAtMs > 0
    ? new Date(sentAtMs).toISOString()
    : new Date().toISOString();
  const fromHeader = h("From") ?? "";
  const { email: senderEmail, name: senderName } = parseFromHeader(fromHeader);
  const to = parseAddrList(h("To"));
  const cc = parseAddrList(h("Cc"));
  const subject = h("Subject");
  const rfcMessageId = h("Message-ID") ?? h("Message-Id") ?? null;
  const bodyPlaintext = extractPlaintextBody(raw.payload);
  const attachmentsMeta = extractAttachmentsMeta(raw.payload);
  const headersMeta: Record<string, string> = {};
  // Persist a small whitelist of headers used downstream (auto-reply
  // detection per Rule 23).
  for (const interesting of [
    "Auto-Submitted", "X-Autoreply", "Precedence",
    "List-Unsubscribe", "Reply-To", "Return-Path",
  ]) {
    const v = h(interesting);
    if (v) headersMeta[interesting] = v;
  }
  return {
    id: raw.id,
    threadId: raw.threadId,
    rfcMessageId,
    senderEmail,
    senderName,
    toRecipients: to,
    ccRecipients: cc,
    subject: subject ?? null,
    bodyPlaintext,
    snippet: raw.snippet ?? null,
    sentAt,
    hasAttachments: attachmentsMeta.length > 0,
    attachmentsMeta,
    headersMeta,
  };
}

// =============================================================================
// Header / body helpers — pure
// =============================================================================

function headerValue(headers: GmailHeader[], name: string): string | null {
  const lower = name.toLowerCase();
  for (const h of headers) {
    if ((h.name ?? "").toLowerCase() === lower) {
      return (h.value ?? "").trim();
    }
  }
  return null;
}

/** Parse an RFC-5322 From header. Tolerant: returns email + optional name. */
export function parseFromHeader(s: string): { email: string; name: string | null } {
  const trimmed = s.trim();
  if (trimmed.length === 0) return { email: "", name: null };
  // Pattern: "Display Name" <email@x>  OR  Display Name <email@x>  OR  email@x
  const angle = /^(?:"?(.*?)"?\s*)?<([^>]+)>$/.exec(trimmed);
  if (angle) {
    const rawName = (angle[1] ?? "").trim();
    return {
      email: angle[2].trim(),
      name: rawName.length > 0 ? rawName : null,
    };
  }
  return { email: trimmed, name: null };
}

/** Parse an RFC-5322 To/Cc list. Returns plain email strings. */
export function parseAddrList(s: string | null): string[] {
  if (!s) return [];
  // Naive split at commas not inside quotes — sufficient for canonical Gmail output.
  const parts = s.split(/,(?=(?:[^"]*"[^"]*")*[^"]*$)/);
  const out: string[] = [];
  for (const p of parts) {
    const { email } = parseFromHeader(p);
    if (email.length > 0) out.push(email);
  }
  return out;
}

/** Strip common reply prefixes from a Subject for thread title canonicalisation. */
export function stripSubjectPrefix(s: string): string {
  return s.replace(/^(?:re|fwd?|vs|vastaus|edasi|пере)\s*:\s*/i, "").trim();
}

/**
 * Walk a Gmail payload tree and pull out the first text/plain body. Falls
 * back to text/html stripped of tags when no plaintext part exists.
 * Multi-byte safe via TextDecoder.
 */
export function extractPlaintextBody(payload?: GmailPayload): string | null {
  if (!payload) return null;
  // Direct plain body.
  if (payload.mimeType === "text/plain" && payload.body?.data) {
    return decodeBody(payload.body.data);
  }
  // Walk parts, prefer text/plain.
  if (payload.parts && payload.parts.length > 0) {
    let htmlFallback: string | null = null;
    for (const part of payload.parts) {
      const sub = extractPlaintextBody(part);
      if (sub != null && part.mimeType === "text/plain") {
        return sub;
      }
      if (sub != null && part.mimeType === "text/html") {
        htmlFallback ??= htmlToText(sub);
      }
    }
    if (htmlFallback != null) return htmlFallback;
    // Walk again allowing any sub-text from nested parts.
    for (const part of payload.parts) {
      const sub = extractPlaintextBody(part);
      if (sub != null) return sub;
    }
  }
  if (payload.mimeType === "text/html" && payload.body?.data) {
    return htmlToText(decodeBody(payload.body.data));
  }
  return null;
}

/** Pull out attachment metadata. */
export function extractAttachmentsMeta(
  payload?: GmailPayload,
): Array<{ filename: string; mime: string; size_bytes: number }> {
  const out: Array<{ filename: string; mime: string; size_bytes: number }> = [];
  if (!payload) return out;
  const walk = (p: GmailPayload) => {
    if (p.filename && p.filename.length > 0 && p.body?.attachmentId) {
      out.push({
        filename: p.filename,
        mime: p.mimeType ?? "application/octet-stream",
        size_bytes: p.body.size ?? 0,
      });
    }
    for (const sub of p.parts ?? []) walk(sub);
  };
  walk(payload);
  return out;
}

/** Decode Gmail's URL-safe base64. */
function decodeBody(data: string): string {
  // Gmail uses base64url (no padding). Restore.
  const padded = data + "=".repeat((4 - data.length % 4) % 4);
  const std = padded.replace(/-/g, "+").replace(/_/g, "/");
  try {
    const bin = atob(std);
    const bytes = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
    return new TextDecoder("utf-8", { fatal: false }).decode(bytes);
  } catch (_) {
    return "";
  }
}

/** Cheap HTML → text. Strip tags + collapse whitespace. */
function htmlToText(html: string): string {
  return html
    .replace(/<style[\s\S]*?<\/style>/gi, " ")
    .replace(/<script[\s\S]*?<\/script>/gi, " ")
    .replace(/<br\s*\/?\s*>/gi, "\n")
    .replace(/<\/p>/gi, "\n\n")
    .replace(/<[^>]+>/g, " ")
    .replace(/&nbsp;/gi, " ")
    .replace(/&amp;/gi, "&")
    .replace(/&lt;/gi, "<")
    .replace(/&gt;/gi, ">")
    .replace(/&quot;/gi, '"')
    .replace(/&#39;/gi, "'")
    .replace(/[ \t]+/g, " ")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}
