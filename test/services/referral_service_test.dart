// Unit tests for ReferralService — the demo-mode (no-Supabase) path that
// also drives the public landing.
//
// The class is under lib/features/referral/data/ but the spec asks for a
// service-level test at test/services/. This file lives at the canonical
// services-tests path so the spec's `flutter test test/services/
// referral_service_test.dart` invocation finds it.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/referral/data/referral_service.dart';
import 'package:advocat/features/referral/models/referral_stats.dart';

void main() {
  group('ReferralService (demo mode — no Supabase)', () {
    test('fetchCode produces a non-empty 8-char alphanumeric code', () async {
      final svc = ReferralService();
      final code = await svc.fetchCode();
      expect(code, isNotEmpty);
      expect(code.length, inInclusiveRange(1, 8));
    });

    test('fetchStats returns a zeroed ReferralStats with code present',
        () async {
      final svc = ReferralService();
      final stats = await svc.fetchStats();
      expect(stats, isA<ReferralStats>());
      expect(stats.invitesSent, 0);
      expect(stats.conversions, 0);
      expect(stats.freeMonthsEarned, 0);
      expect(stats.hasCode, isTrue);
      expect(stats.shareUrl, contains('advocat.ee/r/'));
      expect(stats.recentActivity, isEmpty);
    });

    test('attribute("") returns AttributeFailure missing_referral_code',
        () async {
      final svc = ReferralService();
      final res = await svc.attribute('');
      expect(res, isA<AttributeFailure>());
      expect((res as AttributeFailure).error, 'missing_referral_code');
    });

    test('attribute(code) returns AttributeOk in demo mode', () async {
      final svc = ReferralService();
      final res = await svc.attribute('abc12345');
      expect(res, isA<AttributeOk>());
      final ok = res as AttributeOk;
      expect(ok.status, 'attributed');
      expect(ok.alreadyAttributed, isFalse);
    });

    test('lookupCode returns CodeLookupOk with a name in demo mode',
        () async {
      final svc = ReferralService();
      final res = await svc.lookupCode('abc12345');
      expect(res, isA<CodeLookupOk>());
      final ok = res as CodeLookupOk;
      expect(ok.inviterFirstName, isNotNull);
      expect(ok.inviterFirstName, isNotEmpty);
    });

    test('lookupCode("") returns CodeLookupInvalid', () async {
      final svc = ReferralService();
      final res = await svc.lookupCode('');
      expect(res, isA<CodeLookupInvalid>());
    });
  });

  group('ReferralStats model', () {
    test('hasCode mirrors code.isNotEmpty', () {
      const empty = ReferralStats(
        code: '',
        shareUrl: '',
        invitesSent: 0,
        conversions: 0,
        freeMonthsEarned: 0,
      );
      const filled = ReferralStats(
        code: 'abc12345',
        shareUrl: 'https://advocat.ee/r/abc12345',
        invitesSent: 0,
        conversions: 0,
        freeMonthsEarned: 0,
      );
      expect(empty.hasCode, isFalse);
      expect(filled.hasCode, isTrue);
    });

    test('hasActivity mirrors recentActivity.isNotEmpty', () {
      final withActivity = ReferralStats(
        code: 'abc12345',
        shareUrl: 'https://advocat.ee/r/abc12345',
        invitesSent: 1,
        conversions: 0,
        freeMonthsEarned: 0,
        recentActivity: [
          ReferralActivity(invitedAt: DateTime.utc(2026, 5, 1)),
        ],
      );
      expect(withActivity.hasActivity, isTrue);
    });

    test('ReferralActivity.fromJson is tolerant to junk', () {
      expect(ReferralActivity.fromJson(null), isNull);
      expect(ReferralActivity.fromJson(42), isNull);
      expect(ReferralActivity.fromJson(<String, dynamic>{}), isNull);
    });
  });
}
