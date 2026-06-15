// child_support_calculator_screen.dart — orientation child-support estimate.
// -----------------------------------------------------------------------------
// Highly variable in reality (set case-by-case on the child's need and parents'
// ability to pay). We surface a transparent orientation: max(floor, %-of-net)
// per child, wrapped in an emphatic "starting point only" warning.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/calc_rates.dart';
import '../logic/calculator_logic.dart';
import '../widgets/calc_scaffold.dart';
import '../widgets/calc_shared_widgets.dart';

class ChildSupportCalculatorScreen extends StatefulWidget {
  const ChildSupportCalculatorScreen({super.key, required this.jurisdiction});

  final String jurisdiction;

  @override
  State<ChildSupportCalculatorScreen> createState() =>
      _ChildSupportCalculatorScreenState();
}

class _ChildSupportCalculatorScreenState
    extends State<ChildSupportCalculatorScreen> {
  double _net = 1500;
  int _children = 1;
  ChildSupportResult? _result;

  void _calculate(CalcRates rates) {
    setState(() {
      _result = childSupportEstimate(
        payerNetMonthly: _net,
        children: _children,
        floorPerChild: rates.childSupportFloor,
        percentPerChild: rates.childSupportPercent,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CalcScaffold(
      title: l10n.calcChildSupportTitle,
      jurisdiction: widget.jurisdiction,
      bodyBuilder: (context, rates) => _body(context, l10n, rates),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l10n, CalcRates rates) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Extra emphatic variability warning for this calculator.
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.warningBg,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 16, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.calcChildSupportWarning,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.warning,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        CalcSliderRow(
          label: '${l10n.calcChildSupportNet} (EUR)',
          value: _net,
          min: 0,
          max: 6000,
          divisions: 60,
          display: '${_net.toStringAsFixed(0)} €',
          onChanged: (v) => setState(() {
            _net = v;
            _result = null;
          }),
        ),
        const SizedBox(height: AppSpacing.md),
        CalcSliderRow(
          label: l10n.calcChildSupportChildren,
          value: _children.toDouble(),
          min: 1,
          max: 6,
          divisions: 5,
          display: '$_children',
          onChanged: (v) => setState(() {
            _children = v.round();
            _result = null;
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: () => _calculate(rates),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            minimumSize: const Size.fromHeight(50),
          ),
          child: Text(l10n.calcCalculate),
        ),
        if (_result != null) ...[
          const SizedBox(height: AppSpacing.lg),
          CalcResultCard(
            label: l10n.calcChildSupportTotal,
            value: '${_result!.total.toStringAsFixed(2)} €',
            subLabel: l10n.calcChildSupportPerChild,
            subValue: '${_result!.perChild.toStringAsFixed(2)} €',
            color: AppColors.accent,
            icon: Icons.family_restroom_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          CalcFormulaBox(title: l10n.calcFormula, lines: _result!.breakdown),
          const SizedBox(height: AppSpacing.sm),
          CalcSourceRow(
            label: l10n.calcSource,
            source: rates.childSupportSource,
          ),
        ],
      ],
    );
  }
}
