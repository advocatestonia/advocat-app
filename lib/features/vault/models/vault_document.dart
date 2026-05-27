// features/vault/models/vault_document.dart — Vault UI models.
// -----------------------------------------------------------------------------
// Lightweight data classes for the Document Vault screen. Map directly to the
// `documents` table plus the upcoming `vault_tags` / `vault_document_tags`
// tables the backend agent is shipping in parallel.
//
// Kept intentionally trivial (no codegen, no immutable_collections) so the
// UI tests can construct fixtures inline.
// -----------------------------------------------------------------------------

/// One row from the vault list, denormalised with its primary tag for the UI.
class VaultDocument {
  const VaultDocument({
    required this.id,
    required this.fileName,
    required this.storagePath,
    required this.mimeType,
    required this.createdAt,
    this.fileSizeBytes,
    this.tagId,
    this.tagSlug,
    this.tagLabel,
    this.encrypted = false,
  });

  final String id;
  final String fileName;
  final String storagePath;
  final String mimeType;
  final DateTime createdAt;
  final int? fileSizeBytes;

  /// Primary tag for the doc, if any. The backend may return more than one
  /// row from `vault_document_tags` — UI shows the first.
  final String? tagId;
  final String? tagSlug;
  final String? tagLabel;

  /// True once the backend marks the row as encrypted-at-rest. The icon
  /// shield is shown regardless (storage bucket is always private), this
  /// flag drives the verbiage in the empty state.
  final bool encrypted;

  /// Tolerant of two row shapes:
  ///   1. Raw `documents` row + nullable `tag_*` columns the search RPC
  ///      will project.
  ///   2. JSON-shaped row from a future view.
  factory VaultDocument.fromJson(Map<String, dynamic> j) {
    return VaultDocument(
      id: (j['id'] ?? '') as String,
      fileName: (j['file_name'] ?? 'Document') as String,
      storagePath: (j['storage_path'] ?? '') as String,
      mimeType: (j['mime_type'] ?? '') as String,
      createdAt: DateTime.tryParse((j['created_at'] ?? '') as String) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      fileSizeBytes: j['file_size_bytes'] as int?,
      tagId: j['tag_id'] as String?,
      tagSlug: j['tag_slug'] as String?,
      tagLabel: j['tag_label'] as String?,
      encrypted: (j['encrypted'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'file_name': fileName,
        'storage_path': storagePath,
        'mime_type': mimeType,
        'created_at': createdAt.toIso8601String(),
        if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
        if (tagId != null) 'tag_id': tagId,
        if (tagSlug != null) 'tag_slug': tagSlug,
        if (tagLabel != null) 'tag_label': tagLabel,
        'encrypted': encrypted,
      };
}

/// A tag a user can attach to a vault document. The backend ships six
/// defaults; users may add their own later (out of scope here).
class VaultTag {
  const VaultTag({
    required this.id,
    required this.slug,
    required this.label,
  });

  final String id;
  final String slug;
  final String label;

  factory VaultTag.fromJson(Map<String, dynamic> j) => VaultTag(
        id: (j['id'] ?? '') as String,
        slug: (j['slug'] ?? '') as String,
        label: (j['label'] ?? '') as String,
      );

  /// Defaults shown when the backend has not (yet) populated `vault_tags`.
  /// Slug values are stable and used as the filter key on the chip row.
  static const List<VaultTag> defaults = <VaultTag>[
    VaultTag(id: 'contract', slug: 'contract', label: 'Contract'),
    VaultTag(id: 'receipt', slug: 'receipt', label: 'Receipt'),
    VaultTag(id: 'email', slug: 'email', label: 'Email'),
    VaultTag(id: 'evidence', slug: 'evidence', label: 'Evidence'),
    VaultTag(id: 'id_passport', slug: 'id_passport', label: 'ID/Passport'),
    VaultTag(id: 'other', slug: 'other', label: 'Other'),
  ];
}
