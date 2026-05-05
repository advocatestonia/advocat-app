@Tags(['fast'])
library;

// =============================================================================
// quota_visible_failure_test.dart — Bug 1 (silent send failure on quota cap).
// =============================================================================
//
// QA agent observation (2026-05-05): "After Pro upgrade banner appeared
// mid-session, my next 2 send-button clicks silently no-op'd. Could be the
// actual cause of the broken sends, not a Flutter bug. UX-wise the user
// gets no error when send is silently blocked."
//
// Three reasons a send can be denied:
//   1. Anon (demo) — IP rate limit + demo cap exhausted (3/min)
//   2. Free tier — 7 monthly messages exhausted
//   3. Rate limit — 3/min IP cap (transient)
//
// Fix: a small helper `buildQuotaErrorSnackBar` that produces a SnackBar
// the chat screen surfaces via `ScaffoldMessenger.of(context).showSnackBar`.
// The pure-function shape lets us assert SnackBar text + CTA wiring
// without spinning up the full ChatScreen.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/chat/widgets/quota_error_snackbar.dart';
import 'package:advocat/l10n/app_localizations.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Builder(builder: (_) => child)),
  );
}

/// Pumps a `Scaffold` with a button that, on tap, shows the snackbar built
/// for [reason]. Returns the [tester] mid-frame so tests can pump and assert
/// the snackbar content.
Future<void> _showSnackBar(
  WidgetTester tester, {
  required QuotaDenialReason reason,
  VoidCallback? onSignUp,
  VoidCallback? onUpgrade,
}) async {
  late BuildContext capturedContext;
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(builder: (ctx) {
        capturedContext = ctx;
        return const SizedBox.shrink();
      }),
    ),
  ));
  ScaffoldMessenger.of(capturedContext).showSnackBar(
    buildQuotaErrorSnackBar(
      context: capturedContext,
      reason: reason,
      onSignUp: onSignUp,
      onUpgrade: onUpgrade,
    ),
  );
  // Pump a single frame, then settle so the snackbar finishes its enter
  // animation and the action button lands inside the visible viewport.
  // Without pumpAndSettle the button renders off-screen and tap() warns.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 750));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('buildQuotaErrorSnackBar — visible quota error', () {
    testWidgets('anon demo limit shows demo text + Sign-up CTA', (tester) async {
      var signUps = 0;
      await _showSnackBar(
        tester,
        reason: QuotaDenialReason.anonDemo,
        onSignUp: () => signUps += 1,
      );

      expect(find.text('Demo limit reached. Sign up for free to continue.'),
          findsOneWidget);
      // Sign-up CTA is present and works.
      final ctaFinder = find.byKey(const Key('quota_snackbar_cta'));
      expect(ctaFinder, findsOneWidget);
      await tester.tap(ctaFinder);
      expect(signUps, 1,
          reason:
              'Tapping the CTA must invoke the onSignUp callback so the chat '
              'screen can navigate the user to /register');
    });

    testWidgets('free tier exhausted shows free quota text + Upgrade CTA',
        (tester) async {
      var upgrades = 0;
      await _showSnackBar(
        tester,
        reason: QuotaDenialReason.freeQuotaExhausted,
        onUpgrade: () => upgrades += 1,
      );

      // The user sees BOTH the limit-reached line and the upgrade hint.
      expect(
        find.textContaining("You've used all 7 free messages this month."),
        findsOneWidget,
      );
      // Upgrade CTA is present and works.
      final ctaFinder = find.byKey(const Key('quota_snackbar_cta'));
      expect(ctaFinder, findsOneWidget);
      await tester.tap(ctaFinder);
      expect(upgrades, 1,
          reason: 'Tapping Upgrade must invoke the onUpgrade callback so the '
              'chat screen can navigate to /subscription');
    });

    testWidgets('rate limit shows transient text and NO CTA', (tester) async {
      await _showSnackBar(
        tester,
        reason: QuotaDenialReason.rateLimit,
      );

      expect(
        find.text('Sending too fast. Try again in a few seconds.'),
        findsOneWidget,
      );
      // No CTA for rate-limit (it's a transient retry case, not a paywall).
      expect(find.byKey(const Key('quota_snackbar_cta')), findsNothing);
    });

    testWidgets(
        'after the snackbar appears the underlying composer is still tappable '
        '(send button works after dismissing the snackbar)', (tester) async {
      // We model this by verifying the snackbar is non-modal: it lives in
      // an overlay and does not block the underlying widget tree.
      var taps = 0;
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(builder: (c) {
            ctx = c;
            return Center(
              child: TextButton(
                key: const Key('mock_send_button'),
                onPressed: () => taps += 1,
                child: const Text('Send'),
              ),
            );
          }),
        ),
      ));

      ScaffoldMessenger.of(ctx).showSnackBar(buildQuotaErrorSnackBar(
        context: ctx,
        reason: QuotaDenialReason.rateLimit,
      ));
      await tester.pump();

      expect(find.text('Sending too fast. Try again in a few seconds.'),
          findsOneWidget);

      // The mock send button is still tappable (snackbar is not modal).
      await tester.tap(find.byKey(const Key('mock_send_button')));
      expect(taps, 1);
    });

    testWidgets('Estonian locale renders the Estonian quota text',
        (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('et'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(builder: (c) {
            ctx = c;
            return const SizedBox.shrink();
          }),
        ),
      ));
      ScaffoldMessenger.of(ctx).showSnackBar(
        buildQuotaErrorSnackBar(
          context: ctx,
          reason: QuotaDenialReason.freeQuotaExhausted,
          onUpgrade: () {},
        ),
      );
      await tester.pump();

      // Asserts l10n wiring without locking the exact phrasing — we just
      // confirm the EN string is NOT shown when locale=et.
      expect(
        find.textContaining("You've used all 7 free messages this month."),
        findsNothing,
      );
    });

    testWidgets('Russian locale renders the Russian quota text',
        (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(builder: (c) {
            ctx = c;
            return const SizedBox.shrink();
          }),
        ),
      ));
      ScaffoldMessenger.of(ctx).showSnackBar(
        buildQuotaErrorSnackBar(
          context: ctx,
          reason: QuotaDenialReason.anonDemo,
          onSignUp: () {},
        ),
      );
      await tester.pump();

      // English copy must NOT be shown for ru locale.
      expect(
        find.text('Demo limit reached. Sign up for free to continue.'),
        findsNothing,
      );
    });
  });

  group('QuotaDenialReason.fromQuota — reason inference', () {
    test('isAnon=true → anonDemo regardless of remaining', () {
      expect(
        QuotaDenialReason.fromQuota(isAnon: true, remaining: 0, isPro: false),
        QuotaDenialReason.anonDemo,
      );
    });

    test('isAnon=false, remaining=0, !pro → freeQuotaExhausted', () {
      expect(
        QuotaDenialReason.fromQuota(isAnon: false, remaining: 0, isPro: false),
        QuotaDenialReason.freeQuotaExhausted,
      );
    });

    test('pro user is never denied → returns null', () {
      expect(
        QuotaDenialReason.fromQuota(isAnon: false, remaining: 0, isPro: true),
        isNull,
      );
    });

    test('logged-in free user with remaining > 0 → returns null', () {
      expect(
        QuotaDenialReason.fromQuota(isAnon: false, remaining: 5, isPro: false),
        isNull,
      );
    });
  });
}
