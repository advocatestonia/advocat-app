// Unit tests for the message-counter hook in AIService (Pricing Phase 3).
//
// The hook fires fire-and-forget after each user-facing AI response so the
// Founder's Beta refund window (14 days OR 7 responses) closes correctly.
// These tests use a fake [MessageCounter] to pin the contract at the
// dependency-injection level and at the hook call-site:
//
//   1. MessageCounter is injectable via the AIService constructor.
//   2. A null counter (production default when SupabaseService is absent
//      or the user is offline) must NOT crash the hook site.
//   3. Invoking the hook produces exactly one counter.increment() per
//      call — the RPC is atomic on the server, so a single fire per
//      user-facing response is the full contract.
//   4. An async rejection inside increment() (network / RPC failure) is
//      swallowed — the chat flow must never be delayed or broken by a
//      counter-side problem.
//
// End-to-end verification that the hook fires from the real
// sendChatMessage / sendChatMessageStreaming paths is left to the
// integration tests because cache-hits only materialise when
// isUsingRealAI=true, which requires a Claude API key and live Supabase
// client — both out of scope for a unit test.

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/ai_service.dart';

class _FakeCounter implements MessageCounter {
  int calls = 0;
  final bool asyncReject;
  _FakeCounter({this.asyncReject = false});

  @override
  Future<int?> increment() async {
    calls++;
    if (asyncReject) {
      // Simulate a network / RPC failure as a rejected future.
      throw StateError('synthetic');
    }
    return calls;
  }
}

void main() {
  group('AIService — MessageCounter hook wiring', () {
    test('accepts an injectable MessageCounter', () {
      final counter = _FakeCounter();
      final svc = AIService(messageCounter: counter);
      expect(svc, isNotNull);
      expect(counter.calls, 0);
    });

    test('null counter is safe (production default when Supabase absent)', () {
      final svc = AIService();
      // The hook site must be a no-op when no counter is wired — it
      // would be catastrophic for chat UX to break on unauthenticated
      // or demo-mode clients.
      expect(() => svc.debugBumpMessageCounter(), returnsNormally);
    });

    test('debugBump invokes the counter exactly once', () async {
      final counter = _FakeCounter();
      final svc = AIService(messageCounter: counter);
      svc.debugBumpMessageCounter();
      // Fire-and-forget — yield to the microtask queue so the increment
      // future settles.
      await Future<void>.delayed(Duration.zero);
      expect(counter.calls, 1);
    });

    test('two debug bumps produce two counter calls', () async {
      final counter = _FakeCounter();
      final svc = AIService(messageCounter: counter);
      svc.debugBumpMessageCounter();
      svc.debugBumpMessageCounter();
      await Future<void>.delayed(Duration.zero);
      expect(counter.calls, 2);
    });

    test('async rejection in counter does not propagate', () async {
      final counter = _FakeCounter(asyncReject: true);
      final svc = AIService(messageCounter: counter);
      // Must not throw and must not leave the test with an unhandled
      // async error.
      expect(() => svc.debugBumpMessageCounter(), returnsNormally);
      // Let the rejected future settle.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(counter.calls, 1);
    });
  });
}
