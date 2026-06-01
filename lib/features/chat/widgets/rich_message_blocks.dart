// Pure block parser for RichMessage — extracted from rich_message.dart so the
// structural parse (headers / bullets / numbered / quotes / tables / dividers /
// paragraphs) can be regression-tested without a widget/BuildContext.
//
// A misparse here is user-visible: a table collapsing into garbage paragraphs,
// a dropped bullet, or a numbered item losing its number. No Flutter import —
// keep it that way so the parser stays trivially testable.

enum RichBlockType {
  header,
  bullet,
  numbered,
  quote,
  divider,
  table,
  paragraph,
  empty,
}

class RichBlock {
  final RichBlockType type;
  final String content;
  final int number;
  final List<List<String>> rows;

  const RichBlock({
    required this.type,
    this.content = '',
    this.number = 0,
    this.rows = const [],
  });
}

/// Splits raw AI message text into structural blocks.
List<RichBlock> parseRichBlocks(String text) {
  final lines = text.split('\n');
  final blocks = <RichBlock>[];

  int i = 0;
  while (i < lines.length) {
    final line = lines[i];
    final trimmed = line.trim();

    // Empty line
    if (trimmed.isEmpty) {
      blocks.add(const RichBlock(type: RichBlockType.empty));
      i++;
      continue;
    }

    // Divider: ---  or ___ or ***  (3+ chars)
    if (RegExp(r'^[-_*]{3,}$').hasMatch(trimmed)) {
      blocks.add(const RichBlock(type: RichBlockType.divider));
      i++;
      continue;
    }

    // Header: ## text
    if (trimmed.startsWith('## ')) {
      blocks.add(RichBlock(
        type: RichBlockType.header,
        content: trimmed.substring(3).trim(),
      ));
      i++;
      continue;
    }

    // Single # header (less common but still valid)
    if (trimmed.startsWith('# ') && !trimmed.startsWith('## ')) {
      blocks.add(RichBlock(
        type: RichBlockType.header,
        content: trimmed.substring(2).trim(),
      ));
      i++;
      continue;
    }

    // Quote: > text
    if (trimmed.startsWith('> ')) {
      // Collect consecutive quote lines
      final quoteBuffer = StringBuffer();
      while (i < lines.length && lines[i].trim().startsWith('> ')) {
        if (quoteBuffer.isNotEmpty) quoteBuffer.write('\n');
        quoteBuffer.write(lines[i].trim().substring(2));
        i++;
      }
      blocks.add(
          RichBlock(type: RichBlockType.quote, content: quoteBuffer.toString()));
      continue;
    }

    // Table: line contains | (at least 2 pipes)
    if (trimmed.contains('|') && '|'.allMatches(trimmed).length >= 2) {
      final tableRows = <List<String>>[];
      while (i < lines.length &&
          lines[i].trim().contains('|') &&
          '|'.allMatches(lines[i].trim()).length >= 2) {
        final cells = lines[i]
            .trim()
            .split('|')
            .map((c) => c.trim())
            .where((c) => c.isNotEmpty)
            .toList();
        tableRows.add(cells);
        i++;
      }
      blocks.add(RichBlock(type: RichBlockType.table, rows: tableRows));
      continue;
    }

    // Bullet: - text  or bullet text
    if (trimmed.startsWith('- ') || trimmed.startsWith('\u2022 ')) {
      final prefix = trimmed.startsWith('- ') ? '- ' : '\u2022 ';
      blocks.add(RichBlock(
        type: RichBlockType.bullet,
        content: trimmed.substring(prefix.length).trim(),
      ));
      i++;
      continue;
    }

    // Numbered list: 1. text, 2. text, etc.
    final numberedMatch = RegExp(r'^(\d+)\.\s+(.+)$').firstMatch(trimmed);
    if (numberedMatch != null) {
      blocks.add(RichBlock(
        type: RichBlockType.numbered,
        content: numberedMatch.group(2)!,
        number: int.parse(numberedMatch.group(1)!),
      ));
      i++;
      continue;
    }

    // Paragraph (default)
    blocks.add(RichBlock(type: RichBlockType.paragraph, content: trimmed));
    i++;
  }

  return blocks;
}
