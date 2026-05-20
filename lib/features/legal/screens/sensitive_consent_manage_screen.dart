// =====================================================================
// GDPR Art. 9(2)(a) — manage / withdraw special-category data consent.
//
// Linked from Settings → "Sensitive data consent — manage / withdraw".
// Shows the user their current active consent (version + grant date +
// category list) and a destructive "Withdraw consent" button that
// stamps `withdrawn_at = now()` on every active row for the user.
//
// Per owner default (2026-05-20) withdrawal blocks FUTURE uploads only;
// previously uploaded documents are NOT cascade-deleted. The user can
// still purge their full data set via Settings → "Delete account".
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/sensitive_consent_gate.dart';

class SensitiveConsentManageScreen extends ConsumerStatefulWidget {
  const SensitiveConsentManageScreen({super.key});

  @override
  ConsumerState<SensitiveConsentManageScreen> createState() =>
      _SensitiveConsentManageScreenState();
}

class _SensitiveConsentManageScreenState
    extends ConsumerState<SensitiveConsentManageScreen> {
  Future<Map<String, dynamic>?>? _future;

  @override
  void initState() {
    super.initState();
    _future = fetchActiveSensitiveConsent();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = fetchActiveSensitiveConsent();
    });
  }

  Future<void> _confirmWithdraw() async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        title: Text(l.sensitiveConsentWithdrawAction),
        content: const Text(
          'Withdrawing consent will block future uploads of special-category '
          'documents. Existing uploaded documents are NOT deleted by this '
          'action — to delete them too, use "Delete account" in Settings.',
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l.sensitiveConsentWithdrawAction,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final updated = await withdrawSensitiveConsent();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated > 0
                ? 'Consent withdrawn ($updated record updated).'
                : 'No active consent on record.',
          ),
          backgroundColor:
              updated > 0 ? AppColors.success : AppColors.textSecondary,
        ),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not withdraw consent: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Sensitive data consent',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Could not load consent record: ${snap.error}',
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }
          final row = snap.data;
          if (row == null) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.info_outline,
                      size: 32, color: AppColors.textSecondary),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'No active sensitive-data consent on record.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'You will be asked for explicit consent the first time you '
                    'upload a document that may contain special-category '
                    'personal data (health, criminal records, etc.).',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          final grantedAt =
              DateTime.tryParse(row['granted_at']?.toString() ?? '');
          final version = row['consent_version']?.toString() ?? '—';
          final basis = row['legal_basis']?.toString() ?? '—';
          final categories =
              (row['categories'] as List?)?.cast<String>() ?? const [];

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _Row(label: 'Status', value: 'Active'),
              _Row(
                label: 'Granted',
                value: grantedAt == null
                    ? '—'
                    : grantedAt.toLocal().toString().split('.').first,
              ),
              _Row(label: 'Consent version', value: version),
              _Row(label: 'Legal basis', value: basis),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Categories covered',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in categories)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        c,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _confirmWithdraw,
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(l.sensitiveConsentWithdrawAction),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
