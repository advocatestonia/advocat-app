@Tags(['fast'])
library;

// Widget tests for [EmailPreviewCard].
//
// Verifies:
//   * Renders the email body and a language badge with the contract's
//     ORIGINAL language code (NOT the user's reading language).
//   * The two tabs (Preview / Plain text) are wired and switchable.
//   * "Copy to clipboard" copies the body text.
//   * "Send via Advocat" is disabled when no callback is wired and enabled
//     otherwise.
//   * Quality warnings render as a banner above the tabs.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/chat/widgets/email_preview_card.dart';

const String _germanEmail = '''
**Subject:** Händlervertrag – Fragen zu §3 und §7

Sehr geehrte Damen und Herren,

vielen Dank für die Übersendung des Händlervertrags. Wir haben drei Fragen.

1. Könnten Sie §3.2 erläutern?
2. Könnten Sie §7.1 erläutern?
3. Wie ist §11 zu verstehen?

Mit freundlichen Grüßen,

[Unterschrift]
''';

const String _englishEmail = '''
**Subject:** SaaS MSA — Questions on §8 and §11

Dear Acme Cloud team,

Thank you for the draft. We have three questions.

1. Could you clarify §8.2?
2. Could you clarify §11.4?
3. Could you confirm §14.1?

Kind regards,

[Name]
''';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}

void main() {
  group('EmailPreviewCard — rendering', () {
    testWidgets('shows the language badge in UPPERCASE for German contracts',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const EmailPreviewCard(
          emailMd: _germanEmail,
          originalLanguage: 'de',
        ),
      ));
      await tester.pumpAndSettle();

      // The badge widget exists and shows "DE" — proving the email is
      // labelled by the CONTRACT's language, not the user's locale.
      expect(find.byKey(const Key('email_preview_language_badge')),
          findsOneWidget);
      expect(find.text('DE'), findsOneWidget);
    });

    testWidgets('renders English badge for English contracts', (tester) async {
      await tester.pumpWidget(_wrap(
        const EmailPreviewCard(
          emailMd: _englishEmail,
          originalLanguage: 'en',
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('EN'), findsOneWidget);
    });

    testWidgets('renders both Preview and Plain text tabs', (tester) async {
      await tester.pumpWidget(_wrap(
        const EmailPreviewCard(
          emailMd: _germanEmail,
          originalLanguage: 'de',
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Preview'), findsOneWidget);
      expect(find.text('Plain text'), findsOneWidget);
    });

    testWidgets('renders all three action buttons', (tester) async {
      await tester.pumpWidget(_wrap(
        const EmailPreviewCard(
          emailMd: _germanEmail,
          originalLanguage: 'de',
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('email_preview_copy_btn')), findsOneWidget);
      expect(find.byKey(const Key('email_preview_mailto_btn')), findsOneWidget);
      expect(find.byKey(const Key('email_preview_send_btn')), findsOneWidget);
    });
  });

  group('EmailPreviewCard — Send via Advocat enable state', () {
    testWidgets('Send button is disabled when no callback is wired',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const EmailPreviewCard(
          emailMd: _germanEmail,
          originalLanguage: 'de',
        ),
      ));
      await tester.pumpAndSettle();
      final btn = tester
          .widget<FilledButton>(find.byKey(const Key('email_preview_send_btn')));
      expect(btn.onPressed, isNull);
    });

    testWidgets('Send button is enabled when callback is provided',
        (tester) async {
      await tester.pumpWidget(_wrap(
        EmailPreviewCard(
          emailMd: _germanEmail,
          originalLanguage: 'de',
          onSendViaAdvocat: ({
            required String to,
            required String subject,
            required String body,
          }) {},
        ),
      ));
      await tester.pumpAndSettle();
      final btn = tester
          .widget<FilledButton>(find.byKey(const Key('email_preview_send_btn')));
      expect(btn.onPressed, isNotNull);
    });
  });

  group('EmailPreviewCard — quality warnings', () {
    testWidgets('renders warning banner when warnings are present',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const EmailPreviewCard(
          emailMd: _germanEmail,
          originalLanguage: 'de',
          qualityWarnings: <String>[
            'wrong_language: detected en, expected de',
            'too_short: 80 words',
          ],
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Quality check warnings'), findsOneWidget);
      expect(find.textContaining('wrong_language'), findsOneWidget);
      expect(find.textContaining('too_short'), findsOneWidget);
    });

    testWidgets('hides banner when warning list is empty', (tester) async {
      await tester.pumpWidget(_wrap(
        const EmailPreviewCard(
          emailMd: _germanEmail,
          originalLanguage: 'de',
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Quality check warnings'), findsNothing);
    });
  });

  group('EmailPreviewCard — copy', () {
    testWidgets('Copy button puts the body on the clipboard', (tester) async {
      // Set up a fake clipboard service so we can read what was written.
      String? written;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          if (call.method == 'Clipboard.setData') {
            written = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );

      await tester.pumpWidget(_wrap(
        const EmailPreviewCard(
          emailMd: _germanEmail,
          originalLanguage: 'de',
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('email_preview_copy_btn')));
      await tester.pump();

      expect(written, isNotNull);
      // The body (without the **Subject:** line) ends up on the clipboard.
      expect(written, contains('Sehr geehrte Damen und Herren'));
      expect(written, contains('Mit freundlichen Grüßen'));
      // Subject line itself should NOT be in the body — it's parsed out.
      expect(written, isNot(contains('**Subject:**')));
    });
  });

  // ─── Pkg 7 Drafting Studio — "Draft a reply" CTA ──────────────────────────
  group('EmailPreviewCard — Draft a reply', () {
    testWidgets('Draft a reply button is hidden when callback is null',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const EmailPreviewCard(
          emailMd: _germanEmail,
          originalLanguage: 'de',
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('email_preview_draft_reply_btn')),
          findsNothing);
    });

    testWidgets('Draft a reply button is shown when callback is provided',
        (tester) async {
      await tester.pumpWidget(_wrap(
        EmailPreviewCard(
          emailMd: _germanEmail,
          originalLanguage: 'de',
          onDraftReply: ({
            required String subject,
            required String body,
            required String language,
          }) {},
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('email_preview_draft_reply_btn')),
          findsOneWidget);
    });

    testWidgets('Draft a reply callback receives subject, body, language',
        (tester) async {
      String? capturedSubject;
      String? capturedBody;
      String? capturedLang;
      await tester.pumpWidget(_wrap(
        EmailPreviewCard(
          emailMd: _germanEmail,
          originalLanguage: 'de',
          onDraftReply: ({
            required String subject,
            required String body,
            required String language,
          }) {
            capturedSubject = subject;
            capturedBody = body;
            capturedLang = language;
          },
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('email_preview_draft_reply_btn')));
      await tester.pump();
      expect(capturedLang, 'de');
      expect(capturedSubject, isNotNull);
      expect(capturedSubject, contains('Händlervertrag'));
      expect(capturedBody, contains('Sehr geehrte Damen und Herren'));
    });
  });
}
