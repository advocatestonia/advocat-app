// =============================================================================
// Cost & Risk Estimator provider tests (Feature #6)
// =============================================================================
//
// Validates the pure logic of CostEstimatorNotifier and its model mappers:
//   • parseDisputeAmount() free-text → int|null
//   • EstimateBand / CaseEstimate.fromApi mapping + strength enum coercion
//   • state machine (idle → loading → result / error) with a fake client
//   • validation (empty case type) + null-client offline guard
//
// No network: a FakeCostEstimatorClient stands in for the edge function.

import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/features/cost_estimator/providers/cost_estimator_provider.dart';

class _FakeClient implements CostEstimatorClient {
  _FakeClient(this.response, {this.throwError = false});
  final Map<String, dynamic>? response;
  final bool throwError;

  Map<String, dynamic>? lastBody;

  @override
  Future<Map<String, dynamic>?> estimate({
    required String caseType,
    required String jurisdiction,
    int? disputeAmountEur,
    required String description,
    required bool b2bMode,
  }) async {
    lastBody = {
      'case_type': caseType,
      'jurisdiction': jurisdiction,
      'dispute_amount_eur': disputeAmountEur,
      'description': description,
      'b2b_mode': b2bMode,
    };
    if (throwError) throw Exception('boom');
    return response;
  }
}

Map<String, dynamic> _sampleApi() => {
      'estimate': {
        'courtFee': {'low': 300, 'high': 800},
        'lawyerFee': {'low': 2000, 'high': 4000},
        'total': {'low': 2300, 'high': 4800},
        'durationMonths': {'low': 4, 'high': 12},
        'strength': 'worth_pursuing',
        'factorsFor': ['written contract', 'clear deadline'],
        'factorsAgainst': ['defendant insolvent'],
        'recommendation': 'A claim looks viable.',
        'nextStep': 'Open a case to draft the claim',
      },
      'estimate_id': 'abc-123',
    };

void main() {
  group('parseDisputeAmount', () {
    test('empty → null', () {
      expect(parseDisputeAmount(''), isNull);
      expect(parseDisputeAmount('   '), isNull);
      expect(parseDisputeAmount('abc'), isNull);
    });

    test('strips currency symbols and separators', () {
      expect(parseDisputeAmount('€12,500'), 12500);
      expect(parseDisputeAmount('12 500'), 12500);
      expect(parseDisputeAmount('5000.75'), 5001);
    });

    test('plain integer', () {
      expect(parseDisputeAmount('42'), 42);
    });
  });

  group('EstimateBand.fromApi', () {
    test('maps map values', () {
      final b = EstimateBand.fromApi({'low': 10, 'high': 20});
      expect(b.low, 10);
      expect(b.high, 20);
      expect(b.isZero, isFalse);
    });

    test('defaults to zero band on bad input', () {
      final b = EstimateBand.fromApi('nope');
      expect(b.isZero, isTrue);
    });

    test('coerces numeric strings and doubles', () {
      final b = EstimateBand.fromApi({'low': '100', 'high': 250.6});
      expect(b.low, 100);
      expect(b.high, 251);
    });
  });

  group('CaseEstimate.fromApi', () {
    test('maps a full payload', () {
      final e = CaseEstimate.fromApi(_sampleApi());
      expect(e.courtFee.high, 800);
      expect(e.lawyerFee.low, 2000);
      expect(e.total.high, 4800);
      expect(e.durationMonths.high, 12);
      expect(e.strength, CaseStrength.worthPursuing);
      expect(e.factorsFor, contains('written contract'));
      expect(e.factorsAgainst, contains('defendant insolvent'));
      expect(e.recommendation, 'A claim looks viable.');
      expect(e.nextStep, 'Open a case to draft the claim');
      expect(e.estimateId, 'abc-123');
    });

    test('unknown strength falls back to contested', () {
      final e = CaseEstimate.fromApi({
        'estimate': {'strength': 'definitely_winning'},
      });
      expect(e.strength, CaseStrength.contested);
    });

    test('maps each known strength value', () {
      expect(
        CaseEstimate.fromApi({'estimate': {'strength': 'weak'}}).strength,
        CaseStrength.weak,
      );
      expect(
        CaseEstimate.fromApi({'estimate': {'strength': 'contested'}}).strength,
        CaseStrength.contested,
      );
    });

    test('filters empty / non-string factors', () {
      final e = CaseEstimate.fromApi({
        'estimate': {
          'factorsFor': ['ok', '', 42, '  trimmed  '],
        },
      });
      expect(e.factorsFor, ['ok', 'trimmed']);
    });
  });

  group('CostEstimatorState', () {
    test('canSubmit requires non-empty case type and not loading', () {
      expect(const CostEstimatorState().canSubmit, isFalse);
      expect(
        const CostEstimatorState(caseType: 'debt').canSubmit,
        isTrue,
      );
      expect(
        const CostEstimatorState(caseType: 'debt', isLoading: true).canSubmit,
        isFalse,
      );
    });

    test('copyWith clear flags reset estimate and error', () {
      final e = CaseEstimate.fromApi(_sampleApi());
      final s = CostEstimatorState(estimate: e, errorMessage: 'x');
      final cleared = s.copyWith(clearEstimate: true, clearError: true);
      expect(cleared.estimate, isNull);
      expect(cleared.errorMessage, isNull);
    });
  });

  group('CostEstimatorNotifier', () {
    test('empty case type → validation error, no client call', () async {
      final client = _FakeClient(_sampleApi());
      final n = CostEstimatorNotifier(client: client);
      await n.submit();
      expect(n.state.errorMessage, isNotNull);
      expect(n.state.estimate, isNull);
      expect(client.lastBody, isNull);
    });

    test('happy path produces an estimate', () async {
      final client = _FakeClient(_sampleApi());
      final n = CostEstimatorNotifier(client: client);
      n.setCaseType('Unpaid invoice');
      n.setJurisdiction('FI');
      n.setDisputeAmount('€12,500');
      n.setB2bMode(true);
      await n.submit();

      expect(n.state.isLoading, isFalse);
      expect(n.state.errorMessage, isNull);
      expect(n.state.estimate, isNotNull);
      expect(n.state.estimate!.strength, CaseStrength.worthPursuing);
      // Amount parsed + forwarded to the client.
      expect(client.lastBody!['dispute_amount_eur'], 12500);
      expect(client.lastBody!['jurisdiction'], 'FI');
      expect(client.lastBody!['b2b_mode'], true);
    });

    test('null response → offline error', () async {
      final client = _FakeClient(null);
      final n = CostEstimatorNotifier(client: client);
      n.setCaseType('x');
      await n.submit();
      expect(n.state.estimate, isNull);
      expect(n.state.errorMessage, isNotNull);
    });

    test('error field in response surfaces message', () async {
      final client = _FakeClient({'error': 'rate limited'});
      final n = CostEstimatorNotifier(client: client);
      n.setCaseType('x');
      await n.submit();
      expect(n.state.errorMessage, 'rate limited');
    });

    test('thrown exception → network error', () async {
      final client = _FakeClient(_sampleApi(), throwError: true);
      final n = CostEstimatorNotifier(client: client);
      n.setCaseType('x');
      await n.submit();
      expect(n.state.errorMessage, contains('Network error'));
    });

    test('null client (offline) → guard error', () async {
      final n = CostEstimatorNotifier();
      n.setCaseType('x');
      await n.submit();
      expect(n.state.errorMessage, contains('offline'));
    });

    test('reset clears estimate and error', () async {
      final client = _FakeClient(_sampleApi());
      final n = CostEstimatorNotifier(client: client);
      n.setCaseType('x');
      await n.submit();
      expect(n.state.estimate, isNotNull);
      n.reset();
      expect(n.state.estimate, isNull);
    });
  });
}
