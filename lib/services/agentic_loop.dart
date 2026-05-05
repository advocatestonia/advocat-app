// =============================================================================
// agentic_loop.dart — Smart Agent v2: real `tool_result` agentic loop.
// =============================================================================
//
// The legacy chat path was single-shot: send → if tool_use, return early →
// chat_screen.dart builds a fake user follow-up "I just ran a tool…" and
// calls Claude AGAIN as a fresh turn. Anthropic NEVER saw a real
// tool_result block paired with tool_use_id. That broke tool chaining,
// self-correction, and any future interleaved thinking.
//
// This module implements the canonical Anthropic agentic loop:
//
//   for i in 0..maxIterations:
//     response = claude.send(messages, tools)
//     if response.stop_reason == 'end_turn'     → break, return text
//     if response.stop_reason == 'tool_use':
//       messages += {role:'assistant', content: response.content}  // raw
//       executions = exec(response.tool_use_blocks)
//       messages += {role:'user', content: [tool_result, ...]}
//       continue
//   else: cap-graceful "I tried multiple steps…" termination
//
// CRITICAL invariants enforced by this module:
//
//   • Tool errors propagate with `is_error: true` AND the error string in
//     `content`. Claude can read its own tool failure and self-correct on
//     the next iteration.
//   • Write tools (anything in [AssistantTools.requiresApproval]) are NOT
//     auto-executed inside the loop. The loop yields control back to the
//     caller with `LoopOutcome.requiresApproval`, who routes the tool_use
//     through the existing UI approval flow.
//   • Iteration cap is 5; on reaching the cap we emit a graceful message
//     and stop rather than spinning further or throwing.
//   • Every tool call is captured in [LoopOutcome.toolCalls] for downstream
//     verification (Citation Verifier reads this list).
//
// The loop is decoupled from `ai_service.dart` so it can be exercised by
// pure unit tests with fake Claude + fake tool executor.
// =============================================================================

import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'assistant_tools.dart';
import 'citation_verifier.dart';

/// Maximum agentic-loop iterations before we stop and return a graceful
/// "I tried multiple steps but didn't reach a clean answer" message.
/// Owner-set: 5 (consilium synthesis 2026-05-05).
const int kMaxAgenticIterations = 5;

/// Function signature: send a single Claude API turn.
///
/// `messages` is the conversation in Anthropic's exact wire format —
/// each entry is `{role, content}` where `content` may be either a String
/// or a List of typed content blocks (`text`, `tool_use`, `tool_result`).
typedef ClaudeSendFn = Future<Map<String, dynamic>> Function(
  List<Map<String, dynamic>> messages,
);

/// Function signature: execute a single tool. Returns the [ToolResult]
/// the tool produced. Errors thrown here are captured by the loop and
/// turned into `is_error: true` tool_result blocks.
typedef ToolExecFn = Future<ToolResult> Function(
  String toolName,
  Map<String, dynamic> input,
);

/// Predicate: does this tool require user approval?  Defaults to the
/// production [AssistantTools.requiresApproval] set; tests can inject
/// their own predicate for isolation.
typedef RequiresApprovalFn = bool Function(String toolName);

/// One tool invocation captured by the loop, for the [CitationVerifier]
/// and any downstream analytics.
@immutable
class LoopToolCall {
  const LoopToolCall({
    required this.id,
    required this.name,
    required this.input,
    required this.isError,
  });

  final String id;
  final String name;
  final Map<String, dynamic> input;
  final bool isError;

  CitationToolCall toCitationToolCall() =>
      CitationToolCall(name: name, input: input);
}

/// Why the loop stopped.
enum LoopStopReason {
  /// Claude returned an `end_turn` stop_reason — the answer is in [LoopOutcome.text].
  endTurn,

  /// A write-tool was requested. The caller must run the existing approval
  /// flow on [LoopOutcome.pendingApprovalResponse].
  requiresApproval,

  /// Loop hit [kMaxAgenticIterations]. [LoopOutcome.text] carries a
  /// graceful "tried multiple steps" message.
  maxIterations,

  /// Claude returned an unexpected stop_reason (e.g. `max_tokens`). We
  /// pass through whatever text we have plus an explanatory note.
  other,
}

/// Final outcome of one [runAgenticLoop] invocation.
@immutable
class LoopOutcome {
  const LoopOutcome({
    required this.text,
    required this.stopReason,
    required this.iterations,
    required this.toolCalls,
    this.pendingApprovalResponse,
  });

  /// Text to show the user. Already verified for citations.
  final String text;

  /// Why the loop stopped.
  final LoopStopReason stopReason;

  /// Number of iterations executed (1 = single Claude call, no tools).
  final int iterations;

  /// Every tool call observed in this turn. Used by citation verifier.
  final List<LoopToolCall> toolCalls;

  /// When [stopReason] is [LoopStopReason.requiresApproval], this carries
  /// the raw Claude response that triggered the pause — caller passes it
  /// to [ChatToolBridge.executeToolCalls] to render approval UI.
  final Map<String, dynamic>? pendingApprovalResponse;
}

/// Run the agentic loop. See file header for invariants.
///
/// [send] performs one Claude turn given the running message list.
/// [executeTool] runs one local tool. [requiresApproval] decides whether a
/// tool should pause the loop for UI approval (defaults to the production
/// AssistantTools predicate).
///
/// On approval-pause, the partial conversation up to (but not including)
/// the requested tool call is preserved in [LoopOutcome.text] / tool_calls
/// so the UI can render any prior text and tool cards.
///
/// All exceptions thrown by [send] propagate to the caller — quota /
/// rate-limit / overload handling stays where it is in `ai_service.dart`.
Future<LoopOutcome> runAgenticLoop({
  required List<Map<String, dynamic>> initialMessages,
  required ClaudeSendFn send,
  required ToolExecFn executeTool,
  RequiresApprovalFn? requiresApproval,
  int maxIterations = kMaxAgenticIterations,
}) async {
  // Defensive copy — we mutate the working list across iterations and
  // don't want to surprise the caller's owned list.
  final messages = <Map<String, dynamic>>[
    for (final m in initialMessages) Map<String, dynamic>.from(m),
  ];
  final approvalCheck = requiresApproval ?? AssistantTools.requiresApproval.contains;

  final allToolCalls = <LoopToolCall>[];
  final accumulatedText = StringBuffer();

  for (var i = 0; i < maxIterations; i++) {
    final response = await send(messages);

    final content = (response['content'] as List<dynamic>?) ?? const [];
    final stopReason = response['stop_reason'] as String?;

    // Append any text deltas to the accumulator. Useful for partial
    // termination: even on max-iterations we can return what we did say.
    final turnText = _extractText(content);
    if (turnText.isNotEmpty) {
      if (accumulatedText.isNotEmpty) accumulatedText.write('\n\n');
      accumulatedText.write(turnText);
    }

    // ── End-turn → done ──────────────────────────────────────────────
    if (stopReason == 'end_turn' || stopReason == null) {
      return LoopOutcome(
        text: accumulatedText.toString(),
        stopReason: LoopStopReason.endTurn,
        iterations: i + 1,
        toolCalls: allToolCalls,
      );
    }

    // ── Tool use → execute and loop ─────────────────────────────────
    if (stopReason == 'tool_use') {
      final toolUseBlocks = content
          .where((b) => (b as Map<String, dynamic>)['type'] == 'tool_use')
          .map((b) => b as Map<String, dynamic>)
          .toList();

      if (toolUseBlocks.isEmpty) {
        // Defensive: API claimed tool_use but no blocks found. Bail.
        return LoopOutcome(
          text: accumulatedText.toString(),
          stopReason: LoopStopReason.other,
          iterations: i + 1,
          toolCalls: allToolCalls,
        );
      }

      // Write-tool guard: if ANY tool requires approval, stop the loop
      // here and hand off to the caller. We do NOT auto-execute writes.
      // The other tools in this same response will be handled when the
      // user's approval flow re-enters the chat path.
      final firstWriteTool = toolUseBlocks.firstWhere(
        (b) => approvalCheck((b['name'] as String?) ?? ''),
        orElse: () => const {},
      );
      if (firstWriteTool.isNotEmpty) {
        return LoopOutcome(
          text: accumulatedText.toString(),
          stopReason: LoopStopReason.requiresApproval,
          iterations: i + 1,
          toolCalls: allToolCalls,
          pendingApprovalResponse: response,
        );
      }

      // Append the assistant turn (raw blocks) so Anthropic sees its
      // own tool_use IDs on the next turn.
      messages.add({'role': 'assistant', 'content': content});

      // Execute every tool in the turn, building tool_result blocks.
      final toolResultBlocks = <Map<String, dynamic>>[];
      for (final block in toolUseBlocks) {
        final id = (block['id'] as String?) ?? '';
        final name = (block['name'] as String?) ?? '';
        final input =
            (block['input'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

        ToolResult? result;
        Object? thrown;
        try {
          result = await executeTool(name, input);
        } catch (e) {
          thrown = e;
        }

        final isError = thrown != null || (result?.success == false);
        allToolCalls.add(LoopToolCall(
          id: id,
          name: name,
          input: input,
          isError: isError,
        ));

        // Build the tool_result content. Anthropic accepts either a
        // string or a list of blocks — we use a string for simplicity.
        final String resultContent;
        if (thrown != null) {
          resultContent =
              'Tool execution failed: $thrown. Try a different approach or '
              'tell the user the tool is unavailable right now.';
        } else if (result == null) {
          resultContent = 'Tool returned no result.';
        } else {
          resultContent = jsonEncode(result.toJson());
        }

        toolResultBlocks.add({
          'type': 'tool_result',
          'tool_use_id': id,
          if (isError) 'is_error': true,
          'content': resultContent,
        });
      }

      // Append the user turn carrying all tool_result blocks. Continue
      // to the next iteration — Claude reads its own results and either
      // chains another tool or composes the final answer.
      messages.add({'role': 'user', 'content': toolResultBlocks});
      continue;
    }

    // ── Unknown stop_reason — bail out gracefully ───────────────────
    return LoopOutcome(
      text: accumulatedText.toString(),
      stopReason: LoopStopReason.other,
      iterations: i + 1,
      toolCalls: allToolCalls,
    );
  }

  // ── Iteration cap reached ──────────────────────────────────────────
  // Fall through: emit a graceful note appended to whatever we did say.
  if (accumulatedText.isNotEmpty) accumulatedText.write('\n\n');
  accumulatedText.write(_maxIterationsMessage());
  return LoopOutcome(
    text: accumulatedText.toString(),
    stopReason: LoopStopReason.maxIterations,
    iterations: maxIterations,
    toolCalls: allToolCalls,
  );
}

/// Extract concatenated text from a content-blocks list.
String _extractText(List<dynamic> content) {
  final buf = StringBuffer();
  for (final block in content) {
    final m = block as Map<String, dynamic>;
    if (m['type'] == 'text') {
      final t = m['text'] as String? ?? '';
      if (t.isNotEmpty) {
        if (buf.isNotEmpty) buf.write('\n');
        buf.write(t);
      }
    }
  }
  return buf.toString();
}

/// Graceful termination message used on iteration-cap exit.
/// Owner-set wording (see consilium synthesis 2026-05-05).
String _maxIterationsMessage() =>
    "I tried multiple steps but didn't reach a clean answer. "
    'Want me to try a different approach?';

/// Visible-for-testing accessor to the cap message.
@visibleForTesting
String maxIterationsMessageForTest() => _maxIterationsMessage();
