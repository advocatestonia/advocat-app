// severance_calculator_screen.dart — redundancy severance / notice estimate.
// -----------------------------------------------------------------------------
// FI: notice-period salary (TSL 6:3). EE: koondamine (TLS §100 + Töötukassa)
// + notice (TLS §97). Offers "draft a demand letter" → drafting studio.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/calc_rates.dart';
import '../logic/calculator_logic.dart';
import '../widgets/calc_scaffold.dart';
import '../widgets/calc_shared_widgets.dart';

class SeveranceCalculatorScreen extends StatefulWidget {
  const SeveranceCalculatorScreen({super.key, required this.jurisdiction});

  final String jurisdiction;

  @override
  State<SeveranceCalculatorScreen> createState() =>
      _SeveranceCalculatorScreenState();
}

class _SeveranceCalculatorScreenState extends State<SeveranceCalculatorScreen> {
  double _salary = 2000;
  double _tenure = 3;
  SeveranceResult? _result;

  void _calculate() {
    final r = widget.jurisdiction == 'FI'
        ? finnishNotice(monthlySalary: _salary, tenureYears: _tenure)
        : estonianKoondamine(monthlySalary: _salary, tenureYears: _tenure);
    setState(() => _result = r);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CalcScaffold(
      title: l10n.calcSeveranceTitle,
      jurisdiction: widget.jurisdiction,
      bodyBuilder: (context, rates) => _body(context, l10n, rates),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l10n, CalcRates rates) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CalcSliderRow(
          label: '${l10n.calcSeveranceSalary} (EUR)',
          value: _salary,
          min: 0,
          max: 8000,
          divisions: 80,
          display: '${_salary.toStringAsFixed(0)} €',
          onChanged: (v) => setState(() {
            _salary = v;
            _result = null;
          }),
        ),
        const SizedBox(height: AppSpacing.md),
        CalcSliderRow(
          label: l10n.calcSeveranceTenure,
          value: _tenure,
          min: 0,
          max: 30,
          divisions: 60,
          display: _tenure.toStringAsFixed(1),
          onChanged: (v) => setState(() {
            _tenure = v;
            _result = null;
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: _calculate,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            minimumSize: const Size.fromHeight(50),
          ),
          child: Text(l10n.calcCalculate),
        ),
        if (_result != null) ...[
          const SizedBox(height: AppSpacing.lg),
          CalcResultCard(
            label: l10n.calcSeveranceTotal,
            value: '${_result!.totalAmount.toStringAsFixed(2)} €',
            subLabel: l10n.calcSeveranceNotice,
            subValue: _result!.noticeLabel,
            color: AppColors.accent,
            icon: Icons.work_off_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          CalcFormulaBox(title: l10n.calcFormula, lines: _result!.breakdown),
          const SizedBox(height: AppSpacing.sm),
          CalcSourceRow(
            label: l10n.calcSource,
            source: rates.stateFeeSource.isNotEmpty
                ? (widget.jurisdiction == 'FI'
                    ? 'Työsopimuslaki 55/2001'
                    : 'Töölepingu seadus §100, §97')
                : '',
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () => context.push(
              '${AppRoutes.draftNew}?source=calc_severance',
            ),
            icon: const Icon(Icons.edit_document, size: 18),
            label: Text(l10n.calcSeveranceGenerateDemand),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ],
    );
  }
}
