// ---------------------------------------------------------------------------
// Checklist Summary Card — compact "Action Plan" tile for the case-detail
// screen. Shows a progress bar + "X of Y steps done" and deep-links to the
// full CaseChecklistScreen. Renders nothing when no template matches the
// case type (so it never shows an empty card).
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/checklist_provider.dart';

class ChecklistSummaryCard extends ConsumerWidget {
  const ChecklistSummaryCard({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(caseChecklistProvider(caseId));

    // Hide entirely while loading, on error, or when there is no roadmap
    // for this case type — the case-detail page should not show an empty
    // or spinning card here.
    final checklist = async.valueOrNull;
    if (checklist == null || checklist.isEmpty) {
      return const SizedBox.shrink();
    }

    final allDone = checklist.allDone;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => context.push('/cases/$caseId/checklist'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    allDone ? Icons.task_alt : Icons.checklist,
                    size: 20,
                    color: allDone ? AppColors.success : AppColors.accent,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.checklistActionPlan,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          l10n.checklistActionPlanSubtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: AppColors.textTertiary),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: LinearProgressIndicator(
                  value: checklist.progress,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    allDone ? AppColors.success : AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                allDone
                    ? l10n.checklistAllDone
                    : l10n.checklistProgress(
                        checklist.completed, checklist.total),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
