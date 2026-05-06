// streaming_citations.ts — Phase 2 Pkg 2 closeout (streaming branch verifier).
// -----------------------------------------------------------------------------
// Wraps the Anthropic SSE pipe with a TransformStream that:
//   1. Forwards every byte from upstream UNCHANGED to the client.
//   2. Accumulates the assistant's reply text from `content_block_delta`
//      events of type `text_delta` as they fly past.
//   3. On `message_stop`, runs the grounding verifier on the accumulated
//      text and APPENDS a final SSE event:
//        event: citations
//        data: {"citations": [...], "message_id": "..."}
//
// Why a TransformStream instead of a "consume + replay" approach: Anthropic
// streams can run 30-90s for Sonnet replies. The Flutter UI is rendering
// text deltas live for the full 30-90s — we MUST keep the stream open and
// pass-through. Buffering up the whole stream and replaying after the
// verifier ran would freeze the UI for the full Anthropic latency.
//
// Spec: docs/architecture/phase2-pkg2-citations.md §9 risk #2 (verifier
// latency on long replies — explicitly calls out the streaming-mode hazard:
// "if anyone changes the proxy to streaming mode (Anthropic SSE), verifier
// needs to run on the post-stream concat, NOT per-event").
//
// Pure module — no Supabase, no Deno globals beyond Web Streams + TextDecoder.
// -----------------------------------------------------------------------------

import {
  type Citation,
  type GroundingChunk,
  verifyCitations,
} from "../_shared/citation_grounder.ts";

/** Result envelope used internally by tests; the live wiring writes
 *  these straight to the SSE pipe via formatCitationsSseEvent. */
export interface StreamCitationsResult {
  citations: Citation[];
  message_id: string | null;
  /** The full assistant text we reconstructed from content_block_delta
   *  events. Exposed so tests can pin the accumulator behaviour. */
  assembledText: string;
}

/**
 * Reduce one parsed Anthropic SSE event JSON into the running accumulator.
 *
 * Anthropic event model (in stream order):
 *   • message_start                   — sets up message metadata
 *   • content_block_start             — opens a text/thinking/tool block
 *   • content_block_delta             — incremental delta for that block
 *       - delta.type === 'text_delta'  carries .text (one chunk of reply)
 *       - delta.type === 'thinking_delta' / 'input_json_delta' / etc. — IGNORE
 *   • content_block_stop              — closes a block
 *   • message_delta                   — final usage etc.
 *   • message_stop                    — terminal sentinel
 *
 * Only `text_delta` contributes to the verifier input. Thinking deltas
 * NEVER carry markers (the model is instructed to put markers in the
 * user-visible reply, not in the chain-of-thought summary), and tool_use
 * blocks are JSON inputs, not prose.
 */
export function accumulateTextFromSseEvent(
  parsed: unknown,
  buffer: { text: string },
): void {
  if (!parsed || typeof parsed !== "object") return;
  const obj = parsed as Record<string, unknown>;
  if (obj.type !== "content_block_delta") return;
  const delta = obj.delta;
  if (!delta || typeof delta !== "object") return;
  const deltaObj = delta as Record<string, unknown>;
  if (deltaObj.type !== "text_delta") return;
  const text = deltaObj.text;
  if (typeof text !== "string") return;
  buffer.text += text;
}

/**
 * Format the verifier output as one SSE event frame, following the
 * `event: <name>\ndata: <json>\n\n` shape Anthropic itself uses for
 * everything else on the same pipe.
 *
 * Custom event name: `citations`. Anthropic does not emit anything by
 * that name, so the Flutter client's SSE parser can route it deterministically.
 *
 * The trailing empty line (`\n\n`) is REQUIRED by the SSE protocol —
 * without it, browsers buffer the event indefinitely waiting for the
 * frame terminator.
 */
export function formatCitationsSseEvent(
  result: { citations: Citation[]; message_id: string | null },
): string {
  // JSON.stringify is tolerant of nulls and unicode; the citation snippets
  // are already truncated upstream by the verifier. We do NOT need to
  // base64 / escape the data field — SSE only requires we avoid raw
  // newlines in the data line.
  const json = JSON.stringify(result);
  // Defensive: collapse any \r\n to \n (Anthropic doesn't emit \r, but
  // Windows-routed proxies sometimes do). Then the SSE rule is "data
  // line ends at \n" — we ship the whole JSON as one data line.
  const safeJson = json.replace(/\r/g, "");
  return `event: citations\ndata: ${safeJson}\n\n`;
}

/**
 * Best-effort SSE line parser. Anthropic frames are
 *   data: {...json...}\n
 * (with `event: <name>` lines preceding some, and blank lines as frame
 * terminators). We only care about the `data:` lines — every payload
 * we want to accumulate is in one of those.
 *
 * Returns the parsed JSON or null if the line wasn't a JSON `data:` line.
 */
export function parseSseDataLine(line: string): unknown {
  if (!line.startsWith("data:")) return null;
  const payload = line.slice(5).trim();
  if (!payload) return null;
  try {
    return JSON.parse(payload);
  } catch {
    return null;
  }
}

/**
 * Run the verifier against accumulated text + the rag chunks for the
 * turn. Tolerant: empty input → empty output.
 */
export function verifyStreamedReply(
  assembledText: string,
  ragChunks: ReadonlyArray<GroundingChunk>,
): Citation[] {
  return verifyCitations(assembledText, ragChunks);
}

/**
 * Wrap an upstream SSE ReadableStream<Uint8Array> from Anthropic so that:
 *   • Every byte from upstream is forwarded UNCHANGED to the downstream
 *     consumer.
 *   • A line-buffered shadow parser accumulates `text_delta` events into
 *     `assembled.text`.
 *   • When upstream closes (message_stop is the canonical terminal but we
 *     also handle premature close), we run the verifier and emit ONE
 *     additional SSE event: `event: citations\ndata: {...}\n\n`.
 *
 * The transform never modifies in-flight bytes, so per-event latency is
 * unchanged — the Flutter UI keeps rendering deltas at the same pace.
 *
 * `messageId` may be null when the caller did not opt in to persistence
 * (no body.message_id); the citations event is still emitted (so chips
 * render), just without a server-side row reference.
 *
 * Returns a new ReadableStream<Uint8Array> for `new Response(stream, ...)`.
 */
export function wrapAnthropicStreamWithCitations(
  upstream: ReadableStream<Uint8Array>,
  opts: {
    ragChunks: ReadonlyArray<GroundingChunk>;
    messageId: string | null;
    /** Persistence hook — invoked AFTER the verifier runs, BEFORE the
     *  citations SSE event is emitted. Best-effort; errors swallowed. */
    onCitations?: (citations: Citation[]) => Promise<void> | void;
  },
): ReadableStream<Uint8Array> {
  const decoder = new TextDecoder();
  const encoder = new TextEncoder();
  const assembled = { text: "" };
  // Line buffer for the shadow parser. Anthropic's SSE frames are split
  // by `\n\n` and each frame has an `event: ...` line + a `data: ...` line.
  // We split on `\n` and parse data: lines as we see them.
  let lineBuffer = "";

  const reader = upstream.getReader();

  return new ReadableStream<Uint8Array>({
    async pull(controller) {
      try {
        const { done, value } = await reader.read();
        if (done) {
          // Stream closed — flush any trailing partial line, then emit
          // the citations frame and close downstream.
          if (lineBuffer.length > 0) {
            const parsed = parseSseDataLine(lineBuffer);
            if (parsed !== null) {
              accumulateTextFromSseEvent(parsed, assembled);
            }
            lineBuffer = "";
          }
          let citations: Citation[] = [];
          try {
            citations = verifyStreamedReply(assembled.text, opts.ragChunks);
          } catch (e) {
            console.warn(
              `claude-proxy stream: verifyStreamedReply threw, ` +
                `emitting empty citations: ${String(e).slice(0, 200)}`,
            );
          }
          if (opts.onCitations && citations.length > 0) {
            try {
              await opts.onCitations(citations);
            } catch (e) {
              console.warn(
                `claude-proxy stream: onCitations threw (ignored): ${
                  String(e).slice(0, 200)
                }`,
              );
            }
          }
          const frame = formatCitationsSseEvent({
            citations,
            message_id: opts.messageId,
          });
          controller.enqueue(encoder.encode(frame));
          controller.close();
          return;
        }
        // Forward UNCHANGED to downstream first — this is the hot path.
        controller.enqueue(value);
        // Then update the shadow parser with the same bytes.
        lineBuffer += decoder.decode(value, { stream: true });
        // Drain whole lines from the buffer.
        let idx = lineBuffer.indexOf("\n");
        while (idx !== -1) {
          const line = lineBuffer.slice(0, idx).trimEnd();
          lineBuffer = lineBuffer.slice(idx + 1);
          if (line) {
            const parsed = parseSseDataLine(line);
            if (parsed !== null) {
              accumulateTextFromSseEvent(parsed, assembled);
            }
          }
          idx = lineBuffer.indexOf("\n");
        }
      } catch (e) {
        // Any read error: try to release the reader and surface to
        // the consumer. The citations event won't be emitted in this
        // path — the client's SSE handler should already be catching
        // truncation via message_stop absence.
        console.warn(
          `claude-proxy stream wrap pull error: ${String(e).slice(0, 200)}`,
        );
        try {
          reader.releaseLock();
        } catch (_) {/* noop */}
        controller.error(e);
      }
    },
    async cancel(reason) {
      try {
        await reader.cancel(reason);
      } catch (_) {/* noop */}
    },
  });
}
