@Tags(['fast'])
library;

// Tests for AppUser.isPro / isProActive — the unified frontend Pro detection.
// Single source of truth: profiles.is_pro boolean column.
//
// Mirrors what the server's check-ai-quota Edge Function does so the
// frontend and backend agree on who has Pro access.

import 'package:advocat/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUser.isProActive', () {
    final now = DateTime.now();
    final past = now.subtract(const Duration(days: 1));
    final future = now.add(const Duration(days: 30));

    AppUser build({
      required bool isPro,
      DateTime? expiresAt,
      SubscriptionTier tier = SubscriptionTier.premium,
    }) {
      return AppUser(
        id: 'u-1',
        email: 'a@b.c',
        fullName: 'X',
        isPro: isPro,
        subscriptionTier: tier,
        subscriptionExpiresAt: expiresAt,
        createdAt: DateTime.utc(2024, 1, 1),
      );
    }

    test('is_pro=false → isProActive=false', () {
      final user = build(isPro: false, expiresAt: future);
      expect(user.isProActive, isFalse);
    });

    test('is_pro=true, expiresAt=null → isProActive=false', () {
      final user = build(isPro: true, expiresAt: null);
      expect(user.isProActive, isFalse);
    });

    test('is_pro=true, expiresAt past → isProActive=false', () {
      final user = build(isPro: true, expiresAt: past);
      expect(user.isProActive, isFalse);
    });

    test('is_pro=true, expiresAt future → isProActive=true', () {
      final user = build(isPro: true, expiresAt: future);
      expect(user.isProActive, isTrue);
    });

    test('isProActive ignores subscriptionTier — basic + is_pro=true is Pro',
        () {
      // Tier is for UI labelling only; access decisions key off is_pro.
      final user = build(
        isPro: true,
        expiresAt: future,
        tier: SubscriptionTier.basic,
      );
      expect(user.isProActive, isTrue);
    });

    test('isProActive false when is_pro=false even with premium tier', () {
      // Defends the bug we just fixed: tier could disagree with is_pro.
      // is_pro is authoritative.
      final user = build(
        isPro: false,
        expiresAt: future,
        tier: SubscriptionTier.premium,
      );
      expect(user.isProActive, isFalse);
    });
  });

  group('AppUser JSON parsing of is_pro', () {
    Map<String, dynamic> baseJson({
      bool includeIsPro = true,
      bool isPro = true,
      String tier = 'premium',
    }) {
      return <String, dynamic>{
        'id': 'u-1',
        'email': 'a@b.c',
        'full_name': 'Sofia',
        'preferred_language': 'et',
        'subscription_tier': tier,
        'subscription_expires_at': '2027-01-01T00:00:00.000Z',
        'created_at': '2024-01-01T00:00:00.000Z',
        if (includeIsPro) 'is_pro': isPro,
      };
    }

    test('parses {"is_pro": true, ...} round-trip', () {
      final json = baseJson(includeIsPro: true, isPro: true);
      final user = AppUser.fromJson(json);

      expect(user.isPro, isTrue);
      expect(user.subscriptionTier, SubscriptionTier.premium);
      expect(user.subscriptionExpiresAt, DateTime.utc(2027, 1, 1));

      final restored = AppUser.fromJson(user.toJson());
      expect(restored.isPro, isTrue);
      expect(restored.toJson()['is_pro'], isTrue);
    });

    test('parses {"is_pro": false, ...} explicitly false', () {
      final json = baseJson(includeIsPro: true, isPro: false, tier: 'free');
      final user = AppUser.fromJson(json);
      expect(user.isPro, isFalse);
    });

    test('backwards-compat: missing is_pro infers from tier=free → false', () {
      final json = baseJson(includeIsPro: false, tier: 'free');
      final user = AppUser.fromJson(json);
      expect(user.isPro, isFalse);
    });

    test('backwards-compat: missing is_pro infers from tier=basic → true', () {
      final json = baseJson(includeIsPro: false, tier: 'basic');
      final user = AppUser.fromJson(json);
      expect(user.isPro, isTrue);
    });

    test('backwards-compat: missing is_pro infers from tier=premium → true',
        () {
      final json = baseJson(includeIsPro: false, tier: 'premium');
      final user = AppUser.fromJson(json);
      expect(user.isPro, isTrue);
    });

    test('toJson always emits is_pro key', () {
      final user = AppUser(
        id: 'u-1',
        email: 'a@b.c',
        fullName: 'X',
        isPro: true,
        subscriptionTier: SubscriptionTier.basic,
        subscriptionExpiresAt: DateTime.utc(2030, 1, 1),
        createdAt: DateTime.utc(2024, 1, 1),
      );
      final json = user.toJson();
      expect(json.containsKey('is_pro'), isTrue);
      expect(json['is_pro'], isTrue);
    });
  });

  group('AppUser.copyWith honours isPro', () {
    test('copyWith(isPro: true) flips the flag', () {
      final user = AppUser(
        id: 'u-1',
        email: 'a@b.c',
        fullName: 'X',
        createdAt: DateTime.utc(2024, 1, 1),
      );
      expect(user.isPro, isFalse);
      final upgraded = user.copyWith(isPro: true);
      expect(upgraded.isPro, isTrue);
      // Other fields preserved.
      expect(upgraded.id, user.id);
      expect(upgraded.email, user.email);
    });
  });
}
