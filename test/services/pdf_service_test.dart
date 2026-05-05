@Tags(['fast'])
library;

import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/services/pdf_service.dart';

/// TDD tests for [PdfService] — markdown → PDF rendering for legal documents.
///
/// These tests cover the deterministic pure-Dart parts:
///   • markdown line classification
///   • inline span tokenisation (bold/italic)
///   • disclaimer text resolution per language
///   • the renderer produces non-empty bytes for sample input
///
/// Tests deliberately avoid network: PdfService skips Google Font download
/// when [PdfService.disableNetworkFonts] is true (used in test mode).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfService.classifyLine', () {
    test('# heading is detected as h1', () {
      expect(
        PdfService.classifyLine('# Apellatsioonkaebus'),
        const PdfLine(kind: PdfLineKind.h1, text: 'Apellatsioonkaebus'),
      );
    });

    test('## heading is detected as h2', () {
      expect(
        PdfService.classifyLine('## Asjaolud'),
        const PdfLine(kind: PdfLineKind.h2, text: 'Asjaolud'),
      );
    });

    test('### heading is detected as h3', () {
      expect(
        PdfService.classifyLine('### Lisa 1'),
        const PdfLine(kind: PdfLineKind.h3, text: 'Lisa 1'),
      );
    });

    test('- bullet is detected', () {
      expect(
        PdfService.classifyLine('- esimene punkt'),
        const PdfLine(kind: PdfLineKind.bullet, text: 'esimene punkt'),
      );
    });

    test('* bullet variant is detected', () {
      expect(
        PdfService.classifyLine('* second item'),
        const PdfLine(kind: PdfLineKind.bullet, text: 'second item'),
      );
    });

    test('blank line is detected', () {
      expect(
        PdfService.classifyLine('   '),
        const PdfLine(kind: PdfLineKind.blank, text: ''),
      );
    });

    test('plain paragraph is the fallback', () {
      expect(
        PdfService.classifyLine('See on tavaline lõik teksti.'),
        const PdfLine(
          kind: PdfLineKind.paragraph,
          text: 'See on tavaline lõik teksti.',
        ),
      );
    });
  });

  group('PdfService.parseInlineSpans', () {
    test('plain text becomes a single non-bold span', () {
      final spans = PdfService.parseInlineSpans('plain text');
      expect(spans.length, 1);
      expect(spans[0].text, 'plain text');
      expect(spans[0].bold, isFalse);
    });

    test('**bold** is parsed into a bold span', () {
      final spans = PdfService.parseInlineSpans('hello **world** today');
      expect(spans.length, 3);
      expect(spans[0].text, 'hello ');
      expect(spans[0].bold, isFalse);
      expect(spans[1].text, 'world');
      expect(spans[1].bold, isTrue);
      expect(spans[2].text, ' today');
      expect(spans[2].bold, isFalse);
    });

    test('multiple **bold** runs are all detected', () {
      final spans = PdfService.parseInlineSpans('**a** and **b**');
      final bolds = spans.where((s) => s.bold).map((s) => s.text).toList();
      expect(bolds, ['a', 'b']);
    });

    test('unmatched ** is treated as literal text', () {
      final spans = PdfService.parseInlineSpans('a ** b');
      // No closing ** — treat the whole line as plain.
      expect(spans.length, 1);
      expect(spans[0].text, 'a ** b');
      expect(spans[0].bold, isFalse);
    });
  });

  group('PdfService.disclaimerFor', () {
    test('Estonian disclaimer mentions AI', () {
      final txt = PdfService.disclaimerFor('et');
      expect(txt.toLowerCase(), contains('ai'));
      expect(txt.toLowerCase(), contains('jurist'));
    });

    test('Russian disclaimer mentions ИИ', () {
      final txt = PdfService.disclaimerFor('ru');
      expect(txt, contains('ИИ'));
      expect(txt.toLowerCase(), contains('юрист'));
    });

    test('English disclaimer mentions AI and attorney', () {
      final txt = PdfService.disclaimerFor('en');
      expect(txt.toLowerCase(), contains('ai-generated'));
      expect(txt.toLowerCase(), contains('attorney'));
    });

    test('Unknown language falls back to English', () {
      final txt = PdfService.disclaimerFor('zz');
      expect(txt.toLowerCase(), contains('ai-generated'));
    });
  });

  group('PdfService.renderLegalDocument', () {
    late PdfService service;

    setUp(() {
      service = PdfService(disableNetworkFonts: true);
      // Stub the asset loader for the logo so tests don't touch real assets.
      ServicesBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (ByteData? message) async {
        // Returning null causes pdf to skip the logo (renderLegalDocument
        // wraps the asset load in try/catch and proceeds without logo).
        return null;
      });
    });

    test('renders empty markdown without crashing', () async {
      final bytes = await service.renderLegalDocument(
        markdown: '',
        title: 'Empty Doc',
        language: 'en',
      );
      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(500));
    });

    test('renders sample legal markdown to >1000 bytes', () async {
      const sample = '''
# Apellatsioonkaebus

## Asjaolud

See on **oluline** dokument. See sisaldab eesti tähti: ä õ ü ö.

- Esimene argument
- Teine argument
- Kolmas argument

## Nõuded

Tühistada otsus.
''';
      final bytes = await service.renderLegalDocument(
        markdown: sample,
        title: 'Apellatsioonkaebus',
        language: 'et',
        userName: 'Dmitri Sulga',
      );
      expect(bytes.length, greaterThan(1000));
      // PDF magic header starts with %PDF-
      expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
    });

    test('handles Cyrillic text in Russian draft', () async {
      const sample = '''
# Жалоба

## Описание

Я обжалую решение от **2026-05-01**.

- Пункт первый
- Пункт второй
''';
      final bytes = await service.renderLegalDocument(
        markdown: sample,
        title: 'Жалоба',
        language: 'ru',
      );
      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
    });
  });

  group('PdfService.looksLikeDraft', () {
    test('Estonian draft heading is recognised', () {
      expect(
        PdfService.looksLikeDraft('# Apellatsioonkaebus\n\nLugupeetud kohus'),
        isTrue,
      );
    });

    test('English appeal heading is recognised', () {
      expect(
        PdfService.looksLikeDraft('# Appeal\n\nDear Court'),
        isTrue,
      );
    });

    test('Russian жалоба heading is recognised', () {
      expect(
        PdfService.looksLikeDraft('# Жалоба\n\nУважаемый суд'),
        isTrue,
      );
    });

    test('Casual chat reply is NOT recognised as a draft', () {
      expect(
        PdfService.looksLikeDraft('Sure, here is what I think about your case.'),
        isFalse,
      );
    });

    test('Document-style reply with Lugupeetud is recognised', () {
      expect(
        PdfService.looksLikeDraft('Lugupeetud kohus,\n\nKäesolevaga esitan...'),
        isTrue,
      );
    });
  });
}
