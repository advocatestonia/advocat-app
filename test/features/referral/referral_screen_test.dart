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

  @override
  Future<CodeLookupResult> lookupCode(String code) async {
    return const CodeLookupOk(inviterFirstName: 'TestUser');
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
        // Both the tile and the copy line render the same numbers, so we
        // get more than one match per integer.
        expect(find.text('5'), findsWidgets);
        expect(find.text('3'), findsWidgets);
        expect(find.text('2'), findsWidgets);
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

    testWidgets(
      'shows anti-fraud footnote on every render',
      (tester) async {
        // Tall viewport so the bottom-of-list footnote paints.
        await tester.binding.setSurfaceSize(const Size(800, 2400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final fake = _FakeReferralService();
        await tester.pumpWidget(
          _harness(fake: fake, child: const ReferralScreen()),
        );
        await tester.pumpAndSettle();
        // English string from app_en.arb.
        expect(
          find.textContaining('12 successful referrals'),
          findsOneWidget,
        );
        // Info icon rendered next to the footnote.
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      },
    );

    testWidgets(
      'empty-state message shows when no recent activity',
      (tester) async {
        // Tall viewport so the recent-activity card paints in one frame.
        await tester.binding.setSurfaceSize(const Size(800, 2400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final fake = _FakeReferralService();
        await tester.pumpWidget(
          _harness(fake: fake, child: const ReferralScreen()),
        );
        await tester.pumpAndSettle();
        expect(
          find.textContaining('No referrals yet'),
          findsOneWidget,
        );
        // The empty-state widget uses people_outline.
        expect(find.byIcon(Icons.people_outline), findsOneWidget);
      },
    );

    testWidgets(
      'renders recent activity rows when stats include some',
      (tester) async {
        // Tall viewport so the whole ListView paints in one frame — the
        // RefreshIndicator wraps another Scrollable which trips up
        // scrollUntilVisible with "Too many elements".
        await tester.binding.setSurfaceSize(const Size(800, 2400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final now = DateTime.now().toUtc();
        final fake = _FakeReferralService(
          stats: ReferralStats(
            code: 'abc12345',
            shareUrl: 'https://advocat.ee/r/abc12345',
            invitesSent: 2,
            conversions: 1,
            freeMonthsEarned: 1,
            recentActivity: [
              ReferralActivity(
                invitedAt: now.subtract(const Duration(days: 3)),
                convertedAt: now.subtract(const Duration(days: 2)),
                status: 'credited',
              ),
              ReferralActivity(
                invitedAt: now.subtract(const Duration(hours: 5)),
                status: 'attributed',
              ),
            ],
          ),
        );
        await tester.pumpWidget(
          _harness(fake: fake, child: const ReferralScreen()),
        );
        await tester.pumpAndSettle();
        // No empty card.
        expect(find.byIcon(Icons.people_outline), findsNothing);
        // Two activity rows → two arrow separators in the formatted lines.
        expect(find.textContaining('→'), findsNWidgets(2));
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
      expect(stats.recentActivity, isEmpty);
      expect(stats.hasActivity, isFalse);
    });

    test('lookupCode returns a CodeLookupOk in demo mode', () async {
      final svc = ReferralService();
      final res = await svc.lookupCode('abc12345');
      expect(res, isA<CodeLookupOk>());
      final ok = res as CodeLookupOk;
      expect(ok.inviterFirstName, isNotNull);
    });

    test('lookupCode with empty string returns CodeLookupInvalid', () async {
      final svc = ReferralService();
      final res = await svc.lookupCode('');
      expect(res, isA<CodeLookupInvalid>());
    });
  });

  group('ReferralActivity.fromJson', () {
    test('parses a complete row', () {
      final row = ReferralActivity.fromJson({
        'invited_at': '2026-05-01T10:00:00Z',
        'converted_at': '2026-05-03T10:00:00Z',
        'status': 'credited',
      });
      expect(row, isNotNull);
      expect(row!.hasConverted, isTrue);
      expect(row.status, 'credited');
    });

    test('parses a pending row (no converted_at)', () {
      final row = ReferralActivity.fromJson({
        'invited_at': '2026-05-01T10:00:00Z',
        'status': 'attributed',
      });
      expect(row, isNotNull);
      expect(row!.hasConverted, isFalse);
    });

    test('returns null for unparseable input', () {
      expect(ReferralActivity.fromJson(null), isNull);
      expect(ReferralActivity.fromJson('not a map'), isNull);
      expect(ReferralActivity.fromJson({'invited_at': 'garbage'}), isNull);
      expect(ReferralActivity.fromJson(<String, dynamic>{}), isNull);
    });

    test('accepts attributed_at as an alias for invited_at', () {
      final row = ReferralActivity.fromJson({
        'attributed_at': '2026-05-01T10:00:00Z',
        'status': 'attributed',
      });
      expect(row, isNotNull);
      expect(row!.invitedAt.year, 2026);
    });
  });
}
