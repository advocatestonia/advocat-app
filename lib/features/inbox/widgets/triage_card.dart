// triage_card.dart
// -----------------------------------------------------------------------------
// Single email-triage card for the Inbox list (D6).
//
// Layout:
//   ┌──────────────────────────────────────────────────────────┐
//   │ [SEVERITY]  subject                                  ⋯   │
//   │                                                          │
//   │ user_brief — 2-4 sentence Sonnet briefing                │
//   │                                                          │
//   │ [📧 sender_email]                                         │
//   │                                                          │
//   │ [🟢 Approve & send]  [✏ Edit]  [💤 Snooze]  [🗑 Archive] │
//   └──────────────────────────────────────────────────────────┘
//
// Severity → colour mapping comes from inbox_severity.dart (badgeColor +
// badgeBgColor). CRITICAL also gets a subtle pulse animation (per spec
// §D6 "severity colours" list).
//
// Action buttons:
//   - Approve & send  → confirm modal → calls assistant_tools::execute
//                        ('approve_send_draft', {triage_id})
//                        → existing send-email edge fn dispatches
//                        → toast "Sent"
//                        → notifier.hideAfterAction(threadId)
//   - Edit            → opens existing draft_viewer_screen.dart, passing
//                        the persisted draft body so the user can tweak
//                        before send (still routed via send-email).
//   - Snooze          → notifier.snooze(threadId) — optimistic hide.
//   - Archive         → mark email_threads.triage_status='archived' via
//                        the assistant tool (Gmail label mirror is a
//                        TODO follow-up — MVP hides locally and stamps
//                        the row).
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/supabase_service.dart';
import '../models/inbox_severity.dart';
import '../models/inbox_thread.dart' show InboxDeadline, InboxThread;
import '../providers/inbox_provider.dart';

class TriageCard extends ConsumerStatefulWidget {
  const TriageCard({super.key, required this.thread});

  final InboxThread thread;

  @override
  ConsumerState<TriageCard> createState() => _TriageCardState();
}

class _TriageCardState extends ConsumerState<TriageCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseAnim;

  @override
  void initState() {
    super.initState();
    if (widget.thread.severity.pulses) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      )..repeat(reverse: true);
      _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────

  Future<void> _onApproveSend() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(inboxProvider.notifier);

    // Confirm modal — same pattern as other approval flows in the app.
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l?.inboxConfirmSendTitle ?? 'Send the prepared reply?'),
            content: Text(
              l?.inboxConfirmSendBody ??
                  'Advocat will dispatch the AI-prepared reply via your '
                      'connected Gmail. You can still review the body in '
                      'the next screen.',
            ),
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

    // D6 — call email-send via the inbox provider. Provider returns a
    // structured result so we can surface a retry banner on failure
    // without re-implementing the edge-function plumbing here.
    final res = await notifier.approveAndSend(widget.thread.triageId);
    if (!mounted) return;

    if (res.success) {
      // Fire-and-forget haptic — awaiting the platform channel hangs in
      // widget tests where no handler is registered (mirrors archive).
      unawaited(HapticFeedback.lightImpact().catchError((_) {}));
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            res.idempotent
                ? (l?.inboxAlreadySentToast ?? 'Already sent.')
                : (l?.inboxSentToast ?? 'Sent.'),
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
      notifier.hideAfterAction(widget.thread.threadId);
    } else {
      // Error path — show a snackbar with a Retry action so the user
      // doesn't have to scroll back to the card on a transient failure
      // (e.g. Gmail OAuth re-auth, network flap).
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            res.errorMessage ??
                (l?.inboxSendErrorToast ?? 'Could not send the reply.'),
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: l?.retry ?? 'Retry',
            textColor: AppColors.textOnPrimary,
            onPressed: _onApproveSend,
          ),
        ),
      );
    }
  }

  void _onEdit() {
    // Inbox-scoped wrapper around the existing DraftViewerScreen — see
    // inbox_draft_edit_screen.dart. Path is /inbox/draft/:triageId; the
    // wrapper fetches the persisted draft via get_thread_triage and
    // forwards it to the existing draft viewer for inline edits.
    final uri = Uri(
      path: '/inbox/draft/${widget.thread.triageId}',
      queryParameters: <String, String>{
        'threadId': widget.thread.threadId,
      },
    );
    context.push(uri.toString());
  }

  Future<void> _onSnooze() async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(inboxProvider.notifier).snooze(widget.thread.threadId);
    if (!mounted) return;
    await HapticFeedback.lightImpact();
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

    // Optimistic local hide first — UX must not block on Gmail.
    notifier.hideAfterAction(threadId);
    // Fire-and-forget the haptic — awaiting the platform channel hangs
    // in widget tests where no handler is registered.
    unawaited(HapticFeedback.lightImpact().catchError((_) {}));

    // Carry-over Task 4 — mirror to Gmail by adding the
    // `advocat:auto-archived` label and removing INBOX. Edge fn returns
    // 200 with `{ok:false, error_code}` on Gmail-side failure — the
    // local archive already succeeded; the 5-second snackbar exposes
    // Undo for rollback in either case.
    await _mirrorArchiveToGmail(supabase, threadId);

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

  /// Carry-over Task 4 — mirror local archive to Gmail labels.
  /// Soft-fail: any error logged via debugPrint; local archive stays.
  Future<void> _mirrorArchiveToGmail(
    SupabaseService supabase,
    String threadId,
  ) async {
    try {
      final res = await supabase.callEdgeFunction(
        'gmail-label',
        body: {
          'thread_id': threadId,
          'add_labels': <String>['advocat:auto-archived'],
          'remove_labels': <String>['INBOX'],
        },
      );
      if (res != null && res['ok'] == false) {
        debugPrint(
          'gmail-label: soft-fail '
          '(error_code=${res['error_code']}, detail=${res['detail']})',
        );
      }
    } catch (e) {
      debugPrint('gmail-label: edge fn unavailable: $e');
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = widget.thread;
    final sev = t.severity;

    Widget badge = _SeverityBadge(severity: sev);
    if (_pulseAnim != null) {
      final anim = _pulseAnim!;
      badge = AnimatedBuilder(
        animation: anim,
        builder: (_, child) => Opacity(opacity: anim.value, child: child),
        child: badge,
      );
    }

    final showDraftActions = t.hasDraft;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.shadowSmall,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header — severity badge + subject.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                badge,
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    t.subject.isEmpty ? '(no subject)' : t.subject,
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
              ],
            ),
            if (t.userBrief.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                t.userBrief,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
            if (t.senderEmail.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.email_outlined,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      t.senderEmail,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            // Deadline chip — surfaced from email_triage_results.deadlines
            // (smallest delta_days wins). Pkg 9 shipped a deadline_card not
            // a chip, so we render a small inline chip here. If a chip
            // primitive lands later in lib/widgets/deadlines/ we can swap
            // this block for it without touching the model.
            if (t.topDeadline != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _DeadlineChip(deadline: t.topDeadline!),
            ],
            const SizedBox(height: AppSpacing.md),
            // Action row — wrap so the four buttons reflow gracefully on
            // narrow phones / RTL locales.
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (showDraftActions) ...[
                  _ActionButton(
                    icon: Icons.send_rounded,
                    label: l?.inboxApproveSend ?? 'Approve & send',
                    color: AppColors.success,
                    onPressed: _onApproveSend,
                    primary: true,
                  ),
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    label: l?.inboxEditDraft ?? 'Edit',
                    color: AppColors.primary,
                    onPressed: _onEdit,
                  ),
                ],
                _ActionButton(
                  icon: Icons.snooze_outlined,
                  label: l?.inboxSnooze ?? 'Snooze',
                  color: AppColors.info,
                  onPressed: _onSnooze,
                ),
                _ActionButton(
                  icon: Icons.archive_outlined,
                  label: l?.inboxArchive ?? 'Archive',
                  color: AppColors.textSecondary,
                  onPressed: _onArchive,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.severity});

  final InboxSeverity severity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: severity.badgeBgColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: severity.badgeColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        severity.raw,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: severity.badgeColor,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Tiny inline chip rendering the topmost deadline from
/// `email_triage_results.deadlines`. Colour escalates as the deadline
/// approaches: overdue / ≤2d → error, ≤7d → warning, ≤30d → info,
/// otherwise tertiary text.
class _DeadlineChip extends StatelessWidget {
  const _DeadlineChip({required this.deadline});

  final InboxDeadline deadline;

  Color _bandColor() {
    final d = deadline.deltaDays;
    if (d == null) return AppColors.textTertiary;
    if (d <= 2) return AppColors.error;
    if (d <= 7) return AppColors.warning;
    if (d <= 30) return AppColors.info;
    return AppColors.textSecondary;
  }

  String _label(AppLocalizations? l) {
    final d = deadline.deltaDays;
    final desc = deadline.description.trim();
    String tail;
    if (d == null) {
      tail = deadline.isoDate.isEmpty ? '' : deadline.isoDate;
    } else if (d < 0) {
      tail = l?.inboxDeadlineOverdue(-d) ?? 'overdue ${-d}d';
    } else if (d == 0) {
      tail = l?.inboxDeadlineToday ?? 'today';
    } else if (d == 1) {
      tail = l?.inboxDeadlineTomorrow ?? 'tomorrow';
    } else {
      tail = l?.inboxDeadlineInDays(d) ?? 'in ${d}d';
    }
    if (desc.isEmpty) return tail.isEmpty ? '—' : tail;
    if (tail.isEmpty) return desc;
    return '$desc · $tail';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color = _bandColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _label(l),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: color,
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
