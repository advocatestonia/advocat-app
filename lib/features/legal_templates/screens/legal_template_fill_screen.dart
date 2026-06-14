// legal_templates/screens/legal_template_fill_screen.dart — Feature #5.
// -----------------------------------------------------------------------------
// Collects the template's required (manual) fields, calls the `template-fill`
// edge function to substitute case/profile data + the entered values, then
// persists the result as a normal draft via the existing DraftService and
// opens the Drafting Studio editor for it.
//
// We deliberately reuse DraftService.createDraft rather than introducing a new
// persistence path, so the established PDF/DOCX export and Vault flows apply
// unchanged to template-generated documents.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/secure_screen.dart';
import '../../drafting/models/draft_model.dart';
import '../../drafting/screens/drafting_studio_screen.dart';
import '../../drafting/services/draft_service.dart';
import '../models/legal_template.dart';
import '../services/legal_template_service.dart';

class LegalTemplateFillScreen extends ConsumerStatefulWidget {
  const LegalTemplateFillScreen({super.key, required this.template});

  final LegalTemplate template;

  @override
  ConsumerState<LegalTemplateFillScreen> createState() =>
      _LegalTemplateFillScreenState();
}

class _LegalTemplateFillScreenState
    extends ConsumerState<LegalTemplateFillScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    for (final f in widget.template.requiredFields) {
      _controllers[f] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Maps a token name to its localized label, falling back to a humanized
  /// version of the snake_case token for any token without a dedicated string.
  String _labelFor(String token, AppLocalizations l10n) {
    switch (token) {
      case 'recipient':
        return l10n.legalTemplatesFieldRecipient;
      case 'address':
        return l10n.legalTemplatesFieldAddress;
      case 'subject':
        return l10n.legalTemplatesFieldSubject;
      case 'description':
        return l10n.legalTemplatesFieldDescription;
      case 'demand':
        return l10n.legalTemplatesFieldDemand;
      default:
        return humanizeToken(token);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final userId = currentLegalTemplateUserId();
    if (userId == null) {
      _showError(l10n.legalTemplatesCreateFailed);
      return;
    }

    setState(() => _busy = true);
    try {
      final fields = <String, String>{
        for (final entry in _controllers.entries)
          entry.key: entry.value.text.trim(),
      };

      // 1. Fill the template server-side (auto data + entered fields).
      final tplSvc = ref.read(legalTemplateServiceProvider);
      final filled = await tplSvc.fillTemplate(
        templateId: widget.template.id,
        fields: fields,
      );

      // 2. Persist as a normal draft (reuses export/Vault pipeline).
      final draftSvc = ref.read(draftServiceProvider);
      final draft = await draftSvc.createDraft(
        userId: userId,
        sourceType: DraftSourceType.letter,
        title: filled.title,
        contentMarkdown: filled.filled,
        jurisdiction: widget.template.jurisdiction,
        language: widget.template.locale,
        metadata: <String, dynamic>{
          'origin': 'legal_template',
          'template_slug': widget.template.slug,
          if (filled.unresolved.isNotEmpty) 'unresolved': filled.unresolved,
        },
      );

      if (!mounted) return;

      // Surface a non-blocking warning when fields remain blank.
      if (filled.unresolved.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.legalTemplatesUnresolvedWarning)),
        );
      }

      // 3. Open the editor (replace so Back returns to the gallery).
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => DraftingStudioScreen(draftId: draft.id),
        ),
      );
    } catch (e, st) {
      debugPrint('[legal_template_fill] submit failed: $e\n$st');
      if (mounted) _showError(l10n.legalTemplatesCreateFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final fields = widget.template.requiredFields;

    return SecureScreenScope(
      child: Scaffold(
        appBar: AppBar(title: Text(widget.template.title)),
        body: Form(
          key: _formKey,
          child: ListView(
            key: const Key('legal_template_fill_form'),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: <Widget>[
              Text(
                l10n.legalTemplatesFillIntro,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.legalTemplatesDisclaimer,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              for (final token in fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    key: Key('legal_template_field_$token'),
                    controller: _controllers[token],
                    minLines: token == 'description' || token == 'demand'
                        ? 3
                        : 1,
                    maxLines: token == 'description' || token == 'demand'
                        ? 6
                        : 1,
                    decoration: InputDecoration(
                      labelText: _labelFor(token, l10n),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? l10n.legalTemplatesFieldRequired
                            : null,
                  ),
                ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('legal_template_create_fab'),
          onPressed: _busy ? null : _submit,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.note_add_outlined),
          label: Text(
            _busy
                ? l10n.legalTemplatesCreating
                : l10n.legalTemplatesCreateDraft,
          ),
        ),
      ),
    );
  }
}
