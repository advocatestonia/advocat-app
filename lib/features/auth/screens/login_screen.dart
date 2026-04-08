import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/gdpr_consent_dialog.dart';
import '../providers/auth_provider.dart';

/// Clean, minimal login screen for Advocat.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

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
    // Trigger fade-in after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _opacity = 1.0);
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

  /// Checks GDPR consent before navigating to home.
  /// If consent was not previously given, shows the dialog.
  /// If the user declines, logs them out so they stay on the login screen.
  Future<void> _ensureGdprConsentThenNavigate() async {
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
      // User declined — log them out so they remain on the login screen.
      ref.read(authControllerProvider.notifier).logout();
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
      body: SafeArea(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Use SingleChildScrollView only when screen is very small
              final content = _buildContent(context, l, authState);
              if (constraints.maxHeight < 580) {
                return SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: content,
                );
              }
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: content,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, AppLocalizations l, AuthState authState) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.lg),

          // -- Logo with premium glow --
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.12),
                    AppColors.accent.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                  stops: const [0.3, 0.6, 1.0],
                ),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/logo_shield.png',
                  width: 140,
                  height: 140,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

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
          const SizedBox(height: AppSpacing.xs),
          Text(
            l.signInSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),

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
          const SizedBox(height: AppSpacing.sm),

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
          const SizedBox(height: AppSpacing.sm),

          // -- Log In button with teal glow and press animation --
          Semantics(
            label: 'Login button',
            button: true,
            child: _ScaleOnTapButton(
              onTap: authState.isLoading ? null : _handleLogin,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      blurRadius: 16,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      blurRadius: 6,
                      spreadRadius: 0,
                      offset: const Offset(0, 1),
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
                    minimumSize: const Size.fromHeight(50),
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
          const SizedBox(height: AppSpacing.md),

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
          const SizedBox(height: AppSpacing.md),

          // -- Google sign-in with press animation --
          _ScaleOnTapButton(
            onTap: authState.isLoading ? null : _handleGoogleLogin,
            child: SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed:
                    authState.isLoading ? null : _handleGoogleLogin,
                icon: Image.network(
                  'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                  width: 20,
                  height: 20,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.g_mobiledata_rounded,
                    size: 24,
                  ),
                ),
                label: Text(l.continueWithGoogle),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

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
                height: 48,
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
                    minimumSize: const Size.fromHeight(48),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

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
          const SizedBox(height: AppSpacing.md),
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
      onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}
