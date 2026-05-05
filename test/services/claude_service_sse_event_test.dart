@Tags(['fast'])
library;

// =============================================================================
// claude_service_sse_event_test.dart — SSE → ChatStreamEvent mapping pin.
// =============================================================================
//
// Reasoning Trail v1 (2026-05-05). Drives [parseSseEvent] with canned JSON
// payloads matching Anthropic's SSE wire format and asserts the typed event
// sequence is correct.
//
// Source of truth for shapes:
//   • https://docs.anthropic.com/en/api/messages-streaming
//   • https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking
// =============================================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/chat_stream_event.dart';
import 'package:advocat/services/claude_service.dart';

void main() {
  group('parseSseEvent — text-only stream (legacy path)', () {
    test('plain text turn maps to TextDeltas + MessageDone', () {
      final state = SseStreamState();
      final events = <ChatStreamEvent>[];

      events.addAll(parseSseEvent({
        'type': 'message_start',
        'message': {'usage': {'input_tokens': 50}}
      }, state: state));
      events.addAll(parseSseEvent({
        'type': 'content_block_start',
        'index': 0,
        'content_block': {'type': 'text', 'text': ''}
      }, state: state));
      events.addAll(parseSseEvent({
        'type': 'content_block_delta',
        'index': 0,
        'delta': {'type': 'text_delta', 'text': 'Hello '}
      }, state: state));
      events.addAll(parseSseEvent({
        'type': 'content_block_delta',
        'index': 0,
        'delta': {'type': 'text_delta', 'text': 'world!'}
      }, state: state));
      events.addAll(parseSseEvent({
        'type': 'content_block_stop',
        'index': 0,
      }, state: state));
      events.addAll(parseSseEvent({
        'type': 'message_delta',
        'usage': {'output_tokens': 12}
      }, state: state));
      events.addAll(parseSseEvent({
        'type': 'message_stop',
      }, state: state));

      expect(events, [
        const TextDelta('Hello '),
        const TextDelta('world!'),
        const MessageDone(thinkingMs: null, sources: 0),
      ]);
    });

    test('empty text_delta is skipped (no-op)', () {
      final state = SseStreamState();
      final events = parseSseEvent({
        'type': 'content_block_delta',
        'delta': {'type': 'text_delta', 'text': ''}
      }, state: state);
      expect(events, isEmpty);
    });
  });

  group('parseSseEvent — extended thinking', () {
    test('thinking block emits ThinkingStart + Delta + Stop', () {
      final state = SseStreamState();
      final events = <ChatStreamEvent>[];

      events.addAll(parseSseEvent({'type': 'message_start'}, state: state));
      events.addAll(parseSseEvent({
        'type': 'content_block_start',
        'index': 0,
        'content_block': {'type': 'thinking', 'thinking': ''}
      }, state: state));
      events.addAll(parseSseEvent({
        'type': 'content_block_delta',
        'index': 0,
        'delta': {'type': 'thinking_delta', 'thinking': 'Reading the deportation order…'}
      }, state: state));
      events.addAll(parseSseEvent({
        'type': 'content_block_delta',
        'index': 0,
        'delta': {'type': 'signature_delta', 'signature': 'ABCD'}
      }, state: state));
      events.addAll(parseSseEvent({
        'type': 'content_block_delta',
        'index': 0,
        'delta': {'type': 'signature_delta', 'signature': 'EFGH'}
      }, state: state));
      events.addAll(parseSseEvent({
        'type': 'content_block_stop',
        'index': 0,
      }, state: state));

      expect(events, [
        const ThinkingStart(),
        const ThinkingDelta('Reading the deportation order…'),
        const ThinkingStop(signature: 'ABCDEFGH'),
      ]);
    });

    test('signature_delta from `text` field also accepted (defensive)', () {
      final state = SseStreamState();
      // Some test harnesses use `delta.text` instead of `delta.thinking`.
      final events = parseSseEvent({
        'type': 'content_block_delta',
        'delta': {'type': 'thinking_delta', 'text': 'fallback path'}
      }, state: state);
      expect(events, [const ThinkingDelta('fallback path')]);
    });
  });

  group('parseSseEvent — tool_use', () {
    test('tool_use block emits ToolUseStart + InputDelta + Stop', () {
      final state = SseStreamState();
      final events = <ChatStreamEvent>[];

      events.addAll(parseSseEvent({'type': 'message_start'}, state: state));
      events.addAll(parseSseEvent({
        'type': 'content_block_start',
        'index': 0,
        'content_block': {
          'type': 'tool_use',
          'id': 'toolu_01ABC',
          'name': 'search_estonian_law',
          'input': {}
        }
      }, state: state));
      events.addAll(parseSseEvent({
        'type': 'content_block_delta',
        'index': 0,
        'delta': {'type': 'input_json_delta', 'partial_json': '{"q":"deport'}
      }, state: state));
      events.addAll(parseSseEvent({
        'type': 'content_block_delta',
        'index': 0,
        'delta': {'type': 'input_json_delta', 'partial_json': 'ation"}'}
      }, state: state));
      events.addAll(parseSseEvent({
        'type': 'content_block_stop',
        'index': 0,
      }, state: state));

      expect(events, [
        const ToolUseStart('search_estonian_law', 'toolu_01ABC'),
        const ToolInputDelta('{"q":"deport'),
        const ToolInputDelta('ation"}'),
        const ToolUseStop(),
      ]);
    });

    test('server_tool_use (web_search) is treated like a tool_use', () {
      final state = SseStreamState();
      final events = parseSseEvent({
        'type': 'content_block_start',
        'index': 0,
        'content_block': {
          'type': 'server_tool_use',
          'id': 'srvtoolu_x',
          'name': 'web_search',
        }
      }, state: state);
      expect(events.first, const ToolUseStart('web_search', 'srvtoolu_x'));
    });

    test('synthetic tool_result event yields ToolResultReceived', () {
      final state = SseStreamState();
      final events = parseSseEvent({
        'type': 'tool_result',
        'result': {
          'cardType': 'company_report',
          'data': {'name': 'Acme OU'}
        }
      }, state: state);
      expect(events, hasLength(1));
      expect(events.first, isA<ToolResultReceived>());
      final result = (events.first as ToolResultReceived).result;
      expect(result['cardType'], 'company_report');
    });
  });

  group('parseSseEvent — mixed sequence (typical reasoning turn)', () {
    test('thinking → text emits the right sequence with sources count', () {
      final state = SseStreamState();
      final events = <ChatStreamEvent>[];

      // 1. Open thinking block
      events.addAll(parseSseEvent({'type': 'message_start'}, state: state));
      events.addAll(parseSseEvent({
        'type': 'content_block_start',
        'content_block': {'type': 'thinking'}
      }, state: state));
      events.addAll(parseSseEvent({
        'type': 'content_block_delta',
        'delta': {'type': 'thinking_delta', 'thinking': 'Need to look up the law.'}
      }, state: state));
      events.addAll(parseSseEvent({'type': 'content_block_stop'}, state: state));

      // 2. Tool use
      events.addAll(parseSseEvent({
        'type': 'content_block_start',
        'content_block': {
          'type': 'tool_use',
          'id': 'toolu_x',
          'name': 'search_estonian_law'
        }
      }, state: state));
      events.addAll(parseSseEvent({'type': 'content_block_stop'}, state: state));

      // 3. Final text answer
      events.addAll(parseSseEvent({
        'type': 'content_block_start',
        'content_block': {'type': 'text'}
      }, state: state));
      events.addAll(parseSseEvent({
        'type': 'content_block_delta',
        'delta': {'type': 'text_delta', 'text': 'Per VSS § 17… '}
      }, state: state));
      events.addAll(parseSseEvent({'type': 'content_block_stop'}, state: state));

      // 4. Done
      events.addAll(parseSseEvent({'type': 'message_stop'}, state: state));

      expect(events.map((e) => e.runtimeType.toString()).toList(), [
        'ThinkingStart',
        'ThinkingDelta',
        'ThinkingStop',
        'ToolUseStart',
        'ToolUseStop',
        'TextDelta',
        'MessageDone',
      ]);

      final done = events.last as MessageDone;
      expect(done.sources, 1, reason: 'one tool_use seen');
    });
  });

  group('parseSseEvent — forward compat', () {
    test('unknown event type is dropped silently', () {
      final state = SseStreamState();
      final events = parseSseEvent({'type': 'futurething'}, state: state);
      expect(events, isEmpty);
    });

    test('unknown delta type is dropped silently', () {
      final state = SseStreamState();
      final events = parseSseEvent({
        'type': 'content_block_delta',
        'delta': {'type': 'mysterious_delta', 'data': 42}
      }, state: state);
      expect(events, isEmpty);
    });

    test('missing fields do not crash the parser', () {
      final state = SseStreamState();
      expect(parseSseEvent({}, state: state), isEmpty);
      expect(parseSseEvent({'type': 'content_block_delta'}, state: state), isEmpty);
      expect(parseSseEvent({'type': 'content_block_start'}, state: state), isEmpty);
    });
  });
}
