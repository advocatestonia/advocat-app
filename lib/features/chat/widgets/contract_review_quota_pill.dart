// =============================================================================
// contract_review_quota_pill.dart
// =============================================================================
//
// Compact "X contract reviews left this month" pill rendered near the
// chat-screen upload button. Three visual states:
//
//   - normal      : neutral background, plain "X reviews left this month"
//   - nearLimit   : yellow background, <= 1 remaining (warning)
//   - exhausted   : red background, 0 remaining + inline upgrade CTA
//
// Driven by [ContractReviewQuota] from contract_review_quota_service.dart.
// The pill is intentionally read-only: it never enforces anything. Server
// is the authoritative gate (contract-review edge fn → 402). The pill
// only sets user expectations.
// =============================================================================

import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/user.dart';
import '../services/contract_review_quota_service.dart';

/// Visual state derived from a [ContractReviewQuota] snapshot.
enum ContractReviewPillState { normal, nearLimit, exhausted }

ContractReviewPillState pillStateFor(ContractReviewQuota q) {
  if (q.isExhausted) return ContractReviewPillState.exhausted;
  if (q.isNearLimit) return ContractReviewPillState.nearLimit;
  return ContractReviewPillState.normal;
}

class ContractReviewQuotaPill extends StatelessWidget {
  const ContractReviewQuotaPill({
    super.key,
    required this.quota,
    required this.onUpgrade,
  });

  /// Current quota snapshot — pass the value from the Riverpod
  /// [contractReviewQuotaProvider] (or build by hand for tests).
  final ContractReviewQuota quota;

  /// Callback fired when the user taps the inline "Upgrade to Pro" CTA
  /// shown in the exhausted state. Typically navigates to the upgrade
  /// dialog or the subscription deeplink.
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = pillStateFor(quota);
    final remaining = quota.remaining();

    // ── Background + foreground ────────────────────────────────────
    final Color background;
    final Color foreground;
    switch (state) {
      case ContractReviewPillState.normal:
        background = AppColors.surfaceVariant;
        foreground = AppColors.textSecondary;
        break;
      case ContractReviewPillState.nearLimit:
        // Warning yellow — flutter Material doesn't have a true "warning"
        // colour; use a fixed accessible amber so QA can pin it.
        background = const Color(0xFFFFF8E1);
        foreground = const Color(0xFFB26A00);
        break;
      case ContractReviewPillState.exhausted:
        background = const Color(0xFFFFEBEE);
        foreground = const Color(0xFFC62828);
        break;
    }

    // ── Text body ──────────────────────────────────────────────────
    final String label = _label(l10n, quota, remaining);

    return Container(
      key: Key('contract_review_quota_pill_${state.name}'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            state == ContractReviewPillState.exhausted
                ? Icons.lock_outline_rounded
                : Icons.description_outlined,
            size: 14,
            color: foreground,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
          if (state == ContractReviewPillState.exhausted) ...[
            const SizedBox(width: 8),
            // Inline upgrade CTA. Always promotes Pro (20/mo) on the
            // exhausted state — Counsel (5/mo) is offered by the modal.
            TextButton(
              key: const Key('contract_review_quota_pill_upgrade_cta'),
              onPressed: onUpgrade,
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: foreground,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(_upgradeCtaLabel(l10n)),
            ),
          ],
        ],
      ),
    );
  }

  String _label(
    AppLocalizations? l10n,
    ContractReviewQuota q,
    int remaining,
  ) {
    if (q.tier == SubscriptionTier.free) {
      // Free is a single lifetime trial: copy must reflect that, not
      // "this month".
      if (remaining > 0) {
        return l10n?.contractReviewsFreeTrialLeft ??
            'Free trial: 1 contract review';
      }
      return l10n?.contractReviewsFreeTrialUsed ??
          'Free trial used — upgrade for more';
    }
    if (remaining == 0) {
      return l10n?.contractReviewsExhausted ??
          'No contract reviews left this month';
    }
    return l10n?.contractReviewsLeft(remaining) ??
        '$remaining contract reviews left this month';
  }

  String _upgradeCtaLabel(AppLocalizations? l10n) {
    return l10n?.contractReviewsUpgradeToProShort ?? 'Upgrade to Pro — 20/mo';
  }
}
