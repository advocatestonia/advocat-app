// =====================================================================
// Step 3 — Parties. Your role + opposing side + witnesses repeater.
// All optional.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../state/intake_wizard_state.dart';

class Step3PartiesScreen extends ConsumerWidget {
  const Step3PartiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(intakeWizardProvider);
    final notifier = ref.read(intakeWizardProvider.notifier);

    return ListView(
      key: const Key('intake-step-3'),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          l10n?.intakeStep3Title ?? 'Who is involved?',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n?.intakeStep3Subtitle ?? '',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n?.intakeRoleLabel ?? 'Your role',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: IntakeUserRole.values.map((r) {
            final selected = draft.userRole == r;
            return ChoiceChip(
              key: Key('intake-role-${r.dbValue}'),
              label: Text(_roleLabel(r, l10n)),
              selected: selected,
              onSelected: (sel) => notifier
                  .update((d) => d.copyWith(userRole: sel ? r : null)),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          key: const Key('intake-opposing-side-input'),
          initialValue: draft.opposingSide,
          decoration: InputDecoration(
            labelText:
                l10n?.intakeOpposingSideLabel ?? 'Opposing side (optional)',
          ),
          onChanged: (v) =>
              notifier.update((d) => d.copyWith(opposingSide: v)),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n?.intakeWitnessesLabel ?? 'Witnesses (optional)',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        ..._buildWitnessRows(draft, notifier, l10n),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('intake-add-witness-btn'),
            onPressed: () => notifier.update(
              (d) => d.copyWith(witnesses: [...d.witnesses, '']),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n?.intakeAddWitness ?? 'Add witness'),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildWitnessRows(
    IntakeDraft draft,
    IntakeWizardNotifier notifier,
    AppLocalizations? l10n,
  ) {
    return [
      for (var i = 0; i < draft.witnesses.length; i++)
        Padding(
          key: Key('intake-witness-row-$i'),
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: draft.witnesses[i],
                  decoration: InputDecoration(
                    hintText:
                        l10n?.intakeWitnessHint ?? 'Name or contact',
                  ),
                  onChanged: (v) {
                    final next = [...draft.witnesses];
                    next[i] = v;
                    notifier.update((d) => d.copyWith(witnesses: next));
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: l10n?.delete ?? 'Delete',
                color: AppColors.error,
                onPressed: () {
                  final next = [...draft.witnesses]..removeAt(i);
                  notifier.update((d) => d.copyWith(witnesses: next));
                },
              ),
            ],
          ),
        ),
    ];
  }

  String _roleLabel(IntakeUserRole r, AppLocalizations? l10n) {
    if (l10n == null) return r.dbValue;
    switch (r) {
      case IntakeUserRole.plaintiff:
        return l10n.intakeRolePlaintiff;
      case IntakeUserRole.defendant:
        return l10n.intakeRoleDefendant;
      case IntakeUserRole.victim:
        return l10n.intakeRoleVictim;
      case IntakeUserRole.accused:
        return l10n.intakeRoleAccused;
      case IntakeUserRole.witness:
        return l10n.intakeRoleWitness;
      case IntakeUserRole.family:
        return l10n.intakeRoleFamily;
      case IntakeUserRole.other:
        return l10n.intakeRoleOther;
    }
  }
}
