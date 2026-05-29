import 'package:advocat/features/auth/providers/auth_provider.dart';
import 'package:advocat/features/case_memory/models/user_case.dart';
import 'package:advocat/features/case_memory/state/active_case_provider.dart';
import 'package:advocat/models/user.dart';
import 'package:advocat/services/demo_data.dart';
import 'package:advocat/services/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../test_helpers.dart';

// ---------------------------------------------------------------------------
// Manual mock for SupabaseService
// ---------------------------------------------------------------------------

/// A hand-rolled mock so we avoid mockito's null-safety issues with
/// non-nullable String parameters.
class FakeSupabaseService extends SupabaseService {
  // -- signIn ---------------------------------------------------------------
  Future<AuthResponse> Function(String email, String password)?
      signInHandler;
  int signInCallCount = 0;
  String? lastSignInEmail;
  String? lastSignInPassword;

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    signInCallCount++;
    lastSignInEmail = email;
    lastSignInPassword = password;
    if (signInHandler != null) return signInHandler!(email, password);
    throw UnimplementedError('signIn not stubbed');
  }

  // -- signUp ---------------------------------------------------------------
  Future<AuthResponse> Function(
      String email, String password, Map<String, dynamic>? data)?
      signUpHandler;
  int signUpCallCount = 0;
  String? lastSignUpEmail;
  String? lastSignUpPassword;
  Map<String, dynamic>? lastSignUpData;

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    signUpCallCount++;
    lastSignUpEmail = email;
    lastSignUpPassword = password;
    lastSignUpData = data;
    if (signUpHandler != null) return signUpHandler!(email, password, data);
    throw UnimplementedError('signUp not stubbed');
  }

  // -- signOut --------------------------------------------------------------
  Future<void> Function()? signOutHandler;
  int signOutCallCount = 0;

  @override
  Future<void> signOut() async {
    signOutCallCount++;
    if (signOutHandler != null) return signOutHandler!();
  }

  // -- resetPassword --------------------------------------------------------
  Future<void> Function(String email)? resetPasswordHandler;
  int resetPasswordCallCount = 0;
  String? lastResetEmail;

  @override
  Future<void> resetPassword(String email) async {
    resetPasswordCallCount++;
    lastResetEmail = email;
    if (resetPasswordHandler != null) return resetPasswordHandler!(email);
  }

  // -- getUserProfile -------------------------------------------------------
  Future<AppUser?> Function()? getUserProfileHandler;

  @override
  Future<AppUser?> getUserProfile() async {
    if (getUserProfileHandler != null) return getUserProfileHandler!();
    return null;
  }

  // -- updateUserProfile ----------------------------------------------------
  Future<void> Function(Map<String, dynamic>)? updateUserProfileHandler;
  Map<String, dynamic>? lastProfileUpdate;

  @override
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    lastProfileUpdate = updates;
    if (updateUserProfileHandler != null) {
      return updateUserProfileHandler!(updates);
    }
  }
}

// ---------------------------------------------------------------------------
// Helper: create a ProviderContainer that overrides supabaseServiceProvider
// and starts in demo mode (so _init() skips the Supabase.instance call).
// ---------------------------------------------------------------------------

ProviderContainer _createContainer({
  FakeSupabaseService? fakeSupabase,
  bool startInDemoMode = true,
}) {
  final fake = fakeSupabase ?? FakeSupabaseService();
  final container = ProviderContainer(
    overrides: [
      supabaseServiceProvider.overrideWithValue(fake),
      if (startInDemoMode) isDemoModeProvider.overrideWith((ref) => true),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ========================================================================
  // AuthStatus enum
  // ========================================================================

  group('AuthStatus', () {
    test('has exactly 5 values', () {
      expect(AuthStatus.values.length, 5);
    });

    test('contains all expected values', () {
      expect(
        AuthStatus.values,
        containsAll([
          AuthStatus.initial,
          AuthStatus.loading,
          AuthStatus.authenticated,
          AuthStatus.unauthenticated,
          AuthStatus.error,
        ]),
      );
    });
  });

  // ========================================================================
  // AuthState — pure data class
  // ========================================================================

  group('AuthState', () {
    test('default constructor has initial status, null user and error', () {
      const state = AuthState();
      expect(state.status, AuthStatus.initial);
      expect(state.appUser, isNull);
      expect(state.errorMessage, isNull);
    });

    test('isLoading returns true only for loading status', () {
      const loading = AuthState(status: AuthStatus.loading);
      const notLoading = AuthState(status: AuthStatus.authenticated);
      expect(loading.isLoading, isTrue);
      expect(notLoading.isLoading, isFalse);
    });

    test('isAuthenticated returns true only for authenticated status', () {
      const auth = AuthState(status: AuthStatus.authenticated);
      const notAuth = AuthState(status: AuthStatus.unauthenticated);
      expect(auth.isAuthenticated, isTrue);
      expect(notAuth.isAuthenticated, isFalse);
    });

    test('hasError returns true only for error status', () {
      const err = AuthState(status: AuthStatus.error);
      const noErr = AuthState(status: AuthStatus.initial);
      expect(err.hasError, isTrue);
      expect(noErr.hasError, isFalse);
    });

    group('copyWith', () {
      test('copies status', () {
        const state = AuthState(status: AuthStatus.initial);
        final copy = state.copyWith(status: AuthStatus.loading);
        expect(copy.status, AuthStatus.loading);
        expect(copy.appUser, isNull);
      });

      test('copies appUser', () {
        final user = makeUser();
        const state = AuthState();
        final copy = state.copyWith(appUser: user);
        expect(copy.appUser, same(user));
        expect(copy.status, AuthStatus.initial);
      });

      test('sets errorMessage to null when not provided', () {
        const state = AuthState(
          status: AuthStatus.error,
          errorMessage: 'some error',
        );
        final copy = state.copyWith(status: AuthStatus.loading);
        // errorMessage defaults to null in copyWith (not preserved)
        expect(copy.errorMessage, isNull);
      });

      test('preserves status when not provided', () {
        const state = AuthState(status: AuthStatus.authenticated);
        final copy = state.copyWith(errorMessage: 'msg');
        expect(copy.status, AuthStatus.authenticated);
      });

      test('preserves appUser when not provided', () {
        final user = makeUser();
        final state = AuthState(
          status: AuthStatus.authenticated,
          appUser: user,
        );
        final copy = state.copyWith(status: AuthStatus.loading);
        expect(copy.appUser, same(user));
      });
    });

    group('convenience getters for every status', () {
      test('isLoading false for all non-loading statuses', () {
        for (final s in AuthStatus.values) {
          final state = AuthState(status: s);
          expect(state.isLoading, s == AuthStatus.loading);
        }
      });

      test('isAuthenticated false for all non-authenticated statuses', () {
        for (final s in AuthStatus.values) {
          final state = AuthState(status: s);
          expect(state.isAuthenticated, s == AuthStatus.authenticated);
        }
      });

      test('hasError false for all non-error statuses', () {
        for (final s in AuthStatus.values) {
          final state = AuthState(status: s);
          expect(state.hasError, s == AuthStatus.error);
        }
      });
    });
  });

  // ========================================================================
  // AuthController — demo mode initialisation
  // ========================================================================

  group('AuthController — demo mode', () {
    test('initialises as authenticated with DemoData user', () {
      final container = _createContainer(startInDemoMode: true);
      final state = container.read(authControllerProvider);

      expect(state.status, AuthStatus.authenticated);
      expect(state.appUser, isNotNull);
      expect(state.appUser!.id, DemoData.user.id);
    });
  });

  // ========================================================================
  // AuthController — enterDemoMode
  // ========================================================================

  group('AuthController — enterDemoMode', () {
    test('sets demo flag and authenticated with DemoData user', () {
      final container = _createContainer(startInDemoMode: true);
      final controller = container.read(authControllerProvider.notifier);

      controller.enterDemoMode();

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.authenticated);
      expect(state.appUser!.id, DemoData.user.id);
      expect(container.read(isDemoModeProvider), isTrue);
    });
  });

  // ========================================================================
  // AuthController — login
  // ========================================================================

  group('AuthController — login', () {
    test('sets loading state before calling signIn', () async {
      final fake = FakeSupabaseService();
      final container = _createContainer(fakeSupabase: fake);
      final controller = container.read(authControllerProvider.notifier);

      // Make signIn hang so we can inspect the loading state
      fake.signInHandler = (email, password) =>
          Future.delayed(const Duration(seconds: 10),
              () => AuthResponse(session: null, user: null));

      // Fire login without awaiting
      final loginFuture = controller.login('test@test.ee', 'password123');

      // Give microtask queue a chance to run
      await Future.delayed(Duration.zero);

      final state = container.read(authControllerProvider);
      expect(state.isLoading, isTrue);
      expect(state.errorMessage, isNull);

      loginFuture.ignore();
    });

    test('sets error state when signIn returns null user', () async {
      final fake = FakeSupabaseService();
      final container = _createContainer(fakeSupabase: fake);
      final controller = container.read(authControllerProvider.notifier);

      fake.signInHandler = (_, __) async =>
          AuthResponse(session: null, user: null);

      await controller.login('test@test.ee', 'password123');

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, contains('Login failed'));
    });

    test('sets error state on AuthException', () async {
      final fake = FakeSupabaseService();
      final container = _createContainer(fakeSupabase: fake);
      final controller = container.read(authControllerProvider.notifier);

      fake.signInHandler = (_, __) =>
          throw const AuthException('Invalid login credentials');

      await controller.login('test@test.ee', 'wrong');

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, 'Invalid login credentials');
    });

    test('sets error state on generic exception', () async {
      final fake = FakeSupabaseService();
      final container = _createContainer(fakeSupabase: fake);
      final controller = container.read(authControllerProvider.notifier);

      fake.signInHandler = (_, __) => throw Exception('Network error');

      await controller.login('test@test.ee', 'password123');

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, contains('Login failed'));
      expect(state.errorMessage, contains('Network error'));
    });
  });

  // ========================================================================
  // AuthController — register
  // ========================================================================

  group('AuthController — register', () {
    test('sets loading state before calling signUp', () async {
      final fake = FakeSupabaseService();
      final container = _createContainer(fakeSupabase: fake);
      final controller = container.read(authControllerProvider.notifier);

      fake.signUpHandler = (_, __, ___) =>
          Future.delayed(const Duration(seconds: 10),
              () => AuthResponse(session: null, user: null));

      final registerFuture = controller.register(
        name: 'Test',
        email: 'test@test.ee',
        password: 'password123',
        language: 'et',
      );

      await Future.delayed(Duration.zero);

      final state = container.read(authControllerProvider);
      expect(state.isLoading, isTrue);

      registerFuture.ignore();
    });

    test('sets error state when signUp returns null user', () async {
      final fake = FakeSupabaseService();
      final container = _createContainer(fakeSupabase: fake);
      final controller = container.read(authControllerProvider.notifier);

      fake.signUpHandler = (_, __, ___) async =>
          AuthResponse(session: null, user: null);

      await controller.register(
        name: 'Test',
        email: 'test@test.ee',
        password: 'password123',
        language: 'et',
      );

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, contains('check your email'));
    });

    test('passes correct data to signUp', () async {
      final fake = FakeSupabaseService();
      final container = _createContainer(fakeSupabase: fake);
      final controller = container.read(authControllerProvider.notifier);

      fake.signUpHandler = (_, __, ___) async =>
          AuthResponse(session: null, user: null);

      await controller.register(
        name: 'John Doe',
        email: 'john@test.ee',
        password: 'securePass1!',
        language: 'fi',
      );

      expect(fake.lastSignUpEmail, 'john@test.ee');
      expect(fake.lastSignUpPassword, 'securePass1!');
      expect(fake.lastSignUpData, {
        'full_name': 'John Doe',
        'preferred_language': 'fi',
      });
    });

    test('sets error state on AuthException', () async {
      final fake = FakeSupabaseService();
      final container = _createContainer(fakeSupabase: fake);
      final controller = container.read(authControllerProvider.notifier);

      fake.signUpHandler = (_, __, ___) =>
          throw const AuthException('User already registered');

      await controller.register(
        name: 'Test',
        email: 'exists@test.ee',
        password: 'password123',
        language: 'et',
      );

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, 'User already registered');
    });

    test('sets error state on generic exception', () async {
      final fake = FakeSupabaseService();
      final container = _createContainer(fakeSupabase: fake);
      final controller = container.read(authControllerProvider.notifier);

      fake.signUpHandler = (_, __, ___) =>
          throw Exception('Server unavailable');

      await controller.register(
        name: 'Test',
        email: 'test@test.ee',
        password: 'password123',
        language: 'et',
      );

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, contains('Registration failed'));
      expect(state.errorMessage, contains('Server unavailable'));
    });
  });

  // ========================================================================
  // AuthController — logout
  // ========================================================================

  group('AuthController — logout', () {
    test('sets unauthenticated state and clears demo mode', () async {
      final fake = FakeSupabaseService();
      final container = _createContainer(fakeSupabase: fake);
      final controller = container.read(authControllerProvider.notifier);

      fake.signOutHandler = () async {};

      await controller.logout();

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.appUser, isNull);
      expect(container.read(isDemoModeProvider), isFalse);
    });

    test('sets unauthenticated even when signOut throws', () async {
      final fake = FakeSupabaseService();
      final container = _createContainer(fakeSupabase: fake);
      final controller = container.read(authControllerProvider.notifier);

      fake.signOutHandler = () => throw Exception('Network error');

      await controller.logout();

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.appUser, isNull);
    });

    test('calls signOut on SupabaseService', () async {
      final fake = FakeSupabaseService();
      final container = _createContainer(fakeSupabase: fake);
      final controller = container.read(authControllerProvider.notifier);

      fake.signOutHandler = () async {};

      await controller.logout();

      expect(fake.signOutCallCount, 1);
    });

    test('purges in-memory active-case state (shared-device leak fix)',
        () async {
      // On web context.go() does not reload the page, so the non-autoDispose
      // activeCaseProvider would otherwise carry the previous user's case into
      // the next session. logout() must invalidate it.
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final fake = FakeSupabaseService();
      final container = _createContainer(fakeSupabase: fake);
      final controller = container.read(authControllerProvider.notifier);
      fake.signOutHandler = () async {};

      final now = DateTime.utc(2026, 5, 30);
      await container.read(activeCaseProvider.notifier).setActiveCase(
            UserCase(
              id: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
              userId: 'user-A',
              title: 'Privileged: Sulga v. Finland',
              jurisdiction: 'FI',
              createdAt: now,
              updatedAt: now,
            ),
          );
      expect(container.read(activeCaseProvider).activeCaseId,
          'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
          reason: 'precondition: a case is active before logout');

      await controller.logout();

      expect(container.read(activeCaseProvider).activeCaseId, isNull,
          reason: 'active case must not survive logout into the next session');
    });
  });

  // ========================================================================
  // AuthController — resetPassword
  // ========================================================================

  group('AuthController — resetPassword', () {
    test('returns true and sets unauthenticated on success', () async {
      final fake = FakeSupabaseService();
      final container = _createContainer(fakeSupabase: fake);
      final controller = container.read(authControllerProvider.notifier);

      fake.resetPasswordHandler = (_) async {};

      final result = await controller.resetPassword('test@test.ee');

      expect(result, isTrue);
      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.unauthenticated);
    });

    test('passes the correct email to SupabaseService', () async {
      final fake = FakeSupabaseService();
      final container = _createContainer(fakeSupabase: fake);
      final controller = container.read(authControllerProvider.notifier);

      fake.resetPasswordHandler = (_) async {};

      await controller.resetPassword('specific@email.com');

      expect(fake.lastResetEmail, 'specific@email.com');
    });

    test('returns false and sets error on AuthException', () async {
      final fake = FakeSupabaseService();
      final container = _createContainer(fakeSupabase: fake);
      final controller = container.read(authControllerProvider.notifier);

      fake.resetPasswordHandler = (_) =>
          throw const AuthException('User not found');

      final result = await controller.resetPassword('nobody@test.ee');

      expect(result, isFalse);
      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, 'User not found');
    });

    test('returns false and sets error on generic exception', () async {
      final fake = FakeSupabaseService();
      final container = _createContainer(fakeSupabase: fake);
      final controller = container.read(authControllerProvider.notifier);

      fake.resetPasswordHandler = (_) => throw Exception('Timeout');

      final result = await controller.resetPassword('test@test.ee');

      expect(result, isFalse);
      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, contains('Password reset failed'));
    });

    test('sets loading before resolving', () async {
      final fake = FakeSupabaseService();
      final container = _createContainer(fakeSupabase: fake);
      final controller = container.read(authControllerProvider.notifier);

      fake.resetPasswordHandler = (_) =>
          Future.delayed(const Duration(seconds: 10));

      final resetFuture = controller.resetPassword('test@test.ee');

      await Future.delayed(Duration.zero);

      final state = container.read(authControllerProvider);
      expect(state.isLoading, isTrue);

      resetFuture.ignore();
    });
  });

  // ========================================================================
  // AuthController — clearError
  // ========================================================================

  group('AuthController — clearError', () {
    test('clears error state to unauthenticated', () async {
      final fake = FakeSupabaseService();
      final container = _createContainer(fakeSupabase: fake);
      final controller = container.read(authControllerProvider.notifier);

      // Put controller into error state
      fake.signInHandler = (_, __) =>
          throw const AuthException('Bad credentials');
      await controller.login('test@test.ee', 'wrong');

      expect(container.read(authControllerProvider).hasError, isTrue);

      controller.clearError();

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.unauthenticated);
      expect(state.errorMessage, isNull);
    });

    test('does nothing when state is not error', () {
      final container = _createContainer(startInDemoMode: true);
      final controller = container.read(authControllerProvider.notifier);

      // State is authenticated (demo mode)
      expect(container.read(authControllerProvider).isAuthenticated, isTrue);

      controller.clearError();

      // Still authenticated
      expect(container.read(authControllerProvider).isAuthenticated, isTrue);
    });

    test('does nothing when state is loading', () async {
      final fake = FakeSupabaseService();
      final container = _createContainer(fakeSupabase: fake);
      final controller = container.read(authControllerProvider.notifier);

      fake.signInHandler = (_, __) =>
          Future.delayed(const Duration(seconds: 10),
              () => AuthResponse(session: null, user: null));

      final loginFuture = controller.login('a@b.com', 'p');
      await Future.delayed(Duration.zero);

      expect(container.read(authControllerProvider).isLoading, isTrue);

      controller.clearError();

      // Still loading — clearError only acts on error state
      expect(container.read(authControllerProvider).isLoading, isTrue);

      loginFuture.ignore();
    });
  });

  // ========================================================================
  // isAuthenticatedProvider — derived provider
  // ========================================================================

  group('isAuthenticatedProvider', () {
    test('returns true when authController is authenticated', () {
      final container = _createContainer(startInDemoMode: true);
      expect(container.read(isAuthenticatedProvider), isTrue);
    });

    test('returns false after logout', () async {
      final fake = FakeSupabaseService();
      final container = _createContainer(fakeSupabase: fake);
      fake.signOutHandler = () async {};

      await container.read(authControllerProvider.notifier).logout();

      expect(container.read(isAuthenticatedProvider), isFalse);
    });
  });

  // ========================================================================
  // Edge cases
  // ========================================================================

  group('Edge cases', () {
    test('login with empty email still calls signIn', () async {
      final fake = FakeSupabaseService();
      final container = _createContainer(fakeSupabase: fake);
      final controller = container.read(authControllerProvider.notifier);

      fake.signInHandler = (_, __) =>
          throw const AuthException('Invalid email');

      await controller.login('', 'password123');

      expect(fake.signInCallCount, 1);
      expect(fake.lastSignInEmail, '');
      expect(fake.lastSignInPassword, 'password123');
      expect(container.read(authControllerProvider).hasError, isTrue);
    });

    test('login with empty password still calls signIn', () async {
      final fake = FakeSupabaseService();
      final container = _createContainer(fakeSupabase: fake);
      final controller = container.read(authControllerProvider.notifier);

      fake.signInHandler = (_, __) =>
          throw const AuthException('Password required');

      await controller.login('test@test.ee', '');

      expect(fake.signInCallCount, 1);
      expect(fake.lastSignInEmail, 'test@test.ee');
      expect(fake.lastSignInPassword, '');
      expect(container.read(authControllerProvider).hasError, isTrue);
    });

    test('register with empty name passes empty string to backend', () async {
      final fake = FakeSupabaseService();
      final container = _createContainer(fakeSupabase: fake);
      final controller = container.read(authControllerProvider.notifier);

      fake.signUpHandler = (_, __, ___) async =>
          AuthResponse(session: null, user: null);

      await controller.register(
        name: '',
        email: 'test@test.ee',
        password: 'password123',
        language: 'et',
      );

      expect(fake.signUpCallCount, 1);
      expect(fake.lastSignUpData!['full_name'], '');
    });

    test('multiple rapid logins do not corrupt state', () async {
      final fake = FakeSupabaseService();
      final container = _createContainer(fakeSupabase: fake);
      final controller = container.read(authControllerProvider.notifier);

      fake.signInHandler = (_, __) =>
          throw const AuthException('Error');

      // Fire multiple logins sequentially
      await controller.login('a@b.com', 'p1');
      await controller.login('c@d.com', 'p2');
      await controller.login('e@f.com', 'p3');

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.error);
      expect(fake.signInCallCount, 3);
    });

    test('logout then login is valid flow', () async {
      final fake = FakeSupabaseService();
      final container = _createContainer(fakeSupabase: fake);
      final controller = container.read(authControllerProvider.notifier);

      fake.signOutHandler = () async {};
      fake.signInHandler = (_, __) =>
          throw const AuthException('Bad credentials');

      await controller.logout();
      expect(container.read(authControllerProvider).status,
          AuthStatus.unauthenticated);

      await controller.login('test@test.ee', 'pass');
      expect(container.read(authControllerProvider).status, AuthStatus.error);
    });

    test('clearError after enterDemoMode does nothing', () {
      final container = _createContainer(startInDemoMode: true);
      final controller = container.read(authControllerProvider.notifier);

      controller.enterDemoMode();
      expect(container.read(authControllerProvider).isAuthenticated, isTrue);

      controller.clearError();

      expect(container.read(authControllerProvider).isAuthenticated, isTrue);
    });

    test('login error message is preserved until clearError', () async {
      final fake = FakeSupabaseService();
      final container = _createContainer(fakeSupabase: fake);
      final controller = container.read(authControllerProvider.notifier);

      fake.signInHandler = (_, __) =>
          throw const AuthException('Specific error message');

      await controller.login('a@b.com', 'p');

      // Error message is there
      expect(
        container.read(authControllerProvider).errorMessage,
        'Specific error message',
      );

      // clearError removes it
      controller.clearError();
      expect(container.read(authControllerProvider).errorMessage, isNull);
    });

    test('register error clears previous error message', () async {
      final fake = FakeSupabaseService();
      final container = _createContainer(fakeSupabase: fake);
      final controller = container.read(authControllerProvider.notifier);

      // First: trigger a login error
      fake.signInHandler = (_, __) =>
          throw const AuthException('Login error');
      await controller.login('a@b.com', 'p');
      expect(container.read(authControllerProvider).errorMessage,
          'Login error');

      // Then: trigger a register error
      fake.signUpHandler = (_, __, ___) =>
          throw const AuthException('Register error');
      await controller.register(
        name: 'X',
        email: 'x@x.com',
        password: 'p',
        language: 'en',
      );

      // The error message should be from register, not login
      expect(container.read(authControllerProvider).errorMessage,
          'Register error');
    });

    test('resetPassword with empty email still calls service', () async {
      final fake = FakeSupabaseService();
      final container = _createContainer(fakeSupabase: fake);
      final controller = container.read(authControllerProvider.notifier);

      fake.resetPasswordHandler = (_) async {};

      final result = await controller.resetPassword('');

      expect(result, isTrue);
      expect(fake.resetPasswordCallCount, 1);
      expect(fake.lastResetEmail, '');
    });
  });
}
