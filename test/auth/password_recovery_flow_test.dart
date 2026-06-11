// =============================================================================
// password_recovery_flow_test.dart — beta audit fix (Wave 1, 2026-06-11)
// =============================================================================
//
// Why this exists
// ---------------
// The 2026-06-11 beta-readiness audit flagged that password reset was a dead
// end: the recovery email signed the user in (AuthChangeEvent.passwordRecovery)
// but the app had no set-new-password screen and never reacted to the event.
//
// This file pins down the provider-layer half of the fix:
//   1. AuthController subscribes to the auth-event stream and flips
//      `passwordRecoveryPendingProvider` + marks the session authenticated
//      when a passwordRecovery event arrives (other events are ignored).
//   2. AuthController.updatePassword delegates to
//      SupabaseService.updatePassword, clears the pending flag on success,
//      and surfaces AuthException messages via AuthState.errorMessage.
//   3. SupabaseService.resetPassword carries an explicit redirectTo pointing
//      at the web deployment (https://advocat.ee/app.html) — same target as
//      the OAuth flows.
//
// The widget-layer half (NewPasswordScreen) lives in
// `new_password_screen_test.dart`.

@Tags(['fast'])
library;

import 'dart:async';

import 'package:advocat/features/auth/providers/auth_provider.dart';
import 'package:advocat/services/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

// ---------------------------------------------------------------------------
// Fake SupabaseService — controllable auth-event stream + updatePassword spy
// ---------------------------------------------------------------------------

class FakeSupabaseService extends SupabaseService {
  final authEvents = StreamController<supa.AuthState>.broadcast();

  @override
  Stream<supa.AuthState> get authStateChanges => authEvents.stream;

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

supa.AuthState _authEvent(supa.AuthChangeEvent event, {bool withSession = true}) {
  final session = withSession
      ? supa.Session(
          accessToken: 'access-token',
          tokenType: 'bearer',
          user: const supa.User(
            id: 'user-recovery-001',
            appMetadata: {},
            userMetadata: {
              'full_name': 'Recovery User',
              'preferred_language': 'fi',
            },
            aud: 'authenticated',
            email: 'recovery@advocat.ee',
            createdAt: '2026-01-01T00:00:00Z',
          ),
        )
      : null;
  return supa.AuthState(event, session);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSupabaseService fake;
  late ProviderContainer container;

  setUp(() {
    fake = FakeSupabaseService();
    // NOT in demo mode — the recovery listener is only attached on the real
    // auth path. Supabase.instance is uninitialised in tests, so _init()
    // falls through to unauthenticated, which is exactly what a fresh boot
    // from a recovery deep link looks like before the event arrives.
    container = ProviderContainer(
      overrides: [
        supabaseServiceProvider.overrideWithValue(fake),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(fake.authEvents.close);
  });

  Future<void> pumpEvents() => Future<void>.delayed(Duration.zero);

  group('passwordRecovery event listener', () {
    test('flips passwordRecoveryPendingProvider and authenticates the session',
        () async {
      // Instantiate the controller (subscribes to the stream in _init).
      final controller = container.read(authControllerProvider.notifier);
      expect(container.read(passwordRecoveryPendingProvider), isFalse);

      fake.authEvents.add(_authEvent(supa.AuthChangeEvent.passwordRecovery));
      await pumpEvents();

      expect(container.read(passwordRecoveryPendingProvider), isTrue,
          reason: 'passwordRecovery must flag the pending provider');
      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.authenticated,
          reason: 'the recovery session signs the user in');
      expect(state.appUser?.id, 'user-recovery-001');
      expect(state.appUser?.email, 'recovery@advocat.ee');
      expect(state.appUser?.preferredLanguage, 'fi');
      expect(controller, isNotNull);
    });

    test('ignores non-recovery events', () async {
      container.read(authControllerProvider.notifier);

      fake.authEvents.add(_authEvent(supa.AuthChangeEvent.signedIn));
      fake.authEvents.add(_authEvent(supa.AuthChangeEvent.tokenRefreshed));
      await pumpEvents();

      expect(container.read(passwordRecoveryPendingProvider), isFalse);
      expect(container.read(authControllerProvider).status,
          AuthStatus.unauthenticated);
    });

    test('recovery event without a session still flags the provider',
        () async {
      container.read(authControllerProvider.notifier);

      fake.authEvents.add(_authEvent(
        supa.AuthChangeEvent.passwordRecovery,
        withSession: false,
      ));
      await pumpEvents();

      expect(container.read(passwordRecoveryPendingProvider), isTrue);
      // No session → auth status untouched (stays unauthenticated).
      expect(container.read(authControllerProvider).status,
          AuthStatus.unauthenticated);
    });
  });

  group('AuthController.updatePassword', () {
    test('success: delegates to service, clears the recovery flag', () async {
      final controller = container.read(authControllerProvider.notifier);
      container.read(passwordRecoveryPendingProvider.notifier).state = true;

      final ok = await controller.updatePassword('new-secret-123');

      expect(ok, isTrue);
      expect(fake.updatePasswordCallCount, 1);
      expect(fake.lastNewPassword, 'new-secret-123');
      expect(container.read(passwordRecoveryPendingProvider), isFalse,
          reason: 'a successful update consumes the recovery flag');
      expect(container.read(authControllerProvider).errorMessage, isNull);
    });

    test('AuthException: returns false, surfaces message, keeps flag',
        () async {
      final controller = container.read(authControllerProvider.notifier);
      container.read(passwordRecoveryPendingProvider.notifier).state = true;
      fake.updatePasswordError = const supa.AuthException(
        'New password should be different from the old password.',
      );

      final ok = await controller.updatePassword('same-old-password');

      expect(ok, isFalse);
      expect(
        container.read(authControllerProvider).errorMessage,
        'New password should be different from the old password.',
      );
      expect(container.read(passwordRecoveryPendingProvider), isTrue,
          reason: 'a failed update must NOT consume the recovery flag');
    });

    test('generic error: returns false with a fallback message', () async {
      final controller = container.read(authControllerProvider.notifier);
      fake.updatePasswordError = Exception('network down');

      final ok = await controller.updatePassword('whatever-123');

      expect(ok, isFalse);
      expect(container.read(authControllerProvider).errorMessage,
          contains('network down'));
    });

    test('does not flip auth status on failure (user stays signed in)',
        () async {
      final controller = container.read(authControllerProvider.notifier);
      fake.authEvents.add(_authEvent(supa.AuthChangeEvent.passwordRecovery));
      await pumpEvents();
      expect(container.read(authControllerProvider).status,
          AuthStatus.authenticated);

      fake.updatePasswordError = const supa.AuthException('weak password');
      await controller.updatePassword('short');

      expect(container.read(authControllerProvider).status,
          AuthStatus.authenticated,
          reason: 'failure must not bounce the user out of the session');
    });
  });

  group('SupabaseService.resetPassword redirect contract', () {
    test('redirect URL points at the web app shell', () {
      // The reset-request call site passes this constant as redirectTo —
      // it must match the deployed app URL used by the OAuth flows.
      expect(
        SupabaseService.passwordResetRedirectUrl,
        'https://advocat.ee/app.html',
      );
    });
  });
}
