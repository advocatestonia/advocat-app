@Tags(['fast'])
library;

// =============================================================================
// Vision-path tests for ChatAttachmentService + AIService multimodal builder
// =============================================================================
//
// Regression coverage for the "AI asks for a photo but cannot analyze it"
// bug (2026-04-23). Before this fix images were uploaded to Supabase storage
// and the AI was told to call `read_document` — a text-only tool that
// returned OCR'd strings, which defeats the whole point of a photo. The fix
// sends the image to Claude as an inline multimodal content block.
//
// These tests lock in:
//   • ChatAttachment now carries the raw image bytes (and optional URL) and
//     exposes hasInlineImage.
//   • buildUserMessage for an image no longer mentions `read_document` — the
//     companion text tells the model to analyze the visual content directly.
//   • ChatAttachmentService.buildImageBlock returns an Anthropic image
//     content block with base64-encoded bytes and the right media type.
//   • AIService._maybeBuildMultimodalMessages swaps the last user message
//     for a content-block array with [image, text] blocks.
//   • PDF and plain-text attachments are UNCHANGED (no regression to
//     existing flows).
//   • Oversized images (> 5 MB) throw ChatAttachmentException with a clear
//     localized message rather than silently truncating.
//
// All tests are pure Dart — no Flutter bindings, no network, no Supabase.

import 'dart:convert';
import 'dart:typed_data';

import 'package:advocat/services/ai_service.dart';
import 'package:advocat/services/chat_attachment_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatAttachment — image payload carries bytes', () {
    test('image attachment preserves raw bytes and marks hasInlineImage', () async {
      final bytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]);
      final attachment = await ChatAttachmentService.build(
        fileName: 'summons.jpg',
        mimeType: 'image/jpeg',
        bytes: bytes,
        documentId: 'vault-123',
      );

      expect(attachment.kind, AttachmentKind.image);
      expect(attachment.imageBytes, bytes);
      expect(attachment.hasInlineImage, isTrue);
      // Vault id is still kept for persistence even though Claude reads
      // the visual data directly.
      expect(attachment.documentId, 'vault-123');
    });

    test('image attachment without bytes (defensive) is not inline-ready', () {
      const attachment = ChatAttachment(
        fileName: 'summons.jpg',
        mimeType: 'image/jpeg',
        kind: AttachmentKind.image,
        sizeBytes: 42,
      );
      expect(attachment.hasInlineImage, isFalse);
    });

    test('non-image attachments do not get imageBytes', () async {
      final pdf = await ChatAttachmentService.build(
        fileName: 'contract.pdf',
        mimeType: 'application/pdf',
        bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46]),
        documentId: 'pdf-1',
      );
      expect(pdf.imageBytes, isNull);
      expect(pdf.hasInlineImage, isFalse);

      final txt = await ChatAttachmentService.build(
        fileName: 'note.txt',
        mimeType: 'text/plain',
        bytes: Uint8List.fromList(utf8.encode('hello')),
      );
      expect(txt.imageBytes, isNull);
      expect(txt.hasInlineImage, isFalse);
    });
  });

  group('buildUserMessage — images must NOT reference read_document', () {
    test('image caption tells Claude to analyze visual content directly', () async {
      final attachment = await ChatAttachmentService.build(
        fileName: 'police_letter.jpg',
        mimeType: 'image/jpeg',
        bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]),
        documentId: 'img-7',
      );

      final msgEn = ChatAttachmentService.buildUserMessage(
        attachment: attachment,
        language: 'en',
      );
      expect(msgEn, contains('police_letter.jpg'));
      expect(msgEn.toLowerCase(), isNot(contains('read_document')));
      expect(msgEn.toLowerCase(), contains('visual'));

      final msgRu = ChatAttachmentService.buildUserMessage(
        attachment: attachment,
        language: 'ru',
      );
      expect(msgRu.toLowerCase(), isNot(contains('read_document')));
      expect(msgRu, contains('Проанализируй приложенное изображение'));

      final msgEt = ChatAttachmentService.buildUserMessage(
        attachment: attachment,
        language: 'et',
      );
      expect(msgEt.toLowerCase(), isNot(contains('read_document')));
      expect(msgEt.toLowerCase(), contains('visuaalsest'));
    });

    test('PDF caption still routes the model to read_document (not regressed)',
        () async {
      final pdf = await ChatAttachmentService.build(
        fileName: 'decision.pdf',
        mimeType: 'application/pdf',
        bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46]),
        documentId: 'pdf-abc',
      );
      final msg = ChatAttachmentService.buildUserMessage(
        attachment: pdf,
        language: 'en',
      );
      expect(msg.toLowerCase(), contains('read_document'));
      expect(msg, contains('pdf-abc'));
      expect(msg, contains('decision.pdf'));
    });

    test('plain-text caption inlines the body (not regressed)', () async {
      final txt = await ChatAttachmentService.build(
        fileName: 'memo.txt',
        mimeType: 'text/plain',
        bytes: Uint8List.fromList(utf8.encode('Clause 4 — deposit refund.')),
      );
      final msg = ChatAttachmentService.buildUserMessage(
        attachment: txt,
        language: 'en',
      );
      expect(msg, contains('memo.txt'));
      expect(msg, contains('Clause 4'));
      expect(msg.toLowerCase(), isNot(contains('read_document')));
    });
  });

  group('buildImageBlock — Anthropic content-block shape', () {
    test('produces a valid image block with base64 data and media type',
        () async {
      final bytes = Uint8List.fromList(List.generate(32, (i) => i));
      final attachment = await ChatAttachmentService.build(
        fileName: 'photo.png',
        mimeType: 'image/png',
        bytes: bytes,
      );

      final block = ChatAttachmentService.buildImageBlock(attachment);
      expect(block, isNotNull);
      expect(block!['type'], 'image');

      final source = block['source'] as Map<String, dynamic>;
      expect(source['type'], 'base64');
      expect(source['media_type'], 'image/png');
      expect(source['data'], base64Encode(bytes));
    });

    test('unsupported media types fall back to image/jpeg', () async {
      final bytes = Uint8List.fromList([0x00, 0x01, 0x02]);
      // HEIC is not on Anthropic's supported list — we remap.
      final attachment = await ChatAttachmentService.build(
        fileName: 'x.heic',
        mimeType: 'image/heic',
        bytes: bytes,
      );

      final block = ChatAttachmentService.buildImageBlock(attachment);
      expect(block, isNotNull);
      final source = block!['source'] as Map<String, dynamic>;
      expect(source['media_type'], 'image/jpeg');
    });

    test('returns null for non-image attachments', () async {
      final pdf = await ChatAttachmentService.build(
        fileName: 'c.pdf',
        mimeType: 'application/pdf',
        bytes: Uint8List.fromList([0x25, 0x50]),
        documentId: 'x',
      );
      expect(ChatAttachmentService.buildImageBlock(pdf), isNull);

      final txt = await ChatAttachmentService.build(
        fileName: 'n.txt',
        mimeType: 'text/plain',
        bytes: Uint8List.fromList(utf8.encode('x')),
      );
      expect(ChatAttachmentService.buildImageBlock(txt), isNull);
    });
  });

  group('Size limit — Claude rejects images > 5 MB', () {
    test('throws ChatAttachmentException for oversize image', () async {
      final huge = Uint8List(6 * 1024 * 1024); // 6 MB
      expect(
        () => ChatAttachmentService.build(
          fileName: 'big.jpg',
          mimeType: 'image/jpeg',
          bytes: huge,
        ),
        throwsA(isA<ChatAttachmentException>()
            .having((e) => e.code, 'code', 'image_too_large')),
      );
    });

    test('localized error message includes the 5 MB limit', () {
      final err = ChatAttachmentException.imageTooLarge(
        fileName: 'big.jpg',
        sizeBytes: 6 * 1024 * 1024,
        limitBytes: 5 * 1024 * 1024,
      );
      expect(err.localized('en').toLowerCase(), contains('5 mb'));
      expect(err.localized('ru'), contains('5 МБ'));
      expect(err.localized('et'), contains('5 MB'));
    });
  });

  group('AIService._maybeBuildMultimodalMessages', () {
    late AIService service;

    setUp(() {
      // No real Claude, no real quota — we only test the pure builder.
      service = AIService();
    });

    test('returns null when no image attachment is supplied', () {
      final result = service.buildMultimodalMessagesForTest(
        messages: [
          {'role': 'user', 'content': 'hello'},
        ],
        userMessage: 'hello',
        imageAttachment: null,
      );
      expect(result, isNull);
    });

    test('returns null when the attachment is not an image', () async {
      final pdf = await ChatAttachmentService.build(
        fileName: 'c.pdf',
        mimeType: 'application/pdf',
        bytes: Uint8List.fromList([0x25, 0x50]),
        documentId: 'x',
      );
      final result = service.buildMultimodalMessagesForTest(
        messages: [
          {'role': 'user', 'content': 'analyse this'},
        ],
        userMessage: 'analyse this',
        imageAttachment: pdf,
      );
      expect(result, isNull);
    });

    test('swaps the last user message for a content-block array', () async {
      final bytes = Uint8List.fromList(List.generate(16, (i) => i * 2));
      final image = await ChatAttachmentService.build(
        fileName: 'id.jpg',
        mimeType: 'image/jpeg',
        bytes: bytes,
      );

      final result = service.buildMultimodalMessagesForTest(
        messages: [
          {'role': 'user', 'content': 'previous turn'},
          {'role': 'assistant', 'content': 'earlier reply'},
          {'role': 'user', 'content': 'please look at this'},
        ],
        userMessage: 'please look at this',
        imageAttachment: image,
      );

      expect(result, isNotNull);
      expect(result!.length, 3);
      // First two turns kept verbatim as strings.
      expect(result[0]['content'], 'previous turn');
      expect(result[1]['content'], 'earlier reply');

      // Last turn is now a list of content blocks: [image, text].
      final lastContent = result[2]['content'];
      expect(lastContent, isA<List<dynamic>>());
      final blocks = lastContent as List<dynamic>;
      expect(blocks.length, 2);

      final imageBlock = blocks[0] as Map<String, dynamic>;
      expect(imageBlock['type'], 'image');
      final source = imageBlock['source'] as Map<String, dynamic>;
      expect(source['type'], 'base64');
      expect(source['media_type'], 'image/jpeg');
      expect(source['data'], base64Encode(bytes));

      final textBlock = blocks[1] as Map<String, dynamic>;
      expect(textBlock['type'], 'text');
      expect(textBlock['text'], contains('please look at this'));
      expect(textBlock['text'], contains('Проанализируй приложенное'));
    });

    test('falls back to Russian-only prompt when user message is empty',
        () async {
      final image = await ChatAttachmentService.build(
        fileName: 'x.png',
        mimeType: 'image/png',
        bytes: Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]),
      );

      final result = service.buildMultimodalMessagesForTest(
        messages: [
          {'role': 'user', 'content': ''},
        ],
        userMessage: '',
        imageAttachment: image,
      );
      expect(result, isNotNull);
      final blocks = result![0]['content'] as List<dynamic>;
      final textBlock = blocks[1] as Map<String, dynamic>;
      expect(textBlock['text'], 'Проанализируй приложенное изображение.');
    });
  });
}
