// =====================================================================
// Phase 2 Pkg 4 — Documents tab.
//
// Wraps the existing `case_documents` data path (Pkg 2 PDF parser fills
// parsed_summary / key_extractions server-side; this tab is a thin list
// reader that reuses caseDocumentsProvider from Pkg 1.D).
// =====================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../case_memory/models/case_document.dart';
import '../../case_memory/state/cases_list_provider.dart';

class DocumentsTab extends ConsumerWidget {
  const DocumentsTab({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncDocs = ref.watch(caseDocumentsProvider(caseId));

    return asyncDocs.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) {
        debugPrint('workspace documents tab load failed: $e');
        return Center(
          child: Text(
            l10n?.genericError ?? 'Something went wrong. Please try again.',
          ),
        );
      },
      data: (raw) {
        // caseDocumentsProvider returns List<dynamic> by repo contract; we
        // narrow defensively. Anything that is not a CaseDocument is
        // dropped silently.
        final docs = raw.whereType<CaseDocument>().toList(growable: false);
        if (docs.isEmpty) {
          return Center(
            key: const Key('workspace-documents-empty'),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 48,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n?.workspaceDocumentsEmpty ??
                        'No documents. Upload from Scan.',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(caseDocumentsProvider(caseId)),
          child: ListView.separated(
            key: const Key('workspace-documents-tab'),
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
            itemBuilder: (context, i) => _DocCard(doc: docs[i]),
          ),
        );
      },
    );
  }
}

class _DocCard extends StatelessWidget {
  const _DocCard({required this.doc});
  final CaseDocument doc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.insert_drive_file_outlined,
              size: 22, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.filename,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (doc.parsedSummary != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    doc.parsedSummary!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _formatDate(doc.uploadedAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }
}
