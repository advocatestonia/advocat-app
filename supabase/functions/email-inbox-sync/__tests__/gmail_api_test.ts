// Deno tests for email-inbox-sync/gmail_api.ts (D3 parser).
// -----------------------------------------------------------------------------
// We exercise the parser against canonical Gmail-shaped payloads so a
// regression in header / body / attachment extraction is caught locally.
// The HTTP fetch path itself is not unit-tested (it's a thin URL builder
// + fetch).
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  decodeBase64UrlBytes,
  downloadAttachment,
  extractAttachmentsMeta,
  extractAttachmentsWithIds,
  extractPlaintextBody,
  MAX_ATTACHMENT_BYTES,
  parseAddrList,
  parseFromHeader,
  parseGmailMessage,
  parseGmailThread,
  stripSubjectPrefix,
} from "../gmail_api.ts";

// =============================================================================
// Header parsers
// =============================================================================

Deno.test("parseFromHeader — quoted name + email", () => {
  const r = parseFromHeader('"Minna Jokela" <minna.jokela@oikeus.fi>');
  assertEquals(r.name, "Minna Jokela");
  assertEquals(r.email, "minna.jokela@oikeus.fi");
});

Deno.test("parseFromHeader — bare email", () => {
  const r = parseFromHeader("kirjaamo@oikeus.fi");
  assertEquals(r.name, null);
  assertEquals(r.email, "kirjaamo@oikeus.fi");
});

Deno.test("parseFromHeader — unquoted name + email", () => {
  const r = parseFromHeader("Foo Bar <foo@bar.com>");
  assertEquals(r.name, "Foo Bar");
  assertEquals(r.email, "foo@bar.com");
});

Deno.test("parseAddrList — splits comma-separated", () => {
  const r = parseAddrList('"Foo" <foo@x>, bar@y, "Baz Qux" <baz@z>');
  assertEquals(r, ["foo@x", "bar@y", "baz@z"]);
});

Deno.test("parseAddrList — null returns empty", () => {
  assertEquals(parseAddrList(null), []);
});

Deno.test("stripSubjectPrefix — strips common reply prefixes", () => {
  assertEquals(stripSubjectPrefix("Re: hello"), "hello");
  assertEquals(stripSubjectPrefix("Fwd: hello"), "hello");
  assertEquals(stripSubjectPrefix("Vastaus: tervehdys"), "tervehdys");
  assertEquals(stripSubjectPrefix("Edasi: tere"), "tere");
  assertEquals(stripSubjectPrefix("hello"), "hello");
});

// =============================================================================
// Body extraction
// =============================================================================

function b64u(s: string): string {
  // base64url encode
  return btoa(unescape(encodeURIComponent(s)))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

Deno.test("extractPlaintextBody — direct text/plain payload", () => {
  const out = extractPlaintextBody({
    mimeType: "text/plain",
    body: { data: b64u("hello world") },
  });
  assertEquals(out, "hello world");
});

Deno.test("extractPlaintextBody — multipart prefers text/plain", () => {
  const out = extractPlaintextBody({
    mimeType: "multipart/alternative",
    parts: [
      { mimeType: "text/html", body: { data: b64u("<b>HTML</b>") } },
      { mimeType: "text/plain", body: { data: b64u("plain") } },
    ],
  });
  assertEquals(out, "plain");
});

Deno.test("extractPlaintextBody — falls back to HTML when no plain part", () => {
  const out = extractPlaintextBody({
    mimeType: "multipart/alternative",
    parts: [
      { mimeType: "text/html", body: { data: b64u("<p>hello</p>") } },
    ],
  });
  assert(out != null);
  assertStringIncludes(out, "hello");
});

Deno.test("extractAttachmentsMeta — extracts filename + mime + size", () => {
  const attrs = extractAttachmentsMeta({
    mimeType: "multipart/mixed",
    parts: [
      { mimeType: "text/plain", body: { data: b64u("body") } },
      {
        mimeType: "application/pdf",
        filename: "decision.pdf",
        body: { size: 12345, attachmentId: "att-1" },
      },
    ],
  });
  assertEquals(attrs.length, 1);
  assertEquals(attrs[0].filename, "decision.pdf");
  assertEquals(attrs[0].mime, "application/pdf");
  assertEquals(attrs[0].size_bytes, 12345);
});

// =============================================================================
// Full message parser
// =============================================================================

Deno.test("parseGmailMessage — populates email + headers + auto-reply meta", () => {
  const raw = {
    id: "m1",
    threadId: "t1",
    snippet: "Hello",
    internalDate: String(Date.UTC(2026, 4, 6, 10, 0, 0)),
    payload: {
      mimeType: "text/plain",
      headers: [
        { name: "From", value: '"Foo Bar" <foo@bar.com>' },
        { name: "To", value: "me@advocat.ee" },
        { name: "Subject", value: "Hello" },
        { name: "Auto-Submitted", value: "auto-replied" },
        { name: "Message-ID", value: "<msg-1@bar.com>" },
      ],
      body: { data: b64u("Hello body") },
    },
  };
  const m = parseGmailMessage(raw);
  assertEquals(m.senderEmail, "foo@bar.com");
  assertEquals(m.senderName, "Foo Bar");
  assertEquals(m.toRecipients, ["me@advocat.ee"]);
  assertEquals(m.subject, "Hello");
  assertEquals(m.bodyPlaintext, "Hello body");
  assertEquals(m.rfcMessageId, "<msg-1@bar.com>");
  assertEquals(m.headersMeta["Auto-Submitted"], "auto-replied");
});

Deno.test("parseGmailThread — sorts messages oldest first + collects participants", () => {
  const newer = {
    id: "m2",
    threadId: "t1",
    internalDate: String(Date.UTC(2026, 4, 6, 12, 0, 0)),
    payload: {
      mimeType: "text/plain",
      headers: [
        { name: "From", value: "b@x" },
        { name: "To", value: "me@advocat.ee" },
        { name: "Subject", value: "Re: Hello" },
      ],
      body: { data: b64u("two") },
    },
  };
  const older = {
    id: "m1",
    threadId: "t1",
    internalDate: String(Date.UTC(2026, 4, 6, 10, 0, 0)),
    payload: {
      mimeType: "text/plain",
      headers: [
        { name: "From", value: "a@x" },
        { name: "To", value: "me@advocat.ee" },
        { name: "Subject", value: "Hello" },
      ],
      body: { data: b64u("one") },
    },
  };
  const thread = parseGmailThread({
    id: "t1",
    historyId: "h-9",
    messages: [newer, older],
  });
  assertEquals(thread.messages[0].id, "m1");
  assertEquals(thread.messages[1].id, "m2");
  assertEquals(thread.subject, "Hello");
  assert(thread.participants.includes("a@x"));
  assert(thread.participants.includes("b@x"));
  assert(thread.participants.includes("me@advocat.ee"));
});

// =============================================================================
// Attachments — Fix #1 (2026-05-26)
// =============================================================================

function b64uBytes(bytes: number[]): string {
  // Helper: take raw bytes, base64url-encode them (the exact shape Gmail returns).
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

Deno.test("decodeBase64UrlBytes — round trip on canonical PDF magic", () => {
  // %PDF magic bytes
  const pdf = [0x25, 0x50, 0x44, 0x46, 0x2d, 0x31, 0x2e, 0x34];
  const encoded = b64uBytes(pdf);
  const decoded = decodeBase64UrlBytes(encoded);
  assertEquals(decoded.length, pdf.length);
  for (let i = 0; i < pdf.length; i++) assertEquals(decoded[i], pdf[i]);
});

Deno.test("decodeBase64UrlBytes — handles missing padding (Gmail style)", () => {
  // "any carnal pleas" → "YW55IGNhcm5hbCBwbGVhcw" (no =)
  const out = decodeBase64UrlBytes("YW55IGNhcm5hbCBwbGVhcw");
  const txt = new TextDecoder().decode(out);
  assertEquals(txt, "any carnal pleas");
});

Deno.test("decodeBase64UrlBytes — restores - and _ to + and /", () => {
  // Use a byte sequence that base64-encodes with '+' and '/' in standard base64.
  // 0xfb 0xff 0xbf → standard: "+/+/" → base64url: "-_-_"
  const out = decodeBase64UrlBytes("-_-_");
  assertEquals(out[0], 0xfb);
  assertEquals(out[1], 0xff);
  assertEquals(out[2], 0xbf);
});

Deno.test("extractAttachmentsWithIds — single PDF attachment", () => {
  const payload = {
    parts: [
      {
        mimeType: "text/plain",
        body: { data: "aGVsbG8" },
      },
      {
        mimeType: "application/pdf",
        filename: "SULGA päätös ja tied.anto.pdf",
        body: { attachmentId: "att-123", size: 1489357 },
      },
    ],
  };
  const out = extractAttachmentsWithIds(payload);
  assertEquals(out.length, 1);
  assertEquals(out[0].filename, "SULGA päätös ja tied.anto.pdf");
  assertEquals(out[0].mime, "application/pdf");
  assertEquals(out[0].size_bytes, 1489357);
  assertEquals(out[0].gmail_attachment_id, "att-123");
});

Deno.test("extractAttachmentsWithIds — multiple attachments + nested parts", () => {
  // Shape mirrors the real poliisi.fi thread 19e629d91c0db42a.
  const payload = {
    parts: [
      { mimeType: "text/plain", body: { data: "aGk" } },
      {
        mimeType: "multipart/alternative",
        parts: [
          {
            mimeType: "application/pdf",
            filename: "SULGA S-ilm..pdf",
            body: { attachmentId: "a1", size: 11467 },
          },
          {
            mimeType: "application/pdf",
            filename: "SULGA maksu matkasta.pdf",
            body: { attachmentId: "a2", size: 13834 },
          },
        ],
      },
      {
        mimeType: "application/pdf",
        filename: "SULGA hk.pdf",
        body: { attachmentId: "a3", size: 302321 },
      },
    ],
  };
  const out = extractAttachmentsWithIds(payload);
  assertEquals(out.length, 3);
  assertEquals(out.map((a) => a.gmail_attachment_id), ["a1", "a2", "a3"]);
});

Deno.test("extractAttachmentsWithIds — ignores parts without attachmentId", () => {
  // Inline image with cid: ref but no attachmentId (i.e. embedded via data URL)
  // must not be promoted to a download row.
  const payload = {
    parts: [
      { filename: "no-id.pdf", body: { size: 100 } }, // missing attachmentId
      { filename: "", body: { attachmentId: "att-x", size: 50 } }, // missing filename
    ],
  };
  assertEquals(extractAttachmentsWithIds(payload).length, 0);
});

Deno.test("downloadAttachment — happy path with stubbed fetch", async () => {
  const pdf = new Uint8Array([0x25, 0x50, 0x44, 0x46]); // %PDF
  const encoded = b64uBytes([...pdf]);

  const origFetch = globalThis.fetch;
  let capturedUrl: string | null = null;
  let capturedAuth: string | null = null;
  globalThis.fetch = ((url: string | URL | Request, init?: RequestInit) => {
    capturedUrl = String(url);
    capturedAuth = String((init?.headers as Record<string, string>)?.["Authorization"] ?? "");
    return Promise.resolve(new Response(
      JSON.stringify({ data: encoded, size: pdf.length }),
      { status: 200, headers: { "content-type": "application/json" } },
    ));
  }) as typeof fetch;
  try {
    const out = await downloadAttachment({
      accessToken: "tok-abc",
      messageId: "msg-1",
      attachmentId: "att-9",
    });
    assertEquals(out.size, pdf.length);
    assertEquals(out.data.length, pdf.length);
    assertEquals(out.data[0], 0x25);
    assert(capturedUrl!.endsWith("/users/me/messages/msg-1/attachments/att-9"));
    assertEquals(capturedAuth, "Bearer tok-abc");
  } finally {
    globalThis.fetch = origFetch;
  }
});

Deno.test("downloadAttachment — rejects oversized payload (size header)", async () => {
  const origFetch = globalThis.fetch;
  globalThis.fetch = (() =>
    Promise.resolve(new Response(
      JSON.stringify({ data: "AAAA", size: MAX_ATTACHMENT_BYTES + 1 }),
      { status: 200 },
    ))) as typeof fetch;
  try {
    let threw = false;
    try {
      await downloadAttachment({ accessToken: "t", messageId: "m", attachmentId: "a" });
    } catch (e) {
      threw = true;
      assertStringIncludes(String(e), "MAX_ATTACHMENT_BYTES");
    }
    assert(threw, "expected oversized payload to throw");
  } finally {
    globalThis.fetch = origFetch;
  }
});

Deno.test("downloadAttachment — surfaces HTTP error", async () => {
  const origFetch = globalThis.fetch;
  globalThis.fetch = (() =>
    Promise.resolve(new Response("forbidden", { status: 403 }))) as typeof fetch;
  try {
    let threw = false;
    try {
      await downloadAttachment({ accessToken: "t", messageId: "m", attachmentId: "a" });
    } catch (e) {
      threw = true;
      assertStringIncludes(String(e), "403");
    }
    assert(threw, "expected HTTP error to throw");
  } finally {
    globalThis.fetch = origFetch;
  }
});

Deno.test("downloadAttachment — throws on missing data field", async () => {
  const origFetch = globalThis.fetch;
  globalThis.fetch = (() =>
    Promise.resolve(new Response(JSON.stringify({ size: 0 }), { status: 200 }))) as typeof fetch;
  try {
    let threw = false;
    try {
      await downloadAttachment({ accessToken: "t", messageId: "m", attachmentId: "a" });
    } catch (e) {
      threw = true;
      assertStringIncludes(String(e), "data");
    }
    assert(threw, "expected missing data to throw");
  } finally {
    globalThis.fetch = origFetch;
  }
});
