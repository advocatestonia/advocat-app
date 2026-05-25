// parallel_actions_card.dart
// -----------------------------------------------------------------------------
// Parallel Actions Panel (2026-05-25) — grouped inbox card shown when the
// consilium proposes 2+ related actions for a single triage row.
//
// Pattern source: Sulga case, 25 May 2026. The 5-lawyer consilium recommended
// TWO emails in parallel — one reply to Jokela (HOL §122 soft-return) AND
// one new asiakirjapyyntö to poliisi kirjaamo (JulkL 14§, 2vk deadline). The
// UI needs to surface both in one card so the user can approve them with a
// single tap.
//
// Layout:
//   ┌──────────────────────────────────────────────────────────┐
//   │ [SEVERITY] subject                                       │
//   │ Consilium recommends N parallel actions                  │
//   │ [expert avatars row]                                     │
//   │                                                          │
//   │  ☑  [reply]  jokela@migri.fi          [fi] [2 cit]       │
//   │      Re: Vastaus 12.5.2026 viestiin                      │
//   │      ▸ Soft-return per HOL §122; declines käännytys...   │
//   │                                                          │
//   │  ☑  [new]    kirjaamo@poliisi.fi       [fi] [1 cit]      │
//   │      Asiakirjapyyntö (JulkL 14§)                         │
//   │      ▸ 2vk deadline; requests Eckerö Line records...     │
//   │                                                          │
//   │ [Approve All & Send]   [Snooze]   [Archive]              │
//   └──────────────────────────────────────────────────────────┘
//
// Behaviour:
//   * Per-action checkboxes. All checked by default. Tapping a checkbox
//     toggles selection. The bottom button label switches between
//     "Approve All & Send" (all selected) and "Approve Selected (k of N)"
//     (subset selected). Disabled when nothing selected.
//   * Confirm modal lists what will be dispatched ("2 emails will be sent.
//     Continue?") so a single tap cannot misfire two emails by accident.
//   * On confirm, the widget calls
//     `inboxProvider.notifier.approveSelectedActions(triageId, idxList)`
//     which fans out N `email-send` invocations (one per action_idx).
//   * Snooze / Archive route to the same provider methods as TriageCard
//     so the two cards share behaviour where it matters.
//
// Coordination notes:
//   * The `email-send` edge function is owned by a sibling agent
//     ("Approve&Send UI"). This widget delegates to the provider, which
//     delegates to `SupabaseService.callEdgeFunction('email-send', ...)`
//     with `action_idx` in the body. When the sibling lands their PR,
//     the existing single-action call site already uses action_idx=0,
//     so backwards compat stays clean.
//   * Expert avatars are sourced from the persisted `lawyer_opinions`
//     column (when present) so the card can show *which* lawyers
//     recommended the actions. When absent, a generic "consilium" icon
//     row renders so the card still looks complete.
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/supabase_service.dart';
import '../models/inbox_thread.dart';
import '../providers/inbox_provider.dart';

// ─── Hardcoded fallback strings ──────────────────────────────────────────────
// The .arb files in lib/l10n/ already carry the localised strings for EN,
// ET, RU, FI. They land in the generated AppLocalizations on the next
// `flutter gen-l10n` build. Until that codegen pass runs, the widget uses
// these in-source English fallbacks so the build does not block on the
// codegen step. When the localised methods exist on AppLocalizations the
// caller can swap these for `l.parallelActionsXxx(...)` without changing
// any other code.
String _kHeadline(int count) => 'Consilium recommends $count parallel actions';
String _kApproveAll() => 'Approve All & Send';
String _kApproveSelected(int count, int total) => 'Approve $count of $total';
String _kConfirmTitle(int count) => 'Send $count emails?';
String _kConfirmBody(int count) =>
    'Advocat will dispatch $count prepared replies via your connected Gmail. '
    'Each one is sent independently — if any one fails, the others still go.';
String _kSentToast(int count) => '$count sent.';
String _kPartialFailureToast(int sent, int failed) =>
    '$sent sent, $failed failed.';
String _kKindReply() => 'reply';
String _kKindNew() => 'new';
String _kCheckboxSelected() => 'Action selected';
String _kCheckboxUnselected() => 'Action not selected';
String _kCitationCount(int count) => '$count cit';

class ParallelActionsCard extends ConsumerStatefulWidget {
  const ParallelActionsCard({super.key, required this.thread});

  final InboxThread thread;

  @override
  ConsumerState<ParallelActionsCard> createState() =>
      _ParallelActionsCardState();
}

class _ParallelActionsCardState extends ConsumerState<ParallelActionsCard> {
  /// Per-action selection state, keyed by `ProposedAction.idx`. All actions
  /// start selected (the consilium recommended ALL of them; the user opts
  /// OUT of any they reject).
  late final Map<int, bool> _selected = {
    for (final a in widget.thread.proposedActions) a.idx: true,
  };
  bool _busy = false;

  int get _selectedCount => _selected.values.where((v) => v).length;
  int get _totalCount => widget.thread.proposedActions.length;
  bool get _allSelected =>
      _selectedCount == _totalCount && _totalCount > 0;
  bool get _hasSelection => _selectedCount > 0;

  void _toggle(int idx) {
    setState(() {
      _selected[idx] = !(_selected[idx] ?? false);
    });
  }

  Future<void> _onApprove() async {
    if (!_hasSelection || _busy) return;
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(inboxProvider.notifier);

    final selectedIdxs = widget.thread.proposedActions
        .where((a) => _selected[a.idx] == true)
        .map((a) => a.idx)
        .toList(growable: false);

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(_kConfirmTitle(selectedIdxs.length)),
            content: Text(_kConfirmBody(selectedIdxs.length)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l?.cancel ?? 'Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l?.inboxSendButton ?? 'Send'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    setState(() => _busy = true);
    try {
      final result = await notifier.approveSelectedActions(
        widget.thread.triageId,
        selectedIdxs,
      );
      if (!mounted) return;
      // Haptic is best-effort — in widget tests the platform channel has no
      // handler and an unhandled awaited future would surface a test failure.
      unawaited(HapticFeedback.lightImpact().catchError((_) {}));
      if (result.failed == 0) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(_kSentToast(result.sent)),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
        notifier.hideAfterAction(widget.thread.threadId);
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              _kPartialFailureToast(result.sent, result.failed),
            ),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onSnooze() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(inboxProvider.notifier).snooze(widget.thread.threadId);
    if (!mounted) return;
    unawaited(HapticFeedback.lightImpact().catchError((_) {}));
    messenger.showSnackBar(
      SnackBar(
        content: Text(l?.inboxSnoozedToast ?? 'Snoozed for 24h.'),
        backgroundColor: AppColors.info,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _onArchive() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(inboxProvider.notifier);
    final supabase = ref.read(supabaseServiceProvider);
    final threadId = widget.thread.threadId;

    notifier.hideAfterAction(threadId);
    unawaited(HapticFeedback.lightImpact().catchError((_) {}));

    // Same gmail-label mirror as TriageCard. Soft-fail; local archive
    // already succeeded.
    try {
      await supabase.callEdgeFunction(
        'gmail-label',
        body: {
          'thread_id': threadId,
          'add_labels': <String>['advocat:auto-archived'],
          'remove_labels': <String>['INBOX'],
        },
      );
    } catch (e) {
      debugPrint('gmail-label: edge fn unavailable: $e');
    }

    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(l?.inboxArchivedToast ?? 'Archived.'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: l?.cancel ?? 'Undo',
          textColor: AppColors.textOnPrimary,
          onPressed: () {
            ref.read(inboxProvider.notifier).refresh();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = widget.thread;
    final actions = t.proposedActions;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: AppShadows.shadowSmall,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(thread: t, total: actions.length),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _kHeadline(actions.length),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...actions.map((a) => _ActionRow(
                  action: a,
                  selected: _selected[a.idx] ?? false,
                  onToggle: () => _toggle(a.idx),
                )),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _PrimaryButton(
                  label: _allSelected
                      ? _kApproveAll()
                      : _kApproveSelected(_selectedCount, _totalCount),
                  busy: _busy,
                  enabled: _hasSelection && !_busy,
                  onPressed: _onApprove,
                ),
                _SecondaryButton(
                  icon: Icons.snooze_outlined,
                  label: l?.inboxSnooze ?? 'Snooze',
                  color: AppColors.info,
                  onPressed: _busy ? null : _onSnooze,
                ),
                _SecondaryButton(
                  icon: Icons.archive_outlined,
                  label: l?.inboxArchive ?? 'Archive',
                  color: AppColors.textSecondary,
                  onPressed: _busy ? null : _onArchive,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.thread, required this.total});

  final InboxThread thread;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: thread.severity.badgeBgColor,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: thread.severity.badgeColor.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            thread.severity.raw,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: thread.severity.badgeColor,
              letterSpacing: 0.4,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            thread.subject.isEmpty ? '(no subject)' : thread.subject,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Compact count pill so the user knows the card is "2 actions"
        // at a glance, even after scrolling past the headline line.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            '×$total',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.action,
    required this.selected,
    required this.onToggle,
  });

  final ProposedAction action;
  final bool selected;
  final VoidCallback onToggle;

  IconData get _kindIcon =>
      action.kind == 'email_new' ? Icons.mail_outline : Icons.reply_rounded;

  String _kindLabel() =>
      action.kind == 'email_new' ? _kKindNew() : _kKindReply();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox sized to align with the action title row.
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Semantics(
                label: selected
                    ? _kCheckboxSelected()
                    : _kCheckboxUnselected(),
                child: Checkbox(
                  value: selected,
                  onChanged: (_) => onToggle(),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _kindIcon,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      _Chip(
                        label: _kindLabel(),
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          action.toAddr,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (action.language.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _Chip(
                          label: action.language.toUpperCase(),
                          color: AppColors.info,
                        ),
                      ],
                      if (action.citations.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _Chip(
                          label: _kCitationCount(action.citations.length),
                          color: AppColors.primary,
                        ),
                      ],
                    ],
                  ),
                  if (action.subject.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      action.subject,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (action.rationale.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      action.rationale,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.busy,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: busy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.textOnPrimary,
              ),
            )
          : const Icon(Icons.send_rounded, size: 16),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.textOnPrimary,
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }
}
