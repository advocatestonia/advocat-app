// calculators_hub_screen.dart — entry point listing the four legal calculators.
// -----------------------------------------------------------------------------
// Pure navigation hub. Each tile pushes a dedicated calculator screen carrying
// the selected jurisdiction so the screen can resolve the right rate bundle.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import 'child_support_calculator_screen.dart';
import 'limitation_calculator_screen.dart';
import 'severance_calculator_screen.dart';
import 'state_fee_calculator_screen.dart';

class CalculatorsHubScreen extends StatefulWidget {
  const CalculatorsHubScreen({super.key});

  @override
  State<CalculatorsHubScreen> createState() => _CalculatorsHubScreenState();
}

class _CalculatorsHubScreenState extends State<CalculatorsHubScreen> {
  // Default to Estonia; the hub offers a FI/EE toggle that propagates to every
  // calculator (rates and formulas differ by jurisdiction).
  String _jurisdiction = 'EE';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.calcHubTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            l10n.calcHubSubtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Jurisdiction toggle.
          Text(
            l10n.calcHubJurisdiction,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _JurisChip(
                label: '🇪🇪 Eesti',
                selected: _jurisdiction == 'EE',
                onTap: () => setState(() => _jurisdiction = 'EE'),
              ),
              const SizedBox(width: 8),
              _JurisChip(
                label: '🇫🇮 Suomi',
                selected: _jurisdiction == 'FI',
                onTap: () => setState(() => _jurisdiction = 'FI'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          _CalcTile(
            icon: Icons.work_off_outlined,
            title: l10n.calcSeveranceTitle,
            description: l10n.calcSeveranceDesc,
            onTap: () => _open(SeveranceCalculatorScreen(
              jurisdiction: _jurisdiction,
            )),
          ),
          _CalcTile(
            icon: Icons.event_busy_outlined,
            title: l10n.calcLimitationTitle,
            description: l10n.calcLimitationDesc,
            onTap: () => _open(LimitationCalculatorScreen(
              jurisdiction: _jurisdiction,
            )),
          ),
          _CalcTile(
            icon: Icons.account_balance_outlined,
            title: l10n.calcStateFeeTitle,
            description: l10n.calcStateFeeDesc,
            onTap: () => _open(StateFeeCalculatorScreen(
              jurisdiction: _jurisdiction,
            )),
          ),
          _CalcTile(
            icon: Icons.family_restroom_outlined,
            title: l10n.calcChildSupportTitle,
            description: l10n.calcChildSupportDesc,
            onTap: () => _open(ChildSupportCalculatorScreen(
              jurisdiction: _jurisdiction,
            )),
          ),
        ],
      ),
    );
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _JurisChip extends StatelessWidget {
  const _JurisChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.textOnPrimary : AppColors.textPrimary,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.accent,
      backgroundColor: AppColors.surface,
      side: BorderSide(color: selected ? AppColors.accent : AppColors.border),
      onSelected: (_) => onTap(),
    );
  }
}

class _CalcTile extends StatelessWidget {
  const _CalcTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
