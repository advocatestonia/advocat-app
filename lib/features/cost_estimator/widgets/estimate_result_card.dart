import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/cost_estimator_provider.dart';

// ---------------------------------------------------------------------------
// Estimate Result Card — renders a CaseEstimate as cost/duration bands, a
// traffic-light strength signal, and factor lists.
//
// Trust-safety: every figure is shown as a RANGE ("€X – €Y"), never a single
// number; the strength is a 3-colour signal with neutral wording, never a
// percentage. A "rough estimate, not a prediction" disclaimer is always
// visible above the figures.
// ---------------------------------------------------------------------------

class EstimateResultCard extends StatelessWidget {
  const EstimateResultCard({
    super.key,
    required this.estimate,
    required this.b2bMode,
    this.onNextStep,
  });

  final CaseEstimate estimate;
  final bool b2bMode;
  final VoidCallback? onNextStep;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── "Rough estimate" disclaimer — always first ─────────────────
          _RoughEstimateDisclaimer(
            text: l10n?.costEstimateDisclaimer ??
                'Rough estimate only — not a prediction, guarantee, or legal '
                    'advice. Actual costs and outcomes vary case by case.',
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Traffic-light strength ─────────────────────────────────────
          _StrengthBadge(strength: estimate.strength, l10n: l10n),
          const SizedBox(height: AppSpacing.md),

          // ── Cost bands ─────────────────────────────────────────────────
          Text(
            l10n?.costEstimateCostsHeading ?? 'Estimated costs',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (!estimate.courtFee.isZero)
            _CostRow(
              label: l10n?.costEstimateCourtFee ?? 'Court / state fee',
              band: estimate.courtFee,
              isCurrency: true,
            ),
          if (!estimate.lawyerFee.isZero)
            _CostRow(
              label: l10n?.costEstimateLawyerFee ?? 'Lawyer fee',
              band: estimate.lawyerFee,
              isCurrency: true,
            ),
          const Divider(height: AppSpacing.lg),
          _CostRow(
            label: l10n?.costEstimateTotal ?? 'Total (approx.)',
            band: estimate.total,
            isCurrency: true,
            emphasise: true,
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Duration ───────────────────────────────────────────────────
          if (!estimate.durationMonths.isZero)
            _CostRow(
              label: l10n?.costEstimateDuration ?? 'Time to first resolution',
              band: estimate.durationMonths,
              isCurrency: false,
              monthsLabel:
                  l10n?.costEstimateMonthsSuffix ?? 'months',
            ),

          // ── Factors (hidden in compact B2B card) ───────────────────────
          if (!b2bMode) ...[
            if (estimate.factorsFor.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              _FactorList(
                title: l10n?.costEstimateFactorsFor ?? 'In your favour',
                items: estimate.factorsFor,
                positive: true,
              ),
            ],
            if (estimate.factorsAgainst.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _FactorList(
                title:
                    l10n?.costEstimateFactorsAgainst ?? 'Working against you',
                items: estimate.factorsAgainst,
                positive: false,
              ),
            ],
          ],

          // ── Recommendation ─────────────────────────────────────────────
          if (estimate.recommendation.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline,
                      size: 18, color: AppColors.accent),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      estimate.recommendation,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Next-step CTA ──────────────────────────────────────────────
          if (estimate.nextStep.isNotEmpty && onNextStep != null) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onNextStep,
                icon: const Icon(Icons.arrow_forward),
                label: Text(estimate.nextStep),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Rough-estimate disclaimer chip ─────────────────────────────────────────

class _RoughEstimateDisclaimer extends StatelessWidget {
  const _RoughEstimateDisclaimer({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Strength traffic-light ──────────────────────────────────────────────────

class _StrengthBadge extends StatelessWidget {
  const _StrengthBadge({required this.strength, this.l10n});
  final CaseStrength strength;
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    final (Color fg, Color bg, IconData icon, String label) = switch (strength) {
      CaseStrength.worthPursuing => (
          AppColors.success,
          AppColors.successBg,
          Icons.check_circle_outline,
          l10n?.costEstimateStrengthWorth ?? 'Likely worth pursuing',
        ),
      CaseStrength.contested => (
          AppColors.warning,
          AppColors.warningBg,
          Icons.balance_outlined,
          l10n?.costEstimateStrengthContested ?? 'Contested — could go either way',
        ),
      CaseStrength.weak => (
          AppColors.error,
          AppColors.errorBg,
          Icons.report_problem_outlined,
          l10n?.costEstimateStrengthWeak ?? 'Weak — proceed with caution',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cost / duration band row ────────────────────────────────────────────────

class _CostRow extends StatelessWidget {
  const _CostRow({
    required this.label,
    required this.band,
    required this.isCurrency,
    this.emphasise = false,
    this.monthsLabel,
  });

  final String label;
  final EstimateBand band;
  final bool isCurrency;
  final bool emphasise;
  final String? monthsLabel;

  String _fmt(int v) {
    if (isCurrency) {
      final s = v.toString();
      final buf = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
        buf.write(s[i]);
      }
      return '€$buf';
    }
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = band.low == band.high
        ? _fmt(band.low)
        : '${_fmt(band.low)} – ${_fmt(band.high)}';
    final suffix =
        (!isCurrency && monthsLabel != null) ? ' $monthsLabel' : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: emphasise
                  ? theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w700)
                  : theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Text(
            '$value$suffix',
            style: emphasise
                ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  )
                : theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Factor list ─────────────────────────────────────────────────────────────

class _FactorList extends StatelessWidget {
  const _FactorList({
    required this.title,
    required this.items,
    required this.positive,
  });

  final String title;
  final List<String> items;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colour = positive ? AppColors.success : AppColors.error;
    final icon = positive ? Icons.add_circle_outline : Icons.remove_circle_outline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colour,
          ),
        ),
        const SizedBox(height: 4),
        ...items.map(
          (f) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 16, color: colour),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(f, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
