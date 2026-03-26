import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme.dart';
import '../../../models/document.dart';
import '../../documents/providers/documents_provider.dart';

class CaseDocumentsScreen extends ConsumerWidget {
  const CaseDocumentsScreen({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentsProvider(caseId));

    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: docsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (docs) {
          if (docs.isEmpty) {
            return const Center(
              child: Text('No documents yet. Scan or upload one.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final doc = docs[index];
              return ListTile(
                leading: Icon(
                  doc.mimeType.contains('pdf')
                      ? Icons.picture_as_pdf
                      : Icons.image_outlined,
                  color: AppColors.primary,
                ),
                title: Text(doc.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(doc.category.name),
                trailing: _processingBadge(doc.processingStatus),
              );
            },
          );
        },
      ),
    );
  }

  Widget _processingBadge(DocumentProcessingStatus status) {
    final (color, label) = switch (status) {
      DocumentProcessingStatus.pending => (AppColors.textTertiary, 'Pending'),
      DocumentProcessingStatus.processing => (AppColors.warning, 'Processing'),
      DocumentProcessingStatus.completed => (AppColors.success, 'Analyzed'),
      DocumentProcessingStatus.failed => (AppColors.error, 'Failed'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }
}
