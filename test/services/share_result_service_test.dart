@Tags(['fast'])
library;

// Tests for [ShareResultPayload] — pure payload shaping + UUID validation
// for the Share-this-analysis flow.
//
// The Supabase round-trip is exercised by the deno _tests pack for
// share-result and (when canary smoke runs) the deployed edge function.
// These tests fit the fast / pre-commit budget — no network, no Supabase.

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/share_result_service.dart';

void main() {
  const goodUuid = '11111111-1111-1111-1111-111111111111';

  group('ShareResultPayload.isValidSourceId', () {
    test('accepts a well-formed lowercase UUID', () {
      expect(ShareResultPayload.isValidSourceId(goodUuid), isTrue);
    });
    test('accepts a well-formed uppercase UUID', () {
      expect(
        ShareResultPayload.isValidSourceId(goodUuid.toUpperCase()),
        isTrue,
      );
    });
    test('rejects null and empty', () {
      expect(ShareResultPayload.isValidSourceId(null), isFalse);
      expect(ShareResultPayload.isValidSourceId(''), isFalse);
    });
    test('rejects synthetic chat-stream id', () {
      expect(
        ShareResultPayload.isValidSourceId('ai_stream_1699999999000'),
        isFalse,
      );
    });
    test('rejects almost-UUID with wrong dash positions', () {
      expect(
        ShareResultPayload.isValidSourceId('11111111-1111-11111-111-111111111111'),
        isFalse,
      );
    });
    test('rejects path-injection attempt', () {
      expect(
        ShareResultPayload.isValidSourceId('../../../etc/passwd'),
        isFalse,
      );
    });
  });

  group('ShareResultPayload.buildPayload', () {
    test('emits wire-format source_type for contract_review', () {
      final p = ShareResultPayload.buildPayload(
        sourceType: ShareSourceType.contractReview,
        sourceId: goodUuid,
      );
      expect(p['source_type'], 'contract_review');
      expect(p['source_id'], goodUuid);
    });
    test('emits wire-format source_type for legal_advice', () {
      final p = ShareResultPayload.buildPayload(
        sourceType: ShareSourceType.legalAdvice,
        sourceId: goodUuid,
      );
      expect(p['source_type'], 'legal_advice');
    });
    test('emits wire-format source_type for deadline_analysis', () {
      final p = ShareResultPayload.buildPayload(
        sourceType: ShareSourceType.deadlineAnalysis,
        sourceId: goodUuid,
      );
      expect(p['source_type'], 'deadline_analysis');
    });
    test('throws ArgumentError on invalid UUID', () {
      expect(
        () => ShareResultPayload.buildPayload(
          sourceType: ShareSourceType.legalAdvice,
          sourceId: 'not-a-uuid',
        ),
        throwsArgumentError,
      );
    });
    test('emits only the two wire keys (no smuggled fields)', () {
      final p = ShareResultPayload.buildPayload(
        sourceType: ShareSourceType.contractReview,
        sourceId: goodUuid,
      );
      expect(p.keys.toSet(), {'source_type', 'source_id'});
    });
  });

  group('ShareSourceTypeWire', () {
    test('round-trips between enum and wire slug', () {
      final pairs = {
        ShareSourceType.contractReview: 'contract_review',
        ShareSourceType.legalAdvice: 'legal_advice',
        ShareSourceType.deadlineAnalysis: 'deadline_analysis',
      };
      for (final entry in pairs.entries) {
        expect(entry.key.wireValue, entry.value);
      }
    });
  });
}
