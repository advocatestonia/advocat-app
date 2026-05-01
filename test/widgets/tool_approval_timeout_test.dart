// tool_approval_timeout_test.dart
//
// BUG#4 anti-regression (2026-04-29 pre-launch). Two prod issues:
//
//   1. The approval modal blocked indefinitely. If the user navigated
//      away or closed the tab, the AI never got a tool_result back and
//      future messages would dangle (Anthropic's API requires a
//      tool_result for every preceding tool_use).
//
//   2. On Cancel, the chat sent a free-text "[system] Cancel the
//      action." message, losing the structured shape Claude expects.
//      The AI couldn't reliably tell "user explicitly declined" from
//      "we timed out" from "tool errored", so it gave generic replies.
//
// Fix:
//
//   • A 5-minute timer on the approval bar. Auto-fires onReject with
//     reason: timeout when it elapses.
//   • A tiny pure builder, ToolApprovalOutcome.toToolResultJson, that
//     produces the structured shape:
//         {"is_error": true, "content": <msg>, "type": <reason>}
//     where reason ∈ {user_rejected, timeout, user_approved}.
//
// We test the pure builder + the widget timer behaviour. The widget
// test uses pumpAndSettle with fake clock advances rather than a real
// 5-minute wait.
//
// @Tags(['fast'])

@Tags(['fast'])
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/chat/widgets/approval_outcome.dart';
import 'package:advocat/features/chat/widgets/tool_result_card.dart';
import 'package:advocat/services/assistant_tools.dart';

void main() {
  group('ToolApprovalOutcome — structured tool_result builder', () {
    test('user_rejected → is_error true, type user_rejected', () {
      final json = ToolApprovalOutcome.userRejected().toToolResultJson();
      expect(json['is_error'], true);
      expect(json['type'], 'user_rejected');
      expect(json['content'], contains('declined'));
    });

    test('timeout → is_error true, type timeout', () {
      final json = ToolApprovalOutcome.timeout().toToolResultJson();
      expect(json['is_error'], true);
      expect(json['type'], 'timeout');
      expect(json['content'], contains('timed out'));
    });

    test('user_approved → is_error false, type user_approved', () {
      final json = ToolApprovalOutcome.userApproved().toToolResultJson();
      expect(json['is_error'], false);
      expect(json['type'], 'user_approved');
    });

    test('toSystemMessage produces a structured prompt the AI can parse', () {
      // The AI receives a [system] message containing the JSON. This
      // mirrors the existing chat_screen contract for system messages
      // but carries a structured payload Claude can branch on.
      final msg = ToolApprovalOutcome.timeout().toSystemMessage();
      // It must contain a valid JSON literal so an LLM can extract it.
      final start = msg.indexOf('{');
      final end = msg.lastIndexOf('}');
      expect(start, greaterThan(-1));
      expect(end, greaterThan(start));
      final parsed = jsonDecode(msg.substring(start, end + 1))
          as Map<String, dynamic>;
      expect(parsed['is_error'], true);
      expect(parsed['type'], 'timeout');
    });

    test('default timeout is 5 minutes (300s)', () {
      // Pinned so changing the constant requires updating this test
      // and acknowledging the UX impact.
      expect(ToolApprovalOutcome.defaultTimeout, const Duration(minutes: 5));
    });
  });

  group('ToolResultCard approval bar — timer behaviour', () {
    testWidgets(
        'idle 5 minutes → onReject called with timeout outcome',
        (WidgetTester tester) async {
      ToolApprovalOutcome? captured;
      const result = ToolResult(
        success: true,
        displayText: 'Send this email?',
        cardType: 'email_draft',
        data: {
          'to': 'a@b.com',
          'subject': 's',
          'body': 'b',
        },
        requiresApproval: true,
        approvalMessage: 'Confirm?',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolResultCard(
              result: result,
              onApprove: () {
                captured = ToolApprovalOutcome.userApproved();
              },
              onRejectWithReason: (outcome) {
                captured = outcome;
              },
            ),
          ),
        ),
      );

      // Push past the 5-minute timeout.
      await tester.pump(const Duration(minutes: 5, seconds: 1));

      expect(captured, isNotNull);
      expect(captured!.kind, ToolApprovalKind.timeout);
    });

    testWidgets(
        'tap Cancel → onReject called with user_rejected outcome',
        (WidgetTester tester) async {
      ToolApprovalOutcome? captured;
      const result = ToolResult(
        success: true,
        displayText: 'Send this email?',
        cardType: 'email_draft',
        data: {
          'to': 'a@b.com',
          'subject': 's',
          'body': 'b',
        },
        requiresApproval: true,
        approvalMessage: 'Confirm?',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolResultCard(
              result: result,
              onApprove: () {
                captured = ToolApprovalOutcome.userApproved();
              },
              onRejectWithReason: (outcome) {
                captured = outcome;
              },
            ),
          ),
        ),
      );

      // Let the entry animation finish before tapping (avoids leaked
      // animation timers tripping the test binding's pending-timer check).
      await tester.pumpAndSettle();
      // Tap the Cancel button. The card may contain other OutlinedButtons
      // (Send Email / Copy in the email_draft body), so we match by the
      // localised "Cancel" label fallback used inside _ApprovalBar.
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.kind, ToolApprovalKind.userRejected);
    });

    testWidgets(
        'after Cancel, the timer no longer fires onReject',
        (WidgetTester tester) async {
      // Regression: it would be a bug if user pressed Cancel and 5 min
      // later we ALSO fired the timeout outcome, double-rejecting the
      // pending tool_use. The widget must cancel its timer on dispose
      // and on first reject.
      var rejectCount = 0;
      const result = ToolResult(
        success: true,
        displayText: 'Send this email?',
        cardType: 'email_draft',
        data: {
          'to': 'a@b.com',
          'subject': 's',
          'body': 'b',
        },
        requiresApproval: true,
        approvalMessage: 'Confirm?',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolResultCard(
              result: result,
              onApprove: () {},
              onRejectWithReason: (_) => rejectCount++,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();
      // Then push past the 5-minute timeout.
      await tester.pump(const Duration(minutes: 5, seconds: 1));

      expect(rejectCount, 1, reason: 'Reject must fire exactly once');
    });

    testWidgets(
        'legacy onReject (no reason) still works for backwards compat',
        (WidgetTester tester) async {
      // Old call-sites call ToolResultCard with onReject only. The
      // widget MUST still fire that callback so we don't break the
      // existing chat_screen wiring during the migration.
      var legacyFired = 0;
      const result = ToolResult(
        success: true,
        displayText: 'Send?',
        cardType: 'email_draft',
        data: {'to': 'a@b.com', 'subject': 's', 'body': 'b'},
        requiresApproval: true,
        approvalMessage: 'Confirm?',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolResultCard(
              result: result,
              onApprove: () {},
              onReject: () => legacyFired++,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(legacyFired, 1);
    });
  });
}
