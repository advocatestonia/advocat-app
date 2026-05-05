// Widget test for the ChatMessageBubble "Download PDF" button.
//
// feat(pdf): pins the visibility rule and callback wiring of the PDF
// download icon shown on AI messages that look like legal drafts. The
// callback signature matches the chat_screen integration (caller does
// the actual PdfService.renderLegalDocument + share dance).

@Tags(['fast'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advocat/features/chat/screens/chat_screen.dart';
import 'package:advocat/features/chat/widgets/chat_message_bubble.dart';

ChatMessage _aiMessage(String content, {String id = 'ai-pdf-1'}) =>
    ChatMessage(
      id: id,
      role: MessageRole.assistant,
      content: content,
      timestamp: DateTime(2026, 4, 23, 10, 0),
    );

ChatMessage _userMessage(String content) => ChatMessage(
      id: 'user-pdf-1',
      role: MessageRole.user,
      content: content,
      timestamp: DateTime(2026, 4, 23, 10, 0),
    );

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    ),
  );
  // Let flutter_animate entry animations settle.
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('ChatMessageBubble — PDF download button', () {
    testWidgets(
      'AI draft message shows the picture_as_pdf icon',
      (tester) async {
        const draft = '# Apellatsioonkaebus\n\nLugupeetud kohus, ...';
        await _pump(tester, ChatMessageBubble(message: _aiMessage(draft)));

        expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
      },
    );

    testWidgets(
      'AI casual reply does NOT show the PDF icon',
      (tester) async {
        const casual = 'Sure, here is a quick summary of your situation.';
        await _pump(tester, ChatMessageBubble(message: _aiMessage(casual)));

        expect(find.byIcon(Icons.picture_as_pdf), findsNothing);
      },
    );

    testWidgets(
      'User messages never show the PDF icon, even with draft text',
      (tester) async {
        const drafty = '# Жалоба\n\nуважаемый суд...';
        await _pump(tester, ChatMessageBubble(message: _userMessage(drafty)));

        expect(find.byIcon(Icons.picture_as_pdf), findsNothing);
      },
    );

    testWidgets(
      'Tapping the PDF icon invokes onDownloadPdf with the message',
      (tester) async {
        const draft = '# Appeal\n\nDear Court, ...';
        ChatMessage? received;

        await _pump(
          tester,
          ChatMessageBubble(
            message: _aiMessage(draft, id: 'ai-pdf-tap'),
            onDownloadPdf: (msg) => received = msg,
          ),
        );

        await tester.tap(find.byIcon(Icons.picture_as_pdf));
        await tester.pump();

        expect(received, isNotNull);
        expect(received!.id, 'ai-pdf-tap');
        expect(received!.content, draft);
      },
    );

    testWidgets(
      'Russian жалоба draft is recognised and shows the icon',
      (tester) async {
        const draft = '# Жалоба\n\nУважаемый суд, настоящим...';
        await _pump(tester, ChatMessageBubble(message: _aiMessage(draft)));

        expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
      },
    );

    testWidgets(
      'PDF icon has a unique key including the message id',
      (tester) async {
        const draft = '# Apellatsioonkaebus\n\nLugupeetud kohus, ...';
        await _pump(
          tester,
          ChatMessageBubble(message: _aiMessage(draft, id: 'msg_42')),
        );

        expect(find.byKey(const ValueKey('pdf_download_msg_42')),
            findsOneWidget);
      },
    );
  });
}
