// deadline_countdown_card.dart — top-of-screen "X days until …" card.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../models/case_file.dart';

/// Pure-string helper extracted for unit-testing the countdown logic.
String formatDeadlineCountdown({
  required DateTime today,
  required CaseDeadline deadline,
  required String oneDayLabel,
  required String daysLabel,
  required String overdueLabel,
  required String dueTodayLabel,
}) {
  final days = deadline.daysFrom(today);
  if (days < 0) return '$overdueLabel ${-days} $daysLabel';
  if (days == 0) return dueTodayLabel;
  if (days == 1) return oneDayLabel;
  return '$days $daysLabel';
}

class DeadlineCountdownCard extends StatelessWidget {
  const DeadlineCountdownCard({
    super.key,
    required this.deadline,
    required this.today,
    this.onTap,
  });

  final CaseDeadline deadline;
  final DateTime today;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final urgent = deadline.isUrgentAt(today);
    final overdue = deadline.daysFrom(today) < 0;
    final emphasised = urgent || overdue;

    final accent = overdue
        ? AppColors.error
        : urgent
            ? AppColors.error
            : AppColors.accent;

    final label = formatDeadlineCountdown(
      today: today,
      deadline: deadline,
      oneDayLabel: '1 day remaining',
      daysLabel: 'days remaining',
      overdueLabel: 'Overdue by',
      dueTodayLabel: 'Due today',
    );

    return Semantics(
      label: '${deadline.title} — $label',
      button: onTap != null,
      child: Material(
        color: accent.withValues(alpha: emphasised ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    overdue ? Icons.warning_amber_rounded : Icons.schedule,
                    color: accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        deadline.title,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (deadline.law != null && deadline.law!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          deadline.law!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.textTertiary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
