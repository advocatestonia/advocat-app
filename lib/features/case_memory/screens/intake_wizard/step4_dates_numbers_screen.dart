// =====================================================================
// Step 4 — Numbers & dates. Case number + incident date + deadlines
// repeater. All optional.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../state/intake_wizard_state.dart';

class Step4DatesNumbersScreen extends ConsumerWidget {
  const Step4DatesNumbersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final draft = ref.watch(intakeWizardProvider);
    final notifier = ref.read(intakeWizardProvider.notifier);

    return ListView(
      key: const Key('intake-step-4'),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          l10n?.intakeStep4Title ?? 'Numbers & dates',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n?.intakeStep4Subtitle ?? '',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          key: const Key('intake-case-number-input'),
          initialValue: draft.caseNumber,
          decoration: InputDecoration(
            labelText: l10n?.intakeCaseNumberLabel ?? 'Case number',
          ),
          onChanged: (v) =>
              notifier.update((d) => d.copyWith(caseNumber: v)),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n?.intakeIncidentDateLabel ?? 'Incident date',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              key: const Key('intake-incident-date-btn'),
              icon: const Icon(Icons.event_outlined, size: 18),
              onPressed: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: draft.incidentDate ?? now,
                  firstDate: DateTime(now.year - 25),
                  lastDate: DateTime(now.year + 1),
                );
                if (picked != null) {
                  notifier.update(
                    (d) => d.copyWith(
                      incidentDate: DateTime.utc(
                        picked.year,
                        picked.month,
                        picked.day,
                      ),
                    ),
                  );
                }
              },
              label: Text(
                draft.incidentDate == null
                    ? (l10n?.intakeIncidentDatePick ?? 'Pick date')
                    : _fmtDate(draft.incidentDate!),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n?.intakeDeadlinesLabel ?? 'Known deadlines',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        ..._buildDeadlineRows(context, draft, notifier, l10n),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('intake-add-deadline-btn'),
            onPressed: () => notifier.update(
              (d) => d.copyWith(
                deadlines: [...d.deadlines, const IntakeDeadline()],
              ),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n?.intakeAddDeadline ?? 'Add deadline'),
          ),
        ),
      ],
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  List<Widget> _buildDeadlineRows(
    BuildContext context,
    IntakeDraft draft,
    IntakeWizardNotifier notifier,
    AppLocalizations? l10n,
  ) {
    return [
      for (var i = 0; i < draft.deadlines.length; i++)
        Padding(
          key: Key('intake-deadline-row-$i'),
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: draft.deadlines[i].what,
                  decoration: InputDecoration(
                    hintText:
                        l10n?.intakeDeadlineWhatHint ?? 'What',
                  ),
                  onChanged: (v) {
                    final next = [...draft.deadlines];
                    next[i] = next[i].copyWith(what: v);
                    notifier.update((d) => d.copyWith(deadlines: next));
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: draft.deadlines[i].date ?? now,
                    firstDate: DateTime(now.year - 5),
                    lastDate: DateTime(now.year + 5),
                  );
                  if (picked != null) {
                    final next = [...draft.deadlines];
                    next[i] = next[i].copyWith(
                      date: DateTime.utc(
                        picked.year,
                        picked.month,
                        picked.day,
                      ),
                    );
                    notifier.update((d) => d.copyWith(deadlines: next));
                  }
                },
                child: Text(
                  draft.deadlines[i].date == null
                      ? (l10n?.intakeIncidentDatePick ?? 'Pick date')
                      : _fmtDate(draft.deadlines[i].date!),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.error,
                onPressed: () {
                  final next = [...draft.deadlines]..removeAt(i);
                  notifier.update((d) => d.copyWith(deadlines: next));
                },
              ),
            ],
          ),
        ),
    ];
  }
}
