// =============================================================================
// contract_review_upgrade_dialog.dart
// =============================================================================
//
// Modal shown when contract-review returns 402 (quota_exceeded). Displays
// the user's current tier + usage, and two CTAs that deep-link to Stripe
// checkout for Counsel (€19.99/mo, 5 reviews) and Pro (€29.99/mo, 20).
//
// Free users see BOTH CTAs.
// Counsel users see only the Pro CTA (Counsel = current plan).
// Pro users should NEVER hit this — if they do, only contact-support CTA.
//
// Pricing is locked in code (NOT pulled from server) per project rule
// reference_current_pricing.md. Counsel = €19.99/mo, Pro = €29.99/mo.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/user.dart';
import '../services/contract_review_quota_service.dart';

/// Stable test keys so the widget test can find each CTA by Key.
class ContractReviewUpgradeDialogKeys {
  static const Key root = Key('contract_review_upgrade_dialog');
  static const Key counselCta = Key('contract_review_upgrade_counsel_cta');
  static const Key proCta = Key('contract_review_upgrade_pro_cta');
  static const Key dismiss = Key('contract_review_upgrade_dismiss');
}

/// Result returned from [showContractReviewUpgradeDialog]. Null when the
/// user dismissed without choosing.
enum ContractReviewUpgradeChoice { counsel, pro }

/// Imperative entry point. Returns the user's choice, or null if dismissed.
Future<ContractReviewUpgradeChoice?> showContractReviewUpgradeDialog(
  BuildContext context, {
  required ContractReviewQuota quota,
}) {
  return showDialog<ContractReviewUpgradeChoice>(
    context: context,
    builder: (ctx) => ContractReviewUpgradeDialog(quota: quota),
  );
}

/// The dialog body. Exposed as a public widget so it can be pumped in
/// isolation by the widget test (no need to wrap a navigator).
class ContractReviewUpgradeDialog extends StatelessWidget {
  const ContractReviewUpgradeDialog({
    super.key,
    required this.quota,
  });

  final ContractReviewQuota quota;

  bool get _showCounselCta =>
      quota.tier == SubscriptionTier.free;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      key: ContractReviewUpgradeDialogKeys.root,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded,
              color: AppColors.accent, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n?.contractReviewsUpgradeTitle ?? 'Contract reviews used up',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current state line — gives the user concrete numbers.
          Text(
            _statusLine(l10n, quota),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        // Vertical stack of CTAs — matches subscription-plan card aesthetic.
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showCounselCta) ...[
              _UpgradeCta(
                key: ContractReviewUpgradeDialogKeys.counselCta,
                primary: false,
                label:
                    l10n?.contractReviewsUpgradeCounselCta ??
                        'Upgrade to Counsel (€19.99/mo) — 5 reviews',
                onTap: () => Navigator.of(context)
                    .pop(ContractReviewUpgradeChoice.counsel),
              ),
              const SizedBox(height: 8),
            ],
            _UpgradeCta(
              key: ContractReviewUpgradeDialogKeys.proCta,
              primary: true,
              label:
                  l10n?.contractReviewsUpgradeProCta ??
                      'Upgrade to Pro (€29.99/mo) — 20 reviews',
              onTap: () => Navigator.of(context)
                  .pop(ContractReviewUpgradeChoice.pro),
            ),
            const SizedBox(height: 4),
            TextButton(
              key: ContractReviewUpgradeDialogKeys.dismiss,
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textTertiary,
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                ),
              ),
              child: Text(l10n?.notNow ?? 'Not now'),
            ),
          ],
        ),
      ],
    );
  }

  String _statusLine(AppLocalizations? l10n, ContractReviewQuota q) {
    // Tier-specific message: free shows "free trial used", paid tiers show
    // "X of Y reviews used".
    if (q.tier == SubscriptionTier.free) {
      return l10n?.contractReviewsUpgradeBodyFree ??
          'You used your free contract review. '
              'Upgrade for monthly contract reviews.';
    }
    final used = q.used;
    final cap = q.limit;
    return l10n?.contractReviewsUpgradeBodyPaid(used, cap) ??
        'You used $used of $cap reviews this month. '
            'Upgrade for a higher monthly cap.';
  }
}

/// Single CTA row used inside the dialog. `primary=true` paints the Pro
/// CTA in the accent colour; `primary=false` keeps Counsel neutral so
/// Pro reads as the recommended choice.
class _UpgradeCta extends StatelessWidget {
  const _UpgradeCta({
    super.key,
    required this.primary,
    required this.label,
    required this.onTap,
  });

  final bool primary;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return SizedBox(
        height: 44,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(label, textAlign: TextAlign.center),
        ),
      );
    }
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}
