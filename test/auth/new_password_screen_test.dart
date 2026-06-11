// =============================================================================
// new_password_screen_test.dart — beta audit fix (Wave 1, 2026-06-11)
// =============================================================================
//
// Widget-layer half of the password-reset fix: NewPasswordScreen must
//   - validate (required / min 8 chars / match) before touching the network,
//   - call SupabaseService.updatePassword exactly once on success and
//     navigate away (home when there's no stack, pop when pushed),
//   - stay on the screen and surface the error on failure.
//
// Provider-layer coverage (recovery-event listener, flag lifecycle) lives in
// `password_recovery_flow_test.dart`.

@Tags(['fast'])
library;

import 'dart:async' show unawaited;

import 'package:advocat/features/auth/screens/new_password_screen.dart';
import 'package:advocat/l10n/app_localizations.dart';
import 'package:advocat/services/supabase_service.dart';
import 'package:advocat/shared/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

class FakeSupabaseService extends SupabaseService {
  int updatePasswordCallCount = 0;
  String? lastNewPassword;
  Object? updatePasswordError;

  @override
  Future<void> updatePassword(String newPassword) async {
    updatePasswordCallCount++;
    lastNewPassword = newPassword;
    if (updatePasswordError != null) throw updatePasswordError!;
  }
}

/// Mounts the screen behind a minimal GoRouter so `context.go`/`canPop`
/// behave like production. `pushed: true` mirrors the Settings entry point
/// (screen pushed on top of a home route); `pushed: false` mirrors the
/// recovery deep link (no stack below).
Widget buildApp(
  FakeSupabaseService fake, {
  required GoRouter router,
}) {
  return ProviderScope(
    overrides: [
      supabaseServiceProvider.overrideWithValue(fake),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    ),
  );
}

GoRouter makeRouter({String initialLocation = '/new-password'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, __) => const Scaffold(body: Text('HOME-MARKER')),
      ),
      GoRoute(
        path: '/new-password',
        builder: (_, __) => const NewPasswordScreen(),
      ),
    ],
  );
}

Future<void> pumpScreen(WidgetTester tester, FakeSupabaseService fake,
    {GoRouter? router}) async {
  await tester.pumpWidget(buildApp(fake, router: router ?? makeRouter()));
  await tester.pumpAndSettle();
}

Finder get _passwordField => find.byType(TextFormField).first;
Finder get _confirmField => find.byType(TextFormField).last;
Finder get _saveButton => find.byType(AppButton);

void main() {
  group('NewPasswordScreen — rendering', () {
    testWidgets('shows title, hint, two password fields and save button',
        (tester) async {
      await pumpScreen(tester, FakeSupabaseService());

      expect(find.text('Set a new password'), findsOneWidget);
      expect(
        find.text('Enter and confirm a new password for your account.'),
        findsOneWidget,
      );
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Save new password'), findsOneWidget);
    });
  });

  group('NewPasswordScreen — validation', () {
    testWidgets('empty fields → required errors, no service call',
        (tester) async {
      final fake = FakeSupabaseService();
      await pumpScreen(tester, fake);

      await tester.tap(_saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Password is required'), findsNWidgets(2));
      expect(fake.updatePasswordCallCount, 0);
    });

    testWidgets('short password → too-short error, no service call',
        (tester) async {
      final fake = FakeSupabaseService();
      await pumpScreen(tester, fake);

      await tester.enterText(_passwordField, 'short');
      await tester.enterText(_confirmField, 'short');
      await tester.tap(_saveButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 8 characters'),
        findsOneWidget,
      );
      expect(fake.updatePasswordCallCount, 0);
    });

    testWidgets('mismatched confirmation → mismatch error, no service call',
        (tester) async {
      final fake = FakeSupabaseService();
      await pumpScreen(tester, fake);

      await tester.enterText(_passwordField, 'correct-horse-1');
      await tester.enterText(_confirmField, 'different-horse-2');
      await tester.tap(_saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(fake.updatePasswordCallCount, 0);
    });
  });

  group('NewPasswordScreen — submit', () {
    testWidgets(
        'valid input → updatePassword called once and navigates home '
        '(recovery deep link: no stack below)', (tester) async {
      final fake = FakeSupabaseService();
      await pumpScreen(tester, fake);

      await tester.enterText(_passwordField, 'correct-horse-1');
      await tester.enterText(_confirmField, 'correct-horse-1');
      await tester.tap(_saveButton);
      await tester.pumpAndSettle();

      expect(fake.updatePasswordCallCount, 1);
      expect(fake.lastNewPassword, 'correct-horse-1');
      expect(find.text('HOME-MARKER'), findsOneWidget,
          reason: 'success with empty stack must land on /home');
    });

    testWidgets('valid input from Settings push → pops back', (tester) async {
      final fake = FakeSupabaseService();
      final router = makeRouter(initialLocation: '/home');
      await pumpScreen(tester, fake, router: router);
      unawaited(router.push('/new-password'));
      await tester.pumpAndSettle();
      expect(find.text('Set a new password'), findsOneWidget);

      await tester.enterText(_passwordField, 'correct-horse-1');
      await tester.enterText(_confirmField, 'correct-horse-1');
      await tester.tap(_saveButton);
      await tester.pumpAndSettle();

      expect(fake.updatePasswordCallCount, 1);
      expect(find.text('HOME-MARKER'), findsOneWidget,
          reason: 'success from a pushed route must pop back to Settings');
    });

    testWidgets('AuthException → stays on screen, shows server message',
        (tester) async {
      final fake = FakeSupabaseService()
        ..updatePasswordError =
            const AuthException('Password is too weak.');
      await pumpScreen(tester, fake);

      await tester.enterText(_passwordField, 'correct-horse-1');
      await tester.enterText(_confirmField, 'correct-horse-1');
      await tester.tap(_saveButton);
      await tester.pumpAndSettle();

      expect(fake.updatePasswordCallCount, 1);
      expect(find.text('Set a new password'), findsOneWidget,
          reason: 'failure must keep the user on the screen');
      expect(find.text('Password is too weak.'), findsOneWidget,
          reason: 'server error message surfaces in a snackbar');
      expect(find.text('HOME-MARKER'), findsNothing);
    });

    testWidgets('generic error → fallback localized error message',
        (tester) async {
      final fake = FakeSupabaseService();
      await pumpScreen(tester, fake);
      // Non-AuthException → controller builds a fallback message containing
      // the raw error; the screen shows whatever the controller stored.
      fake.updatePasswordError = Exception('boom');

      await tester.enterText(_passwordField, 'correct-horse-1');
      await tester.enterText(_confirmField, 'correct-horse-1');
      await tester.tap(_saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Set a new password'), findsOneWidget);
      expect(find.textContaining('boom'), findsOneWidget);
    });
  });
}
