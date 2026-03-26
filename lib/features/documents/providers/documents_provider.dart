import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/document.dart';
import '../../../services/ai_service.dart';
import '../../../services/supabase_service.dart';

// ---------------------------------------------------------------------------
// Documents list provider (reactive, per case)
// ---------------------------------------------------------------------------

/// Documents for a given case. Auto-refreshes when invalidated.
final documentsProvider =
    FutureProvider.family<List<CaseDocument>, String>((ref, caseId) async {
  return ref.watch(supabaseServiceProvider).getDocuments(caseId);
});

// ---------------------------------------------------------------------------
// Document upload & analysis state
// ---------------------------------------------------------------------------

enum UploadPhase { idle, uploading, ocr, analyzing, done, error }

class DocumentUploadState {
  final UploadPhase phase;
  final double progress;
  final String? documentId;
  final String? ocrText;
  final DocumentAnalysis? analysis;
  final String? error;

  const DocumentUploadState({
    this.phase = UploadPhase.idle,
    this.progress = 0,
    this.documentId,
    this.ocrText,
    this.analysis,
    this.error,
  });

  DocumentUploadState copyWith({
    UploadPhase? phase,
    double? progress,
    String? documentId,
    String? ocrText,
    DocumentAnalysis? analysis,
    String? error,
  }) {
    return DocumentUploadState(
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
      documentId: documentId ?? this.documentId,
      ocrText: ocrText ?? this.ocrText,
      analysis: analysis ?? this.analysis,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Documents notifier (simplified for web/demo compatibility)
// ---------------------------------------------------------------------------

class DocumentsNotifier extends StateNotifier<DocumentUploadState> {
  DocumentsNotifier({
    required this.caseId,
    required this.supabaseService,
    required this.aiService,
  }) : super(const DocumentUploadState());

  final String caseId;
  final SupabaseService supabaseService;
  final AIService aiService;

  /// Reset state for a new upload.
  void reset() {
    state = const DocumentUploadState();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final documentUploadProvider = StateNotifierProvider.family<DocumentsNotifier,
    DocumentUploadState, String>(
  (ref, caseId) {
    return DocumentsNotifier(
      caseId: caseId,
      supabaseService: ref.watch(supabaseServiceProvider),
      aiService: ref.watch(aiServiceProvider),
    );
  },
);
