import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../config/theme.dart';
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

  // ── Color coding by case type ────────────────────────────────────────────

  Color _typeAccentColor(CaseType type) {
    return switch (type) {
      CaseType.deportation => AppColors.error,
      CaseType.asylum => AppColors.info,
      CaseType.residencePermit => AppColors.accent,
      CaseType.familyReunification => AppColors.warning,
      CaseType.citizenship => AppColors.success,
      CaseType.workPermit => AppColors.primaryLight,
      CaseType.laborDispute => const Color(0xFF8B5CF6),
      CaseType.tenantRights => const Color(0xFF10B981),
      CaseType.debtCollection => const Color(0xFFF59E0B),
      CaseType.discrimination => const Color(0xFFEC4899),
      CaseType.policeMisconduct => const Color(0xFF6366F1),
      CaseType.socialBenefits => const Color(0xFF14B8A6),
      CaseType.other => AppColors.textTertiary,
    };
  }

  Color _statusColor(CaseStatus status) {
    return switch (status) {
      CaseStatus.active => AppColors.accent,
      CaseStatus.pendingDecision => AppColors.warning,
      CaseStatus.appealFiled => AppColors.info,
      CaseStatus.inCourt => AppColors.primary,
      CaseStatus.resolved => AppColors.success,
      CaseStatus.closed => AppColors.textTertiary,
    };
  }

  String _statusLabel(CaseStatus status) {
    return switch (status) {
      CaseStatus.active => 'Active',
      CaseStatus.pendingDecision => 'Pending Decision',
      CaseStatus.appealFiled => 'Appeal Filed',
      CaseStatus.inCourt => 'In Court',
      CaseStatus.resolved => 'Resolved',
      CaseStatus.closed => 'Closed',
    };
  }

  String _typeLabel(CaseType type) {
    return switch (type) {
      CaseType.deportation => 'Deportation',
      CaseType.asylum => 'Asylum',
      CaseType.residencePermit => 'Residence Permit',
      CaseType.familyReunification => 'Family Reunion',
      CaseType.citizenship => 'Citizenship',
      CaseType.workPermit => 'Work Permit',
      CaseType.laborDispute => 'Labor Dispute',
      CaseType.tenantRights => 'Tenant Rights',
      CaseType.debtCollection => 'Debt Collection',
      CaseType.discrimination => 'Discrimination',
      CaseType.policeMisconduct => 'Police Misconduct',
      CaseType.socialBenefits => 'Social Benefits',
      CaseType.other => 'Other',
    };
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _typeAccentColor(legalCase.type);
    final statusColor = _statusColor(legalCase.status);
    final lastActivity = legalCase.updatedAt ?? legalCase.createdAt;

    final card = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // ── Left color bar ─────────────────────────────────────────
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: accentColor,
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
                                  _statusLabel(legalCase.status),
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
                            label: _typeLabel(legalCase.type),
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
      builder: (context) => AlertDialog(
        title: const Text('Delete Case'),
        content: Text(
          'Are you sure you want to delete "${legalCase.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onDelete?.call();
              Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
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
