import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ---------------------------------------------------------------------------
// Markdown line model — used by classifyLine and the renderer
// ---------------------------------------------------------------------------

/// The structural kind of a line in the input markdown.
enum PdfLineKind { h1, h2, h3, bullet, paragraph, blank }

/// A classified line of input markdown. Line text has the markdown sigil
/// (`# `, `- `, etc.) stripped — only the visible content is kept.
class PdfLine {
  final PdfLineKind kind;
  final String text;
  const PdfLine({required this.kind, required this.text});

  @override
  bool operator ==(Object other) =>
      other is PdfLine && other.kind == kind && other.text == text;

  @override
  int get hashCode => Object.hash(kind, text);

  @override
  String toString() => 'PdfLine($kind, "$text")';
}

/// A run of inline text inside a paragraph, bullet, or heading. Currently we
/// support a single inline annotation: bold (`**word**`).
class PdfInlineSpan {
  final String text;
  final bool bold;
  const PdfInlineSpan({required this.text, this.bold = false});
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Renders AI-generated legal-document markdown into a PDF byte buffer that
/// the chat UI can offer for download.
///
/// Design notes:
///   • The markdown subset is intentionally tiny: `#`/`##`/`###` for headings,
///     `-` and `*` for bullets, `**bold**` inline. Anything else falls through
///     as a paragraph — this matches what Claude actually emits for drafts and
///     keeps the renderer easy to test.
///   • Unicode coverage (Cyrillic + Estonian diacritics) is handled by Noto
///     Sans, fetched at runtime via the `printing` package's
///     `PdfGoogleFonts` helper. On test or when offline we fall back to
///     Helvetica which is fine for ASCII smoke tests.
///   • The Advocat logo is loaded from `assets/icons/Icon-512.png`. If the
///     asset is missing (e.g. unit tests) we render a text-only header.
class PdfService {
  /// When true, skip the runtime Google-Fonts download (used by tests so they
  /// stay hermetic and offline-safe). Falls back to built-in Helvetica.
  final bool disableNetworkFonts;

  /// Public so tests can inject fake fonts; production callers leave it null.
  pw.Font? overrideRegularFont;
  pw.Font? overrideBoldFont;

  PdfService({this.disableNetworkFonts = false});

  // -------------------------------------------------------------------------
  // Public entry point
  // -------------------------------------------------------------------------

  /// Render [markdown] as a PDF. Returns the raw bytes ready for a browser
  /// download or upload.
  ///
  /// [title] is shown in the header strip and used as the PDF metadata title.
  /// [language] is the document language code (`et`, `ru`, `en`, ...) and
  /// drives the footer disclaimer wording.
  Future<Uint8List> renderLegalDocument({
    required String markdown,
    required String title,
    required String language,
    String? userName,
  }) async {
    final doc = pw.Document(
      title: title,
      author: 'Advocat',
      creator: 'Advocat AI Assistant',
      subject: title,
    );

    final regular = await _loadRegularFont();
    final bold = await _loadBoldFont();
    final logo = await _loadLogo();
    final disclaimer = disclaimerFor(language);
    final lines = _classifyMarkdown(markdown);
    final theme = pw.ThemeData.withFont(base: regular, bold: bold);
    final dateString = _formatDate(DateTime.now(), language);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.fromLTRB(48, 48, 48, 56),
        header: (context) => _buildHeader(
          title: title,
          dateString: dateString,
          logo: logo,
        ),
        footer: (context) => _buildFooter(
          context: context,
          disclaimer: disclaimer,
          userName: userName,
        ),
        build: (context) => _buildBody(lines),
      ),
    );

    return doc.save();
  }

  // -------------------------------------------------------------------------
  // Static helpers (pure — exposed for unit tests)
  // -------------------------------------------------------------------------

  /// Map a single line of input markdown to a [PdfLine].
  static PdfLine classifyLine(String raw) {
    final trimmed = raw.trimRight();
    if (trimmed.trim().isEmpty) {
      return const PdfLine(kind: PdfLineKind.blank, text: '');
    }
    if (trimmed.startsWith('### ')) {
      return PdfLine(kind: PdfLineKind.h3, text: trimmed.substring(4).trim());
    }
    if (trimmed.startsWith('## ')) {
      return PdfLine(kind: PdfLineKind.h2, text: trimmed.substring(3).trim());
    }
    if (trimmed.startsWith('# ')) {
      return PdfLine(kind: PdfLineKind.h1, text: trimmed.substring(2).trim());
    }
    if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
      return PdfLine(
        kind: PdfLineKind.bullet,
        text: trimmed.substring(2).trim(),
      );
    }
    return PdfLine(kind: PdfLineKind.paragraph, text: trimmed);
  }

  /// Tokenise inline `**bold**` runs from a line of text.
  ///
  /// Robustness: we only emit bold spans for *matched* `**...**` pairs. An
  /// orphan `**` is treated as literal text — Claude occasionally emits a
  /// stray `**` and we don't want that to lose half the document.
  static List<PdfInlineSpan> parseInlineSpans(String text) {
    final out = <PdfInlineSpan>[];
    var i = 0;
    var plainStart = 0;

    while (i < text.length - 1) {
      if (text[i] == '*' && text[i + 1] == '*') {
        // Look for the closing **.
        final closeIdx = text.indexOf('**', i + 2);
        if (closeIdx == -1) {
          // Unmatched — bail out, the whole text is treated as plain.
          break;
        }
        // Flush plain prefix.
        if (i > plainStart) {
          out.add(PdfInlineSpan(text: text.substring(plainStart, i)));
        }
        out.add(
          PdfInlineSpan(
            text: text.substring(i + 2, closeIdx),
            bold: true,
          ),
        );
        i = closeIdx + 2;
        plainStart = i;
        continue;
      }
      i++;
    }

    // Flush trailing plain text.
    if (plainStart < text.length) {
      out.add(PdfInlineSpan(text: text.substring(plainStart)));
    }
    if (out.isEmpty) {
      out.add(PdfInlineSpan(text: text));
    }
    return out;
  }

  /// The footer disclaimer in the document language. Falls back to English
  /// for unknown codes.
  static String disclaimerFor(String language) {
    switch (language.toLowerCase()) {
      case 'et':
        return 'AI-genereeritud. See ei ole õigusnõu. Konsulteerige '
            'kvalifitseeritud juristiga.';
      case 'ru':
        return 'Сгенерировано ИИ. Не является юридической консультацией. '
            'Обратитесь к квалифицированному юристу.';
      case 'fi':
        return 'Tekoälyn luoma. Tämä ei ole oikeudellinen neuvo. Ota yhteyttä '
            'pätevään asianajajaan.';
      case 'de':
        return 'KI-generiert. Keine Rechtsberatung. Konsultieren Sie einen '
            'qualifizierten Anwalt.';
      case 'sv':
        return 'AI-genererad. Inte juridisk rådgivning. Konsultera en '
            'kvalificerad advokat.';
      case 'lv':
        return 'AI ģenerēts. Šī nav juridiska konsultācija. Sazinieties ar '
            'kvalificētu juristu.';
      case 'lt':
        return 'AI sugeneruota. Tai nėra teisinė konsultacija. Pasitarkite su '
            'kvalifikuotu teisininku.';
      case 'en':
      default:
        return 'AI-generated. Not legal advice. Consult a qualified attorney.';
    }
  }

  /// Heuristic: does this assistant message look like a generated legal
  /// document (worth offering a "Download PDF" button)? We look for a top
  /// heading whose first word is one of the canonical draft types in any of
  /// the supported languages, OR a formal salutation like "Lugupeetud".
  static bool looksLikeDraft(String content) {
    if (content.trim().isEmpty) return false;
    final lower = content.toLowerCase();

    // Heading-based detection.
    final headingMatch =
        RegExp(r'^#\s+(.+)$', multiLine: true).firstMatch(content);
    if (headingMatch != null) {
      final h = headingMatch.group(1)!.toLowerCase().trim();
      for (final keyword in _draftHeadingKeywords) {
        if (h.startsWith(keyword)) return true;
      }
    }

    // Salutation-based detection.
    for (final salutation in _draftSalutations) {
      if (lower.contains(salutation)) return true;
    }
    return false;
  }

  // -------------------------------------------------------------------------
  // Internal — fonts and assets
  // -------------------------------------------------------------------------

  Future<pw.Font> _loadRegularFont() async {
    if (overrideRegularFont != null) return overrideRegularFont!;
    if (disableNetworkFonts) return pw.Font.helvetica();
    try {
      return await PdfGoogleFonts.notoSansRegular();
    } catch (_) {
      return pw.Font.helvetica();
    }
  }

  Future<pw.Font> _loadBoldFont() async {
    if (overrideBoldFont != null) return overrideBoldFont!;
    if (disableNetworkFonts) return pw.Font.helveticaBold();
    try {
      return await PdfGoogleFonts.notoSansBold();
    } catch (_) {
      return pw.Font.helveticaBold();
    }
  }

  Future<pw.MemoryImage?> _loadLogo() async {
    try {
      final data = await rootBundle.load('assets/icons/Icon-512.png');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // Internal — markdown helpers
  // -------------------------------------------------------------------------

  List<PdfLine> _classifyMarkdown(String markdown) {
    return markdown.split('\n').map(classifyLine).toList();
  }

  String _formatDate(DateTime now, String language) {
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    // ISO is unambiguous and culturally neutral — no need for intl bloat here.
    return '$y-$m-$d';
  }

  // -------------------------------------------------------------------------
  // Internal — PDF widget construction
  // -------------------------------------------------------------------------

  pw.Widget _buildHeader({
    required String title,
    required String dateString,
    required pw.MemoryImage? logo,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      margin: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _kCyan, width: 2),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logo != null)
            pw.Container(
              width: 28,
              height: 28,
              margin: const pw.EdgeInsets.only(right: 10),
              child: pw.Image(logo),
            ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Advocat',
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: _kBlueDark,
                    letterSpacing: 1.2,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
          pw.Text(
            dateString,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter({
    required pw.Context context,
    required String disclaimer,
    required String? userName,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      margin: const pw.EdgeInsets.only(top: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  disclaimer,
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                ),
                if (userName != null && userName.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    userName,
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _buildBody(List<PdfLine> lines) {
    final out = <pw.Widget>[];
    // Coalesce consecutive bullet lines into a single padded block.
    var i = 0;
    while (i < lines.length) {
      final line = lines[i];
      switch (line.kind) {
        case PdfLineKind.blank:
          out.add(pw.SizedBox(height: 6));
          i++;
        case PdfLineKind.h1:
          out.add(_renderHeading(line.text, 18, true));
          i++;
        case PdfLineKind.h2:
          out.add(_renderHeading(line.text, 14, true));
          i++;
        case PdfLineKind.h3:
          out.add(_renderHeading(line.text, 12, true));
          i++;
        case PdfLineKind.bullet:
          // Greedy-collect successive bullets.
          final bullets = <String>[];
          while (i < lines.length && lines[i].kind == PdfLineKind.bullet) {
            bullets.add(lines[i].text);
            i++;
          }
          out.add(_renderBulletList(bullets));
        case PdfLineKind.paragraph:
          out.add(_renderParagraph(line.text));
          i++;
      }
    }
    return out;
  }

  pw.Widget _renderHeading(String text, double size, bool bold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 10, bottom: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          children: parseInlineSpans(text)
              .map(
                (s) => pw.TextSpan(
                  text: s.text,
                  style: pw.TextStyle(
                    fontSize: size,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  pw.Widget _renderParagraph(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.RichText(
        text: pw.TextSpan(
          children: parseInlineSpans(text)
              .map(
                (s) => pw.TextSpan(
                  text: s.text,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight:
                        s.bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                    lineSpacing: 1.4,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  pw.Widget _renderBulletList(List<String> items) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 6, top: 2, bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: items
            .map(
              (item) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 14,
                      padding: const pw.EdgeInsets.only(top: 2),
                      child: pw.Text(
                        '•',
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: _kBlueDark,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.RichText(
                        text: pw.TextSpan(
                          children: parseInlineSpans(item)
                              .map(
                                (s) => pw.TextSpan(
                                  text: s.text,
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    fontWeight: s.bold
                                        ? pw.FontWeight.bold
                                        : pw.FontWeight.normal,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const PdfColor _kCyan = PdfColor.fromInt(0xff00E5FF);
const PdfColor _kBlueDark = PdfColor.fromInt(0xff0077FF);

/// Heading prefixes that mark the message as a legal-draft output. Lowercased.
/// Covers ET/RU/EN/FI/DE/SV/LV/LT canonical draft types.
const List<String> _draftHeadingKeywords = [
  // English
  'appeal',
  'complaint',
  'response',
  'request',
  'cover letter',
  'application',
  'statement',
  // Estonian
  'apellatsioon', // apellatsioonkaebus
  'kaebus',
  'avaldus',
  'vastus',
  'taotlus',
  'kaaskiri',
  // Russian (lowercased Cyrillic)
  'жалоба',
  'апелляция',
  'заявление',
  'ходатайство',
  'обращение',
  'претензия',
  'ответ',
  // Finnish
  'valitus',
  'hakemus',
  'vastine',
  // German
  'beschwerde',
  'einspruch',
  'antrag',
  // Swedish
  'överklagande',
  'klagomål',
  'ansökan',
  // Latvian
  'sūdzība',
  'apelācija',
  'iesniegums',
  // Lithuanian
  'skundas',
  'apeliacinis',
  'prašymas',
];

/// Salutations that legal documents typically open with. Lowercased.
const List<String> _draftSalutations = [
  'lugupeetud kohus',
  'lugupeetud',
  'käesolevaga',
  'уважаемый суд',
  'уважаемая',
  'настоящим',
  'dear court',
  'to whom it may concern',
  'sehr geehrte',
  'arvoisa',
];
