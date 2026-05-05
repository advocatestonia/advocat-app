@Tags(['fast'])
library;

// =============================================================================
// ai_agentic_loop_test.dart — Smart Agent v2: agentic loop contract tests.
// =============================================================================
//
// These tests pin down the canonical Anthropic agentic loop:
//
//   for i in 0..5:
//     response = claude.send(messages)
//     end_turn?       → break
//     tool_use?       → exec, append [tool_result, ...], continue
//     errors          → is_error:true block, model can self-correct
//     write tool      → halt for UI approval (sacred flow preserved)
//     5 iterations    → graceful "tried multiple steps" termination
//
// We drive [runAgenticLoop] with fake send/exec closures so the tests are
// pure: no Claude API, no tool side-effects, deterministic ordering.
// =============================================================================

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/services/agentic_loop.dart';
import 'package:advocat/services/assistant_tools.dart';

/// Fake Claude — returns a queued list of canned responses in order.
class _FakeClaude {
  _FakeClaude(this.responses);
  final List<Map<String, dynamic>> responses;
  final List<List<Map<String, dynamic>>> received = [];
  int _idx = 0;

  Future<Map<String, dynamic>> send(
      List<Map<String, dynamic>> messages) async {
    // Deep-copy received messages so later mutations don't poison snapshots.
    received.add(messages.map((m) {
      return {
        'role': m['role'],
        'content': m['content'] is List
            ? List<dynamic>.from(m['content'] as List)
            : m['content'],
      };
    }).toList());

    if (_idx >= responses.length) {
      throw StateError(
          'FakeClaude ran out of canned responses (got ${responses.length})');
    }
    return responses[_idx++];
  }

  int get callCount => _idx;
}

/// Helper: build a Claude end_turn response with text only.
Map<String, dynamic> _endTurn(String text) => {
      'stop_reason': 'end_turn',
      'content': [
        {'type': 'text', 'text': text}
      ],
    };

/// Helper: build a Claude tool_use response.
Map<String, dynamic> _toolUse({
  required String id,
  required String name,
  required Map<String, dynamic> input,
  String? text,
}) =>
    {
      'stop_reason': 'tool_use',
      'content': [
        if (text != null) {'type': 'text', 'text': text},
        {
          'type': 'tool_use',
          'id': id,
          'name': name,
          'input': input,
        },
      ],
    };

/// Default fake tool: returns a small ToolResult with the input echoed.
Future<ToolResult> _fakeToolOk(String name, Map<String, dynamic> input) async {
  return ToolResult(
    success: true,
    displayText: 'Result of $name',
    cardType: 'fake',
    data: input,
  );
}

void main() {
  group('runAgenticLoop', () {
    test('Single-turn no tools — returns immediately, 1 API call', () async {
      final claude = _FakeClaude([_endTurn('Hello!')]);

      final outcome = await runAgenticLoop(
        initialMessages: [
          {'role': 'user', 'content': 'hi'}
        ],
        send: claude.send,
        executeTool: _fakeToolOk,
      );

      expect(outcome.text, equals('Hello!'));
      expect(outcome.stopReason, LoopStopReason.endTurn);
      expect(outcome.iterations, equals(1));
      expect(outcome.toolCalls, isEmpty);
      expect(claude.callCount, equals(1));
    });

    test(
        'Single tool_use — loop iterates twice, tool_result block sent correctly',
        () async {
      final claude = _FakeClaude([
        _toolUse(
          id: 'toolu_1',
          name: 'search_estonian_law',
          input: {'query': 'KarS § 121'},
        ),
        _endTurn('KarS § 121 is the assault statute.'),
      ]);

      final outcome = await runAgenticLoop(
        initialMessages: [
          {'role': 'user', 'content': 'what is § 121?'}
        ],
        send: claude.send,
        executeTool: _fakeToolOk,
      );

      expect(outcome.iterations, equals(2));
      expect(outcome.stopReason, LoopStopReason.endTurn);
      expect(outcome.text, contains('KarS § 121 is the assault statute.'));
      expect(outcome.toolCalls, hasLength(1));
      expect(outcome.toolCalls.first.name, 'search_estonian_law');
      expect(outcome.toolCalls.first.isError, isFalse);

      // Critical: on the SECOND send, messages must include the
      // assistant turn (raw blocks) AND a user turn carrying the
      // tool_result block paired with the matching tool_use_id.
      expect(claude.received, hasLength(2));
      final secondTurnMessages = claude.received[1];
      expect(secondTurnMessages, hasLength(3),
          reason: 'user → assistant(tool_use) → user(tool_result)');
      expect(secondTurnMessages[1]['role'], 'assistant');
      expect(secondTurnMessages[2]['role'], 'user');

      final toolResultContent =
          secondTurnMessages[2]['content'] as List<dynamic>;
      expect(toolResultContent, hasLength(1));
      final toolResult = toolResultContent.first as Map<String, dynamic>;
      expect(toolResult['type'], 'tool_result');
      expect(toolResult['tool_use_id'], 'toolu_1');
      expect(toolResult.containsKey('is_error'), isFalse);
      // Content is JSON-encoded ToolResult.toJson
      final decoded =
          jsonDecode(toolResult['content'] as String) as Map<String, dynamic>;
      expect(decoded['success'], isTrue);
      expect(decoded['displayText'], 'Result of search_estonian_law');
    });

    test(
        'Two-tool chain — search_estonian_law → analyze_document → 3 iterations',
        () async {
      final claude = _FakeClaude([
        _toolUse(
          id: 'toolu_a',
          name: 'search_estonian_law',
          input: {'query': 'KarS § 121'},
        ),
        _toolUse(
          id: 'toolu_b',
          name: 'analyze_document',
          input: {'doc_id': 'abc'},
        ),
        _endTurn('Combined answer.'),
      ]);

      final outcome = await runAgenticLoop(
        initialMessages: [
          {'role': 'user', 'content': 'analyze and cite'}
        ],
        send: claude.send,
        executeTool: _fakeToolOk,
      );

      expect(outcome.iterations, equals(3));
      expect(outcome.stopReason, LoopStopReason.endTurn);
      expect(outcome.text, contains('Combined answer.'));
      expect(outcome.toolCalls, hasLength(2));
      expect(outcome.toolCalls[0].name, 'search_estonian_law');
      expect(outcome.toolCalls[1].name, 'analyze_document');

      // The third send should have BOTH prior tool_result blocks in
      // history (one assistant + one user pair per tool turn).
      final thirdTurn = claude.received[2];
      expect(thirdTurn.length, equals(5),
          reason:
              'user → assistant(tool_use_a) → user(tool_result_a) → assistant(tool_use_b) → user(tool_result_b)');
    });

    test(
        'Tool error — is_error:true block sent, model recovers on next iteration',
        () async {
      final claude = _FakeClaude([
        _toolUse(
          id: 'toolu_x',
          name: 'search_estonian_law',
          input: {'query': 'broken'},
        ),
        _endTurn('Sorry, I could not find that statute.'),
      ]);

      Future<ToolResult> failingExecutor(
          String name, Map<String, dynamic> input) async {
        throw Exception('Estonian law DB unreachable');
      }

      final outcome = await runAgenticLoop(
        initialMessages: [
          {'role': 'user', 'content': 'find § X'}
        ],
        send: claude.send,
        executeTool: failingExecutor,
      );

      expect(outcome.stopReason, LoopStopReason.endTurn);
      expect(outcome.iterations, equals(2));
      expect(outcome.toolCalls.first.isError, isTrue);

      // The is_error:true must reach Claude in the second turn so it
      // can self-correct.
      final secondTurn = claude.received[1];
      final toolResultBlock =
          (secondTurn[2]['content'] as List<dynamic>).first
              as Map<String, dynamic>;
      expect(toolResultBlock['type'], 'tool_result');
      expect(toolResultBlock['is_error'], isTrue);
      expect(toolResultBlock['content'].toString(),
          contains('Estonian law DB unreachable'));
    });

    test('Max iterations cap (5) — loop terminates with graceful message',
        () async {
      // Six tool_use responses; loop should stop at iteration 5 even
      // though Claude keeps asking for more tools.
      final infiniteToolLoop = List.generate(
        10,
        (i) => _toolUse(
          id: 'toolu_$i',
          name: 'search_estonian_law',
          input: {'query': 'iter $i'},
        ),
      );
      final claude = _FakeClaude(infiniteToolLoop);

      final outcome = await runAgenticLoop(
        initialMessages: [
          {'role': 'user', 'content': 'go forever'}
        ],
        send: claude.send,
        executeTool: _fakeToolOk,
      );

      expect(outcome.stopReason, LoopStopReason.maxIterations);
      expect(outcome.iterations, equals(kMaxAgenticIterations));
      expect(outcome.text, contains('tried multiple steps'),
          reason: 'graceful cap message must be present');
    });

    test(
        'Write tool with requiresApproval — loop pauses, returns pendingApprovalResponse',
        () async {
      // Hard-coded: send_email is in AssistantTools.requiresApproval.
      expect(AssistantTools.requiresApproval, contains('send_email'));

      final pausingResponse = _toolUse(
        id: 'toolu_email',
        name: 'send_email',
        input: {'to': 'x@y.com', 'subject': 'Test'},
        text: 'I will draft the email now.',
      );
      final claude = _FakeClaude([pausingResponse]);

      // executor must NEVER be called for write-approval tools — that
      // would bypass the user-approval flow.
      var execCount = 0;
      Future<ToolResult> spyingExecutor(
          String name, Map<String, dynamic> input) async {
        execCount++;
        return _fakeToolOk(name, input);
      }

      final outcome = await runAgenticLoop(
        initialMessages: [
          {'role': 'user', 'content': 'send email to x@y.com'}
        ],
        send: claude.send,
        executeTool: spyingExecutor,
      );

      expect(outcome.stopReason, LoopStopReason.requiresApproval);
      expect(outcome.iterations, equals(1));
      expect(execCount, equals(0),
          reason:
              'write-approval tool must NOT be auto-executed — UI approval flow handles it');
      expect(outcome.pendingApprovalResponse, equals(pausingResponse));
      // Pre-approval text the model said is preserved
      expect(outcome.text, contains('I will draft the email now.'));
      expect(claude.callCount, equals(1));
    });

    test('Tool error returning success=false also marked is_error:true',
        () async {
      // ToolResult.success=false should trigger is_error:true even
      // when the executor returned cleanly.
      final claude = _FakeClaude([
        _toolUse(
          id: 'toolu_y',
          name: 'check_company',
          input: {'name': 'Bogus AS'},
        ),
        _endTurn('Could not find that company.'),
      ]);

      Future<ToolResult> erroredResultExecutor(
          String name, Map<String, dynamic> input) async {
        return ToolResult(
          success: false,
          displayText: 'Company not found in registry',
        );
      }

      final outcome = await runAgenticLoop(
        initialMessages: [
          {'role': 'user', 'content': 'check Bogus AS'}
        ],
        send: claude.send,
        executeTool: erroredResultExecutor,
      );

      expect(outcome.toolCalls.first.isError, isTrue);
      final secondTurn = claude.received[1];
      final toolResultBlock =
          (secondTurn[2]['content'] as List<dynamic>).first
              as Map<String, dynamic>;
      expect(toolResultBlock['is_error'], isTrue);
    });

    test('toolCalls list captures inputs verbatim for citation verification',
        () async {
      final claude = _FakeClaude([
        _toolUse(
          id: 'toolu_law',
          name: 'search_estonian_law',
          input: {'query': 'KarS § 121 nõusolekuta seksuaalvahekord'},
        ),
        _endTurn('Per KarS § 121, …'),
      ]);

      final outcome = await runAgenticLoop(
        initialMessages: [
          {'role': 'user', 'content': 'tell me about § 121'}
        ],
        send: claude.send,
        executeTool: _fakeToolOk,
      );

      expect(outcome.toolCalls, hasLength(1));
      final call = outcome.toolCalls.first;
      expect(call.name, 'search_estonian_law');
      expect(call.input['query'],
          equals('KarS § 121 nõusolekuta seksuaalvahekord'));
      // The CitationToolCall view feeds the verifier
      final view = call.toCitationToolCall();
      expect(view.name, 'search_estonian_law');
      expect(view.input['query'], contains('KarS'));
      expect(view.input['query'], contains('121'));
    });
  });
}
