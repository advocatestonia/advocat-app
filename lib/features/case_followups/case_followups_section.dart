/// Smart Case Follow-ups (Feature #2) — the "Next steps" section widget.
///
/// Renders the soft next-step checklist on the case detail screen. Lets the
/// user tick steps done, snooze, dismiss, add their own, and pull 3-5
/// AI-suggested steps. Distinct from the Deadlines section (statutory dates).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import 'case_followup_model.dart';
import 'case_followups_provider.dart';

class CaseFollowupsSection extends ConsumerWidget {
  const CaseFollowupsSection({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(caseFollowupsProvider(caseId));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.checklist_rounded,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n?.followupsTitle ?? 'Next steps',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              IconButton(
                tooltip: l10n?.followupsSuggest ?? 'Suggest steps',
                icon: const Icon(Icons.auto_awesome, size: 20),
                onPressed: () => _onSuggest(context, ref),
              ),
              IconButton(
                tooltip: l10n?.followupsAdd ?? 'Add step',
                icon: const Icon(Icons.add, size: 22),
                onPressed: () => _onAdd(context, ref),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                l10n?.followupsLoadError ?? 'Could not load next steps',
                style: const TextStyle(color: AppColors.textTertiary),
              ),
            ),
            data: (items) => items.isEmpty
                ? _EmptyState(l10n: l10n)
                : Column(
                    children: items
                        .map((f) => _FollowupTile(
                              followup: f,
                              caseId: caseId,
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _onAdd(BuildContext context, WidgetRef ref) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddFollowupSheet(caseId: caseId),
    );
    if (created == true) ref.invalidate(caseFollowupsProvider(caseId));
  }

  Future<void> _onSuggest(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(caseFollowupsServiceProvider);

    // The transcript is intentionally light: we ask the backend to base
    // suggestions on the case file. Passing the case id is enough for the
    // edge fn to fold in existing steps; a richer transcript can be wired
    // from chat later. For now we seed with a neutral prompt so Haiku reasons
    // from the case context the backend already holds.
    final suggestions = await service.suggest(
      caseId: caseId,
      transcript: 'Suggest practical next steps for this case.',
    );

    if (!context.mounted) return;
    if (suggestions.isEmpty) {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n?.followupsSuggestNone ??
            'No suggestions right now. Try after chatting about the case.'),
      ));
      return;
    }

    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SuggestionsSheet(caseId: caseId, suggestions: suggestions),
    );
    if (added == true) ref.invalidate(caseFollowupsProvider(caseId));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.followupsEmpty ?? 'No follow-up steps yet.',
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n?.followupsEmptyDesc ??
                'Add a step, or let the AI suggest what to do next.',
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _FollowupTile extends ConsumerWidget {
  const _FollowupTile({required this.followup, required this.caseId});

  final CaseFollowup followup;
  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final done = followup.isDone;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: done,
            visualDensity: VisualDensity.compact,
            onChanged: done
                ? null
                : (_) => _complete(ref),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        followup.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          decoration: done ? TextDecoration.lineThrough : null,
                          color: done
                              ? AppColors.textTertiary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (followup.source == FollowupSource.ai) ...[
                      const SizedBox(width: AppSpacing.xs),
                      _AiBadge(label: l10n?.followupsAiBadge ?? 'AI'),
                    ],
                  ],
                ),
                if (followup.detail != null && followup.detail!.isNotEmpty)
                  Text(
                    followup.detail!,
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 12.5),
                  ),
                if (followup.dueAt != null && !done)
                  Text(
                    followup.isOverdue
                        ? (l10n?.followupsOverdue ?? 'Overdue')
                        : (l10n?.followupsDueOn(_fmtDate(followup.dueAt!)) ??
                            'Due ${_fmtDate(followup.dueAt!)}'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: followup.isOverdue
                          ? AppColors.error
                          : AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          if (!done)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  size: 18, color: AppColors.textTertiary),
              onSelected: (v) => _onMenu(context, ref, v),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'snooze',
                  child: Text(l10n?.followupsSnooze1Week ?? 'Remind in a week'),
                ),
                PopupMenuItem(
                  value: 'dismiss',
                  child: Text(l10n?.followupsDismiss ?? 'Dismiss'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _complete(WidgetRef ref) async {
    final ok = await ref.read(caseFollowupsServiceProvider).complete(followup.id);
    if (ok) ref.invalidate(caseFollowupsProvider(caseId));
  }

  Future<void> _onMenu(BuildContext context, WidgetRef ref, String action) async {
    final service = ref.read(caseFollowupsServiceProvider);
    bool ok = false;
    if (action == 'snooze') {
      ok = await service.snooze(
        followup.id,
        DateTime.now().add(const Duration(days: 7)),
      );
    } else if (action == 'dismiss') {
      ok = await service.dismiss(followup.id);
    }
    if (ok) ref.invalidate(caseFollowupsProvider(caseId));
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _AiBadge extends StatelessWidget {
  const _AiBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add-step bottom sheet
// ---------------------------------------------------------------------------

class _AddFollowupSheet extends ConsumerStatefulWidget {
  const _AddFollowupSheet({required this.caseId});

  final String caseId;

  @override
  ConsumerState<_AddFollowupSheet> createState() => _AddFollowupSheetState();
}

class _AddFollowupSheetState extends ConsumerState<_AddFollowupSheet> {
  final _title = TextEditingController();
  final _detail = TextEditingController();
  DateTime? _dueAt;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _detail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.followupsAdd ?? 'Add step',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _title,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n?.followupsNewTitleHint ?? 'What needs to be done?',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _detail,
            decoration: InputDecoration(
              hintText:
                  l10n?.followupsNewDetailHint ?? 'Optional note (why / what to attach)',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            icon: const Icon(Icons.event_outlined, size: 18),
            label: Text(
              _dueAt == null
                  ? (l10n?.followupsDueOptional ?? 'Remind me on (optional)')
                  : _fmt(_dueAt!),
            ),
            onPressed: _pickDate,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n?.followupsAdd ?? 'Add step'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueAt = picked);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);
    final created = await ref.read(caseFollowupsServiceProvider).create(
          caseId: widget.caseId,
          title: title,
          detail: _detail.text.trim(),
          dueAt: _dueAt,
        );
    if (!mounted) return;
    Navigator.of(context).pop(created != null);
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// Suggestions bottom sheet
// ---------------------------------------------------------------------------

class _SuggestionsSheet extends ConsumerStatefulWidget {
  const _SuggestionsSheet({required this.caseId, required this.suggestions});

  final String caseId;
  final List<FollowupSuggestion> suggestions;

  @override
  ConsumerState<_SuggestionsSheet> createState() => _SuggestionsSheetState();
}

class _SuggestionsSheetState extends ConsumerState<_SuggestionsSheet> {
  late final List<bool> _checked =
      List<bool>.filled(widget.suggestions.length, true);
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.followupsSuggestTitle ?? 'Suggested next steps',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n?.followupsAddPrompt ?? 'Add the steps you want to keep:',
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.sm),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.suggestions.length,
              itemBuilder: (_, i) {
                final s = widget.suggestions[i];
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _checked[i],
                  onChanged: (v) => setState(() => _checked[i] = v ?? false),
                  title: Text(s.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: s.detail != null && s.detail!.isNotEmpty
                      ? Text(s.detail!)
                      : null,
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _saveSelected,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n?.followupsAdd ?? 'Add step'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSelected() async {
    setState(() => _saving = true);
    final service = ref.read(caseFollowupsServiceProvider);
    var anyAdded = false;
    for (var i = 0; i < widget.suggestions.length; i++) {
      if (!_checked[i]) continue;
      final s = widget.suggestions[i];
      final created = await service.create(
        caseId: widget.caseId,
        title: s.title,
        detail: s.detail,
        dueAt: s.dueAtFrom(),
        source: FollowupSource.ai,
      );
      if (created != null) anyAdded = true;
    }
    if (!mounted) return;
    Navigator.of(context).pop(anyAdded);
  }
}
