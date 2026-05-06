@Tags(['fast'])
library;

// =============================================================================
// citations_streaming_parser_test.dart — Pkg 2 closeout (Flutter side).
// =============================================================================
//
// Pins the SSE-side handling of the proxy's trailing `event: citations`
// frame on the Flutter consumer. The proxy wrap (claude-proxy/streaming_
// citations.ts) emits the frame AFTER Anthropic's own message_stop; on
// the wire it looks like:
//
//   event: citations
//   data: {"citations":[{...}], "message_id":"550e8400-..."}
//   <blank line>
//
// The existing line-buffered SSE parser ignores `event:` lines and only
// processes `data:` lines, so the detection signal in [parseSseEvent] is
// the presence of a top-level `citations` array on the parsed JSON
// (Anthropic's own SSE payloads never carry that key at top level).
//
// Two contracts here:
//   1. parseSseEvent emits a `CitationsReceived` event when the citations
//      JSON arrives. The event preserves payload order and message_id.
//   2. The downstream consumer (`sendMessageStreamingEvents`) does NOT
//      `return` on MessageDone — it now relies on the upstream reader
//      reaching `done`. We pin this in source text since wiring the live
//      streaming pipe in a test would need a real SSE server.
// =============================================================================

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/chat_stream_event.dart';
import 'package:advocat/services/claude_service.dart';

void main() {
  group('parseSseEvent — Pkg 2 trailing citations frame', () {
    test('emits CitationsReceived for verifier payload', () {
      final state = SseStreamState();
      final events = parseSseEvent({
        'citations': [
          {
            'marker': '[[ref:TLS:88]]',
            'status': 'verified',
            'chunk_id': 'tls-§88-1',
            'act_slug': 'tls',
            'paragraph': '88',
            'act_name': 'Töölepingu seadus',
            'title': 'Tööandja erakorraline ülesütlemine',
            'snippet': 'Tööandja võib töölepingu erakorraliselt…',
            'source_url': 'https://www.riigiteataja.ee/akt/tls',
            'jurisdiction': 'EE',
            'in_force': true,
            'occurrences': 1,
          },
          {
            'marker': '[[ref:KarS:121]]',
            'status': 'unverified',
            'chunk_id': null,
            'act_slug': 'kars',
            'paragraph': '121',
            'act_name': null,
            'title': null,
            'snippet': null,
            'source_url': null,
            'jurisdiction': null,
            'in_force': null,
            'occurrences': 1,
          },
        ],
        'message_id': '550e8400-e29b-41d4-a716-446655440000',
      }, state: state);

      expect(events, hasLength(1));
      expect(events.first, isA<CitationsReceived>());
      final ev = events.first as CitationsReceived;
      expect(ev.messageId, '550e8400-e29b-41d4-a716-446655440000');
      expect(ev.rawCitations, hasLength(2));
      expect(ev.rawCitations[0]['act_slug'], 'tls');
      expect(ev.rawCitations[0]['status'], 'verified');
      expect(ev.rawCitations[1]['act_slug'], 'kars');
      expect(ev.rawCitations[1]['status'], 'unverified');
    });

    test('handles message_id null (caller did not opt in to persistence)', () {
      final state = SseStreamState();
      final events = parseSseEvent({
        'citations': [],
        'message_id': null,
      }, state: state);
      expect(events, hasLength(1));
      final ev = events.first as CitationsReceived;
      expect(ev.messageId, isNull);
      expect(ev.rawCitations, isEmpty);
    });

    test('empty citations array still produces a CitationsReceived event', () {
      // The wrap ALWAYS emits the trailing frame, even when verifier output
      // is empty. The Flutter consumer needs the event so it can update
      // its UI ("0 citations") rather than remain in an in-progress state.
      final state = SseStreamState();
      final events = parseSseEvent({
        'citations': <dynamic>[],
        'message_id': 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      }, state: state);
      expect(events, hasLength(1));
      final ev = events.first as CitationsReceived;
      expect(ev.rawCitations, isEmpty);
      expect(ev.messageId, 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee');
    });

    test('payload missing "citations" key emits NO event (legacy compat)', () {
      // Anthropic's own message_delta already lands in the default branch
      // when usage info is absent — we MUST NOT mistake those for citation
      // frames. Detection signal is "citations is a List", nothing else.
      final state = SseStreamState();
      final events = parseSseEvent({
        'unknown_future_event': 'some-value',
      }, state: state);
      expect(events, isEmpty);
    });

    test('non-list "citations" value is ignored (defensive)', () {
      final state = SseStreamState();
      final events = parseSseEvent({
        'citations': 'not an array',
        'message_id': 'foo',
      }, state: state);
      expect(events, isEmpty);
    });

    test('citations event ordering: lands AFTER MessageDone in a full turn', () {
      // Realistic sequence: the wrap forwards Anthropic's message_stop
      // first, then injects the citations frame. The parser pipeline
      // surfaces them in arrival order: MessageDone first, then
      // CitationsReceived. The chat consumer can latch the just-completed
      // assistant message id from MessageDone state, then attach
      // citations from the next event.
      final state = SseStreamState();
      final out = <ChatStreamEvent>[];
      out.addAll(parseSseEvent({
        'type': 'content_block_delta',
        'index': 0,
        'delta': {'type': 'text_delta', 'text': '[[ref:TLS:88]]'},
      }, state: state));
      out.addAll(parseSseEvent({
        'type': 'message_stop',
      }, state: state));
      out.addAll(parseSseEvent({
        'citations': [
          {
            'marker': '[[ref:TLS:88]]',
            'status': 'verified',
            'chunk_id': 'tls-§88-1',
            'act_slug': 'tls',
            'paragraph': '88',
            'act_name': 'TLS',
            'title': null,
            'snippet': null,
            'source_url': null,
            'jurisdiction': 'EE',
            'in_force': true,
            'occurrences': 1,
          },
        ],
        'message_id': null,
      }, state: state));

      expect(out, hasLength(3));
      expect(out[0], isA<TextDelta>());
      expect(out[1], isA<MessageDone>());
      expect(out[2], isA<CitationsReceived>());
    });
  });

  group('CitationsReceived value semantics', () {
    test('equal events compare equal', () {
      const a = CitationsReceived(rawCitations: [], messageId: 'm1');
      const b = CitationsReceived(rawCitations: [], messageId: 'm1');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different messageId values are not equal', () {
      const a = CitationsReceived(rawCitations: [], messageId: 'm1');
      const b = CitationsReceived(rawCitations: [], messageId: 'm2');
      expect(a == b, isFalse);
    });

    test('toString surfaces the count and message id', () {
      final ev = CitationsReceived(
        rawCitations: [
          {'marker': '[[ref:TLS:88]]'},
        ],
        messageId: 'mid-1',
      );
      final s = ev.toString();
      expect(s, contains('n=1'));
      expect(s, contains('messageId=mid-1'));
    });
  });

  group('streaming consumer — does not return early on MessageDone', () {
    test('sendMessageStreamingEvents source no longer breaks on MessageDone',
        () async {
      // Source-text pin: the streaming consumer (claude_service.dart) MUST
      // NOT terminate on MessageDone — the proxy's trailing citations
      // frame arrives AFTER message_stop, and an early return would drop
      // it on the floor. The end-of-stream signal is now the upstream
      // reader's `done` flag.
      final f = File('lib/services/claude_service.dart');
      expect(f.existsSync(), isTrue,
          reason: 'claude_service.dart not found from package root');
      final source = f.readAsStringSync();
      final hasEarlyReturn =
          RegExp(r'if\s*\(\s*ev\s+is\s+MessageDone\s*\)\s*return\s*;')
              .hasMatch(source);
      expect(hasEarlyReturn, isFalse,
          reason:
              'Pkg 2 closeout requires the consumer to keep reading after '
              'MessageDone so the trailing citations SSE frame is delivered.');
    });
  });
}
