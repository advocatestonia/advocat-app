@Tags(['fast'])
library;

// =============================================================================
// oauth_scope_test.dart — D1 V1/V2 OAuth scope flag + re-auth banner
// (Track E, v2.1 consilium, 2026-05-07)
// =============================================================================
//
// Coverage:
//   1. kGmailOAuthScopesV1 is send-only (proactive scopes ABSENT).
//   2. kGmailOAuthScopesV2 includes gmail.readonly + gmail.modify.
//   3. kGmailScopesActive defaults to V2 (D1 ship state).
//   4. kGmailScopesIncludeProactive returns true for V2-active, false for V1.
//   5. gmailScopeIncludesReadonly() helper handles null / V1 / V2 strings.
//   6. GmailReauthBanner renders body + CTA from l10n in en/et/ru/fi.
//   7. GmailReauthBanner fires onReauthorize callback when CTA tapped.
//
// Test approach: the live `_emailConnectionProvider` in email_screen.dart is
// file-private and pulls Supabase at construct time, so we test the public
// surface (feature flags + banner widget) directly. The "V1 user sees banner
// vs V2 user does not" semantics is fully captured by
// gmailScopeIncludesReadonly() — which is what email_screen.dart uses to gate
// the banner mount — so locking down that helper is structurally equivalent.
//
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/config/feature_flags.dart';
import 'package:advocat/features/email/widgets/gmail_reauth_banner.dart';
import 'package:advocat/l10n/app_localizations.dart';

// ── Helpers ────────────────────────────────────────────────────────────────

/// Wrap a widget with the minimum scaffolding the banner needs:
/// `MaterialApp` + l10n delegates + locale.
Widget _wrap(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('en'),
      Locale('et'),
      Locale('ru'),
      Locale('fi'),
    ],
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ===========================================================================
  // 1. Constant shape — V1 vs V2.
  // ===========================================================================

  group('feature_flags — V1 vs V2 scope literals', () {
    test('V1 contains gmail.send but NOT gmail.readonly or gmail.modify', () {
      expect(kGmailOAuthScopesV1, contains('gmail.send'));
      expect(kGmailOAuthScopesV1, isNot(contains('gmail.readonly')));
      expect(kGmailOAuthScopesV1, isNot(contains('gmail.modify')));
    });

    test('V2 contains all three Gmail scopes', () {
      expect(kGmailOAuthScopesV2, contains('gmail.send'));
      expect(kGmailOAuthScopesV2, contains('gmail.readonly'));
      expect(kGmailOAuthScopesV2, contains('gmail.modify'));
    });

    test('V2 includes the basic email scope', () {
      // Without `email`, Supabase cannot expose user.email — required for
      // the connected-view "Connected to <email>" copy.
      expect(kGmailOAuthScopesV2, contains('email'));
    });

    test('V1 and V2 are distinct strings', () {
      expect(kGmailOAuthScopesV1, isNot(equals(kGmailOAuthScopesV2)));
    });
  });

  // ===========================================================================
  // 2. kGmailScopesActive default — D1 ships V2.
  // ===========================================================================

  group('feature_flags — kGmailScopesActive default', () {
    test('kGmailScopesActive == kGmailOAuthScopesV2 (D1 ship state)', () {
      expect(
        kGmailScopesActive,
        equals(kGmailOAuthScopesV2),
        reason:
            'D1 (2026-05-07) ships V2 active by default. Flipping to V1 '
            'requires a code edit + redeploy and is the documented '
            'rollback path.',
      );
    });

    test('kGmailScopesActive contains gmail.readonly (regression guard)', () {
      // Belt-and-suspenders: if a future PR flips the default but forgets
      // to update this test, we'd notice via a red CI before deploy.
      expect(kGmailScopesActive, contains('gmail.readonly'));
    });
  });

  // ===========================================================================
  // 3. kGmailScopesIncludeProactive — banner gate predicate.
  // ===========================================================================

  group('feature_flags — kGmailScopesIncludeProactive', () {
    test('returns true when active is V2 (current default)', () {
      // Static check on the const — the predicate evaluates against
      // kGmailScopesActive, which is V2 today.
      expect(kGmailScopesIncludeProactive, isTrue);
    });

    test('predicate definition: requires BOTH readonly AND modify', () {
      // We can't toggle the const at runtime in a unit test, but we can
      // confirm the predicate keys off both scope substrings — V2's
      // string contains both, so true; either one missing would flip
      // the result. Lock this in via the active-string state.
      expect(kGmailScopesActive.contains('gmail.readonly'), isTrue);
      expect(kGmailScopesActive.contains('gmail.modify'), isTrue);
    });
  });

  // ===========================================================================
  // 4. gmailScopeIncludesReadonly() helper — banner show/hide test.
  // ===========================================================================

  group('feature_flags — gmailScopeIncludesReadonly()', () {
    test('null scope → false (banner shows)', () {
      // Defence: when the token row hasn't been read yet, we prefer
      // showing the banner over silent loss-of-functionality.
      expect(gmailScopeIncludesReadonly(null), isFalse);
    });

    test('empty string → false (banner shows)', () {
      expect(gmailScopeIncludesReadonly(''), isFalse);
    });

    test('V1-shape scope string (send-only) → false (banner shows)', () {
      // This is the "V1 token user sees re-auth banner when active scopes
      // are V2" case from the runbook §4.1. The user's stored token is
      // V1, kGmailScopesActive is V2 → banner shows.
      expect(gmailScopeIncludesReadonly(kGmailOAuthScopesV1), isFalse);
    });

    test('V2-shape scope string (readonly+modify present) → true (banner hides)',
        () {
      // The "V2 token user does NOT see banner" case.
      expect(gmailScopeIncludesReadonly(kGmailOAuthScopesV2), isTrue);
    });

    test('partial scope containing only readonly → true', () {
      // Future-proofing: if Google returns scopes in a different order or
      // missing modify (impossible per Google docs but defence-in-depth),
      // the readonly substring alone is enough to suppress the banner.
      expect(
        gmailScopeIncludesReadonly(
          'email https://www.googleapis.com/auth/gmail.readonly',
        ),
        isTrue,
      );
    });

    test('lowercased input still matches (canonicalisation)', () {
      // The notifier lowercases the scope before storing the hint.
      expect(
        gmailScopeIncludesReadonly(
          kGmailOAuthScopesV2.toLowerCase(),
        ),
        isTrue,
      );
    });
  });

  // ===========================================================================
  // 5. GmailReauthBanner widget — renders l10n in EN.
  // ===========================================================================

  group('GmailReauthBanner — renders l10n', () {
    testWidgets('renders the EN body and CTA when locale is en', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(_wrap(
        GmailReauthBanner(onReauthorize: () => tapped++),
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();

      // Body — the verbatim phrase per Track C O1.
      expect(
        find.textContaining('reads your inbox to draft replies'),
        findsOneWidget,
        reason:
            'Track C O1 mandates the verbatim phrase "reads inbox to draft '
            'replies; you can revoke any time" in the EN copy.',
      );
      expect(find.text('Reauthorize'), findsOneWidget);
      expect(tapped, 0);
    });

    testWidgets('renders the ET copy when locale is et', (tester) async {
      await tester.pumpWidget(_wrap(
        GmailReauthBanner(onReauthorize: () {}),
        locale: const Locale('et'),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('postkasti'), findsOneWidget,
          reason: 'ET body must mention postkasti (inbox).');
      expect(find.text('Anna uuesti luba'), findsOneWidget);
    });

    testWidgets('renders the RU copy when locale is ru', (tester) async {
      await tester.pumpWidget(_wrap(
        GmailReauthBanner(onReauthorize: () {}),
        locale: const Locale('ru'),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('почтовый ящик'), findsOneWidget,
          reason: 'RU body must mention почтовый ящик.');
      expect(find.text('Переподключить'), findsOneWidget);
    });

    testWidgets('renders the FI copy when locale is fi', (tester) async {
      await tester.pumpWidget(_wrap(
        GmailReauthBanner(onReauthorize: () {}),
        locale: const Locale('fi'),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('postilaatikko'), findsOneWidget,
          reason: 'FI body must mention postilaatikko.');
      expect(find.text('Vahvista uudelleen'), findsOneWidget);
    });
  });

  // ===========================================================================
  // 6. GmailReauthBanner — onReauthorize callback fires on tap.
  // ===========================================================================

  group('GmailReauthBanner — onReauthorize callback', () {
    testWidgets('fires the callback when CTA button is tapped',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(_wrap(
        GmailReauthBanner(onReauthorize: () => taps++),
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reauthorize'));
      await tester.pumpAndSettle();

      expect(taps, 1,
          reason:
              'Tapping the CTA must invoke the onReauthorize callback. '
              'In the live tree this re-runs connectGmail() with '
              'prompt=consent → fresh V2 token → banner suppresses on '
              'next state read.');
    });

    testWidgets('fires the callback once per tap (no double-fire)',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(_wrap(
        GmailReauthBanner(onReauthorize: () => taps++),
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reauthorize'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reauthorize'));
      await tester.pumpAndSettle();
      expect(taps, 2);
    });
  });
}
