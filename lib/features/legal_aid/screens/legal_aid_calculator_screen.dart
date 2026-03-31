import 'package:flutter/material.dart';

import '../../../config/theme.dart';

/// Calculator screen to determine eligibility for legal aid in Finland.
class LegalAidCalculatorScreen extends StatefulWidget {
  const LegalAidCalculatorScreen({super.key});

  @override
  State<LegalAidCalculatorScreen> createState() =>
      _LegalAidCalculatorScreenState();
}

class _LegalAidCalculatorScreenState extends State<LegalAidCalculatorScreen> {
  double _monthlyIncome = 0;
  double _assets = 0;
  int _dependents = 0;
  bool _calculated = false;
  _AidResult? _result;

  void _calculate() {
    final disposable = _monthlyIncome - (_dependents * 300);
    final bool eligible;
    final String description;
    final double coPayPercent;

    if (disposable <= 600 && _assets < 10000) {
      eligible = true;
      coPayPercent = 0;
      description =
          'You likely qualify for full free legal aid (no co-payment).';
    } else if (disposable <= 1300 && _assets < 30000) {
      eligible = true;
      coPayPercent = ((disposable - 600) / 700 * 75).clamp(0, 75);
      description =
          'You may qualify for legal aid with a co-payment of '
          '${coPayPercent.toStringAsFixed(0)}%.';
    } else {
      eligible = false;
      coPayPercent = 100;
      description =
          'Based on this estimate, you may not qualify for state legal aid. '
          'Consider consulting a private lawyer or legal clinic.';
    }

    setState(() {
      _calculated = true;
      _result = _AidResult(
        eligible: eligible,
        coPayPercent: coPayPercent,
        description: description,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Legal Aid Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Check your eligibility for Finnish legal aid',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'This is an estimate only. Actual eligibility is determined by '
              'the Legal Aid Office.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _SliderField(
              label: 'Monthly income (EUR)',
              value: _monthlyIncome,
              min: 0,
              max: 5000,
              divisions: 50,
              onChanged: (v) => setState(() {
                _monthlyIncome = v;
                _calculated = false;
              }),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SliderField(
              label: 'Total assets (EUR)',
              value: _assets,
              min: 0,
              max: 100000,
              divisions: 100,
              onChanged: (v) => setState(() {
                _assets = v;
                _calculated = false;
              }),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                const Text(
                  'Number of dependents',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _dependents > 0
                      ? () => setState(() {
                            _dependents--;
                            _calculated = false;
                          })
                      : null,
                ),
                Text(
                  '$_dependents',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() {
                    _dependents++;
                    _calculated = false;
                  }),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Calculate Eligibility'),
              ),
            ),
            if (_calculated && _result != null) ...[
              const SizedBox(height: AppSpacing.xl),
              _ResultCard(result: _result!),
            ],
          ],
        ),
      ),
    );
  }
}

class _SliderField extends StatelessWidget {
  const _SliderField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const Spacer(),
            Text('${value.toStringAsFixed(0)} EUR',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: AppColors.accent,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _AidResult {
  final bool eligible;
  final double coPayPercent;
  final String description;

  const _AidResult({
    required this.eligible,
    required this.coPayPercent,
    required this.description,
  });
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final _AidResult result;

  @override
  Widget build(BuildContext context) {
    final color = result.eligible ? AppColors.success : AppColors.warning;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.eligible
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  result.eligible ? 'Likely Eligible' : 'May Not Qualify',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: color),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(result.description,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5)),
          ],
        ),
      ),
    );
  }
}
