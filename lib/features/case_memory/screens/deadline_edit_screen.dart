// =====================================================================
// DeadlineEditScreen — manual create / edit for a single deadline.
//
// Used for:
//   * /cases-v2/:id/deadlines/new
//   * /cases-v2/:id/deadlines/:deadlineId/edit
//
// The statute-template dropdown is sourced from a small in-app list of
// the four deadline-kind anchors. We don't import the full TS registry
// in Dart — only the option list users actually pick from.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../models/case_deadline.dart';
import '../state/case_deadline_providers.dart';

/// Statute-template options exposed to the manual-edit form. Mirrors
/// the four deadline-kind anchors in
/// `supabase/functions/_shared/statutory_anchors.ts`.
class DeadlineStatuteOption {
  const DeadlineStatuteOption({
    required this.anchorKey,
    required this.label,
    required this.statuteBasis,
  });
  final String? anchorKey;
  final String label;
  final String statuteBasis;
}

const List<DeadlineStatuteOption> kDeadlineStatuteOptions = [
  DeadlineStatuteOption(
    anchorKey: 'ee_hkms_46_kaebus',
    label: 'EE — Kaebus halduskohtule',
    statuteBasis: 'HKMS §46',
  ),
  DeadlineStatuteOption(
    anchorKey: 'ee_hms_75_vaie',
    label: 'EE — Vaie',
    statuteBasis: 'HMS §75',
  ),
  DeadlineStatuteOption(
    anchorKey: 'fi_hol_2019_808_khoa',
    label: 'FI — Valitus KHO:hon',
    statuteBasis: 'HOL §164',
  ),
  DeadlineStatuteOption(
    anchorKey: 'fi_hl_49b_oikaisu',
    label: 'FI — Oikaisuvaatimus',
    statuteBasis: 'Hallintolaki §49b',
  ),
  DeadlineStatuteOption(
    anchorKey: 'eu_echr_protocol_15',
    label: 'EU — ECHR application',
    statuteBasis: 'ECHR Protocol 15',
  ),
];

class DeadlineEditScreen extends ConsumerStatefulWidget {
  const DeadlineEditScreen({
    super.key,
    required this.caseId,
    this.existing,
  });

  final String caseId;
  final CaseDeadline? existing;

  @override
  ConsumerState<DeadlineEditScreen> createState() =>
      _DeadlineEditScreenState();
}

class _DeadlineEditScreenState extends ConsumerState<DeadlineEditScreen> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  DateTime? _deadlineAt;
  DeadlineStatuteOption? _selectedTemplate;
  CaseDeadlinePriority _priority = CaseDeadlinePriority.high;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _title = TextEditingController(text: ex?.title ?? '');
    _description = TextEditingController(text: ex?.description ?? '');
    _deadlineAt = ex?.deadlineAt;
    _priority = ex?.priority ?? CaseDeadlinePriority.high;
    if (ex?.anchorKey != null) {
      _selectedTemplate = kDeadlineStatuteOptions.firstWhere(
        (o) => o.anchorKey == ex!.anchorKey,
        orElse: () => kDeadlineStatuteOptions.first,
      );
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit
              ? (l10n?.deadlineCardEdit ?? 'Edit deadline')
              : (l10n?.deadlineAddManualCta ?? 'Add deadline'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            TextField(
              key: const Key('deadline-form-title'),
              controller: _title,
              decoration: InputDecoration(
                labelText: l10n?.deadlineFormTitle ?? 'Title',
              ),
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const Key('deadline-form-description'),
              controller: _description,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n?.deadlineFormDescription ??
                    'Description (optional)',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<DeadlineStatuteOption?>(
              key: const Key('deadline-form-statute'),
              initialValue: _selectedTemplate,
              decoration: InputDecoration(
                labelText: l10n?.deadlineFormStatuteTemplate ??
                    'Statute template',
              ),
              items: <DropdownMenuItem<DeadlineStatuteOption?>>[
                DropdownMenuItem(
                  value: null,
                  child: Text(l10n?.deadlineFormStatuteTemplateNone ??
                      'None (manual)'),
                ),
                ...kDeadlineStatuteOptions.map(
                  (o) => DropdownMenuItem(
                    value: o,
                    child: Text(o.label),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _selectedTemplate = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              key: const Key('deadline-form-date'),
              contentPadding: EdgeInsets.zero,
              title: Text(
                  l10n?.deadlineFormDeadlineAt ?? 'Deadline date'),
              subtitle: Text(_deadlineAt == null
                  ? '—'
                  : _deadlineAt!.toLocal().toString().split('.').first),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<CaseDeadlinePriority>(
              key: const Key('deadline-form-priority'),
              initialValue: _priority,
              decoration: InputDecoration(
                labelText: l10n?.deadlineFormPriority ?? 'Priority',
              ),
              items: CaseDeadlinePriority.values
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.dbValue),
                      ))
                  .toList(growable: false),
              onChanged: (v) => setState(() {
                if (v != null) _priority = v;
              }),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                    child:
                        Text(l10n?.deadlineFormCancel ?? 'Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    key: const Key('deadline-form-save'),
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n?.deadlineFormSave ?? 'Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadlineAt ??
          DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate:
          DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked == null) return;
    setState(() {
      _deadlineAt = DateTime(picked.year, picked.month, picked.day, 16, 0);
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final title = _title.text.trim();
    final at = _deadlineAt;
    if (title.isEmpty || at == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.deadlineRequiredFields ??
                'Title and deadline date are required',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final mutations = ref.read(deadlineMutationsProvider);
    try {
      if (widget.existing == null) {
        await mutations.createManual(
          caseId: widget.caseId,
          title: title,
          deadlineAt: at,
          description:
              _description.text.trim().isEmpty ? null : _description.text.trim(),
          statuteBasis: _selectedTemplate?.statuteBasis,
          anchorKey: _selectedTemplate?.anchorKey,
          priority: _priority,
        );
      } else {
        await mutations.editManual(
          id: widget.existing!.id,
          caseId: widget.caseId,
          title: title,
          deadlineAt: at,
          description:
              _description.text.trim().isEmpty ? null : _description.text.trim(),
          statuteBasis: _selectedTemplate?.statuteBasis,
          priority: _priority,
        );
      }
      if (mounted) navigator.pop();
    } catch (e) {
      debugPrint('deadline save failed: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n?.genericError ?? 'Something went wrong. Please try again.',
          ),
        ),
      );
      if (mounted) setState(() => _saving = false);
    }
  }
}
