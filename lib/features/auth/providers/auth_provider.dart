import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  // -- Initialization -------------------------------------------------------

  void _init() {
    final isDemo = _ref.read(isDemoModeProvider);
    if (isDemo) {
      state = AuthState(
        status: AuthStatus.authenticated,
        appUser: DemoData.user,
      );
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  // -- Public API -----------------------------------------------------------

  /// Enter demo mode — bypasses all backend authentication.
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
    // In demo mode or without backend, show error
    state = const AuthState(
      status: AuthStatus.error,
      errorMessage: 'Backend not configured. Use Demo Mode instead.',
    );
  }

  /// Register a new account.
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String language,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    state = const AuthState(
      status: AuthStatus.error,
      errorMessage: 'Backend not configured. Use Demo Mode instead.',
    );
  }

  /// Sign in with Google OAuth.
  Future<void> loginWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    state = const AuthState(
      status: AuthStatus.error,
      errorMessage: 'Backend not configured. Use Demo Mode instead.',
    );
  }

  /// Sign out the current user.
  Future<void> logout() async {
    _ref.read(isDemoModeProvider.notifier).state = false;
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Send a password reset email.
  Future<bool> resetPassword(String email) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    state = const AuthState(
      status: AuthStatus.error,
      errorMessage: 'Backend not configured.',
    );
    return false;
  }

  /// Clear any error and return to unauthenticated state.
  void clearError() {
    if (state.hasError) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }
}
