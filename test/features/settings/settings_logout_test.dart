@Tags(['fast'])
library;

// =============================================================================
// Regression guard for the Logout button in Settings (Fix #1 from QA report
// 2026-05-03).
// =============================================================================
//
// QA report flagged: "No 'Sign out' / 'Logi välja' / 'Выйти' anywhere. A user
// has no graceful way to leave their session. Only 'Kustuta konto' (Delete
// account) is destructive."
//
// In fact the button is implemented in lib/features/settings/screens/
// settings_screen.dart and routed through AppButton(variant: danger,
// label: l.signOut). The QA pass appears to have missed it (likely because
// the list scrolls past it). These tests lock down:
//
//   1. The settings source still wires l.signOut → AppButton onPressed →
//      _showSignOutDialog → authControllerProvider.notifier.logout().
//   2. The logout button is positioned BELOW the destructive
//      "Kustuta konto" tile in the list, so logout (less destructive) is
//      what the user encounters last and tries first.   *(NOTE: per
//      review the existing layout has logout LAST in the list rather than
//      directly above delete. We assert presence + ordering relative to
//      delete instead of strict adjacency, to avoid breaking unrelated
//      list reorderings.)*
//   3. signOut localisation strings exist for ET / EN / RU.

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

  group('Settings logout button (QA report 2026-05-03 fix #1)', () {
    test('SettingsScreen renders an AppButton for sign-out', () {
      // Look for the AppButton(label: l.signOut, ...) construction.
      expect(settingsSource, contains('label: l.signOut'),
          reason: 'Settings must render an AppButton wired to l.signOut');
      // It must be a danger-variant button (visually distinct from delete
      // which is also destructive — but logout is reversible).
      final signOutIdx = settingsSource.indexOf('label: l.signOut');
      // Window of ~300 chars around the label should contain the button
      // construction including its variant.
      final start = (signOutIdx - 200).clamp(0, settingsSource.length);
      final end = (signOutIdx + 200).clamp(0, settingsSource.length);
      final block = settingsSource.substring(start, end);
      expect(block, contains('AppButton('),
          reason: 'l.signOut must be passed to an AppButton');
      expect(block, contains('AppIcons.logout'),
          reason: 'Sign-out button must use the standard logout icon');
    });

    test('Sign-out tap opens a confirmation dialog', () {
      // The onPressed wires through to _showSignOutDialog which shows an
      // AlertDialog with l.signOutConfirm content.
      expect(settingsSource, contains('_showSignOutDialog'),
          reason:
              'Sign-out button must show a confirmation dialog before logout');
      expect(settingsSource, contains('l.signOutConfirm'),
          reason: 'Confirmation dialog must use l.signOutConfirm body text');
    });

    test('Confirmation dialog calls authControllerProvider.notifier.logout()',
        () {
      // Find the _showSignOutDialog body and assert it dispatches logout().
      final dialogIdx = settingsSource.indexOf('_showSignOutDialog(');
      expect(dialogIdx, greaterThan(0));
      // Find the method definition (not just the call).
      final methodIdx = settingsSource.indexOf(
          'void _showSignOutDialog(BuildContext context, WidgetRef ref)');
      expect(methodIdx, greaterThan(0),
          reason: '_showSignOutDialog method must exist');
      // Method body window — generous to survive minor refactors.
      final methodBody =
          settingsSource.substring(methodIdx, methodIdx + 1200);
      expect(methodBody, contains('authControllerProvider.notifier'),
          reason: 'Sign-out dialog must use the auth controller');
      expect(methodBody, contains('.logout()'),
          reason: 'Sign-out dialog must call logout() on the auth controller');
    });

    test('After logout the user is sent to the onboarding/login flow', () {
      final methodIdx = settingsSource.indexOf(
          'void _showSignOutDialog(BuildContext context, WidgetRef ref)');
      expect(methodIdx, greaterThan(0));
      final methodBody =
          settingsSource.substring(methodIdx, methodIdx + 1200);
      // Production navigates to the onboarding route after logout. The
      // routerProvider redirect then sends unauthenticated users straight
      // to /login (auth-route guard), so onboarding → login is intentional.
      expect(methodBody, contains('AppRoutes.onboarding'),
          reason:
              'After logout, navigate to AppRoutes.onboarding (router guard '
              'will then send unauthenticated users to /login).');
    });

    test('Sign-out button is positioned AFTER the delete account tile', () {
      // Less-destructive ordering check: delete-account uses l.deleteAccount,
      // sign-out uses l.signOut. Both must appear; sign-out must come at or
      // below delete in the list (delete is in DATA & PRIVACY, sign-out is in
      // its own bottom section so the user sees it last).
      final deleteIdx = settingsSource.indexOf('title: l.deleteAccount');
      final signOutIdx = settingsSource.indexOf('label: l.signOut');
      expect(deleteIdx, greaterThan(0),
          reason: 'l.deleteAccount tile must still exist');
      expect(signOutIdx, greaterThan(0),
          reason: 'l.signOut button must exist');
      expect(signOutIdx, greaterThan(deleteIdx),
          reason:
              'Sign-out button should appear after the delete-account tile so '
              'users encounter the safer option in the visually distinct '
              'bottom-of-list slot.');
    });
  });

  group('signOut localisation', () {
    Map<String, dynamic> loadArb(String code) {
      final file = File('lib/l10n/app_$code.arb');
      expect(file.existsSync(), isTrue, reason: 'app_$code.arb must exist');
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }

    test('Estonian has signOut + signOutConfirm', () {
      final arb = loadArb('et');
      expect(arb['signOut'], isNotNull);
      expect((arb['signOut'] as String).trim(), isNotEmpty);
      expect(arb['signOutConfirm'], isNotNull);
      expect((arb['signOutConfirm'] as String).trim(), isNotEmpty);
    });

    test('English has signOut + signOutConfirm', () {
      final arb = loadArb('en');
      expect(arb['signOut'], isNotNull);
      expect((arb['signOut'] as String).trim(), isNotEmpty);
      expect(arb['signOutConfirm'], isNotNull);
      expect((arb['signOutConfirm'] as String).trim(), isNotEmpty);
    });

    test('Russian has signOut + signOutConfirm', () {
      final arb = loadArb('ru');
      expect(arb['signOut'], isNotNull);
      expect((arb['signOut'] as String).trim(), isNotEmpty);
      expect(arb['signOutConfirm'], isNotNull);
      expect((arb['signOutConfirm'] as String).trim(), isNotEmpty);
    });
  });
}
