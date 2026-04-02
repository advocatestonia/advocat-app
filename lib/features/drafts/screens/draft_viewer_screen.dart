import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/ai_service.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class DraftViewerScreen extends ConsumerStatefulWidget {
  const DraftViewerScreen({
    super.key,
    required this.caseId,
    this.draftTitle,
    this.draftContent,
    this.targetInstitution,
    this.draftType,
  });

  final String caseId;
  final String? draftTitle;
  final String? draftContent;
  final String? targetInstitution;
  final String? draftType;

  @override
  ConsumerState<DraftViewerScreen> createState() => _DraftViewerScreenState();
}

class _DraftViewerScreenState extends ConsumerState<DraftViewerScreen> {
  bool _isEditing = false;
  bool _isGenerating = false;
  late TextEditingController _contentController;
  late String _title;
  late String _content;
  String? _targetInstitution;

  @override
  void initState() {
    super.initState();
    _title = widget.draftTitle ?? '';
    _content = widget.draftContent ?? '';
    _targetInstitution = widget.targetInstitution;
    _contentController = TextEditingController(text: _content);

    if (_content.isEmpty) {
      _generateDraft();
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  // ── Draft generation ────────────────────────────────────────────────────

  Future<void> _generateDraft() async {
    setState(() => _isGenerating = true);

    try {
      final ai = ref.read(aiServiceProvider);
      final response = await ai.generateDraft(
        caseId: widget.caseId,
        draftType: widget.draftType ?? 'appeal',
      );

      if (mounted) {
        setState(() {
          _title = response.title;
          _content = response.content;
          _contentController.text = _content;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToGenerateDraft),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _toggleEdit() {
    if (_isEditing) {
      // Save changes
      setState(() {
        _content = _contentController.text;
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.changesSaved),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      setState(() => _isEditing = true);
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _content));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.copiedToClipboard),
        backgroundColor: AppColors.accent,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _exportPdf() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.pdfExportComingSoon),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _sendViaEmail() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.emailComingSoon),
        backgroundColor: AppColors.info,
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.draftDocument),
        actions: [
          if (!_isGenerating)
            IconButton(
              icon: Icon(_isEditing ? Icons.check_rounded : Icons.edit_outlined),
              tooltip: _isEditing ? AppLocalizations.of(context)!.saveChanges : AppLocalizations.of(context)!.editDocument,
              onPressed: _toggleEdit,
            ),
        ],
      ),
      body: _isGenerating ? _buildGeneratingState() : _buildContent(theme),
    );
  }

  // ── Generating state ────────────────────────────────────────────────────

  Widget _buildGeneratingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.accent,
                backgroundColor: AppColors.accent.withValues(alpha: 0.15),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 0.95, end: 1.05, duration: 1200.ms),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppLocalizations.of(context)!.generatingDraft,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppLocalizations.of(context)!.generatingDraftDesc,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Document content ────────────────────────────────────────────────────

  Widget _buildContent(ThemeData theme) {
    return Column(
      children: [
        // Warning banner
        _buildWarningBanner(),

        // Document body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Document header
                _buildDocumentHeader(theme),
                const SizedBox(height: AppSpacing.lg),

                // Document content
                _isEditing
                    ? _buildEditableContent(theme)
                    : _buildReadOnlyContent(theme),

                const SizedBox(height: 100), // Space for action bar
              ],
            ),
          ),
        ),

        // Bottom action bar
        _buildActionBar(),
      ],
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      color: AppColors.warning.withValues(alpha: 0.1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.reviewBeforeSending,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.warning.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentHeader(ThemeData theme) {
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
          // Title
          Text(
            _title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Metadata row
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _MetadataChip(
                icon: Icons.description_outlined,
                label: widget.draftType?.replaceAll('_', ' ').toUpperCase() ??
                    'APPEAL',
              ),
              _MetadataChip(
                icon: Icons.calendar_today_outlined,
                label: _formatDate(DateTime.now()),
              ),
              if (_targetInstitution != null)
                _MetadataChip(
                  icon: Icons.business_outlined,
                  label: _targetInstitution!,
                ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildReadOnlyContent(ThemeData theme) {
    if (_content.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noContentAvailable,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SelectableText(
        _content,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimary,
          height: 1.7,
          fontSize: 15,
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildEditableContent(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.accent, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _contentController,
        maxLines: null,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimary,
          height: 1.7,
          fontSize: 15,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(AppSpacing.sm),
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm + 4,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.sm + 4,
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
      child: Row(
        children: [
          // Edit
          _ActionButton(
            icon: _isEditing ? Icons.check_rounded : Icons.edit_outlined,
            label: _isEditing ? AppLocalizations.of(context)!.save : AppLocalizations.of(context)!.edit,
            onPressed: _toggleEdit,
          ),
          const SizedBox(width: AppSpacing.sm),

          // Export PDF
          _ActionButton(
            icon: Icons.picture_as_pdf_outlined,
            label: AppLocalizations.of(context)!.pdf,
            onPressed: _exportPdf,
          ),
          const SizedBox(width: AppSpacing.sm),

          // Email
          _ActionButton(
            icon: Icons.email_outlined,
            label: AppLocalizations.of(context)!.email,
            onPressed: _sendViaEmail,
          ),
          const SizedBox(width: AppSpacing.sm),

          // Copy
          _ActionButton(
            icon: Icons.copy_outlined,
            label: AppLocalizations.of(context)!.copy,
            onPressed: _copyToClipboard,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

// ---------------------------------------------------------------------------
// Supporting widgets
// ---------------------------------------------------------------------------

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
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
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: AppColors.primary),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
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
