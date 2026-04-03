import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../config/theme.dart';
import '../providers/auth_provider.dart';

/// Registration screen with full name, email, password with strength
/// indicator, confirm password, language selector, and terms checkbox.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  String _selectedLanguage = 'en';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  _PasswordStrength _evaluateStrength(String password) {
    if (password.isEmpty) return _PasswordStrength.none;
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    if (score <= 2) return _PasswordStrength.weak;
    if (score <= 3) return _PasswordStrength.medium;
    return _PasswordStrength.strong;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      _showSnackBar('Please agree to the Terms of Service');
      return;
    }

    await ref.read(authControllerProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          language: _selectedLanguage,
        );
  }

  Future<void> _handleGoogleRegister() async {
    await ref.read(authControllerProvider.notifier).loginWithGoogle();
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final passwordStrength = _evaluateStrength(_passwordController.text);

    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next.isAuthenticated) {
        context.go(AppRoutes.home);
      } else if (next.hasError && next.errorMessage != null) {
        _showSnackBar(next.errorMessage!);
        ref.read(authControllerProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: BackButton(
          onPressed: () => context.go(AppRoutes.onboarding),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create Account',
                  style:
                      Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // -- Full name --
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: AppSpacing.md),

                // -- Email --
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    final emailRegex =
                        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!emailRegex.hasMatch(v.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // -- Password --
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 8) return 'Password must be at least 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),

                // -- Password strength indicator --
                if (_passwordController.text.isNotEmpty)
                  _PasswordStrengthIndicator(strength: passwordStrength),
                const SizedBox(height: AppSpacing.md),

                // -- Confirm password --
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() =>
                          _obscureConfirmPassword =
                              !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // -- Language selector --
                DropdownButtonFormField<String>(
                  initialValue: _selectedLanguage,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)?.preferredLanguage ?? 'Preferred Language',
                    prefixIcon: const Icon(Icons.language_outlined),
                  ),
                  items: [
                    DropdownMenuItem(value: 'en', child: Text(AppLocalizations.of(context)?.english ?? 'English')),
                    DropdownMenuItem(value: 'ru', child: Text(AppLocalizations.of(context)?.russian ?? 'Russian')),
                    DropdownMenuItem(value: 'fi', child: Text(AppLocalizations.of(context)?.finnish ?? 'Finnish')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedLanguage = value);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // -- Terms checkbox --
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreedToTerms,
                        onChanged: (v) =>
                            setState(() => _agreedToTerms = v ?? false),
                        activeColor: AppColors.accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                            children: [
                              TextSpan(text: AppLocalizations.of(context)?.iAgreeToThe ?? 'I agree to the '),
                              TextSpan(
                                text: AppLocalizations.of(context)?.termsOfService ?? 'Terms of Service',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // TODO: Open Terms of Service
                                  },
                              ),
                              TextSpan(text: AppLocalizations.of(context)?.andWord ?? ' and '),
                              TextSpan(
                                text: AppLocalizations.of(context)?.privacyPolicy ?? 'Privacy Policy',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // TODO: Open Privacy Policy
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // -- Create Account button --
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        authState.isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.accent.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                      ),
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
                        : Text(AppLocalizations.of(context)?.createAccount ?? 'Create Account'),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // -- Divider --
                Row(
                  children: [
                    const Expanded(
                        child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      child: Text(
                        AppLocalizations.of(context)?.orWord ?? 'or',
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Expanded(
                        child: Divider(color: AppColors.border)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // -- Google sign-in --
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: authState.isLoading
                        ? null
                        : _handleGoogleRegister,
                    icon: Image.network(
                      'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                      width: 20,
                      height: 20,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.g_mobiledata_rounded,
                        size: 24,
                      ),
                    ),
                    label: Text(AppLocalizations.of(context)?.continueWithGoogle ?? 'Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // -- Already have account --
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.login),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Password strength types & indicator widget
// ---------------------------------------------------------------------------

enum _PasswordStrength { none, weak, medium, strong }

class _PasswordStrengthIndicator extends StatelessWidget {
  const _PasswordStrengthIndicator({required this.strength});

  final _PasswordStrength strength;

  @override
  Widget build(BuildContext context) {
    final (label, color, filledBars) = switch (strength) {
      _PasswordStrength.none => ('', AppColors.border, 0),
      _PasswordStrength.weak =>
        ('Weak', const Color(0xFFC0392B), 1),
      _PasswordStrength.medium =>
        ('Medium', const Color(0xFFD4870E), 2),
      _PasswordStrength.strong =>
        ('Strong', AppColors.accent, 3),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (index) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                decoration: BoxDecoration(
                  color: index < filledBars
                      ? color
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
