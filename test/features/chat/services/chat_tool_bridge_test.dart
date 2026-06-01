// Pure-Dart regression for ChatToolBridge's static response-parsing methods.
//
// These parse the Claude API response into tool_use blocks + text, and build
// the tool_result content sent BACK to Claude. A bug here is user-visible: a
// dropped tool_use block means a tool silently never runs; a malformed
// tool_result breaks the follow-up turn. The instance methods (executeToolCalls,
// performNavigations) need a BuildContext/executor and are not unit-testable,
// but every static method here is pure and worth locking.

import 'dart:convert';

import 'package:advocat/features/chat/services/chat_tool_bridge.dart';
import 'package:advocat/services/assistant_tools.dart';
import 'package:flutter_test/flutter_test.dart';

// Mirrors what jsonDecode produces in production: every nested object is a
// Map<String, dynamic>. Re-encoding through json normalizes inline literals
// (e.g. `{}`) that would otherwise infer Map<dynamic, dynamic> and break the
// `as Map<String, dynamic>?` cast in ToolUseBlock.fromJson.
Map<String, dynamic> _resp(List<Map<String, dynamic>> content) =>
    jsonDecode(jsonEncode({'content': content})) as Map<String, dynamic>;

void main() {
  group('ToolUseBlock.fromJson', () {
    test('maps id/name/input', () {
      final b = ToolUseBlock.fromJson({
        'id': 'tu_1',
        'name': 'check_company',
        'input': {'code': '12345678'},
      });
      expect(b.id, 'tu_1');
      expect(b.name, 'check_company');
      expect(b.input['code'], '12345678');
    });

    test('missing fields → empty defaults (no throw)', () {
      final b = ToolUseBlock.fromJson(const {});
      expect(b.id, '');
      expect(b.name, '');
      expect(b.input, isEmpty);
    });
  });

  group('hasToolUse', () {
    test('true when a tool_use block is present', () {
      expect(
        ChatToolBridge.hasToolUse(_resp([
          {'type': 'text', 'text': 'hi'},
          {'type': 'tool_use', 'id': 't', 'name': 'x', 'input': {}},
        ])),
        isTrue,
      );
    });

    test('false for text-only and for missing content', () {
      expect(
        ChatToolBridge.hasToolUse(_resp([
          {'type': 'text', 'text': 'hi'},
        ])),
        isFalse,
      );
      expect(ChatToolBridge.hasToolUse(const {}), isFalse);
    });
  });

  group('extractToolUseBlocks', () {
    test('returns only tool_use blocks, in order', () {
      final blocks = ChatToolBridge.extractToolUseBlocks(_resp([
        {'type': 'text', 'text': 'thinking'},
        {'type': 'tool_use', 'id': 't1', 'name': 'check_company', 'input': {}},
        {'type': 'tool_use', 'id': 't2', 'name': 'check_vehicle', 'input': {}},
      ]));
      expect(blocks.map((b) => b.id).toList(), ['t1', 't2']);
      expect(blocks.map((b) => b.name).toList(),
          ['check_company', 'check_vehicle']);
    });

    test('empty when no content / no tool_use', () {
      expect(ChatToolBridge.extractToolUseBlocks(const {}), isEmpty);
      expect(
        ChatToolBridge.extractToolUseBlocks(_resp([
          {'type': 'text', 'text': 'hi'},
        ])),
        isEmpty,
      );
    });
  });

  group('extractText', () {
    test('joins multiple text blocks with newlines, ignores tool_use', () {
      final text = ChatToolBridge.extractText(_resp([
        {'type': 'text', 'text': 'line one'},
        {'type': 'tool_use', 'id': 't', 'name': 'x', 'input': {}},
        {'type': 'text', 'text': 'line two'},
      ]));
      expect(text, 'line one\nline two');
    });

    test('empty string when no text / no content', () {
      expect(ChatToolBridge.extractText(const {}), '');
      expect(
        ChatToolBridge.extractText(_resp([
          {'type': 'tool_use', 'id': 't', 'name': 'x', 'input': {}},
        ])),
        '',
      );
    });
  });

  group('buildToolResultsForClaude', () {
    test('pairs each tool_use id with its result content (JSON when structured)', () {
      final original = _resp([
        {'type': 'tool_use', 'id': 't1', 'name': 'check_company', 'input': {}},
      ]);
      final results = [
        const ToolResultMessage(
          displayText: 'shown to user',
          toolResult: ToolResult(
            success: true,
            displayText: 'Company OÜ is active',
            cardType: 'company_report',
          ),
        ),
      ];
      final built = ChatToolBridge.buildToolResultsForClaude(original, results);
      expect(built, hasLength(1));
      expect(built.first['type'], 'tool_result');
      expect(built.first['tool_use_id'], 't1');
      // structured → content is the JSON-encoded toJson()
      expect(built.first['content'], contains('Company OÜ is active'));
      expect(built.first['content'], contains('company_report'));
    });

    test('falls back to displayText when there is no structured toolResult', () {
      final original = _resp([
        {'type': 'tool_use', 'id': 't1', 'name': 'x', 'input': {}},
      ]);
      final built = ChatToolBridge.buildToolResultsForClaude(original, [
        const ToolResultMessage(displayText: 'plain failure text'),
      ]);
      expect(built.first['content'], 'plain failure text');
    });

    test('zips to the SHORTER of blocks vs results (no index overflow)', () {
      final original = _resp([
        {'type': 'tool_use', 'id': 't1', 'name': 'x', 'input': {}},
        {'type': 'tool_use', 'id': 't2', 'name': 'y', 'input': {}},
      ]);
      final built = ChatToolBridge.buildToolResultsForClaude(original, [
        const ToolResultMessage(displayText: 'only one result'),
      ]);
      expect(built, hasLength(1), reason: 'stops at the shorter list');
      expect(built.first['tool_use_id'], 't1');
    });
  });

  group('buildFollowUpSummary', () {
    test('summarizes structured result: tool/status/summary + scalar details', () {
      final summary = ChatToolBridge.buildFollowUpSummary([
        const ToolResultMessage(
          displayText: 'd',
          toolResult: ToolResult(
            success: true,
            displayText: 'Found 2 deadlines',
            cardType: 'deadline_list',
            data: {'count': 2, 'urgent': true, 'note': 'KHO appeal'},
          ),
        ),
      ]);
      expect(summary, contains('Tool: deadline_list'));
      expect(summary, contains('Status: success'));
      expect(summary, contains('Summary: Found 2 deadlines'));
      expect(summary, contains('count: 2'));
      expect(summary, contains('urgent: true'));
      expect(summary, contains('note: KHO appeal'));
    });

    test('collapses long lists to a count, joins short lists', () {
      final summary = ChatToolBridge.buildFollowUpSummary([
        ToolResultMessage(
          displayText: 'd',
          toolResult: ToolResult(
            success: true,
            displayText: 's',
            data: {
              'short': ['a', 'b'],
              'long': List.generate(9, (i) => 'x$i'),
            },
          ),
        ),
      ]);
      expect(summary, contains('short: a, b'));
      expect(summary, contains('long: 9 items'),
          reason: 'lists > 5 are collapsed to "<n> items"');
    });

    test('flags approval-required actions', () {
      final summary = ChatToolBridge.buildFollowUpSummary([
        const ToolResultMessage(
          displayText: 'd',
          toolResult: ToolResult(
            success: true,
            displayText: 'Draft ready',
            requiresApproval: true,
            approvalMessage: 'Send email to court?',
          ),
        ),
      ]);
      expect(summary, contains('requires user approval'));
      expect(summary, contains('Send email to court?'));
    });

    test('handles a result with no structured toolResult', () {
      final summary = ChatToolBridge.buildFollowUpSummary([
        const ToolResultMessage(displayText: 'raw text only'),
      ]);
      expect(summary, contains('returned no structured result'));
      expect(summary, contains('raw text only'));
    });
  });
}
