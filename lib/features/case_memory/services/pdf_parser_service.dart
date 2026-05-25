// =====================================================================
// PdfParserService — Pkg 2 of Case Memory rebuild.
//
// Client side of the `pdf-parser` Edge Function. Two-step flow:
//   1. Upload PDF bytes to Supabase Storage at:
//        case-documents/<user_id>/<case_id_or_general>/<filename>
//   2. POST {storage_path, case_id, mime_type, filename} to pdf-parser.
//
// On success, invalidates the Riverpod providers backing the case detail
// + list screens so the parsed doc shows up immediately.
//
// Hard guarantees:
//   * Returns a typed result, NEVER throws — chat / detail screens render
//     the error inline.
//   * Active-case auto-attach: when [activeCaseId] is provided, the doc
//     is linked at parse time. When null, server returns the parsed
//     result without writing a row; client banner asks the user to pick
//     a case.
//   * Demo-mode: a synthetic stub result is returned without network.
// =====================================================================

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';
import '../state/cases_list_provider.dart';

/// Riverpod DI. Tests override the underlying [SupabaseService] +
/// optionally a fake [PdfStorageUploader].
final pdfParserServiceProvider = Provider<PdfParserService>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return PdfParserService(supabase: supabase, ref: ref);
});

// =====================================================================
// Result types
// =====================================================================

/// Sealed result of [PdfParserService.uploadAndParse]. The chat /
/// detail screen pattern-matches on the `kind` to decide what to show.
sealed class ParsedDocumentResult {
  const ParsedDocumentResult();

  /// Convenience for `result.kind == 'parsed'` checks in tests.
  String get kind;
}

/// Happy path. [documentId] is empty when [caseId] was null at upload AND
/// no soft-case shell could be created (e.g. anonymous visitor) — the
/// server intentionally did NOT write a row, the chat client must re-call
/// [PdfParserService.attachToCase] once the user picks a case.
///
/// [softCaseId] is non-null when the service auto-materialised a soft
/// shell case for a first-touch authenticated user. The UI should show a
/// one-line "We created 'Untitled case' to track this. Tap to rename."
/// banner that deep-links to the case-rename screen for [softCaseId].
final class ParsedOk extends ParsedDocumentResult {
  const ParsedOk({
    required this.documentId,
    required this.docType,
    required this.parsedSummary,
    required this.keyExtractions,
    required this.pageCount,
    required this.langDetected,
    this.softCaseId,
  });

  final String documentId;
  final String docType;
  final String parsedSummary;
  final Map<String, dynamic> keyExtractions;
  final int pageCount;
  final List<String> langDetected;

  /// Non-null when a soft-case shell was auto-created for a first-touch
  /// upload (caller passed activeCaseId=null but was authenticated).
  /// The UI shows a rename-banner for this id; if the user dismisses the
  /// banner the case stays as "Untitled case YYYY-MM-DD" — still
  /// idempotent: a future first-touch upload by the same user reuses
  /// the same shell instead of stacking duplicates.
  final String? softCaseId;

  @override
  String get kind => 'parsed';
}

/// Document had >100 pages — server saved nothing. [parsedPages] is the
/// truncation point (always 100 in current build).
final class ParsedTooLong extends ParsedDocumentResult {
  const ParsedTooLong({required this.parsedPages});
  final int parsedPages;
  @override
  String get kind => 'too_long';
}

/// Scanned PDF with no text layer AND >25 pages — Vision OCR cap was
/// hit, server saved nothing. UI should suggest splitting the doc.
final class ParsedScanTooLong extends ParsedDocumentResult {
  const ParsedScanTooLong({required this.suggestion});
  final String suggestion;
  @override
  String get kind => 'scan_too_long';
}

/// Doc had no readable text after both extraction + OCR — saved nothing.
final class ParsedUnreadable extends ParsedDocumentResult {
  const ParsedUnreadable({required this.suggestion});
  final String suggestion;
  @override
  String get kind => 'unreadable';
}

/// Network / upload / 5xx / quota error. UI shows a "try again" toast.
final class ParsedNetworkError extends ParsedDocumentResult {
  const ParsedNetworkError({required this.message});
  final String message;
  @override
  String get kind => 'network_error';
}

/// 401 / 403 — caller is not authenticated or path is mis-scoped.
final class ParsedForbidden extends ParsedDocumentResult {
  const ParsedForbidden({required this.message});
  final String message;
  @override
  String get kind => 'forbidden';
}

/// Demo mode — Edge Functions not reachable. UI shows a stub doc.
final class ParsedDemo extends ParsedDocumentResult {
  const ParsedDemo();
  @override
  String get kind => 'demo';
}

/// Caller passed empty bytes / empty filename / non-pdf mime / invalid
/// case id. We never POST in this case.
final class ParsedInvalidInput extends ParsedDocumentResult {
  const ParsedInvalidInput({required this.message});
  final String message;
  @override
  String get kind => 'invalid_input';
}

// =====================================================================
// Storage uploader — injectable seam for tests.
// =====================================================================

/// Function shape: upload bytes to bucket+path; returns nothing on success
/// or throws on any storage error (caught + mapped by the service).
typedef PdfStorageUploader = Future<void> Function({
  required String bucket,
  required String path,
  required Uint8List bytes,
  required String contentType,
});

/// Default uploader: write to the `case-documents` bucket using the live
/// Supabase client. Replaced in tests via the constructor seam.
Future<void> _defaultUploader({
  required String bucket,
  required String path,
  required Uint8List bytes,
  required String contentType,
}) async {
  final client = Supabase.instance.client;
  await client.storage.from(bucket).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: contentType, upsert: true),
      );
}

// =====================================================================
// Service
// =====================================================================

class PdfParserService {
  PdfParserService({
    required SupabaseService supabase,
    required Ref ref,
    PdfStorageUploader? uploader,
  })  : _supabase = supabase,
        _ref = ref,
        _uploader = uploader ?? _defaultUploader;

  /// Test-only constructor — see `pdf_parser_service_test.dart`. Real
  /// callers go through [pdfParserServiceProvider].
  @visibleForTesting
  PdfParserService.forTest({
    required SupabaseService supabase,
    Ref? ref,
    PdfStorageUploader? uploader,
  })  : _supabase = supabase,
        _ref = ref,
        _uploader = uploader ?? _defaultUploader;

  final SupabaseService _supabase;
  final Ref? _ref;
  final PdfStorageUploader _uploader;

  /// Edge Function name. Exposed for tests / observability.
  static const String endpoint = 'pdf-parser';

  /// Storage bucket. Mirrors the server-side [STORAGE_BUCKET] in
  /// `pdf-parser/index.ts`.
  static const String storageBucket = 'case-documents';

  /// 50 MB hard cap — mirrors the server-side cap in `pdf-parser/index.ts`.
  static const int maxBytes = 50 * 1024 * 1024;

  /// 10 MB hard cap for image uploads — mirrors `MAX_IMAGE_BYTES` in
  /// `pdf-parser/index.ts`. Phone-camera snaps are 2-6 MB; HEIC originals
  /// can run a little larger. Anything above is almost certainly not a
  /// document scan.
  static const int maxImageBytes = 10 * 1024 * 1024;

  /// Supported image MIME types. Mirrors `SUPPORTED_IMAGE_MIME_TYPES` in
  /// `supabase/functions/pdf-parser/helpers.ts`. Phone-snap UX path:
  /// JPEG/HEIC/HEIF from iOS, PNG from screenshots, WebP from share
  /// sheets. We accept all four and let the edge function normalize.
  static const Set<String> supportedImageMimeTypes = {
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/heic',
    'image/heif',
    'image/webp',
  };

  /// Returns true if [mime] is one of [supportedImageMimeTypes].
  static bool isImageMime(String mime) =>
      supportedImageMimeTypes.contains(mime.trim().toLowerCase());

  /// Returns true if [mime] is application/pdf.
  static bool isPdfMime(String mime) =>
      mime.trim().toLowerCase() == 'application/pdf';

  /// UUID v4 (mixed case). Strict — matches server validator.
  static final RegExp _uuidRe = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Upload + parse. [activeCaseId] auto-attaches the doc to that case;
  /// pass `null` when the user is in "general chat" mode — the server
  /// will return the parsed result without persisting a row, and the
  /// chat UI then prompts the user to attach.
  ///
  /// [onProgress] receives values in [0.0, 1.0]. We can only emit two
  /// stable points without server-sent events: 0.5 after upload, 1.0
  /// after parse. Tests assert both fire.
  Future<ParsedDocumentResult> uploadAndParse({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    String? activeCaseId,
    void Function(double progress)? onProgress,
  }) async {
    // ── Input validation ──────────────────────────────────────────────
    if (bytes.isEmpty) {
      return const ParsedInvalidInput(message: 'empty bytes');
    }
    if (filename.trim().isEmpty) {
      return const ParsedInvalidInput(message: 'empty filename');
    }

    // Normalize mime — accept PDF or any supported image MIME.
    // Phone-snap UX: user takes a JPEG of a paper letter, app uploads
    // it to the same pdf-parser pipeline (Vision OCR + Sonnet structured
    // extraction). We canonicalize image/jpg → image/jpeg so the edge
    // function sees one spelling.
    final mimeLc = mimeType.trim().toLowerCase();
    final bool isImage = isImageMime(mimeLc);
    final bool isPdf = isPdfMime(mimeLc);
    if (!isImage && !isPdf) {
      return ParsedInvalidInput(
        message: 'mime $mimeType is not application/pdf or a supported image',
      );
    }
    final String canonicalMime = isImage
        ? (mimeLc == 'image/jpg' ? 'image/jpeg' : mimeLc)
        : 'application/pdf';

    // Per-format size cap. Images are 10 MB (phone snaps); PDFs are 50 MB.
    final int sizeCap = isImage ? maxImageBytes : maxBytes;
    if (bytes.length > sizeCap) {
      return ParsedInvalidInput(
        message: isImage
            ? 'Image too large (max 10 MB, got ${bytes.length} bytes)'
            : 'PDF too large (max 50 MB, got ${bytes.length} bytes)',
      );
    }

    if (activeCaseId != null && !_uuidRe.hasMatch(activeCaseId)) {
      return ParsedInvalidInput(message: 'case_id is not a UUID: $activeCaseId');
    }

    if (_supabase.isDemo) return const ParsedDemo();

    final userId = _supabase.currentUserId;
    if (userId == null) {
      return const ParsedForbidden(message: 'not authenticated');
    }

    // ── 0. Soft-case shell — first-touch upload protection ────────────
    //
    // Bug context (P0): when activeCaseId was null we used to forward
    // case_id=null to pdf-parser, which intentionally skipped the
    // case_documents insert. Without a case_documents row, the post-parse
    // handoff to deadline-extractor never fired and the appeal deadline
    // (e.g. 10 days on a käännytyspäätös) vanished.
    //
    // Fix: ask the DB for the user's soft-shell case via an idempotent
    // RPC, then forward that id as case_id so the full deadline pipeline
    // runs as it would for any other case. If the RPC fails (legacy DB,
    // RLS, network), fall back to the old null path so we never block
    // the upload.
    String? effectiveCaseId = activeCaseId;
    String? softCaseId;
    if (activeCaseId == null) {
      // Defence-in-depth: production SupabaseService.ensureSoftCaseForUser
      // already catches RPC errors and returns null, but we wrap a second
      // try here so a buggy fake or future implementation can't crash
      // the upload pipeline. uploadAndParse is contractually non-throwing.
      String? shellId;
      try {
        shellId = await _supabase.ensureSoftCaseForUser();
      } catch (_) {
        shellId = null;
      }
      if (shellId != null && _uuidRe.hasMatch(shellId)) {
        effectiveCaseId = shellId;
        softCaseId = shellId;
      }
    }

    // ── 1. Upload to Storage ──────────────────────────────────────────
    // Use the effective case_id in the storage path so the file lands
    // under the shell case folder (matching the regular case path
    // shape <userId>/<caseId>/<filename>). When even the shell could
    // not be created we keep the legacy "general" segment.
    final caseSegment = effectiveCaseId ?? 'general';
    final safeName = _sanitizeFilename(filename);
    final storagePath = '$userId/$caseSegment/$safeName';

    try {
      await _uploader(
        bucket: storageBucket,
        path: storagePath,
        bytes: bytes,
        contentType: canonicalMime,
      );
    } catch (e) {
      return ParsedNetworkError(message: 'upload failed: $e');
    }
    onProgress?.call(0.5);

    // ── 2. Call Edge Function ─────────────────────────────────────────
    final body = <String, dynamic>{
      'storage_path': storagePath,
      'case_id': effectiveCaseId,
      'mime_type': canonicalMime,
      'filename': safeName,
    };

    Map<String, dynamic>? response;
    try {
      response = await _supabase.callEdgeFunction(endpoint, body: body);
    } catch (e) {
      return ParsedNetworkError(message: 'edge call threw: $e');
    }
    onProgress?.call(1.0);

    if (response == null) {
      return const ParsedNetworkError(message: 'no response from pdf-parser');
    }

    // ── 3. Map response shape to typed result ─────────────────────────
    final err = response['error'];
    if (err is String) {
      final lc = err.toLowerCase();
      if (err == 'too_long') {
        final pp = response['parsed_pages'];
        return ParsedTooLong(parsedPages: pp is num ? pp.toInt() : 0);
      }
      if (err == 'scan_too_long') {
        final s = response['suggestion'];
        return ParsedScanTooLong(
          suggestion: s is String ? s : 'document is too long for OCR',
        );
      }
      if (err == 'unreadable') {
        final s = response['suggestion'];
        return ParsedUnreadable(
          suggestion: s is String ? s : 'document was not readable',
        );
      }
      if (lc.contains('unauthorized') ||
          lc.contains('invalid session') ||
          lc.contains('forbidden')) {
        return ParsedForbidden(message: err);
      }
      return ParsedNetworkError(message: err);
    }

    final docId = (response['document_id'] as String?) ?? '';
    final docType = (response['doc_type'] as String?) ?? 'other';
    final parsedSummary = (response['parsed_summary'] as String?) ?? '';
    final keyExtractions = response['key_extractions'] is Map
        ? Map<String, dynamic>.from(response['key_extractions'] as Map)
        : <String, dynamic>{};
    final pageCount = (response['page_count'] as num?)?.toInt() ?? 0;
    final langRaw = response['lang_detected'];
    final langDetected = langRaw is List
        ? langRaw.whereType<String>().toList(growable: false)
        : const <String>[];

    final result = ParsedOk(
      documentId: docId,
      docType: docType,
      parsedSummary: parsedSummary,
      keyExtractions: keyExtractions,
      pageCount: pageCount,
      langDetected: langDetected,
      softCaseId: softCaseId,
    );

    // Invalidate providers for whichever case actually owns the row —
    // user-picked case OR auto-created soft shell. Without this, the
    // case-list screen would not pick up the brand-new shell row until
    // the next manual refresh.
    final invalidateId = effectiveCaseId;
    if (invalidateId != null && docId.isNotEmpty) {
      _invalidateProviders(invalidateId);
    }
    return result;
  }

  /// Sanitize a user-supplied filename for Storage. Strips any path
  /// separators (Storage rejects `..` anyway, but we strip them here so
  /// clients don't see a server-side error). Spaces → `_`. Unicode is
  /// preserved — Supabase Storage handles UTF-8 in keys.
  static String _sanitizeFilename(String name) {
    var cleaned = name.replaceAll(RegExp(r'[\\/]+'), '_');
    cleaned = cleaned.replaceAll('..', '_');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), '_');
    if (cleaned.length > 200) {
      cleaned = cleaned.substring(0, 200);
    }
    return cleaned.isEmpty ? 'upload.pdf' : cleaned;
  }

  void _invalidateProviders(String caseId) {
    final ref = _ref;
    if (ref == null) return;
    try {
      ref.invalidate(caseByIdProvider(caseId));
      ref.invalidate(casesListProvider);
    } catch (_) {
      // Disposed scope or test container — never bubble.
    }
  }
}
