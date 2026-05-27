// drafting/widgets/ai_revision_dialog.dart — Pkg 7 Drafting Studio MVP.
// -----------------------------------------------------------------------------
// Modal that:
//   1. Captures an optional user instruction ("make it more formal", …)
//   2. Shows a spinner while we call `draft-ai-revise`
//   3. Renders the suggestion with two clear actions: Accept / Reject
//
// Behaviour-only widget: the caller owns the AI call and just feeds in the
// Future. Keeps this dialog cheap to widget-test.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../models/draft_model.dart';

/// Outcome returned to the caller when the user closes the dialog.
class AiRevisionDecision {
  const AiRevisionDecision({required this.accepted, this.revision, this.instruction});
  final bool accepted;
  final AiRevision? revision;
  final String? instruction;
}

/// Shows the dialog. Returns the user's decision (or null if they dismissed).
Future<AiRevisionDecision?> showAiRevisionDialog({
  required BuildContext context,
  required String selectedText,
  required Future<AiRevision> Function(String instruction) onRequestRevision,
}) {
  return showDialog<AiRevisionDecision>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AiRevisionDialog(
      selectedText: selectedText,
      onRequestRevision: onRequestRevision,
    ),
  );
}

class AiRevisionDialog extends StatefulWidget {
  const AiRevisionDialog({
    super.key,
    required this.selectedText,
    required this.onRequestRevision,
  });

  final String selectedText;
  final Future<AiRevision> Function(String instruction) onRequestRevision;

  @override
  State<AiRevisionDialog> createState() => _AiRevisionDialogState();
}

class _AiRevisionDialogState extends State<AiRevisionDialog> {
  final TextEditingController _instructionCtrl = TextEditingController();
  AiRevision? _revision;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _instructionCtrl.dispose();
    super.dispose();
  }

  Future<void> _runRevision() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rev = await widget.onRequestRevision(_instructionCtrl.text.trim());
      if (!mounted) return;
      setState(() {
        _revision = rev;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      key: const Key('ai_revision_dialog'),
      title: Text(l10n.draftingAiReviseTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Selection preview.
              Text(
                l10n.draftingAiReviseSelectionLabel,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              Container(
                key: const Key('ai_revision_selection_box'),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.selectedText,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ),
              const SizedBox(height: 14),
              // Instruction input (only shown until a revision arrives).
              if (_revision == null) ...<Widget>[
                TextField(
                  key: const Key('ai_revision_instruction_field'),
                  controller: _instructionCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.draftingAiReviseInstructionLabel,
                    hintText: l10n.draftingAiReviseInstructionHint,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                FilledButton.icon(
                  key: const Key('ai_revision_run_btn'),
                  onPressed: _loading ? null : _runRevision,
                  icon: _loading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: Text(l10n.draftingAiReviseRunButton),
                ),
              ],
              // Suggestion.
              if (_revision != null) ...<Widget>[
                Text(
                  l10n.draftingAiReviseSuggestionLabel,
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                Container(
                  key: const Key('ai_revision_suggestion_box'),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    _revision!.revisedText,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                if (_revision!.explanation.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    _revision!.explanation,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (_revision!.changesMade.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    l10n.draftingAiReviseChangesLabel,
                    style: theme.textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  for (final c in _revision!.changesMade)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Text('• $c', style: theme.textTheme.bodySmall),
                    ),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          key: const Key('ai_revision_reject_btn'),
          onPressed: () => Navigator.of(context).pop(
            AiRevisionDecision(
              accepted: false,
              revision: _revision,
              instruction: _instructionCtrl.text.trim(),
            ),
          ),
          child: Text(l10n.draftingAiReviseReject),
        ),
        if (_revision != null)
          FilledButton(
            key: const Key('ai_revision_accept_btn'),
            onPressed: () => Navigator.of(context).pop(
              AiRevisionDecision(
                accepted: true,
                revision: _revision,
                instruction: _instructionCtrl.text.trim(),
              ),
            ),
            child: Text(l10n.draftingAiReviseAccept),
          ),
      ],
    );
  }
}
