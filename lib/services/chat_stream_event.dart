// =============================================================================
// chat_stream_event.dart — typed SSE events for the chat streaming pipeline.
// =============================================================================
//
// Reasoning Trail v1 (2026-05-05): the streaming chat pipe used to yield raw
// `String` chunks. The Anthropic SSE protocol carries far more than text —
// `thinking_delta`, `tool_use`, `tool_result`, `signature_delta`, `input_json_delta`
// — and the chat UI's "Reasoning Trail" pill needs all of those to surface
// what the model is actually doing.
//
// Surface contract:
//   • Sealed class hierarchy below covers every event type the UI cares about.
//   • Old text-only call sites get a `Stream<ChatStreamEvent>.toTextStream()`
//     extension that filters down to TextDelta.text — backwards compatible.
//   • Voice tag scrubbing still happens upstream of this layer (in
//     ai_service.dart::sendChatMessageStreaming) since the scrubber operates
//     on raw text deltas.
// =============================================================================

import 'dart:async';

/// Sealed base for all events that flow through the chat streaming pipeline.
///
/// Use exhaustive `switch` on subtypes for compile-time safety:
///
/// ```dart
/// stream.listen((event) => switch (event) {
///   TextDelta(:final text) => append(text),
///   ToolUseStart(:final name) => trail.startTool(name),
///   ThinkingDelta(:final text) => trail.thinking(text),
///   _ => null,
/// });
/// ```
sealed class ChatStreamEvent {
  const ChatStreamEvent();
}

/// Plain text delta. Carries the same payload the legacy `Stream<String>`
/// yielded — every text chunk arrives as one of these.
final class TextDelta extends ChatStreamEvent {
  const TextDelta(this.text);
  final String text;

  @override
  String toString() => 'TextDelta(${_preview(text)})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TextDelta && other.text == text;

  @override
  int get hashCode => text.hashCode;
}

/// A `thinking` content block has started. Anthropic's extended-thinking
/// surface emits these between message_start and content_block_delta blocks
/// of type=thinking_delta.
final class ThinkingStart extends ChatStreamEvent {
  const ThinkingStart();

  @override
  String toString() => 'ThinkingStart()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ThinkingStart;

  @override
  int get hashCode => 0x7e1;
}

/// A delta of summarized reasoning content. With `display: "summarized"` the
/// API returns short, sanitized stages — not verbatim chain of thought.
/// We use first-sentence-of-text to drive the rotating pill caption.
final class ThinkingDelta extends ChatStreamEvent {
  const ThinkingDelta(this.text);
  final String text;

  @override
  String toString() => 'ThinkingDelta(${_preview(text)})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ThinkingDelta && other.text == text;

  @override
  int get hashCode => text.hashCode ^ 0x7e2;
}

/// The thinking block has closed. `signature` is the cryptographic seal that
/// must be echoed verbatim into the next assistant turn for budget continuity
/// — see Anthropic interleaved-thinking docs.
final class ThinkingStop extends ChatStreamEvent {
  const ThinkingStop({this.signature});
  final String? signature;

  @override
  String toString() =>
      'ThinkingStop(sig=${signature == null ? 'null' : '<${signature!.length}b>'})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThinkingStop && other.signature == signature;

  @override
  int get hashCode => (signature ?? '').hashCode ^ 0x7e3;
}

/// A `tool_use` content block has started. `name` is the tool's logical
/// name (matches `tool_definitions.dart`); `id` is the toolUseId Anthropic
/// will reference in the corresponding tool_result.
final class ToolUseStart extends ChatStreamEvent {
  const ToolUseStart(this.name, this.id);
  final String name;
  final String id;

  @override
  String toString() => 'ToolUseStart($name, id=$id)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToolUseStart && other.name == name && other.id == id;

  @override
  int get hashCode => Object.hash(name, id);
}

/// Partial JSON for a tool's input arguments. May arrive in many small
/// fragments. Parse client-side if you need it; the trail just shows that
/// the tool *is* being prepared.
final class ToolInputDelta extends ChatStreamEvent {
  const ToolInputDelta(this.partialJson);
  final String partialJson;

  @override
  String toString() => 'ToolInputDelta(${_preview(partialJson)})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToolInputDelta && other.partialJson == partialJson;

  @override
  int get hashCode => partialJson.hashCode ^ 0x7e4;
}

/// The current tool_use content block has closed. Trail can flip the
/// pill to "preparing" → "running" or just leave it on the running caption
/// until ToolResultReceived lands.
final class ToolUseStop extends ChatStreamEvent {
  const ToolUseStop();

  @override
  String toString() => 'ToolUseStop()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ToolUseStop;

  @override
  int get hashCode => 0x7e5;
}

/// The local tool dispatch returned. `result` is the tool's payload (cards,
/// JSON, etc.). The Trail uses this to flip the pill to a checkmark with
/// the result snippet.
///
/// Note: Anthropic's *server-side* tools (web_search) emit
/// `web_search_tool_result` blocks inline. Those are also surfaced here for
/// uniformity; the UI doesn't need to distinguish.
final class ToolResultReceived extends ChatStreamEvent {
  const ToolResultReceived(this.result);
  final Map<String, dynamic> result;

  @override
  String toString() => 'ToolResultReceived(keys=${result.keys.toList()})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToolResultReceived && _mapEquals(other.result, result);

  @override
  int get hashCode => Object.hashAll(result.entries.map((e) => Object.hash(e.key, e.value)));
}

/// Terminal event — the message_stop SSE arrived. `thinkingMs` is the wall
/// clock spent in thinking blocks (best effort, may be null on legacy
/// streams). `sources` is the count of tool_use blocks observed in the turn.
final class MessageDone extends ChatStreamEvent {
  const MessageDone({this.thinkingMs, this.sources});
  final int? thinkingMs;
  final int? sources;

  @override
  String toString() => 'MessageDone(thinkingMs=$thinkingMs, sources=$sources)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageDone &&
          other.thinkingMs == thinkingMs &&
          other.sources == sources;

  @override
  int get hashCode => Object.hash(thinkingMs, sources);
}

// ---------------------------------------------------------------------------
// Backwards-compat shim
// ---------------------------------------------------------------------------

/// Filters a `Stream<ChatStreamEvent>` down to its raw text content — the
/// legacy `Stream<String>` shape. Used by call sites that pre-date the
/// reasoning surface and only ever want plain text.
extension ChatStreamEventTextExt on Stream<ChatStreamEvent> {
  Stream<String> toTextStream() async* {
    await for (final event in this) {
      if (event is TextDelta) {
        if (event.text.isNotEmpty) yield event.text;
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Internal helpers (private — only used by toString())
// ---------------------------------------------------------------------------

String _preview(String s) {
  if (s.length <= 32) return '"$s"';
  return '"${s.substring(0, 29)}…"';
}

bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final k in a.keys) {
    if (!b.containsKey(k)) return false;
    if (a[k] != b[k]) return false;
  }
  return true;
}
