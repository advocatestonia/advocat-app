import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/assistant_tools.dart';
import '../../../shared/safe_launch.dart';
import 'approval_outcome.dart';

// ---------------------------------------------------------------------------
// Main dispatcher widget
// ---------------------------------------------------------------------------

/// Renders a [ToolResult] as a rich card in the chat.
///
/// Dispatches to a specialised card layout based on [ToolResult.cardType].
/// Falls back to a simple text display when no card type is set.
class ToolResultCard extends StatelessWidget {
  const ToolResultCard({
    super.key,
    required this.result,
    this.onAction,
    this.onApprove,
    this.onReject,
    this.onRejectWithReason,
    this.approvalTimeout = ToolApprovalOutcome.defaultTimeout,
  });

  final ToolResult result;

  /// Called when the user taps an action inside the card (e.g. "Open Case").
  final ValueChanged<String>? onAction;

  /// Called when the user approves a pending action.
  final VoidCallback? onApprove;

  /// Legacy reject callback. Kept for backwards compatibility with
  /// existing call-sites; new code should prefer [onRejectWithReason]
  /// for structured outcome routing (BUG#4 fix, 2026-04-29).
  final VoidCallback? onReject;

  /// Structured reject callback. Fires for both explicit Cancel taps
  /// and the [approvalTimeout] auto-reject. Carries a typed
  /// [ToolApprovalOutcome] the chat layer can hand to Claude as a
  /// proper tool_result shape.
  final ValueChanged<ToolApprovalOutcome>? onRejectWithReason;

  /// How long the approval bar waits for user input before auto-firing
  /// a [ToolApprovalKind.timeout] outcome. Defaults to 5 min.
  final Duration approvalTimeout;

  @override
  Widget build(BuildContext context) {
    final Widget card;

    switch (result.cardType) {
      case 'company_report':
        card = _CompanyReportCard(data: result.data ?? {});
      case 'vehicle_report':
        card = _VehicleReportCard(data: result.data ?? {});
      case 'case_summary':
        card = _CaseSummaryCard(
          data: result.data ?? {},
          onAction: onAction,
        );
      case 'deadline_list':
        card = _DeadlineListCard(data: result.data ?? {});
      case 'document_analysis':
        card = _DocumentAnalysisCard(data: result.data ?? {});
      case 'draft_preview':
        card = _DraftPreviewCard(
          data: result.data ?? {},
          displayText: result.displayText,
          onAction: onAction,
        );
      case 'lawyer_list':
        card = _LawyerListCard(data: result.data ?? {});
      case 'email_draft':
        card = _EmailDraftCard(data: result.data ?? {});
      case 'language_changed':
        card = _LanguageChangedCard(data: result.data ?? {});
      case 'translation':
        card = _TranslationCard(data: result.data ?? {});
      default:
        // No specialised card -- return nothing (caller shows displayText)
        return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        card
            .animate()
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.05, end: 0, duration: 300.ms),
        if (result.requiresApproval) ...[
          const SizedBox(height: 8),
          _ApprovalBar(
            message: result.approvalMessage ?? 'Confirm this action?',
            onApprove: onApprove,
            onReject: onReject,
            onRejectWithReason: onRejectWithReason,
            timeout: approvalTimeout,
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

class _CardContainer extends StatelessWidget {
  const _CardContainer({
    required this.child,
    this.borderColor,
    this.headerColor,
    this.headerIcon,
    this.headerTitle,
  });

  final Widget child;
  final Color? borderColor;
  final Color? headerColor;
  final IconData? headerIcon;
  final String? headerTitle;

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? AppColors.border;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (headerTitle != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 2,
              ),
              decoration: BoxDecoration(
                color: (headerColor ?? AppColors.accent).withValues(alpha: 0.08),
                border: Border(
                  bottom: BorderSide(color: border, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  if (headerIcon != null) ...[
                    Icon(headerIcon, size: 18, color: headerColor ?? AppColors.accent),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      headerTitle!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: headerColor ?? AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _riskBadge(String level) {
  final Color color;
  final IconData icon;

  switch (level.toLowerCase()) {
    case 'low':
      color = AppColors.success;
      icon = Icons.check_circle_outline_rounded;
    case 'medium':
      color = AppColors.warning;
      icon = Icons.warning_amber_rounded;
    case 'high':
      color = AppColors.error;
      icon = Icons.dangerous_outlined;
    default:
      color = AppColors.textTertiary;
      icon = Icons.help_outline_rounded;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppRadius.full),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          level.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Company report card
// ---------------------------------------------------------------------------

class _CompanyReportCard extends StatelessWidget {
  const _CompanyReportCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final name = data['company_name'] as String? ?? 'Unknown';
    final status = data['registration_status'] as String? ?? 'unknown';
    final taxId = data['tax_id'] as String? ?? '-';
    final founded = data['founded'] as String? ?? '-';
    final taxDebts = data['tax_debts'] as num? ?? 0;
    final vatRegistered = data['vat_registered'] as bool? ?? false;
    final courtCases = data['court_cases'] as int? ?? 0;
    final riskLevel = data['risk_level'] as String? ?? 'unknown';

    return _CardContainer(
      headerIcon: Icons.business_rounded,
      headerTitle: 'Company Report: $name',
      headerColor: AppColors.info,
      borderColor: AppColors.info.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _riskBadge(riskLevel),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: status == 'active'
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: status == 'active' ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Tax ID', value: taxId),
          _InfoRow(label: 'Founded', value: founded),
          _InfoRow(
            label: 'Tax debts',
            value: 'EUR ${taxDebts.toStringAsFixed(2)}',
            valueColor: taxDebts > 0 ? AppColors.error : AppColors.success,
          ),
          _InfoRow(label: 'VAT registered', value: vatRegistered ? 'Yes' : 'No'),
          _InfoRow(
            label: 'Court cases',
            value: '$courtCases',
            valueColor: courtCases > 0 ? AppColors.warning : AppColors.success,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vehicle report card
// ---------------------------------------------------------------------------

class _VehicleReportCard extends StatelessWidget {
  const _VehicleReportCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final plate = data['plate_number'] as String? ?? '-';
    final make = data['make'] as String? ?? '-';
    final model = data['model'] as String? ?? '-';
    final year = data['year'] ?? '-';
    final color = data['color'] as String? ?? '-';
    final regValid = data['registration_valid'] as bool? ?? false;
    final inspPassed = data['inspection_passed'] as bool? ?? false;
    final stolen = data['stolen'] as bool? ?? false;
    final liens = data['liens'] as bool? ?? false;
    final odometer = data['odometer_km'] as int? ?? 0;

    return _CardContainer(
      headerIcon: Icons.directions_car_rounded,
      headerTitle: 'Vehicle Report: $plate',
      headerColor: AppColors.primary,
      borderColor: AppColors.primary.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statusChip('Registration', regValid),
              const SizedBox(width: 8),
              _statusChip('Inspection', inspPassed),
              const SizedBox(width: 8),
              _statusChip(stolen ? 'Stolen!' : 'Not Stolen', !stolen),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Make / Model', value: '$make $model'),
          _InfoRow(label: 'Year', value: '$year'),
          _InfoRow(label: 'Color', value: color),
          _InfoRow(label: 'Odometer', value: '${_formatNumber(odometer)} km'),
          _InfoRow(
            label: 'Liens',
            value: liens ? 'Yes' : 'None',
            valueColor: liens ? AppColors.error : AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, bool ok) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (ok ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 14,
            color: ok ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ok ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatNumber(int n) {
    final s = n.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}

// ---------------------------------------------------------------------------
// Case summary card
// ---------------------------------------------------------------------------

class _CaseSummaryCard extends StatelessWidget {
  const _CaseSummaryCard({required this.data, this.onAction});
  final Map<String, dynamic> data;
  final ValueChanged<String>? onAction;

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? 'Case';
    final caseId = data['case_id'] as String? ?? '';
    final caseType = data['type'] ?? data['case_type'] ?? '-';
    final status = data['status'] as String? ?? 'active';
    final description = data['description'] as String?;
    final nextDeadline = data['next_deadline'] as String?;

    return _CardContainer(
      headerIcon: Icons.folder_open_rounded,
      headerTitle: title,
      headerColor: AppColors.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$caseType'.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(status),
                  ),
                ),
              ),
            ],
          ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (nextDeadline != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 14, color: AppColors.warning),
                const SizedBox(width: 4),
                Text(
                  'Next: $nextDeadline',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                if (caseId.isNotEmpty) {
                  context.push('/cases/$caseId');
                }
                onAction?.call('open_case');
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(AppLocalizations.of(context)?.openCase ?? 'Open Case'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'closed':
        return AppColors.textTertiary;
      default:
        return AppColors.info;
    }
  }
}

// ---------------------------------------------------------------------------
// Deadline list card
// ---------------------------------------------------------------------------

class _DeadlineListCard extends StatelessWidget {
  const _DeadlineListCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final deadlines = (data['deadlines'] as List<dynamic>?) ?? [];
    if (deadlines.isEmpty) {
      return const _CardContainer(
        headerIcon: Icons.event_available_rounded,
        headerTitle: 'Deadlines',
        headerColor: AppColors.success,
        child: Text(
          'No upcoming deadlines.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    }

    return _CardContainer(
      headerIcon: Icons.schedule_rounded,
      headerTitle: 'Upcoming Deadlines',
      headerColor: AppColors.warning,
      borderColor: AppColors.warning.withValues(alpha: 0.3),
      child: Column(
        children: [
          for (final d in deadlines)
            _DeadlineRow(data: d as Map<String, dynamic>),
        ],
      ),
    );
  }
}

class _DeadlineRow extends StatelessWidget {
  const _DeadlineRow({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? '-';
    final dueDate = data['due_date'] as String? ?? '';
    final daysLeft = data['days_left'] as int? ?? 0;
    final urgency = data['urgency'] as String? ?? 'Upcoming';

    final Color urgencyColor;
    switch (urgency) {
      case 'URGENT':
        urgencyColor = AppColors.error;
      case 'Soon':
        urgencyColor = AppColors.warning;
      default:
        urgencyColor = AppColors.info;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: urgencyColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${dueDate.length >= 10 ? dueDate.substring(0, 10) : dueDate} '
                  '($daysLeft days)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: urgencyColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              urgency,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: urgencyColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Document analysis card
// ---------------------------------------------------------------------------

class _DocumentAnalysisCard extends StatelessWidget {
  const _DocumentAnalysisCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final fileName = data['file_name'] as String? ?? 'Document';
    final issuesCount = data['issues_count'] as int? ?? 0;
    final issues = (data['issues'] as List<dynamic>?) ?? [];
    final legalRefs = (data['legal_references'] as List<dynamic>?) ?? [];

    return _CardContainer(
      headerIcon: Icons.description_rounded,
      headerTitle: 'Analysis: $fileName',
      headerColor: issuesCount > 0 ? AppColors.warning : AppColors.success,
      borderColor: (issuesCount > 0 ? AppColors.warning : AppColors.success)
          .withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Issues count badge
          if (issuesCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '$issuesCount issues found',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ),
          if (issues.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final issue in issues)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4, right: 8),
                      child: Icon(Icons.error_outline, size: 14, color: AppColors.error),
                    ),
                    Expanded(
                      child: Text(
                        '$issue',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (legalRefs.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Legal References:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: legalRefs
                  .map((ref) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          '$ref',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.accent,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Draft preview card
// ---------------------------------------------------------------------------

class _DraftPreviewCard extends StatelessWidget {
  const _DraftPreviewCard({
    required this.data,
    required this.displayText,
    this.onAction,
  });

  final Map<String, dynamic> data;
  final String displayText;
  final ValueChanged<String>? onAction;

  @override
  Widget build(BuildContext context) {
    final draftType = data['draft_type'] as String? ?? 'draft';
    final caseTitle = data['case_title'] as String? ?? '';

    return _CardContainer(
      headerIcon: Icons.edit_document,
      headerTitle: '${draftType.replaceAll('_', ' ').toUpperCase()} Draft',
      headerColor: AppColors.primary,
      borderColor: AppColors.primary.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (caseTitle.isNotEmpty) ...[
            Text(
              'Re: $caseTitle',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Preview of the draft (first 200 chars)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              displayText.length > 300
                  ? '${displayText.substring(0, 300)}...'
                  : displayText,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onAction?.call('view_full_draft'),
                  icon: const Icon(Icons.fullscreen_rounded, size: 16),
                  label: Text(AppLocalizations.of(context)?.viewFull ?? 'View Full'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: displayText));
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)?.draftCopiedToClipboard ?? 'Draft copied to clipboard'),
                        backgroundColor: AppColors.accent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text(AppLocalizations.of(context)?.copy ?? 'Copy'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'AI-generated draft. Must be reviewed by a qualified attorney.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lawyer / legal aid list card
// ---------------------------------------------------------------------------

class _LawyerListCard extends StatelessWidget {
  const _LawyerListCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final contacts = (data['contacts'] as List<dynamic>?) ?? [];
    final country = data['country'] as String? ?? '';

    return _CardContainer(
      headerIcon: Icons.people_rounded,
      headerTitle: 'Legal Aid ($country)',
      headerColor: AppColors.accent,
      child: Column(
        children: [
          for (int i = 0; i < contacts.length; i++) ...[
            if (i > 0) const Divider(height: 16),
            _LawyerContactRow(data: contacts[i] as Map<String, dynamic>),
          ],
        ],
      ),
    );
  }
}

class _LawyerContactRow extends StatelessWidget {
  const _LawyerContactRow({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? '-';
    final type = data['type'] as String? ?? '';
    final phone = data['phone'] as String?;
    final website = data['website'] as String?;
    final description = data['description'] as String?;
    final cost = data['cost'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                type,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            if (phone != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.phone_rounded, size: 12, color: AppColors.accent),
                  const SizedBox(width: 4),
                  Text(
                    phone,
                    style: const TextStyle(fontSize: 12, color: AppColors.accent),
                  ),
                ],
              ),
            if (website != null)
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.language_rounded, size: 12, color: AppColors.info),
                  SizedBox(width: 4),
                  Text(
                    'Website',
                    style: TextStyle(fontSize: 12, color: AppColors.info),
                  ),
                ],
              ),
            if (cost != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.euro_rounded, size: 12, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    cost,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Email draft card
// ---------------------------------------------------------------------------

class _EmailDraftCard extends StatelessWidget {
  const _EmailDraftCard({required this.data});
  final Map<String, dynamic> data;

  Future<void> _openMailto(BuildContext context) async {
    final to = data['to'] as String? ?? '';
    final subject = data['subject'] as String? ?? '';
    final body = data['body'] as String? ?? '';

    final uri = Uri(
      scheme: 'mailto',
      path: to,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    // F5 (WAVE 1, 2026-05-28) — schema/canLaunch guard + mailto
    // header-injection check via safeLaunchUrl. Tool-result cards render
    // LLM-produced mailto payloads, which are an active prompt-injection
    // surface (poisoned attachment can instruct the model to draft a
    // `to: victim,bcc:attacker` link).
    final result = await safeLaunchUrl(uri);
    if (!result.launched) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open email app'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _copyToClipboard(BuildContext context) {
    final to = data['to'] as String? ?? '';
    final subject = data['subject'] as String? ?? '';
    final body = data['body'] as String? ?? '';

    final fullText = 'To: $to\nSubject: $subject\n\n$body';
    Clipboard.setData(ClipboardData(text: fullText));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)?.draftCopiedToClipboard ?? 'Email copied to clipboard'),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final to = data['to'] as String? ?? '';
    final subject = data['subject'] as String? ?? '';
    final body = data['body'] as String? ?? '';

    return _CardContainer(
      headerIcon: Icons.email_rounded,
      headerTitle: 'Email Draft',
      headerColor: AppColors.info,
      borderColor: AppColors.info.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: 'To', value: to),
          _InfoRow(label: 'Subject', value: subject),
          const Divider(height: 16),
          Text(
            body.length > 200 ? '${body.substring(0, 200)}...' : body,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openMailto(context),
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: Text(AppLocalizations.of(context)?.sendViaEmail ?? 'Send Email'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.info,
                    side: const BorderSide(color: AppColors.info),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyToClipboard(context),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text(AppLocalizations.of(context)?.copy ?? 'Copy'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Language changed card
// ---------------------------------------------------------------------------

class _LanguageChangedCard extends StatelessWidget {
  const _LanguageChangedCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final displayName = data['display_name'] as String? ?? data['language'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.translate_rounded, size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(
            'Language: $displayName',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Translation card
// ---------------------------------------------------------------------------

class _TranslationCard extends StatelessWidget {
  const _TranslationCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final sourceText = data['source_text'] as String? ?? '';
    final translatedText = data['translated_text'] as String? ?? '';
    final sourceLang = data['source_language'] as String? ?? 'auto';
    final targetLang = data['target_language'] as String? ?? '';

    return _CardContainer(
      headerIcon: Icons.g_translate_rounded,
      headerTitle: 'Translation ($sourceLang -> $targetLang)',
      headerColor: AppColors.info,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sourceText.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                sourceText,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Icon(Icons.arrow_downward_rounded, size: 18, color: AppColors.accent),
            const SizedBox(height: 8),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.15)),
            ),
            child: SelectableText(
              translatedText,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Approval bar
// ---------------------------------------------------------------------------

/// Stateful approval bar.
///
/// BUG#4 fix (2026-04-29). Adds two guarantees on top of the legacy
/// stateless bar:
///   1. Timeout: if the user doesn't respond within [timeout] (default
///      5 min), the bar auto-fires [onRejectWithReason] with a
///      [ToolApprovalKind.timeout] outcome. Without this, navigating
///      away left the AI hanging on a tool_use with no result, and
///      every subsequent message in the case would dangle.
///   2. Single-shot reject: once any reject fires (manual Cancel or
///      timer), all later events are ignored. Prevents double-rejection
///      after Cancel-then-timeout races.
class _ApprovalBar extends StatefulWidget {
  const _ApprovalBar({
    required this.message,
    this.onApprove,
    this.onReject,
    this.onRejectWithReason,
    required this.timeout,
  });

  final String message;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final ValueChanged<ToolApprovalOutcome>? onRejectWithReason;
  final Duration timeout;

  @override
  State<_ApprovalBar> createState() => _ApprovalBarState();
}

class _ApprovalBarState extends State<_ApprovalBar> {
  Timer? _timeoutTimer;
  bool _settled = false;

  @override
  void initState() {
    super.initState();
    _timeoutTimer = Timer(widget.timeout, _handleTimeout);
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _handleTimeout() {
    if (_settled) return;
    _settled = true;
    widget.onRejectWithReason?.call(ToolApprovalOutcome.timeout());
    // Legacy callback still fires for older call-sites that don't yet
    // wire the structured variant.
    widget.onReject?.call();
  }

  void _handleCancel() {
    if (_settled) return;
    _settled = true;
    _timeoutTimer?.cancel();
    widget.onRejectWithReason?.call(ToolApprovalOutcome.userRejected());
    widget.onReject?.call();
  }

  void _handleApprove() {
    if (_settled) return;
    _settled = true;
    _timeoutTimer?.cancel();
    widget.onApprove?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline_rounded, size: 16, color: AppColors.warning),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _handleCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textTertiary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _handleApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context)?.confirm ?? 'Confirm'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
