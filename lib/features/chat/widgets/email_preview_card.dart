// email_preview_card.dart — bilingual counterparty email preview.
// -----------------------------------------------------------------------------
// Shown after Contract Review completes. Renders the `email_to_counterparty`
// markdown the planner returned, with two tabs:
//   * Preview — markdown rendered as styled text (bold, headings, lists)
//   * Plain text — raw markdown, mono-font, ideal for copy-paste
//
// Action row:
//   * Copy to clipboard
//   * Open in email app (mailto: deep link)
//   * Send via Advocat (forwards to the existing send_email tool — uses the
//     user's Gmail OAuth if connected; otherwise falls back to support@-domain)
//
// A language badge with a country-code dot shows which language the email is
// in (always the contract's ORIGINAL language, not the user's reading
// language). This is the killer-feature signal: a German contract analysed
// for a Russian-reading lawyer still produces a German email.
//
// Constraint: file must stay under 500 lines. Behaviour-only widgets
// (no business logic, no network calls) keep the test surface small.
// -----------------------------------------------------------------------------

library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/safe_launch.dart';

/// Callback signature for the "Send via Advocat" button. The host widget
/// owns the actual tool invocation — we just hand back the edited subject
/// and body when the user is ready.
typedef SendViaAdvocatCallback = void Function({
  required String to,
  required String subject,
  required String body,
});

/// Callback for the "Draft a reply" button — Pkg 7 Drafting Studio. The host
/// opens the editor pre-filled with the bilingual email so the user can
/// fine-tune it before sending. The widget hands back the current edited
/// subject + body (which may differ from the originally-generated emailMd
/// if the user typed in the Plain text tab).
typedef DraftReplyCallback = void Function({
  required String subject,
  required String body,
  required String language,
});

/// Renders the bilingual counterparty email produced by Contract Review.
class EmailPreviewCard extends StatefulWidget {
  const EmailPreviewCard({
    super.key,
    required this.emailMd,
    required this.originalLanguage,
    this.subject,
    this.qualityWarnings = const <String>[],
    this.onSendViaAdvocat,
    this.onDraftReply,
    this.counterpartyName,
  });

  /// Markdown body returned by the planner (`email_to_counterparty`).
  final String emailMd;

  /// ISO-639-1 code of the contract's original language (drives the badge).
  final String originalLanguage;

  /// Optional subject line. If null, we try to parse one from the markdown
  /// (looking for a leading `**Subject:** …` line).
  final String? subject;

  /// Non-blocking warnings from the quality verifier (e.g. "wrong_language"
  /// when detection was inconclusive). UI shows them as an amber banner.
  final List<String> qualityWarnings;

  /// When non-null, the "Send via Advocat" button is enabled and this
  /// callback fires after the user types a recipient address.
  final SendViaAdvocatCallback? onSendViaAdvocat;

  /// When non-null, a "Draft a reply" button is shown and this callback
  /// fires with the current subject + body so the host can route to the
  /// Drafting Studio editor. Pkg 7 (Drafting Studio MVP).
  final DraftReplyCallback? onDraftReply;

  /// Optional counterparty name for the draft title ("Reply to {name}").
  /// When null, the host falls back to a generic "Reply" title.
  final String? counterpartyName;

  @override
  State<EmailPreviewCard> createState() => _EmailPreviewCardState();
}

class _EmailPreviewCardState extends State<EmailPreviewCard>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final TextEditingController _bodyCtrl;
  late final TextEditingController _subjectCtrl;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    final parsed = _parseSubjectAndBody(widget.emailMd);
    _subjectCtrl = TextEditingController(
      text: widget.subject ?? parsed.subject,
    );
    _bodyCtrl = TextEditingController(text: parsed.body);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      key: const Key('email_preview_card'),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _header(theme),
          if (widget.qualityWarnings.isNotEmpty) _warningBanner(theme),
          TabBar(
            controller: _tabs,
            labelColor: cs.primary,
            unselectedLabelColor: cs.onSurfaceVariant,
            indicatorColor: cs.primary,
            tabs: const <Tab>[
              Tab(text: 'Preview'),
              Tab(text: 'Plain text'),
            ],
          ),
          SizedBox(
            height: 320,
            child: TabBarView(
              controller: _tabs,
              children: <Widget>[
                _preview(theme),
                _plainText(theme),
              ],
            ),
          ),
          const Divider(height: 1),
          _actionRow(theme),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Header — language badge + flag
  // -------------------------------------------------------------------------

  Widget _header(ThemeData theme) {
    final cs = theme.colorScheme;
    final lang = widget.originalLanguage.toLowerCase();
    final flag = _flagFor(lang);
    final name = _displayNameFor(lang);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
      child: Row(
        children: <Widget>[
          Icon(Icons.outgoing_mail, size: 20, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Counterparty email',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
          Tooltip(
            message:
                'Written in the contract\'s original language ($name) so '
                'you can forward without translating.',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(flag, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    lang.toUpperCase(),
                    key: const Key('email_preview_language_badge'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _warningBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      color: Colors.amber.withValues(alpha: 0.15),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.warning_amber, size: 16, color: Colors.orange),
              const SizedBox(width: 6),
              Text(
                'Quality check warnings',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final w in widget.qualityWarnings)
            Padding(
              padding: const EdgeInsets.only(left: 22, top: 2),
              child: Text(
                '• $w',
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Preview tab — lightweight markdown renderer (bold, headings, lists)
  // -------------------------------------------------------------------------

  Widget _preview(ThemeData theme) {
    final spans = _renderMarkdownSpans(_bodyCtrl.text, theme);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText.rich(TextSpan(children: spans)),
    );
  }

  // -------------------------------------------------------------------------
  // Plain-text tab — raw markdown, editable mono-font
  // -------------------------------------------------------------------------

  Widget _plainText(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        key: const Key('email_preview_plain_text'),
        controller: _bodyCtrl,
        maxLines: null,
        expands: true,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Action row — Copy / Open in email app / Send via Advocat
  // -------------------------------------------------------------------------

  Widget _actionRow(ThemeData theme) {
    final canSend = widget.onSendViaAdvocat != null;
    final canDraft = widget.onDraftReply != null;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          OutlinedButton.icon(
            key: const Key('email_preview_copy_btn'),
            onPressed: _copy,
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy to clipboard'),
          ),
          OutlinedButton.icon(
            key: const Key('email_preview_mailto_btn'),
            onPressed: _openInMailApp,
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Open in email app'),
          ),
          if (canDraft)
            OutlinedButton.icon(
              key: const Key('email_preview_draft_reply_btn'),
              onPressed: _draftReply,
              icon: const Icon(Icons.edit_note, size: 16),
              label: const Text('Draft a reply'),
            ),
          FilledButton.icon(
            key: const Key('email_preview_send_btn'),
            onPressed: canSend ? _sendViaAdvocat : null,
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Send via Advocat'),
          ),
        ],
      ),
    );
  }

  void _draftReply() {
    final cb = widget.onDraftReply;
    if (cb == null) return;
    cb(
      subject: _subjectCtrl.text,
      body: _bodyCtrl.text,
      language: widget.originalLanguage,
    );
  }

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _bodyCtrl.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openInMailApp() async {
    // F5 (WAVE 1, 2026-05-28) — use Uri() constructor instead of string
    // concat + Uri.parse('mailto:?$query'). The constructor percent-encodes
    // queryParameters automatically, eliminating the manual encode dance
    // (which was correct but brittle). safeLaunchUrl then enforces the
    // mailto scheme allowlist + the (empty) `to` field guard.
    final uri = Uri(
      scheme: 'mailto',
      queryParameters: <String, String>{
        'subject': _subjectCtrl.text,
        'body': _bodyCtrl.text,
      },
    );
    final result = await safeLaunchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!result.launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app')),
      );
    }
  }

  Future<void> _sendViaAdvocat() async {
    final cb = widget.onSendViaAdvocat;
    if (cb == null) return;
    final to = await _promptForRecipient();
    if (to == null || to.isEmpty || !mounted) return;
    cb(
      to: to,
      subject: _subjectCtrl.text,
      body: _bodyCtrl.text,
    );
  }

  Future<String?> _promptForRecipient() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Send to'),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'counterparty@example.com',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  static _ParsedEmail _parseSubjectAndBody(String md) {
    // Look for a leading "**Subject:** …" line.
    final lines = md.split('\n');
    String subject = '';
    int startBody = 0;
    for (int i = 0; i < lines.length && i < 5; i++) {
      final m = RegExp(r'^\*\*\s*Subject\s*:\s*\*\*\s*(.*)$', caseSensitive: false)
          .firstMatch(lines[i]);
      if (m != null) {
        subject = m.group(1)?.trim() ?? '';
        startBody = i + 1;
        // Skip a blank line after the subject line, if any.
        while (startBody < lines.length && lines[startBody].trim().isEmpty) {
          startBody++;
        }
        break;
      }
    }
    final body = startBody == 0 ? md : lines.sublist(startBody).join('\n');
    return _ParsedEmail(subject: subject, body: body.trim());
  }

  static List<InlineSpan> _renderMarkdownSpans(String md, ThemeData theme) {
    // Lightweight renderer: paragraph splits + **bold** + numbered/bullet
    // list markers. Avoids pulling flutter_markdown for a single screen.
    final spans = <InlineSpan>[];
    final lines = md.split('\n');
    for (final line in lines) {
      final l = line;
      if (l.trim().isEmpty) {
        spans.add(const TextSpan(text: '\n\n'));
        continue;
      }
      spans.addAll(_inlineBold(l, theme));
      spans.add(const TextSpan(text: '\n'));
    }
    return spans;
  }

  static List<InlineSpan> _inlineBold(String line, ThemeData theme) {
    final out = <InlineSpan>[];
    final rx = RegExp(r'\*\*(.+?)\*\*');
    int idx = 0;
    for (final m in rx.allMatches(line)) {
      if (m.start > idx) {
        out.add(TextSpan(text: line.substring(idx, m.start)));
      }
      out.add(
        TextSpan(
          text: m.group(1),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
      idx = m.end;
    }
    if (idx < line.length) {
      out.add(TextSpan(text: line.substring(idx)));
    }
    return out;
  }

  static String _flagFor(String lang) {
    switch (lang) {
      case 'en':
        return '🇬🇧';
      case 'de':
        return '🇩🇪';
      case 'fi':
        return '🇫🇮';
      case 'et':
        return '🇪🇪';
      case 'ru':
        return '🇷🇺';
      case 'uk':
        return '🇺🇦';
      case 'pl':
        return '🇵🇱';
      case 'fr':
        return '🇫🇷';
      case 'es':
        return '🇪🇸';
      case 'it':
        return '🇮🇹';
      case 'sv':
        return '🇸🇪';
      case 'no':
        return '🇳🇴';
      case 'da':
        return '🇩🇰';
      case 'lv':
        return '🇱🇻';
      case 'lt':
        return '🇱🇹';
      default:
        return '🌐';
    }
  }

  static String _displayNameFor(String lang) {
    switch (lang) {
      case 'en':
        return 'English';
      case 'de':
        return 'German';
      case 'fi':
        return 'Finnish';
      case 'et':
        return 'Estonian';
      case 'ru':
        return 'Russian';
      case 'uk':
        return 'Ukrainian';
      case 'pl':
        return 'Polish';
      case 'fr':
        return 'French';
      case 'es':
        return 'Spanish';
      case 'it':
        return 'Italian';
      case 'sv':
        return 'Swedish';
      case 'no':
        return 'Norwegian';
      case 'da':
        return 'Danish';
      case 'lv':
        return 'Latvian';
      case 'lt':
        return 'Lithuanian';
      default:
        return lang.toUpperCase();
    }
  }
}

class _ParsedEmail {
  const _ParsedEmail({required this.subject, required this.body});
  final String subject;
  final String body;
}
