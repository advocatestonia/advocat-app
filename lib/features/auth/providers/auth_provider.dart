import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../models/user.dart';
import '../../../services/demo_data.dart';
import '../../../services/supabase_service.dart';
import '../../case_memory/state/active_case_provider.dart'
    show kActiveCaseIdPrefKey;
import '../../case_memory/state/intake_wizard_state.dart'
    show kIntakeDraftPrefKey;

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
        // Set initial state from auth metadata (fast, synchronous)
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
        // Then load full profile from database (async, updates state)
        _loadProfileFromDatabase();
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Load the user's full profile from the Supabase `profiles` table.
  ///
  /// This enriches the auth state with data that may not be present in
  /// the auth metadata (e.g. full_name saved only to profiles).
  Future<void> _loadProfileFromDatabase() async {
    try {
      final profile = await _supabase.getUserProfile();
      if (profile != null && mounted) {
        state = AuthState(
          status: AuthStatus.authenticated,
          appUser: profile,
        );
      }

      // Ensure Google OAuth email is saved in profiles table
      try {
        final currentEmail =
            Supabase.instance.client.auth.currentUser?.email;
        if (currentEmail != null && currentEmail.isNotEmpty) {
          final profileEmail = profile?.email;
          if (profileEmail == null || profileEmail.isEmpty) {
            final userId =
                Supabase.instance.client.auth.currentUser?.id;
            if (userId != null) {
              await Supabase.instance.client
                  .from('profiles')
                  .update({'email': currentEmail}).eq('id', userId);
            }
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Failed to sync email to profile: $e');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to load profile from database: $e');
      // Keep the metadata-based state; not critical.
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
        // Set initial state from auth metadata (immediate)
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
        // Load full profile from DB to get accurate full_name
        await _loadProfileFromDatabase();
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
        // Save profile to profiles table so it persists across sessions
        try {
          await _supabase.updateUserProfile({
            'full_name': name,
            'email': email,
            'preferred_language': language,
          });
        } catch (e) {
          if (kDebugMode) debugPrint('Failed to save profile after register: $e');
        }

        // B2B silent lead detection — if the signup email comes from a law-
        // firm domain, fire a `law_firm_email_domain` signal. The score it
        // contributes (100) instantly crosses the threshold and the next
        // session-check flips the B2B modal pending flag server-side.
        //
        // Fire-and-forget: NEVER block the signup flow. The edge fn is rate-
        // limited and idempotent within the hour, so a stalled request, a
        // 5xx, or a missing edge deployment all degrade silently — the user
        // is already authenticated and the worst case is a missed lead, not
        // a broken registration.
        if (_isLawFirmEmailDomain(email)) {
          unawaited(
            _supabase.callEdgeFunction(
              'b2b-signal',
              body: {
                'signal_type': 'law_firm_email_domain',
                'payload': {
                  'source': 'signup',
                  'email_domain': email
                      .substring(email.lastIndexOf('@') + 1)
                      .toLowerCase(),
                },
              },
            ).catchError((Object e) {
              if (kDebugMode) {
                debugPrint('b2b-signal (signup) failed: $e');
              }
              return <String, dynamic>{'error': e.toString()};
            }),
          );
        }
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
          .signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'https://advocat.ee/app.html',
      );
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

  /// Sign in with Apple OAuth.
  ///
  /// Requires Apple OAuth provider to be enabled in Supabase Auth settings
  /// (Authentication → Providers → Apple) with a valid Service ID and Key.
  Future<void> loginWithApple() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await Supabase.instance.client.auth
          .signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'https://advocat.ee/app.html',
      );
      // OAuth redirects the browser; on return _init() picks up the session.
    } on AuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Apple login error: $e');
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Apple sign-in failed: ${e.toString()}',
      );
    }
  }

  /// Sign out the current user.
  ///
  /// Security: F1 (WAVE 1, 2026-05-28) — purge SharedPreferences of all
  /// legal-content caches before flipping to unauthenticated. Without this
  /// sweep, a residual `intake_draft`, `contract_review_handoff_v1`, or
  /// `active_case_id` survives logout and is readable by the next user on
  /// a shared device (or any XSS on web, where prefs map to `localStorage`).
  /// Bar-association privilege rules treat such residue as a confidentiality
  /// breach, so we err on the side of over-purging — anything that smells
  /// like case content is wiped.
  Future<void> logout() async {
    try {
      await _supabase.signOut();
    } catch (_) {}

    // Purge legal-content caches from SharedPreferences. Best-effort: if
    // prefs is unavailable (test stub etc.), we still flip to unauth so the
    // UI doesn't get stuck.
    try {
      await purgeLegalPrefs();
    } catch (_) {
      // Non-fatal — the auth state transition below is the priority.
    }

    _ref.read(isDemoModeProvider.notifier).state = false;
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Visible-for-testing helper that wipes every known legal-content key
  /// out of SharedPreferences. Called from [logout]; exposed so the
  /// regression test (`test/auth/logout_purge_test.dart`) can call it
  /// directly without having to mock the full Supabase signOut path.
  ///
  /// Strategy:
  ///   1. Remove a hard-coded allowlist of known keys (the ones we KNOW
  ///      hold attorney-client material today).
  ///   2. Sweep any key starting with `case_`, `draft_`, `vault_`,
  ///      `intake_`, or `pending_checkout_` — future code can add new
  ///      keys under those prefixes without having to remember to update
  ///      this list.
  @visibleForTesting
  static Future<void> purgeLegalPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Explicit keys — fast path.
    const explicit = <String>[
      'contract_review_handoff_v1',
      kIntakeDraftPrefKey,
      kActiveCaseIdPrefKey,
      'pending_checkout',
    ];
    for (final k in explicit) {
      await prefs.remove(k);
    }

    // 2. Prefix sweep — catches any future legal-content key without
    //    requiring this list to be kept in sync.
    const purgePrefixes = <String>[
      'case_',
      'draft_',
      'vault_',
      'intake_',
      'pending_checkout_',
    ];
    final allKeys = prefs.getKeys().toList(growable: false);
    for (final k in allKeys) {
      for (final prefix in purgePrefixes) {
        if (k.startsWith(prefix)) {
          await prefs.remove(k);
          break;
        }
      }
    }
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

  // ──────────────────────────────────────────────────────────────────────
  // B2B lead detection — law-firm email domain heuristic
  // ──────────────────────────────────────────────────────────────────────
  //
  // Mirrors the server-side check in supabase/functions/b2b-signal/signals.ts.
  // Kept in sync MANUALLY — if you add/remove a domain or prefix on one
  // side, change the other in the same commit. The two layers are
  // intentionally redundant (defence in depth + zero round-trip for the
  // happy "civilian email" path) and a divergence is harmless: server-side
  // is authoritative (it owns the scoring).
  //
  // Returns true when the email's @-suffix looks like a law-firm domain.

  static const _exactLawFirmDomains = <String>{
    // Estonia
    'advokaadibüroo.ee', 'advokaadiburoo.ee',
    'advokatuur.ee', 'law.ee', 'advokaat.ee',
    // Finland
    'asianajotoimisto.fi', 'law.fi', 'asianajaja.fi', 'lakitoimisto.fi',
    // Germany / DACH
    'kanzlei.de', 'rechtsanwalt.de', 'rechtsanwaelte.de', 'anwalt.de',
    'kanzlei.at', 'anwalt.at',
    // Nordics
    'advokatbyra.se', 'advokatfirma.no', 'advokatfirma.dk',
    // UK / Ireland
    'solicitors.co.uk', 'barristers.co.uk',
    // EU-wide
    'law-firm.eu', 'lawfirm.eu',
  };

  static final _lawFirmPrefixPatterns = <RegExp>[
    RegExp(r'^advokaadi[- ].+\..+'),
    RegExp(r'^advokaat-.+\..+'),
    RegExp(r'^advokatuuri.+\..+'),
    RegExp(r'^asianajo-.+\..+'),
    RegExp(r'^asianajotoimisto-.+\..+'),
    RegExp(r'^kanzlei-.+\..+'),
    RegExp(r'^anwalt-.+\..+'),
    RegExp(r'^advokat-.+\..+'),
    RegExp(r'^lawfirm-.+\..+'),
  ];

  bool _isLawFirmEmailDomain(String email) {
    final at = email.lastIndexOf('@');
    if (at < 0 || at == email.length - 1) return false;
    final domain = email.substring(at + 1).trim().toLowerCase();
    if (domain.isEmpty) return false;
    if (_exactLawFirmDomains.contains(domain)) return true;
    if (domain.endsWith('.law')) return true;
    for (final re in _lawFirmPrefixPatterns) {
      if (re.hasMatch(domain)) return true;
    }
    return false;
  }
}
