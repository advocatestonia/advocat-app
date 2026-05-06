// =====================================================================
// DeadlineCard — single-deadline rendering primitive (Pkg 9).
//
// Used by:
//   * DeadlineRadarWidget (compact mode, no actions)
//   * CaseDeadlinesScreen (full mode with action menu)
//
// Color coding (architect §7):
//   * critical (≤1d) → red 700 background, white text
//   * high (≤3d)     → red 500
//   * medium (≤7d)   → amber 700
//   * info (>7d)     → theme surfaceContainerHigh
//
// Reuses existing AppColors / AppRadius tokens — no new constants.
// =====================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../models/case_deadline.dart';

/// Visual density for the card.
enum DeadlineCardMode {
  /// Compact: title + delta-days chip. Used by the radar widget.
  compact,

  /// Full: title + statute + days + action menu. Used by the per-case
  /// list and the deadline detail bottom sheet.
  full,
}

class DeadlineCard extends StatelessWidget {
  const DeadlineCard({
    super.key,
    required this.deadline,
    this.mode = DeadlineCardMode.full,
    this.onTap,
    this.onMarkComplete,
    this.onSnooze,
    this.onEdit,
    this.onArchive,
    this.now,
  });

  final CaseDeadline deadline;
  final DeadlineCardMode mode;
  final VoidCallback? onTap;
  final VoidCallback? onMarkComplete;
  final VoidCallback? onSnooze;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;

  /// Test-only override of "now" for deterministic urgency math. Falls
  /// back to `DateTime.now()`.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final urgency = deadline.urgency(now: now);
    final days = deadline.daysUntil(now: now);
    final colors = _UrgencyColors.from(context, urgency, deadline.isOpen);
    final whenLabel = _whenLabel(l10n, days);

    return Material(
      color: colors.background,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Days chip
              _DeltaDaysChip(
                days: days,
                urgency: urgency,
                isOpen: deadline.isOpen,
                colors: colors,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (deadline.caseTitle != null &&
                        deadline.caseTitle!.isNotEmpty)
                      Text(
                        deadline.caseTitle!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: colors.muted,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      deadline.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.text,
                        decoration:
                            deadline.status == CaseDeadlineStatus.completed
                                ? TextDecoration.lineThrough
                                : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      whenLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (mode == DeadlineCardMode.full) ...[
                      if (deadline.statuteBasis != null &&
                          deadline.statuteBasis!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            deadline.statuteBasis!,
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.muted,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      if (deadline.holidayShifted &&
                          deadline.holidayShiftNote != null)
                        _HolidayShiftBadge(
                          note: deadline.holidayShiftNote!,
                          color: colors.muted,
                        ),
                    ],
                  ],
                ),
              ),
              if (mode == DeadlineCardMode.full && deadline.isOpen)
                _DeadlineActions(
                  l10n: l10n,
                  onMarkComplete: onMarkComplete,
                  onSnooze: onSnooze,
                  onEdit: onEdit,
                  onArchive: onArchive,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Localized "in 3 days" / "tomorrow" / "today" / "2 days overdue".
  String _whenLabel(AppLocalizations? l10n, int days) {
    if (l10n == null) {
      if (days < 0) return '${-days} days overdue';
      if (days == 0) return 'today';
      if (days == 1) return 'tomorrow';
      return 'in $days days';
    }
    if (days < 0) return l10n.deadlineCardOverdue(-days);
    if (days == 0) return l10n.deadlineCardToday;
    if (days == 1) return l10n.deadlineCardTomorrow;
    return l10n.deadlineCardDaysLeft(days);
  }
}

class _DeltaDaysChip extends StatelessWidget {
  const _DeltaDaysChip({
    required this.days,
    required this.urgency,
    required this.isOpen,
    required this.colors,
  });

  final int days;
  final CaseDeadlineUrgency urgency;
  final bool isOpen;
  final _UrgencyColors colors;

  @override
  Widget build(BuildContext context) {
    final isOverdue = days < 0;
    final display = isOverdue ? '${-days}' : '$days';

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: colors.chipBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Center(
        child: !isOpen
            ? Icon(Icons.check, color: colors.chipForeground, size: 24)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    display,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: colors.chipForeground,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isOverdue ? 'late' : 'days',
                    style: TextStyle(
                      fontSize: 9,
                      color: colors.chipForeground,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _HolidayShiftBadge extends StatelessWidget {
  const _HolidayShiftBadge({required this.note, required this.color});
  final String note;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Tooltip(
        message: note,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_calls, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              note,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _DeadlineActions extends StatelessWidget {
  const _DeadlineActions({
    required this.l10n,
    this.onMarkComplete,
    this.onSnooze,
    this.onEdit,
    this.onArchive,
  });

  final AppLocalizations? l10n;
  final VoidCallback? onMarkComplete;
  final VoidCallback? onSnooze;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      key: const Key('deadline-card-menu'),
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'complete':
            onMarkComplete?.call();
            break;
          case 'snooze':
            onSnooze?.call();
            break;
          case 'edit':
            onEdit?.call();
            break;
          case 'archive':
            onArchive?.call();
            break;
        }
      },
      itemBuilder: (_) => [
        if (onMarkComplete != null)
          PopupMenuItem(
            value: 'complete',
            child: Text(l10n?.deadlineCardMarkComplete ?? 'Mark complete'),
          ),
        if (onSnooze != null)
          PopupMenuItem(
            value: 'snooze',
            child: Text(l10n?.deadlineCardSnooze ?? 'Snooze'),
          ),
        if (onEdit != null)
          PopupMenuItem(
            value: 'edit',
            child: Text(l10n?.deadlineCardEdit ?? 'Edit'),
          ),
        if (onArchive != null)
          PopupMenuItem(
            value: 'archive',
            child: Text(l10n?.deadlineCardDelete ?? 'Archive'),
          ),
      ],
    );
  }
}

/// Resolved color tokens for one card. Centralized so the radar widget
/// and the per-case list look identical.
class _UrgencyColors {
  const _UrgencyColors({
    required this.background,
    required this.text,
    required this.muted,
    required this.chipBackground,
    required this.chipForeground,
  });

  final Color background;
  final Color text;
  final Color muted;
  final Color chipBackground;
  final Color chipForeground;

  factory _UrgencyColors.from(
    BuildContext context,
    CaseDeadlineUrgency urgency,
    bool isOpen,
  ) {
    final scheme = Theme.of(context).colorScheme;
    if (!isOpen) {
      return _UrgencyColors(
        background: scheme.surfaceContainerHigh,
        text: AppColors.textTertiary,
        muted: AppColors.textTertiary,
        chipBackground: AppColors.success.withValues(alpha: 0.12),
        chipForeground: AppColors.success,
      );
    }
    switch (urgency) {
      case CaseDeadlineUrgency.critical:
        return const _UrgencyColors(
          background: Color(0xFFFFEBEE),
          text: AppColors.textPrimary,
          muted: AppColors.error,
          chipBackground: AppColors.error,
          chipForeground: Colors.white,
        );
      case CaseDeadlineUrgency.high:
        return _UrgencyColors(
          background: AppColors.error.withValues(alpha: 0.08),
          text: AppColors.textPrimary,
          muted: AppColors.error,
          chipBackground: AppColors.error.withValues(alpha: 0.18),
          chipForeground: AppColors.error,
        );
      case CaseDeadlineUrgency.medium:
        return _UrgencyColors(
          background: AppColors.warning.withValues(alpha: 0.08),
          text: AppColors.textPrimary,
          muted: AppColors.warning,
          chipBackground: AppColors.warning.withValues(alpha: 0.18),
          chipForeground: AppColors.warning,
        );
      case CaseDeadlineUrgency.info:
        return _UrgencyColors(
          background: scheme.surfaceContainerHigh,
          text: AppColors.textPrimary,
          muted: AppColors.textSecondary,
          chipBackground: AppColors.textSecondary.withValues(alpha: 0.12),
          chipForeground: AppColors.textSecondary,
        );
    }
  }
}

/// Shared helper for "today by 16:15" — exported so tests can assert
/// the format without re-implementing it.
String formatDeadlineExactWhen(DateTime deadlineAt) {
  return DateFormat('HH:mm').format(deadlineAt.toLocal());
}
