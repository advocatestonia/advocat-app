// Regression for parseRichBlocks — the structural parser behind every AI
// chat message. Extracted from rich_message.dart (was a private _parseBlocks
// inside the widget, untestable). A misparse is user-visible: a table
// collapsing into garbage paragraphs, a dropped bullet, a numbered item
// losing its number, or a multi-line quote splitting apart.

import 'package:advocat/features/chat/widgets/rich_message_blocks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseRichBlocks — line classification', () {
    test('empty input → no blocks', () {
      expect(parseRichBlocks(''), hasLength(1)); // single empty line
      expect(parseRichBlocks('').single.type, RichBlockType.empty);
    });

    test('## and # headers strip their marker', () {
      final b = parseRichBlocks('## Big\n# Small');
      expect(b.map((x) => x.type), [RichBlockType.header, RichBlockType.header]);
      expect(b[0].content, 'Big');
      expect(b[1].content, 'Small');
    });

    test('"## " is a header, not a "# " header (longest-prefix wins)', () {
      final b = parseRichBlocks('## Section');
      expect(b.single.type, RichBlockType.header);
      expect(b.single.content, 'Section', reason: 'only "## " stripped, not "# # "');
    });

    test('dividers: ---, ___, *** (3+ chars)', () {
      for (final d in ['---', '___', '***', '------']) {
        expect(parseRichBlocks(d).single.type, RichBlockType.divider,
            reason: '"$d" should be a divider');
      }
      // 2 chars is NOT a divider
      expect(parseRichBlocks('--').single.type, RichBlockType.paragraph);
    });

    test('bullets: "- " and the bullet char "\u2022 "', () {
      final b = parseRichBlocks('- first\n\u2022 second');
      expect(b.map((x) => x.type),
          [RichBlockType.bullet, RichBlockType.bullet]);
      expect(b[0].content, 'first');
      expect(b[1].content, 'second');
    });

    test('numbered list captures number + content', () {
      final b = parseRichBlocks('1. alpha\n2. beta\n10. later');
      expect(b.every((x) => x.type == RichBlockType.numbered), isTrue);
      expect(b.map((x) => x.number), [1, 2, 10]);
      expect(b.map((x) => x.content), ['alpha', 'beta', 'later']);
    });

    test('plain text → paragraph', () {
      final b = parseRichBlocks('Just a sentence.');
      expect(b.single.type, RichBlockType.paragraph);
      expect(b.single.content, 'Just a sentence.');
    });
  });

  group('parseRichBlocks — multi-line collectors', () {
    test('consecutive quote lines merge into ONE quote block with newlines', () {
      final b = parseRichBlocks('> line one\n> line two\nafter');
      expect(b[0].type, RichBlockType.quote);
      expect(b[0].content, 'line one\nline two');
      expect(b[1].type, RichBlockType.paragraph);
      expect(b[1].content, 'after');
    });

    test('table groups consecutive pipe rows into one block, splits cells', () {
      final b = parseRichBlocks(
        '| Col A | Col B |\n| 1 | 2 |\nplain after',
      );
      expect(b[0].type, RichBlockType.table);
      expect(b[0].rows, [
        ['Col A', 'Col B'],
        ['1', '2'],
      ]);
      expect(b[1].type, RichBlockType.paragraph,
          reason: 'table collection stops at the first non-pipe line');
    });

    test('a single pipe is NOT a table (needs >= 2 pipes)', () {
      final b = parseRichBlocks('a | b');
      expect(b.single.type, RichBlockType.paragraph,
          reason: 'one pipe = ordinary text, not a table row');
    });
  });

  group('parseRichBlocks — ordering + mixed document', () {
    test('preserves block order across a realistic mixed message', () {
      const msg = '## Summary\n'
          'Intro paragraph.\n'
          '\n'
          '- bullet a\n'
          '- bullet b\n'
          '1. step one\n'
          '> a quote\n'
          '---\n'
          '| H1 | H2 |\n'
          '| x | y |';
      final types = parseRichBlocks(msg).map((b) => b.type).toList();
      expect(types, [
        RichBlockType.header,
        RichBlockType.paragraph,
        RichBlockType.empty,
        RichBlockType.bullet,
        RichBlockType.bullet,
        RichBlockType.numbered,
        RichBlockType.quote,
        RichBlockType.divider,
        RichBlockType.table,
      ]);
    });
  });
}
