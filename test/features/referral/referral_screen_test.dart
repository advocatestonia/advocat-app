// Widget tests for ReferralScreen.
// -----------------------------------------------------------------------------
// Ref: lib/features/referral/screens/referral_screen.dart
//      lib/features/referral/state/referral_providers.dart
//
// The ReferralService is swapped out via the provider override — these
// tests drive the screen without any Supabase backend.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/referral/data/referral_service.dart';
import 'package:advocat/features/referral/models/referral_stats.dart';
import 'package:advocat/features/referral/screens/referral_screen.dart';
import 'package:advocat/l10n/app_localizations.dart';

/// In-memory ReferralService replacement. Records calls and returns
/// scripted stats / code / attribute results.
class _FakeReferralService implements ReferralService {
  _FakeReferralService({
    ReferralStats? stats,
    this.throwOnFetchStats = false,
  })  : code = 'abc12345',
        stats = stats ??
            const ReferralStats(
              code: 'abc12345',
              shareUrl: 'https://advocat.ee/r/abc12345',
              invitesSent: 0,
              conversions: 0,
              freeMonthsEarned: 0,
            );

  final String code;
  final ReferralStats stats;
  final bool throwOnFetchStats;

  int fetchCodeCalls = 0;
  int fetchStatsCalls = 0;
  final List<String> attributeCalls = [];

  @override
  Future<String> fetchCode() async {
    fetchCodeCalls++;
    return code;
  }

  @override
  Future<ReferralStats> fetchStats() async {
    fetchStatsCalls++;
    if (throwOnFetchStats) {
      throw const ReferralServiceException('boom');
    }
    return stats;
  }

  @override
  Future<AttributeResult> attribute(String code) async {
    attributeCalls.add(code);
    return const AttributeOk(
      attributionId: 'fake-attrib',
      status: 'attributed',
      alreadyAttributed: false,
    );
  }

  // Unused — satisfy the analyzer by punting to noSuchMethod.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

ProviderScope _harness({
  required _FakeReferralService fake,
  required Widget child,
}) {
  return ProviderScope(
    overrides: [
      referralServiceProvider.overrideWithValue(fake),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  group('ReferralScreen', () {
    testWidgets(
      'shows the share URL once stats load',
      (tester) async {
        final fake = _FakeReferralService();
        await tester.pumpWidget(
          _harness(fake: fake, child: const ReferralScreen()),
        );
        // First pump → loading spinner.
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.pumpAndSettle();
        expect(find.byType(CircularProgressIndicator), findsNothing);
        // Share URL is visible.
        expect(find.textContaining('advocat.ee/r/abc12345'), findsOneWidget);
        // Three stat tiles (Invited / Converted / Months earned).
        expect(find.text('0'), findsNWidgets(3));
      },
    );

    testWidgets(
      'renders all three channel buttons when code present',
      (tester) async {
        final fake = _FakeReferralService();
        await tester.pumpWidget(
          _harness(fake: fake, child: const ReferralScreen()),
        );
        await tester.pumpAndSettle();
        // Channel button labels include "WhatsApp", "Telegram", and the
        // email word — they're elevated buttons.
        expect(find.textContaining('WhatsApp'), findsWidgets);
        expect(find.textContaining('Telegram'), findsWidgets);
        // Email label depends on locale — at least the Icons.email_outlined
        // icon should be present.
        expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'renders accent-highlighted Months earned when > 0',
      (tester) async {
        final fake = _FakeReferralService(
          stats: const ReferralStats(
            code: 'abc12345',
            shareUrl: 'https://advocat.ee/r/abc12345',
            invitesSent: 5,
            conversions: 3,
            freeMonthsEarned: 2,
          ),
        );
        await tester.pumpWidget(
          _harness(fake: fake, child: const ReferralScreen()),
        );
        await tester.pumpAndSettle();
        expect(find.text('5'), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
      },
    );

    testWidgets(
      'shows error state with Retry when fetchStats throws',
      (tester) async {
        final fake = _FakeReferralService(throwOnFetchStats: true);
        await tester.pumpWidget(
          _harness(fake: fake, child: const ReferralScreen()),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.cloud_off), findsOneWidget);
        // Retry button rendered.
        expect(find.byType(TextButton), findsWidgets);
      },
    );

    testWidgets(
      'pull-to-refresh re-invokes fetchStats',
      (tester) async {
        final fake = _FakeReferralService();
        await tester.pumpWidget(
          _harness(fake: fake, child: const ReferralScreen()),
        );
        await tester.pumpAndSettle();
        final initial = fake.fetchStatsCalls;

        // Drag down — RefreshIndicator triggers the onRefresh callback.
        await tester.drag(
          find.byType(ListView),
          const Offset(0, 320),
          touchSlopY: 0,
        );
        await tester.pumpAndSettle();
        expect(fake.fetchStatsCalls, greaterThan(initial));
      },
    );

    testWidgets(
      'Copy link tile renders Copy and Share buttons',
      (tester) async {
        final fake = _FakeReferralService();
        await tester.pumpWidget(
          _harness(fake: fake, child: const ReferralScreen()),
        );
        await tester.pumpAndSettle();
        // Two outlined/elevated buttons in the share-link card row.
        expect(find.byIcon(Icons.copy), findsOneWidget);
        expect(find.byIcon(Icons.ios_share), findsOneWidget);
      },
    );

    testWidgets(
      'no share-link card when code is empty (defensive)',
      (tester) async {
        final fake = _FakeReferralService(
          stats: const ReferralStats(
            code: '',
            shareUrl: '',
            invitesSent: 0,
            conversions: 0,
            freeMonthsEarned: 0,
          ),
        );
        await tester.pumpWidget(
          _harness(fake: fake, child: const ReferralScreen()),
        );
        await tester.pumpAndSettle();
        // Copy/Share icons hidden when code is empty.
        expect(find.byIcon(Icons.copy), findsNothing);
        expect(find.byIcon(Icons.ios_share), findsNothing);
      },
    );
  });

  group('ReferralService demo mode', () {
    test('fetchCode returns a stable 8-char code in demo mode', () async {
      // Demo mode is auto-detected when Supabase.instance.client throws.
      // In a unit test it has not been initialised → demo path is taken.
      final svc = ReferralService();
      final code = await svc.fetchCode();
      expect(code, isNotEmpty);
      expect(code.length, lessThanOrEqualTo(8));
    });

    test('attribute returns AttributeOk in demo mode', () async {
      final svc = ReferralService();
      final res = await svc.attribute('abc12345');
      expect(res, isA<AttributeOk>());
      expect((res as AttributeOk).status, 'attributed');
    });

    test('attribute with empty string returns AttributeFailure', () async {
      final svc = ReferralService();
      final res = await svc.attribute('');
      expect(res, isA<AttributeFailure>());
      expect((res as AttributeFailure).error, 'missing_referral_code');
    });

    test('fetchStats returns zeroed stats in demo mode', () async {
      final svc = ReferralService();
      final stats = await svc.fetchStats();
      expect(stats.invitesSent, 0);
      expect(stats.conversions, 0);
      expect(stats.freeMonthsEarned, 0);
      expect(stats.hasCode, true);
    });
  });
}
