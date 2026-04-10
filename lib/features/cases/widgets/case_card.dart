import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/case_model.dart';

// ---------------------------------------------------------------------------
// Case Card — used across home, cases list, and other screens
// ---------------------------------------------------------------------------

class CaseCard extends StatelessWidget {
  const CaseCard({
    super.key,
    required this.legalCase,
    required this.onTap,
    this.onArchive,
    this.onDelete,
  });

  final LegalCase legalCase;
  final VoidCallback onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  // ── Color coding by case status ──────────────────────────────────────────

  Color _statusColor(CaseStatus status) {
    return switch (status) {
      CaseStatus.active => const Color(0xFF0D9488),
      CaseStatus.pendingDecision => const Color(0xFFD69E2E),
      CaseStatus.appealFiled => const Color(0xFF0D9488),
      CaseStatus.inCourt => const Color(0xFFE53E3E),
      CaseStatus.resolved => const Color(0xFF38A169),
      CaseStatus.closed => AppColors.textTertiary,
    };
  }

  // TODO: Add l10n keys for case status labels (caseStatusActive, caseStatusPending, etc.) to ARB files
  String _statusLabel(CaseStatus status, BuildContext context) {
    return switch (status) {
      CaseStatus.active => 'Active',
      CaseStatus.pendingDecision => 'Pending Decision',
      CaseStatus.appealFiled => 'Appeal Filed',
      CaseStatus.inCourt => 'In Court',
      CaseStatus.resolved => 'Resolved',
      CaseStatus.closed => 'Closed',
    };
  }

  // TODO: Add l10n keys for case type labels to ARB files (reuse from case_create_screen)
  String _typeLabel(CaseType type, BuildContext context) {
    final l = AppLocalizations.of(context);
    return switch (type) {
      CaseType.deportation => l?.deportation ?? 'Deportation',
      CaseType.asylum => l?.asylum ?? 'Asylum',
      CaseType.residencePermit => l?.residencePermit ?? 'Residence Permit',
      CaseType.familyReunification => l?.familyReunification ?? 'Family Reunion',
      CaseType.citizenship => l?.citizenship ?? 'Citizenship',
      CaseType.workPermit => l?.workPermit ?? 'Work Permit',
      CaseType.laborDispute => l?.laborDispute ?? 'Labor Dispute',
      CaseType.tenantRights => l?.tenantRights ?? 'Tenant Rights',
      CaseType.debtCollection => l?.debtCollection ?? 'Debt Collection',
      CaseType.discrimination => l?.discrimination ?? 'Discrimination',
      CaseType.policeMisconduct => l?.policeMisconduct ?? 'Police Misconduct',
      CaseType.socialBenefits => l?.socialBenefits ?? 'Social Benefits',
      CaseType.domesticViolence => l?.domesticViolence ?? 'Domestic Violence',
      CaseType.consumerProtection => l?.consumerProtection ?? 'Consumer Protection',
      CaseType.other => l?.other ?? 'Other',
    };
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(legalCase.status);
    final lastActivity = legalCase.updatedAt ?? legalCase.createdAt;

    final card = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        label: 'Case: ${legalCase.title}, status: ${_statusLabel(legalCase.status, context)}',
        button: true,
        child: Material(
        color: Colors.transparent,
        child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // ── Left status color bar ──────────────────────────────────
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.md),
                    bottomLeft: Radius.circular(AppRadius.md),
                  ),
                ),
              ),

              // ── Card content ───────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              legalCase.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          // Status indicator
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _statusLabel(legalCase.status, context),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Chips row: type + jurisdiction
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          _Chip(
                            label: _typeLabel(legalCase.type, context),
                            icon: Icons.category_outlined,
                          ),
                          if (legalCase.nationality != null)
                            _Chip(
                              label: legalCase.nationality!,
                              icon: Icons.flag_outlined,
                            ),
                          if (legalCase.migriReferenceNumber != null)
                            _Chip(
                              label: legalCase.migriReferenceNumber!,
                              icon: Icons.tag,
                            ),
                        ],
                      ),

                      // Appeal deadline warning
                      if (legalCase.appealDeadline != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _AppealDeadlineRow(
                            deadline: legalCase.appealDeadline!),
                      ],

                      const SizedBox(height: AppSpacing.sm),

                      // Bottom row: doc count + last activity
                      Row(
                        children: [
                          if (legalCase.documentCount > 0) ...[
                            const Icon(
                              Icons.description_outlined,
                              size: 14,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${legalCase.documentCount} docs',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                          ],
                          Expanded(
                            child: Text(
                              'Last activity: ${timeago.format(lastActivity)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.textTertiary,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
      ),
    );

    // ── Swipe actions ──────────────────────────────────────────────────────
    if (onArchive == null && onDelete == null) return card;

    return Dismissible(
      key: ValueKey(legalCase.id),
      background: const _SwipeBackground(
        color: AppColors.warning,
        icon: Icons.archive_outlined,
        label: 'Archive',
        alignment: Alignment.centerLeft,
      ),
      secondaryBackground: const _SwipeBackground(
        color: AppColors.error,
        icon: Icons.delete_outline,
        label: 'Delete',
        alignment: Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onArchive?.call();
          return false; // Don't actually dismiss; let the callback handle it
        }
        if (direction == DismissDirection.endToStart) {
          return await _confirmDelete(context);
        }
        return false;
      },
      child: card,
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
        title: Text(l10n?.deleteCase ?? 'Delete Case'),
        content: Text(
          l10n?.deleteCaseConfirm(legalCase.title) ?? 'Are you sure you want to delete "${legalCase.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              onDelete?.call();
              Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n?.delete ?? 'Delete'),
          ),
        ],
      );
      },
    );
    return confirmed ?? false;
  }
}

// ---------------------------------------------------------------------------
// Internal widgets
// ---------------------------------------------------------------------------

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppealDeadlineRow extends StatelessWidget {
  const _AppealDeadlineRow({required this.deadline});

  final DateTime deadline;

  @override
  Widget build(BuildContext context) {
    final isOverdue = deadline.isBefore(DateTime.now());
    final color = isOverdue ? AppColors.error : AppColors.warning;

    return Row(
      children: [
        Icon(Icons.schedule, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          'Appeal deadline: ${timeago.format(deadline)}',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.color,
    required this.icon,
    required this.label,
    required this.alignment,
  });

  final Color color;
  final IconData icon;
  final String label;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
