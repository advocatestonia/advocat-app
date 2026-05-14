// Unit tests for the referral nudge gating logic.
// -----------------------------------------------------------------------------
// Ref: lib/features/referral/referral_nudge.dart
//
// The decision function is pure — no provider/widget surface needed.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:advocat/features/referral/referral_nudge.dart';

void main() {
  group('shouldShowReferralNudge', () {
    final now = DateTime.utc(2026, 5, 11, 12, 0);

    test('returns false when firstChatAt is null', () {
      expect(
        shouldShowReferralNudge(now: now, firstChatAt: null),
        isFalse,
      );
    });

    test('returns false when referralSeen is already true', () {
      expect(
        shouldShowReferralNudge(
          now: now,
          firstChatAt: now.subtract(const Duration(days: 2)),
          accountCreatedAt: now.subtract(const Duration(days: 3)),
          referralSeen: true,
        ),
        isFalse,
      );
    });

    test('returns false when the nudge has already been shown', () {
      expect(
        shouldShowReferralNudge(
          now: now,
          firstChatAt: now.subtract(const Duration(days: 2)),
          accountCreatedAt: now.subtract(const Duration(days: 3)),
          nudgeAlreadyShown: true,
        ),
        isFalse,
      );
    });

    test('returns false when account is < 24h old', () {
      expect(
        shouldShowReferralNudge(
          now: now,
          firstChatAt: now.subtract(const Duration(hours: 12)),
          accountCreatedAt: now.subtract(const Duration(hours: 6)),
        ),
        isFalse,
      );
    });

    test('returns true when all gates open', () {
      expect(
        shouldShowReferralNudge(
          now: now,
          firstChatAt: now.subtract(const Duration(days: 2)),
          accountCreatedAt: now.subtract(const Duration(days: 3)),
        ),
        isTrue,
      );
    });

    test(
      'falls back to firstChatAt as account-age proxy when account is unknown',
      () {
        expect(
          shouldShowReferralNudge(
            now: now,
            // 25h ago — passes the 24h check via the fallback.
            firstChatAt: now.subtract(const Duration(hours: 25)),
            accountCreatedAt: null,
          ),
          isTrue,
        );
      },
    );
  });

  group('markFirstChatTimestamp', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('writes a timestamp on first call', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kFirstChatAtPrefKey), isNull);
      await markFirstChatTimestamp(prefs: prefs);
      final stored = prefs.getString(kFirstChatAtPrefKey);
      expect(stored, isNotNull);
      // Round-trips through DateTime.parse.
      expect(DateTime.tryParse(stored!), isNotNull);
    });

    test('is idempotent — second call does not overwrite', () async {
      final prefs = await SharedPreferences.getInstance();
      await markFirstChatTimestamp(prefs: prefs);
      final first = prefs.getString(kFirstChatAtPrefKey);
      // Wait long enough that any rewrite would produce a new ISO value.
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await markFirstChatTimestamp(prefs: prefs);
      final second = prefs.getString(kFirstChatAtPrefKey);
      expect(second, first);
    });
  });
}
