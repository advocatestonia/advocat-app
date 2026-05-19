// =====================================================================
// CaseDeadlinesScreen — per-case deadline list with mutations.
//
// Reachable from:
//   * case_detail_screen.dart "View deadlines" link
//   * GoRouter `/cases-v2/:id/deadlines`
//   * Notification deep-link
//
// Capabilities:
//   * sort (default by `deadline_at asc`)
//   * filter (active / completed / archived / all)
//   * mark complete (with optional note)
//   * snooze 3d / 7d / custom
//   * archive
//   * "Add deadline" CTA → DeadlineEditScreen
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../models/case_deadline.dart';
import '../state/case_deadline_providers.dart';
import '../widgets/deadline_card.dart';

enum _DeadlineFilter { active, completed, archived, all }

final _filterProvider = StateProvider.autoDispose<_DeadlineFilter>(
  (_) => _DeadlineFilter.active,
);

class CaseDeadlinesScreen extends ConsumerWidget {
  const CaseDeadlinesScreen({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncDeadlines = ref.watch(deadlinesProvider(caseId));
    final filter = ref.watch(_filterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.deadlineCaseScreenTitle ?? 'Case deadlines'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('deadline-add-cta'),
        onPressed: () => context.push('/cases-v2/$caseId/deadlines/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n?.deadlineAddManualCta ?? 'Add deadline'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: SegmentedButton<_DeadlineFilter>(
              segments: [
                ButtonSegment(
                  value: _DeadlineFilter.active,
                  label: Text(l10n?.upcoming ?? 'Active'),
                ),
                ButtonSegment(
                  value: _DeadlineFilter.completed,
                  label: Text(l10n?.completed ?? 'Done'),
                ),
                ButtonSegment(
                  value: _DeadlineFilter.archived,
                  label: Text(l10n?.deadlineCardDelete ?? 'Archived'),
                ),
                ButtonSegment(
                  value: _DeadlineFilter.all,
                  label: Text(l10n?.all ?? 'All'),
                ),
              ],
              selected: {filter},
              onSelectionChanged: (sel) =>
                  ref.read(_filterProvider.notifier).state = sel.first,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          Expanded(
            child: asyncDeadlines.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) {
                debugPrint('deadlines load failed: $e');
                return Center(
                  child: Text(
                    l10n?.genericError ??
                        'Something went wrong. Please try again.',
                  ),
                );
              },
              data: (deadlines) {
                final filtered = _applyFilter(deadlines, filter);
                if (filtered.isEmpty) {
                  return Center(
                    key: const Key('case-deadlines-empty'),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        l10n?.deadlineRadarEmpty ?? 'No deadlines',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(deadlinesProvider(caseId)),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      AppSpacing.xxl + AppSpacing.md,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, i) {
                      final d = filtered[i];
                      return DeadlineCard(
                        deadline: d,
                        onTap: () =>
                            _showDetailSheet(context, ref, d, l10n),
                        onMarkComplete: () =>
                            _onMarkComplete(context, ref, d, l10n),
                        onSnooze: () => _onSnooze(context, ref, d, l10n),
                        onEdit: () => context.push(
                            '/cases-v2/$caseId/deadlines/${d.id}/edit'),
                        onArchive: () => _onArchive(context, ref, d),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<CaseDeadline> _applyFilter(
      List<CaseDeadline> all, _DeadlineFilter filter) {
    switch (filter) {
      case _DeadlineFilter.active:
        return all
            .where((d) => d.status == CaseDeadlineStatus.active)
            .toList(growable: false);
      case _DeadlineFilter.completed:
        return all
            .where((d) => d.status == CaseDeadlineStatus.completed)
            .toList(growable: false);
      case _DeadlineFilter.archived:
        return all
            .where((d) => d.status == CaseDeadlineStatus.archived)
            .toList(growable: false);
      case _DeadlineFilter.all:
        return all;
    }
  }

  Future<void> _onMarkComplete(BuildContext context, WidgetRef ref,
      CaseDeadline d, AppLocalizations? l10n) async {
    final messenger = ScaffoldMessenger.of(context);
    final note = await _promptForNote(context, l10n);
    if (note == null) return;
    try {
      await ref.read(deadlineMutationsProvider).markComplete(
            deadlineId: d.id,
            caseId: caseId,
            note: note.isEmpty ? null : note,
          );
    } catch (e) {
      debugPrint('deadline markComplete failed: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n?.genericError ?? 'Something went wrong. Please try again.',
          ),
        ),
      );
    }
  }

  /// Returns null if user cancelled, '' if user saved without a note.
  Future<String?> _promptForNote(
      BuildContext context, AppLocalizations? l10n) async {
    return showDialog<String?>(
      context: context,
      builder: (ctx) => _CompleteNoteDialog(l10n: l10n),
    );
  }

  Future<void> _onSnooze(BuildContext context, WidgetRef ref,
      CaseDeadline d, AppLocalizations? l10n) async {
    final messenger = ScaffoldMessenger.of(context);
    final selected = await showModalBottomSheet<Duration?>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('deadline-snooze-3d'),
              leading: const Icon(Icons.snooze),
              title:
                  Text(l10n?.deadlineCardSnooze3d ?? 'Snooze 3 days'),
              onTap: () =>
                  Navigator.pop(ctx, const Duration(days: 3)),
            ),
            ListTile(
              key: const Key('deadline-snooze-7d'),
              leading: const Icon(Icons.snooze),
              title:
                  Text(l10n?.deadlineCardSnooze7d ?? 'Snooze 7 days'),
              onTap: () =>
                  Navigator.pop(ctx, const Duration(days: 7)),
            ),
            ListTile(
              key: const Key('deadline-snooze-custom'),
              leading: const Icon(Icons.calendar_today),
              title:
                  Text(l10n?.deadlineCardSnoozeCustom ?? 'Pick a date'),
              onTap: () => Navigator.pop(ctx, _kCustomSentinel),
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    DateTime newAt;
    if (identical(selected, _kCustomSentinel)) {
      if (!context.mounted) return;
      final picked = await showDatePicker(
        context: context,
        initialDate: d.deadlineAt.add(const Duration(days: 7)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      );
      if (picked == null) return;
      newAt = DateTime(picked.year, picked.month, picked.day,
          d.deadlineAt.hour, d.deadlineAt.minute);
    } else {
      newAt = d.deadlineAt.add(selected);
    }
    try {
      await ref.read(deadlineMutationsProvider).snooze(
            deadlineId: d.id,
            caseId: caseId,
            newDeadlineAt: newAt,
          );
    } catch (e) {
      debugPrint('deadline snooze failed: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n?.genericError ?? 'Something went wrong. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> _onArchive(
      BuildContext context, WidgetRef ref, CaseDeadline d) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(deadlineMutationsProvider).archive(
            deadlineId: d.id,
            caseId: caseId,
          );
    } catch (e) {
      debugPrint('deadline archive failed: $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n?.genericError ?? 'Something went wrong. Please try again.',
          ),
        ),
      );
    }
  }

  void _showDetailSheet(BuildContext context, WidgetRef ref,
      CaseDeadline d, AppLocalizations? l10n) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                d.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (d.statuteBasis != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(d.statuteBasis!,
                    style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary)),
              ],
              if (d.holidayShifted && d.holidayShiftNote != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.swap_calls,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        d.holidayShiftNote!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sentinel that means "show a date picker" — we reuse Duration as the
/// return type so the bottom-sheet stays simple.
const Duration _kCustomSentinel = Duration(microseconds: -1);

/// Dialog body for the completion-note prompt. Stateful because the
/// TextEditingController must be owned by a widget with a clear
/// lifecycle (otherwise the controller leaks at test-shutdown and
/// triggers the InputDecorator-out-of-scope assertion).
class _CompleteNoteDialog extends StatefulWidget {
  const _CompleteNoteDialog({required this.l10n});
  final AppLocalizations? l10n;

  @override
  State<_CompleteNoteDialog> createState() => _CompleteNoteDialogState();
}

class _CompleteNoteDialogState extends State<_CompleteNoteDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n?.deadlineCompletedNotePrompt ?? 'Note (optional)'),
      content: TextField(
        controller: _controller,
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(l10n?.deadlineFormCancel ?? 'Cancel'),
        ),
        ElevatedButton(
          key: const Key('deadline-complete-save'),
          onPressed: () =>
              Navigator.pop(context, _controller.text.trim()),
          child: Text(l10n?.deadlineCompletedNoteSave ?? 'Save'),
        ),
      ],
    );
  }
}
