import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../config/theme.dart';
import '../../../core/citations/marker.dart';
import '../citations/citation_model.dart';
import 'action_chip.dart';
import 'citations/citation_marker_span.dart';
import 'rich_message_blocks.dart';

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Renders an AI message with rich markdown-like formatting.
///
/// Supported syntax:
/// - **bold**, *italic*
/// - Bullet lists (- or bullet char)
/// - Numbered lists (1. 2. 3.)
/// - Headers (## )
/// - Code / law refs in `backticks`
/// - Clickable actions in [brackets]
/// - Status badges (colored emoji)
/// - Tables (pipe-separated)
/// - Dividers (---)
/// - Quotes (> prefix)
class RichMessage extends StatelessWidget {
  const RichMessage({
    super.key,
    required this.text,
    this.onActionTap,
    this.animate = true,
    this.baseStyle,
    this.citations = const [],
  });

  /// Raw AI message text.
  final String text;

  /// Callback when a user taps an [action] chip. Receives the action label.
  final ValueChanged<String>? onActionTap;

  /// Whether to stagger-animate blocks on entrance.
  final bool animate;

  /// Base text style. Falls back to a sensible default.
  final TextStyle? baseStyle;

  /// Phase 2 Pkg 2 — grounded citations for this assistant message.
  /// `[[ref:ACT:PARA]]` markers in [text] are replaced inline with chips
  /// that look up their data from this list. Empty for legacy messages
  /// or non-legal turns.
  final List<Citation> citations;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = baseStyle ??
        TextStyle(
          fontSize: 15,
          height: 1.5,
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        );

    final blocks = parseRichBlocks(text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < blocks.length; i++)
          _buildBlock(context, blocks[i], style, i, isDark),
      ],
    );
  }

  // ── Block renderer ──────────────────────────────────────────────────────

  Widget _buildBlock(
    BuildContext context,
    RichBlock block,
    TextStyle style,
    int index,
    bool isDark,
  ) {
    Widget child;
    switch (block.type) {
      case RichBlockType.header:
        child = _buildHeader(context, block.content, style, isDark);
      case RichBlockType.bullet:
        child = _buildBullet(context, block.content, style, isDark);
      case RichBlockType.numbered:
        child = _buildNumbered(context, block.content, block.number, style, isDark);
      case RichBlockType.quote:
        child = _buildQuote(context, block.content, style, isDark);
      case RichBlockType.divider:
        child = _buildDivider(isDark);
      case RichBlockType.table:
        child = _buildTable(context, block.rows, style, isDark);
      case RichBlockType.paragraph:
        child = _buildParagraph(context, block.content, style, isDark);
      case RichBlockType.empty:
        child = const SizedBox(height: 4);
    }

    if (animate) {
      final delay = Duration(milliseconds: 30 * index);
      child = child
          .animate()
          .fadeIn(duration: 200.ms, delay: delay)
          .slideY(begin: 0.05, end: 0, duration: 200.ms, delay: delay);
    }

    return child;
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(
    BuildContext context,
    String content,
    TextStyle style,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: _richText(
        context,
        content,
        style.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.accentLight : AppColors.primary,
        ),
        isDark,
      ),
    );
  }

  // ── Bullet list item ────────────────────────────────────────────────────

  Widget _buildBullet(
    BuildContext context,
    String content,
    TextStyle style,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 8),
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: _richText(context, content, style, isDark),
          ),
        ],
      ),
    );
  }

  // ── Numbered list item ──────────────────────────────────────────────────

  Widget _buildNumbered(
    BuildContext context,
    String content,
    int number,
    TextStyle style,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$number.',
              style: style.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ),
          Expanded(
            child: _richText(context, content, style, isDark),
          ),
        ],
      ),
    );
  }

  // ── Quote ───────────────────────────────────────────────────────────────

  Widget _buildQuote(
    BuildContext context,
    String content,
    TextStyle style,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6, right: 8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.6),
            width: 3,
          ),
        ),
        color: (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant)
            .withValues(alpha: 0.5),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
      ),
      child: _richText(
        context,
        content,
        style.copyWith(
          fontStyle: FontStyle.italic,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
        ),
        isDark,
      ),
    );
  }

  // ── Divider ─────────────────────────────────────────────────────────────

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(
        height: 1,
        thickness: 1,
        color: (isDark ? AppColors.darkBorder : AppColors.border)
            .withValues(alpha: 0.6),
      ),
    );
  }

  // ── Paragraph ───────────────────────────────────────────────────────────

  Widget _buildParagraph(
    BuildContext context,
    String content,
    TextStyle style,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: _richText(context, content, style, isDark),
    );
  }

  // ── Table ───────────────────────────────────────────────────────────────

  Widget _buildTable(
    BuildContext context,
    List<List<String>> rows,
    TextStyle style,
    bool isDark,
  ) {
    if (rows.isEmpty) return const SizedBox.shrink();

    final headerRow = rows.first;
    final bodyRows = rows.length > 1 ? rows.sublist(1) : <List<String>>[];

    // Filter out separator rows (e.g. |---|---|)
    final filteredBody = bodyRows
        .where((row) => !row.every((c) => RegExp(r'^[-:]+$').hasMatch(c.trim())))
        .toList();

    final borderColor =
        (isDark ? AppColors.darkBorder : AppColors.border).withValues(alpha: 0.6);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        border: TableBorder.symmetric(
          inside: BorderSide(color: borderColor, width: 0.5),
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          // Header
          TableRow(
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant)
                  .withValues(alpha: 0.7),
            ),
            children: headerRow
                .map((cell) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      child: Text(
                        cell.trim(),
                        style: style.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ))
                .toList(),
          ),
          // Body
          ...filteredBody.map(
            (row) {
              // Pad or trim row to match header column count
              final padded = List<String>.generate(
                headerRow.length,
                (i) => i < row.length ? row[i].trim() : '',
              );
              return TableRow(
                children: padded
                    .map((cell) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          child: Text(
                            cell,
                            style: style.copyWith(fontSize: 13),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Inline span parser ──────────────────────────────────────────────────

  /// Builds a [Text.rich] widget that handles bold, italic, code, badges,
  /// and action-chip inlines.
  Widget _richText(
    BuildContext context,
    String text,
    TextStyle baseStyle,
    bool isDark,
  ) {
    final spans = _parseInlineSpans(context, text, baseStyle, isDark);

    // Check if any span is a widget span (action chip)
    final hasWidgets = spans.any((s) => s is WidgetSpan);

    if (hasWidgets) {
      return Text.rich(
        TextSpan(children: spans),
        textDirection: _detectDirection(text),
      );
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      textDirection: _detectDirection(text),
    );
  }

  List<InlineSpan> _parseInlineSpans(
    BuildContext context,
    String text,
    TextStyle baseStyle,
    bool isDark,
  ) {
    // Phase 2 Pkg 2 — citation markers `[[ref:ACT:PARA]]` in text get
    // replaced with tappable chips before any other inline parsing.
    // We split the text into segments at every marker, run the legacy
    // inline parser on each NON-marker segment, then concatenate.
    if (text.contains('[[ref:')) {
      final markerRegex = RegExp(kCitationMarkerPattern);
      final byKey = <String, Citation>{
        for (final c in citations) c.key: c,
      };
      final out = <InlineSpan>[];
      int cursor = 0;
      for (final match in markerRegex.allMatches(text)) {
        if (match.start > cursor) {
          // Recurse into the legacy parser on the prefix text. Pass an
          // empty-citations RichMessage spec so the recursion stops.
          out.addAll(_parseInlineSpansLegacy(
            text.substring(cursor, match.start),
            baseStyle,
            isDark,
          ));
        }
        final actSlug = (match.group(1) ?? '').toLowerCase();
        final paragraph = match.group(2) ?? '';
        final key = '$actSlug:$paragraph';
        final citation = byKey[key];
        out.addAll(buildCitationSpans(
          context: context,
          text: match.group(0)!,
          citations: citation == null ? const [] : [citation],
          baseStyle: baseStyle,
        ));
        cursor = match.end;
      }
      if (cursor < text.length) {
        out.addAll(_parseInlineSpansLegacy(
          text.substring(cursor),
          baseStyle,
          isDark,
        ));
      }
      return out;
    }
    return _parseInlineSpansLegacy(text, baseStyle, isDark);
  }

  List<InlineSpan> _parseInlineSpansLegacy(
    String text,
    TextStyle baseStyle,
    bool isDark,
  ) {
    final spans = <InlineSpan>[];
    final buffer = StringBuffer();

    int i = 0;
    while (i < text.length) {
      // ── Status badge emoji ────────────────────────────────────────────
      final badgeColor = _checkBadgeEmoji(text, i);
      if (badgeColor != null) {
        // Flush buffer
        if (buffer.isNotEmpty) {
          spans.add(TextSpan(text: buffer.toString(), style: baseStyle));
          buffer.clear();
        }
        spans.add(_buildBadgeSpan(text, i, badgeColor, baseStyle));
        // Advance past the emoji (most are 1-2 code units, but some
        // multi-byte; we consume until we leave the emoji cluster).
        i += _emojiLength(text, i);
        continue;
      }

      // ── Bold **text** ─────────────────────────────────────────────────
      if (i + 1 < text.length &&
          text[i] == '*' &&
          text[i + 1] == '*') {
        final end = text.indexOf('**', i + 2);
        if (end != -1) {
          if (buffer.isNotEmpty) {
            spans.add(TextSpan(text: buffer.toString(), style: baseStyle));
            buffer.clear();
          }
          final inner = text.substring(i + 2, end);
          spans.add(TextSpan(
            text: inner,
            style: baseStyle.copyWith(fontWeight: FontWeight.w700),
          ));
          i = end + 2;
          continue;
        }
      }

      // ── Italic *text* (single star, but not **) ───────────────────────
      if (text[i] == '*' &&
          (i + 1 >= text.length || text[i + 1] != '*') &&
          (i == 0 || text[i - 1] != '*')) {
        final end = text.indexOf('*', i + 1);
        if (end != -1 && end > i + 1) {
          if (buffer.isNotEmpty) {
            spans.add(TextSpan(text: buffer.toString(), style: baseStyle));
            buffer.clear();
          }
          final inner = text.substring(i + 1, end);
          spans.add(TextSpan(
            text: inner,
            style: baseStyle.copyWith(fontStyle: FontStyle.italic),
          ));
          i = end + 1;
          continue;
        }
      }

      // ── Code / law reference `text` ───────────────────────────────────
      if (text[i] == '`') {
        final end = text.indexOf('`', i + 1);
        if (end != -1) {
          if (buffer.isNotEmpty) {
            spans.add(TextSpan(text: buffer.toString(), style: baseStyle));
            buffer.clear();
          }
          final inner = text.substring(i + 1, end);
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _CodeChip(text: inner, isDark: isDark),
          ));
          i = end + 1;
          continue;
        }
      }

      // ── Action chip [text] ────────────────────────────────────────────
      if (text[i] == '[') {
        final end = text.indexOf(']', i + 1);
        if (end != -1) {
          if (buffer.isNotEmpty) {
            spans.add(TextSpan(text: buffer.toString(), style: baseStyle));
            buffer.clear();
          }
          final label = text.substring(i + 1, end);
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: ChatActionChip(
                label: label,
                compact: true,
                onTap: () => onActionTap?.call(label),
              ),
            ),
          ));
          i = end + 1;
          continue;
        }
      }

      buffer.write(text[i]);
      i++;
    }

    if (buffer.isNotEmpty) {
      spans.add(TextSpan(text: buffer.toString(), style: baseStyle));
    }

    return spans;
  }

  // ── Badge helpers ───────────────────────────────────────────────────────

  static const _badgeMap = <String, Color>{
    '\u{1F534}': AppColors.error, // red circle
    '\u{1F7E1}': AppColors.warning, // yellow circle
    '\u{1F7E2}': AppColors.success, // green circle
    '\u2705': AppColors.success, // check mark
    '\u274C': AppColors.error, // cross mark
    '\u26A0\uFE0F': AppColors.warning, // warning sign (with VS16)
    '\u26A0': AppColors.warning, // warning sign (without VS16)
  };

  Color? _checkBadgeEmoji(String text, int i) {
    for (final entry in _badgeMap.entries) {
      if (text.startsWith(entry.key, i)) {
        return entry.value;
      }
    }
    return null;
  }

  int _emojiLength(String text, int i) {
    for (final key in _badgeMap.keys) {
      if (text.startsWith(key, i)) return key.length;
    }
    return 1;
  }

  WidgetSpan _buildBadgeSpan(
    String text,
    int i,
    Color color,
    TextStyle style,
  ) {
    // Grab the emoji text for display
    String emoji = '';
    for (final key in _badgeMap.keys) {
      if (text.startsWith(key, i)) {
        emoji = key;
        break;
      }
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          emoji,
          style: style.copyWith(fontSize: 14),
        ),
      ),
    );
  }

  // ── RTL detection ───────────────────────────────────────────────────────

  TextDirection _detectDirection(String text) {
    // Check first 20 non-whitespace chars for RTL characters (Arabic, Farsi).
    final cleaned = text.replaceAll(RegExp(r'\s'), '');
    final sample = cleaned.substring(0, cleaned.length.clamp(0, 20));
    final rtlPattern = RegExp(r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]');
    final rtlCount = rtlPattern.allMatches(sample).length;
    return rtlCount > sample.length / 3
        ? TextDirection.rtl
        : TextDirection.ltr;
  }
}

// ---------------------------------------------------------------------------
// Code / law reference chip
// ---------------------------------------------------------------------------

class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.text, required this.isDark});

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.25),
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.accentLight : AppColors.accentDark,
          height: 1.3,
        ),
      ),
    );
  }
}
