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

/// Trailing citations frame — emitted by the Pkg 2 streaming wrap on
/// claude-proxy. Anthropic itself never emits this; it's a custom SSE
/// event injected by the proxy AFTER message_stop, carrying the verifier
/// output for the just-completed assistant message.
///
/// Frame format on the wire:
///   event: citations
///   data: {"citations": [...], "message_id": "uuid-or-null"}
///   <blank line>
///
/// `messageId` is non-null only when the caller opted in to server-side
/// persistence by passing body.message_id; for fire-and-forget streaming
/// (no persistence), the field is null and the chat UI can still render
/// chips against the in-memory message identity.
///
/// `rawCitations` is the verifier payload as a list of JSON maps so the
/// chat layer can deserialise into its own MessageCitation model without
/// this layer needing to import that model. Order matches verifier
/// first-occurrence order.
final class CitationsReceived extends ChatStreamEvent {
  const CitationsReceived({required this.rawCitations, this.messageId});
  final List<Map<String, dynamic>> rawCitations;
  final String? messageId;

  @override
  String toString() =>
      'CitationsReceived(n=${rawCitations.length}, messageId=$messageId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CitationsReceived &&
          other.messageId == messageId &&
          _listOfMapsEquals(other.rawCitations, rawCitations);

  @override
  int get hashCode =>
      Object.hash(messageId, rawCitations.length);
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
// Consilium v1 events (Phase 1, 2026-05-25)
// ---------------------------------------------------------------------------
//
// The lawyer_router multi-role consilium emits a richer SSE flow than a
// single Anthropic stream: it announces a panel of roles up front, streams
// each role's opinion, surfaces adversarial cross-examination in round 2,
// and synthesises a final answer. The events below mirror what
// consilium_v3.ts / consilium.ts emit on the wire so the chat UI can render
// per-role cards, attack callouts, and round progress without re-parsing.
// =============================================================================

/// Lightweight descriptor of one participating role at consilium kickoff.
final class ConsiliumRoleInfo {
  const ConsiliumRoleInfo({required this.id, required this.name});
  final String id;
  final String name;

  @override
  String toString() => 'ConsiliumRoleInfo($id, $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConsiliumRoleInfo && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

/// The consilium has started. Carries the full panel of roles so the UI can
/// render placeholder cards before opinions stream in.
final class ConsiliumStart extends ChatStreamEvent {
  const ConsiliumStart({required this.roles, required this.total});
  final List<ConsiliumRoleInfo> roles;
  final int total;

  @override
  String toString() => 'ConsiliumStart(total=$total, roles=${roles.length})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ConsiliumStart) return false;
    if (other.total != total) return false;
    if (other.roles.length != roles.length) return false;
    for (var i = 0; i < roles.length; i++) {
      if (other.roles[i] != roles[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(total, Object.hashAll(roles));
}

/// One role's opinion arrived — round 1 (independent), round 2 (post-attack
/// revision), or round 3 (final defense). Free-form `opinion` is the role's
/// answer; the other fields are structured metadata for chips/badges.
final class RoleOpinion extends ChatStreamEvent {
  const RoleOpinion({
    required this.roleId,
    required this.roleName,
    required this.opinion,
    this.position,
    this.confidence,
    this.keyCitation,
  });
  final String roleId;
  final String roleName;
  final String opinion;
  final String? position;
  final double? confidence;
  final String? keyCitation;

  @override
  String toString() =>
      'RoleOpinion($roleId/$roleName, pos=$position, conf=$confidence)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoleOpinion &&
          other.roleId == roleId &&
          other.roleName == roleName &&
          other.opinion == opinion &&
          other.position == position &&
          other.confidence == confidence &&
          other.keyCitation == keyCitation;

  @override
  int get hashCode =>
      Object.hash(roleId, roleName, opinion, position, confidence, keyCitation);
}

/// Round 2 adversarial cross-examination — one role attacks another's weak
/// point with counter-evidence. Also re-used for round 3 defenses (in which
/// case attacker/target are swapped to reflect the rebuttal direction).
final class AdversarialAttack extends ChatStreamEvent {
  const AdversarialAttack({
    required this.attacker,
    required this.targetRole,
    required this.weakPoint,
    required this.counterEvidence,
  });
  final String attacker;
  final String targetRole;
  final String weakPoint;
  final String counterEvidence;

  @override
  String toString() =>
      'AdversarialAttack($attacker → $targetRole, weakPoint=${_preview(weakPoint)})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdversarialAttack &&
          other.attacker == attacker &&
          other.targetRole == targetRole &&
          other.weakPoint == weakPoint &&
          other.counterEvidence == counterEvidence;

  @override
  int get hashCode =>
      Object.hash(attacker, targetRole, weakPoint, counterEvidence);
}

/// A consilium round (1=independent, 2=attack, 3=defense) finished. UI can
/// use this to drive round-progress indicators.
final class RoundDone extends ChatStreamEvent {
  const RoundDone({required this.round});
  final int round;

  @override
  String toString() => 'RoundDone(round=$round)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RoundDone && other.round == round;

  @override
  int get hashCode => round.hashCode ^ 0x7e6;
}

/// Synthesis phase started — the orchestrator is now merging role opinions
/// into a single final answer. Plain TextDelta events follow until done.
final class ConsiliumSynthesisStart extends ChatStreamEvent {
  const ConsiliumSynthesisStart();

  @override
  String toString() => 'ConsiliumSynthesisStart()';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ConsiliumSynthesisStart;

  @override
  int get hashCode => 0x7e7;
}

/// The consilium has fully concluded — synthesis emitted. The MessageDone
/// event (from the underlying SSE) still fires for token usage; this one is
/// a logical-layer terminator the UI uses to seal per-role cards.
final class ConsiliumDone extends ChatStreamEvent {
  const ConsiliumDone({this.disagreementDetected = false, this.totalRoles = 0});
  final bool disagreementDetected;
  final int totalRoles;

  @override
  String toString() =>
      'ConsiliumDone(disagreement=$disagreementDetected, roles=$totalRoles)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConsiliumDone &&
          other.disagreementDetected == disagreementDetected &&
          other.totalRoles == totalRoles;

  @override
  int get hashCode => Object.hash(disagreementDetected, totalRoles);
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

bool _listOfMapsEquals(
  List<Map<String, dynamic>> a,
  List<Map<String, dynamic>> b,
) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!_mapEquals(a[i], b[i])) return false;
  }
  return true;
}
