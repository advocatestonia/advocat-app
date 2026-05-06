@Tags(['fast'])
library;

// =============================================================================
// CasePhaseService — Phase 2 Pkg 5
// =============================================================================
// Pinned by docs/architecture/phase2-pkg5-state-machine.md §5 + §9 (CPS-T08).
//
// Tests the manual-override path:
//   * setPhase(caseId, phase) calls the `set_case_phase` RPC with the
//     correct args.
//   * Returns CasePhaseTransition with `changed/from/to` reflecting the
//     RPC response.
//   * Tolerates noop responses (RPC returns changed:false, reason:'noop').
//   * Surfaces RPC errors as CasePhaseTransitionError.
// =============================================================================

import 'package:advocat/features/case_memory/models/case_phase.dart';
import 'package:advocat/services/case_phase_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRpc {
  _FakeRpc({Map<String, dynamic>? response, Object? error})
      : _response = response,
        _error = error;

  final Map<String, dynamic>? _response;
  final Object? _error;

  String? lastFnName;
  Map<String, dynamic>? lastParams;
  int callCount = 0;

  Future<Map<String, dynamic>?> call(
    String fnName,
    Map<String, dynamic> params,
  ) async {
    callCount++;
    lastFnName = fnName;
    lastParams = params;
    if (_error != null) throw _error!;
    return _response;
  }
}

void main() {
  group('CasePhaseService.setPhase — happy paths', () {
    test('CPS-T08a — calls set_case_phase RPC with right args', () async {
      final rpc = _FakeRpc(response: {
        'changed': true,
        'from': 'intake',
        'to': 'strategy',
        'phase_entered_at': '2026-05-06T12:00:00.000Z',
      });
      final svc = CasePhaseServiceImpl(rpc: rpc.call);

      final result = await svc.setPhase(
        'case-1',
        CasePhase.strategy,
        metadata: {'reason': 'manual override'},
      );

      expect(rpc.callCount, 1);
      expect(rpc.lastFnName, 'set_case_phase');
      expect(rpc.lastParams!['p_case_id'], 'case-1');
      expect(rpc.lastParams!['p_phase'], 'strategy');
      expect(rpc.lastParams!['p_metadata'], isA<Map<String, dynamic>>());
      expect((rpc.lastParams!['p_metadata'] as Map)['reason'],
          'manual override');

      expect(result.changed, isTrue);
      expect(result.from, CasePhase.intake);
      expect(result.to, CasePhase.strategy);
    });

    test('CPS-T08b — noop response yields changed=false, no error', () async {
      final rpc = _FakeRpc(response: {
        'changed': false,
        'reason': 'noop',
        'phase': 'strategy',
      });
      final svc = CasePhaseServiceImpl(rpc: rpc.call);

      final result = await svc.setPhase('case-2', CasePhase.strategy);
      expect(result.changed, isFalse);
      expect(result.from, isNull);
      expect(result.to, isNull);
      expect(result.reason, 'noop');
    });

    test(
        'CPS-T08c — case_not_found response yields changed=false, '
        'reason=case_not_found', () async {
      final rpc = _FakeRpc(response: {
        'changed': false,
        'reason': 'case_not_found',
      });
      final svc = CasePhaseServiceImpl(rpc: rpc.call);

      final result = await svc.setPhase('missing', CasePhase.draft);
      expect(result.changed, isFalse);
      expect(result.reason, 'case_not_found');
    });

    test('CPS-T08d — defaults metadata to empty map when caller omits it',
        () async {
      final rpc = _FakeRpc(response: {
        'changed': true,
        'from': 'strategy',
        'to': 'draft',
        'phase_entered_at': '2026-05-06T12:00:00.000Z',
      });
      final svc = CasePhaseServiceImpl(rpc: rpc.call);

      await svc.setPhase('c', CasePhase.draft);
      expect(rpc.lastParams!['p_metadata'], <String, dynamic>{});
    });

    test('CPS-T08e — accepts all five phase values without throwing', () async {
      final rpc = _FakeRpc(response: {
        'changed': true,
        'from': 'intake',
        'to': 'closed',
        'phase_entered_at': '2026-05-06T12:00:00.000Z',
      });
      final svc = CasePhaseServiceImpl(rpc: rpc.call);

      for (final phase in CasePhase.values) {
        await svc.setPhase('c', phase);
        expect(rpc.lastParams!['p_phase'], phase.dbValue);
      }
    });
  });

  group('CasePhaseService.setPhase — error paths', () {
    test('CPS-T08f — RPC throw surfaces as CasePhaseException', () async {
      final rpc = _FakeRpc(error: StateError('network down'));
      final svc = CasePhaseServiceImpl(rpc: rpc.call);

      await expectLater(
        () => svc.setPhase('c', CasePhase.strategy),
        throwsA(isA<CasePhaseException>()),
      );
    });

    test('CPS-T08g — null RPC response surfaces as CasePhaseException',
        () async {
      final rpc = _FakeRpc(response: null);
      final svc = CasePhaseServiceImpl(rpc: rpc.call);

      await expectLater(
        () => svc.setPhase('c', CasePhase.strategy),
        throwsA(isA<CasePhaseException>()),
      );
    });
  });
}
