// limitation_calculator_screen.dart — limitation / appeal-deadline checker.
// -----------------------------------------------------------------------------
// Pick a period type + an event/decision date; the calculator computes the
// statutory deadline, rolls it off weekends/holidays, and flags whether it has
// expired. Offers "add to deadlines" (navigates to the deadlines screen).
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

class LimitationCalculatorScreen extends StatefulWidget {
  const LimitationCalculatorScreen({super.key, required this.jurisdiction});

  final String jurisdiction;

  @override
  State<LimitationCalculatorScreen> createState() =>
      _LimitationCalculatorScreenState();
}

class _LimitationCalculatorScreenState
    extends State<LimitationCalculatorScreen> {
  int _selectedIndex = 0;
  DateTime? _startDate;
  LimitationResult? _result;

  void _calculate(CalcRates rates) {
    final period = rates.limitationPeriods[_selectedIndex];
    final start = _startDate;
    if (start == null) return;
    final r = limitationDeadline(
      start: start,
      days: period.days,
      years: period.years,
      jurisdiction: widget.jurisdiction,
      norm: period.norm,
    );
    setState(() => _result = r);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 30),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _result = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CalcScaffold(
      title: l10n.calcLimitationTitle,
      jurisdiction: widget.jurisdiction,
      bodyBuilder: (context, rates) => _body(context, l10n, rates),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l10n, CalcRates rates) {
    final periods = rates.limitationPeriods;
    // Guard index against a shorter network list.
    final idx = _selectedIndex.clamp(0, periods.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.calcLimitationType,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: idx,
              items: [
                for (var i = 0; i < periods.length; i++)
                  DropdownMenuItem(
                    value: i,
                    child: Text(
                      periods[i].label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
              ],
              onChanged: (v) => setState(() {
                _selectedIndex = v ?? 0;
                _result = null;
              }),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          periods[idx].norm,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Date picker row.
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 18, color: AppColors.accent),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _startDate == null
                        ? l10n.calcLimitationStart
                        : _fmt(_startDate!),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _startDate == null
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  l10n.calcLimitationPickDate,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: _startDate == null ? null : () => _calculate(rates),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            minimumSize: const Size.fromHeight(50),
          ),
          child: Text(l10n.calcCalculate),
        ),

        if (_result != null) ...[
          const SizedBox(height: AppSpacing.lg),
          CalcResultCard(
            label: l10n.calcLimitationDeadline,
            value: _fmt(_result!.deadline),
            subLabel: _result!.expired
                ? l10n.calcLimitationExpired
                : l10n.calcLimitationDaysLeft(_result!.daysRemaining),
            subValue: _result!.expired ? '⚠' : '✓',
            color: _result!.expired ? AppColors.warning : AppColors.success,
            icon: Icons.event_busy_outlined,
          ),
          if (_result!.shifted) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.calcLimitationShifted,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          CalcSourceRow(
            label: l10n.calcSource,
            source: _result!.norm,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!_result!.expired)
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.deadlines),
              icon: const Icon(Icons.add_alert_outlined, size: 18),
              label: Text(l10n.calcLimitationAddDeadline),
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

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}
