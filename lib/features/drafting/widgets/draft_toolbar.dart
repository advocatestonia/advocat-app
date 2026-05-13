// drafting/widgets/draft_toolbar.dart — Pkg 7 Drafting Studio MVP.
// -----------------------------------------------------------------------------
// Compact toolbar above the editor: format buttons (bold/italic/heading/lists),
// AI revise, save, and export menu. Pure widget — the host owns the editor
// state and reacts to the callback events emitted here.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import 'drafting_strings.dart';

/// Markdown formatting operation requested by the toolbar.
enum DraftFormatOp { bold, italic, heading, bullet, numbered }

/// Which export pipeline was requested.
enum DraftExportKind { pdf, docx, markdown }

class DraftToolbar extends StatelessWidget {
  const DraftToolbar({
    super.key,
    required this.onFormat,
    required this.onAiRevise,
    required this.onSave,
    required this.onExport,
    this.savedLabel,
    this.busy = false,
  });

  final ValueChanged<DraftFormatOp> onFormat;
  final VoidCallback onAiRevise;
  final VoidCallback onSave;
  final ValueChanged<DraftExportKind> onExport;
  final String? savedLabel;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = DraftingStrings.of(context);
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: <Widget>[
            // Left cluster — format buttons + AI revise — wrapped in a
            // horizontal scroller so narrow viewports don't overflow.
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    _toolbarBtn(
                      keyName: 'draft_format_bold',
                      icon: Icons.format_bold,
                      tooltip: l10n.formatBold,
                      onTap: () => onFormat(DraftFormatOp.bold),
                    ),
                    _toolbarBtn(
                      keyName: 'draft_format_italic',
                      icon: Icons.format_italic,
                      tooltip: l10n.formatItalic,
                      onTap: () => onFormat(DraftFormatOp.italic),
                    ),
                    _toolbarBtn(
                      keyName: 'draft_format_heading',
                      icon: Icons.title,
                      tooltip: l10n.formatHeading,
                      onTap: () => onFormat(DraftFormatOp.heading),
                    ),
                    _toolbarBtn(
                      keyName: 'draft_format_bullet',
                      icon: Icons.format_list_bulleted,
                      tooltip: l10n.formatBullet,
                      onTap: () => onFormat(DraftFormatOp.bullet),
                    ),
                    _toolbarBtn(
                      keyName: 'draft_format_numbered',
                      icon: Icons.format_list_numbered,
                      tooltip: l10n.formatNumbered,
                      onTap: () => onFormat(DraftFormatOp.numbered),
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      key: const Key('draft_toolbar_ai_revise'),
                      onPressed: busy ? null : onAiRevise,
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: Text(l10n.aiRevise),
                    ),
                  ],
                ),
              ),
            ),
            // Right cluster — Saved label + Save button + Export menu.
            if (savedLabel != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  savedLabel!,
                  key: const Key('draft_toolbar_saved_label'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            OutlinedButton.icon(
              key: const Key('draft_toolbar_save'),
              onPressed: busy ? null : onSave,
              icon: const Icon(Icons.save_outlined, size: 16),
              label: Text(l10n.save),
            ),
            const SizedBox(width: 6),
            PopupMenuButton<DraftExportKind>(
              key: const Key('draft_toolbar_export_menu'),
              tooltip: l10n.exportPdf,
              onSelected: onExport,
              icon: const Icon(Icons.download),
              itemBuilder: (ctx) => <PopupMenuEntry<DraftExportKind>>[
                PopupMenuItem<DraftExportKind>(
                  key: const Key('draft_toolbar_export_pdf'),
                  value: DraftExportKind.pdf,
                  child: Text(l10n.exportPdf),
                ),
                PopupMenuItem<DraftExportKind>(
                  key: const Key('draft_toolbar_export_docx'),
                  value: DraftExportKind.docx,
                  child: Text(l10n.exportDocx),
                ),
                PopupMenuItem<DraftExportKind>(
                  key: const Key('draft_toolbar_export_md'),
                  value: DraftExportKind.markdown,
                  child: Text(l10n.exportMd),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolbarBtn({
    required String keyName,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return IconButton(
      key: Key(keyName),
      tooltip: tooltip,
      icon: Icon(icon, size: 18),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
    );
  }
}

// ─── Pure formatting helpers (no Flutter deps) ──────────────────────────────
//
// Exposed so widget tests can hit them without rendering a TextField.
// Each helper takes the current text + selection range and returns the new
// text + new caret position.
// -----------------------------------------------------------------------------

class FormatResult {
  const FormatResult({required this.text, required this.selectionStart, required this.selectionEnd});
  final String text;
  final int selectionStart;
  final int selectionEnd;
}

FormatResult applyFormat(
  DraftFormatOp op,
  String text,
  int selectionStart,
  int selectionEnd,
) {
  // Normalise selection range.
  final s = selectionStart.clamp(0, text.length);
  final e = selectionEnd.clamp(0, text.length);
  final start = s < e ? s : e;
  final end = s < e ? e : s;
  final before = text.substring(0, start);
  final inside = text.substring(start, end);
  final after = text.substring(end);

  String marker = '';
  switch (op) {
    case DraftFormatOp.bold:
      marker = '**';
      final wrapped = '$before$marker${inside.isEmpty ? "bold" : inside}$marker$after';
      final newStart = before.length + marker.length;
      final newEnd = newStart + (inside.isEmpty ? 4 : inside.length);
      return FormatResult(text: wrapped, selectionStart: newStart, selectionEnd: newEnd);
    case DraftFormatOp.italic:
      marker = '*';
      final wrapped = '$before$marker${inside.isEmpty ? "italic" : inside}$marker$after';
      final newStart = before.length + marker.length;
      final newEnd = newStart + (inside.isEmpty ? 6 : inside.length);
      return FormatResult(text: wrapped, selectionStart: newStart, selectionEnd: newEnd);
    case DraftFormatOp.heading:
      // Find start of line.
      final lineStart = _lineStart(text, start);
      final newText =
          '${text.substring(0, lineStart)}## ${text.substring(lineStart)}';
      return FormatResult(
        text: newText,
        selectionStart: start + 3,
        selectionEnd: end + 3,
      );
    case DraftFormatOp.bullet:
      return _prefixLine(text, start, end, '- ');
    case DraftFormatOp.numbered:
      return _prefixLine(text, start, end, '1. ');
  }
}

int _lineStart(String t, int idx) {
  var i = idx;
  while (i > 0 && t[i - 1] != '\n') {
    i--;
  }
  return i;
}

FormatResult _prefixLine(String text, int start, int end, String prefix) {
  final ls = _lineStart(text, start);
  final newText = '${text.substring(0, ls)}$prefix${text.substring(ls)}';
  return FormatResult(
    text: newText,
    selectionStart: start + prefix.length,
    selectionEnd: end + prefix.length,
  );
}
