// support-ticket/__tests__/support_ticket_test.ts
// -----------------------------------------------------------------------------
// Tests for the support-ticket edge function.
//
// Two layers:
//
//   1. Pure-function tests against telegram.ts — these verify MarkdownV2
//      escaping, message composition, line-break scrubbing, and the
//      sanitiseMessage helper. No network, no Supabase.
//
//   2. Wiring tests — exercise the helpers in combination the same way the
//      handler does so we catch any escape-order regressions before they
//      reach Telegram.
//
// The HTTP handler itself depends on Deno.serve + a live Supabase service
// role, so end-to-end exercise lives in the canary smoke script. The pure
// pieces below carry the bulk of the contract.
//
// Run:
//   deno test --allow-read --allow-env \
//     supabase/functions/support-ticket/__tests__/support_ticket_test.ts
// -----------------------------------------------------------------------------

import {
  assert,
  assertEquals,
  assertMatch,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  buildTelegramMessage,
  escapeMarkdownV2,
  sanitiseMessage,
  scrubLineBreaks,
} from "../telegram.ts";

// ─── escapeMarkdownV2 ────────────────────────────────────────────────────

Deno.test("ESC-T01 — escapes every MarkdownV2 special char", () => {
  // Every char from the canonical Telegram MarkdownV2 list must be backslash-
  // prefixed. If any character is missed Telegram returns 400 and our
  // notify fails silently.
  const specials = "_*[]()~`>#+-=|{}.!\\";
  const out = escapeMarkdownV2(specials);
  for (const ch of specials) {
    assertStringIncludes(out, `\\${ch}`, `missing escape for ${JSON.stringify(ch)}`);
  }
});

Deno.test("ESC-T02 — leaves plain ASCII letters and digits alone", () => {
  assertEquals(escapeMarkdownV2("Advocat 2026"), "Advocat 2026");
});

Deno.test("ESC-T03 — handles null and undefined safely", () => {
  assertEquals(escapeMarkdownV2(null), "");
  assertEquals(escapeMarkdownV2(undefined), "");
});

Deno.test("ESC-T04 — escapes characters that could form bold/italic injection", () => {
  // Without escaping, a user message like "*HACK*" would render as bold.
  // After escaping the asterisks must be literal.
  const out = escapeMarkdownV2("*HACK*");
  assertEquals(out, "\\*HACK\\*");
});

// ─── sanitiseMessage ─────────────────────────────────────────────────────

Deno.test("SAN-T01 — trims surrounding whitespace", () => {
  assertEquals(sanitiseMessage("   hello world   "), "hello world");
});

Deno.test("SAN-T02 — converts CRLF to LF", () => {
  assertEquals(sanitiseMessage("line1\r\nline2"), "line1\nline2");
});

Deno.test("SAN-T03 — converts lone CR to LF", () => {
  assertEquals(sanitiseMessage("line1\rline2"), "line1\nline2");
});

// ─── scrubLineBreaks ─────────────────────────────────────────────────────

Deno.test("SCRUB-T01 — replaces all line-break runs with single space", () => {
  assertEquals(scrubLineBreaks("a\r\nb\nc\r\r\nd"), "a b c d");
});

Deno.test("SCRUB-T02 — trims surrounding whitespace", () => {
  assertEquals(scrubLineBreaks("  hello  "), "hello");
});

// ─── buildTelegramMessage ────────────────────────────────────────────────

Deno.test("BUILD-T01 — happy path includes every header line", () => {
  const text = buildTelegramMessage({
    ticketId: "abc12345-aaaa-bbbb-cccc-dddddddddddd",
    category: "bug",
    contactChannel: "in_app",
    email: "user@example.com",
    userId: "uid-1",
    pageUrl: "https://advocat.ee/app.html",
    language: "et",
    appVersion: "1.2.0",
    message: "the chat freezes after second message",
  });

  // Title + every label.
  assertStringIncludes(text, "*New Support Ticket*");
  assertStringIncludes(text, "*Category:* bug");
  assertStringIncludes(text, "*Channel:* in\\_app"); // underscore escaped
  assertStringIncludes(text, "user@example\\.com");
  assertStringIncludes(text, "*Language:* et");
  assertStringIncludes(text, "*App version:* 1\\.2\\.0");
  // Message body is quoted line-by-line.
  assertStringIncludes(text, ">the chat freezes after second message");
});

Deno.test("BUILD-T02 — escapes injection attempt in message body", () => {
  const text = buildTelegramMessage({
    ticketId: "abcdef-0000-0000-0000-000000000000",
    category: "bug",
    contactChannel: "in_app",
    email: null,
    userId: null,
    pageUrl: "https://advocat.ee/app.html",
    language: "en",
    appVersion: "1.0.0",
    message: "*BOLD HACK*\n_italic hack_\n[link](https://evil.example)",
  });
  // Stars/underscores/brackets in the user's body must be escaped so they
  // render as literal text, not Markdown.
  assertStringIncludes(text, "\\*BOLD HACK\\*");
  assertStringIncludes(text, "\\_italic hack\\_");
  assertStringIncludes(text, "\\[link\\]\\(https://evil\\.example\\)");
});

Deno.test("BUILD-T03 — anonymous user renders as 'anonymous'", () => {
  const text = buildTelegramMessage({
    ticketId: "abcdef-0000-0000-0000-000000000001",
    category: "question",
    contactChannel: "in_app",
    email: null,
    userId: null,
    pageUrl: "https://advocat.ee/",
    language: "en",
    appVersion: "1.0.0",
    message: "0123456789", // exactly MIN — wiring concern not validated here
  });
  assertStringIncludes(text, "*User:* anonymous");
});

Deno.test("BUILD-T04 — anonymous with email is tagged '(anonymous)'", () => {
  const text = buildTelegramMessage({
    ticketId: "abcdef-0000-0000-0000-000000000002",
    category: "feature",
    contactChannel: "email",
    email: "anon@example.org",
    userId: null,
    pageUrl: "https://advocat.ee/",
    language: "en",
    appVersion: "1.0.0",
    message: "would love dark mode please",
  });
  assertStringIncludes(text, "anon@example\\.org (anonymous)");
});

Deno.test("BUILD-T05 — admin URL appended as inline link", () => {
  const text = buildTelegramMessage({
    ticketId: "feedfa-0000-0000-0000-000000000abc",
    category: "bug",
    contactChannel: "in_app",
    email: null,
    userId: "u1",
    pageUrl: "https://advocat.ee/app.html",
    language: "en",
    appVersion: "1.0.0",
    message: "something broken in chat please help",
    adminUrl: "https://advocat.ee/admin/tickets/feedfa-0000-0000-0000-000000000abc",
  });
  // Inline link syntax with the short ticket id as label.
  assertMatch(text, /\[Open ticket \\#feedfa\]\(https:\/\/advocat\.ee\/admin\/tickets\//);
});

Deno.test("BUILD-T06 — multiline message gets quote prefix on every line", () => {
  const text = buildTelegramMessage({
    ticketId: "feedfa-0000-0000-0000-000000000abd",
    category: "bug",
    contactChannel: "in_app",
    email: null,
    userId: "u1",
    pageUrl: "https://advocat.ee/",
    language: "en",
    appVersion: "1.0.0",
    message: "first line\nsecond line\nthird line",
  });
  assertStringIncludes(text, ">first line\n>second line\n>third line");
});

Deno.test("BUILD-T07 — message body cannot break out of quote block via newline", () => {
  // A malicious user inserts a fake "*PWNED*" header by including a newline
  // followed by Markdown — without per-line quoting + escaping this would
  // render as bold text outside the blockquote.
  const text = buildTelegramMessage({
    ticketId: "feedfa-0000-0000-0000-000000000ace",
    category: "other",
    contactChannel: "in_app",
    email: null,
    userId: "u1",
    pageUrl: "https://advocat.ee/",
    language: "en",
    appVersion: "1.0.0",
    message: "harmless\n*PWNED*\nmore",
  });
  // The injected bold MUST appear escaped AND quoted.
  assertStringIncludes(text, ">\\*PWNED\\*");
});

// ─── Handler-side validation expectations (documented contract) ──────────
//
// The HTTP handler in index.ts depends on Deno.serve and the Supabase
// service-role client, so it isn't exercised in this pure test file.
// The behaviours below ARE part of the contract and are smoke-tested
// against the deployed function in scripts/canary_smoke.sh:
//
//   * Valid POST              → 200 { ok: true, ticket_id }
//   * Honeypot `_hp` filled   → 400 { error, reason: "honeypot" }
//   * Message length < 10     → 400 { error, reason: "too_short" }
//   * Message length > 2000   → 400 { error, reason: "too_long" }
//   * Anon > 1 req/min        → 429 (handled by _shared/auth.ts)
//   * Auth > 10 tickets/24h   → 429 { reason: "rate_limited" }
//   * Telegram failure        → 200 (ticket persisted, telegram_sent=false)
//
// The pure tests above cover the message-composition / escaping halves of
// each rule. If either side regresses, fix the test first.

// ─── B2B inquiry (2026-05-26) ────────────────────────────────────────────

Deno.test("B2B-T01 — b2bLead title prefix renders as `[B2B LEAD]`", () => {
  const text = buildTelegramMessage({
    ticketId: "bbbbbbbb-0000-0000-0000-000000000001",
    category: "b2b_inquiry",
    contactChannel: "in_app",
    email: "partner@law.ee",
    userId: "uid-b2b",
    pageUrl: "https://advocat.ee/app.html",
    language: "et",
    appVersion: "1.2.0",
    message: "We have 8 lawyers, want a pilot",
    b2bLead: true,
    firmName: "Sirel & Partners",
    teamSize: "5-20",
    practices: "dispute, IP",
  });
  // Title prefix uses MarkdownV2-escaped brackets.
  assertStringIncludes(text, "\\[B2B LEAD\\] New Support Ticket");
  assertStringIncludes(text, "*Category:* b2b\\_inquiry");
  assertStringIncludes(text, "*Firm:* Sirel & Partners");
  assertStringIncludes(text, "*Team size:* 5\\-20");
  assertStringIncludes(text, "*Practices:* dispute, IP");
});

Deno.test("B2B-T02 — non-b2b ticket keeps original 🆘 title", () => {
  const text = buildTelegramMessage({
    ticketId: "aaaaaaaa-0000-0000-0000-000000000001",
    category: "bug",
    contactChannel: "in_app",
    email: null,
    userId: "u1",
    pageUrl: "https://advocat.ee/",
    language: "en",
    appVersion: "1.0.0",
    message: "something broken in chat please help",
  });
  assertStringIncludes(text, "🆘 *New Support Ticket*");
  // The B2B prefix MUST NOT appear when b2bLead is unset.
  assert(!text.includes("[B2B LEAD]"));
  assert(!text.includes("*Firm:*"));
});

Deno.test("B2B-T03 — empty firm/team/practices fields are silently skipped", () => {
  const text = buildTelegramMessage({
    ticketId: "bbbbbbbb-0000-0000-0000-000000000002",
    category: "b2b_inquiry",
    contactChannel: "email",
    email: "anon@law.ee",
    userId: null,
    pageUrl: "https://advocat.ee/",
    language: "en",
    appVersion: "1.0.0",
    message: "Curious about pricing for a 12-lawyer firm.",
    b2bLead: true,
    firmName: "",
    teamSize: undefined,
    practices: "",
  });
  // Prefix still wins.
  assertStringIncludes(text, "\\[B2B LEAD\\]");
  // No empty Firm:/Team size: lines.
  assert(!text.includes("*Firm:*"));
  assert(!text.includes("*Team size:*"));
  assert(!text.includes("*Practices:*"));
});

Deno.test("B2B-T04 — injection attempt in firm_name is escaped", () => {
  const text = buildTelegramMessage({
    ticketId: "bbbbbbbb-0000-0000-0000-000000000003",
    category: "b2b_inquiry",
    contactChannel: "in_app",
    email: "x@law.fi",
    userId: "u-b",
    pageUrl: "https://advocat.ee/",
    language: "fi",
    appVersion: "1.0.0",
    message: "We want a custom plan with SSO.",
    b2bLead: true,
    firmName: "*PWN* [link](https://evil)",
    teamSize: "20+",
    practices: "* / _ / `",
  });
  // Specials in firm name must render literally.
  assertStringIncludes(text, "*Firm:* \\*PWN\\* \\[link\\]\\(https://evil\\)");
  assertStringIncludes(text, "*Team size:* 20\\+");
  assertStringIncludes(text, "*Practices:* \\* / \\_ / \\`");
});

Deno.test("CONTRACT-T01 — sanitiseMessage feeds buildTelegramMessage cleanly", () => {
  // The handler calls sanitiseMessage(raw) then passes the result into
  // buildTelegramMessage. We re-execute that pipeline here to lock in the
  // contract that line breaks survive sanitisation but stray CRs do not
  // produce double blank lines in the quote block.
  const raw = "  line A\r\nline B\rline C  ";
  const cleaned = sanitiseMessage(raw);
  assert(cleaned.length >= 10);
  const out = buildTelegramMessage({
    ticketId: "feedfa-0000-0000-0000-000000000001",
    category: "bug",
    contactChannel: "in_app",
    email: null,
    userId: null,
    pageUrl: "https://advocat.ee/",
    language: "en",
    appVersion: "1.0.0",
    message: cleaned,
  });
  assertStringIncludes(out, ">line A");
  assertStringIncludes(out, ">line B");
  assertStringIncludes(out, ">line C");
});
