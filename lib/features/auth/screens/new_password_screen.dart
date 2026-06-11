import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../main.dart' show rootScaffoldMessengerKey;
import '../../../shared/widgets/app_button.dart';
import '../providers/auth_provider.dart';

/// Set-new-password screen.
///
/// Reached two ways:
///  1. Password-recovery deep link — Supabase signs the user in via the
///     reset-email link and emits `AuthChangeEvent.passwordRecovery`;
///     `AdvocatApp` listens to [passwordRecoveryPendingProvider] and routes
///     here so the reset flow is no longer a dead end (beta audit
///     2026-06-11: the email logged users in but offered no way to actually
///     set a new password).
///  2. Settings → "Change password" — same screen, pushed manually.
class NewPasswordScreen extends ConsumerStatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _saving = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final l = AppLocalizations.of(context)!;

    setState(() => _saving = true);
    final ok = await ref
        .read(authControllerProvider.notifier)
        .updatePassword(_passwordController.text);
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      // Root messenger so the toast survives the route change below.
      // Falls back to the local messenger in tests where the root key
      // isn't mounted.
      final messenger =
          rootScaffoldMessengerKey.currentState ?? ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l.newPasswordSuccess),
          behavior: SnackBarBehavior.floating,
        ),
      );
      // From Settings the screen was pushed — pop back. From the recovery
      // deep link there is no stack — go home.
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.home);
      }
    } else {
      final message =
          ref.read(authControllerProvider).errorMessage ?? l.newPasswordError;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.newPasswordTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.newPasswordHint,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // -- New password --
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l.password,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      tooltip: _obscurePassword ? l.showPassword : l.hidePassword,
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return l.passwordRequired;
                    if (v.length < 8) return l.passwordTooShort;
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // -- Confirm password --
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleSave(),
                  decoration: InputDecoration(
                    labelText: l.confirmPassword,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      tooltip: _obscureConfirm ? l.showPassword : l.hidePassword,
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return l.passwordRequired;
                    if (v != _passwordController.text) {
                      return l.passwordsDoNotMatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                AppButton(
                  label: l.newPasswordSave,
                  isFullWidth: true,
                  isLoading: _saving,
                  onPressed: _saving ? null : _handleSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
