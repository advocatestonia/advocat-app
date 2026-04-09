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

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  String _selectedLanguage = 'et';

  // Focus nodes for shadow animations
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  // Fade-in animation
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  // Checkbox scale animation
  late final AnimationController _checkboxController;
  late final Animation<double> _checkboxScale;

  // Button press animation
  late final AnimationController _buttonPressController;
  late final Animation<double> _buttonScale;

  // Google button press animation
  late final AnimationController _googlePressController;
  late final Animation<double> _googleScale;

  @override
  void initState() {
    super.initState();

    // Fade-in on screen load
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // Checkbox bounce
    _checkboxController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _checkboxScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _checkboxController,
      curve: Curves.easeInOut,
    ));

    // Create Account button press
    _buttonPressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(
        parent: _buttonPressController,
        curve: Curves.easeInOut,
      ),
    );

    // Google button press
    _googlePressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _googleScale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(
        parent: _googlePressController,
        curve: Curves.easeInOut,
      ),
    );

    // Listen to focus changes for shadow effect
    _nameFocus.addListener(_onFocusChange);
    _emailFocus.addListener(_onFocusChange);
    _passwordFocus.addListener(_onFocusChange);
    _confirmPasswordFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() => setState(() {});

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _fadeController.dispose();
    _checkboxController.dispose();
    _buttonPressController.dispose();
    _googlePressController.dispose();
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

  /// Wraps a text field in an animated container that shows a subtle
  /// shadow when the field is focused.
  Widget _buildFocusableField({
    required FocusNode focusNode,
    required Widget child,
  }) {
    final isFocused = focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Reduced top spacing (was xxl = 48)
                  Text(
                    l.createAccount,
                    style:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // -- Full name --
                  _buildFocusableField(
                    focusNode: _nameFocus,
                    child: TextFormField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l.fullName,
                        prefixIcon: const Icon(Icons.person_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l.nameRequired
                          : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm + 4),

                  // -- Email --
                  _buildFocusableField(
                    focusNode: _emailFocus,
                    child: TextFormField(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l.email,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l.emailRequired;
                        }
                        final emailRegex =
                            RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!emailRegex.hasMatch(v.trim())) {
                          return l.emailInvalid;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm + 4),

                  // -- Password --
                  _buildFocusableField(
                    focusNode: _passwordFocus,
                    child: TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: l.password,
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
                        if (v == null || v.isEmpty) {
                          return l.passwordRequired;
                        }
                        if (v.length < 8) {
                          return l.passwordTooShort;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs + 2),

                  // -- Password strength indicator (animated) --
                  _AnimatedPasswordStrengthIndicator(
                    strength: passwordStrength,
                    visible: _passwordController.text.isNotEmpty,
                  ),
                  const SizedBox(height: AppSpacing.sm + 4),

                  // -- Confirm password --
                  _buildFocusableField(
                    focusNode: _confirmPasswordFocus,
                    child: TextFormField(
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordFocus,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: l.confirmPassword,
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
                        if (v == null || v.isEmpty) {
                          return l.passwordRequired;
                        }
                        if (v != _passwordController.text) {
                          return l.passwordsDoNotMatch;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // -- Language selector --
                  DropdownButtonFormField<String>(
                    initialValue: _selectedLanguage,
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)?.preferredLanguage ??
                              'Preferred Language',
                      prefixIcon: const Icon(Icons.language_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'et', child: Text('🇪🇪 Eesti')),
                      DropdownMenuItem(value: 'en', child: Text('🇬🇧 English')),
                      DropdownMenuItem(value: 'fi', child: Text('🇫🇮 Suomi')),
                      DropdownMenuItem(value: 'de', child: Text('🇩🇪 Deutsch')),
                      DropdownMenuItem(value: 'sv', child: Text('🇸🇪 Svenska')),
                      DropdownMenuItem(value: 'fr', child: Text('🇫🇷 Français')),
                      DropdownMenuItem(value: 'es', child: Text('🇪🇸 Español')),
                      DropdownMenuItem(value: 'it', child: Text('🇮🇹 Italiano')),
                      DropdownMenuItem(value: 'pl', child: Text('🇵🇱 Polski')),
                      DropdownMenuItem(value: 'lv', child: Text('🇱🇻 Latviešu')),
                      DropdownMenuItem(value: 'lt', child: Text('🇱🇹 Lietuvių')),
                      DropdownMenuItem(value: 'ro', child: Text('🇷🇴 Română')),
                      DropdownMenuItem(value: 'tr', child: Text('🇹🇷 Türkçe')),
                      DropdownMenuItem(value: 'ru', child: Text('🇷🇺 Русский')),
                      DropdownMenuItem(value: 'uk', child: Text('🇺🇦 Українська')),
                      DropdownMenuItem(value: 'ar', child: Text('🇸🇦 العربية')),
                      DropdownMenuItem(value: 'fa', child: Text('🇮🇷 فارسی')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedLanguage = value);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // -- Terms checkbox with scale animation --
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(
                              () => _agreedToTerms = !_agreedToTerms);
                          _checkboxController.forward(from: 0);
                        },
                        child: ScaleTransition(
                          scale: _checkboxScale,
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _agreedToTerms,
                              onChanged: (v) {
                                setState(
                                    () => _agreedToTerms = v ?? false);
                                _checkboxController.forward(from: 0);
                              },
                              activeColor: AppColors.accent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
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
                                TextSpan(
                                    text:
                                        AppLocalizations.of(context)
                                                ?.iAgreeToThe ??
                                            'I agree to the '),
                                TextSpan(
                                  text: AppLocalizations.of(context)
                                          ?.termsOfService ??
                                      'Terms of Service',
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      // TODO: Open Terms of Service
                                    },
                                ),
                                TextSpan(
                                    text:
                                        AppLocalizations.of(context)
                                                ?.andWord ??
                                            ' and '),
                                TextSpan(
                                  text: AppLocalizations.of(context)
                                          ?.privacyPolicy ??
                                      'Privacy Policy',
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
                  const SizedBox(height: AppSpacing.lg),

                  // -- Create Account button with glow + press animation --
                  ScaleTransition(
                    scale: _buttonScale,
                    child: GestureDetector(
                      onTapDown: (_) => _buttonPressController.forward(),
                      onTapUp: (_) => _buttonPressController.reverse(),
                      onTapCancel: () => _buttonPressController.reverse(),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.accent.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color:
                                  AppColors.accent.withValues(alpha: 0.15),
                              blurRadius: 32,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
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
                            minimumSize: const Size.fromHeight(52),
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
                              : Text(
                                  AppLocalizations.of(context)
                                          ?.createAccount ??
                                      'Create Account'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

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
                  const SizedBox(height: AppSpacing.md),

                  // -- Google sign-in with press animation --
                  ScaleTransition(
                    scale: _googleScale,
                    child: GestureDetector(
                      onTapDown: (_) =>
                          _googlePressController.forward(),
                      onTapUp: (_) =>
                          _googlePressController.reverse(),
                      onTapCancel: () =>
                          _googlePressController.reverse(),
                      child: SizedBox(
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
                          label: Text(
                              AppLocalizations.of(context)
                                      ?.continueWithGoogle ??
                                  'Continue with Google'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(
                                color: AppColors.border),
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
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // -- Already have account --
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l.alreadyHaveAccount,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.login),
                        child: Text(
                          l.signIn,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Password strength types & animated indicator widget
// ---------------------------------------------------------------------------

enum _PasswordStrength { none, weak, medium, strong }

class _AnimatedPasswordStrengthIndicator extends StatelessWidget {
  const _AnimatedPasswordStrengthIndicator({
    required this.strength,
    required this.visible,
  });

  final _PasswordStrength strength;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final (label, color, filledBars) = switch (strength) {
      _PasswordStrength.none => ('', AppColors.border, 0),
      _PasswordStrength.weak => ('Weak', const Color(0xFFC0392B), 1),
      _PasswordStrength.medium => ('Medium', const Color(0xFFD4870E), 2),
      _PasswordStrength.strong => ('Strong', AppColors.accent, 3),
    };

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: visible
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(3, (index) {
                    final isFilled = index < filledBars;
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                        height: 4,
                        margin:
                            EdgeInsets.only(right: index < 2 ? 6 : 0),
                        decoration: BoxDecoration(
                          color: isFilled ? color : AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                if (label.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    child: Text(label),
                  ),
                ],
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}
