// state_fee_calculator_screen.dart — court / state fee reference table.
// -----------------------------------------------------------------------------
// State fees (riigilõiv / oikeudenkäyntimaksu) are looked up by court + stage
// rather than computed, so this screen presents the versioned bracket table for
// the jurisdiction with its source citation.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/calc_rates.dart';
import '../widgets/calc_scaffold.dart';
import '../widgets/calc_shared_widgets.dart';

class StateFeeCalculatorScreen extends StatelessWidget {
  const StateFeeCalculatorScreen({super.key, required this.jurisdiction});

  final String jurisdiction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CalcScaffold(
      title: l10n.calcStateFeeTitle,
      jurisdiction: jurisdiction,
      bodyBuilder: (context, rates) => _body(l10n, rates),
    );
  }

  Widget _body(AppLocalizations l10n, CalcRates rates) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rates.stateFeeBrackets.length; i++)
                _FeeRow(
                  bracket: rates.stateFeeBrackets[i],
                  isLast: i == rates.stateFeeBrackets.length - 1,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        CalcSourceRow(
          label: l10n.calcSource,
          source: rates.stateFeeSource,
        ),
      ],
    );
  }
}

class _FeeRow extends StatelessWidget {
  const _FeeRow({required this.bracket, required this.isLast});

  final FeeBracket bracket;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.border, width: 0.5),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              bracket.label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${bracket.fee} €',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
