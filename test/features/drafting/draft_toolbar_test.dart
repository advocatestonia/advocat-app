@Tags(['fast'])
library;

// Unit + widget tests for DraftToolbar (Pkg 7 Drafting Studio MVP).
// -----------------------------------------------------------------------------
// Focuses on the pure `applyFormat` helper (12 cases) and the toolbar widget's
// callback contract (3 cases).
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/drafting/widgets/draft_toolbar.dart';

void main() {
  group('applyFormat — bold', () {
    test('wraps selection with **', () {
      final r = applyFormat(DraftFormatOp.bold, 'one two three', 4, 7);
      expect(r.text, 'one **two** three');
      expect(r.selectionStart, 6);
      expect(r.selectionEnd, 9);
    });

    test('inserts placeholder when no selection', () {
      final r = applyFormat(DraftFormatOp.bold, 'one ', 4, 4);
      expect(r.text, 'one **bold**');
      expect(r.selectionStart, 6);
      expect(r.selectionEnd, 10);
    });
  });

  group('applyFormat — italic', () {
    test('wraps selection with *', () {
      final r = applyFormat(DraftFormatOp.italic, 'aa bb cc', 3, 5);
      expect(r.text, 'aa *bb* cc');
    });

    test('inserts placeholder when no selection', () {
      final r = applyFormat(DraftFormatOp.italic, '', 0, 0);
      expect(r.text, '*italic*');
    });
  });

  group('applyFormat — heading', () {
    test('prefixes line with "## "', () {
      final r = applyFormat(DraftFormatOp.heading, 'Hello', 0, 5);
      expect(r.text, '## Hello');
      expect(r.selectionStart, 3);
      expect(r.selectionEnd, 8);
    });

    test('respects newlines when finding line start', () {
      final r = applyFormat(DraftFormatOp.heading, 'first\nsecond', 8, 10);
      expect(r.text, 'first\n## second');
    });
  });

  group('applyFormat — bullet', () {
    test('prefixes line with "- "', () {
      final r = applyFormat(DraftFormatOp.bullet, 'item', 0, 0);
      expect(r.text, '- item');
    });

    test('honours mid-line position by going to line start', () {
      final r = applyFormat(DraftFormatOp.bullet, 'line1\nline2', 7, 7);
      expect(r.text, 'line1\n- line2');
    });
  });

  group('applyFormat — numbered', () {
    test('prefixes line with "1. "', () {
      final r = applyFormat(DraftFormatOp.numbered, 'item', 0, 0);
      expect(r.text, '1. item');
    });
  });

  group('applyFormat — boundary safety', () {
    test('handles selectionEnd < selectionStart by normalising', () {
      final r = applyFormat(DraftFormatOp.bold, 'hello world', 7, 4);
      expect(r.text, 'hell**o w**orld');
    });

    test('clamps out-of-range selections to text length', () {
      final r = applyFormat(DraftFormatOp.bold, 'hi', 0, 99);
      expect(r.text, '**hi**');
    });

    test('handles empty input', () {
      final r = applyFormat(DraftFormatOp.heading, '', 0, 0);
      expect(r.text, '## ');
    });
  });

  group('DraftToolbar widget', () {
    Widget wrap(Widget child) {
      return MaterialApp(home: Scaffold(body: child));
    }

    testWidgets('emits onFormat callback with right op', (tester) async {
      DraftFormatOp? captured;
      await tester.pumpWidget(wrap(DraftToolbar(
        onFormat: (op) => captured = op,
        onAiRevise: () {},
        onSave: () {},
        onExport: (_) {},
      )));
      await tester.tap(find.byKey(const Key('draft_format_bold')));
      expect(captured, DraftFormatOp.bold);
      await tester.tap(find.byKey(const Key('draft_format_italic')));
      expect(captured, DraftFormatOp.italic);
      await tester.tap(find.byKey(const Key('draft_format_heading')));
      expect(captured, DraftFormatOp.heading);
      await tester.tap(find.byKey(const Key('draft_format_bullet')));
      expect(captured, DraftFormatOp.bullet);
      await tester.tap(find.byKey(const Key('draft_format_numbered')));
      expect(captured, DraftFormatOp.numbered);
    });

    testWidgets('AI revise button fires callback', (tester) async {
      var aiPressed = false;
      await tester.pumpWidget(wrap(DraftToolbar(
        onFormat: (_) {},
        onAiRevise: () => aiPressed = true,
        onSave: () {},
        onExport: (_) {},
      )));
      await tester.tap(find.byKey(const Key('draft_toolbar_ai_revise')));
      expect(aiPressed, isTrue);
    });

    testWidgets('Save button is disabled when busy=true', (tester) async {
      await tester.pumpWidget(wrap(DraftToolbar(
        onFormat: (_) {},
        onAiRevise: () {},
        onSave: () {},
        onExport: (_) {},
        busy: true,
      )));
      final btn = tester.widget<OutlinedButton>(
          find.byKey(const Key('draft_toolbar_save')));
      expect(btn.onPressed, isNull);
    });

    testWidgets('savedLabel renders when provided', (tester) async {
      await tester.pumpWidget(wrap(DraftToolbar(
        onFormat: (_) {},
        onAiRevise: () {},
        onSave: () {},
        onExport: (_) {},
        savedLabel: 'Saved just now',
      )));
      expect(find.byKey(const Key('draft_toolbar_saved_label')), findsOneWidget);
      expect(find.text('Saved just now'), findsOneWidget);
    });

    testWidgets('export menu surfaces three options', (tester) async {
      DraftExportKind? captured;
      await tester.pumpWidget(wrap(DraftToolbar(
        onFormat: (_) {},
        onAiRevise: () {},
        onSave: () {},
        onExport: (k) => captured = k,
      )));
      await tester.tap(find.byKey(const Key('draft_toolbar_export_menu')));
      await tester.pumpAndSettle();
      // Tap the DOCX entry.
      await tester.tap(find.byKey(const Key('draft_toolbar_export_docx')));
      await tester.pumpAndSettle();
      expect(captured, DraftExportKind.docx);
    });
  });
}
