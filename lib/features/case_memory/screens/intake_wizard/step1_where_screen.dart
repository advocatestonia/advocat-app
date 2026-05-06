// =====================================================================
// Step 1 — Where? Jurisdiction + authority type + free-text authority
// name.
//
// Required: jurisdiction (defaulted to EE) + authority type.
// Optional: authority name.
//
// Mirrors the legacy minimal create's "jurisdiction" dropdown but adds
// the authority axis so the assistant can disambiguate "police" vs
// "court" vs "social services" without asking.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../state/intake_wizard_state.dart';

/// Jurisdictions matching the legal corpus we ship. Free-form: the DB
/// stores plain text, so adding more later is migration-free.
const kIntakeJurisdictions = ['EE', 'FI', 'RU', 'UA', 'DE', 'EN'];

class Step1WhereScreen extends ConsumerWidget {
  const Step1WhereScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(intakeWizardProvider);
    final notifier = ref.read(intakeWizardProvider.notifier);

    return ListView(
      key: const Key('intake-step-1'),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          l10n?.intakeStep1Title ?? 'Where is the case?',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n?.intakeStep1Subtitle ?? '',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        DropdownButtonFormField<String>(
          key: const Key('intake-jurisdiction-dropdown'),
          initialValue: draft.jurisdiction ?? 'EE',
          decoration: InputDecoration(
            labelText: l10n?.intakeJurisdictionLabel ?? 'Jurisdiction',
          ),
          items: kIntakeJurisdictions
              .map((j) => DropdownMenuItem(value: j, child: Text(j)))
              .toList(),
          onChanged: (v) =>
              notifier.update((d) => d.copyWith(jurisdiction: v ?? 'EE')),
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<IntakeAuthorityType>(
          key: const Key('intake-authority-dropdown'),
          initialValue: draft.authorityType,
          decoration: InputDecoration(
            labelText: l10n?.intakeAuthorityLabel ?? 'Authority type',
          ),
          items: IntakeAuthorityType.values
              .map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(_authorityLabel(t, l10n)),
                  ))
              .toList(),
          onChanged: (v) =>
              notifier.update((d) => d.copyWith(authorityType: v)),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          key: const Key('intake-authority-name-input'),
          initialValue: draft.authorityName,
          decoration: InputDecoration(
            labelText:
                l10n?.intakeAuthorityNameLabel ?? 'Authority name (optional)',
          ),
          onChanged: (v) =>
              notifier.update((d) => d.copyWith(authorityName: v)),
        ),
      ],
    );
  }

  String _authorityLabel(IntakeAuthorityType t, AppLocalizations? l10n) {
    if (l10n == null) return t.dbValue;
    switch (t) {
      case IntakeAuthorityType.police:
        return l10n.intakeAuthorityPolice;
      case IntakeAuthorityType.court:
        return l10n.intakeAuthorityCourt;
      case IntakeAuthorityType.social:
        return l10n.intakeAuthoritySocial;
      case IntakeAuthorityType.employer:
        return l10n.intakeAuthorityEmployer;
      case IntakeAuthorityType.landlord:
        return l10n.intakeAuthorityLandlord;
      case IntakeAuthorityType.opposingParty:
        return l10n.intakeAuthorityOpposingParty;
      case IntakeAuthorityType.other:
        return l10n.intakeAuthorityOther;
    }
  }
}
