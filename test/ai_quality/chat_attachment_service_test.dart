// =============================================================================
// AI quality — ChatAttachmentService (Bug 1: file handling)
// =============================================================================
//
// Bug 1 from owner: when the user attaches a file to chat, the AI never sees
// the content — _pickAndAttachFile only sends a message "Document attached:
// foo.pdf" without any content. This test locks in the contract of
// ChatAttachmentService: given raw file bytes and a mime type, produce a
// ChatAttachment record the chat path can turn into a proper AI-visible
// message (embedded text for .txt, upload + read_document hint for binary).
//
// All tests are pure Dart — no Flutter bindings needed.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:advocat/services/chat_attachment_service.dart';

void main() {
  group('ChatAttachmentService.classify — mime + extension detection', () {
    test('plain txt → text kind', () {
      final cls = ChatAttachmentService.classify(
        fileName: 'note.txt',
        mimeType: 'text/plain',
      );
      expect(cls.kind, AttachmentKind.text);
      expect(cls.isSupported, isTrue);
    });

    test('PDF → pdf kind', () {
      final cls = ChatAttachmentService.classify(
        fileName: 'contract.pdf',
        mimeType: 'application/pdf',
      );
      expect(cls.kind, AttachmentKind.pdf);
      expect(cls.isSupported, isTrue);
    });

    test('JPG image → image kind', () {
      final cls = ChatAttachmentService.classify(
        fileName: 'photo.jpg',
        mimeType: 'image/jpeg',
      );
      expect(cls.kind, AttachmentKind.image);
      expect(cls.isSupported, isTrue);
    });

    test('unknown binary → unsupported', () {
      final cls = ChatAttachmentService.classify(
        fileName: 'foo.xyz',
        mimeType: 'application/octet-stream',
      );
      expect(cls.kind, AttachmentKind.unknown);
      expect(cls.isSupported, isFalse);
    });

    test('mime missing but extension is .txt → text', () {
      final cls = ChatAttachmentService.classify(
        fileName: 'note.txt',
        mimeType: null,
      );
      expect(cls.kind, AttachmentKind.text);
    });
  });

  group('ChatAttachmentService.buildUserMessage — txt inlined, binary hint', () {
    test('txt attachment → content inlined in the chat message', () async {
      final bytes = Uint8List.fromList(utf8.encode(
          'This is the contract body.\nClause 1 — payment due in 14 days.'));
      final attachment = await ChatAttachmentService.build(
        fileName: 'contract.txt',
        mimeType: 'text/plain',
        bytes: bytes,
      );

      expect(attachment.kind, AttachmentKind.text);
      expect(attachment.extractedText, contains('Clause 1'));

      final msg = ChatAttachmentService.buildUserMessage(
        attachment: attachment,
        language: 'en',
      );
      // AI must actually see the body, not just the file name.
      expect(msg, contains('contract.txt'));
      expect(msg, contains('Clause 1'));
      expect(msg.toLowerCase(), isNot(equals('document attached: contract.txt')));
    });

    test('PDF attachment → hints to use read_document tool', () async {
      final attachment = await ChatAttachmentService.build(
        fileName: 'decision.pdf',
        mimeType: 'application/pdf',
        bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46]),
        documentId: 'doc-abc-123',
      );

      expect(attachment.kind, AttachmentKind.pdf);
      expect(attachment.documentId, 'doc-abc-123');

      final msg = ChatAttachmentService.buildUserMessage(
        attachment: attachment,
        language: 'en',
      );
      expect(msg, contains('decision.pdf'));
      expect(msg, contains('doc-abc-123'));
      expect(msg.toLowerCase(), contains('read_document'));
    });

    test('image attachment with documentId → same read_document instruction',
        () async {
      final attachment = await ChatAttachmentService.build(
        fileName: 'summons.jpg',
        mimeType: 'image/jpeg',
        bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF]),
        documentId: 'img-9',
      );
      final msg = ChatAttachmentService.buildUserMessage(
        attachment: attachment,
        language: 'ru',
      );
      expect(msg, contains('summons.jpg'));
      expect(msg, contains('img-9'));
    });
  });

  group('ChatAttachmentService — size guard', () {
    test('txt over 200KB is truncated, note is added', () async {
      final big = 'x' * (300 * 1024);
      final attachment = await ChatAttachmentService.build(
        fileName: 'big.txt',
        mimeType: 'text/plain',
        bytes: Uint8List.fromList(utf8.encode(big)),
      );
      expect(attachment.extractedText, isNotNull);
      expect(attachment.extractedText!.length, lessThanOrEqualTo(200 * 1024));
      expect(attachment.wasTruncated, isTrue);
    });
  });
}
