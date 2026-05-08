import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/gdpr_consent_dialog.dart';
import '../../../shared/widgets/max_width_wrapper.dart';
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

  Future<void> _handleAppleLogin() async {
    try {
      await ref.read(authControllerProvider.notifier).loginWithApple();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Apple Sign-In failed. Please try email.');
    }
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

    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: isCompact ? 4.0 : 8.0),

          // -- Logo --
          Center(
            child: Image.asset(
              'assets/images/logo_shield.png',
              width: logoSize,
              height: logoSize,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
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
                    // Google "G" logo — inline, no network dependency
                    const _GoogleGLogo(size: 20),
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

          // -- Apple sign-in --
          _ScaleOnTapButton(
            onTap: authState.isLoading ? null : _handleAppleLogin,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(AppRadius.md),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: OutlinedButton(
                onPressed: authState.isLoading ? null : _handleAppleLogin,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
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

/// Google "G" logo as 4 colored circles arranged in the classic pattern.
class _GoogleGLogo extends StatelessWidget {
  const _GoogleGLogo({this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) {
    // Use the official Google colors in a simple 2x2 grid pattern
    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dot(const Color(0xFFEA4335), size * 0.42), // red top-left
              SizedBox(width: size * 0.08),
              _dot(const Color(0xFF4285F4), size * 0.42), // blue top-right
            ],
          ),
          SizedBox(height: size * 0.08),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dot(const Color(0xFFFBBC05), size * 0.42), // yellow bottom-left
              SizedBox(width: size * 0.08),
              _dot(const Color(0xFF34A853), size * 0.42), // green bottom-right
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color, double dotSize) {
    return Container(
      width: dotSize,
      height: dotSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
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
