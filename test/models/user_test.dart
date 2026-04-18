import 'package:advocat/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  group('AppUser', () {
    // ── fromJson ──────────────────────────────────────────────────────────

    group('fromJson', () {
      test('parses a complete JSON map', () {
        final json = makeUserJson(
          id: 'u-1',
          email: 'john@example.com',
          fullName: 'John Doe',
          phone: '+372 555 1234',
          avatarUrl: 'https://example.com/avatar.png',
          preferredLanguage: 'fi',
          subscriptionTier: 'premium',
          subscriptionExpiresAt: fixtureFuture.toIso8601String(),
          createdAt: fixtureNow.toIso8601String(),
          updatedAt: fixtureNow.toIso8601String(),
          gdprConsentAt: fixtureNow.toIso8601String(),
        );

        final user = AppUser.fromJson(json);

        expect(user.id, 'u-1');
        expect(user.email, 'john@example.com');
        expect(user.fullName, 'John Doe');
        expect(user.phone, '+372 555 1234');
        expect(user.avatarUrl, 'https://example.com/avatar.png');
        expect(user.preferredLanguage, 'fi');
        expect(user.subscriptionTier, SubscriptionTier.premium);
        expect(user.subscriptionExpiresAt, fixtureFuture);
        expect(user.createdAt, fixtureNow);
        expect(user.updatedAt, fixtureNow);
        expect(user.gdprConsentAt, fixtureNow);
      });

      test('applies defaults for missing optional fields', () {
        final json = {
          'id': 'u-2',
          'created_at': fixtureNow.toIso8601String(),
        };

        final user = AppUser.fromJson(json);

        expect(user.email, '');
        expect(user.fullName, '');
        expect(user.phone, isNull);
        expect(user.avatarUrl, isNull);
        expect(user.preferredLanguage, 'et');
        expect(user.subscriptionTier, SubscriptionTier.free);
        expect(user.subscriptionExpiresAt, isNull);
        expect(user.updatedAt, isNull);
        expect(user.gdprConsentAt, isNull);
      });

      test('maps unknown subscription_tier to free', () {
        final json = makeUserJson(subscriptionTier: 'enterprise');
        final user = AppUser.fromJson(json);
        expect(user.subscriptionTier, SubscriptionTier.free);
      });

      test('maps null subscription_tier to free', () {
        final json = makeUserJson();
        json['subscription_tier'] = null;
        final user = AppUser.fromJson(json);
        expect(user.subscriptionTier, SubscriptionTier.free);
      });
    });

    // ── toJson ────────────────────────────────────────────────────────────

    group('toJson', () {
      test('serialises all fields', () {
        final user = makeUser(
          id: 'u-1',
          email: 'a@b.com',
          fullName: 'Alice',
          phone: '+1',
          avatarUrl: 'https://img.png',
          preferredLanguage: 'ru',
          subscriptionTier: SubscriptionTier.basic,
          subscriptionExpiresAt: fixtureFuture,
          createdAt: fixtureNow,
          updatedAt: fixtureNow,
          gdprConsentAt: fixtureNow,
        );

        final json = user.toJson();

        expect(json['id'], 'u-1');
        expect(json['email'], 'a@b.com');
        expect(json['full_name'], 'Alice');
        expect(json['phone'], '+1');
        expect(json['avatar_url'], 'https://img.png');
        expect(json['preferred_language'], 'ru');
        expect(json['subscription_tier'], 'basic');
        expect(json['subscription_expires_at'], fixtureFuture.toIso8601String());
        expect(json['created_at'], fixtureNow.toIso8601String());
        expect(json['updated_at'], fixtureNow.toIso8601String());
        expect(json['gdpr_consent_at'], fixtureNow.toIso8601String());
      });

      test('omits avatar_url when null', () {
        final user = makeUser(avatarUrl: null);
        final json = user.toJson();
        expect(json.containsKey('avatar_url'), isFalse);
      });

      test('omits gdpr_consent_at when null', () {
        final user = makeUser(gdprConsentAt: null);
        final json = user.toJson();
        expect(json.containsKey('gdpr_consent_at'), isFalse);
      });
    });

    // ── fromJson / toJson round-trip ──────────────────────────────────────

    test('round-trip: fromJson(toJson(user)) preserves data', () {
      final original = makeUser(
        id: 'round-trip',
        email: 'rt@test.ee',
        fullName: 'RT User',
        preferredLanguage: 'fi',
        subscriptionTier: SubscriptionTier.premium,
        subscriptionExpiresAt: fixtureFuture,
        createdAt: fixtureNow,
        updatedAt: fixtureNow,
      );

      final restored = AppUser.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.email, original.email);
      expect(restored.fullName, original.fullName);
      expect(restored.preferredLanguage, original.preferredLanguage);
      expect(restored.subscriptionTier, original.subscriptionTier);
      expect(restored.subscriptionExpiresAt, original.subscriptionExpiresAt);
      expect(restored.createdAt, original.createdAt);
    });

    // ── copyWith ──────────────────────────────────────────────────────────

    group('copyWith', () {
      test('copies with changed fields', () {
        final user = makeUser();
        final copy = user.copyWith(
          email: 'new@email.com',
          subscriptionTier: SubscriptionTier.premium,
        );

        expect(copy.email, 'new@email.com');
        expect(copy.subscriptionTier, SubscriptionTier.premium);
        // Unchanged fields
        expect(copy.id, user.id);
        expect(copy.fullName, user.fullName);
      });

      test('copies with no changes returns equivalent object', () {
        final user = makeUser();
        final copy = user.copyWith();
        expect(copy.id, user.id);
        expect(copy.email, user.email);
        expect(copy.fullName, user.fullName);
      });
    });

    // ── isSubscriptionActive ──────────────────────────────────────────────

    group('isSubscriptionActive', () {
      test('returns false for free tier', () {
        final user = makeUser(subscriptionTier: SubscriptionTier.free);
        expect(user.isSubscriptionActive, isFalse);
      });

      test('returns true for basic tier with no expiry', () {
        final user = makeUser(
          subscriptionTier: SubscriptionTier.basic,
          subscriptionExpiresAt: null,
        );
        expect(user.isSubscriptionActive, isTrue);
      });

      test('returns true for premium tier with future expiry', () {
        final user = makeUser(
          subscriptionTier: SubscriptionTier.premium,
          subscriptionExpiresAt: DateTime.now().add(const Duration(days: 30)),
        );
        expect(user.isSubscriptionActive, isTrue);
      });

      test('returns false for basic tier with past expiry', () {
        final user = makeUser(
          subscriptionTier: SubscriptionTier.basic,
          subscriptionExpiresAt: DateTime.now().subtract(const Duration(days: 1)),
        );
        expect(user.isSubscriptionActive, isFalse);
      });

      test('returns false for premium tier with past expiry', () {
        final user = makeUser(
          subscriptionTier: SubscriptionTier.premium,
          subscriptionExpiresAt: fixturePast,
        );
        expect(user.isSubscriptionActive, isFalse);
      });
    });

    // ── SubscriptionTier enum ────────────────────────────────────────────

    group('SubscriptionTier', () {
      test('has exactly 3 values', () {
        expect(SubscriptionTier.values.length, 3);
      });

      test('contains free, basic, premium', () {
        expect(
          SubscriptionTier.values,
          containsAll([
            SubscriptionTier.free,
            SubscriptionTier.basic,
            SubscriptionTier.premium,
          ]),
        );
      });
    });

    // ── Default values ───────────────────────────────────────────────────

    group('default values', () {
      test('constructor defaults', () {
        final user = AppUser(
          id: 'def',
          email: 'def@test.ee',
          fullName: 'Default',
          createdAt: fixtureNow,
        );
        expect(user.preferredLanguage, 'en');
        expect(user.subscriptionTier, SubscriptionTier.free);
        expect(user.subscriptionExpiresAt, isNull);
        expect(user.phone, isNull);
        expect(user.avatarUrl, isNull);
        expect(user.updatedAt, isNull);
        expect(user.gdprConsentAt, isNull);
      });
    });
  });
}
