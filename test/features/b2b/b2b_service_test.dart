@Tags(['fast'])
library;

// Unit tests for [B2BService] in demo mode (no Supabase).
//
// In demo mode:
//   * fetchB2BModalPending returns false (so nothing fires for demo users)
//   * markB2BModalShown is a no-op
//   * submitInquiry short-circuits with a synthetic ok ticket id

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/b2b/services/b2b_service.dart';
import 'package:advocat/services/supabase_service.dart';

void main() {
  group('B2BService — demo mode', () {
    late B2BService service;

    setUp(() {
      // No Supabase.initialize() in tests → SupabaseService.isDemo == true.
      service = B2BService(SupabaseService());
    });

    test('fetchB2BModalPending returns false in demo mode', () async {
      final pending = await service.fetchB2BModalPending();
      expect(pending, isFalse);
    });

    test('markB2BModalShown is a no-op in demo mode', () async {
      // Just ensure it doesn't throw.
      await service.markB2BModalShown();
    });

    test('submitInquiry returns synthetic ok in demo mode', () async {
      final result = await service.submitInquiry(
        name: 'Anna',
        email: 'anna@kovacic-legal.ee',
        firmName: 'Kovacic Legal',
        teamSize: '2-5',
        practices: ['immigration', 'family'],
        biggestPainToday: 'Sharing case history across the team.',
      );

      expect(result.success, isTrue);
      expect(result.ticketId, isNotNull);
      expect(result.errorReason, isNull);
    });
  });

  group('B2BInquiryResult', () {
    test('ok constructor flags success and clears errorReason', () {
      const r = B2BInquiryResult.ok('abc');
      expect(r.success, isTrue);
      expect(r.ticketId, 'abc');
      expect(r.errorReason, isNull);
    });

    test('error constructor flags failure and clears ticketId', () {
      const r = B2BInquiryResult.error('network');
      expect(r.success, isFalse);
      expect(r.ticketId, isNull);
      expect(r.errorReason, 'network');
    });
  });
}
