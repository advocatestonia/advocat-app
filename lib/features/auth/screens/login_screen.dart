import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/pending_checkout.dart';
import '../../../shared/widgets/gdpr_consent_dialog.dart';
import '../../../shared/widgets/max_width_wrapper.dart';
import '../providers/auth_provider.dart';

/// Clean, minimal login screen for Advocat.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.initialEmail});

  /// Email to pre-fill in the email field on mount. Used by the
  /// register screen's "already registered → sign in" SnackBar
  /// (FIX-WAVE 6, 2026-05-20) to drop the user one tap away from a
  /// successful login.
  final String? initialEmail;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;

  // Fade-in animation
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Pre-fill email if the route passed one (e.g. from the register
    // screen's "email already registered" SnackBar action).
    final seed = widget.initialEmail?.trim();
    if (seed != null && seed.isNotEmpty) {
      _emailController.text = seed;
    }
    // Trigger fade-in after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _opacity = 1.0);
      // Move focus to the password field so the user just types their
      // password and submits — the email is already known.
      if (mounted && seed != null && seed.isNotEmpty) {
        _passwordFocusNode.requestFocus();
      }
    });
    // Listen to focus changes for field animations
    _emailFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authControllerProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  Future<void> _handleGoogleLogin() async {
    await ref.read(authControllerProvider.notifier).loginWithGoogle();
  }

  /// Apple Sign-In is intentionally disabled at the UI layer until the
  /// Supabase Apple provider is configured (pending Apple Developer Program
  /// enrollment). Instead of triggering a broken OAuth flow, we surface a
  /// localized "coming soon" snackbar. See `appleComingSoonMessage` in l10n.
  void _handleAppleComingSoon() {
    final l = AppLocalizations.of(context)!;
    _showSnackBar(l.appleComingSoonMessage);
  }

  Future<void> _handleForgotPassword() async {
    final l = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar(l.emailRequired);
      return;
    }

    final success =
        await ref.read(authControllerProvider.notifier).resetPassword(email);

    if (!mounted) return;
    _showSnackBar(
      success ? l.resetPasswordSent : l.resetPasswordFailed,
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      );
  }

  bool _navigating = false;

  /// Checks GDPR consent before navigating to home.
  Future<void> _ensureGdprConsentThenNavigate() async {
    if (_navigating) return;
    _navigating = true;

    try {
      final alreadyConsented = await hasGdprConsent();
      if (alreadyConsented) {
        if (mounted) context.go(AppRoutes.home);
        return;
      }

      if (!mounted) return;
      final accepted = await showGdprConsentDialog(context);
      if (!mounted) return;

      if (accepted) {
        context.go(AppRoutes.home);
      } else {
        unawaited(ref.read(authControllerProvider.notifier).logout());
      }
    } finally {
      _navigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final authState = ref.watch(authControllerProvider);

    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next.isAuthenticated) {
        _ensureGdprConsentThenNavigate();
      } else if (next.hasError && next.errorMessage != null) {
        _showSnackBar(next.errorMessage!);
        ref.read(authControllerProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF7F6F4), // lighter at top
              Color(0xFFF0EEEB), // background
              Color(0xFFE8E5E1), // darker at bottom
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        // Constrain form to phone width on desktop viewports —
        // 1200px-wide form fields look terrible. Explicit 480 wins
        // over MaxWidthWrapper's responsive default (which is for shell).
        child: MaxWidthWrapper(
          maxWidth: 480,
          child: SafeArea(
            child: AnimatedOpacity(
              opacity: _opacity,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final content = _buildContent(context, l, authState);
                  // Always use SingleChildScrollView so keyboard doesn't push content off
                  return SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(child: content),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, AppLocalizations l, AuthState authState) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isCompact = screenHeight < 750;
    final logoSize = isCompact ? 160.0 : 240.0;

    // UX audit FIX 3 (2026-05-14): if the user came from a landing pricing
    // CTA (e.g. /app.html?plan=counsel&billing=monthly) show a plan-context
    // banner so they know what they're signing in to activate. Eliminates
    // the "Estonian login from Finnish funnel" abandonment risk.
    final pending = ref.watch(pendingCheckoutProvider);
    final langCode = Localizations.localeOf(context).languageCode;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: isCompact ? 4.0 : 8.0),

          // -- Plan-context banner (only when user arrived from a pricing CTA) --
          if (pending != null) _PlanContextBanner(
            planId: pending.planId,
            billingPeriod: pending.billingPeriod,
            languageCode: langCode,
          ),

          // -- Logo (original Advocat shield PNG, whitespace-trimmed so it
          //    fills the frame; restored 2026-07-03 after a prior design pass
          //    had swapped it for a hand-coded SVG reconstruction) --
          Center(
            child: Image.asset(
              'assets/images/logo_shield_tight.png',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
          ),
          const SizedBox(height: 2),

          // -- Title with shadow effect --
          Text(
            l.welcomeBack,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                  shadows: [
                    Shadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            l.signInSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // -- Email field with focus animation --
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              boxShadow: _emailFocusNode.hasFocus
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: TextFormField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              autofillHints: const [AutofillHints.email, AutofillHints.username],
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l.email,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l.emailRequired;
                }
                final emailRegex =
                    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return l.emailInvalid;
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 6),

          // -- Password field with focus animation --
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              boxShadow: _passwordFocusNode.hasFocus
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: TextFormField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleLogin(),
              decoration: InputDecoration(
                labelText: l.password,
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  tooltip: _obscurePassword
                      ? (AppLocalizations.of(context)?.showPassword ?? 'Show password')
                      : (AppLocalizations.of(context)?.hidePassword ?? 'Hide password'),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l.passwordRequired;
                }
                return null;
              },
            ),
          ),

          // -- Forgot password --
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _handleForgotPassword,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l.forgotPassword,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // -- Log In button with teal glow and press animation --
          Semantics(
            label: 'Login button',
            button: true,
            child: _ScaleOnTapButton(
              onTap: authState.isLoading ? null : _handleLogin,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.accent.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    minimumSize: const Size.fromHeight(44),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(l.logIn),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // -- Divider with "or" --
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.border)),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  l.orDivider,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 13,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.border)),
            ],
          ),
          const SizedBox(height: 8),

          // -- Google sign-in --
          _ScaleOnTapButton(
            onTap: authState.isLoading ? null : _handleGoogleLogin,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: OutlinedButton(
                onPressed:
                    authState.isLoading ? null : _handleGoogleLogin,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  minimumSize: const Size.fromHeight(44),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google "G" logo — official 4-colour SVG
                    SvgPicture.asset(
                      'assets/icons/google_g.svg',
                      width: 20,
                      height: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l.continueWithGoogle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // -- Apple sign-in (disabled — "Coming soon") --
          //
          // The button is intentionally kept visible so the auth surface
          // looks complete, but Apple OAuth is not yet wired in Supabase
          // (awaiting Apple Developer Program enrollment). Tapping it
          // shows a localized snackbar via _handleAppleComingSoon().
          Semantics(
            label: 'Apple Sign-In — coming soon',
            button: true,
            enabled: false,
            child: _ScaleOnTapButton(
              onTap: authState.isLoading ? null : _handleAppleComingSoon,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Opacity(
                    opacity: 0.6,
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: OutlinedButton(
                        // Disable OAuth entirely; tap is handled by the
                        // outer _ScaleOnTapButton which shows the snackbar.
                        onPressed: null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black,
                          disabledForegroundColor: Colors.white,
                          disabledBackgroundColor: Colors.black,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.apple, size: 22, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'Continue with Apple',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // "Tulemas" / "Coming soon" pill badge — top-right corner.
                  Positioned(
                    top: -6,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        l.appleComingSoon,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),

          // -- Demo Mode button with press animation --
          Semantics(
            label: 'Try demo mode button',
            button: true,
            child: _ScaleOnTapButton(
              onTap: authState.isLoading
                  ? null
                  : () {
                      ref
                          .read(authControllerProvider.notifier)
                          .enterDemoMode();
                    },
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: authState.isLoading
                      ? null
                      : () {
                          ref
                              .read(authControllerProvider.notifier)
                              .enterDemoMode();
                        },
                  icon: const Icon(Icons.play_circle_outline, size: 20),
                  label: Text(l.tryDemoMode),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    minimumSize: const Size.fromHeight(44),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // -- Sign up link --
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l.noAccount,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              Semantics(
                label: 'Sign up link',
                button: true,
                child: GestureDetector(
                  onTap: () => context.go(AppRoutes.register),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      l.signUpLink,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// A widget that applies a subtle scale-down animation on press.
class _ScaleOnTapButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _ScaleOnTapButton({required this.child, this.onTap});

  @override
  State<_ScaleOnTapButton> createState() => _ScaleOnTapButtonState();
}

class _ScaleOnTapButtonState extends State<_ScaleOnTapButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null ? (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      } : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: IgnorePointer(child: widget.child),
      ),
    );
  }
}

/// Banner displayed at the top of the login screen when the user arrives
/// from a marketing-page pricing CTA (`/app.html?plan=…&billing=…`). Shows
/// "Sign in to activate <Plan> — <price> (incl. 22% VAT)" so the user
/// understands they're committing to a paid plan after they sign in.
///
/// Kept in sync with web/index.html#plan2/plan3 prices and
/// subscription_screen.dart#_PlanCard.
///
/// Stable PendingCheckout.planId values: 'counsel' (Pro) | 'representation'
/// (Premium). Billing: 'monthly' | 'yearly' | 'annual'.
class _PlanContextBanner extends StatefulWidget {
  const _PlanContextBanner({
    required this.planId,
    required this.billingPeriod,
    required this.languageCode,
  });

  final String planId;
  final String billingPeriod;
  final String languageCode;

  @override
  State<_PlanContextBanner> createState() => _PlanContextBannerState();
}

class _PlanContextBannerState extends State<_PlanContextBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  // ── Plan display name (no localization needed — brand names) ──
  String get _planDisplayName {
    switch (widget.planId) {
      case 'counsel':
        return 'Pro';
      case 'representation':
        return 'Premium';
      default:
        return widget.planId;
    }
  }

  // ── Price by plan + billing ──
  // Source of truth: subscription_screen.dart#monthlyPrice / annualPrice.
  String get _priceText {
    final isAnnual = widget.billingPeriod == 'annual' ||
        widget.billingPeriod == 'yearly';
    if (widget.planId == 'counsel') {
      return isAnnual ? '€159.99' : '€19.99';
    }
    if (widget.planId == 'representation') {
      return isAnnual ? '€249.99' : '€29.99';
    }
    return '';
  }

  /// Localised banner template:
  ///   "{prompt} {planName} — {price}{periodSuffix} ({vatNote})"
  /// Each part is localized; assembled here to avoid 17 separate l10n keys
  /// for what is essentially a single composed string.
  String get _bannerText {
    final code = widget.languageCode;
    final isAnnual = widget.billingPeriod == 'annual' ||
        widget.billingPeriod == 'yearly';

    // 1. Action prompt: "Sign in to activate"
    final prompt = _signInPrompts[code] ?? _signInPrompts['en']!;
    // 2. Billing suffix: "/mo" or "/yr"
    final periodSuffix = (isAnnual ? _yrSuffix : _moSuffix)[code] ??
        (isAnnual ? _yrSuffix : _moSuffix)['en']!;
    // 3. VAT note
    final vat = _vatNotes[code] ?? _vatNotes['en']!;

    return '$prompt $_planDisplayName — $_priceText$periodSuffix ($vat)';
  }

  // Per-locale strings. Kept tight to fit a one-line banner on phones.
  static const Map<String, String> _signInPrompts = {
    'en': 'Sign in to activate',
    'et': 'Logi sisse, et aktiveerida',
    'ru': 'Войдите, чтобы активировать',
    'uk': 'Увійдіть, щоб активувати',
    'fi': 'Kirjaudu aktivoidaksesi',
    'de': 'Anmelden zur Aktivierung von',
    'fr': 'Connectez-vous pour activer',
    'es': 'Inicia sesión para activar',
    'it': 'Accedi per attivare',
    'pl': 'Zaloguj się, aby aktywować',
    'sv': 'Logga in för att aktivera',
    'lv': 'Pierakstieties, lai aktivizētu',
    'lt': 'Prisijunkite norėdami aktyvuoti',
    'ro': 'Conectați-vă pentru a activa',
    'tr': 'Etkinleştirmek için giriş yapın',
    'ar': 'سجِّل الدخول لتفعيل',
    'fa': 'برای فعال‌سازی وارد شوید',
  };

  static const Map<String, String> _moSuffix = {
    'en': '/mo',
    'et': '/kuus',
    'ru': '/мес',
    'uk': '/міс',
    'fi': '/kk',
    'de': '/Mon.',
    'fr': '/mois',
    'es': '/mes',
    'it': '/mese',
    'pl': '/mies.',
    'sv': '/mån',
    'lv': '/mēn.',
    'lt': '/mėn.',
    'ro': '/lună',
    'tr': '/ay',
    'ar': '/شهر',
    'fa': '/ماه',
  };

  static const Map<String, String> _yrSuffix = {
    'en': '/yr',
    'et': '/aastas',
    'ru': '/год',
    'uk': '/рік',
    'fi': '/vuosi',
    'de': '/Jahr',
    'fr': '/an',
    'es': '/año',
    'it': '/anno',
    'pl': '/rok',
    'sv': '/år',
    'lv': '/gadā',
    'lt': '/metus',
    'ro': '/an',
    'tr': '/yıl',
    'ar': '/سنة',
    'fa': '/سال',
  };

  static const Map<String, String> _vatNotes = {
    'en': 'incl. 22% VAT',
    'et': 'sis. käibemaks 22%',
    'ru': 'вкл. НДС 22%',
    'uk': 'з ПДВ 22%',
    'fi': 'sis. ALV 22%',
    'de': 'inkl. 22 % MwSt.',
    'fr': 'TVA 22 % incl.',
    'es': 'IVA 22 % incl.',
    'it': 'IVA 22 % incl.',
    'pl': 'zawiera 22% VAT',
    'sv': 'inkl. 22 % moms',
    'lv': 'ar 22 % PVN',
    'lt': 'su 22 % PVM',
    'ro': 'TVA 22 % inclus',
    'tr': 'KDV %22 dahil',
    'ar': 'شامل ضريبة 22%',
    'fa': 'شامل ۲۲٪ مالیات',
  };

  @override
  Widget build(BuildContext context) {
    // Skip rendering for unknown plan ids — defensive.
    if (_priceText.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          // Soft pulse on the accent border so the banner reads as a live
          // active commitment, not a static label.
          final t = _pulse.value;
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.accent,
                  // Slight hue shift for depth — uses primary navy.
                  Color.lerp(AppColors.accent, AppColors.primary, 0.25)!,
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(
                    alpha: 0.20 + 0.15 * t,
                  ),
                  blurRadius: 10 + 4 * t,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Pin / lock icon — communicates "this purchase is held for you".
                const Icon(
                  Icons.push_pin_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _bannerText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
