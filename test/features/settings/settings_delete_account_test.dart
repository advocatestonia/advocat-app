@Tags(['fast'])
library;

// =============================================================================
// Regression guard for the Delete Account flow in Settings.
//
// App Store Guideline 5.1.1(v) (hard requirement since 2022) + GDPR Art. 17.
// These tests are source-code contract tests (same pattern as
// settings_logout_test.dart and gdpr_delete_rls_test.dart). They lock down:
//
//   1. The Delete Account tile exists in settings_screen.dart and is wired
//      to the two-step confirmation flow.
//   2. The destructive flow routes through SupabaseService.deleteAllUserData
//      with `confirmEmail:` (not a bare call) — the typed-email guard must
//      reach the edge function.
//   3. The destructive button starts DISABLED and only enables when the
//      user-typed email matches their own session email (case-insensitive).
//   4. After successful deletion the user is navigated to /onboarding (the
//      router guard then redirects unauthenticated users to /login).
//   5. The six new ARB keys (dangerZone, deleteAccountWarning,
//      deleteAccountConfirmHint, deleteAccountConfirmButton,
//      deleteAccountSuccess, deletingAccount) exist in EN/ET/FI/RU.
// =============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String settingsSource;

  setUpAll(() {
    settingsSource =
        File('lib/features/settings/screens/settings_screen.dart')
            .readAsStringSync();
  });

  group('Delete Account UI source contract (App Store 5.1.1(v))', () {
    test('SettingsScreen renders a Delete Account tile', () {
      expect(settingsSource, contains('title: l.deleteAccount'),
          reason:
              'Settings must render a tile whose title is l.deleteAccount '
              '(App Store 5.1.1(v) requires an in-app entry point).');
      expect(settingsSource, contains('_showDeleteAccountDialog'),
          reason:
              'The Delete Account tile must open the warning dialog.');
      expect(settingsSource, contains('AppColors.error'),
          reason:
              'Destructive action must be visually marked as such.');
    });

    test('Delete flow shows a typed-email confirmation step', () {
      // The second-stage dialog must use the typed-email guard.
      expect(settingsSource, contains('_showFinalDeleteConfirmation'),
          reason: 'second confirmation method must exist');
      expect(settingsSource, contains('l.deleteAccountConfirmHint'),
          reason:
              'second dialog must use l.deleteAccountConfirmHint as the '
              'TextField label so the user sees their own email echoed.');
      expect(settingsSource, contains('l.deleteAccountConfirmButton'),
          reason:
              'second dialog destructive button must use '
              'l.deleteAccountConfirmButton (not the generic l.deleteAccount '
              'label — the typed-confirm dialog is its own copy).');
      expect(settingsSource, contains('l.deleteAccountWarning'),
          reason:
              'second dialog must surface the loss-of-data warning copy.');
    });

    test('Destructive button stays disabled until typed email matches', () {
      // The dialog must use a `matches`-style gate. We check for the
      // textbook pattern: matches ? <handler> : null  (Material Button's
      // null onPressed renders it disabled).
      expect(settingsSource, contains('matches'),
          reason: 'dialog must compute a "matches" boolean');
      expect(
          settingsSource,
          contains(RegExp(r'onPressed:\s*matches\s*\?')),
          reason:
              'Destructive button onPressed must be `matches ? ... : null` so '
              'it is disabled until the typed email matches.');
      // Case-insensitive match — avoid foot-gun where user types
      // "User@example.com" with a different case than the session email.
      expect(settingsSource, contains('toLowerCase()'),
          reason:
              'Email match must be case-insensitive (toLowerCase on both '
              'sides). Otherwise a "User@x" vs "user@x" mismatch would '
              'block legitimate deletion.');
    });

    test('Performs deletion through SupabaseService with confirmEmail', () {
      // Must call deleteAllUserData with the confirmEmail named param.
      expect(settingsSource,
          contains('deleteAllUserData(confirmEmail:'),
          reason:
              'must call deleteAllUserData(confirmEmail: ...) — the '
              'edge fn re-checks this server-side as defence in depth.');
    });

    test('After deletion: signs out and navigates to /onboarding', () {
      // _performAccountDeletion must do both. Find the method body window.
      final methodIdx =
          settingsSource.indexOf('Future<void> _performAccountDeletion(');
      expect(methodIdx, greaterThan(0),
          reason: '_performAccountDeletion method must exist');
      final methodBody = settingsSource.substring(
          methodIdx, methodIdx + 2500);
      expect(methodBody, contains('authControllerProvider.notifier'),
          reason: 'must use auth controller for logout');
      expect(methodBody, contains('.logout()'),
          reason: 'must call logout() on the auth controller');
      expect(methodBody, contains('AppRoutes.onboarding'),
          reason:
              'After deletion, navigate to AppRoutes.onboarding (the router '
              'guard will redirect unauthenticated users to /login).');
      expect(methodBody, contains('l.deleteAccountSuccess'),
          reason:
              'success snackbar must use the new l.deleteAccountSuccess copy '
              '(not a hard-coded English string).');
    });

    test('GDPR Art. 17 comment present in the deletion methods', () {
      // Document the regulatory tie-in so future refactors don't drop it.
      expect(settingsSource, contains('App Store'),
          reason:
              'source must reference App Store 5.1.1(v) somewhere in the '
              'deletion path so a future reviewer understands why this '
              'cannot be soft-deleted.');
      expect(settingsSource, contains('GDPR Art. 17'),
          reason: 'source must reference GDPR Art. 17');
    });
  });

  group('Account-delete localisation (4 native + 13 fallback)', () {
    Map<String, dynamic> loadArb(String code) {
      final file = File('lib/l10n/app_$code.arb');
      expect(file.existsSync(), isTrue, reason: 'app_$code.arb must exist');
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }

    const newKeys = <String>[
      'dangerZone',
      'deleteAccountConfirmButton',
      'deleteAccountConfirmHint',
      'deleteAccountSuccess',
      'deleteAccountWarning',
      'deletingAccount',
    ];

    const nativeLangs = <String>['en', 'et', 'fi', 'ru'];
    const fallbackLangs = <String>[
      'ar', 'de', 'es', 'fa', 'fr', 'it', 'lt', 'lv',
      'pl', 'ro', 'sv', 'tr', 'uk',
    ];

    for (final lang in nativeLangs) {
      test('$lang has all 6 new delete-account keys natively translated', () {
        final arb = loadArb(lang);
        for (final key in newKeys) {
          expect(arb[key], isNotNull,
              reason: 'app_$lang.arb missing key "$key"');
          final val = (arb[key] as String).trim();
          expect(val, isNotEmpty,
              reason: 'app_$lang.arb key "$key" is empty');
          // Native languages must NOT carry the TODO sentinel; if they
          // do, someone copied a fallback by mistake.
          expect(val.startsWith('@@TODO_TRANSLATE@@'), isFalse,
              reason:
                  'app_$lang.arb key "$key" still carries the TODO sentinel '
                  '— this language is meant to be natively translated.');
        }
      });
    }

    for (final lang in fallbackLangs) {
      test('$lang has all 6 new keys present (fallback string OK)', () {
        final arb = loadArb(lang);
        for (final key in newKeys) {
          expect(arb[key], isNotNull,
              reason: 'app_$lang.arb missing key "$key"');
          expect((arb[key] as String).trim(), isNotEmpty,
              reason: 'app_$lang.arb key "$key" is empty');
        }
      });
    }

    test('deleteAccountConfirmHint carries the {email} placeholder meta', () {
      final arb = loadArb('en');
      // The {email} substitution requires the placeholder meta in EN
      // (the master ARB) — otherwise flutter gen-l10n emits a plain getter
      // instead of a function and runtime substitution breaks.
      expect(arb['@deleteAccountConfirmHint'], isNotNull,
          reason: 'EN must declare the @deleteAccountConfirmHint meta');
      final meta = arb['@deleteAccountConfirmHint'] as Map<String, dynamic>;
      final placeholders = meta['placeholders'] as Map<String, dynamic>?;
      expect(placeholders, isNotNull);
      expect(placeholders!['email'], isNotNull,
          reason: 'placeholders.email must be declared');
    });

    test('All 4 native languages contain {email} placeholder in the hint',
        () {
      for (final lang in nativeLangs) {
        final arb = loadArb(lang);
        final val = arb['deleteAccountConfirmHint'] as String;
        expect(val, contains('{email}'),
            reason:
                'app_$lang.arb deleteAccountConfirmHint must include the '
                '{email} placeholder for runtime substitution');
      }
    });
  });
}
