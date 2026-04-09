import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../models/user.dart';
import '../../../services/demo_data.dart';
import '../../../services/supabase_service.dart';

// ---------------------------------------------------------------------------
// Auth state
// ---------------------------------------------------------------------------

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  const AuthState({
    this.status = AuthStatus.initial,
    this.appUser,
    this.errorMessage,
  });

  final AuthStatus status;
  final AppUser? appUser;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? appUser,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      appUser: appUser ?? this.appUser,
      errorMessage: errorMessage,
    );
  }

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get hasError => status == AuthStatus.error;
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Whether the user is currently authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.isAuthenticated;
});

/// The current user's profile.
final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final isDemo = ref.watch(isDemoModeProvider);
  if (isDemo) return DemoData.user;

  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  if (!isAuthenticated) return null;
  return ref.watch(supabaseServiceProvider).getUserProfile();
});

/// Controller for auth actions.
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});

// ---------------------------------------------------------------------------
// Auth controller
// ---------------------------------------------------------------------------

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState()) {
    _init();
  }

  final Ref _ref;

  SupabaseService get _supabase => _ref.read(supabaseServiceProvider);

  // -- Initialization -------------------------------------------------------

  void _init() {
    final isDemo = _ref.read(isDemoModeProvider);
    if (isDemo) {
      state = AuthState(
        status: AuthStatus.authenticated,
        appUser: DemoData.user,
      );
      return;
    }

    // Check if user is already logged in via Supabase
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          appUser: AppUser(
            id: currentUser.id,
            email: currentUser.email ?? '',
            fullName: currentUser.userMetadata?['full_name'] as String? ?? '',
            preferredLanguage:
                currentUser.userMetadata?['preferred_language'] as String? ??
                    'et',
            createdAt: DateTime.tryParse(currentUser.createdAt) ?? DateTime.now(),
          ),
        );
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  // -- Public API -----------------------------------------------------------

  /// Enter demo mode -- bypasses all backend authentication.
  void enterDemoMode() {
    _ref.read(isDemoModeProvider.notifier).state = true;
    state = AuthState(
      status: AuthStatus.authenticated,
      appUser: DemoData.user,
    );
  }

  /// Sign in with email and password.
  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _supabase.signIn(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          appUser: AppUser(
            id: user.id,
            email: user.email ?? email,
            fullName: user.userMetadata?['full_name'] as String? ?? '',
            preferredLanguage:
                user.userMetadata?['preferred_language'] as String? ?? 'et',
            createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
          ),
        );
      } else {
        state = const AuthState(
          status: AuthStatus.error,
          errorMessage: 'Login failed. Please check your credentials.',
        );
      }
    } on AuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Login error: $e');
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Login failed: ${e.toString()}',
      );
    }
  }

  /// Register a new account.
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String language,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _supabase.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          'preferred_language': language,
        },
      );
      final user = response.user;
      if (user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          appUser: AppUser(
            id: user.id,
            email: user.email ?? email,
            fullName: name,
            preferredLanguage: language,
            createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
          ),
        );
      } else {
        state = const AuthState(
          status: AuthStatus.error,
          errorMessage:
              'Registration successful. Please check your email to confirm.',
        );
      }
    } on AuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Register error: $e');
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Registration failed: ${e.toString()}',
      );
    }
  }

  /// Sign in with Google OAuth.
  Future<void> loginWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await Supabase.instance.client.auth
          .signInWithOAuth(OAuthProvider.google);
      // OAuth redirects the browser; on return _init() picks up the session.
    } on AuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Google login error: $e');
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Google sign-in failed: ${e.toString()}',
      );
    }
  }

  /// Sign out the current user.
  Future<void> logout() async {
    try {
      await _supabase.signOut();
    } catch (_) {}
    _ref.read(isDemoModeProvider.notifier).state = false;
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Send a password reset email.
  Future<bool> resetPassword(String email) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _supabase.resetPassword(email);
      state = const AuthState(status: AuthStatus.unauthenticated);
      return true;
    } on AuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('Reset password error: $e');
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Password reset failed: ${e.toString()}',
      );
      return false;
    }
  }

  /// Clear any error and return to unauthenticated state.
  void clearError() {
    if (state.hasError) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }
}
