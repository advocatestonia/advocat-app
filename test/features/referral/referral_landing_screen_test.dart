// Widget tests for ReferralLandingScreen.
// -----------------------------------------------------------------------------
// Ref: lib/features/referral/screens/referral_landing_screen.dart
//
// The ReferralService is swapped out via the provider override; the screen
// reads the inviter's first name from the fake and renders the social-proof
// hero copy. Invalid codes hit the fallback path.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:advocat/features/referral/data/referral_service.dart';
import 'package:advocat/features/referral/models/referral_stats.dart';
import 'package:advocat/features/referral/screens/referral_landing_screen.dart';
import 'package:advocat/l10n/app_localizations.dart';

class _StubReferralService implements ReferralService {
  _StubReferralService(this.lookupResult);
  final CodeLookupResult lookupResult;

  @override
  Future<CodeLookupResult> lookupCode(String code) async => lookupResult;

  // The landing only ever calls lookupCode — the rest is unreachable.
  @override
  Future<String> fetchCode() async => 'unused';

  @override
  Future<ReferralStats> fetchStats() async => const ReferralStats(
        code: '',
        shareUrl: '',
        invitesSent: 0,
        conversions: 0,
        freeMonthsEarned: 0,
      );

  @override
  Future<AttributeResult> attribute(String code) async => const AttributeOk(
        attributionId: '',
        status: 'attributed',
        alreadyAttributed: false,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

Widget _harness({
  required ReferralService service,
  required String code,
}) {
  return ProviderScope(
    overrides: [
      referralServiceProvider.overrideWithValue(service),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ReferralLandingScreen(code: code),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('ReferralLandingScreen — happy path', () {
    testWidgets(
      'shows inviter first name when lookup returns a name',
      (tester) async {
        await tester.pumpWidget(_harness(
          service: _StubReferralService(
            const CodeLookupOk(inviterFirstName: 'Anna'),
          ),
          code: 'abc12345',
        ));
        await tester.pumpAndSettle();

        expect(find.textContaining('Anna'), findsOneWidget);
        // CTA visible.
        expect(find.byType(ElevatedButton), findsOneWidget);
        // Secondary CTA visible.
        expect(find.byType(TextButton), findsOneWidget);
      },
    );

    testWidgets(
      'shows generic subtitle when inviter name is null',
      (tester) async {
        await tester.pumpWidget(_harness(
          service: _StubReferralService(
            const CodeLookupOk(inviterFirstName: null),
          ),
          code: 'abc12345',
        ));
        await tester.pumpAndSettle();

        // Should fall back to the generic copy mentioning "free first
        // month".
        expect(find.textContaining('first month'), findsOneWidget);
      },
    );

    testWidgets(
      'renders the benefits block with the 17-languages copy',
      (tester) async {
        await tester.pumpWidget(_harness(
          service: _StubReferralService(
            const CodeLookupOk(inviterFirstName: 'Anna'),
          ),
          code: 'abc12345',
        ));
        await tester.pumpAndSettle();

        expect(find.textContaining('17 languages'), findsOneWidget);
        expect(find.byIcon(Icons.verified), findsOneWidget);
      },
    );

    testWidgets(
      'stashes the pending referral code in SharedPreferences',
      (tester) async {
        await tester.pumpWidget(_harness(
          service: _StubReferralService(
            const CodeLookupOk(inviterFirstName: 'Anna'),
          ),
          code: 'ABC12345',
        ));
        await tester.pumpAndSettle();
        // Pump once more so the deferred init future resolves.
        await tester.pump(const Duration(milliseconds: 10));

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString(kPendingReferralCodePrefKey),
          'abc12345', // lowercased
        );
      },
    );
  });

  group('ReferralLandingScreen — fallback / expired', () {
    testWidgets(
      'shows the expired fallback copy on CodeLookupInvalid',
      (tester) async {
        await tester.pumpWidget(_harness(
          service: _StubReferralService(const CodeLookupInvalid()),
          code: 'deadbeef',
        ));
        await tester.pumpAndSettle();

        // English fallback message.
        expect(
          find.textContaining('expired'),
          findsOneWidget,
        );
        // Hero icon flips to link_off.
        expect(find.byIcon(Icons.link_off), findsOneWidget);
        // But the CTA still lets the user try Advocat.
        expect(find.byType(ElevatedButton), findsOneWidget);
      },
    );

    testWidgets(
      'shows hero gradient icon (card_giftcard) on happy path',
      (tester) async {
        await tester.pumpWidget(_harness(
          service: _StubReferralService(
            const CodeLookupOk(inviterFirstName: 'Anna'),
          ),
          code: 'abc12345',
        ));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.card_giftcard), findsOneWidget);
        expect(find.byIcon(Icons.link_off), findsNothing);
      },
    );
  });
}
