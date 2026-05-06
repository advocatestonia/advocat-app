// Deno tests for Phase 2 Pkg 2 closeout — streaming-branch citations.
// -----------------------------------------------------------------------------
// Covers design §9 risk #2 ("if anyone changes the proxy to streaming mode
// (Anthropic SSE), verifier needs to run on the post-stream concat, NOT
// per-event"):
//
//   • accumulator collects ONLY text_delta payloads (not thinking_delta,
//     not input_json_delta, not server_tool_use blocks).
//   • formatCitationsSseEvent produces a valid `event: citations\ndata: ...
//     \n\n` frame.
//   • wrapAnthropicStreamWithCitations forwards every upstream byte
//     UNCHANGED and APPENDS one trailing citations frame on close.
//   • Empty stream → trailing citations: [] frame still emitted (Flutter
//     parser depends on the field being present).
//   • Source-text wiring pins on claude-proxy/index.ts confirming the
//     streaming branch wraps the upstream now (was raw pass-through).
//
// Run with:
//   deno test --allow-read \
//     supabase/functions/claude-proxy/__tests__/citations_streaming_test.ts
// -----------------------------------------------------------------------------

import {
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  accumulateTextFromSseEvent,
  formatCitationsSseEvent,
  parseSseDataLine,
  verifyStreamedReply,
  wrapAnthropicStreamWithCitations,
} from "../streaming_citations.ts";
import type { GroundingChunk } from "../../_shared/citation_grounder.ts";

// ─── fixtures ──────────────────────────────────────────────────────────────

function tlsChunk(): GroundingChunk {
  return {
    id: "tls-§88-1",
    act_slug: "tls",
    paragraph: "88",
    act_name: "Töölepingu seadus",
    title: "Tööandja erakorraline ülesütlemine",
    body: "Tööandja võib töölepingu erakorraliselt üles öelda…",
    source_url: "https://www.riigiteataja.ee/akt/tls",
    jurisdiction: "EE",
    in_force: true,
  };
}

/** Helper: turn a string into a single-chunk ReadableStream<Uint8Array>. */
function streamFrom(s: string): ReadableStream<Uint8Array> {
  const encoded = new TextEncoder().encode(s);
  return new ReadableStream<Uint8Array>({
    start(controller) {
      controller.enqueue(encoded);
      controller.close();
    },
  });
}

/** Helper: turn a string into a multi-chunk stream (split across N points)
 *  to exercise mid-line buffering. */
function streamFromChunks(chunks: string[]): ReadableStream<Uint8Array> {
  const enc = new TextEncoder();
  let i = 0;
  return new ReadableStream<Uint8Array>({
    pull(controller) {
      if (i >= chunks.length) {
        controller.close();
        return;
      }
      controller.enqueue(enc.encode(chunks[i]));
      i++;
    },
  });
}

/** Helper: drain a ReadableStream<Uint8Array> to a single string. */
async function drain(stream: ReadableStream<Uint8Array>): Promise<string> {
  const reader = stream.getReader();
  const dec = new TextDecoder();
  let out = "";
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    out += dec.decode(value, { stream: true });
  }
  out += dec.decode();
  return out;
}

// ─── Accumulator behaviour ─────────────────────────────────────────────────

Deno.test("CIT-STREAM-T01 — accumulator collects ONLY text_delta payloads", () => {
  const buf = { text: "" };
  // text_delta — accumulated.
  accumulateTextFromSseEvent(
    { type: "content_block_delta", delta: { type: "text_delta", text: "Hello " } },
    buf,
  );
  accumulateTextFromSseEvent(
    {
      type: "content_block_delta",
      delta: { type: "text_delta", text: "[[ref:TLS:88]]" },
    },
    buf,
  );
  // thinking_delta — IGNORED. Marker in chain-of-thought must not count.
  accumulateTextFromSseEvent(
    {
      type: "content_block_delta",
      delta: { type: "thinking_delta", text: "[[ref:KarS:121]]" },
    },
    buf,
  );
  // input_json_delta — IGNORED (tool use args, not prose).
  accumulateTextFromSseEvent(
    {
      type: "content_block_delta",
      delta: { type: "input_json_delta", partial_json: '{"q":' },
    },
    buf,
  );
  // signature_delta — IGNORED.
  accumulateTextFromSseEvent(
    {
      type: "content_block_delta",
      delta: { type: "signature_delta", signature: "abc" },
    },
    buf,
  );
  // Non-delta event — IGNORED.
  accumulateTextFromSseEvent(
    { type: "message_start", message: { id: "msg_1" } },
    buf,
  );
  // Malformed inputs — silently ignored.
  accumulateTextFromSseEvent(null, buf);
  accumulateTextFromSseEvent({}, buf);
  accumulateTextFromSseEvent({ type: "content_block_delta" }, buf);

  assertEquals(buf.text, "Hello [[ref:TLS:88]]");
});

Deno.test("CIT-STREAM-T02 — parseSseDataLine handles canonical and edge forms", () => {
  // Canonical "data: {json}".
  assertEquals(parseSseDataLine('data: {"x":1}'), { x: 1 });
  // Multi-space tolerance.
  assertEquals(parseSseDataLine('data:   {"y":2}'), { y: 2 });
  // event: lines are NOT data lines — return null.
  assertEquals(parseSseDataLine("event: message_start"), null);
  // Comment lines (start with `:`) — null.
  assertEquals(parseSseDataLine(": keep-alive"), null);
  // Empty payload — null.
  assertEquals(parseSseDataLine("data:"), null);
  // Malformed JSON — null (don't throw).
  assertEquals(parseSseDataLine("data: {not json"), null);
});

// ─── SSE frame formatter ───────────────────────────────────────────────────

Deno.test(
  "CIT-STREAM-T03 — formatCitationsSseEvent emits a valid SSE frame",
  () => {
    const frame = formatCitationsSseEvent({
      citations: [],
      message_id: "550e8400-e29b-41d4-a716-446655440000",
    });
    // Event name MUST be `citations` so the Flutter SSE parser routes it.
    assertStringIncludes(frame, "event: citations\n");
    // Data line: one JSON payload.
    assertStringIncludes(frame, 'data: {"citations":[]');
    assertStringIncludes(frame, '"message_id":"550e8400-');
    // Frame terminator: trailing blank line is required by the SSE protocol.
    assertEquals(frame.endsWith("\n\n"), true);
  },
);

Deno.test(
  "CIT-STREAM-T04 — formatCitationsSseEvent strips \\r so SSE protocol is preserved",
  () => {
    // Some upstream proxies normalise \n to \r\n inside JSON strings, which
    // would break SSE framing. The formatter MUST flatten those.
    const frame = formatCitationsSseEvent({
      citations: [
        {
          marker: "[[ref:TLS:88]]\r",
          status: "verified",
          chunk_id: "tls-§88-1",
          act_slug: "tls",
          paragraph: "88",
          act_name: "TLS",
          title: null,
          snippet: "snippet\rwith CR",
          source_url: "https://example.com",
          jurisdiction: "EE",
          in_force: true,
          occurrences: 1,
        },
      ],
      message_id: null,
    });
    assertEquals(frame.includes("\r"), false);
  },
);

// ─── verifyStreamedReply (thin wrapper) ────────────────────────────────────

Deno.test(
  "CIT-STREAM-T05 — verifyStreamedReply matches assembled text against rag chunks",
  () => {
    const out = verifyStreamedReply(
      "Tööandja võib lepingu erakorraliselt üles öelda [[ref:TLS:88]].",
      [tlsChunk()],
    );
    assertEquals(out.length, 1);
    assertEquals(out[0].status, "verified");
    assertEquals(out[0].chunk_id, "tls-§88-1");
  },
);

// ─── End-to-end stream wrap: pass-through + trailing citations event ──────

Deno.test(
  "CIT-STREAM-T06 — wrapAnthropicStreamWithCitations forwards every byte unchanged",
  async () => {
    // Build a fake upstream Anthropic SSE pipe with one text delta.
    const upstreamPayload = [
      "event: message_start",
      'data: {"type":"message_start","message":{"id":"msg_1"}}',
      "",
      "event: content_block_delta",
      'data: {"type":"content_block_delta","delta":{"type":"text_delta","text":"Plain reply, no markers"}}',
      "",
      "event: message_stop",
      'data: {"type":"message_stop"}',
      "",
    ].join("\n");
    const wrapped = wrapAnthropicStreamWithCitations(streamFrom(upstreamPayload), {
      ragChunks: [],
      messageId: null,
    });
    const out = await drain(wrapped);
    // Every upstream line MUST appear unchanged in the downstream output.
    for (const line of upstreamPayload.split("\n")) {
      if (line) assertStringIncludes(out, line);
    }
    // Trailing citations event always present.
    assertStringIncludes(out, "event: citations\n");
    assertStringIncludes(out, '"citations":[]');
  },
);

Deno.test(
  "CIT-STREAM-T07 — accumulator survives mid-frame TCP chunk splits",
  async () => {
    // Simulate the marker text being split across two TCP chunks
    // (`[[ref:TLS:` + `88]]`). The shadow parser MUST still match.
    const chunks = [
      'event: content_block_delta\ndata: {"type":"content_block_delta","delta":{"type":"text_delta","text":"',
      'Verbatim [[ref:TLS:',
      '88]] applies"}}',
      "\n\nevent: message_stop\ndata: {\"type\":\"message_stop\"}\n\n",
    ];
    const wrapped = wrapAnthropicStreamWithCitations(streamFromChunks(chunks), {
      ragChunks: [tlsChunk()],
      messageId: null,
    });
    const out = await drain(wrapped);
    // The trailing citations frame must contain a verified TLS:88 entry.
    assertStringIncludes(out, "event: citations\n");
    assertStringIncludes(out, '"status":"verified"');
    assertStringIncludes(out, '"chunk_id":"tls-§88-1"');
  },
);

Deno.test(
  "CIT-STREAM-T08 — empty upstream still emits trailing citations:[] frame",
  async () => {
    // Anthropic occasionally closes the stream without ANY text deltas
    // (tool_use only path). The client SSE parser still needs the
    // trailing frame so it can update its UI state ("0 citations") rather
    // than waiting forever.
    const wrapped = wrapAnthropicStreamWithCitations(streamFrom(""), {
      ragChunks: [tlsChunk()],
      messageId: "550e8400-e29b-41d4-a716-446655440000",
    });
    const out = await drain(wrapped);
    assertStringIncludes(out, "event: citations\n");
    assertStringIncludes(out, '"citations":[]');
    assertStringIncludes(out, '"message_id":"550e8400-');
  },
);

Deno.test(
  "CIT-STREAM-T09 — message_id surfaces in the trailing citations frame",
  async () => {
    const upstream = [
      'data: {"type":"content_block_delta","delta":{"type":"text_delta","text":"[[ref:TLS:88]]"}}',
      "",
      'data: {"type":"message_stop"}',
      "",
    ].join("\n");
    const wrapped = wrapAnthropicStreamWithCitations(streamFrom(upstream), {
      ragChunks: [tlsChunk()],
      messageId: "11111111-2222-3333-4444-555555555555",
    });
    const out = await drain(wrapped);
    assertStringIncludes(out, '"message_id":"11111111-2222-3333-4444-555555555555"');
  },
);

Deno.test(
  "CIT-STREAM-T10 — onCitations hook fires with verifier output before the SSE frame",
  async () => {
    // Persistence is plumbed via an `onCitations` callback so the wrap
    // module stays I/O-free. We verify the callback is invoked and
    // receives the verifier output.
    let captured: unknown[] | null = null;
    const upstream = [
      'data: {"type":"content_block_delta","delta":{"type":"text_delta","text":"[[ref:TLS:88]]"}}',
      "",
      'data: {"type":"message_stop"}',
      "",
    ].join("\n");
    const wrapped = wrapAnthropicStreamWithCitations(streamFrom(upstream), {
      ragChunks: [tlsChunk()],
      messageId: "11111111-2222-3333-4444-555555555555",
      onCitations: (citations) => {
        captured = citations as unknown[];
      },
    });
    await drain(wrapped);
    if (captured === null) {
      throw new Error("onCitations was never called despite N citations > 0");
    }
    assertEquals((captured as unknown[]).length, 1);
  },
);

Deno.test(
  "CIT-STREAM-T11 — onCitations errors do not break the trailing SSE frame",
  async () => {
    // Persistence failure must not block the citations event — the chips
    // still render even when the DB write fails.
    const upstream = [
      'data: {"type":"content_block_delta","delta":{"type":"text_delta","text":"[[ref:TLS:88]]"}}',
      "",
      'data: {"type":"message_stop"}',
      "",
    ].join("\n");
    const wrapped = wrapAnthropicStreamWithCitations(streamFrom(upstream), {
      ragChunks: [tlsChunk()],
      messageId: null,
      onCitations: () => {
        throw new Error("simulated persistence failure");
      },
    });
    const out = await drain(wrapped);
    assertStringIncludes(out, "event: citations\n");
    assertStringIncludes(out, '"status":"verified"');
  },
);

// ─── Wiring contract: source-text pins on claude-proxy/index.ts ────────────

Deno.test(
  "CIT-STREAM-T12 — index.ts streaming branch imports the wrap helper",
  async () => {
    const source = await Deno.readTextFile(
      new URL("../index.ts", import.meta.url),
    );
    assertStringIncludes(source, "./streaming_citations.ts");
    assertStringIncludes(source, "wrapAnthropicStreamWithCitations");
  },
);

Deno.test(
  "CIT-STREAM-T13 — streaming branch no longer pipes raw upstream body",
  async () => {
    // The old behaviour was `new Response(claudeStreamResponse.body, ...)`.
    // Closeout requires wrapping that body before constructing the
    // Response, otherwise the trailing citations frame can never be
    // appended.
    const source = await Deno.readTextFile(
      new URL("../index.ts", import.meta.url),
    );
    // Pin: somewhere in the streaming branch, the wrap helper is invoked
    // on `claudeStreamResponse.body`, and its return value flows into a
    // `new Response(...)` builder. We accept either inline-call form
    // (`new Response(wrapAnthropic...())`) or via-named-binding form
    // (`const wrappedBody = wrapAnthropic...(); new Response(wrappedBody)`).
    const inlineForm =
      /new\s+Response\s*\(\s*wrapAnthropicStreamWithCitations\s*\(/.test(source);
    const namedForm =
      /wrapAnthropicStreamWithCitations\s*\(\s*claudeStreamResponse\.body/.test(
        source,
      );
    if (!inlineForm && !namedForm) {
      throw new Error(
        "Streaming branch must wrap the upstream body with " +
          "wrapAnthropicStreamWithCitations before returning the Response.",
      );
    }
    // Make sure the streaming branch DOESN'T also keep the old raw-body
    // pass-through (a refactor that adds the wrap but forgets to remove
    // the old return is the realistic regression we're guarding).
    const rawPassthrough =
      /new\s+Response\s*\(\s*claudeStreamResponse\.body\s*,/.test(source);
    if (rawPassthrough) {
      throw new Error(
        "Streaming branch still has a raw `new Response(claudeStreamResponse.body, ...)` " +
          "path — Pkg 2 closeout requires the wrap. Remove the legacy return.",
      );
    }
  },
);
