// =============================================================================
// reasoning_caption_mapper.dart — pure ChatStreamEvent → caption string mapper.
// =============================================================================
//
// Reasoning Trail v1 (2026-05-05). Drives the rotating one-line caption in the
// 32px pill above the streaming answer. Pure function so it's trivially
// unit-tested — no Flutter widgets, no state.
//
// Rules:
//   • Tool name → l10n key. Each tool gets its own user-facing verb form
//     (e.g. search_estonian_law → "Searching Estonian law…").
//   • Unknown tool → fall back to generic "Thinking through your case…".
//   • ThinkingDelta → first sentence of the SUMMARIZED text, max 60 chars.
//     We never render verbatim chain-of-thought — Anthropic's
//     `display: "summarized"` mode is required for the `thinking` block.
//     If the delta is empty / whitespace-only → fall back to generic key.
//   • All other events return null → caller keeps the previous caption.
// =============================================================================

import 'package:advocat/l10n/app_localizations.dart';

import '../../../services/chat_stream_event.dart';

/// Maximum displayable length for a thinking-derived caption.
/// 60 chars fits the 32px pill at default font without ellipsis truncation.
const int _kThinkingCaptionMaxLen = 60;

/// Compute the next caption string for a given [event]. Returns null when the
/// event carries no caption signal — in that case the UI keeps the previous
/// caption (don't rotate to idle just because a non-caption event arrived).
///
/// [toolName] is required only when [event] is a [ToolUseStart]; the caller
/// passes the tool name from the event itself. Future tool events
/// ([ToolInputDelta], [ToolUseStop]) leave the caption alone — the pill
/// continues showing "Searching Estonian law…" while the tool runs.
String? captionForEvent(
  ChatStreamEvent event,
  AppLocalizations l10n, {
  String? toolName,
}) {
  return switch (event) {
    ThinkingStart() => l10n.reasoningPillThinking,
    ThinkingDelta(:final text) => _captionFromThinkingText(text, l10n),
    ToolUseStart(:final name) => _captionForTool(name, l10n),
    ToolResultReceived() => l10n.reasoningPillFinalising,
    MessageDone() => l10n.reasoningPillFinalising,
    _ => null,
  };
}

/// Map a tool's logical name (matches `tool_definitions.dart`) to its
/// localized "user verb" caption. Unknown tools → generic thinking caption.
String _captionForTool(String name, AppLocalizations l10n) {
  switch (name) {
    case 'search_estonian_law':
    case 'search_finnish_law':
    case 'search_knowledge':
      return l10n.reasoningPillSearchingLaw;
    case 'web_search':
      return l10n.reasoningPillSearchingWeb;
    case 'check_company':
      return l10n.reasoningPillCheckingCompany;
    case 'check_vehicle':
      return l10n.reasoningPillCheckingVehicle;
    case 'analyze_document':
    case 'analyze_contract':
    case 'read_document':
    case 'list_documents':
      return l10n.reasoningPillReadingDocument;
    case 'generate_draft':
      return l10n.reasoningPillDrafting;
    case 'send_email':
    case 'draft_email':
      return l10n.reasoningPillPreparingEmail;
    case 'find_lawyer':
      return l10n.reasoningPillFindingLawyer;
    default:
      // Unknown tool — fall back to a safe generic caption rather than
      // exposing the raw tool name (which is an internal API detail).
      return l10n.reasoningPillThinking;
  }
}

/// First sentence of [text], capped at [_kThinkingCaptionMaxLen] chars.
/// Sanitises whitespace and falls back to the generic thinking caption when
/// the input is empty / whitespace-only after trimming.
String _captionFromThinkingText(String text, AppLocalizations l10n) {
  // Collapse all whitespace runs (incl. newlines) to a single space,
  // then trim leading/trailing whitespace.
  final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (cleaned.isEmpty) return l10n.reasoningPillThinking;

  // First sentence — split on the first . / ! / ? followed by space or EOS.
  // We keep the punctuation off (cleaner pill) and strip trailing punctuation.
  final match = RegExp(r'^([^.!?]+)([.!?])').firstMatch(cleaned);
  String first = match != null ? match.group(1)!.trim() : cleaned;

  // Cap at MAX_LEN. If the cap forces truncation, end on a word boundary
  // when one exists in the last 12 chars.
  if (first.length > _kThinkingCaptionMaxLen) {
    final cap = first.substring(0, _kThinkingCaptionMaxLen);
    final lastSpace = cap.lastIndexOf(' ');
    first = (lastSpace >= _kThinkingCaptionMaxLen - 12)
        ? '${cap.substring(0, lastSpace)}…'
        : '$cap…';
  }

  return first;
}
