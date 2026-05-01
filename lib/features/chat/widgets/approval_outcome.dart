// approval_outcome.dart
// -----------------------------------------------------------------------------
// BUG#4 fix (2026-04-29 pre-launch). Structured outcome for tool-approval
// modal events.
//
// Why.
//   Anthropic's Messages API requires a tool_result for every preceding
//   tool_use block. The legacy chat_screen path emitted a free-text
//   "[system] Cancel the action." string, which Claude treated as plain
//   user text — leading to vague replies that failed to differentiate
//   "user explicitly declined" from "we timed out" from "tool errored".
//
// What.
//   A small immutable value type carrying both a typed [kind] and a
//   ready-to-serialize JSON shape:
//     {"is_error": <bool>, "content": <human-readable>, "type": <reason>}
//
//   - userApproved → not currently routed through tool_result (the
//     real action runs and produces its own result), but the type is
//     here for completeness and so future code paths can use it
//     without inventing yet another shape.
//   - userRejected / timeout → wrapped into [toSystemMessage] which the
//     chat layer sends back as a [system] message containing the JSON,
//     letting Claude branch on the structured payload.
//
// Pinned by test/widgets/tool_approval_timeout_test.dart.
// -----------------------------------------------------------------------------

import 'dart:convert';

/// Discriminator for the three terminal states of an approval modal.
enum ToolApprovalKind {
  userApproved,
  userRejected,
  timeout,
}

/// Immutable outcome record produced by the approval bar.
class ToolApprovalOutcome {
  const ToolApprovalOutcome._({
    required this.kind,
    required this.isError,
    required this.content,
    required this.type,
  });

  /// Default modal lifetime before auto-rejection. Tests pin this so a
  /// change requires updating the UX expectation explicitly.
  static const Duration defaultTimeout = Duration(minutes: 5);

  final ToolApprovalKind kind;
  final bool isError;
  final String content;
  final String type;

  factory ToolApprovalOutcome.userApproved() => const ToolApprovalOutcome._(
        kind: ToolApprovalKind.userApproved,
        isError: false,
        content: 'User approved this action.',
        type: 'user_approved',
      );

  factory ToolApprovalOutcome.userRejected() => const ToolApprovalOutcome._(
        kind: ToolApprovalKind.userRejected,
        isError: true,
        content: 'User declined this action.',
        type: 'user_rejected',
      );

  factory ToolApprovalOutcome.timeout() => const ToolApprovalOutcome._(
        kind: ToolApprovalKind.timeout,
        isError: true,
        content: 'Approval timed out — user did not respond within the '
            'allowed window.',
        type: 'timeout',
      );

  /// JSON shape mirroring Anthropic's tool_result content blocks:
  ///   {"is_error": ..., "content": ..., "type": ...}
  Map<String, dynamic> toToolResultJson() => {
        'is_error': isError,
        'content': content,
        'type': type,
      };

  /// Wrap the JSON in a [system] message so the existing
  /// `_sendMessage('[system] …')` path in chat_screen continues to
  /// work. Claude can extract the embedded JSON and branch on `type`
  /// to choose between "offer alternative", "apologise", "retry".
  String toSystemMessage() {
    final body = jsonEncode(toToolResultJson());
    return '[system] tool_approval_outcome=$body. '
        'Acknowledge in the user\'s language and, if appropriate, '
        'suggest an alternative. Do not retry the same action.';
  }
}
