import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/router.dart';
import '../../../config/theme.dart';
import '../data/dpa_text.dart';

/// GDPR Art. 28 — checkout DPA clickwrap gate.
///
/// Returns `true` when the user has either (a) already accepted the current
/// DPA version on a prior checkout, or (b) just accepted it inside the
/// modal and the acceptance row was persisted to `public.dpa_acceptances`.
/// Returns `false` if the user cancels or if persisting the row fails (in
/// which case the caller MUST NOT proceed to Stripe checkout).
///
/// Usage:
/// ```dart
/// final ok = await ensureDpaAccepted(context);
/// if (!ok) return;
/// // ... proceed with stripeService.startCheckout(...)
/// ```
Future<bool> ensureDpaAccepted(BuildContext context) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) {
    // No authenticated user — defer to the caller's own auth handling.
    // We choose not to silently insert; checkout would fail downstream anyway.
    return false;
  }

  // 1. Fast path: row already exists for (user, current_dpa_version).
  try {
    final existing = await supabase
        .from('dpa_acceptances')
        .select('id')
        .eq('user_id', user.id)
        .eq('dpa_version', kCurrentDpaVersion)
        .limit(1)
        .maybeSingle();
    if (existing != null) return true;
  } catch (_) {
    // RLS or transient error — fall through and present the dialog so the
    // user can still accept and we attempt the insert.
  }

  if (!context.mounted) return false;

  // 2. Show the mandatory clickwrap modal.
  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _DpaGateDialog(),
  );
  if (accepted != true) return false;

  // 3. Persist the acceptance BEFORE returning. If this fails we treat the
  //    flow as cancelled — we will not let a paid checkout proceed without
  //    a recorded acceptance, full stop.
  try {
    await supabase.from('dpa_acceptances').insert({
      'user_id': user.id,
      'dpa_version': kCurrentDpaVersion,
      'accepted_via': 'checkout',
      // ip_address and user_agent are intentionally left null on the client
      // — they're populated server-side by the create-checkout gate-check
      // (which has access to request headers and the X-Forwarded-For).
    });
    return true;
  } on PostgrestException catch (e) {
    // 23505 = unique_violation — a concurrent insert (or a prior accept on
    // the same version) is a valid pass. Anything else means we failed to
    // record and the caller must not proceed.
    if (e.code == '23505') return true;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not record DPA acceptance: ${e.message}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
    return false;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not record DPA acceptance: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
    return false;
  }
}

class _DpaGateDialog extends StatefulWidget {
  const _DpaGateDialog();

  @override
  State<_DpaGateDialog> createState() => _DpaGateDialogState();
}

class _DpaGateDialogState extends State<_DpaGateDialog> {
  bool _checked = false;
  bool _viewed = false;

  bool get _canAccept => _checked && _viewed;

  Future<void> _openDpa() async {
    setState(() => _viewed = true);
    // Push the full DPA review screen. We don't gate on the pop result; the
    // act of opening the screen is what satisfies the "click-through" leg.
    await context.push(AppRoutes.dpa);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      title: const Text(
        'Before you upgrade',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'EU law (GDPR Art. 28) requires us to sign a Data Processing '
              'Agreement with every paying customer. Please review and '
              'accept before proceeding to payment.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Link to full DPA — must be clicked at least once before
            // "Accept and continue" enables.
            InkWell(
              onTap: _openDpa,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _viewed
                          ? Icons.check_circle
                          : Icons.description_outlined,
                      size: 18,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Text(
                        'View Data Processing Agreement',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: AppColors.accent,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Acceptance checkbox.
            InkWell(
              onTap: () => setState(() => _checked = !_checked),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _checked,
                      onChanged: (v) =>
                          setState(() => _checked = v ?? false),
                      activeColor: AppColors.accent,
                      visualDensity: VisualDensity.compact,
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 12, left: 4),
                        child: Text(
                          'I have read and accept the Data Processing '
                          'Agreement (v1.0).',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            height: 1.4,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (!_viewed)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Open the DPA at least once to enable the Accept button.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _canAccept
              ? () => Navigator.of(context).pop(true)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.3),
            disabledForegroundColor: Colors.white70,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          child: const Text(
            'Accept and continue',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
