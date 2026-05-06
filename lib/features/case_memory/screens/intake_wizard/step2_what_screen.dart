// =====================================================================
// Step 2 — What? Case-type single-select via large tappable cards.
//
// Required: case type. No free text — the AI can refine in chat.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../state/intake_wizard_state.dart';

class Step2WhatScreen extends ConsumerWidget {
  const Step2WhatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(intakeWizardProvider);
    final notifier = ref.read(intakeWizardProvider.notifier);

    return ListView(
      key: const Key('intake-step-2'),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          l10n?.intakeStep2Title ?? 'What kind of case?',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n?.intakeStep2Subtitle ?? '',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: IntakeCaseType.values.map((t) {
            final selected = draft.caseType == t;
            return _CaseTypeCard(
              key: Key('intake-case-type-${t.dbValue}'),
              type: t,
              label: _caseTypeLabel(t, l10n),
              icon: _caseTypeIcon(t),
              selected: selected,
              onTap: () => notifier.update((d) => d.copyWith(caseType: t)),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _caseTypeLabel(IntakeCaseType t, AppLocalizations? l10n) {
    if (l10n == null) return t.dbValue;
    switch (t) {
      case IntakeCaseType.criminal:
        return l10n.intakeCaseTypeCriminal;
      case IntakeCaseType.civil:
        return l10n.intakeCaseTypeCivil;
      case IntakeCaseType.family:
        return l10n.intakeCaseTypeFamily;
      case IntakeCaseType.admin:
        return l10n.intakeCaseTypeAdmin;
      case IntakeCaseType.immigration:
        return l10n.intakeCaseTypeImmigration;
      case IntakeCaseType.labor:
        return l10n.intakeCaseTypeLabor;
      case IntakeCaseType.consumer:
        return l10n.intakeCaseTypeConsumer;
      case IntakeCaseType.inheritance:
        return l10n.intakeCaseTypeInheritance;
      case IntakeCaseType.other:
        return l10n.intakeCaseTypeOther;
    }
  }

  IconData _caseTypeIcon(IntakeCaseType t) {
    switch (t) {
      case IntakeCaseType.criminal:
        return Icons.gavel;
      case IntakeCaseType.civil:
        return Icons.balance;
      case IntakeCaseType.family:
        return Icons.family_restroom;
      case IntakeCaseType.admin:
        return Icons.account_balance;
      case IntakeCaseType.immigration:
        return Icons.flight_takeoff;
      case IntakeCaseType.labor:
        return Icons.work_outline;
      case IntakeCaseType.consumer:
        return Icons.shopping_cart_outlined;
      case IntakeCaseType.inheritance:
        return Icons.account_tree_outlined;
      case IntakeCaseType.other:
        return Icons.more_horiz;
    }
  }
}

class _CaseTypeCard extends StatelessWidget {
  const _CaseTypeCard({
    super.key,
    required this.type,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IntakeCaseType type;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 110,
      child: Material(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: selected ? Colors.white : AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
