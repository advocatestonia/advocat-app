import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../config/theme.dart';
import '../../../models/document.dart';
import '../providers/documents_provider.dart';

// ---------------------------------------------------------------------------
// View mode toggle
// ---------------------------------------------------------------------------

enum _ViewMode { grid, list }

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class DocumentListScreen extends ConsumerStatefulWidget {
  const DocumentListScreen({super.key, required this.caseId});

  final String caseId;

  @override
  ConsumerState<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends ConsumerState<DocumentListScreen> {
  _ViewMode _viewMode = _ViewMode.list;
  final Set<String> _selectedIds = {};
  bool get _isSelecting => _selectedIds.isNotEmpty;

  void _toggleViewMode() {
    HapticFeedback.selectionClick();
    setState(
      () => _viewMode =
          _viewMode == _ViewMode.grid ? _ViewMode.list : _ViewMode.grid,
    );
  }

  void _toggleSelection(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  void _onDocumentTap(CaseDocument doc) {
    if (_isSelecting) {
      _toggleSelection(doc.id);
      return;
    }

    // Navigate to analysis screen
    context.push(
      '/cases/${widget.caseId}/documents/${doc.id}/analysis',
      extra: {
        'documentName': doc.fileName,
      },
    );
  }

  void _onDocumentLongPress(CaseDocument doc) {
    if (!_isSelecting) {
      HapticFeedback.mediumImpact();
    }
    _toggleSelection(doc.id);
  }

  @override
  Widget build(BuildContext context) {
    final documentsAsync = ref.watch(documentsProvider(widget.caseId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _isSelecting
            ? Text('${_selectedIds.length} selected')
            : const Text('Documents'),
        leading: _isSelecting
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _clearSelection,
              )
            : null,
        actions: [
          if (_isSelecting) ...[
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete selected',
              onPressed: () {
                // Bulk delete action
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Delete ${_selectedIds.length} documents?'),
                    action: SnackBarAction(
                      label: 'Delete',
                      onPressed: () {
                        // Implement delete
                        _clearSelection();
                      },
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.analytics_outlined),
              tooltip: 'Analyze selected',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Batch analysis starting...'),
                    backgroundColor: AppColors.accent,
                  ),
                );
                _clearSelection();
              },
            ),
          ] else ...[
            IconButton(
              icon: Icon(
                _viewMode == _ViewMode.grid
                    ? Icons.view_list_rounded
                    : Icons.grid_view_rounded,
              ),
              tooltip: _viewMode == _ViewMode.grid
                  ? 'Switch to list'
                  : 'Switch to grid',
              onPressed: _toggleViewMode,
            ),
          ],
        ],
      ),
      body: documentsAsync.when(
        loading: () => _buildLoadingShimmer(),
        error: (e, _) => _buildErrorState(e, theme),
        data: (documents) {
          if (documents.isEmpty) return _buildEmptyState(theme);
          return _viewMode == _ViewMode.grid
              ? _buildGridView(documents)
              : _buildListView(documents);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/scan?caseId=${widget.caseId}'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.document_scanner_rounded),
        label: const Text('Scan New'),
      ),
    );
  }

  // ── Grid view ───────────────────────────────────────────────────────────

  Widget _buildGridView(List<CaseDocument> documents) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.78,
      ),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index];
        final isSelected = _selectedIds.contains(doc.id);

        return _DocumentGridCard(
          document: doc,
          isSelected: isSelected,
          isSelecting: _isSelecting,
          onTap: () => _onDocumentTap(doc),
          onLongPress: () => _onDocumentLongPress(doc),
          index: index,
        );
      },
    );
  }

  // ── List view ───────────────────────────────────────────────────────────

  Widget _buildListView(List<CaseDocument> documents) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index];
        final isSelected = _selectedIds.contains(doc.id);

        return _DocumentListTile(
          document: doc,
          isSelected: isSelected,
          isSelecting: _isSelecting,
          onTap: () => _onDocumentTap(doc),
          onLongPress: () => _onDocumentLongPress(doc),
          index: index,
        );
      },
    );
  }

  // ── Loading shimmer ─────────────────────────────────────────────────────

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1200.ms, color: AppColors.border);
      },
    );
  }

  // ── Empty state ─────────────────────────────────────────────────────────

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.document_scanner_outlined,
                size: 40,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No documents yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Scan your first document to let AI analyze it for errors and generate appeals.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () =>
                  context.push('/scan?caseId=${widget.caseId}'),
              icon: const Icon(Icons.document_scanner_rounded),
              label: const Text('Scan Document'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error state ─────────────────────────────────────────────────────────

  Widget _buildErrorState(Object error, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text('Failed to load documents',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () =>
                  ref.invalidate(documentsProvider(widget.caseId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Document grid card
// ---------------------------------------------------------------------------

class _DocumentGridCard extends StatelessWidget {
  const _DocumentGridCard({
    required this.document,
    required this.isSelected,
    required this.isSelecting,
    required this.onTap,
    required this.onLongPress,
    required this.index,
  });

  final CaseDocument document;
  final bool isSelected;
  final bool isSelecting;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail area
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppRadius.md - 1),
                      ),
                    ),
                    child: Icon(
                      _iconForMimeType(document.mimeType),
                      size: 40,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),

                // Info section
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm + 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.fileName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _StatusChip(status: document.processingStatus),
                          const Spacer(),
                          Text(
                            timeago.format(document.createdAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Selection checkbox
            if (isSelecting)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.accent : Colors.white,
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 50 * index),
          duration: 300.ms,
        )
        .scaleXY(
          begin: 0.95,
          end: 1,
          delay: Duration(milliseconds: 50 * index),
          duration: 300.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

// ---------------------------------------------------------------------------
// Document list tile
// ---------------------------------------------------------------------------

class _DocumentListTile extends StatelessWidget {
  const _DocumentListTile({
    required this.document,
    required this.isSelected,
    required this.isSelecting,
    required this.onTap,
    required this.onLongPress,
    required this.index,
  });

  final CaseDocument document;
  final bool isSelected;
  final bool isSelecting;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.05)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Leading icon / selection checkbox
            if (isSelecting)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm + 4),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.accent : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              )
            else
              Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(right: AppSpacing.sm + 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  _iconForMimeType(document.mimeType),
                  size: 24,
                  color: AppColors.textTertiary,
                ),
              ),

            // Document info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.fileName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _StatusChip(status: document.processingStatus),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        timeago.format(document.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Trailing arrow
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 40 * index),
          duration: 300.ms,
        )
        .slideX(
          begin: 0.05,
          end: 0,
          delay: Duration(milliseconds: 40 * index),
          duration: 300.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

// ---------------------------------------------------------------------------
// Status chip
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final DocumentProcessingStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bgColor;
    String label;

    switch (status) {
      case DocumentProcessingStatus.completed:
        color = AppColors.success;
        bgColor = const Color(0xFFDCFCE7);
        label = 'Analyzed';
      case DocumentProcessingStatus.processing:
        color = AppColors.warning;
        bgColor = const Color(0xFFFEF3C7);
        label = 'Processing';
      case DocumentProcessingStatus.failed:
        color = AppColors.error;
        bgColor = const Color(0xFFFEE2E2);
        label = 'Failed';
      case DocumentProcessingStatus.pending:
        color = AppColors.textTertiary;
        bgColor = AppColors.surfaceVariant;
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

IconData _iconForMimeType(String mimeType) {
  if (mimeType.contains('pdf')) return Icons.picture_as_pdf_outlined;
  if (mimeType.contains('image')) return Icons.image_outlined;
  if (mimeType.contains('word') || mimeType.contains('doc')) {
    return Icons.article_outlined;
  }
  return Icons.insert_drive_file_outlined;
}
