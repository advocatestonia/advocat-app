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
  extractAttachmentsMeta,
  extractPlaintextBody,
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
