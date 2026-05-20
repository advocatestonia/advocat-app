// =====================================================================
// Step 5 — Documents. PDF/photo upload via file_picker. Each upload
// streams to Storage + creates a `case_documents` row with parsed_text
// left null. Pkg 2's PDF parser fills it asynchronously when deployed.
//
// Pkg 3 keeps it deliberately simple: we don't try to parse here, we
// don't show progress per byte — just a list of staged file pickers
// and an "uploading 2 / 5" snackbar. Skip is fully supported.
//
// Important: this screen requires a real `caseId`. The host wizard
// either creates the case BEFORE step 5 (so the user can upload to
// the right row) or skips step 5 if no case has been created yet
// (urgent path). We default to staging file metadata locally and
// upload at finish-time so the same flow works whether step 5 is
// shown or skipped.
// =====================================================================

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../legal/utils/sensitive_consent_gate.dart';

/// A staged document — bytes held in memory, ready for upload at
/// wizard finish-time. Stored in the screen's local state (NOT
/// persisted, because the bytes are non-trivial; the user re-picks
/// if they restart the wizard).
@immutable
class StagedDocument {
  const StagedDocument({
    required this.filename,
    required this.bytes,
    required this.mimeType,
  });

  final String filename;
  final Uint8List bytes;
  final String mimeType;

  int get sizeBytes => bytes.length;
}

/// Provider so the host wizard can read staged docs at finish-time
/// without breaking PageView lazy-build. Cleared by the host on
/// successful create.
final stagedDocumentsProvider =
    StateProvider<List<StagedDocument>>((ref) => const []);

/// Picker dependency injected so tests can simulate file selection
/// without touching the platform plugin.
typedef FilePickFn = Future<FilePickerResult?> Function();

final intakeFilePickerProvider = Provider<FilePickFn>((ref) {
  return () => FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      );
});

class Step5DocumentsScreen extends ConsumerWidget {
  const Step5DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final staged = ref.watch(stagedDocumentsProvider);
    final picker = ref.watch(intakeFilePickerProvider);

    return ListView(
      key: const Key('intake-step-5'),
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          l10n?.intakeStep5Title ?? 'Documents',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n?.intakeStep5Subtitle ?? '',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton.icon(
          key: const Key('intake-pick-files-btn'),
          icon: const Icon(Icons.upload_file_outlined),
          label: Text(
            l10n?.intakeUploadDocsLabel ?? 'Upload documents',
          ),
          onPressed: () async {
            // GDPR Art. 9(2)(a) — explicit consent before file picker fires.
            final consented = await ensureSensitiveConsent(context, ref);
            if (!consented) return;
            if (!context.mounted) return;

            final picked = await picker();
            if (picked == null) return;
            final list = [...staged];
            for (final f in picked.files) {
              final bytes = f.bytes;
              if (bytes == null) continue;
              list.add(StagedDocument(
                filename: f.name,
                bytes: bytes,
                mimeType: _guessMimeType(f.name),
              ));
            }
            ref.read(stagedDocumentsProvider.notifier).state = list;
          },
        ),
        const SizedBox(height: AppSpacing.md),
        ..._stagedRows(staged, ref, l10n),
      ],
    );
  }

  String _guessMimeType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  List<Widget> _stagedRows(
    List<StagedDocument> staged,
    WidgetRef ref,
    AppLocalizations? l10n,
  ) {
    if (staged.isEmpty) return const [];
    return [
      for (var i = 0; i < staged.length; i++)
        Card(
          key: Key('intake-staged-doc-$i'),
          child: ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(
              staged[i].filename,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(_formatBytes(staged[i].sizeBytes)),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: l10n?.delete ?? 'Delete',
              color: AppColors.error,
              onPressed: () {
                final next = [...staged]..removeAt(i);
                ref.read(stagedDocumentsProvider.notifier).state = next;
              },
            ),
          ),
        ),
    ];
  }

  String _formatBytes(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
