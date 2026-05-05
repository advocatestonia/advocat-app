// =====================================================================
// CaseCreateScreen — minimal create form (Pkg 1.D scope).
//
// Pkg 3 will replace this with the 5-screen structured-intake wizard.
// For now: title + jurisdiction + case_type + language → create →
// navigate to detail with the new case set as active.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/case_repository.dart';
import '../state/active_case_provider.dart';
import '../state/cases_list_provider.dart';

/// Jurisdictions we support — matches the legal corpus we ship with.
/// The DB column is just `text`, so adding a new one later doesn't
/// require a migration.
const _kJurisdictions = ['EE', 'FI', 'RU', 'UA', 'EN'];

/// Case types we surface in the picker. Server accepts any string;
/// these are the canonical taxonomy from the migration.
const _kCaseTypes = [
  'deportation',
  'criminal',
  'civil',
  'family',
  'admin',
  'immigration',
  'labor',
  'other',
];

/// Languages the assistant currently has full prompt support for.
const _kLanguages = ['ru', 'en', 'et', 'fi', 'uk'];

class CaseCreateScreen extends ConsumerStatefulWidget {
  const CaseCreateScreen({super.key});

  @override
  ConsumerState<CaseCreateScreen> createState() => _CaseCreateScreenState();
}

class _CaseCreateScreenState extends ConsumerState<CaseCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  String _jurisdiction = 'EE';
  String _caseType = 'other';
  String _language = 'ru';
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(caseRepositoryProvider);
      final created = await repo.createCase(
        title: _titleController.text.trim(),
        jurisdiction: _jurisdiction,
        caseType: _caseType,
        language: _language,
      );

      // Mark the new case active so the next chat opens with full
      // context.
      await ref
          .read(activeCaseProvider.notifier)
          .setActiveCase(created);

      // Pull-to-refresh idempotent — invalidate list before navigation.
      ref.invalidate(casesListProvider);

      if (!mounted) return;
      // Replace the current /cases-v2/new with the detail screen so
      // back doesn't return to the empty form.
      context.go('/cases-v2/${created.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.newCase ?? 'New case'),
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n?.caseTitleLabel ?? 'Case title',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return l10n?.caseTitleLabel ?? 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                key: const Key('jurisdiction-dropdown'),
                initialValue: _jurisdiction,
                decoration: InputDecoration(
                  labelText: l10n?.jurisdictionLabel ?? 'Jurisdiction',
                ),
                items: _kJurisdictions
                    .map((j) => DropdownMenuItem(value: j, child: Text(j)))
                    .toList(),
                onChanged: (v) => setState(() => _jurisdiction = v ?? 'EE'),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                key: const Key('case-type-dropdown'),
                initialValue: _caseType,
                decoration: InputDecoration(
                  labelText: l10n?.caseTypeLabel ?? 'Case type',
                ),
                items: _kCaseTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _caseType = v ?? 'other'),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                key: const Key('language-dropdown'),
                initialValue: _language,
                decoration: InputDecoration(
                  labelText: l10n?.caseLanguageLabel ?? 'Language',
                ),
                items: _kLanguages
                    .map((lang) =>
                        DropdownMenuItem(value: lang, child: Text(lang)))
                    .toList(),
                onChanged: (v) => setState(() => _language = v ?? 'ru'),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                key: const Key('create-case-submit'),
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n?.createCase ?? 'Create case'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
