@Tags(['fast'])
library;

// Overnight isolated test suite — DOES NOT modify production code.
// Additional edge-case coverage for AppUser model.
import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/models/user.dart';

void main() {
  group('AppUser overnight edge cases', () {
    test('isSubscriptionActive boundary — exactly at expiration (past)', () {
      final user = AppUser(
        id: 'u1',
        email: 'a@b.c',
        fullName: 'X',
        subscriptionTier: SubscriptionTier.premium,
        // 1 second in the past
        subscriptionExpiresAt:
            DateTime.now().subtract(const Duration(seconds: 1)),
        createdAt: DateTime.utc(2024, 1, 1),
      );
      expect(user.isSubscriptionActive, isFalse);
    });

    test('isSubscriptionActive boundary — far future expiry', () {
      final user = AppUser(
        id: 'u1',
        email: 'a@b.c',
        fullName: 'X',
        subscriptionTier: SubscriptionTier.basic,
        subscriptionExpiresAt: DateTime.utc(2100, 1, 1),
        createdAt: DateTime.utc(2024, 1, 1),
      );
      expect(user.isSubscriptionActive, isTrue);
    });

    test('fromJson handles empty email string', () {
      final json = {
        'id': 'u1',
        'email': '',
        'full_name': 'Tester',
        'created_at': '2024-01-01T00:00:00.000Z',
      };
      final user = AppUser.fromJson(json);
      expect(user.email, '');
      expect(user.preferredLanguage, 'et');
      expect(user.subscriptionTier, SubscriptionTier.free);
    });

    test('fromJson defaults preferredLanguage to "et" when absent', () {
      final user = AppUser.fromJson({
        'id': 'u1',
        'email': 'a@b.c',
        'full_name': 'Tester',
        'created_at': '2024-01-01T00:00:00.000Z',
      });
      expect(user.preferredLanguage, 'et');
    });

    test('fromJson rejects missing required id with TypeError', () {
      expect(
        () => AppUser.fromJson({
          'email': 'a@b.c',
          'created_at': '2024-01-01T00:00:00.000Z',
        }),
        throwsA(isA<TypeError>()),
      );
    });

    test('fromJson rejects malformed date string', () {
      expect(
        () => AppUser.fromJson({
          'id': 'u1',
          'email': 'a@b.c',
          'full_name': 'T',
          'created_at': 'not-a-date',
        }),
        throwsFormatException,
      );
    });

    // is_pro is a DEFAULTED field, NOT a required identity field, so unlike
    // id/created_at it must tolerate a present-but-wrong type rather than
    // crash profile parsing (which would silently drop a Pro user). These
    // lock the lenient coercion in AppUser.fromJson.
    AppUser parseWithIsPro(Object? raw, {String tier = 'premium'}) =>
        AppUser.fromJson({
          'id': 'u1',
          'email': 'a@b.c',
          'full_name': 'T',
          'subscription_tier': tier,
          'is_pro': raw,
          'created_at': '2024-01-01T00:00:00.000Z',
        });

    test('fromJson coerces int is_pro (1/0) without throwing', () {
      expect(parseWithIsPro(1).isPro, isTrue);
      expect(parseWithIsPro(0).isPro, isFalse);
    });

    test('fromJson coerces string is_pro ("true"/"false"/"t"/"f")', () {
      expect(parseWithIsPro('true').isPro, isTrue);
      expect(parseWithIsPro('TRUE').isPro, isTrue);
      expect(parseWithIsPro('t').isPro, isTrue);
      expect(parseWithIsPro('false').isPro, isFalse);
      expect(parseWithIsPro('f').isPro, isFalse);
      expect(parseWithIsPro('0').isPro, isFalse);
    });

    test('fromJson falls back to tier inference for unrecognised is_pro', () {
      // Garbage string on a premium tier → infer Pro from the tier (true),
      // never throw.
      expect(parseWithIsPro('garbage', tier: 'premium').isPro, isTrue);
      expect(parseWithIsPro('garbage', tier: 'free').isPro, isFalse);
    });

    test('fromJson still infers from tier when is_pro is null/absent', () {
      expect(parseWithIsPro(null, tier: 'premium').isPro, isTrue);
      expect(
        AppUser.fromJson({
          'id': 'u1',
          'email': 'a@b.c',
          'full_name': 'T',
          'subscription_tier': 'basic',
          'created_at': '2024-01-01T00:00:00.000Z',
        }).isPro,
        isTrue,
      );
    });

    test('toJson omits optional nulls where expected, keeps keys otherwise',
        () {
      final user = AppUser(
        id: 'u1',
        email: 'a@b.c',
        fullName: 'T',
        createdAt: DateTime.utc(2024, 1, 1),
      );
      final json = user.toJson();
      // Omitted by the conditional spread.
      expect(json.containsKey('avatar_url'), isFalse);
      expect(json.containsKey('gdpr_consent_at'), isFalse);
      // Always included, but may be null.
      expect(json.containsKey('phone'), isTrue);
      expect(json['phone'], isNull);
      expect(json['subscription_expires_at'], isNull);
      expect(json['updated_at'], isNull);
    });

    test('copyWith explicit same values preserves equality of fields', () {
      final a = AppUser(
        id: 'u1',
        email: 'a@b.c',
        fullName: 'T',
        preferredLanguage: 'en',
        subscriptionTier: SubscriptionTier.basic,
        createdAt: DateTime.utc(2024, 1, 1),
      );
      final b = a.copyWith();
      expect(b.id, a.id);
      expect(b.email, a.email);
      expect(b.fullName, a.fullName);
      expect(b.preferredLanguage, a.preferredLanguage);
      expect(b.subscriptionTier, a.subscriptionTier);
      expect(b.createdAt, a.createdAt);
    });

    test('round-trip with premium tier preserves enum value', () {
      final a = AppUser(
        id: 'u1',
        email: 'a@b.c',
        fullName: 'T',
        subscriptionTier: SubscriptionTier.premium,
        subscriptionExpiresAt: DateTime.utc(2030, 6, 15),
        createdAt: DateTime.utc(2024, 1, 1),
      );
      final b = AppUser.fromJson(a.toJson());
      expect(b.subscriptionTier, SubscriptionTier.premium);
      expect(b.subscriptionExpiresAt, a.subscriptionExpiresAt);
    });

    test('SubscriptionTier.values.byName resolves all known values', () {
      expect(SubscriptionTier.values.byName('free'), SubscriptionTier.free);
      expect(SubscriptionTier.values.byName('basic'), SubscriptionTier.basic);
      expect(SubscriptionTier.values.byName('premium'), SubscriptionTier.premium);
    });
  });
}
