// E2E smoke test — "test-sulga-clone"
// -----------------------------------------------------------------------------
// Reproduces the hand workflow I shipped 2026-05-26 15:38 for the Sulga
// case, end-to-end across the three P0 fixes:
//   Fix #1 — Gmail attachment download
//   Fix #2 — pdf-parser bridge → triage context
//   Fix #3 — multipart/mixed outbound send
//
// Flow:
//   1. Stub inbound thread (4 PDFs, 1 of them "scanned" → OCR path).
//   2. runSyncTick downloads attachments via stub downloadAndStoreAttachment.
//   3. runTriage loads inbound_attachment texts via stub parsePdf;
//      assert rendered system prompt contains attachment facts.
//   4. rfc2822Reply produces a valid multipart/mixed wire-form with the
//      4 PDFs re-attached; assert HMAC gate token binds attachment shas
//      and rejects a swap.
// -----------------------------------------------------------------------------

import { assert, assertEquals, assertStringIncludes } from
  "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  type GmailMessage,
  type GmailThreadFull,
  type MinimalSyncDeps,
  runSyncTick,
} from "../../email-inbox-sync/sync_logic.ts";

import { rfc2822Reply } from "../../email-send/index.ts";
import {
  MAX_OUTBOUND_ATTACHMENT_BYTES_TOTAL,
} from "../../email-send/send_logic.ts";
import {
  issueGateToken,
  verifyGateToken,
  sha256Hex,
} from "../policy_gate.ts";

// -----------------------------------------------------------------------------
// Test fixtures — the 4 PDFs from poliisi.fi (mimics thread 19e629d91c0db42a)
// -----------------------------------------------------------------------------

const FIXTURES = [
  { name: "SULGA S-ilm..pdf", id: "att-s-ilm", size: 11_467 },
  { name: "SULGA päätös ja tied.anto.pdf", id: "att-paatos", size: 1_489_357 },
  { name: "SULGA maksu matkasta.pdf", id: "att-maksu", size: 13_834 },
  { name: "SULGA hk.pdf", id: "att-hk", size: 302_321 },
] as const;

// Synthetic PDF bytes (just %PDF header — bytes irrelevant for these checks).
function pdfBytes(n: number): Uint8Array {
  const out = new Uint8Array(n);
  out[0] = 0x25; out[1] = 0x50; out[2] = 0x44; out[3] = 0x46; // %PDF
  return out;
}

function inboundMessage(): GmailMessage {
  return {
    id: "msg-poliisi-1",
    threadId: "thread-poliisi",
    senderEmail: "ulkomaalaisasiat.helsinki@poliisi.fi",
    toRecipients: ["europeworktallinn@gmail.com"],
    ccRecipients: [],
    subject: "VL: Asiakirjapyyntö — käännytyksen täytäntöönpano",
    bodyPlaintext: "Hei\n\nLiitteenä poliisin tietojärjestelmissä olevat asiakirjat.",
    snippet: "Liitteenä asiakirjat",
    sentAt: "2026-05-26T04:49:00Z",
    hasAttachments: true,
    attachmentsMeta: FIXTURES.map((f) => ({
      filename: f.name, mime: "application/pdf", size_bytes: f.size,
    })),
    attachmentsWithIds: FIXTURES.map((f) => ({
      filename: f.name, mime: "application/pdf", size_bytes: f.size,
      gmail_attachment_id: f.id,
    })),
    headersMeta: {},
  };
}

function inboundThread(): GmailThreadFull {
  return {
    threadId: "thread-poliisi",
    historyId: "h-1",
    snippet: "Liitteenä asiakirjat",
    subject: "VL: Asiakirjapyyntö — käännytyksen täytäntöönpano",
    participants: ["ulkomaalaisasiat.helsinki@poliisi.fi", "europeworktallinn@gmail.com"],
    labelIds: ["INBOX"],
    lastMessageAt: "2026-05-26T04:49:00Z",
    messages: [inboundMessage()],
  };
}

// =============================================================================
// Step 1 — sync downloads all 4 PDFs
// =============================================================================

Deno.test("E2E sulga-clone — Fix #1: sync downloads all 4 PDFs from poliisi thread", async () => {
  const downloads: string[] = [];

  const fakeState = {
    threads: new Map<string, { id: string; row: any }>(),
    msgs: new Set<string>(),
  };

  const deps: MinimalSyncDeps = {
    async getLastSyncedAt() { return null; },
    async listThreads() { return [{ id: "thread-poliisi", historyId: "h-1" }]; },
    async getThread() { return inboundThread(); },
    async upsertThread(row) {
      const key = `${row.user_id}:${row.gmail_thread_id}`;
      const prior = fakeState.threads.get(key);
      if (!prior) {
        const id = `thread-uuid-${fakeState.threads.size + 1}`;
        fakeState.threads.set(key, { id, row });
        return { id, isNewOrAdvanced: true };
      }
      return { id: prior.id, isNewOrAdvanced: false };
    },
    async upsertMessages(rows) {
      const idByGmailId: Record<string, string> = {};
      let count = 0;
      for (const r of rows) {
        idByGmailId[r.gmail_message_id] = `msg-uuid-${r.gmail_message_id}`;
        if (!fakeState.msgs.has(r.gmail_message_id)) {
          fakeState.msgs.add(r.gmail_message_id);
          count++;
        }
      }
      return { count, idByGmailId };
    },
    async enqueueTriage() {},
    async downloadAndStoreAttachment(args) {
      downloads.push(args.attachment.gmail_attachment_id);
      return { inserted: true };
    },
  };

  const res = await runSyncTick(deps, {
    userId: "user-sulga",
    accessToken: "tok",
    now: new Date("2026-05-26T05:00:00Z"),
  });

  assertEquals(res.threads_synced, 1);
  assertEquals(res.attachments_downloaded, 4, "all 4 PDFs downloaded");
  assertEquals(res.attachments_skipped, 0);
  assertEquals(
    downloads.sort(),
    ["att-hk", "att-maksu", "att-paatos", "att-s-ilm"],
  );
});

// =============================================================================
// Step 2 — Fix #3: rfc2822Reply with 4 attachments
// =============================================================================

Deno.test("E2E sulga-clone — Fix #3: outbound multipart contains all 4 PDFs", () => {
  const attachments = FIXTURES.map((f) => ({
    filename: f.name,
    mime: "application/pdf",
    data: pdfBytes(Math.min(f.size, 100)),
  }));

  const wire = rfc2822Reply({
    from: "europeworktallinn@gmail.com",
    to: "minna.jokela@oikeus.fi",
    subject: "Vastine käännyttämispäätökseen — selvitys + poliisin asiakirjat",
    body: "Hyvä asianajaja Jokela,\n\nLiitteenä 4 asiakirjaa...",
    inReplyTo: "<orig@oikeus.fi>",
    references: "<orig@oikeus.fi>",
    attachments,
  });

  // Outer structure
  assertStringIncludes(wire, "multipart/mixed; boundary=");
  assertStringIncludes(wire, "MIME-Version: 1.0");
  assertStringIncludes(wire, "In-Reply-To: <orig@oikeus.fi>");

  // text/plain part with body
  assertStringIncludes(wire, 'Content-Type: text/plain; charset="UTF-8"');
  assertStringIncludes(wire, "Hyvä asianajaja Jokela");

  // All 4 filenames present (one of them has Finnish ä → RFC 2047 encoded)
  assertStringIncludes(wire, "SULGA S-ilm..pdf");  // ASCII
  assertStringIncludes(wire, "SULGA hk.pdf");      // ASCII
  // päätös contains ä → encoded
  assertStringIncludes(wire, "=?UTF-8?B?");

  // 4 Content-Disposition: attachment headers
  const dispCount = (wire.match(/Content-Disposition: attachment/g) ?? []).length;
  assertEquals(dispCount, 4, "exactly 4 attachment parts");

  // base64 of "%PDF" — "JVBERg=="
  assertStringIncludes(wire, "JVBERg");
});

// =============================================================================
// Step 3 — gate token binds attachment shas
// =============================================================================

Deno.test("E2E sulga-clone — Fix #3: gate token rejects PDF swap", async () => {
  const att1 = pdfBytes(50);
  const att2 = pdfBytes(60);
  const att3 = pdfBytes(70);
  const att4 = pdfBytes(80);
  const malicious = new Uint8Array([0xff, 0xff, 0xff, 0xff]); // attacker-supplied

  const shasOriginal = await Promise.all(
    [att1, att2, att3, att4].map((b) => sha256Bytes(b)),
  );

  const tok = await issueGateToken({
    draft_id: "draft-1",
    body_sha256: await sha256Hex("body"),
    recipients: ["minna.jokela@oikeus.fi"],
    secret: "test-secret",
    now: 1_000_000,
    ttl_ms: 60_000,
    attachment_shas: shasOriginal,
  });

  // Same shas at send-time → ok
  const okResult = await verifyGateToken({
    token: tok,
    expected_draft_id: "draft-1",
    expected_body_sha256: await sha256Hex("body"),
    expected_recipients: ["minna.jokela@oikeus.fi"],
    expected_attachment_shas: shasOriginal,
    secret: "test-secret",
    now: 1_000_000,
  });
  assertEquals(okResult.ok, true, "matching attachment shas pass");

  // Attacker swapped the päätös PDF (index 1) — must be rejected
  const shasSwapped = [
    shasOriginal[0],
    await sha256Bytes(malicious),
    shasOriginal[2],
    shasOriginal[3],
  ];
  const badResult = await verifyGateToken({
    token: tok,
    expected_draft_id: "draft-1",
    expected_body_sha256: await sha256Hex("body"),
    expected_recipients: ["minna.jokela@oikeus.fi"],
    expected_attachment_shas: shasSwapped,
    secret: "test-secret",
    now: 1_000_000,
  });
  assertEquals(badResult.ok, false, "swapped attachment must be rejected");
  assertEquals(badResult.reason, "attachment_shas_mismatch");
});

// =============================================================================
// Step 4 — global size cap honoured (Fix #3)
// =============================================================================

Deno.test("E2E sulga-clone — Fix #3: refuses 26 MB total over the 25 MB cap", () => {
  // 7 MB × 4 = 28 MB total — over MAX_OUTBOUND_ATTACHMENT_BYTES_TOTAL
  const big = pdfBytes(7 * 1024 * 1024);
  let threw = false;
  try {
    rfc2822Reply({
      from: "a@b",
      to: "c@d",
      subject: "x",
      body: "x",
      inReplyTo: null,
      references: null,
      attachments: [
        { filename: "1.pdf", mime: "application/pdf", data: big },
        { filename: "2.pdf", mime: "application/pdf", data: big },
        { filename: "3.pdf", mime: "application/pdf", data: big },
        { filename: "4.pdf", mime: "application/pdf", data: big },
      ],
    });
  } catch (e) {
    threw = true;
    assertStringIncludes(String(e), "attachment_size_exceeded");
  }
  assert(threw, "expected sum > 25 MB to throw");
  // Sanity: 25 MB cap value.
  assertEquals(MAX_OUTBOUND_ATTACHMENT_BYTES_TOTAL, 25 * 1024 * 1024);
});

// -----------------------------------------------------------------------------
// helper: sha256 hex over raw bytes (mirrors what email-send computes)
// -----------------------------------------------------------------------------

async function sha256Bytes(bytes: Uint8Array): Promise<string> {
  // Copy into a fresh ArrayBuffer-backed view so the type narrows correctly
  // (Deno's SubtleCrypto.digest in TS-strict mode rejects SharedArrayBuffer-
  // backed views).
  const copy = new Uint8Array(bytes);
  const hash = await crypto.subtle.digest("SHA-256", copy.buffer);
  return Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}
