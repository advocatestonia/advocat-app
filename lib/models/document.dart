class CaseDocument {
  final String id;
  final String caseId;
  final String userId;
  final String fileName;
  final String storagePath;
  final String mimeType;
  final int fileSizeBytes;
  final DocumentCategory category;
  final String? language;
  final String? ocrText;
  final String? aiSummary;
  final Map<String, dynamic> extractedEntities;
  final DocumentProcessingStatus processingStatus;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CaseDocument({
    required this.id,
    required this.caseId,
    required this.userId,
    required this.fileName,
    required this.storagePath,
    required this.mimeType,
    required this.fileSizeBytes,
    this.category = DocumentCategory.other,
    this.language,
    this.ocrText,
    this.aiSummary,
    this.extractedEntities = const {},
    this.processingStatus = DocumentProcessingStatus.pending,
    required this.createdAt,
    this.updatedAt,
  });

  CaseDocument copyWith({
    String? id,
    String? caseId,
    String? userId,
    String? fileName,
    String? storagePath,
    String? mimeType,
    int? fileSizeBytes,
    DocumentCategory? category,
    String? language,
    String? ocrText,
    String? aiSummary,
    Map<String, dynamic>? extractedEntities,
    DocumentProcessingStatus? processingStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CaseDocument(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      userId: userId ?? this.userId,
      fileName: fileName ?? this.fileName,
      storagePath: storagePath ?? this.storagePath,
      mimeType: mimeType ?? this.mimeType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      category: category ?? this.category,
      language: language ?? this.language,
      ocrText: ocrText ?? this.ocrText,
      aiSummary: aiSummary ?? this.aiSummary,
      extractedEntities: extractedEntities ?? this.extractedEntities,
      processingStatus: processingStatus ?? this.processingStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CaseDocument.fromJson(Map<String, dynamic> json) {
    return CaseDocument(
      id: json['id'] as String,
      caseId: json['case_id'] as String,
      userId: json['user_id'] as String,
      fileName: json['file_name'] as String,
      storagePath: json['storage_path'] as String,
      mimeType: json['mime_type'] as String,
      fileSizeBytes: json['file_size_bytes'] as int,
      category: _categoryFromJson(json['category'] as String?),
      language: json['language'] as String?,
      ocrText: json['ocr_text'] as String?,
      aiSummary: json['ai_summary'] as String?,
      extractedEntities: (json['extracted_entities'] as Map<String, dynamic>?) ?? {},
      processingStatus: _processingStatusFromJson(json['processing_status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'case_id': caseId,
      'user_id': userId,
      'file_name': fileName,
      'storage_path': storagePath,
      'mime_type': mimeType,
      'file_size_bytes': fileSizeBytes,
      'category': _categoryToJson(category),
      'language': language,
      'ocr_text': ocrText,
      'ai_summary': aiSummary,
      'extracted_entities': extractedEntities,
      'processing_status': _processingStatusToJson(processingStatus),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static DocumentCategory _categoryFromJson(String? value) {
    switch (value) {
      case 'decision': return DocumentCategory.decision;
      case 'appeal': return DocumentCategory.appeal;
      case 'correspondence': return DocumentCategory.correspondence;
      case 'identity': return DocumentCategory.identity;
      case 'evidence': return DocumentCategory.evidence;
      case 'medical': return DocumentCategory.medical;
      case 'employment': return DocumentCategory.employment;
      case 'court_filing': return DocumentCategory.courtFiling;
      default: return DocumentCategory.other;
    }
  }

  static String _categoryToJson(DocumentCategory category) {
    switch (category) {
      case DocumentCategory.decision: return 'decision';
      case DocumentCategory.appeal: return 'appeal';
      case DocumentCategory.correspondence: return 'correspondence';
      case DocumentCategory.identity: return 'identity';
      case DocumentCategory.evidence: return 'evidence';
      case DocumentCategory.medical: return 'medical';
      case DocumentCategory.employment: return 'employment';
      case DocumentCategory.courtFiling: return 'court_filing';
      case DocumentCategory.other: return 'other';
    }
  }

  static DocumentProcessingStatus _processingStatusFromJson(String? value) {
    switch (value) {
      case 'processing': return DocumentProcessingStatus.processing;
      case 'completed': return DocumentProcessingStatus.completed;
      case 'failed': return DocumentProcessingStatus.failed;
      default: return DocumentProcessingStatus.pending;
    }
  }

  static String _processingStatusToJson(DocumentProcessingStatus status) {
    switch (status) {
      case DocumentProcessingStatus.pending: return 'pending';
      case DocumentProcessingStatus.processing: return 'processing';
      case DocumentProcessingStatus.completed: return 'completed';
      case DocumentProcessingStatus.failed: return 'failed';
    }
  }
}

enum DocumentCategory {
  decision,
  appeal,
  correspondence,
  identity,
  evidence,
  medical,
  employment,
  courtFiling,
  other,
}

enum DocumentProcessingStatus {
  pending,
  processing,
  completed,
  failed,
}
