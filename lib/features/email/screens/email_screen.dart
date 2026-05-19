import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
// Re-import Supabase's AuthState under an alias so we can type-annotate the
// auth-stream subscription. The bare import above hides AuthState because a
// future merge with auth_provider.dart's own AuthState would otherwise
// collide.
import 'package:supabase_flutter/supabase_flutter.dart' as sb
    show AuthState, AuthChangeEvent;

import '../../../config/feature_flags.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/oauth_storage_service.dart';
import '../../../shared/constants/app_icons.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../widgets/gmail_reauth_banner.dart';

// ── State ────────────────────────────────────────────────────────────────

enum _EmailProvider { gmail, outlook, icloud, yahoo }

/// User-facing connection-error kinds. Notifier code is widget-context-free,
/// so we cannot resolve the localized string here — the widget maps this
/// enum onto `AppLocalizations` when rendering. Keep the set small.
enum _ConnectionError { generic }

class _EmailConnectionState {
  const _EmailConnectionState({
    this.isConnected = false,
    this.email,
    this.provider,
    this.lastSyncAt,
    this.isSyncing = false,
    this.isConnecting = false,
    this.errorKind,
    this.tokenScopeHint,
  });

  final bool isConnected;
  final String? email;
  final _EmailProvider? provider;
  final DateTime? lastSyncAt;
  final bool isSyncing;
  final bool isConnecting;
  final _ConnectionError? errorKind;

  /// Best-effort: the scope string from `user_oauth_tokens.scope`, lowercased.
  /// `null` when we have not yet fetched it (e.g. first launch before the
  /// background read returns) — treat null as "scope unknown" and show the
  /// banner when V2 is active, preferring user friction over silent
  /// loss-of-functionality.
  final String? tokenScopeHint;

  _EmailConnectionState copyWith({
    bool? isConnected,
    String? email,
    _EmailProvider? provider,
    DateTime? lastSyncAt,
    bool? isSyncing,
    bool? isConnecting,
    _ConnectionError? errorKind,
    String? tokenScopeHint,
  }) {
    return _EmailConnectionState(
      isConnected: isConnected ?? this.isConnected,
      email: email ?? this.email,
      provider: provider ?? this.provider,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      isSyncing: isSyncing ?? this.isSyncing,
      isConnecting: isConnecting ?? this.isConnecting,
      errorKind: errorKind,
      tokenScopeHint: tokenScopeHint ?? this.tokenScopeHint,
    );
  }
}

/// Google OAuth scopes requested when connecting Gmail. Beyond the basic
/// `email` scope (so we can read user.email) we also request
/// `gmail.send` — that is the load-bearing scope: it lets send-email
/// dispatch on behalf of the user via the Gmail API instead of falling back
/// to Resend / no-reply@advocat.ee.
///
/// IMPORTANT: this scope must be added to the OAuth consent screen in
/// Google Cloud Console (Authorized scopes). Without that, Google will
/// redirect with `error=access_denied` even though the request looks fine
/// on our side.
// D1 (Email Agent integration, 2026-05-07): added gmail.readonly +
// gmail.modify on top of the original gmail.send scope. readonly powers the
// proactive inbox-triage agent (email-inbox-sync edge fn polls every 5 min);
// modify is required to apply Gmail labels (e.g. `advocat-handled-auto`)
// once a thread has been triaged + auto-archived. Existing connected users
// must re-authorise — the email_screen UI surfaces a one-time banner per
// 09_INTEGRATION_INTO_ADVOCAT.md §D1, gated by `kGmailScopesIncludeProactive`
// in lib/config/feature_flags.dart.
//
// Backwards-compat alias. New code should reference `kGmailScopesActive`
// directly; this name is kept because tests and comments reference it.
const String kGmailOAuthScopes = kGmailScopesActive;

class _EmailConnectionNotifier extends StateNotifier<_EmailConnectionState> {
  _EmailConnectionNotifier(this._oauthStorage)
      : super(const _EmailConnectionState()) {
    _checkExistingConnection();
    _subscribeToAuthChanges();
  }

  final OAuthStorageService _oauthStorage;
  StreamSubscription<sb.AuthState>? _authSub;

  /// Check if the user is already signed in with Google via Supabase.
  void _checkExistingConnection() {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Check if user authenticated via Google OAuth
        final providers = user.appMetadata['providers'] as List<dynamic>?;
        final identities = user.identities;
        final hasGoogle = (providers != null && providers.contains('google')) ||
            (identities != null &&
                identities.any((i) => i.provider == 'google'));

        if (hasGoogle) {
          state = _EmailConnectionState(
            isConnected: true,
            email: user.email ?? '',
            provider: _EmailProvider.gmail,
            lastSyncAt: DateTime.now(),
          );
          // D1 (Email Agent integration): fetch the stored token's scope
          // string so the re-auth banner can decide whether the user is on
          // V1 (send-only) or V2 (send + readonly + modify). Best-effort —
          // any error leaves `tokenScopeHint` null and the banner shows
          // (preferring user friction over silent loss-of-functionality).
          unawaited(_loadTokenScopeHint(user.id));
        }
      }
    } catch (_) {
      // Supabase not initialized or other error — stay disconnected
    }
  }

  /// Reads `user_oauth_tokens.scope` for the current user (Gmail provider)
  /// and stores the lowercased scope string in state so the re-auth banner
  /// can gate visibility. RLS policies enforce that the row is the user's
  /// own; we never trust the server to filter for us.
  Future<void> _loadTokenScopeHint(String userId) async {
    try {
      final row = await Supabase.instance.client
          .from('user_oauth_tokens')
          .select('scope')
          .eq('user_id', userId)
          .eq('provider', 'gmail')
          .maybeSingle();
      String? scope;
      if (row != null) {
        final raw = (row as Map)['scope'];
        if (raw is String) scope = raw.toLowerCase();
      }
      if (scope != null) {
        state = state.copyWith(tokenScopeHint: scope);
      }
    } catch (_) {
      // Swallow — null scope is the safe-by-default value.
    }
  }

  /// Listen for auth state changes and persist the Gmail provider token to
  /// user_oauth_tokens as soon as Supabase exposes it on the session.
  ///
  /// Why this matters: `signInWithOAuth` returns the user a Google identity,
  /// but the actual access_token / refresh_token live ONLY in the in-memory
  /// session (session.providerToken / providerRefreshToken). They are never
  /// written to any Postgres table by Supabase. To use them server-side
  /// (Gmail API call from send-email), we must POST them once after the
  /// OAuth redirect lands.
  void _subscribeToAuthChanges() {
    try {
      _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(
        _handleAuthStateChange,
        onError: (_) {/* swallow — not critical for screen rendering */},
      );
    } catch (_) {
      // Supabase not initialised yet (e.g. unit tests). Silently skip.
    }
  }

  Future<void> _handleAuthStateChange(sb.AuthState data) async {
    if (data.event != sb.AuthChangeEvent.signedIn &&
        data.event != sb.AuthChangeEvent.tokenRefreshed) {
      return;
    }
    final session = data.session;
    if (session == null) return;
    final providerToken = session.providerToken;
    if (providerToken == null || providerToken.isEmpty) {
      // Either not a Google sign-in or the provider token has already been
      // dropped by Supabase (it is only kept for the immediate post-redirect
      // session). Nothing to persist.
      return;
    }
    try {
      final result = await _oauthStorage.persistGmailToken(
        accessToken: providerToken,
        refreshToken: session.providerRefreshToken,
        email: session.user.email,
        // Google's standard access-token lifetime is 3600s; Supabase doesn't
        // surface the actual expires_in for the provider token, so we send
        // null and let the Edge Function default kick in.
      );
      state = state.copyWith(
        isConnected: result.ok,
        isConnecting: false,
        email: result.email ?? session.user.email,
        provider: _EmailProvider.gmail,
        lastSyncAt: DateTime.now(),
        errorKind: result.ok ? null : _ConnectionError.generic,
      );
    } catch (e, st) {
      debugPrint('[email_screen] persistGmailToken failed: $e\n$st');
      state = state.copyWith(
        isConnecting: false,
        errorKind: _ConnectionError.generic,
      );
    }
  }

  /// Connect Gmail via Google OAuth through Supabase.
  Future<void> connectGmail() async {
    state = state.copyWith(isConnecting: true, errorKind: null);
    try {
      // Link Google identity to existing session, or sign in with Google.
      // Scope MUST include gmail.send so send-email can dispatch via the
      // Gmail API instead of falling back to Resend.
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        scopes: kGmailScopesActive,
        // access_type=offline + prompt=consent are required to receive a
        // refresh_token. Without prompt=consent, Google omits the refresh
        // token on subsequent sign-ins for the same user.
        queryParams: const {
          'access_type': 'offline',
          'prompt': 'consent',
        },
      );
      // On web, this redirects the browser. When the user comes back,
      // _handleAuthStateChange will pick up session.providerToken and POST
      // it to oauth-callback.
    } catch (e, st) {
      debugPrint('[email_screen] connectGmail failed: $e\n$st');
      state = const _EmailConnectionState(
        isConnecting: false,
        errorKind: _ConnectionError.generic,
      );
    }
  }

  Future<void> syncNow() async {
    state = state.copyWith(isSyncing: true);
    // Email reading requires Gmail API backend — not yet implemented.
    // Simulate a brief check then update timestamp.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    state = state.copyWith(
      lastSyncAt: DateTime.now(),
      isSyncing: false,
    );
  }

  Future<void> disconnect() async {
    state = const _EmailConnectionState();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

final _emailConnectionProvider =
    StateNotifierProvider<_EmailConnectionNotifier, _EmailConnectionState>(
  (ref) => _EmailConnectionNotifier(ref.read(oauthStorageServiceProvider)),
);

// ── Screen ───────────────────────────────────────────────────────────────

class EmailScreen extends ConsumerWidget {
  const EmailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(_emailConnectionProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.emailIntegrationTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: connection.isConnected
            ? _ConnectedView(
                key: const ValueKey('connected'), connection: connection)
            : const _DisconnectedView(key: ValueKey('disconnected')),
      ),
    );
  }
}

// ── Disconnected View ────────────────────────────────────────────────────

class _DisconnectedView extends ConsumerWidget {
  const _DisconnectedView({super.key});

  static const _providers = [
    _ProviderInfo(
      provider: _EmailProvider.gmail,
      name: 'Gmail',
      icon: Icons.email,
      color: Color(0xFFDB4437),
      label: 'Connect Gmail',
      isAvailable: true,
    ),
    _ProviderInfo(
      provider: _EmailProvider.outlook,
      name: 'Outlook',
      icon: Icons.email,
      color: Color(0xFF0078D4),
      label: 'Connect Outlook',
      isAvailable: false,
    ),
    _ProviderInfo(
      provider: _EmailProvider.icloud,
      name: 'iCloud',
      icon: Icons.cloud,
      color: Color(0xFFA2AAAD),
      label: 'Connect iCloud',
      isAvailable: false,
    ),
    _ProviderInfo(
      provider: _EmailProvider.yahoo,
      name: 'Yahoo',
      icon: Icons.email,
      color: Color(0xFF6001D2),
      label: 'Connect Yahoo',
      isAvailable: false,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final connection = ref.watch(_emailConnectionProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.lg),

            // Illustration with animated glow
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    blurRadius: 32,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                AppIcons.emailOutlined,
                size: 48,
                color: AppColors.accent.withValues(alpha: 0.6),
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                .slideY(
                    begin: -0.15,
                    end: 0,
                    duration: 500.ms,
                    curve: Curves.easeOut),

            const SizedBox(height: AppSpacing.md),

            Text(
              l10n.connectYourEmail,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
            )
                .animate()
                .fadeIn(delay: 100.ms, duration: 400.ms)
                .slideY(
                    begin: 0.1,
                    end: 0,
                    delay: 100.ms,
                    duration: 400.ms),

            const SizedBox(height: AppSpacing.xs),

            Text(
              l10n.connectYourEmailDesc,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 400.ms)
                .slideY(
                    begin: 0.1,
                    end: 0,
                    delay: 200.ms,
                    duration: 400.ms),

            const SizedBox(height: AppSpacing.xl),

            // Provider grid (2 columns)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.05,
              children: _providers.asMap().entries.map((entry) {
                final idx = entry.key;
                final info = entry.value;
                return _ProviderCard(
                  info: info,
                  isConnecting:
                      connection.isConnecting &&
                      info.provider == _EmailProvider.gmail,
                ).animate().fadeIn(
                      delay: Duration(milliseconds: 250 + idx * 100),
                      duration: 400.ms,
                    ).scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                      delay: Duration(milliseconds: 250 + idx * 100),
                      duration: 400.ms,
                      curve: Curves.easeOutCubic,
                    );
              }).toList(),
            ),

            // Error message
            if (connection.errorKind != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.15)),
                ),
                child: Text(
                  AppLocalizations.of(context)?.genericError ??
                      'Something went wrong. Please try again.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.error.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Security note
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border:
                    Border.all(color: AppColors.info.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(
                    AppIcons.privacyOutlined,
                    size: 20,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.emailPrivacyNote,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.info.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 650.ms, duration: 400.ms)
                .slideY(
                    begin: 0.1,
                    end: 0,
                    delay: 650.ms,
                    duration: 400.ms),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

// ── Provider info model ─────────────────────────────────────────────────

class _ProviderInfo {
  const _ProviderInfo({
    required this.provider,
    required this.name,
    required this.icon,
    required this.color,
    required this.label,
    required this.isAvailable,
  });

  final _EmailProvider provider;
  final String name;
  final IconData icon;
  final Color color;
  final String label;
  final bool isAvailable;
}

// ── Provider card widget ────────────────────────────────────────────────

class _ProviderCard extends ConsumerStatefulWidget {
  const _ProviderCard({
    required this.info,
    this.isConnecting = false,
  });
  final _ProviderInfo info;
  final bool isConnecting;

  @override
  ConsumerState<_ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends ConsumerState<_ProviderCard> {
  bool _isPressed = false;

  void _handleTap() {
    HapticFeedback.lightImpact();

    if (widget.info.isAvailable) {
      // Gmail — trigger real Google OAuth
      ref.read(_emailConnectionProvider.notifier).connectGmail();
    } else {
      // Other providers — show "Coming soon" bottom sheet
      _showComingSoonSheet(context, widget.info);
    }
  }

  void _showComingSoonSheet(BuildContext context, _ProviderInfo info) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Provider icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: info.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                info.icon,
                color: info.color,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              '${info.name} Integration',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              'Email sync for ${info.name} is coming soon.\nWe\'re working on bringing this integration to you!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // Status badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Coming Soon',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Close button
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Got it',
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUnavailable = !widget.info.isAvailable;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _handleTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: _isPressed
                  ? widget.info.color.withValues(alpha: 0.4)
                  : AppColors.border,
            ),
            boxShadow: _isPressed
                ? []
                : [
                    BoxShadow(
                      color: widget.info.color.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                    ...AppShadows.shadowSmall,
                  ],
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo container
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: widget.info.color.withValues(
                          alpha: isUnavailable ? 0.05 : 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: widget.isConnecting
                        ? Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: widget.info.color,
                              ),
                            ),
                          )
                        : Icon(
                            widget.info.icon,
                            color: widget.info.color.withValues(
                                alpha: isUnavailable ? 0.4 : 1.0),
                            size: 28,
                          ),
                  ),
                  const SizedBox(height: 10),
                  // Provider name
                  Text(
                    widget.info.name,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isUnavailable
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Connect button / Coming soon label
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: isUnavailable
                          ? AppColors.textTertiary.withValues(alpha: 0.08)
                          : widget.info.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      isUnavailable ? 'Coming soon' : 'Connect',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isUnavailable
                            ? AppColors.textTertiary
                            : widget.info.color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Connected View ───────────────────────────────────────────────────────

class _ConnectedView extends ConsumerWidget {
  const _ConnectedView({super.key, required this.connection});

  final _EmailConnectionState connection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // D1: when the active scope set is V2 but the stored token was minted
    // with V1, surface the one-time re-auth banner above the connected view.
    final showReauthBanner = kGmailScopesIncludeProactive &&
        !gmailScopeIncludesReadonly(connection.tokenScopeHint);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // ── One-time re-auth banner (V1 → V2 scope migration) ─────────
        if (showReauthBanner) ...[
          GmailReauthBanner(
            onReauthorize: () =>
                ref.read(_emailConnectionProvider.notifier).connectGmail(),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // ── Connection status with animated indicator ──────────────────
        _AnimatedConnectionCard(connection: connection, ref: ref)
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.08, end: 0, duration: 400.ms),

        const SizedBox(height: AppSpacing.lg),

        // ── Email reading coming soon notice ─────────────────────────
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.15)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.construction_rounded,
                size: 20,
                color: AppColors.warning,
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email Reading Coming Soon',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your Gmail account is connected. Email sync and automatic legal email detection will be available in an upcoming update.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms)
            .slideY(begin: 0.08, end: 0, delay: 200.ms, duration: 400.ms),

        const SizedBox(height: AppSpacing.lg),

        // ── Empty state for emails ──────────────────────────────────
        EmptyState(
          icon: AppIcons.emailOutlined,
          title: l10n.noLegalEmailsYet,
          description: l10n.legalEmailsWillAppear,
          compact: true,
        )
            .animate()
            .fadeIn(delay: 300.ms, duration: 400.ms),

        const SizedBox(height: AppSpacing.xl),

        // ── Disconnect button ─────────────────────────────────────────
        Center(
          child: AppButton(
            label: l10n.disconnectEmail,
            variant: AppButtonVariant.danger,
            size: AppButtonSize.small,
            leadingIcon: Icons.link_off_rounded,
            onPressed: () => _showDisconnectDialog(context, ref),
          ),
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 300.ms),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  void _showDisconnectDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        title: Text(l10n.disconnectEmail),
        content: Text(l10n.disconnectEmailConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(_emailConnectionProvider.notifier).disconnect();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.emailDisconnected)),
              );
            },
            child: Text(
              l10n.disconnect,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated Connection Card ─────────────────────────────────────────────

class _AnimatedConnectionCard extends StatelessWidget {
  const _AnimatedConnectionCard({
    required this.connection,
    required this.ref,
  });

  final _EmailConnectionState connection;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          ...AppShadows.shadowSmall,
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Animated pulsing green dot
              _PulsingDot(),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.connectedTo(connection.email ?? ''),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Gmail',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              // Green check icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Pulsing green dot ────────────────────────────────────────────────────

class _PulsingDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse ring
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(
                  begin: 0.8,
                  end: 1.4,
                  duration: 1500.ms,
                  curve: Curves.easeOut)
              .fadeOut(begin: 0.6, duration: 1500.ms),
          // Inner solid dot
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

