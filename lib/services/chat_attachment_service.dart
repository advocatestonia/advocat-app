// =============================================================================
// ChatAttachmentService — turn a picked file into an AI-visible chat message
// =============================================================================
//
// Bug 1 from owner (fix/ai-quality): _pickAndAttachFile previously only sent
// "Document attached: foo.pdf" — the AI never saw the content. This service
// bridges the picked File → the chat path:
//
//   • .txt / plain text  → UTF-8 decoded, first 200 KB inlined into the
//     user message so Claude can reason about it directly.
//   • .pdf / .jpg / .png → caller is expected to upload the bytes via
//     SupabaseService.uploadDocument (or similar) and pass the resulting
//     document_id. We then build a message that names the file AND tells
//     the AI to call the existing read_document tool with that id, so the
//     AI actually retrieves the OCR/extracted text instead of guessing.
//   • unsupported        → user-facing explanation, no AI-visible payload.
//
// The service is pure Dart (no Flutter bindings) so it is easy to test.

import 'dart:convert';
import 'dart:typed_data';

/// The kind of attachment we detected.
enum AttachmentKind {
  text,    // plain-text, inlined directly into the chat message
  pdf,     // binary PDF — must be uploaded and fetched via read_document
  image,   // image — must be uploaded and fetched via read_document
  unknown, // unsupported
}

/// A processed chat attachment ready to be turned into a user message.
class ChatAttachment {
  /// Original file name (e.g. "contract.pdf").
  final String fileName;

  /// Detected mime type ("application/pdf", "image/jpeg", "text/plain", …).
  final String mimeType;

  /// What kind of payload this is.
  final AttachmentKind kind;

  /// Raw byte size before any truncation.
  final int sizeBytes;

  /// For [AttachmentKind.text] only — decoded (and possibly truncated) text
  /// that will be inlined in the chat message.
  final String? extractedText;

  /// For [AttachmentKind.pdf] / [AttachmentKind.image] only — id of the
  /// document after it was uploaded to the vault. When non-null, the message
  /// builder tells the AI to retrieve the content via the read_document tool
  /// (PDFs) or serves as vault persistence (images — vision path is inline).
  final String? documentId;

  /// Set to `true` when [extractedText] was shortened to fit the inlining
  /// budget. Useful for UI warnings / tests.
  final bool wasTruncated;

  /// For [AttachmentKind.image] only — raw image bytes preserved so the chat
  /// path can attach them inline as a multimodal content block to Claude
  /// (`read_document` returns TEXT, not visual data — an image must go in as
  /// a base64 image block, not as a tool call).
  final Uint8List? imageBytes;

  /// For [AttachmentKind.image] only — optional signed URL pointing at the
  /// uploaded vault copy. Reserved for future URL-based image blocks; the
  /// current client path relies on [imageBytes] and base64 encoding.
  final String? imageUrl;

  const ChatAttachment({
    required this.fileName,
    required this.mimeType,
    required this.kind,
    required this.sizeBytes,
    this.extractedText,
    this.documentId,
    this.wasTruncated = false,
    this.imageBytes,
    this.imageUrl,
  });

  /// Whether this attachment carries useful content for the AI.
  bool get isSupported => kind != AttachmentKind.unknown;

  /// Whether the attachment carries inline visual data for Claude's vision
  /// content block. True only for images with non-empty bytes.
  bool get hasInlineImage =>
      kind == AttachmentKind.image &&
      imageBytes != null &&
      imageBytes!.isNotEmpty;
}

/// Lightweight classification — just the mime/kind decision, no bytes needed.
class ChatAttachmentClassification {
  final AttachmentKind kind;
  final String resolvedMimeType;

  const ChatAttachmentClassification({
    required this.kind,
    required this.resolvedMimeType,
  });

  bool get isSupported => kind != AttachmentKind.unknown;
}

/// Core helper. Stateless, static methods only.
abstract final class ChatAttachmentService {
  /// Maximum size of inlined text content (in chars ≈ bytes for ASCII). Binary
  /// files exceeding this must be uploaded and read via the read_document
  /// tool — inlining megabytes of text into the prompt would blow the
  /// input-token budget and (worse) confuse the model.
  static const int maxInlineTextChars = 200 * 1024;

  /// Claude's per-image cap for the Messages API (base64 source). Images
  /// larger than this must be downsampled client-side or refused with a
  /// clear error — the API rejects oversize payloads with a 413-class error
  /// that is hard to recover from mid-chat.
  static const int maxInlineImageBytes = 5 * 1024 * 1024;

  /// File-extension → mime fallback table. Used when the platform file picker
  /// does not supply a mime type (common on web and older Android).
  static const Map<String, String> _extensionMime = {
    'txt': 'text/plain',
    'md': 'text/markdown',
    'csv': 'text/csv',
    'json': 'application/json',
    'pdf': 'application/pdf',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'heic': 'image/heic',
    'webp': 'image/webp',
    'doc': 'application/msword',
    'docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  };

  /// Decide what kind of attachment a file is based on its name and mime.
  /// Does not touch the bytes — useful for cheap pre-flight checks.
  static ChatAttachmentClassification classify({
    required String fileName,
    String? mimeType,
  }) {
    final resolved = mimeType != null && mimeType.isNotEmpty
        ? mimeType.toLowerCase()
        : _mimeFromExtension(fileName);

    if (resolved.startsWith('text/') ||
        resolved == 'application/json' ||
        resolved == 'application/xml') {
      return ChatAttachmentClassification(
        kind: AttachmentKind.text,
        resolvedMimeType: resolved,
      );
    }
    if (resolved == 'application/pdf') {
      return ChatAttachmentClassification(
        kind: AttachmentKind.pdf,
        resolvedMimeType: resolved,
      );
    }
    if (resolved.startsWith('image/')) {
      return ChatAttachmentClassification(
        kind: AttachmentKind.image,
        resolvedMimeType: resolved,
      );
    }
    return ChatAttachmentClassification(
      kind: AttachmentKind.unknown,
      resolvedMimeType: resolved,
    );
  }

  /// Take a picked file's bytes and produce a [ChatAttachment] ready for the
  /// chat pipeline. Pure, no I/O — caller must already have the bytes.
  ///
  /// For PDF attachments the caller should first upload the bytes to Supabase
  /// and pass the resulting [documentId] here so we can bake the id into the
  /// AI-visible message (the PDF path still uses read_document for OCR).
  ///
  /// For image attachments we ALSO keep [bytes] on the returned attachment so
  /// the chat path can forward them to Claude inline as a base64 vision
  /// block — read_document only returns TEXT, which is useless for a photo.
  /// The [documentId] is kept for vault persistence but the visual channel
  /// is the authoritative source for analysis.
  ///
  /// Throws [ChatAttachmentException] if an image is larger than
  /// [maxInlineImageBytes] — we surface a clear error rather than silently
  /// truncating visual data, which would be worse than not analysing it.
  static Future<ChatAttachment> build({
    required String fileName,
    String? mimeType,
    required Uint8List bytes,
    String? documentId,
    String? imageUrl,
  }) async {
    final cls = classify(fileName: fileName, mimeType: mimeType);
    final size = bytes.length;

    if (cls.kind == AttachmentKind.text) {
      String text;
      try {
        text = utf8.decode(bytes, allowMalformed: true);
      } catch (_) {
        text = '';
      }
      var truncated = false;
      if (text.length > maxInlineTextChars) {
        text = text.substring(0, maxInlineTextChars);
        truncated = true;
      }
      return ChatAttachment(
        fileName: fileName,
        mimeType: cls.resolvedMimeType,
        kind: AttachmentKind.text,
        sizeBytes: size,
        extractedText: text,
        wasTruncated: truncated,
      );
    }

    if (cls.kind == AttachmentKind.image) {
      if (size > maxInlineImageBytes) {
        throw ChatAttachmentException.imageTooLarge(
          fileName: fileName,
          sizeBytes: size,
          limitBytes: maxInlineImageBytes,
        );
      }
      return ChatAttachment(
        fileName: fileName,
        mimeType: cls.resolvedMimeType,
        kind: AttachmentKind.image,
        sizeBytes: size,
        documentId: documentId,
        imageBytes: bytes,
        imageUrl: imageUrl,
      );
    }

    return ChatAttachment(
      fileName: fileName,
      mimeType: cls.resolvedMimeType,
      kind: cls.kind,
      sizeBytes: size,
      documentId: documentId,
    );
  }

  /// Build the user-visible chat message that will also be forwarded to the
  /// AI. For .txt we inline the body; for binary we name the file and tell
  /// the AI to retrieve content via the `read_document` tool.
  static String buildUserMessage({
    required ChatAttachment attachment,
    required String language,
  }) {
    final sizeKb = (attachment.sizeBytes / 1024).round();

    switch (attachment.kind) {
      case AttachmentKind.text:
        final body = attachment.extractedText ?? '';
        final header = _localize(
          language,
          et: 'Lisasin teksti "${attachment.fileName}" ($sizeKb KB). '
              'Sisu on allpool — palun analüüsi seda.',
          en: 'I attached a text file "${attachment.fileName}" ($sizeKb KB). '
              'Content is below — please analyze it.',
          ru: 'Прикрепил текстовый файл «${attachment.fileName}» ($sizeKb КБ). '
              'Содержимое ниже — проанализируй его, пожалуйста.',
        );
        final truncNote = attachment.wasTruncated
            ? '\n\n${_localize(
                language,
                et: '(Näidatud on esimesed 200 KB teksti.)',
                en: '(Showing first 200 KB of text.)',
                ru: '(Показаны первые 200 КБ текста.)',
              )}'
            : '';
        return '$header\n\n---\n$body\n---$truncNote';

      case AttachmentKind.pdf:
        final pdfIdSuffix = attachment.documentId != null
            ? ' (document_id=${attachment.documentId})'
            : '';
        if (attachment.documentId != null) {
          return _localize(
            language,
            et: 'Lisasin PDFi "${attachment.fileName}"$pdfIdSuffix. '
                'Kasuta tööriista read_document document_id-ga '
                '"${attachment.documentId}", et lugeda täistekst, ja analüüsi seda.',
            en: 'I attached a PDF "${attachment.fileName}"$pdfIdSuffix. '
                'Use the read_document tool with document_id '
                '"${attachment.documentId}" to fetch the full text and analyze it.',
            ru: 'Прикрепил PDF «${attachment.fileName}»$pdfIdSuffix. '
                'Используй инструмент read_document с document_id '
                '"${attachment.documentId}", чтобы получить полный текст, '
                'и проанализируй его.',
          );
        }
        return _localize(
          language,
          et: 'Üritasin lisada PDF-faili "${attachment.fileName}", '
              'kuid üleslaadimine ebaõnnestus. Palun kasuta skaneerimise '
              'ekraani, et fail hoidlasse lisada.',
          en: 'I tried to attach PDF "${attachment.fileName}", but the '
              'upload failed. Please use the scan screen to add the file to '
              'your vault first.',
          ru: 'Попытался прикрепить PDF «${attachment.fileName}», но '
              'загрузка не удалась. Воспользуйся экраном сканирования, чтобы '
              'добавить файл в хранилище.',
        );

      case AttachmentKind.image:
        // Images are sent to Claude as inline visual content blocks — see
        // ChatAttachment.imageBytes and ai_service.dart's _buildImageMessage.
        // The text we return here accompanies that visual block so the model
        // knows what to do with the picture. DO NOT reference read_document
        // here: read_document returns plain text and would make Claude fetch
        // textual OCR for a file it is already seeing visually.
        if (attachment.hasInlineImage) {
          return _localize(
            language,
            et: 'Lisasin pildi "${attachment.fileName}" ($sizeKb KB). '
                'Analüüsi seda otse lisatud visuaalsest sisust — see on '
                'ette antud kui pildiplokk.',
            en: 'I attached an image "${attachment.fileName}" ($sizeKb KB). '
                'Analyze it directly from the visual content provided — '
                'it is attached as an image block.',
            ru: 'Прикрепил изображение «${attachment.fileName}» ($sizeKb КБ). '
                'Проанализируй приложенное изображение напрямую — оно '
                'передано как visual content.',
          );
        }
        // Upload failed and no inline bytes — fall back to a clear error so
        // the user knows the image will NOT be analysed this turn.
        return _localize(
          language,
          et: 'Üritasin lisada pildi "${attachment.fileName}", kuid '
              'üleslaadimine ebaõnnestus. Palun proovi uuesti.',
          en: 'I tried to attach an image "${attachment.fileName}", but the '
              'upload failed. Please try again.',
          ru: 'Попытался прикрепить изображение «${attachment.fileName}», но '
              'загрузка не удалась. Попробуй ещё раз.',
        );

      case AttachmentKind.unknown:
        return _localize(
          language,
          et: 'Fail "${attachment.fileName}" pole toetatud — palun lae üles '
              'PDF, pilt või tekst.',
          en: 'File "${attachment.fileName}" is not supported — please upload '
              'a PDF, image, or text file.',
          ru: 'Файл «${attachment.fileName}» не поддерживается — загрузи PDF, '
              'изображение или текст.',
        );
    }
  }

  /// Build the Anthropic Messages-API image content block for an image
  /// attachment. Returns `null` for non-image attachments or when the bytes
  /// are missing (upload-only case).
  ///
  /// Anthropic accepts media types: image/jpeg, image/png, image/gif,
  /// image/webp. HEIC is not on the supported list — we map HEIC to JPEG
  /// at the media-type level so the model at least sees something; the
  /// actual byte decode is the server's problem. In practice the client
  /// should convert HEIC before reaching this point, but we are defensive.
  static Map<String, dynamic>? buildImageBlock(ChatAttachment attachment) {
    if (!attachment.hasInlineImage) return null;
    final data = base64Encode(attachment.imageBytes!);
    final mt = attachment.mimeType.toLowerCase();
    const supported = {'image/jpeg', 'image/png', 'image/gif', 'image/webp'};
    final mediaType = supported.contains(mt) ? mt : 'image/jpeg';
    return {
      'type': 'image',
      'source': {
        'type': 'base64',
        'media_type': mediaType,
        'data': data,
      },
    };
  }

  // -- internals --------------------------------------------------------------

  static String _mimeFromExtension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) {
      return 'application/octet-stream';
    }
    final ext = fileName.substring(dot + 1).toLowerCase();
    return _extensionMime[ext] ?? 'application/octet-stream';
  }

  static String _localize(
    String language, {
    required String et,
    required String en,
    required String ru,
  }) {
    switch (language) {
      case 'et':
        return et;
      case 'ru':
        return ru;
      default:
        return en;
    }
  }
}

/// Thrown when an attachment cannot be built for Claude — most commonly an
/// image that exceeds the Messages-API inline size cap.
class ChatAttachmentException implements Exception {
  final String message;
  final String code;

  const ChatAttachmentException(this.message, {this.code = 'attachment_error'});

  factory ChatAttachmentException.imageTooLarge({
    required String fileName,
    required int sizeBytes,
    required int limitBytes,
  }) {
    final sizeMb = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
    final limitMb = (limitBytes / (1024 * 1024)).round();
    return ChatAttachmentException(
      'Image "$fileName" is $sizeMb MB; maximum inline size is $limitMb MB. '
      'Please resize or upload a smaller image.',
      code: 'image_too_large',
    );
  }

  /// User-facing, localized explanation for the UI to show.
  String localized(String language) {
    if (code == 'image_too_large') {
      switch (language) {
        case 'et':
          return 'Pilt on liiga suur. Maksimaalne suurus on 5 MB.';
        case 'ru':
          return 'Изображение слишком большое. Максимум 5 МБ.';
        default:
          return 'The image is too large. Maximum size is 5 MB.';
      }
    }
    return message;
  }

  @override
  String toString() => 'ChatAttachmentException($code): $message';
}
