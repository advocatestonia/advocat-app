import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/ai_service.dart';
import '../../../services/demo_data.dart';
import '../widgets/issue_card.dart';

// ---------------------------------------------------------------------------
// Analysis state
// ---------------------------------------------------------------------------

enum _AnalysisStep { ocr, analyzing, checking, researching, done, error }

class _AnalysisResult {
  final String summary;
  final List<DocumentIssue> issues;
  final int criticalCount;
  final int importantCount;
  final int infoCount;

  const _AnalysisResult({
    required this.summary,
    required this.issues,
    required this.criticalCount,
    required this.importantCount,
    required this.infoCount,
  });
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class DocumentAnalysisScreen extends ConsumerStatefulWidget {
  const DocumentAnalysisScreen({
    super.key,
    required this.caseId,
    required this.documentId,
    this.documentName,
    this.thumbnailUrl,
  });

  final String caseId;
  final String documentId;
  final String? documentName;
  final String? thumbnailUrl;

  @override
  ConsumerState<DocumentAnalysisScreen> createState() =>
      _DocumentAnalysisScreenState();
}

class _DocumentAnalysisScreenState
    extends ConsumerState<DocumentAnalysisScreen> {
  _AnalysisStep _step = _AnalysisStep.ocr;
  _AnalysisResult? _result;
  String? _errorMessage;
  final Set<String> _selectedIssueIds = {};

  @override
  void initState() {
    super.initState();
    _runAnalysis();
  }

  // ── Analysis pipeline ───────────────────────────────────────────────────

  Future<void> _runAnalysis() async {
    try {
      // Step 1: OCR
      setState(() => _step = _AnalysisStep.ocr);
      await Future.delayed(const Duration(milliseconds: 1200));

      // Step 2: Analyzing content
      if (!mounted) return;
      setState(() => _step = _AnalysisStep.analyzing);
      await Future.delayed(const Duration(milliseconds: 1000));

      // Step 3: Checking for errors
      if (!mounted) return;
      setState(() => _step = _AnalysisStep.checking);

      final isDemo = ref.read(isDemoModeProvider);
      List<DocumentIssue> issues;
      String summary;

      if (isDemo) {
        // Use the 3 real errors from the Estonia case
        await Future.delayed(const Duration(milliseconds: 800));
        issues = DemoData.analysisIssues.map((data) {
          return DocumentIssue(
            id: data['id'] as String,
            severity: IssueSeverity.critical,
            title: data['title'] as String,
            explanation: data['explanation'] as String,
            legalBasis: data['legal_basis'] as String,
            detailedAnalysis: data['detailed_analysis'] as String?,
          );
        }).toList();
        summary = 'Found 3 critical procedural errors in the police deportation '
            'decision. The decision was issued in the wrong language (Russian only), '
            'signed by an unauthorized officer, and references the non-existent '
            '"Soviet Union" as country of origin.';
      } else {
        // Actual AI call
        final ai = ref.read(aiServiceProvider);
        final analysis = await ai.analyzeDocument(
          caseId: widget.caseId,
          documentId: widget.documentId,
        );
        issues = _buildIssuesFromAnalysis(analysis);
        summary = analysis.summary;
      }

      // Step 4: Researching law
      if (!mounted) return;
      setState(() => _step = _AnalysisStep.researching);
      await Future.delayed(const Duration(milliseconds: 800));

      final criticalCount =
          issues.where((i) => i.severity == IssueSeverity.critical).length;
      final importantCount =
          issues.where((i) => i.severity == IssueSeverity.important).length;
      final infoCount =
          issues.where((i) => i.severity == IssueSeverity.informational).length;

      if (!mounted) return;
      setState(() {
        _step = _AnalysisStep.done;
        _result = _AnalysisResult(
          summary: summary,
          issues: issues,
          criticalCount: criticalCount,
          importantCount: importantCount,
          infoCount: infoCount,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _AnalysisStep.error;
        _errorMessage = null;
      });
    }
  }

  List<DocumentIssue> _buildIssuesFromAnalysis(DocumentAnalysis analysis) {
    // The AI service returns key_points which we map to issues.
    // In production, the backend would return structured issue objects.
    // Here we transform key_points into issues with mock severity data
    // to demonstrate the UI pattern.
    final issues = <DocumentIssue>[];
    final keyPoints = analysis.keyPoints;

    for (var i = 0; i < keyPoints.length; i++) {
      final point = keyPoints[i];
      IssueSeverity severity;
      if (i == 0 && keyPoints.length > 2) {
        severity = IssueSeverity.critical;
      } else if (i < keyPoints.length ~/ 2) {
        severity = IssueSeverity.important;
      } else {
        severity = IssueSeverity.informational;
      }

      issues.add(DocumentIssue(
        id: 'issue_$i',
        severity: severity,
        title: point.length > 60 ? '${point.substring(0, 60)}...' : point,
        explanation: point,
        legalBasis: _inferLegalBasis(point),
        detailedAnalysis: analysis.summary,
      ));
    }

    // Ensure at least one demo issue if backend returned empty key_points
    if (issues.isEmpty) {
      issues.add(const DocumentIssue(
        id: 'issue_0',
        severity: IssueSeverity.informational,
        title: 'Document processed successfully',
        explanation: 'No significant issues were detected in this document.',
        legalBasis: 'N/A',
      ));
    }

    return issues;
  }

  String _inferLegalBasis(String point) {
    final lower = point.toLowerCase();
    if (lower.contains('language') || lower.contains('keel')) {
      return 'Haldusmenetluse seadus \u00A78, V\u00E4lismaalaste seadus \u00A7203';
    }
    if (lower.contains('deadline') || lower.contains('time') || lower.contains('day')) {
      return 'Haldusmenetluse seadus \u00A733, V\u00E4lismaalaste seadus \u00A7190';
    }
    if (lower.contains('hearing') || lower.contains('interview')) {
      return 'Haldusmenetluse seadus \u00A740, P\u00F5hiseadus \u00A715';
    }
    if (lower.contains('decision') || lower.contains('otsus')) {
      return 'Haldusmenetluse seadus \u00A756, V\u00E4lismaalaste seadus \u00A7196';
    }
    return 'V\u00E4lismaalaste seadus, Haldusmenetluse seadus';
  }

  void _toggleIssueForAppeal(String issueId, bool selected) {
    setState(() {
      if (selected) {
        _selectedIssueIds.add(issueId);
      } else {
        _selectedIssueIds.remove(issueId);
      }
    });
  }

  void _generateAppeal() {
    // Navigate to draft generation with selected issues
    // In production, pass _selectedIssueIds to the draft generator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Generating appeal with ${_selectedIssueIds.isEmpty ? 'all' : _selectedIssueIds.length} issue${_selectedIssueIds.length == 1 ? '' : 's'}...',
        ),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.documentName ?? AppLocalizations.of(context)!.documentAnalysis),
        actions: [
          if (_step == _AnalysisStep.done)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: AppLocalizations.of(context)!.exportAsPdf,
              onPressed: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.pdfExportComingSoon),
                    backgroundColor: AppColors.info,
                  ),
                );
              },
            ),
        ],
      ),
      body: _step == _AnalysisStep.done || _step == _AnalysisStep.error
          ? _buildResults()
          : _buildProcessing(),
    );
  }

  // ── Processing states ───────────────────────────────────────────────────

  Widget _buildProcessing() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Document thumbnail
            _buildDocumentThumbnail(),
            const SizedBox(height: AppSpacing.xl),

            // Animated step indicator
            _AnimatedStepIndicator(currentStep: _step),

            const SizedBox(height: AppSpacing.xl),

            // Progress steps list
            _buildProgressSteps(),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentThumbnail() {
    return Container(
      width: 80,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: widget.thumbnailUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm - 1),
              child: Image.network(widget.thumbnailUrl!, fit: BoxFit.cover),
            )
          : const Icon(
              Icons.description_outlined,
              size: 36,
              color: AppColors.textTertiary,
            ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1.0, end: 1.04, duration: 1500.ms)
        .then()
        .scaleXY(begin: 1.04, end: 1.0, duration: 1500.ms);
  }

  Widget _buildProgressSteps() {
    final l10n = AppLocalizations.of(context)!;
    final steps = [
      _StepInfo(
        label: l10n.readingDocument,
        icon: Icons.description_outlined,
        step: _AnalysisStep.ocr,
      ),
      _StepInfo(
        label: l10n.analyzingContent,
        icon: Icons.search_rounded,
        step: _AnalysisStep.analyzing,
      ),
      _StepInfo(
        label: l10n.checkingErrors,
        icon: Icons.checklist_rounded,
        step: _AnalysisStep.checking,
      ),
      _StepInfo(
        label: l10n.researchingLaw,
        icon: Icons.menu_book_rounded,
        step: _AnalysisStep.researching,
      ),
    ];

    return Column(
      children: steps.map((s) {
        final isActive = _step == s.step;
        final isDone = _step.index > s.step.index;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              // Status icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? AppColors.accent
                      : isActive
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                ),
                child: Icon(
                  isDone ? Icons.check_rounded : s.icon,
                  size: 16,
                  color: isDone || isActive ? Colors.white : AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 4),

              // Label
              Text(
                s.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isDone
                      ? AppColors.textTertiary
                      : isActive
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                ),
              ),

              if (isActive) ...[
                const SizedBox(width: AppSpacing.sm),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Results ─────────────────────────────────────────────────────────────

  Widget _buildResults() {
    if (_step == _AnalysisStep.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 64, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text(
                _errorMessage ?? AppLocalizations.of(context)!.analysisFailedRetry,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _step = _AnalysisStep.ocr;
                    _errorMessage = null;
                  });
                  _runAnalysis();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: Text(AppLocalizations.of(context)!.retryAnalysis),
              ),
            ],
          ),
        ),
      );
    }

    final result = _result!;
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Summary card
              _buildSummaryCard(result, theme),
              const SizedBox(height: AppSpacing.md),

              // Severity overview
              _buildSeverityOverview(result, theme),
              const SizedBox(height: AppSpacing.lg),

              // Issues header
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  AppLocalizations.of(context)!.issuesFoundHeader,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              // Issue cards
              ...result.issues.asMap().entries.map((entry) {
                final issue = entry.value;
                final isSelected = _selectedIssueIds.contains(issue.id);
                return IssueCard(
                  key: ValueKey(issue.id),
                  issue: issue.copyWith(selectedForAppeal: isSelected),
                  index: entry.key,
                  initiallyExpanded: issue.severity == IssueSeverity.critical,
                  onToggleAppeal: (selected) =>
                      _toggleIssueForAppeal(issue.id, selected),
                );
              }),

              const SizedBox(height: 100), // Space for the bottom button
            ],
          ),
        ),

        // Generate Appeal button
        _buildBottomActionBar(theme),
      ],
    );
  }

  Widget _buildSummaryCard(_AnalysisResult result, ThemeData theme) {
    final totalIssues = result.issues.length;
    final hasProblems = result.criticalCount > 0 || result.importantCount > 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasProblems
              ? [
                  AppColors.error.withValues(alpha: 0.08),
                  AppColors.warning.withValues(alpha: 0.05),
                ]
              : [
                  AppColors.success.withValues(alpha: 0.08),
                  AppColors.accent.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: hasProblems
              ? AppColors.error.withValues(alpha: 0.2)
              : AppColors.success.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hasProblems
                  ? AppColors.error.withValues(alpha: 0.12)
                  : AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasProblems
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline_rounded,
              color: hasProblems ? AppColors.error : AppColors.success,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.issuesFoundInDocument(totalIssues),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.summary,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildSeverityOverview(_AnalysisResult result, ThemeData theme) {
    final total = result.issues.length;
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.severityOverview,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 4),

          // Severity bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (result.criticalCount > 0)
                    Flexible(
                      flex: result.criticalCount,
                      child: Container(color: AppColors.error),
                    ),
                  if (result.importantCount > 0)
                    Flexible(
                      flex: result.importantCount,
                      child: Container(color: AppColors.warning),
                    ),
                  if (result.infoCount > 0)
                    Flexible(
                      flex: result.infoCount,
                      child: Container(color: AppColors.info),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 4),

          // Legend
          Builder(builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Row(
              children: [
                if (result.criticalCount > 0)
                  _SeverityLegendItem(
                    color: AppColors.error,
                    label: '${result.criticalCount} ${l10n.critical}',
                  ),
                if (result.importantCount > 0)
                  _SeverityLegendItem(
                    color: AppColors.warning,
                    label: '${result.importantCount} ${l10n.important}',
                  ),
                if (result.infoCount > 0)
                  _SeverityLegendItem(
                    color: AppColors.info,
                    label: '${result.infoCount} ${l10n.informational}',
                  ),
              ],
            );
          }),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0, delay: 200.ms, duration: 400.ms);
  }

  Widget _buildBottomActionBar(ThemeData theme) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _generateAppeal,
          icon: const Icon(Icons.description_outlined),
          label: Text(
            _selectedIssueIds.isEmpty
                ? AppLocalizations.of(context)!.generateAppeal
                : AppLocalizations.of(context)!.generateAppealWithIssues(_selectedIssueIds.length),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Supporting widgets
// ---------------------------------------------------------------------------

class _StepInfo {
  final String label;
  final IconData icon;
  final _AnalysisStep step;

  _StepInfo({
    required this.label,
    required this.icon,
    required this.step,
  });
}

class _AnimatedStepIndicator extends StatelessWidget {
  const _AnimatedStepIndicator({required this.currentStep});

  final _AnalysisStep currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isActive = currentStep.index == index;
        final isDone = currentStep.index > index;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isDone
                ? AppColors.accent
                : isActive
                    ? AppColors.primary
                    : AppColors.border,
          ),
        );
      }),
    );
  }
}

class _SeverityLegendItem extends StatelessWidget {
  const _SeverityLegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
