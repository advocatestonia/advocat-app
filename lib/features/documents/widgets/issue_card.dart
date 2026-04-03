import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';

/// Severity levels for document analysis issues.
enum IssueSeverity { critical, important, informational }

/// Data model for a single issue found during document analysis.
class DocumentIssue {
  final String id;
  final IssueSeverity severity;
  final String title;
  final String explanation;
  final String legalBasis;
  final String? detailedAnalysis;
  final bool selectedForAppeal;

  const DocumentIssue({
    required this.id,
    required this.severity,
    required this.title,
    required this.explanation,
    required this.legalBasis,
    this.detailedAnalysis,
    this.selectedForAppeal = false,
  });

  DocumentIssue copyWith({bool? selectedForAppeal}) {
    return DocumentIssue(
      id: id,
      severity: severity,
      title: title,
      explanation: explanation,
      legalBasis: legalBasis,
      detailedAnalysis: detailedAnalysis,
      selectedForAppeal: selectedForAppeal ?? this.selectedForAppeal,
    );
  }
}

/// Reusable expandable card that displays a single issue found in a document.
///
/// Shows severity badge, title, short explanation, legal basis, and an
/// optional "Use in Appeal" toggle. Supports animated expand/collapse.
class IssueCard extends StatefulWidget {
  const IssueCard({
    super.key,
    required this.issue,
    required this.index,
    this.onToggleAppeal,
    this.initiallyExpanded = false,
  });

  final DocumentIssue issue;
  final int index;
  final ValueChanged<bool>? onToggleAppeal;
  final bool initiallyExpanded;

  @override
  State<IssueCard> createState() => _IssueCardState();
}

class _IssueCardState extends State<IssueCard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late final AnimationController _rotationController;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );
    if (_isExpanded) _rotationController.forward();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _rotationController.forward();
    } else {
      _rotationController.reverse();
    }
  }

  Color get _severityColor {
    switch (widget.issue.severity) {
      case IssueSeverity.critical:
        return AppColors.error;
      case IssueSeverity.important:
        return AppColors.warning;
      case IssueSeverity.informational:
        return AppColors.info;
    }
  }

  Color get _severityBgColor {
    switch (widget.issue.severity) {
      case IssueSeverity.critical:
        return const Color(0xFFFEE2E2);
      case IssueSeverity.important:
        return const Color(0xFFFEF3C7);
      case IssueSeverity.informational:
        return const Color(0xFFDBEAFE);
    }
  }

  String get _severityLabel {
    switch (widget.issue.severity) {
      case IssueSeverity.critical:
        return 'CRITICAL';
      case IssueSeverity.important:
        return 'IMPORTANT';
      case IssueSeverity.informational:
        return 'INFO';
    }
  }

  IconData get _severityIcon {
    switch (widget.issue.severity) {
      case IssueSeverity.critical:
        return Icons.error_rounded;
      case IssueSeverity.important:
        return Icons.warning_amber_rounded;
      case IssueSeverity.informational:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: _isExpanded ? _severityColor.withValues(alpha: 0.4) : AppColors.border,
          width: _isExpanded ? 1.5 : 1,
        ),
        boxShadow: _isExpanded
            ? [
                BoxShadow(
                  color: _severityColor.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (always visible) — tappable to expand/collapse
          InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Severity badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _severityBgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_severityIcon, size: 14, color: _severityColor),
                        const SizedBox(width: 4),
                        Text(
                          _severityLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _severityColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // Title + short explanation
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.issue.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.issue.explanation,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                          maxLines: _isExpanded ? null : 2,
                          overflow:
                              _isExpanded ? null : TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // Expand/collapse chevron
                  RotationTransition(
                    turns: _rotationAnimation,
                    child: const Icon(
                      Icons.expand_more_rounded,
                      color: AppColors.textTertiary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded details
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(theme),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 80 * widget.index),
          duration: 350.ms,
        )
        .slideY(
          begin: 0.08,
          end: 0,
          delay: Duration(milliseconds: 80 * widget.index),
          duration: 350.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildExpandedContent(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),

          // Legal basis
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm + 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.gavel_rounded,
                  size: 16,
                  color: AppColors.accent,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Legal Basis',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.issue.legalBasis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Detailed analysis (if available)
          if (widget.issue.detailedAnalysis != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.issue.detailedAnalysis!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // "Use in Appeal" button
          SizedBox(
            width: double.infinity,
            child: widget.issue.selectedForAppeal
                ? OutlinedButton.icon(
                    onPressed: () =>
                        widget.onToggleAppeal?.call(false),
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: Text(AppLocalizations.of(context)?.addedToAppeal ?? 'Added to Appeal'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                      backgroundColor: AppColors.accent.withValues(alpha: 0.05),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: () =>
                        widget.onToggleAppeal?.call(true),
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                    label: Text(AppLocalizations.of(context)?.useInAppeal ?? 'Use in Appeal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
}
